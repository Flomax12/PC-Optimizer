# ============================================================================
#  Core.ps1 - Motor de aplicacion / reversion de tweaks
#  Cada cambio se respalda en data\backup.json ANTES de aplicarse.
# ============================================================================

$script:RootDir    = Split-Path -Parent $PSScriptRoot
$script:DataDir    = Join-Path $RootDir 'data'
$script:LogDir     = Join-Path $RootDir 'logs'
$script:BackupFile = Join-Path $DataDir 'backup.json'

foreach ($d in @($script:DataDir, $script:LogDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$script:LogFile = Join-Path $script:LogDir ("sesion-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
$script:LogSink = $null   # scriptblock opcional que la GUI engancha para mostrar el log

$script:ABSENT = '<<AUSENTE>>'

# ---------------------------------------------------------------- logging ---
function Write-Opt {
    param(
        [Parameter(Mandatory)][string]$Mensaje,
        [ValidateSet('INFO','OK','WARN','ERROR','PASO')][string]$Nivel = 'INFO'
    )
    $linea = '[{0}] [{1,-5}] {2}' -f (Get-Date -Format 'HH:mm:ss'), $Nivel, $Mensaje
    Add-Content -Path $script:LogFile -Value $linea -Encoding UTF8
    if ($script:LogSink) { & $script:LogSink $Mensaje $Nivel } else {
        $color = switch ($Nivel) {
            'OK'    { 'Green' }
            'WARN'  { 'Yellow' }
            'ERROR' { 'Red' }
            'PASO'  { 'Cyan' }
            default { 'Gray' }
        }
        Write-Host $linea -ForegroundColor $color
    }
}

function Get-OptLogPath { $script:LogFile }

# ------------------------------------------------------------- privilegios ---
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ----------------------------------------------------------------- backup ---
function Get-BackupStore {
    if (Test-Path $script:BackupFile) {
        try {
            $raw = Get-Content $script:BackupFile -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
            $obj = $raw | ConvertFrom-Json
            $h = @{}
            foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = @($p.Value) }
            return $h
        } catch {
            Write-Opt "backup.json ilegible, se empieza uno nuevo: $($_.Exception.Message)" 'WARN'
            return @{}
        }
    }
    return @{}
}

function Save-BackupStore {
    param([Parameter(Mandatory)][hashtable]$Store)
    ($Store | ConvertTo-Json -Depth 8) | Set-Content -Path $script:BackupFile -Encoding UTF8
}

# --------------------------------------------------------------- registro ---
function ConvertTo-PsPath {
    param([string]$Path)
    $Path -replace '^HKLM\\', 'HKLM:\' -replace '^HKCU\\', 'HKCU:\' `
          -replace '^HKCR\\', 'HKCR:\' -replace '^HKU\\',  'HKU:\'
}

function Get-RegSnapshot {
    param([string]$Path, [string]$Name)
    $p = ConvertTo-PsPath $Path
    if (-not (Test-Path $p)) { return @{ Existe = $false; Valor = $script:ABSENT; KeyExiste = $false } }
    $item = Get-ItemProperty -Path $p -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $item) { return @{ Existe = $false; Valor = $script:ABSENT; KeyExiste = $true } }
    @{ Existe = $true; Valor = $item.$Name; KeyExiste = $true }
}

function Set-RegValue {
    param([string]$Path, [string]$Name, [string]$Type, $Value)
    $p = ConvertTo-PsPath $Path
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    # al volver de backup.json un REG_BINARY llega como array de enteros:
    # hay que devolverlo a byte[] o New-ItemProperty lo rechaza
    if ($Type -eq 'Binary' -and $Value -isnot [byte[]]) {
        $Value = [byte[]]@($Value | ForEach-Object { [byte]$_ })
    }
    New-ItemProperty -Path $p -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

function Remove-RegValue {
    param([string]$Path, [string]$Name)
    $p = ConvertTo-PsPath $Path
    if (Test-Path $p) { Remove-ItemProperty -Path $p -Name $Name -ErrorAction SilentlyContinue }
}

# ------------------------------------------------- estado de una accion ----
function Test-Action {
    param([Parameter(Mandatory)]$Action)
    switch ($Action.Kind) {
        'Reg' {
            $s = Get-RegSnapshot $Action.Path $Action.Name
            if (-not $s.Existe) { return $false }
            return ("$($s.Valor)" -eq "$($Action.Value)")
        }
        'Service' {
            $sv = Get-Service -Name $Action.Name -ErrorAction SilentlyContinue
            if (-not $sv) { return $true }   # no existe = nada que hacer
            $wmi = Get-CimInstance Win32_Service -Filter "Name='$($Action.Name)'" -ErrorAction SilentlyContinue
            if (-not $wmi) { return $true }
            $map = @{ 'Disabled' = 'Disabled'; 'Manual' = 'Manual'; 'Automatic' = 'Auto' }
            return ($wmi.StartMode -eq $map[$Action.Startup])
        }
        'Task' {
            $t = Get-ScheduledTask -TaskPath $Action.Path -TaskName $Action.Name -ErrorAction SilentlyContinue
            if (-not $t) { return $true }
            return ($t.State -eq 'Disabled')
        }
        'Script'  { if ($Action.Test) { return [bool](& $Action.Test) } else { return $false } }
        'Cleanup' { return $false }   # las limpiezas siempre se pueden repetir
    }
    return $false
}

function Test-Tweak {
    param([Parameter(Mandatory)]$Tweak)
    foreach ($a in $Tweak.Actions) { if (-not (Test-Action $a)) { return $false } }
    return $true
}

# --------------------------------------------------- aplicar una accion ----
function Invoke-Action {
    param(
        [Parameter(Mandatory)]$Action,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList]$Undo
    )

    switch ($Action.Kind) {

        'Reg' {
            $snap = Get-RegSnapshot $Action.Path $Action.Name
            [void]$Undo.Add(@{
                Kind = 'Reg'; Path = $Action.Path; Name = $Action.Name
                Type = $Action.Type; Previo = $snap.Valor; Existia = $snap.Existe
            })
            Set-RegValue $Action.Path $Action.Name $Action.Type $Action.Value
            Write-Opt "  registro: $($Action.Path)\$($Action.Name) = $($Action.Value)" 'INFO'
        }

        'Service' {
            $wmi = Get-CimInstance Win32_Service -Filter "Name='$($Action.Name)'" -ErrorAction SilentlyContinue
            if (-not $wmi) { Write-Opt "  servicio $($Action.Name) no existe, se omite" 'WARN'; return }
            $modo = switch ($wmi.StartMode) { 'Auto' { 'Automatic' } 'Manual' { 'Manual' } 'Disabled' { 'Disabled' } default { 'Manual' } }
            [void]$Undo.Add(@{
                Kind = 'Service'; Name = $Action.Name; Previo = $modo; Corria = ($wmi.State -eq 'Running')
            })
            if ($Action.Stop -and $wmi.State -eq 'Running') {
                Stop-Service -Name $Action.Name -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $Action.Name -StartupType $Action.Startup -ErrorAction Stop
            Write-Opt "  servicio: $($Action.Name) -> $($Action.Startup)" 'INFO'
        }

        'Task' {
            $t = Get-ScheduledTask -TaskPath $Action.Path -TaskName $Action.Name -ErrorAction SilentlyContinue
            if (-not $t) { Write-Opt "  tarea $($Action.Path)$($Action.Name) no existe, se omite" 'WARN'; return }
            [void]$Undo.Add(@{ Kind = 'Task'; Path = $Action.Path; Name = $Action.Name; Previo = "$($t.State)" })
            Disable-ScheduledTask -TaskPath $Action.Path -TaskName $Action.Name -ErrorAction SilentlyContinue | Out-Null
            Write-Opt "  tarea programada desactivada: $($Action.Name)" 'INFO'
        }

        'Script' {
            & $Action.Do
            if ($Action.UndoId) { [void]$Undo.Add(@{ Kind = 'Script'; UndoId = $Action.UndoId }) }
        }

        'Cleanup' { & $Action.Do }
    }
}

# --------------------------------------------------- revertir una accion ---
function Undo-Action {
    param([Parameter(Mandatory)]$Entry)

    switch ($Entry.Kind) {

        'Reg' {
            if ($Entry.Existia) {
                Set-RegValue $Entry.Path $Entry.Name $Entry.Type $Entry.Previo
                Write-Opt "  restaurado: $($Entry.Path)\$($Entry.Name) = $($Entry.Previo)" 'INFO'
            } else {
                Remove-RegValue $Entry.Path $Entry.Name
                Write-Opt "  eliminado (no existia antes): $($Entry.Path)\$($Entry.Name)" 'INFO'
            }
        }

        'Service' {
            $sv = Get-Service -Name $Entry.Name -ErrorAction SilentlyContinue
            if (-not $sv) { return }
            Set-Service -Name $Entry.Name -StartupType $Entry.Previo -ErrorAction SilentlyContinue
            if ($Entry.Corria) { Start-Service -Name $Entry.Name -ErrorAction SilentlyContinue }
            Write-Opt "  servicio restaurado: $($Entry.Name) -> $($Entry.Previo)" 'INFO'
        }

        'Task' {
            if ($Entry.Previo -ne 'Disabled') {
                Enable-ScheduledTask -TaskPath $Entry.Path -TaskName $Entry.Name -ErrorAction SilentlyContinue | Out-Null
                Write-Opt "  tarea reactivada: $($Entry.Name)" 'INFO'
            }
        }

        'Script' {
            $undo = Get-UndoScript $Entry.UndoId
            if ($undo) { & $undo; Write-Opt "  revertido: $($Entry.UndoId)" 'INFO' }
            else { Write-Opt "  sin rutina de reversion para '$($Entry.UndoId)'" 'WARN' }
        }
    }
}

# --------------------------------------------------------- API principal ---
function Invoke-Tweak {
    param([Parameter(Mandatory)]$Tweak)

    Write-Opt "Aplicando: $($Tweak.Nombre)" 'PASO'
    $undo = New-Object System.Collections.ArrayList
    try {
        foreach ($a in $Tweak.Actions) { Invoke-Action -Action $a -Undo $undo }

        if ($undo.Count -gt 0) {
            $store = Get-BackupStore
            # el backup mas antiguo es el que vale: no lo pisamos si ya existe
            if (-not $store.ContainsKey($Tweak.Id)) {
                $store[$Tweak.Id] = @($undo.ToArray())
                Save-BackupStore $store
            }
        }
        Write-Opt "$($Tweak.Nombre) -> aplicado" 'OK'
        return $true
    }
    catch {
        Write-Opt "FALLO en '$($Tweak.Nombre)': $($_.Exception.Message)" 'ERROR'
        # rollback inmediato de lo que si alcanzo a cambiar
        for ($i = $undo.Count - 1; $i -ge 0; $i--) {
            try { Undo-Action $undo[$i] } catch { }
        }
        return $false
    }
}

function Undo-Tweak {
    param([Parameter(Mandatory)][string]$TweakId)

    $store = Get-BackupStore
    if (-not $store.ContainsKey($TweakId)) {
        Write-Opt "No hay respaldo guardado para '$TweakId'" 'WARN'
        return $false
    }
    Write-Opt "Revirtiendo: $TweakId" 'PASO'
    $entries = @($store[$TweakId])
    for ($i = $entries.Count - 1; $i -ge 0; $i--) {
        try { Undo-Action $entries[$i] }
        catch { Write-Opt "  error al revertir: $($_.Exception.Message)" 'ERROR' }
    }
    $store.Remove($TweakId)
    Save-BackupStore $store
    Write-Opt "$TweakId -> revertido" 'OK'
    return $true
}

function Get-AppliedTweakIds { @((Get-BackupStore).Keys) }

# ------------------------------------------------- punto de restauracion ---
function New-OptRestorePoint {
    param([string]$Descripcion = 'PC Optimizer - antes de optimizar')
    try {
        Write-Opt 'Creando punto de restauracion del sistema...' 'PASO'
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        # Windows limita a 1 punto cada 24h; este registro lo desactiva temporalmente
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        $prev = (Get-ItemProperty -Path $k -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue).SystemRestorePointCreationFrequency
        New-ItemProperty -Path $k -Name 'SystemRestorePointCreationFrequency' -PropertyType DWord -Value 0 -Force | Out-Null
        Checkpoint-Computer -Description $Descripcion -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        if ($null -ne $prev) {
            New-ItemProperty -Path $k -Name 'SystemRestorePointCreationFrequency' -PropertyType DWord -Value $prev -Force | Out-Null
        }
        Write-Opt 'Punto de restauracion creado correctamente' 'OK'
        return $true
    }
    catch {
        Write-Opt "No se pudo crear el punto de restauracion: $($_.Exception.Message)" 'ERROR'
        Write-Opt 'Revisa que Proteccion del sistema este activada en la unidad C:' 'WARN'
        return $false
    }
}

# ------------------------------------------------------ info del sistema ---
function Get-SystemSummary {
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    # ignora adaptadores virtuales (Parsec, escritorio remoto, Meta, etc.)
    $gpus = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -notmatch 'Virtual|Remote|Basic Display|Parsec|Meta |IDD|Mirror' }
    $gpu = ($gpus | Where-Object { $_.Name -match 'NVIDIA|GeForce|RTX|Radeon RX|Arc' } |
            Select-Object -First 1).Name
    if (-not $gpu) { $gpu = ($gpus | Select-Object -First 1).Name }
    if (-not $gpu) { $gpu = 'n/d' }
    $sys = Get-Volume -DriveLetter $env:SystemDrive.TrimEnd(':') -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        SO        = "$($os.Caption) (build $($os.BuildNumber))"
        CPU       = $cpu.Name.Trim()
        Nucleos   = "$($cpu.NumberOfCores) nucleos / $($cpu.NumberOfLogicalProcessors) hilos"
        RAM       = "{0:N1} GB" -f ($cs.TotalPhysicalMemory / 1GB)
        RAMGb     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        GPU       = $gpu
        DiscoSO   = if ($sys) { "{0:N0} GB libres de {1:N0} GB" -f ($sys.SizeRemaining/1GB), ($sys.Size/1GB) } else { 'n/d' }
        Uptime    = "{0:dd\d\ hh\h\ mm\m}" -f ((Get-Date) - $os.LastBootUpTime)
        EsSSD     = [bool](Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' })
    }
}

function Get-TempFootprintMB {
    $rutas = @($env:TEMP, "$env:SystemRoot\Temp", "$env:SystemRoot\SoftwareDistribution\Download")
    $total = 0
    foreach ($r in $rutas) {
        if (Test-Path $r) {
            $b = (Get-ChildItem $r -Recurse -Force -File -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum
            if ($b) { $total += $b }
        }
    }
    [math]::Round($total / 1MB, 0)
}

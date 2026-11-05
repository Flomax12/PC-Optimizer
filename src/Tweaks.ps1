# ============================================================================
#  Tweaks.ps1 - Catalogo de optimizaciones
#
#  NUNCA se tocan:  animaciones de ventanas, transparencia/Mica, esquinas
#  redondeadas, Snap Layouts, efectos visuales, Windows Defender ni Windows
#  Update.  La estetica de Windows 11 queda intacta.
#
#  Niveles:  Basico (0 riesgo) | Medio (bajo) | Avanzado (requiere criterio)
# ============================================================================

# --------------------------------------------------------------------------
#  Rutinas de reversion para acciones de tipo 'Script'
# --------------------------------------------------------------------------
$script:UndoScripts = @{

    'power-restaurar-balanceado' = {
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    }

    'hibernacion-on' = { powercfg /hibernate on 2>$null }

    'lastaccess-on'  = { fsutil behavior set disablelastaccess 0 | Out-Null }

    'ochopuntotres-on' = { fsutil behavior set disable8dot3 0 | Out-Null }

    'compresion-memoria-on' = { Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue }

    'nic-power-on' = {
        Get-NetAdapter -Physical | ForEach-Object {
            Set-NetAdapterPowerManagement -Name $_.Name -AllowComputerToTurnOffDevice Enabled -ErrorAction SilentlyContinue
        }
    }

    'ultimate-quitar' = {
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
        $u = powercfg /list | Select-String 'Ultimate|Rendimiento maximo|Maximo rendimiento'
        if ($u) {
            $guid = [regex]::Match($u[0].ToString(), '([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})').Value
            if ($guid) { powercfg /delete $guid 2>$null }
        }
    }

    'ethernet-desactivar' = {
        $d = Get-PnpDevice -Class Net -EA SilentlyContinue |
             Where-Object { $_.FriendlyName -like '*Realtek*2.5GbE*' }
        if ($d) { Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -EA SilentlyContinue }
    }

    'nic-latencia-restaurar' = {
        foreach ($a in (Get-NetAdapter -Physical -EA SilentlyContinue)) {
            foreach ($prop in 'Interrupt Moderation','Energy-Efficient Ethernet','Green Ethernet') {
                Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $prop `
                    -DisplayValue 'Enabled' -NoRestart -EA SilentlyContinue
            }
            Restart-NetAdapter -Name $a.Name -EA SilentlyContinue
        }
    }

    'usb-suspend-on' = {
        powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 2>$null
        powercfg /setactive SCHEME_CURRENT 2>$null
    }

    'gpu-preferencia-quitar' = {
        if ($script:FortniteExe) {
            Remove-RegValue 'HKCU\Software\Microsoft\DirectX\UserGpuPreferences' $script:FortniteExe
        }
    }

    'fso-restaurar' = {
        if ($script:FortniteExe) {
            Remove-RegValue 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' $script:FortniteExe
        }
    }

    'val-gpu-quitar' = {
        if ($script:ValorantExe) {
            Remove-RegValue 'HKCU\Software\Microsoft\DirectX\UserGpuPreferences' $script:ValorantExe
        }
    }

    'val-fso-restaurar' = {
        if ($script:ValorantExe) {
            Remove-RegValue 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' $script:ValorantExe
        }
    }

    'riot-autoarranque-on' = {
        $apr = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
        if (Test-Path $apr) {
            $p = Get-ItemProperty $apr -EA SilentlyContinue
            foreach ($n in ($p.PSObject.Properties.Name | Where-Object { $_ -match 'Riot' })) {
                Set-RegValue 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' `
                    $n 'Binary' ([byte[]](2,0,0,0,0,0,0,0,0,0,0,0))
            }
        }
    }
}

function Get-UndoScript { param([string]$Id) $script:UndoScripts[$Id] }

# --------------------------------------------------------------------------
#  Localizar el ejecutable de Fortnite
#  Primero el manifiesto de Epic, luego las rutas habituales de cada disco.
# --------------------------------------------------------------------------
function Find-FortniteExe {
    $rel = 'FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe'

    $manifiesto = "$env:ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat"
    if (Test-Path $manifiesto) {
        try {
            $datos = Get-Content $manifiesto -Raw | ConvertFrom-Json
            $fn = $datos.InstallationList | Where-Object { $_.AppName -eq 'Fortnite' } | Select-Object -First 1
            if ($fn) {
                $exe = Join-Path $fn.InstallLocation $rel
                if (Test-Path $exe) { return $exe }
            }
        } catch { }
    }

    foreach ($u in (Get-PSDrive -PSProvider FileSystem -EA SilentlyContinue).Root) {
        foreach ($base in 'Program Files\Epic Games\Fortnite', 'Epic Games\Fortnite', 'Fortnite') {
            $exe = Join-Path $u (Join-Path $base $rel)
            if (Test-Path $exe) { return $exe }
        }
    }
    return $null
}

$script:FortniteExe = Find-FortniteExe

# --------------------------------------------------------------------------
#  Localizar el ejecutable de Valorant (la ruta varia entre equipos)
# --------------------------------------------------------------------------
function Find-ValorantExe {
    $rel = 'live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe'
    foreach ($u in (Get-PSDrive -PSProvider FileSystem -EA SilentlyContinue).Root) {
        foreach ($base in 'Riot Games\VALORANT', 'Program Files\Riot Games\VALORANT', 'VALORANT') {
            $exe = Join-Path $u (Join-Path $base $rel)
            if (Test-Path $exe) { return $exe }
        }
    }
    return $null
}

$script:ValorantExe = Find-ValorantExe

# --------------------------------------------------------------------------
#  Helper para declarar tweaks
# --------------------------------------------------------------------------
function New-Tweak {
    param(
        [string]$Id, [string]$Nombre, [string]$Descripcion,
        [ValidateSet('Basico','Medio','Avanzado','Fortnite','Valorant')][string[]]$Nivel,
        [string]$Categoria,
        [ValidateSet('Ninguno','Bajo','Medio','Alto')][string]$Riesgo = 'Ninguno',
        [switch]$Reinicio,
        [bool]$PorDefecto = $true,
        [string]$Nota = '',
        [array]$Actions
    )
    [PSCustomObject]@{
        Id = $Id; Nombre = $Nombre; Descripcion = $Descripcion; Nivel = $Nivel
        Categoria = $Categoria; Riesgo = $Riesgo; Reinicio = [bool]$Reinicio
        PorDefecto = $PorDefecto; Nota = $Nota; Actions = $Actions
    }
}

# ==========================================================================
#  NIVEL BASICO - limpieza y ajustes sin ningun riesgo
# ==========================================================================
$script:Catalogo = @(

New-Tweak -Id 'limpiar-temporales' -Nivel 'Basico' -Categoria 'Limpieza' `
  -Nombre 'Limpiar archivos temporales' `
  -Descripcion 'Borra %TEMP%, C:\Windows\Temp y volcados de errores. No toca documentos ni programas.' `
  -Actions @(
    @{ Kind='Cleanup'; Do={
        $rutas = @($env:TEMP, "$env:SystemRoot\Temp", "$env:LOCALAPPDATA\CrashDumps",
                   "$env:LOCALAPPDATA\Microsoft\Windows\WER")
        $liberado = 0
        foreach ($r in $rutas) {
            if (-not (Test-Path $r)) { continue }
            $antes = (Get-ChildItem $r -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Measure-Object Length -Sum).Sum
            Get-ChildItem $r -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $despues = (Get-ChildItem $r -Recurse -Force -File -ErrorAction SilentlyContinue |
                        Measure-Object Length -Sum).Sum
            $liberado += (($antes - $despues) / 1MB)
        }
        Write-Opt ("  liberados ~{0:N0} MB en temporales" -f $liberado) 'OK'
    }}
  )

New-Tweak -Id 'limpiar-wu' -Nivel 'Basico' -Categoria 'Limpieza' `
  -Nombre 'Vaciar cache de Windows Update' `
  -Descripcion 'Borra las descargas viejas de SoftwareDistribution. Windows Update sigue funcionando igual.' `
  -Actions @(
    @{ Kind='Cleanup'; Do={
        $sd = "$env:SystemRoot\SoftwareDistribution\Download"
        foreach ($s in 'wuauserv','bits') { Stop-Service $s -Force -ErrorAction SilentlyContinue }
        if (Test-Path $sd) {
            $antes = (Get-ChildItem $sd -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Get-ChildItem $sd -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Opt ("  liberados ~{0:N0} MB de cache de Windows Update" -f ($antes/1MB)) 'OK'
        }
        foreach ($s in 'bits','wuauserv') { Start-Service $s -ErrorAction SilentlyContinue }
    }}
  )

New-Tweak -Id 'vaciar-dns' -Nivel 'Basico' -Categoria 'Red' `
  -Nombre 'Vaciar cache DNS' `
  -Descripcion 'Resuelve paginas que cargan mal o no cargan por entradas DNS obsoletas.' `
  -Actions @( @{ Kind='Cleanup'; Do={ ipconfig /flushdns | Out-Null; Write-Opt '  cache DNS vaciada' 'OK' } } )

New-Tweak -Id 'papelera-vieja' -Nivel 'Basico' -Categoria 'Limpieza' -PorDefecto $false `
  -Nombre 'Vaciar la Papelera de reciclaje' `
  -Descripcion 'Vacia la papelera de todas las unidades. Revisa antes que no haya nada que quieras recuperar.' `
  -Nota 'No se puede deshacer.' `
  -Actions @( @{ Kind='Cleanup'; Do={ Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Opt '  papelera vaciada' 'OK' } } )

New-Tweak -Id 'sensor-almacenamiento' -Nivel 'Basico' -Categoria 'Limpieza' `
  -Nombre 'Activar Sensor de almacenamiento' `
  -Descripcion 'Windows limpia temporales solo, de forma automatica y periodica.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name='01';  Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name='2048'; Type='DWord'; Value=30 }
  )

New-Tweak -Id 'id-publicidad' -Nivel 'Basico' -Categoria 'Privacidad' `
  -Nombre 'Desactivar ID de publicidad' `
  -Descripcion 'Impide que las apps te perfilen para anuncios personalizados.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'sugerencias' -Nivel 'Basico' -Categoria 'Interfaz' `
  -Nombre 'Quitar sugerencias, consejos y anuncios' `
  -Descripcion 'Elimina los "consejos" del menu Inicio, Configuracion y pantalla de bloqueo. Es publicidad, no funcionalidad.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338389Enabled'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338388Enabled'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338393Enabled'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-353694Enabled'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-353696Enabled'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SystemPaneSuggestionsEnabled';    Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SilentInstalledAppsEnabled';      Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='PreInstalledAppsEnabled';         Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='OemPreInstalledAppsEnabled';      Type='DWord'; Value=0 }
  )

New-Tweak -Id 'retardo-inicio' -Nivel 'Basico' -Categoria 'Arranque' `
  -Nombre 'Quitar el retardo artificial de arranque' `
  -Descripcion 'Windows espera ~10 s antes de lanzar los programas de inicio. Esto lo elimina.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name='StartupDelayInMSec'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'menu-rapido' -Nivel 'Basico' -Categoria 'Interfaz' `
  -Nombre 'Menus mas agiles (sin perder animaciones)' `
  -Descripcion 'Reduce la espera antes de que se despliegue un submenu, de 400 ms a 150 ms. Las animaciones siguen activas.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Control Panel\Desktop'; Name='MenuShowDelay'; Type='String'; Value='150' }
  )

New-Tweak -Id 'gamedvr' -Nivel 'Basico' -Categoria 'Rendimiento' `
  -Nombre 'Desactivar grabacion en segundo plano (Game DVR)' `
  -Descripcion 'Xbox Game Bar graba constantemente en background y cuesta FPS. El Modo Juego y la Game Bar siguen disponibles.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\System\GameConfigStore'; Name='GameDVR_Enabled';            Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\System\GameConfigStore'; Name='GameDVR_FSEBehaviorMode';    Type='DWord'; Value=2 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name='AllowGameDVR'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'plan-alto-rendimiento' -Nivel 'Basico' -Categoria 'Energia' `
  -Nombre 'Plan de energia: Alto rendimiento' `
  -Descripcion 'Evita que la CPU baje de frecuencia en reposo. En un PC de escritorio es la opcion correcta.' `
  -Actions @(
    @{ Kind='Script'; UndoId='power-restaurar-balanceado'
       Test={ (powercfg /getactivescheme) -match '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
       Do={ powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Opt '  plan de energia -> Alto rendimiento' 'OK' } }
  )

New-Tweak -Id 'chkdsk-sfc' -Nivel 'Basico' -Categoria 'Diagnostico' -PorDefecto $false `
  -Nombre 'Verificar integridad del sistema (SFC + DISM)' `
  -Descripcion 'Repara archivos de sistema danados. Util justo despues de formatear o si venias con errores raros. Tarda 5-15 min.' `
  -Nota 'Puede tardar bastante. No interrumpas el proceso.' `
  -Actions @(
    @{ Kind='Cleanup'; Do={
        Write-Opt '  ejecutando DISM /RestoreHealth (paciencia)...' 'INFO'
        DISM /Online /Cleanup-Image /RestoreHealth | Out-Null
        Write-Opt '  ejecutando sfc /scannow...' 'INFO'
        sfc /scannow | Out-Null
        Write-Opt '  verificacion terminada (detalle en CBS.log)' 'OK'
    }}
  )

# ==========================================================================
#  NIVEL MEDIO - telemetria, procesos en segundo plano, bloatware
# ==========================================================================

New-Tweak -Id 'telemetria-servicio' -Nivel 'Medio' -Categoria 'Privacidad' `
  -Nombre 'Desactivar servicio de telemetria (DiagTrack)' `
  -Descripcion 'Detiene "Experiencias del usuario conectado". Consume CPU, red y disco de forma constante.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Service'; Name='DiagTrack';         Startup='Disabled'; Stop=$true },
    @{ Kind='Service'; Name='dmwappushservice';  Startup='Disabled'; Stop=$true }
  )

New-Tweak -Id 'telemetria-politica' -Nivel 'Medio' -Categoria 'Privacidad' `
  -Nombre 'Telemetria al minimo por directiva' `
  -Descripcion 'Deja el nivel de datos de diagnostico en el minimo permitido.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry';                    Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='DoNotShowFeedbackNotifications';    Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name='AllowTelemetry';     Type='DWord'; Value=0 }
  )

New-Tweak -Id 'tareas-telemetria' -Nivel 'Medio' -Categoria 'Privacidad' `
  -Nombre 'Desactivar tareas programadas de telemetria' `
  -Descripcion 'Apaga las tareas del Programa de mejora de la experiencia (CEIP) y recoleccion de datos.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='Microsoft Compatibility Appraiser' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='ProgramDataUpdater' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='StartupAppTask' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Customer Experience Improvement Program\'; Name='Consolidator' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Customer Experience Improvement Program\'; Name='UsbCeip' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Autochk\'; Name='Proxy' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Feedback\Siuf\'; Name='DmClient' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Feedback\Siuf\'; Name='DmClientOnScenarioDownload' },
    @{ Kind='Task'; Path='\Microsoft\Windows\Windows Error Reporting\'; Name='QueueReporting' }
  )

New-Tweak -Id 'apps-segundo-plano' -Nivel 'Medio' -Categoria 'Rendimiento' `
  -Nombre 'Desactivar apps en segundo plano' `
  -Descripcion 'Las apps de la Store dejan de ejecutarse cuando no las usas. Las notificaciones de las que abras siguen funcionando.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name='GlobalUserDisabled'; Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; Name='BackgroundAppGlobalToggle'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'delivery-optimization' -Nivel 'Medio' -Categoria 'Red' `
  -Nombre 'Desactivar subida P2P de actualizaciones' `
  -Descripcion 'Windows deja de usar tu subida para repartir actualizaciones a otros PCs de internet. Descargas igual de rapido.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name='DODownloadMode'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'inicio-rapido' -Nivel 'Medio' -Categoria 'Arranque' `
  -Nombre 'Desactivar Inicio rapido (Fast Startup)' `
  -Descripcion 'Fast Startup nunca apaga del todo el kernel y es la causa numero uno de errores raros que "solo se arreglan reiniciando". Arranca 2-3 s mas lento pero limpio.' `
  -Riesgo 'Bajo' -Reinicio `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name='HiberbootEnabled'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'error-reporting' -Nivel 'Medio' -Categoria 'Privacidad' `
  -Nombre 'Desactivar envio de informes de errores' `
  -Descripcion 'Deja de subir volcados de memoria a Microsoft cuando algo falla. Los logs locales se mantienen.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg';     Path='HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; Name='Disabled'; Type='DWord'; Value=1 },
    @{ Kind='Service'; Name='WerSvc'; Startup='Disabled'; Stop=$true }
  )

New-Tweak -Id 'registro-remoto' -Nivel 'Medio' -Categoria 'Seguridad' `
  -Nombre 'Desactivar Registro remoto' `
  -Descripcion 'Cierra la posibilidad de editar tu registro desde la red. En un PC personal no sirve para nada.' `
  -Riesgo 'Bajo' `
  -Actions @( @{ Kind='Service'; Name='RemoteRegistry'; Startup='Disabled'; Stop=$true } )

New-Tweak -Id 'servicios-inutiles' -Nivel 'Medio' -Categoria 'Rendimiento' `
  -Nombre 'Desactivar servicios sin uso en un PC personal' `
  -Descripcion 'Fax, Asistencia remota, Compartir Windows Media y Mapas sin conexion.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Service'; Name='Fax';                Startup='Disabled'; Stop=$true },
    @{ Kind='Service'; Name='RemoteAccess';       Startup='Disabled'; Stop=$true },
    @{ Kind='Service'; Name='WMPNetworkSvc';      Startup='Disabled'; Stop=$true },
    @{ Kind='Service'; Name='MapsBroker';         Startup='Disabled'; Stop=$true },
    @{ Kind='Service'; Name='RetailDemo';         Startup='Disabled'; Stop=$true }
  )

New-Tweak -Id 'widgets' -Nivel 'Medio' -Categoria 'Interfaz' -PorDefecto $false `
  -Nombre 'Desactivar Widgets / Noticias e intereses' `
  -Descripcion 'Quita el panel de widgets. Libera RAM y un proceso permanente en segundo plano.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Dsh'; Name='AllowNewsAndInterests'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarDa'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'busqueda-web' -Nivel 'Medio' -Categoria 'Interfaz' `
  -Nombre 'Quitar resultados web de la busqueda del menu Inicio' `
  -Descripcion 'La busqueda deja de consultar Bing y responde al instante con lo que tienes en el PC.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; Name='BingSearchEnabled';    Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; Name='CortanaConsent';       Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='DisableWebSearch';   Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='EnableDynamicContentInWSB'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'edge-background' -Nivel 'Medio' -Categoria 'Rendimiento' `
  -Nombre 'Que Edge no se quede corriendo al cerrarlo' `
  -Descripcion 'Desactiva el "inicio rapido" y el modo segundo plano de Edge. Edge funciona normal cuando lo abres.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name='StartupBoostEnabled';  Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name='BackgroundModeEnabled'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'bloatware' -Nivel 'Medio' -Categoria 'Limpieza' -PorDefecto $false `
  -Nombre 'Quitar apps preinstaladas que no usas' `
  -Descripcion 'Elimina Clipchamp, Noticias, Tiempo, Solitario, LinkedIn, Mapas, People, Feedback Hub, Xbox TCUI y similares. Conserva Store, Terminal, Fotos, Calculadora, Notas, Recortes, Camara y Xbox Game Bar.' `
  -Riesgo 'Medio' `
  -Nota 'Reinstalables desde la Microsoft Store, pero NO se restauran con el boton Revertir.' `
  -Actions @(
    @{ Kind='Script'; Test={ $false }; Do={
        $quitar = @(
            'Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather',
            'Microsoft.BingSearch','Microsoft.MicrosoftSolitaireCollection',
            'Microsoft.MicrosoftOfficeHub','Microsoft.Office.OneNote','Microsoft.SkypeApp',
            'Microsoft.People','Microsoft.WindowsMaps','Microsoft.WindowsFeedbackHub',
            'Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.Todos',
            'Microsoft.MixedReality.Portal','Microsoft.Wallet','Microsoft.3DBuilder',
            'Microsoft.Print3D','Microsoft.Microsoft3DViewer','Microsoft.ZuneVideo',
            'Microsoft.XboxApp','Microsoft.Xbox.TCUI','Microsoft.XboxSpeechToTextOverlay',
            'MicrosoftTeams','MSTeams','Microsoft.OutlookForWindows','Microsoft.549981C3F5F10'
        )
        $n = 0
        foreach ($app in $quitar) {
            $pk = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            if ($pk) {
                $pk | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                Write-Opt "  eliminada: $app" 'INFO'; $n++
            }
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object DisplayName -eq $app |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Opt "  $n apps preinstaladas eliminadas" 'OK'
    }}
  )

New-Tweak -Id 'winsxs-cleanup' -Nivel 'Medio' -Categoria 'Limpieza' `
  -Nombre 'Compactar almacen de componentes (WinSxS)' `
  -Descripcion 'Elimina versiones antiguas de componentes de Windows. Suele liberar entre 2 y 8 GB. Tarda unos minutos.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Cleanup'; Do={
        Write-Opt '  ejecutando DISM StartComponentCleanup...' 'INFO'
        DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
        Write-Opt '  almacen de componentes compactado' 'OK'
    }}
  )

# ==========================================================================
#  NIVEL AVANZADO - requiere entender el compromiso de cada opcion
# ==========================================================================

New-Tweak -Id 'plan-ultimate' -Nivel 'Avanzado' -Categoria 'Energia' `
  -Nombre 'Plan de energia: Rendimiento maximo' `
  -Descripcion 'Plan oculto de Windows. Elimina toda latencia de gestion de energia. Solo para PC de escritorio enchufado.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Script'; UndoId='ultimate-quitar'
       Test={ (powercfg /getactivescheme) -match 'e9a42b02-d5df-448d-aa00-03f14749eb61' }
       Do={
          powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
          powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
          Write-Opt '  plan de energia -> Rendimiento maximo' 'OK'
       } }
  )

New-Tweak -Id 'hags' -Nivel 'Avanzado' -Categoria 'Rendimiento' `
  -Nombre 'Planificacion de GPU acelerada por hardware (HAGS)' `
  -Descripcion 'La GPU gestiona su propia memoria de video en vez de la CPU. Reduce latencia en juegos. Recomendado en NVIDIA RTX moderna.' `
  -Riesgo 'Bajo' -Reinicio `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name='HwSchMode'; Type='DWord'; Value=2 }
  )

New-Tweak -Id 'prioridad-primer-plano' -Nivel 'Avanzado' -Categoria 'Rendimiento' `
  -Nombre 'Priorizar la ventana en primer plano' `
  -Descripcion 'Ajusta Win32PrioritySeparation para dar mas quantum de CPU a la app que estas usando. Mejora la sensacion de respuesta.' `
  -Riesgo 'Bajo' -Reinicio `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name='Win32PrioritySeparation'; Type='DWord'; Value=38 }
  )

New-Tweak -Id 'perfil-juegos' -Nivel 'Avanzado' -Categoria 'Rendimiento' `
  -Nombre 'Perfil multimedia optimizado para juegos' `
  -Descripcion 'Sube la prioridad de GPU y CPU de la tarea "Games" del planificador multimedia y quita el limite de red en tiempo real.' `
  -Riesgo 'Bajo' -Reinicio `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='NetworkThrottlingIndex'; Type='DWord'; Value=4294967295 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='SystemResponsiveness';   Type='DWord'; Value=10 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='GPU Priority'; Type='DWord'; Value=8 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='Priority';     Type='DWord'; Value=6 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='Scheduling Category'; Type='String'; Value='High' },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='SFIO Priority';        Type='String'; Value='High' }
  )

New-Tweak -Id 'sysmain-prefetch' -Nivel 'Avanzado' -Categoria 'Rendimiento' `
  -Nombre 'Desactivar SysMain y Prefetch (solo con SSD NVMe)' `
  -Descripcion 'SysMain precarga apps a RAM anticipandose a tu uso. En un NVMe la ganancia es nula y genera escrituras y picos de disco constantes.' `
  -Riesgo 'Medio' -Reinicio `
  -Nota 'NO lo actives si el sistema esta instalado en un disco mecanico (HDD).' `
  -Actions @(
    @{ Kind='Service'; Name='SysMain'; Startup='Disabled'; Stop=$true },
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnablePrefetcher';  Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnableSuperfetch'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'ntfs-lastaccess' -Nivel 'Avanzado' -Categoria 'Disco' `
  -Nombre 'Desactivar marca de "ultimo acceso" en NTFS' `
  -Descripcion 'Evita una escritura al disco cada vez que se LEE un archivo. Notable al trabajar con muchos archivos pequenos.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Script'; UndoId='lastaccess-on'
       Test={ (fsutil behavior query disablelastaccess) -match '=\s*1' }
       Do={ fsutil behavior set disablelastaccess 1 | Out-Null; Write-Opt '  last access desactivado' 'OK' } }
  )

New-Tweak -Id 'ntfs-8dot3' -Nivel 'Avanzado' -Categoria 'Disco' -PorDefecto $false `
  -Nombre 'Desactivar nombres cortos 8.3' `
  -Descripcion 'Acelera operaciones en carpetas con muchos archivos. Compatibilidad heredada de MS-DOS que ya casi nada usa.' `
  -Riesgo 'Medio' `
  -Nota 'Programas muy antiguos (16 bits, instaladores de los 90) podrian fallar.' `
  -Actions @(
    @{ Kind='Script'; UndoId='ochopuntotres-on'
       Test={ (fsutil behavior query disable8dot3) -match '=\s*1' }
       Do={ fsutil behavior set disable8dot3 1 | Out-Null; Write-Opt '  nombres 8.3 desactivados' 'OK' } }
  )

New-Tweak -Id 'hibernacion' -Nivel 'Avanzado' -Categoria 'Disco' -PorDefecto $false `
  -Nombre 'Desactivar hibernacion (libera varios GB)' `
  -Descripcion 'Borra hiberfil.sys, que ocupa aproximadamente el 40% de tu RAM en disco. Pierdes hibernar; suspender sigue funcionando.' `
  -Riesgo 'Bajo' `
  -Nota 'Con 62 GB de RAM esto libera cerca de 25 GB en C:.' `
  -Actions @(
    @{ Kind='Script'; UndoId='hibernacion-on'
       Test={ -not (Test-Path "$env:SystemDrive\hiberfil.sys") }
       Do={ powercfg /hibernate off 2>$null; Write-Opt '  hibernacion desactivada, hiberfil.sys eliminado' 'OK' } }
  )

New-Tweak -Id 'compresion-memoria' -Nivel 'Avanzado' -Categoria 'Rendimiento' -PorDefecto $false `
  -Nombre 'Desactivar compresion de memoria' `
  -Descripcion 'Windows comprime paginas de RAM gastando CPU. Con mucha RAM libre es trabajo innecesario.' `
  -Riesgo 'Medio' -Reinicio `
  -Nota 'Solo tiene sentido con 32 GB o mas. Con poca RAM empeora el rendimiento.' `
  -Actions @(
    @{ Kind='Script'; UndoId='compresion-memoria-on'
       Test={ $a = Get-MMAgent -ErrorAction SilentlyContinue
              if ($a) { -not $a.MemoryCompression } else { $false } }
       Do={ Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
            Write-Opt '  compresion de memoria desactivada' 'OK' } }
  )

New-Tweak -Id 'nic-ahorro' -Nivel 'Avanzado' -Categoria 'Red' `
  -Nombre 'Impedir que Windows apague la tarjeta de red' `
  -Descripcion 'Quita el permiso de "apagar este dispositivo para ahorrar energia". Evita microcortes y picos de ping.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Script'; UndoId='nic-power-on'
       Test={ $false }
       Do={
          Get-NetAdapter -Physical | ForEach-Object {
             Set-NetAdapterPowerManagement -Name $_.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue
             Write-Opt "  ahorro de energia desactivado en: $($_.Name)" 'INFO'
          }
       } }
  )

New-Tweak -Id 'copilot' -Nivel 'Avanzado' -Categoria 'Interfaz' -PorDefecto $false `
  -Nombre 'Desactivar Copilot' `
  -Descripcion 'Quita el asistente Copilot de la barra de tareas y del sistema.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name='TurnOffWindowsCopilot'; Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; Name='TurnOffWindowsCopilot'; Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ShowCopilotButton'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'recall' -Nivel 'Avanzado' -Categoria 'Privacidad' `
  -Nombre 'Desactivar Recall (capturas continuas de pantalla)' `
  -Descripcion 'Impide que Windows guarde un historial visual de todo lo que haces. Ahorra disco, CPU y NPU.' `
  -Riesgo 'Bajo' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name='DisableAIDataAnalysis'; Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKCU\Software\Policies\Microsoft\Windows\WindowsAI'; Name='DisableAIDataAnalysis'; Type='DWord'; Value=1 }
  )

New-Tweak -Id 'cola-impresion' -Nivel 'Avanzado' -Categoria 'Seguridad' -PorDefecto $false `
  -Nombre 'Desactivar Cola de impresion (si no tienes impresora)' `
  -Descripcion 'El servicio Spooler acumula historial de vulnerabilidades graves. Si no imprimes, apagarlo es puro beneficio.' `
  -Riesgo 'Medio' `
  -Nota 'Si algun dia conectas una impresora, revierte este cambio primero.' `
  -Actions @( @{ Kind='Service'; Name='Spooler'; Startup='Disabled'; Stop=$true } )

New-Tweak -Id 'vbs-integridad-memoria' -Nivel 'Avanzado' -Categoria 'Seguridad' -PorDefecto $false `
  -Nombre 'Desactivar VBS / Integridad de memoria' `
  -Descripcion 'La virtualizacion de seguridad cuesta entre 5% y 15% de FPS en juegos. Desactivarla los recupera.' `
  -Riesgo 'Alto' -Reinicio `
  -Nota 'COMPROMISO REAL DE SEGURIDAD: reduce la proteccion del kernel frente a drivers maliciosos. Activalo solo si priorizas FPS y sabes lo que instalas. SI JUEGAS A VALORANT, LOL O TFT: la solucion oficial de Riot para el error VAN 9005 es ACTIVAR Integridad de memoria, asi que desactivarla puede dejarte sin jugar. Usa la reparacion de la pestana Valorant si te pasa.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name='EnableVirtualizationBasedSecurity'; Type='DWord'; Value=0 },
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='Enabled'; Type='DWord'; Value=0 }
  )
)

# --------------------------------------------------------------------------
#  Nivel Fortnite, en su propio archivo
. (Join-Path $PSScriptRoot 'Tweaks.Fortnite.ps1')
. (Join-Path $PSScriptRoot 'Tweaks.Valorant.ps1')

# --------------------------------------------------------------------------
function Get-Catalogo { param([string]$Nivel)
    # un tweak puede pertenecer a varios niveles (p.ej. los de latencia, que valen
    # para Fortnite y para Valorant): por eso -contains y no -eq
    if ($Nivel) { @($script:Catalogo | Where-Object { $_.Nivel -contains $Nivel }) } else { $script:Catalogo }
}
function Get-TweakById { param([string]$Id) $script:Catalogo | Where-Object Id -eq $Id | Select-Object -First 1 }

<#
    Probar.ps1 - Prueba de humo. NO aplica ningun cambio al sistema.
    Verifica: catalogo integro, motor de respaldo/reversion y construccion de la GUI.
    Se puede ejecutar sin permisos de administrador.
#>
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'src\Core.ps1')
. (Join-Path $PSScriptRoot 'src\Tweaks.ps1')

$fallos = 0
function Assert { param([string]$Que, [bool]$Cond)
    if ($Cond) { Write-Host "  OK    $Que" -ForegroundColor Green }
    else       { Write-Host "  FALLO $Que" -ForegroundColor Red; $script:fallos++ }
}

Write-Host ''
Write-Host '  --- Catalogo ---' -ForegroundColor Cyan
$cat = Get-Catalogo
Assert "hay optimizaciones cargadas ($($cat.Count))" ($cat.Count -gt 0)
Assert 'no hay identificadores duplicados' (($cat | Group-Object Id | Where-Object Count -gt 1).Count -eq 0)
$vacios = @('Basico','Medio','Avanzado','Fortnite','Valorant' | Where-Object { (Get-Catalogo -Nivel $_).Count -eq 0 })
Assert 'los cinco niveles tienen contenido' ($vacios.Count -eq 0)

$sinAcciones = @($cat | Where-Object { -not $_.Actions -or $_.Actions.Count -eq 0 })
Assert 'todas las optimizaciones declaran acciones' ($sinAcciones.Count -eq 0)

$scriptSinUndo = @($cat | ForEach-Object { $t = $_
    $_.Actions | Where-Object { $_.Kind -eq 'Script' -and -not $_.UndoId } |
        ForEach-Object { $t.Id } }) | Sort-Object -Unique
if ($scriptSinUndo) {
    Write-Host "  aviso  sin reversion automatica: $($scriptSinUndo -join ', ')" -ForegroundColor Yellow
}
$undoRotos = @($cat | ForEach-Object { $_.Actions } |
    Where-Object { $_.Kind -eq 'Script' -and $_.UndoId -and -not (Get-UndoScript $_.UndoId) })
Assert 'todo UndoId apunta a una rutina real' ($undoRotos.Count -eq 0)

Write-Host ''
Write-Host '  --- Deteccion de estado ---' -ForegroundColor Cyan
$err = 0
foreach ($t in $cat) { try { $null = Test-Tweak $t } catch { $err++; Write-Host "    $($t.Id): $($_.Exception.Message)" -ForegroundColor DarkRed } }
Assert 'Test-Tweak funciona en todo el catalogo' ($err -eq 0)

Write-Host ''
Write-Host '  --- Motor de respaldo y reversion ---' -ForegroundColor Cyan
$rutaTest = 'HKCU:\Software\PCOptimizerSelfTest'
New-Item -Path $rutaTest -Force | Out-Null
New-ItemProperty -Path $rutaTest -Name 'Previo' -PropertyType DWord -Value 111 -Force | Out-Null

$prueba = New-Tweak -Id '__selftest__' -Nombre 'Prueba interna' -Descripcion 'temporal' `
    -Nivel 'Basico' -Categoria 'Test' -Actions @(
        @{ Kind='Reg'; Path='HKCU\Software\PCOptimizerSelfTest'; Name='Previo'; Type='DWord'; Value=999 },
        @{ Kind='Reg'; Path='HKCU\Software\PCOptimizerSelfTest'; Name='Nuevo';  Type='DWord'; Value=42  })

$script:LogSink = { param($m,$n) }   # silencia el log durante la prueba
$null = Invoke-Tweak $prueba
$p = Get-ItemProperty $rutaTest
Assert 'aplica el valor nuevo'          ($p.Previo -eq 999 -and $p.Nuevo -eq 42)
Assert 'registra el cambio como aplicado' ((Get-AppliedTweakIds) -contains '__selftest__')
$null = Invoke-Tweak $prueba
$null = Undo-Tweak '__selftest__'
$p = Get-ItemProperty $rutaTest
Assert 'restaura el valor original tras reaplicar' ($p.Previo -eq 111)
Assert 'elimina el valor que no existia antes'     ($null -eq $p.PSObject.Properties['Nuevo'])
Assert 'limpia el respaldo'                        ((Get-AppliedTweakIds) -notcontains '__selftest__')
Remove-Item $rutaTest -Recurse -Force
$script:LogSink = $null

Write-Host ''
Write-Host '  --- Interfaz grafica ---' -ForegroundColor Cyan
. (Join-Path $PSScriptRoot 'src\Gui.ps1')
$r = Show-OptimizerGui -SoloConstruir
Assert "la ventana se construye ($($r.Tarjetas) tarjetas)" ($r.Tarjetas -eq $cat.Count)
Assert 'las cinco pestañas tienen contenido' ($r.Basico -gt 0 -and $r.Medio -gt 0 -and $r.Avanzado -gt 0 -and $r.Fortnite -gt 0 -and $r.Valorant -gt 0)

Write-Host ''
if ($fallos -eq 0) { Write-Host "  TODO CORRECTO. $($cat.Count) optimizaciones listas." -ForegroundColor Green }
else               { Write-Host "  $fallos prueba(s) fallidas." -ForegroundColor Red }
Write-Host ''
exit $fallos

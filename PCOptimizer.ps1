<#
.SYNOPSIS
    PC Optimizer - optimizador de Windows 11 con tres niveles y reversion completa.

.DESCRIPTION
    Sin parametros abre la interfaz grafica.
    Nunca toca animaciones, transparencias, efectos visuales, Defender ni Windows Update.

.PARAMETER Nivel
    Basico | Medio | Avanzado | Fortnite | Valorant. Usado con -Aplicar o -Listar.

.PARAMETER Aplicar
    Aplica por consola las optimizaciones recomendadas del nivel indicado.

.PARAMETER Listar
    Muestra el catalogo y el estado actual de cada optimizacion.

.PARAMETER RevertirTodo
    Deshace todos los cambios aplicados por esta app.

.PARAMETER SinPunto
    Omite la creacion del punto de restauracion en modo consola.

.EXAMPLE
    .\PCOptimizer.ps1
.EXAMPLE
    .\PCOptimizer.ps1 -Listar
.EXAMPLE
    .\PCOptimizer.ps1 -Nivel Basico -Aplicar
.EXAMPLE
    .\PCOptimizer.ps1 -RevertirTodo
#>
[CmdletBinding()]
param(
    [ValidateSet('Basico','Medio','Avanzado','Fortnite','Valorant')][string]$Nivel,
    [switch]$Aplicar,
    [switch]$Listar,
    [switch]$RevertirTodo,
    [switch]$SinPunto
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'src\Core.ps1')
. (Join-Path $PSScriptRoot 'src\Tweaks.ps1')

# ------------------------------------------------------------ elevacion ----
if (-not (Test-Admin)) {
    Write-Host ''
    Write-Host '  Se necesitan permisos de administrador. Relanzando elevado...' -ForegroundColor Yellow
    $argumentos = @('-NoProfile','-ExecutionPolicy','Bypass','-File', "`"$PSCommandPath`"")
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        if ($kv.Value -is [switch]) { if ($kv.Value.IsPresent) { $argumentos += "-$($kv.Key)" } }
        else { $argumentos += @("-$($kv.Key)", "$($kv.Value)") }
    }
    try { Start-Process powershell.exe -Verb RunAs -ArgumentList $argumentos }
    catch { Write-Host '  Elevacion cancelada. La app no puede continuar.' -ForegroundColor Red }
    return
}

# ------------------------------------------------------------ modo lista ---
if ($Listar) {
    Write-Host ''
    Write-Host '  CATALOGO DE OPTIMIZACIONES' -ForegroundColor Cyan
    $aplicados = Get-AppliedTweakIds
    foreach ($n in 'Basico','Medio','Avanzado','Fortnite','Valorant') {
        Write-Host ''
        Write-Host "  === $($n.ToUpper()) ===" -ForegroundColor White
        foreach ($t in (Get-Catalogo -Nivel $n)) {
            $estado = if ($aplicados -contains $t.Id) { '[APLICADO]' }
                      elseif (Test-Tweak $t)          { '[ya ok]   ' }
                      else                            { '[         ' + ']' }
            $marca  = if ($t.PorDefecto) { '*' } else { ' ' }
            $color  = switch ($t.Riesgo) { 'Alto' {'Red'} 'Medio' {'Yellow'} default {'Gray'} }
            Write-Host ("  {0} {1} {2,-46} {3}" -f $estado, $marca, $t.Nombre, $t.Categoria) -ForegroundColor $color
        }
    }
    Write-Host ''
    Write-Host '  * = recomendado (se marca por defecto)' -ForegroundColor DarkGray
    Write-Host ''
    return
}

# --------------------------------------------------------- modo revertir ---
if ($RevertirTodo) {
    $ids = @(Get-AppliedTweakIds)
    if ($ids.Count -eq 0) { Write-Host '  No hay nada aplicado que revertir.' -ForegroundColor Yellow; return }
    Write-Host ''
    Write-Host "  Se van a revertir $($ids.Count) cambios." -ForegroundColor Yellow
    if ((Read-Host '  Escribe SI para confirmar') -ne 'SI') { Write-Host '  Cancelado.'; return }
    foreach ($id in $ids) { Undo-Tweak $id | Out-Null }
    Write-Host ''
    Write-Host '  Todo revertido. Reinicia el PC para completar el proceso.' -ForegroundColor Green
    return
}

# --------------------------------------------------------- modo aplicar ----
if ($Aplicar) {
    if (-not $Nivel) { throw 'Indica el nivel: -Nivel Basico | Medio | Avanzado | Fortnite' }
    $lote = @(Get-Catalogo -Nivel $Nivel | Where-Object PorDefecto)
    Write-Host ''
    Write-Host "  Nivel $Nivel : $($lote.Count) optimizaciones recomendadas" -ForegroundColor Cyan
    $lote | ForEach-Object { Write-Host "    - $($_.Nombre)" -ForegroundColor Gray }
    Write-Host ''
    if ((Read-Host '  Escribe SI para aplicar') -ne 'SI') { Write-Host '  Cancelado.'; return }

    if (-not $SinPunto) { New-OptRestorePoint | Out-Null }

    $ok = 0; $fail = 0
    foreach ($t in $lote) { if (Invoke-Tweak $t) { $ok++ } else { $fail++ } }

    Write-Host ''
    Write-Host "  Terminado: $ok correctas, $fail con error." -ForegroundColor Green
    if ($lote | Where-Object Reinicio) { Write-Host '  Reinicia el PC para que todo tenga efecto.' -ForegroundColor Yellow }
    Write-Host "  Registro: $(Get-OptLogPath)" -ForegroundColor DarkGray
    Write-Host ''
    return
}

# ---------------------------------------------------------------- modo GUI --
. (Join-Path $PSScriptRoot 'src\Gui.ps1')
Show-OptimizerGui

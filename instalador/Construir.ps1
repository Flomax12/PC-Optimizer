<#
    Construir.ps1 - genera PCOptimizer-Setup.exe

    Empaqueta la app en un ZIP y lo compila DENTRO de un .exe con csc.exe, el
    compilador de C# que viene con .NET Framework. No descarga nada.

    Antes de empaquetar ejecuta Probar.ps1 sobre la copia preparada: si el
    paquete no pasa sus propias pruebas, no se genera el instalador.
#>
$ErrorActionPreference = 'Stop'

$raiz    = Split-Path -Parent $PSScriptRoot
$trabajo = Join-Path $PSScriptRoot 'build'
$salida  = Join-Path $PSScriptRoot 'PCOptimizer-Setup.exe'

$csc = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { $csc = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe" }
if (-not (Test-Path $csc)) { throw "No encuentro csc.exe (.NET Framework 4.x)" }

Write-Host ''
Write-Host '  Construyendo el instalador...' -ForegroundColor Cyan

if (Test-Path $trabajo) { Remove-Item $trabajo -Recurse -Force }
New-Item -ItemType Directory -Path $trabajo -Force | Out-Null

$padre = Join-Path $trabajo 'stage'
$stage = Join-Path $padre 'PC-Optimizer'
New-Item -ItemType Directory -Path (Join-Path $stage 'src') -Force | Out-Null

foreach ($f in 'Iniciar.bat','PCOptimizer.ps1','Probar.ps1','README.md','GUIA-FORTNITE.md','GUIA-VALORANT.md') {
    $o = Join-Path $raiz $f
    if (Test-Path $o) { Copy-Item $o -Destination $stage }
    else { Write-Host "    AVISO: falta $f" -ForegroundColor Yellow }
}
Copy-Item (Join-Path $raiz 'src\*.ps1') -Destination (Join-Path $stage 'src')

# data\ y logs\ NO se distribuyen: el respaldo es propio de cada equipo
$total = (Get-ChildItem $stage -Recurse -File).Count
Write-Host "    $total archivos preparados"

Write-Host '    verificando el paquete...'
$prueba = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $stage 'Probar.ps1') 2>&1
if ($LASTEXITCODE -ne 0) {
    $prueba | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
    throw 'El paquete no pasa sus propias pruebas. Instalador NO generado.'
}
Write-Host '    el paquete pasa sus pruebas' -ForegroundColor Green

foreach ($d in 'data','logs') {
    $p = Join-Path $stage $d
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}

# Ni Compress-Archive ni ZipFile::CreateFromDirectory escriben las rutas con
# barra normal en .NET Framework: usan la del sistema. El formato ZIP exige
# '/', asi que construimos las entradas a mano.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = Join-Path $trabajo 'payload.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
$fs = [System.IO.File]::Open($zip, 'CreateNew')
try {
    $arch = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $sep = [System.IO.Path]::DirectorySeparatorChar
        foreach ($archivo in (Get-ChildItem $padre -Recurse -File)) {
            $rel = $archivo.FullName.Substring($padre.Length).TrimStart($sep).Replace($sep, '/')
            $e = $arch.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
            $salidaE = $e.Open()
            try { $bytes = [System.IO.File]::ReadAllBytes($archivo.FullName)
                  $salidaE.Write($bytes, 0, $bytes.Length) }
            finally { $salidaE.Dispose() }
        }
    } finally { $arch.Dispose() }
} finally { $fs.Dispose() }

Write-Host '    compilando el .exe...'
if (Test-Path $salida) { Remove-Item $salida -Force }

$opciones = @(
    '/nologo', '/target:winexe', '/optimize+', '/platform:anycpu'
    "/out:$salida"
    "/resource:$zip,payload.zip"
    '/reference:System.dll'
    '/reference:System.Drawing.dll'
    '/reference:System.Windows.Forms.dll'
    '/reference:System.IO.Compression.dll'
    '/reference:System.IO.Compression.FileSystem.dll'
    (Join-Path $PSScriptRoot 'Setup.cs')
)
$log = & $csc @opciones 2>&1
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $salida)) {
    $log | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
    throw 'La compilacion fallo.'
}

$kb = [math]::Round((Get-Item $salida).Length / 1KB, 0)
Remove-Item $trabajo -Recurse -Force

Write-Host ''
Write-Host "  LISTO: $salida  ($kb KB)" -ForegroundColor Green
Write-Host ''
Write-Host '  Al abrirlo en otro PC, Windows mostrara un aviso de SmartScreen'   -ForegroundColor Yellow
Write-Host '  porque el .exe no esta firmado digitalmente. Es lo normal en'      -ForegroundColor Yellow
Write-Host '  software sin certificado de pago: Mas informacion -> Ejecutar.'    -ForegroundColor Yellow
Write-Host ''

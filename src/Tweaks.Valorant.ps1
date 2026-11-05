# ============================================================================
#  Tweaks.Valorant.ps1 - Nivel "Valorant"
#
#  Los ajustes de latencia comunes (red, raton, USB, FilterKeys, Modo juego,
#  temporizador) estan declarados con -Nivel 'Fortnite','Valorant' y aparecen
#  tambien en esta pestana. Aqui solo va lo especifico de Riot y Vanguard.
#
#  IMPORTANTE sobre Vanguard: este archivo NO toca, oculta ni elude el
#  anticheat. Al contrario, incluye una reparacion para cuando otro
#  "optimizador" ha dejado su servicio desactivado y el juego no arranca.
#
#  Verificado en la documentacion oficial de Riot (noviembre 2026):
#   - VAN 9001: "This build of Vanguard requires TPM 2.0 to be enabled in
#     order to play."  TPM 2.0 es requisito duro.
#   - VAN 9005: los pasos oficiales de Riot piden activar Secure Boot y
#     comprobar Integridad de memoria (VBS).
#  Por eso desactivar VBS puede dejarte sin jugar: ver 'val-vbs-reparar'.
# ============================================================================

$script:Catalogo += @(

# ------------------------------------------------------------ diagnostico ---
New-Tweak -Id 'val-diagnostico' -Nivel 'Valorant' -Categoria 'Diagnostico' `
  -Nombre 'Comprobar requisitos de Vanguard' `
  -Descripcion 'No cambia nada. Revisa TPM 2.0, Secure Boot, Integridad de memoria y el servicio de Vanguard, y escribe el resultado en la pestana Registro. Ejecuta esto PRIMERO si el juego no arranca o sale un error VAN.' `
  -Actions @(
    @{ Kind='Cleanup'; Do={
        $tpm = Get-CimInstance -Namespace 'root\cimv2\security\microsofttpm' -ClassName Win32_Tpm -EA SilentlyContinue
        if ($tpm) {
            $ver = ($tpm.SpecVersion -split ',')[0].Trim()
            $ok  = $tpm.IsEnabled_InitialValue -and $ver -match '^2'
            Write-Opt "  TPM: version $ver, activado=$($tpm.IsEnabled_InitialValue)" $(if($ok){'OK'}else{'ERROR'})
            if (-not $ok) { Write-Opt '    -> Vanguard EXIGE TPM 2.0. Activalo en la BIOS (fTPM en AMD, PTT en Intel).' 'ERROR' }
        } else { Write-Opt '  TPM: no se pudo leer' 'WARN' }

        try {
            $sb = Confirm-SecureBootUEFI
            Write-Opt "  Secure Boot: $sb" $(if($sb){'OK'}else{'WARN'})
            if (-not $sb) { Write-Opt '    -> Riot pide activarlo en los pasos del error VAN 9005.' 'WARN' }
        } catch { Write-Opt "  Secure Boot: no se pudo leer ($($_.Exception.Message))" 'WARN' }

        $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -EA SilentlyContinue
        if ($dg) {
            $hvci = ($dg.SecurityServicesRunning -contains 2)
            Write-Opt "  Integridad de memoria (HVCI) en ejecucion: $hvci" $(if($hvci){'OK'}else{'WARN'})
            if (-not $hvci) { Write-Opt '    -> Si sale el error VAN 9005, reactivala con la reparacion de esta pestana.' 'WARN' }
        } else { Write-Opt '  Integridad de memoria: no se pudo leer' 'WARN' }

        $vgc = Get-CimInstance Win32_Service -Filter "Name='vgc'" -EA SilentlyContinue
        if ($vgc) {
            $bien = $vgc.StartMode -ne 'Disabled'
            Write-Opt "  Servicio vgc: $($vgc.State), inicio=$($vgc.StartMode)" $(if($bien){'OK'}else{'ERROR'})
            if (-not $bien) { Write-Opt '    -> Esta DESACTIVADO. Usa la reparacion de esta pestana.' 'ERROR' }
        } else { Write-Opt '  Servicio vgc: no instalado (se instala con el juego)' 'WARN' }

        if ($script:ValorantExe) { Write-Opt "  Valorant: $($script:ValorantExe)" 'OK' }
        else { Write-Opt '  Valorant: no encontrado en este equipo' 'WARN' }
    }}
  )

# ------------------------------------------------------------- reparacion ---
New-Tweak -Id 'val-vanguard-reparar' -Nivel 'Valorant' -Categoria 'Vanguard' `
  -Nombre 'Reparar el servicio de Vanguard' `
  -Descripcion 'Devuelve el servicio vgc a Inicio manual, que es su valor de fabrica. Muchos "optimizadores" lo desactivan para ganar un megabyte de RAM y luego el juego no arranca con un error VAN.' `
  -Nota 'Si vgc ya esta en manual o automatico, esto no cambia nada.' `
  -Actions @(
    @{ Kind='Service'; Name='vgc'; Startup='Manual'; Stop=$false }
  )

New-Tweak -Id 'val-vbs-reparar' -Nivel 'Valorant' -Categoria 'Vanguard' -PorDefecto $false `
  -Nombre 'Reactivar Integridad de memoria (error VAN 9005)' `
  -Descripcion 'Vuelve a activar VBS y HVCI. Es la solucion oficial de Riot para el error VAN 9005. Marca esto si desactivaste VBS en el nivel Avanzado y ahora Valorant no te deja jugar.' `
  -Riesgo 'Bajo' -Reinicio `
  -Nota 'Deshace el tweak "Desactivar VBS" del nivel Avanzado. No marques los dos a la vez. Recuperas la proteccion del kernel y pierdes entre 5% y 15% de FPS.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name='EnableVirtualizationBasedSecurity'; Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='Enabled'; Type='DWord'; Value=1 }
  )

# --------------------------------------------------------------- graficos ---
New-Tweak -Id 'val-gpu-dedicada' -Nivel 'Valorant' -Categoria 'Graficos' `
  -Nombre 'Forzar la GPU dedicada para Valorant' `
  -Descripcion 'Valorant es tan ligero que Windows a veces decide que la grafica integrada le basta. Con un monitor de alta tasa de refresco eso te cuesta la mitad de los FPS. Esto fija la tarjeta dedicada de forma explicita.' `
  -Actions @(
    @{ Kind='Script'; UndoId='val-gpu-quitar'
       Test={
          if (-not $script:ValorantExe) { return $true }
          $v = Get-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $script:ValorantExe -EA SilentlyContinue
          [bool]($v -and "$($v.$($script:ValorantExe))" -match 'GpuPreference=2')
       }
       Do={
          if (-not $script:ValorantExe) { Write-Opt '  Valorant no encontrado, se omite' 'WARN'; return }
          Set-RegValue 'HKCU\Software\Microsoft\DirectX\UserGpuPreferences' $script:ValorantExe 'String' 'GpuPreference=2;'
          Write-Opt '  GPU dedicada fijada para Valorant' 'OK'
       } }
  )

New-Tweak -Id 'val-sin-fso' -Nivel 'Valorant' -Categoria 'Graficos' -PorDefecto $false `
  -Nombre 'Desactivar optimizaciones de pantalla completa en Valorant' `
  -Descripcion 'Fuerza pantalla completa exclusiva, el camino mas corto hasta el monitor.' `
  -Riesgo 'Bajo' `
  -Nota 'Desmarcado: en exclusiva pierdes el Alt-Tab instantaneo, y en Valorant se hace Alt-Tab mucho. Mide antes de dejarlo puesto.' `
  -Actions @(
    @{ Kind='Script'; UndoId='val-fso-restaurar'
       Test={
          if (-not $script:ValorantExe) { return $true }
          $v = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -Name $script:ValorantExe -EA SilentlyContinue
          [bool]($v -and "$($v.$($script:ValorantExe))" -match 'DISABLEDXMAXIMIZEDWINDOWEDMODE')
       }
       Do={
          if (-not $script:ValorantExe) { Write-Opt '  Valorant no encontrado, se omite' 'WARN'; return }
          Set-RegValue 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' $script:ValorantExe 'String' '~ DISABLEDXMAXIMIZEDWINDOWEDMODE'
          Write-Opt '  pantalla completa exclusiva forzada para Valorant' 'OK'
       } }
  )

# ---------------------------------------------------------------- arranque ---
New-Tweak -Id 'val-riot-autoarranque' -Nivel 'Valorant' -Categoria 'Arranque' `
  -Nombre 'Que el cliente de Riot no arranque con Windows' `
  -Descripcion 'El Riot Client se mete solo en el arranque y se queda en segundo plano consumiendo RAM y red. Lo desactiva igual que lo haria el Administrador de tareas.' `
  -Actions @(
    @{ Kind='Script'; UndoId='riot-autoarranque-on'
       Test={
          $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
          if (-not (Test-Path $run)) { return $false }
          $p = Get-ItemProperty $run -EA SilentlyContinue
          $n = $p.PSObject.Properties.Name | Where-Object { $_ -match 'Riot' } | Select-Object -First 1
          if (-not $n) { return $false }
          [bool](([byte[]]$p.$n)[0] -band 1)
       }
       Do={
          $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
          $nombres = @()
          if (Test-Path $runKey) {
             $nombres = @((Get-ItemProperty $runKey).PSObject.Properties.Name | Where-Object { $_ -match 'Riot' })
          }
          if (-not $nombres) { Write-Opt '  el cliente de Riot no esta en el arranque' 'INFO'; return }
          $apr = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
          foreach ($n in $nombres) {
             Set-RegValue $apr $n 'Binary' ([byte[]](3,0,0,0,0,0,0,0,0,0,0,0))
             Write-Opt "  desactivado del arranque: $n" 'OK'
          }
       } }
  )
)

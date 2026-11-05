# ============================================================================
#  Tweaks.Fortnite.ps1 - Nivel "Fortnite": latencia de entrada minima
#
#  Esto es SOLO la parte que Windows puede automatizar. La mitad importante
#  del trabajo esta en programas externos: panel de NVIDIA, ajustes dentro de
#  Fortnite, BIOS y el OSD del monitor.  Ver GUIA-FORTNITE.md.
#
#  Nada de lo que hay aqui oculta ni intercepta nada frente a Easy Anti-Cheat:
#  son ajustes estandar de Windows por APIs publicas. No se inyecta codigo en
#  el proceso del juego ni se modifica ningun archivo suyo.
# ============================================================================

$script:Catalogo += @(

# -------------------------------------------------------------------- red ---
New-Tweak -Id 'fn-ethernet' -Nivel 'Fortnite','Valorant' -Categoria 'Red' `
  -Nombre 'Reactivar la tarjeta Ethernet' `
  -Descripcion 'Si tu Ethernet esta desactivada en el Administrador de dispositivos, la vuelve a habilitar. Pasar de Wi-Fi a cable quita entre 5 y 30 ms de ping y, sobre todo, elimina los picos. Es la mejora mas grande de toda esta pestana.' `
  -Nota 'Despues de reactivarla tienes que enchufar el cable de red al PC.' `
  -Actions @(
    @{ Kind='Script'; UndoId='ethernet-desactivar'
       Test={
          $d = Get-PnpDevice -Class Net -EA SilentlyContinue | Where-Object {
                 $_.FriendlyName -notmatch 'Wi-?Fi|Wireless|Virtual|Bluetooth|Loopback|WAN Miniport' }
          if (-not $d) { return $true }
          -not ($d | Where-Object { $_.Status -eq 'Error' })
       }
       Do={
          $d = Get-PnpDevice -Class Net -EA SilentlyContinue | Where-Object {
                 $_.Status -eq 'Error' -and
                 $_.FriendlyName -notmatch 'Wi-?Fi|Wireless|Virtual|Bluetooth|Loopback|WAN Miniport' }
          if (-not $d) { Write-Opt '  no hay ninguna tarjeta Ethernet desactivada' 'INFO'; return }
          foreach ($x in $d) {
             Enable-PnpDevice -InstanceId $x.InstanceId -Confirm:$false -EA SilentlyContinue
             Write-Opt "  reactivada: $($x.FriendlyName)" 'OK'
          }
          Write-Opt '  ahora enchufa el cable de red al PC' 'WARN'
       } }
  )

New-Tweak -Id 'fn-nic-latencia' -Nivel 'Fortnite','Valorant' -Categoria 'Red' `
  -Nombre 'Quitar el buffering de la tarjeta de red' `
  -Descripcion 'Desactiva Interrupt Moderation (la tarjeta agrupa paquetes antes de avisar a la CPU) y los ahorros Energy-Efficient Ethernet. Baja unos pocos ms la latencia de red y la vuelve mucho mas estable.' `
  -Riesgo 'Bajo' `
  -Nota 'Al revertir se vuelve a "Enabled", que es el valor de fabrica de estas tarjetas.' `
  -Actions @(
    @{ Kind='Script'; UndoId='nic-latencia-restaurar'
       Test={ $false }
       Do={
          foreach ($a in (Get-NetAdapter -Physical -EA SilentlyContinue | Where-Object Status -eq 'Up')) {
             foreach ($prop in 'Interrupt Moderation','Energy-Efficient Ethernet','Green Ethernet','Ultra Low Power Mode') {
                if (Get-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $prop -EA SilentlyContinue) {
                   Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $prop `
                       -DisplayValue 'Disabled' -NoRestart -EA SilentlyContinue
                   Write-Opt "  $($a.Name): $prop -> Disabled" 'INFO'
                }
             }
             Restart-NetAdapter -Name $a.Name -EA SilentlyContinue
          }
       } }
  )

# --------------------------------------------------------------- graficos ---
New-Tweak -Id 'fn-gpu-dedicada' -Nivel 'Fortnite' -Categoria 'Graficos' `
  -Nombre 'Forzar la GPU dedicada para Fortnite' `
  -Descripcion 'Tu Ryzen trae graficos Radeon integrados. Si Windows enruta Fortnite por la iGPU aunque sea en parte, pierdes rendimiento sin enterarte. Esto fija la tarjeta dedicada de forma explicita.' `
  -Actions @(
    @{ Kind='Script'; UndoId='gpu-preferencia-quitar'
       Test={
          if (-not $script:FortniteExe) { return $true }
          $v = Get-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $script:FortniteExe -EA SilentlyContinue
          [bool]($v -and "$($v.$($script:FortniteExe))" -match 'GpuPreference=2')
       }
       Do={
          if (-not $script:FortniteExe) { Write-Opt '  Fortnite no encontrado, se omite' 'WARN'; return }
          Set-RegValue 'HKCU\Software\Microsoft\DirectX\UserGpuPreferences' $script:FortniteExe 'String' 'GpuPreference=2;'
          Write-Opt "  GPU dedicada fijada para $($script:FortniteExe)" 'OK'
       } }
  )

New-Tweak -Id 'fn-ventana-optimizada' -Nivel 'Fortnite','Valorant' -Categoria 'Graficos' `
  -Nombre 'Optimizaciones para juegos en ventana' `
  -Descripcion 'Funcion de Windows 11 que permite presentacion directa en ventana sin bordes, saltandose una copia del compositor. Quita del orden de un fotograma de latencia si no juegas en pantalla completa exclusiva.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\DirectX\UserGpuPreferences'; Name='DirectXUserGlobalSettings'; Type='String'; Value='SwapEffectUpgradeEnable=1;' }
  )

New-Tweak -Id 'fn-sin-fso' -Nivel 'Fortnite' -Categoria 'Graficos' -PorDefecto $false `
  -Nombre 'Desactivar optimizaciones de pantalla completa en Fortnite' `
  -Descripcion 'Fuerza pantalla completa exclusiva de verdad, el camino mas corto hasta el monitor. Con un panel de 480 Hz la diferencia es medible.' `
  -Riesgo 'Bajo' `
  -Nota 'Desmarcado porque depende del caso: en exclusiva pierdes el Alt-Tab instantaneo. Pruebalo y mide con FrameView antes de dejarlo puesto.' `
  -Actions @(
    @{ Kind='Script'; UndoId='fso-restaurar'
       Test={
          if (-not $script:FortniteExe) { return $true }
          $v = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -Name $script:FortniteExe -EA SilentlyContinue
          [bool]($v -and "$($v.$($script:FortniteExe))" -match 'DISABLEDXMAXIMIZEDWINDOWEDMODE')
       }
       Do={
          if (-not $script:FortniteExe) { Write-Opt '  Fortnite no encontrado, se omite' 'WARN'; return }
          Set-RegValue 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' $script:FortniteExe 'String' '~ DISABLEDXMAXIMIZEDWINDOWEDMODE'
          Write-Opt '  pantalla completa exclusiva forzada para Fortnite' 'OK'
       } }
  )

# ---------------------------------------------------------------- entrada ---
New-Tweak -Id 'fn-raton-sin-aceleracion' -Nivel 'Fortnite','Valorant' -Categoria 'Entrada' `
  -Nombre 'Quitar la aceleracion del raton' `
  -Descripcion 'Desactiva "Mejorar la precision del puntero". Con aceleracion, el mismo movimiento fisico gira distinto segun la velocidad y la memoria muscular nunca termina de formarse. Imprescindible para apuntar.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Control Panel\Mouse'; Name='MouseSpeed';      Type='String'; Value='0' },
    @{ Kind='Reg'; Path='HKCU\Control Panel\Mouse'; Name='MouseThreshold1'; Type='String'; Value='0' },
    @{ Kind='Reg'; Path='HKCU\Control Panel\Mouse'; Name='MouseThreshold2'; Type='String'; Value='0' }
  )

New-Tweak -Id 'fn-usb-sin-suspension' -Nivel 'Fortnite','Valorant' -Categoria 'Entrada' `
  -Nombre 'Desactivar suspension selectiva USB' `
  -Descripcion 'Impide que Windows duerma puertos USB. Evita que el raton pierda informes y que el primer movimiento tras unos segundos quieto llegue tarde.' `
  -Actions @(
    @{ Kind='Script'; UndoId='usb-suspend-on'
       Test={ $false }
       Do={
          powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
          powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
          powercfg /setactive SCHEME_CURRENT 2>$null
          Write-Opt '  suspension selectiva USB desactivada' 'OK'
       } }
  )

# ---------------------------------------------------------------- sistema ---
New-Tweak -Id 'fn-modo-juego' -Nivel 'Fortnite','Valorant' -Categoria 'Sistema' `
  -Nombre 'Activar Modo juego de Windows' `
  -Descripcion 'Suena a placebo pero no lo es: evita que Windows Update y las tareas en segundo plano se metan en mitad de una partida. Microsoft y NVIDIA lo recomiendan activo junto con Reflex.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\GameBar'; Name='AllowAutoGameMode';   Type='DWord'; Value=1 },
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\GameBar'; Name='AutoGameModeEnabled'; Type='DWord'; Value=1 }
  )

New-Tweak -Id 'fn-sin-power-throttling' -Nivel 'Fortnite','Valorant' -Categoria 'Sistema' `
  -Nombre 'Desactivar limitacion de energia de procesos' `
  -Descripcion 'Windows baja la frecuencia de los procesos que cree secundarios. Con un 9800X3D enchufado a la corriente no hay razon para que nada se frene.' `
  -Riesgo 'Bajo' -Reinicio `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; Name='PowerThrottlingOff'; Type='DWord'; Value=1 }
  )

New-Tweak -Id 'fn-sin-notificaciones' -Nivel 'Fortnite','Valorant' -Categoria 'Sistema' `
  -Nombre 'Silenciar notificaciones en pantalla completa' `
  -Descripcion 'Evita que salte un aviso en mitad de una pelea. Ademas de la distraccion, una notificacion provoca un tiron del compositor de escritorio.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name='NOC_GLOBAL_SETTING_TOASTS_ENABLED_WHEN_FULLSCREEN'; Type='DWord'; Value=0 }
  )

New-Tweak -Id 'fn-teclas-accesibilidad' -Nivel 'Fortnite','Valorant' -Categoria 'Entrada' `
  -Nombre 'Desarmar Filtro de teclas y Teclas especiales' `
  -Descripcion 'Filter Keys, Sticky Keys, Toggle Keys y Mouse Keys estan apagadas, pero su ATAJO sigue armado: mantener Shift derecho 8 segundos o pulsar Shift 5 veces las enciende en mitad de una partida, y Filter Keys si introduce retardo de teclado real. Esto desactiva los atajos sin quitarle la accesibilidad a quien la necesite.' `
  -Nota 'Esto es lo que buscan las guias cuando dicen "desactiva FilterKeys". Las funciones siguen disponibles desde Configuracion; solo deja de haber activacion accidental.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKCU\Control Panel\Accessibility\Keyboard Response'; Name='Flags'; Type='String'; Value='122' },
    @{ Kind='Reg'; Path='HKCU\Control Panel\Accessibility\StickyKeys';        Name='Flags'; Type='String'; Value='506' },
    @{ Kind='Reg'; Path='HKCU\Control Panel\Accessibility\ToggleKeys';        Name='Flags'; Type='String'; Value='58'  },
    @{ Kind='Reg'; Path='HKCU\Control Panel\Accessibility\MouseKeys';         Name='Flags'; Type='String'; Value='58'  }
  )

New-Tweak -Id 'fn-timer-global' -Nivel 'Fortnite','Valorant' -Categoria 'Sistema' -PorDefecto $false `
  -Nombre 'Resolucion de temporizador global (lo que hacen las apps TimerResolution)' `
  -Descripcion 'Desde Windows 11 22H2 la resolucion del temporizador es POR PROCESO: una app externa que pida 0,5 ms se lo aplica solo a si misma, no al juego. Por eso esas herramientas ya no hacen nada en tu build. Esta clave restaura el comportamiento global antiguo, que es lo unico que les daba efecto.' `
  -Riesgo 'Medio' -Reinicio `
  -Nota 'Desmarcado a proposito. Fortnite ya pide la resolucion que necesita; forzarla global puede empeorar el frame pacing. Si lo pruebas, MIDE la PCL con FrameView antes y despues: si no baja, revierte.' `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name='GlobalTimerResolutionRequests'; Type='DWord'; Value=1 }
  )
)

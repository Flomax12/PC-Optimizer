# PC Optimizer

Optimizador de Windows 11 con cinco niveles y reversión completa. **No toca la estética de Windows 11.**

## Cómo se usa

Doble clic en **`Iniciar.bat`** → acepta el UAC → se abre la interfaz.

Orden recomendado la primera vez:

1. **Crear punto de restauración** (botón abajo a la izquierda)
2. Pestaña **Básico** → *Aplicar seleccionados*
3. Usa el PC un par de días
4. Si todo va bien, pasa a **Medio**, y sólo después a **Avanzado**

No apliques los tres niveles de golpe: si algo se rompe no sabrás cuál fue.

## Lo que NUNCA se toca

Estas cosas están fuera del catálogo a propósito, no hay forma de desactivarlas desde la app:

- Animaciones de ventanas, minimizar/maximizar, animaciones del menú Inicio
- Transparencias, efecto Mica y Acrylic
- Esquinas redondeadas
- Snap Layouts y Escritorios virtuales
- Cualquier ajuste de *Efectos visuales* (`VisualFXSetting`)
- Windows Defender
- Windows Update
- Windows Search (la búsqueda del menú Inicio sigue indexando)

## Los tres niveles

| Nivel | Qué hace | Riesgo |
|---|---|---|
| **Básico** | Limpieza de temporales y caché, quitar anuncios y sugerencias, plan de energía, Game DVR, retardo de arranque | Ninguno |
| **Medio** | Telemetría, tareas programadas de diagnóstico, apps en segundo plano, servicios sin uso, bloatware, compactar WinSxS | Bajo |
| **Avanzado** | Plan Rendimiento máximo, HAGS, prioridad de primer plano, perfil de juegos, SysMain/Prefetch, NTFS, hibernación, VBS | Requiere criterio |
| **Fortnite** | Latencia de entrada mínima: Ethernet, buffering de red, GPU dedicada, ratón, USB, Modo juego | Bajo |
| **Valorant** | Todo lo anterior de latencia + diagnóstico y reparación de Vanguard, GPU dedicada, autoarranque de Riot | Bajo |

> Los ajustes de latencia comunes (red, ratón, USB, FilterKeys, Modo juego) aparecen en **las dos** pestañas de juego: es el mismo cambio, aplicarlo en una lo marca en la otra.

> El nivel **Fortnite** es solo la mitad de Windows. La otra mitad está en programas externos — panel de NVIDIA, ajustes del juego, BIOS y OSD del monitor — y está en **[GUIA-FORTNITE.md](GUIA-FORTNITE.md)**, con una sección dedicada a los tweaks populares que NO funcionan y por qué.

Dentro de cada nivel, lo que viene **marcado por defecto** es lo recomendado. Lo desmarcado tiene alguna contrapartida y trae una advertencia explicando cuál.

## Reversión

Cada cambio guarda en `data/backup.json` el valor **exacto** que había antes de tocarlo: valor de registro, tipo de inicio del servicio, estado de la tarea programada. La pestaña **Revertir** los restaura uno a uno, o todos de golpe.

Dos excepciones:

- **Quitar apps preinstaladas**: la desinstalación no se deshace desde aquí. Se reinstalan desde la Microsoft Store.
- **Limpiezas** (temporales, papelera, WinSxS): borran archivos, no hay nada que restaurar.

Si algo va muy mal, el punto de restauración del sistema es la red de seguridad: *Configuración → Sistema → Recuperación → Recuperación avanzada*.

## Cosas que conviene saber

- **Desactivar Inicio rápido** (nivel Medio) es probablemente lo más útil de toda la app si venías con "errores raros". Fast Startup nunca apaga del todo el kernel, y arrastra estados corruptos de driver entre sesiones.
- **Desactivar SysMain/Prefetch** sólo tiene sentido si el sistema está en SSD NVMe. En disco mecánico empeora las cosas.
- **VBS / Integridad de memoria** da entre 5% y 15% de FPS, pero baja la protección del kernel y algunos anticheat (Valorant, Faceit) lo exigen activo. Por eso viene desmarcado.
- Los cambios marcados **"requiere reinicio"** no hacen nada hasta que reinicies.

## Uso por consola

```powershell
.\PCOptimizer.ps1 -Listar                  # ver el catálogo y qué está aplicado
.\PCOptimizer.ps1 -Nivel Basico -Aplicar   # aplicar los recomendados de un nivel
.\PCOptimizer.ps1 -Nivel Fortnite -Aplicar # nivel de baja latencia
.\PCOptimizer.ps1 -RevertirTodo            # deshacer todo
.\Probar.ps1                               # prueba de humo, no toca el sistema
```

## Estructura

```
PC-Optimizer/
  Iniciar.bat          lanzador con elevación
  PCOptimizer.ps1      punto de entrada (GUI y consola)
  Probar.ps1           pruebas, no modifican nada
  GUIA-FORTNITE.md     ajustes externos: NVIDIA, juego, BIOS, monitor
  GUIA-VALORANT.md     Vanguard, errores VAN, audio, ajustes del juego
  instalador/          genera el .exe para distribuir
  src/
    Core.ps1           motor: respaldo, aplicación, reversión, logging
    Tweaks.ps1         catálogo (básico, medio, avanzado)
    Tweaks.Fortnite.ps1  catálogo del nivel Fortnite
    Tweaks.Valorant.ps1  catálogo del nivel Valorant
    Gui.ps1            interfaz WPF
  data/backup.json     estado anterior de todo lo aplicado  ← no lo borres
  logs/                un registro por sesión
```

> `data/backup.json` es lo que permite revertir. Si lo borras, pierdes la posibilidad de deshacer los cambios desde la app.

## Añadir tus propias optimizaciones

En `src/Tweaks.ps1`, dentro del array `$script:Catalogo`:

```powershell
New-Tweak -Id 'mi-ajuste' -Nivel 'Medio' -Categoria 'Rendimiento' `
  -Nombre 'Lo que hace' `
  -Descripcion 'Explicación honesta, incluyendo la contrapartida.' `
  -Riesgo 'Bajo' -PorDefecto $false `
  -Actions @(
    @{ Kind='Reg'; Path='HKLM\SOFTWARE\Ruta'; Name='Valor'; Type='DWord'; Value=1 }
  )
```

Tipos de acción: `Reg`, `Service`, `Task`, `Script` (con `Do`, `Test` y `UndoId`) y `Cleanup`. Las tres primeras se respaldan y revierten solas; `Script` necesita que declares un `UndoId` que exista en `$script:UndoScripts`.

Después de editar, ejecuta `.\Probar.ps1` para comprobar que el catálogo sigue coherente.

## Crear el instalador para otro PC

```powershell
.\instalador\Construir.ps1
```

Genera `instalador\PCOptimizer-Setup.exe` (~57 KB): un ejecutable autocontenido con la app embebida dentro. No descarga nada y se compila con `csc.exe`, el compilador de C# que ya trae Windows.

Antes de empaquetar ejecuta `Probar.ps1` sobre la copia preparada: **si las pruebas fallan, no genera el instalador**. Nunca incluye `dataackup.json` ni los registros, que son de cada equipo.

El `.exe` instala en `%LOCALAPPDATA%\PC-Optimizer` sin pedir administrador y crea accesos directos. La app pide elevación por su cuenta al ejecutarse.

> Windows mostrará un aviso de SmartScreen porque el ejecutable no está firmado digitalmente. Es lo normal en software sin certificado de pago: *Más información → Ejecutar de todas formas*.

## Requisitos

Windows 11, PowerShell 5.1 (el que trae Windows) y permisos de administrador.
Los archivos `.ps1` deben guardarse en **UTF-8 con BOM** o los acentos romperán el script.

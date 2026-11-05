# Fortnite · 0 delay — programas externos

La pestaña **Fortnite** de PC Optimizer cubre la parte de Windows. Esta guía cubre el resto, que es donde está la mayoría de los milisegundos.

Escrita para tu equipo concreto: **Ryzen 7 9800X3D · RTX 5070 · 62 GB · monitor 480 Hz a 1920×1440 · Fortnite en `D:\Fortnite`**.

---

## Orden de impacto

No hagas esto en orden aleatorio. De mayor a menor ganancia real:

| # | Qué | Ganancia aprox. | Dónde |
|---|---|---|---|
| 1 | **Pasar de Wi-Fi a cable** | 5–30 ms y adiós a los picos | Pestaña Fortnite + cable |
| 2 | **Reflex On + Boost** | 10–30 ms con la GPU al límite | Dentro de Fortnite |
| 3 | **Modo Rendimiento** | sube FPS → baja latencia | Dentro de Fortnite |
| 4 | **Config correcta de V-Sync / G-SYNC** | 5–20 ms si está mal | Panel NVIDIA |
| 5 | **Instant Mode del monitor** | 1–5 ms | OSD del monitor |
| 6 | **Overlays fuera** (Discord, Epic, ShadowPlay) | 1–8 ms y tirones | Cada programa |
| 7 | **Ratón a 1000 Hz** | 0,5–1 ms | Software del ratón |
| 8 | BIOS: EXPO + Resizable BAR | FPS, no latencia directa | BIOS |

Todo lo que esté por debajo del punto 8 es ruido. Si alguien te vende "0 delay" con un .bat de 300 líneas, te está vendiendo humo.

---

## 1. Red — tu problema número uno ahora mismo

Estás jugando por **Wi-Fi 6E**. Da igual lo bien afinado que esté el PC: el Wi-Fi mete jitter que no puedes controlar.

Y hay algo mejor: tu placa ASUS tiene un **Realtek 2.5 GbE que está desactivado** (código de error 22 en el Administrador de dispositivos). No le falta driver — está apagado, probablemente desde la instalación "optimizada" anterior.

**Qué hacer:**

1. Pestaña **Fortnite** → marca *Reactivar la tarjeta Ethernet* → Aplicar.
2. Enchufa el cable del router al PC.
3. Desactiva el Wi-Fi para que Windows no reparta tráfico entre los dos.
4. Marca también *Quitar el buffering de la tarjeta de red*.

Comprueba después:

```bash
ping -n 20 fortnite.com
```

Lo que importa no es la media, es la **diferencia entre el mínimo y el máximo**. Por cable debería moverse en 1–3 ms; por Wi-Fi verás saltos de 20–80 ms.

> **Región de matchmaking:** dentro de Fortnite, fija la región a la de menor ping en vez de "Automática". Esto pesa más que cualquier tweak de Windows.

---

## 2. NVIDIA — driver y panel

### Driver

Instala el **NVIDIA App** desde `nvidia.com` (ya sustituyó a GeForce Experience). En la instalación elige **Personalizada → Instalación limpia**.

**DDU (Display Driver Uninstaller)** solo lo necesitas si vienes de un driver corrupto. Acabas de formatear, así que no hace falta. Si algún día lo usas: modo seguro, desinstalar, reiniciar, instalar limpio.

Dentro de NVIDIA App, **desactiva**:
- Superposición en el juego (overlay)
- Repetición instantánea / ShadowPlay — graba todo el rato y cuesta FPS y latencia

### Panel de control NVIDIA → Administrar configuración 3D

Hazlo en la pestaña **Configuración del programa**, eligiendo `FortniteClient-Win64-Shipping.exe`:

| Ajuste | Valor | Por qué |
|---|---|---|
| Modo de baja latencia | **Activado** (no "Ultra") | Fortnite tiene Reflex; Reflex manda y Ultra solo estorba |
| Modo de administración de energía | **Preferir rendimiento máximo** | evita que la GPU baje de reloj entre rondas |
| Tecnología de monitor | **G-SYNC compatible**, si tu panel lo soporta | |
| Sincronización vertical | ver abajo | |
| Filtrado de textura · Calidad | **Alto rendimiento** | |
| Subprocesos preparados | **Activado** | |
| Mejora de nitidez de imagen | **Desactivado** | pasa de post-proceso |

### V-Sync: elige UNA de las dos configuraciones

**A — G-SYNC con cero tearing (recomendada si tu monitor tiene G-SYNC):**
- G-SYNC: Activado
- V-Sync en el panel NVIDIA: **Activado**
- V-Sync dentro de Fortnite: Desactivado
- Reflex: **Activado + Impulso**

Suena contradictorio activar V-Sync para bajar latencia, pero Reflex capa los FPS justo por debajo del refresco y evita que la cola de V-Sync se llene. Es la configuración que recomiendan NVIDIA y Blur Busters.

**B — Sin G-SYNC, a pelo:**
- V-Sync: Desactivado en ambos sitios
- Límite de FPS: ilimitado
- Reflex: Activado + Impulso

Tendrás tearing, pero es la latencia más baja posible. Mucho competitivo juega así.

Prueba las dos y **mide** (sección 7). No te fíes de la sensación.

### Tu resolución 1920×1440

Estás en 4:3 estirado. Para que se estire de verdad y no salga con bandas negras:

Panel NVIDIA → **Ajustar tamaño y posición del escritorio**:
- Modo de escala: **Pantalla completa**
- Realizar ajuste de escala en: **GPU**
- Marcar **"Reemplazar el modo de escalado establecido por juegos y programas"**

Escalar en la GPU en vez de en el monitor también ahorra un pelín de latencia.

---

## 3. Dentro de Fortnite

Menú → Configuración → Vídeo:

| Ajuste | Valor |
|---|---|
| Modo de ventana | **Pantalla completa** (nunca "Ventana sin bordes" en competitivo) |
| Resolución | 1920×1440 |
| Modo de renderizado | **Rendimiento** |
| Límite de fotogramas | **Ilimitado** (o 480 si usas la config A) |
| **Reflex de baja latencia** | **Activado + Impulso** ← el ajuste más importante de toda la lista |
| Resolución 3D | 100 % |
| Sombras, Texturas, Efectos, Posprocesado | Bajo / Desactivado |
| Desenfoque de movimiento | **Desactivado** |
| Mostrar FPS | Activado |

**Modo Rendimiento** es feo pero es lo que te deja empujar hacia los 480 FPS que tu monitor puede mostrar. Con DirectX 12 se ve mucho mejor y pierdes FPS; si te sobran fotogramas, DX12 es una opción legítima.

En **Entrada**, comprueba que no quede ninguna sensibilidad de mira con aceleración activada.

---

## 4. Monitor — el OSD, no Windows

Entra con los botones físicos del monitor y busca:

- **Instant Mode / Low Latency / Through Mode** → **Activado**. Salta el escalador interno del panel.
- **Overdrive / Response Time** → el nivel medio, no el máximo. El máximo mete *overshoot* (estelas invertidas), que se ve peor que un poco de ghosting.
- **Dynamic Contrast, Black eQualizer, modos "Game"/"FPS" con post-proceso** → **Desactivados**. Cada filtro añade retardo de procesado.
- **HDR** → desactivado en competitivo.
- **Variable refresh / Adaptive-Sync** → activado solo si usas la config A.

Y confirma en Windows que estás realmente a 480 Hz:
Configuración → Sistema → Pantalla → Configuración de pantalla avanzada.

---

## 5. Ratón y teclado

- **Tasa de sondeo: 1000 Hz.** Con tu 9800X3D puedes probar 2000, 4000 u 8000 Hz si el ratón lo permite, pero por encima de 1000 Hz la ganancia es de décimas de ms y algunos juegos dan tirones. Sube de uno en uno y mide.
- Guarda el perfil en la **memoria interna (onboard)** del ratón. Así puedes cerrar G Hub / Synapse y no tener su proceso corriendo.
- **Velocidad del puntero en Windows: 6/11**, la muesca central. Cualquier otro valor hace que Windows interpole y te come píxeles.
- Aceleración del ratón: ya la tienes desactivada. La pestaña Fortnite la mantiene así.
- Cable USB directo a un puerto **trasero** de la placa, no a un hub ni al frontal de la caja.

---

## 6. BIOS

Reinicia y entra con `Supr`. En tu ASUS:

- **EXPO / DOCP: Activado.** Sin esto tu RAM corre a 4800 MT/s en vez de a su velocidad real. Es la mayor ganancia de la BIOS.
- **Resizable BAR: Activado.**
- **Above 4G Decoding: Activado** (necesario para ReBAR).
- **PBO (Precision Boost Overdrive):** opcional. En un 9800X3D el margen es pequeño; si lo tocas, vigila temperaturas.
- **C-States globales: déjalos activados.** En Ryzen moderno no añaden latencia apreciable y desactivarlos sube temperatura y consumo para nada.
- Si el ratón o el teclado se "duermen": busca **ErP Ready** y desactívalo.

Después de activar EXPO, haz una pasada de memtest o deja el PC un rato con carga: un perfil EXPO inestable provoca justo los "errores raros" que te hicieron formatear.

---

## 7. Medir, que es lo que separa el 0 delay del placebo

Sin medir, todo esto es fe. Dos herramientas:

### NVIDIA FrameView (gratis, de NVIDIA)

Es la que quieres. Como Fortnite tiene Reflex, FrameView puede leer la **PC Latency (PCL)** real en milisegundos sin hardware extra.

Método:
1. Abre FrameView con el overlay activado.
2. Entra en el **Campo de batalla** (no al lobby: no es representativo).
3. Apunta la PCL media durante 60 segundos moviéndote y disparando.
4. Cambia **un solo ajuste**.
5. Repite.

Si un cambio no mueve la PCL, no estaba haciendo nada. Revierte y sigue.

### Reflex Latency Analyzer

Mide la latencia *completa*, desde el clic físico hasta el píxel. Necesita un monitor G-SYNC con el módulo y un ratón compatible. Si tu monitor lo trae, es lo mejor que hay; si no, FrameView te sirve de sobra.

**Referencia de a dónde llegar:** con tu hardware, por cable, Modo Rendimiento, Reflex On+Boost y FPS cerca de 480, una PCL de **8–15 ms** es un resultado excelente. Por encima de 25 ms, algo está mal configurado.

---

## 8. Las apps de "0 delay", una por una

Comprobado en tu máquina, no copiado de un foro. Ninguna de las cinco está instalada todavía.

| App | Veredicto | Por qué |
|---|---|---|
| **FilterKeys** | ✅ **Hazlo** — ya está en la app | Era real, y en tu PC estaba mal |
| **TimerResolution** | ⚠️ Inútil como app · ahora nativo | Win11 lo cambió a por-proceso |
| **ParkControl** | ❌ Redundante | Tu plan de energía ya lo hace |
| **TCP Optimizer** | ❌ No aplica | Fortnite es UDP |
| **GameFirst VI** | ❌ Contraproducente | Instala un driver de filtro de red |

### FilterKeys — la única que tenías razón en pedir

Y en tu PC estaba **medio mal**. Los valores que leí:

```
Keyboard Response (FilterKeys)  Flags = 126
StickyKeys                      Flags = 510
ToggleKeys                      Flags = 62
MouseKeys                       Flags = 62
```

Las cuatro están **apagadas** (los números son pares, el bit 0 es el de "encendido"). Pero el **bit 4 — el del atajo de teclado — está activo en las cuatro**. Eso significa que mantener Shift derecho 8 segundos, o pulsar Shift 5 veces seguidas, te enciende Filter Keys o Sticky Keys **en mitad de una partida**. Y Filter Keys sí introduce retardo de teclado de verdad.

Ya está en la pestaña Fortnite como *Desarmar Filtro de teclas y Teclas especiales*: pone 122 / 506 / 58 / 58, que es lo mismo con el atajo desarmado. Reversible como todo lo demás.

### TimerResolution — ya no hace lo que crees

Desde **Windows 11 22H2**, Microsoft cambió la resolución del temporizador a **por proceso**. Una app externa que pida 0,5 ms se lo aplica **solo a sí misma**; Fortnite sigue con la suya. Por eso esas herramientas funcionaban en Windows 10 y hoy no hacen nada.

Lo comprobé en tu registro:

```
GlobalTimerResolutionRequests = no definido  →  comportamiento por proceso
```

Lo único que devuelve el efecto global es esa clave. Está en la pestaña Fortnite como *Resolución de temporizador global*, **desmarcada a propósito**: Fortnite ya pide la resolución que necesita, y forzarla global puede empeorar el frame pacing. Si la pruebas, mide la PCL con FrameView antes y después. Si no baja, reviértela.

Lo importante: no necesitas ninguna app residente para esto. Es una clave del registro.

### ParkControl — tu plan de energía ya lo hace

ParkControl desactiva el *core parking*. Pero el plan **Alto rendimiento** que ya tienes activo (lo puso el nivel Básico) lo deja desactivado por diseño, igual que Rendimiento máximo del nivel Avanzado.

Verifícalo tú mismo en una consola **como administrador**:

```bash
powercfg /q SCHEME_CURRENT SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318583
```

Si el valor de CA es `0x00000064` (100 decimal), no hay nada que aparcar y ParkControl no tiene trabajo.

Además, ParkControl y Process Lasso son del mismo fabricante y su utilidad real está en los Ryzen de **doble CCD** (7950X3D y similares), donde hay que fijar el juego al chiplet con caché 3D. Tu **9800X3D es de un solo CCD**: los 8 núcleos tienen la caché. No hay nada que repartir.

### TCP Optimizer — optimiza el protocolo equivocado

**Fortnite transmite por UDP.** TCP Optimizer ajusta RWIN, auto-tuning, control de congestión y Nagle, que son **todo cosas de TCP**. No toca el camino por el que viaja tu partida.

Lo mismo con las claves `TcpAckFrequency` y `TCPNoDelay` que salen en todas las guías: solo afectan a TCP. Cero efecto en tu ping de Fortnite.

Hay un segundo motivo para no instalarlo: su preajuste "Optimal" escribe un montón de valores pensados originalmente para Windows XP/7. En Windows 11 moderno, varios son contraproducentes y otros los ignora el sistema. Es justo el tipo de cambio masivo y opaco que te dejó el PC como lo tenías antes de formatear.

Lo único que de verdad baja latencia de red en tu tarjeta ya está en la app: *Quitar el buffering de la tarjeta de red* (Interrupt Moderation y Energy-Efficient Ethernet).

### GameFirst VI — el único que puede hacerte daño

Es el QoS de ASUS. Prioriza el tráfico del juego frente al resto de tu red. Dos problemas:

1. **No tienes nada que priorizar.** El QoS sirve cuando alguien está saturando la línea: descargas grandes, otro PC con streaming 4K. Si el único tráfico pesado es tu partida, no hay nada que poner por delante de nada.
2. **Instala un driver de filtro de red** que se mete en la pila TCP/IP. Eso puede dar microcortes, incompatibilidades y es la clase de componente que conviene no tener corriendo bajo un anticheat.

Si algún día de verdad necesitas QoS porque compartís la conexión, hazlo **en el router**, priorizando la IP de tu PC. Ahí no hay driver de por medio.

### Y ya que estamos: otros tres que te van a recomendar

**ISLC (Intelligent Standby List Cleaner).** Resuelve un problema de RAM saturada. Tienes **62 GB**. No lo instales.

**MSI mode forzado en la GPU.** Los drivers NVIDIA modernos ya lo activan solos. Tocar `DeviceParameters` a mano solo te expone a un arranque sin vídeo.

**Prioridad "Alta" permanente vía IFEO.** Poner Fortnite por encima del resto suena bien hasta que le roba tiempo al compositor de escritorio y al audio y te genera tirones. Las claves IFEO son además un vector conocido de secuestro de procesos: no merece la pena llamar la atención del anticheat a cambio de nada.

**Desactivar Windows Defender.** Ganancia nula en Fortnite y te quedas sin protección. Si acaso, añade `D:\Fortnite` a las exclusiones del análisis en tiempo real: eso sí ahorra algo de I/O y son dos clics.

**"Debloaters" agresivos** del estilo del que traía tu instalación anterior. Ahí empezó todo esto. Quitar WinSxS a mano, borrar servicios en vez de desactivarlos o arrancar paquetes del sistema produce justo los errores irreparables que te obligaron a formatear. La app que tienes desactiva y **guarda el valor anterior**; nunca borra.

---

## 9. Overlays y programas de fondo

Cada overlay que se engancha a DirectX añade latencia de presentación:

| Programa | Qué desactivar |
|---|---|
| **Discord** | Superposición en el juego **y** Aceleración por hardware (Ajustes → Avanzado) |
| **Epic Games Launcher** | Overlay, y que no arranque con Windows (Administrador de tareas → Inicio) |
| **NVIDIA App** | Superposición y Repetición instantánea |
| **Steam** | Overlay en el juego |
| **MSI Afterburner / RTSS** | Úsalo solo para medir; quítalo del inicio automático |

Durante una partida, el Administrador de tareas debería estar prácticamente plano. Si ves algo al 5 % constante, averigua qué es.

---

## Resumen: qué instalar

| Programa | Para qué | ¿Imprescindible? |
|---|---|---|
| **NVIDIA App** | driver limpio y panel de control | Sí |
| **NVIDIA FrameView** | medir la latencia real | Sí — sin esto vas a ciegas |
| Software del ratón (G Hub / Synapse) | fijar 1000 Hz y guardar en memoria interna | Sí, una vez; luego lo cierras |
| **DDU** | solo si el driver se corrompe | No |
| MSI Afterburner + RTSS | medir FPS y frametime | Opcional |
| TimerResolution / ParkControl / TCP Optimizer / GameFirst VI / ISLC | — | **No**, ver sección 8 |

---

## Checklist de una sentada

```
[ ] Pestaña Fortnite de la app → Aplicar
[ ] Cable de red enchufado, Wi-Fi desactivado
[ ] Región de matchmaking fijada a la de menor ping
[ ] NVIDIA App instalado, overlay y repetición instantánea fuera
[ ] Panel NVIDIA configurado para FortniteClient-Win64-Shipping.exe
[ ] Escalado 4:3 en GPU con "reemplazar modo de escalado"
[ ] Fortnite: Rendimiento + Reflex On+Boost + pantalla completa
[ ] Monitor: Instant Mode on, overdrive medio, post-proceso off
[ ] Ratón a 1000 Hz, perfil en memoria interna, puerto trasero
[ ] BIOS: EXPO + Resizable BAR
[ ] Discord: overlay y aceleración por hardware fuera
[ ] FrameView: anotar la PCL de partida. Objetivo: 8-15 ms
```

Mide **antes** de empezar y **después** de terminar. Si no bajó, no lo hiciste por el motivo que creías.

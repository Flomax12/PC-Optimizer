# Valorant · 0 delay — guía completa

La pestaña **Valorant** de PC Optimizer cubre la parte de Windows. Esto cubre el resto.

Valorant es un juego muy distinto a Fortnite para optimizar: es **ligerísimo en GPU y pesado en CPU**. En la mayoría de equipos decentes vas a estar limitado por procesador, no por gráfica. Eso cambia qué merece la pena tocar.

---

## 0. Antes que nada: Vanguard

Vanguard es anticheat **a nivel de kernel**. Esto importa para un optimizador porque muchas "guías de FPS" desactivan cosas que Vanguard necesita, y luego el juego no arranca.

**Lo que dice la documentación oficial de Riot** (verificado en noviembre de 2026):

| Requisito | Estado | Fuente |
|---|---|---|
| **TPM 2.0** | **Obligatorio** | Error VAN 9001: *"This build of Vanguard requires TPM 2.0 to be enabled in order to play."* |
| **Secure Boot** | Paso oficial de solución | Error VAN 9005, paso 2 |
| **Integridad de memoria (VBS/HVCI)** | Riot pide comprobarla y activarla | Error VAN 9005, paso "Check Memory Integrity" |

> **Corrección a lo que te dije antes:** en la guía de Fortnite escribí que Valorant "exige VBS activo". Eso afirmaba más de lo que dice la documentación de Riot. Lo confirmado es que **TPM 2.0 sí es requisito duro**, y que **la solución oficial de Riot al error VAN 9005 es activar Secure Boot e Integridad de memoria**. No encontré ninguna página oficial que diga que el juego se niega a arrancar con VBS desactivado — pero sí que, si te sale ese error, el arreglo que Riot te da es encenderla.

**Traducción práctica:** si juegas a Valorant, LoL o TFT, piénsatelo dos veces antes de marcar *Desactivar VBS* en el nivel Avanzado. Y si ya lo hiciste y te sale VAN 9005, la pestaña Valorant tiene la reparación en un clic.

### Si el juego no arranca

Pestaña Valorant → **Comprobar requisitos de Vanguard**. No cambia nada: solo mira TPM, Secure Boot, Integridad de memoria y el servicio `vgc`, y escribe el diagnóstico en la pestaña Registro.

| Error | Qué significa | Arreglo |
|---|---|---|
| **VAN 9001** | Falta TPM 2.0 | BIOS → activa **fTPM** (AMD) o **PTT** (Intel) |
| **VAN 9005** | Problema con VBS / Secure Boot | Reparación de la pestaña Valorant + Secure Boot en BIOS |
| **VAN -81 / 68** | Servicio `vgc` caído o desactivado | *Reparar el servicio de Vanguard* |
| **VAN 1067** | Vanguard no arrancó con Windows | Reinicia; si sigue, reinstala Vanguard |

**Nunca** desactives el servicio `vgc` ni borres `vgk.sys` para "ganar rendimiento". Es lo primero que hacen los debloaters agresivos y lo primero que deja el juego inservible.

---

## 1. Dentro de Valorant — lo que más pesa

Ajustes → Vídeo.

### General

| Ajuste | Valor |
|---|---|
| Modo de visualización | **Pantalla completa** |
| Resolución | nativa del monitor (o estirada si juegas en 4:3) |
| **Limitar FPS siempre** | Activado, al valor que mantengas de forma **estable** |
| Limitar FPS en el menú | Activado, 60 — no necesitas 500 FPS en el menú |

El límite estable importa más que el máximo. Valorant oscilando entre 400 y 250 se siente peor que clavado en 240. Mira tu mínimo en una pelea de 5 y capa un poco por debajo.

### Calidad gráfica

Todo al mínimo, excepto lo que te quite información:

| Ajuste | Valor | Por qué |
|---|---|---|
| Calidad de material / textura / detalle | **Bajo** | |
| Calidad de interfaz | Bajo | |
| Viñeta | **Desactivada** | oscurece los bordes, que es por donde aparecen |
| VSync | **Desactivado** | |
| Suavizado de bordes | **MSAA 2x** o desactivado | el único que quizá quieras: los bordes dentados esconden cabezas a distancia |
| Filtrado anisotrópico | 1x–2x | |
| Mejorar claridad | Desactivado | |
| Experimental Sharpening | Desactivado | |
| **Bloom** | **Desactivado** | el fogonazo te ciega |
| **Distorsión** | **Desactivada** | las habilidades deforman la imagen |
| Proyectar sombras | **Desactivado** | menos carga de CPU y no da información útil |

### Estadísticas — actívalas

Ajustes → General → **Mostrar estadísticas del cliente**: pon FPS y latencia visibles. Sin esto no sabes si un cambio funcionó.

### Entrada (crítico)

- **Búfer de entrada sin procesar (Raw Input Buffer): Activado.** Lee los datos del ratón directamente del driver, saltándose la cola de mensajes de Windows. Es el ajuste de entrada más importante del juego.
- Sensibilidad: la que uses, pero **sin aceleración de Windows** (ya lo cubre la app).
- Repetición de sensibilidad al apuntar: déjala en 1 salvo que sepas por qué la cambias.

---

## 2. El audio importa más que los FPS

En Valorant las pisadas son información de combate. Esto vale más que 20 FPS extra y casi nadie lo toca.

**Windows → Configuración → Sistema → Sonido → tu dispositivo → Propiedades:**

- **Mejoras de audio: Desactivadas.** Cualquier procesado (graves, ecualizador, "virtualización") retrasa el sonido y deforma la dirección.
- **Audio espacial: Desactivado.** El motor de Valorant ya hace su propio HRTF; encima del de Windows, las pisadas se vuelven ambiguas.
- **Formato:** 16 bits, 48000 Hz. Más no te da nada en un juego.

**Dentro de Valorant** → Ajustes → Audio:
- Activa el **modo HRTF** si usas auriculares estéreo. Ese sí es el bueno.
- Baja la música del menú y sube el volumen de efectos.

Si tu auricular trae software propio (Logitech, SteelSeries, Razer) con ecualizador o "surround 7.1" por software: **apágalo**. Compite con el HRTF del juego.

---

## 3. NVIDIA

Panel de control → Configuración del programa → `VALORANT-Win64-Shipping.exe`:

| Ajuste | Valor |
|---|---|
| Modo de baja latencia | **Ultra** |
| Modo de administración de energía | Preferir rendimiento máximo |
| Sincronización vertical | Desactivada |
| Filtrado de textura · Calidad | Alto rendimiento |

**Diferencia con Fortnite:** Valorant **no tiene NVIDIA Reflex**. En la guía de Fortnite te dije que pusieras el modo de baja latencia en "Activado" porque Reflex manda. Aquí no hay Reflex, así que **Ultra sí es la opción correcta**: es lo más parecido a Reflex que puedes aplicar desde fuera.

Como estarás limitado por CPU, el efecto será menor que en un juego pesado de GPU, pero no cuesta nada.

---

## 4. Red

Valorant usa servidores a **128 tick**, el doble que la mayoría. Eso premia la estabilidad de la conexión mucho más que los FPS.

- **Cable, siempre.** Igual que en la guía de Fortnite.
- *Quitar el buffering de la tarjeta de red* en la app.
- Elige el servidor con menor ping a mano, no el automático.
- Valorant va por **UDP**: los tweaks de TCP (`TcpAckFrequency`, TCP Optimizer, "desactivar Nagle") no hacen nada. Igual que en Fortnite.

---

## 5. CPU — aquí sí estás limitado

Valorant es de los pocos competitivos que se benefician de forma clara de la CPU. Lo que importa:

- **EXPO / DOCP activado en BIOS.** En Valorant la latencia de memoria se nota en los mínimos. Es la mayor ganancia disponible.
- **Modo juego de Windows activado** (ya en la app).
- **Power throttling desactivado** (ya en la app).
- Cierra Chrome. En serio: cada pestaña con vídeo le roba tiempo de CPU al juego, y en un título limitado por CPU eso sale directo de tus mínimos.

Lo que **no** hace falta: ningún gestor de afinidad de núcleos. Valorant reparte bien y Windows lo planifica correctamente.

---

## 6. Checklist

```
[ ] Pestana Valorant de la app -> Comprobar requisitos de Vanguard
[ ] Si sale error VAN: arreglarlo con la tabla de la seccion 0
[ ] Aplicar la pestana Valorant
[ ] Cable de red, Wi-Fi desactivado
[ ] Servidor con menor ping elegido a mano
[ ] En el juego: pantalla completa + limite de FPS estable
[ ] Raw Input Buffer ACTIVADO
[ ] Vineta, Bloom, Distorsion y Sombras desactivados
[ ] Mostrar estadisticas del cliente activado
[ ] Mejoras de audio y audio espacial de Windows DESACTIVADOS
[ ] HRTF del juego activado (si usas auriculares)
[ ] Software del auricular: surround por software apagado
[ ] NVIDIA: modo de baja latencia en ULTRA (aqui no hay Reflex)
[ ] BIOS: EXPO activado
```

---

## 7. Lo que no vas a hacer

Todo lo de la **sección 8 de `GUIA-FORTNITE.md`** aplica igual: TimerResolution, ParkControl, TCP Optimizer, GameFirst VI e ISLC siguen sin servir. En Valorant hay dos añadidos:

**No toques Vanguard.** Ni el servicio, ni el driver, ni "retrasar su arranque". Lo único que consigues es no poder jugar.

**No desactives VBS a la ligera.** En Fortnite es un cambio de FPS contra seguridad. Aquí, además, es el paso que Riot te va a pedir deshacer si te sale VAN 9005.

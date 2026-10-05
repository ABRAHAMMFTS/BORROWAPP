---
name: BorrowApp
colors:
  surface: '#eafdfb'
  surface-dim: '#cbdedc'
  surface-bright: '#eafdfb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e4f8f5'
  surface-container: '#dff2f0'
  surface-container-high: '#d9ecea'
  surface-container-highest: '#d3e6e4'
  on-surface: '#0d1e1d'
  on-surface-variant: '#3f4947'
  inverse-surface: '#233332'
  inverse-on-surface: '#e1f5f2'
  outline: '#6f7977'
  outline-variant: '#bec9c7'
  surface-tint: '#1c6964'
  primary: '#004642'
  on-primary: '#ffffff'
  primary-container: '#0a5f5a'
  on-primary-container: '#90d6cf'
  inverse-primary: '#8dd3cc'
  secondary: '#7a5900'
  on-secondary: '#ffffff'
  secondary-container: '#fcc030'
  on-secondary-container: '#6d4f00'
  tertiary: '#00463f'
  on-tertiary: '#ffffff'
  tertiary-container: '#006057'
  on-tertiary-container: '#6fdccd'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a8f0e8'
  primary-fixed-dim: '#8dd3cc'
  on-primary-fixed: '#00201e'
  on-primary-fixed-variant: '#00504b'
  secondary-fixed: '#ffdea2'
  secondary-fixed-dim: '#f9bd2d'
  on-secondary-fixed: '#261900'
  on-secondary-fixed-variant: '#5c4200'
  tertiary-fixed: '#89f5e6'
  tertiary-fixed-dim: '#6bd8ca'
  on-tertiary-fixed: '#00201c'
  on-tertiary-fixed-variant: '#005049'
  background: '#eafdfb'
  on-background: '#0d1e1d'
  surface-variant: '#d3e6e4'
typography:
  display-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 34px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Bricolage Grotesque
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Figtree
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Figtree
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 19px
  label-lg:
    fontFamily: Figtree
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Figtree
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

# DESIGN.md · BorrowApp

Sistema visual de BorrowApp, app móvil (Android/iOS, vertical) para prestar y alquilar objetos dentro de comunidades cerradas. Todo el texto de la interfaz va en español de Colombia.

---

## 1. Idea de diseño: "Marea"

Lo que sale, vuelve. Prestar un objeto es una marea: el objeto se va con alguien y regresa al mismo punto central. El diseño se apoya en esa idea con tres decisiones:

1. **El color viene del Caribe colombiano, no de una app financiera.** Una laguna profunda como color de marca, un amarillo sol como señal de atención y neutros con un tinte verdoso, nunca grises fríos ni crema.
2. **Una sola figura firma: "El Encuentro".** Dos círculos que se cruzan (quien presta y quien recibe). El cruce forma una lente. Aparece en el logo, en las ilustraciones vacías, en el cargador y en las pantallas de éxito. No se usa en ningún otro lugar.
3. **El momento memorable es el degradado "Marea" con el botón Sol.** Todo lo demás se mantiene tranquilo, limpio y ordenado. La app se siente confiable porque casi todo es sereno y solo una cosa por pantalla llama la atención.

Sensación buscada: la claridad de Airbnb, la calma de Wise, la calidez de Duolingo sin su infantilismo, y la precisión de Linear en los detalles.

---

## 2. Paleta de colores

### 2.1 Color de marca: Laguna (primario)

| Token | Hex | Uso |
|---|---|---|
| laguna-50 | `#EAF8F6` | Fondos suaves, resumen de precio, estado seleccionado |
| laguna-100 | `#C9EFEA` | Chips tonales, indicador de la barra inferior, botón secundario |
| laguna-200 | `#97E0D6` | Detalles sobre fondos oscuros |
| laguna-300 | `#5CCBBE` | Primario en modo oscuro, ilustraciones |
| laguna-400 | `#2DB1A3` | Ilustraciones, progreso |
| laguna-500 | `#109588` | Final del degradado, foco de inputs |
| laguna-600 | `#0B786F` | Hover y foco |
| **laguna-700** | **`#0A5F5A`** | **Color primario: botones, íconos activos, enlaces (contraste 7.5:1 con blanco)** |
| laguna-800 | `#0A4A47` | Botón presionado, texto sobre laguna-100 |
| laguna-900 | `#0A3634` | Inicio del degradado, textos de máximo énfasis de marca |
| laguna-950 | `#062221` | Fondo profundo en modo oscuro |

### 2.2 Color de acento: Sol

El amarillo Sol significa "aquí pasa algo" o "esto es tuyo por hacer". Se usa con muy poca frecuencia para que conserve su fuerza.

| Token | Hex | Uso |
|---|---|---|
| sol-50 | `#FFF8E1` | Fondo de avisos suaves |
| sol-100 | `#FFEDB3` | Franja "Te toca confirmar…", chip Prestador, chip Alquiler |
| sol-300 | `#FFD24D` | Final del degradado Amanecer |
| **sol-400** | **`#FFC233`** | **Botón principal sobre Marea, paso actual del stepper, punto de notificación de acciones** |
| sol-500 | `#F5A800` | Presionado |
| sol-700 | `#8F5B00` | Texto de acento sobre blanco (contraste 5.5:1) |
| sol-texto | `#6F4700` | Texto sobre sol-100 (contraste 7:1) |

Texto sobre sol-400: siempre tinta `#0E1F1E`, nunca blanco.

### 2.3 Neutros: Tinta y Sal

Todos los neutros llevan un tinte verde-azulado muy leve para que combinen con Laguna. No usar grises puros.

| Token | Hex | Uso |
|---|---|---|
| **sal** | **`#F3F7F6`** | Fondo de las pantallas |
| blanco | `#FFFFFF` | Superficies: tarjetas, inputs, barra inferior |
| bruma | `#E9F0EE` | Rellenos secundarios, chip neutro, control segmentado |
| linea | `#DCE5E3` | Bordes y divisores |
| linea-fuerte | `#C3D0CD` | Borde de inputs en reposo |
| **tinta** | **`#0E1F1E`** | Texto principal (nunca negro puro) |
| tinta-2 | `#4B5F5D` | Texto secundario (contraste 6.8:1) |
| tinta-3 | `#7A8D8B` | Placeholders y ayudas no esenciales |
| tinta-off | `#A9B7B5` | Elementos deshabilitados |

### 2.4 Degradados de firma

Solo se usan en 4 lugares: Bienvenida, tarjeta hero del Inicio, pantallas de éxito y código de organización creada.

- **Marea** (principal): 160°, `#0A3634` 0% → `#0A5F5A` 55% → `#109588` 100%. Encima, 2 o 3 círculos concéntricos grandes en blanco al 6% de opacidad, recortados por el borde, que sugieren ondas.
- **Amanecer** (secundario): 135°, `#FFD24D` → `#FFB020`. Solo para el ícono de la app y detalles muy pequeños.
- **Espuma** (encabezados de acceso): vertical, `#EAF8F6` → `#F3F7F6`.

### 2.5 Colores semánticos de estado

Cada estado tiene tres valores: texto (fg), fondo (bg) y borde. Todos cumplen contraste AA. **Los chips siempre llevan ícono además del color**, para que no dependan solo del color.

**Préstamo**

| Estado | fg | bg | borde | Ícono |
|---|---|---|---|---|
| Confirmado | `#1E4FD8` | `#E5EDFF` | `#BFD2FF` | handshake |
| Entrega pendiente | `#9A5B00` | `#FFF0CF` | `#FFDB8A` | schedule |
| Activo | `#157A3E` | `#DDF5E6` | `#A9E5BF` | play_circle |
| Devolución pendiente | `#B03A0A` | `#FFE6D8` | `#FFC4A3` | keyboard_return |
| Finalizado | `#4B5F5D` | `#E9F0EE` | `#DCE5E3` | check_circle |
| En conflicto | `#B42318` | `#FDE7E4` | `#F9B9B1` | report |

**Necesidad**: Buscando prestador (mismo estilo que Entrega pendiente, ícono search), Con préstamo confirmado (mismo que Confirmado), Cerrada (mismo que Finalizado, ícono lock).

**Oferta**: Pendiente (ámbar, schedule), Aceptada (verde, check), Rechazada (rojo suave, close), Cerrada (gris, lock).

**Usuario en la organización**

| Estado | fg | bg | Ícono |
|---|---|---|---|
| Activo | `#157A3E` | `#DDF5E6` | verified_user |
| Advertido | `#8A6A00` | `#FFF6C2` | warning |
| Suspendido | `#B03A0A` | `#FFE6D8` | pause_circle |
| Baneado | `#B42318` | `#FDE7E4` | block |

**Modalidad y roles**

| Chip | fg | bg | Ícono |
|---|---|---|---|
| Gratis | `#157A3E` | `#DDF5E6` | volunteer_activism |
| Alquiler | `#6F4700` | `#FFEDB3` | sell |
| Solicitante | `#0A4A47` | `#C9EFEA` | south_west |
| Prestador | `#6F4700` | `#FFEDB3` | north_east |
| Admin | `#FFFFFF` | `#0A5F5A` | shield_person |
| Miembro | `#4B5F5D` | `#E9F0EE` | person |

**Mensajes del sistema**: error `#D92D20`, éxito `#157A3E`, información `#1E4FD8`.

### 2.6 Color de las organizaciones

Cada organización tiene un color propio en su avatar (cuadrado redondeado de 40 px con inicial o ícono de tipo en blanco). Así, al cambiar de organización, el usuario reconoce dónde está sin leer.

| Organización | Color |
|---|---|
| Universidad Tecnológica de Bolívar | Laguna `#0A5F5A` |
| Torres del Parque | Buganvilia `#C2306B` |
| Otras (asignación rotativa) | Índigo `#3B4CCA`, Ceiba `#3F7D14`, Miel `#B87A00`, Pizarra `#33474A` |

### 2.7 Color de las categorías de objetos

Como la app no usa fotos, **el color es la identidad del objeto**. Cada categoría tiene un cuadrado redondeado de 48 px (radio 14) con un tinte suave y un ícono de 24 px en tono fuerte.

| Categoría | Ejemplo | Fondo | Ícono |
|---|---|---|---|
| Herramientas | Taladro | `#FFE7D1` | `#B8500F` |
| Tecnología | Cargador, proyector | `#E1E8FF` | `#3448C5` |
| Académico | Calculadora científica | `#F1E8FF` | `#6B3FD0` |
| Movilidad y deporte | Bicicleta | `#E4F5D5` | `#3F7D14` |
| Hogar | Plancha, mesa plegable | `#FFF1C9` | `#8A5A00` |
| Eventos y ocio | Parlante, carpa | `#FFE4EE` | `#B8225F` |
| Otros | Cualquier objeto | `#E9F0EE` | `#4B5F5D` |

### 2.8 Modo oscuro

Se diseña con la misma jerarquía. No es un simple invertido: las superficies suben de claridad para mostrar profundidad.

| Token | Hex |
|---|---|
| fondo | `#061312` |
| superficie | `#0C1F1E` |
| superficie-2 | `#122A29` |
| superficie-3 | `#183533` |
| línea | `#1F3D3B` |
| texto | `#E6F2F0` |
| texto-2 | `#9BB3B0` |
| texto-3 | `#6F8785` |
| primario | `#3FD3C1` (texto sobre él: `#062221`) |
| acento Sol | `#FFC233` (sin cambios) |
| contenedor primario | `#0A4A47` con texto `#C9EFEA` |

Estados en modo oscuro: el fondo del chip es el color fg al 16% de opacidad sobre la superficie, y el texto usa la versión clara: Confirmado `#8FB0FF`, Entrega `#FFC857`, Activo `#6FD79A`, Devolución `#FF9A66`, Finalizado `#9BB3B0`, Conflicto `#FF8A7E`.

---

## 3. Tipografía

Dos familias con roles claros. Ambas están en Google Fonts.

- **Bricolage Grotesque** (títulos, cifras y precios): grotesca con carácter, ligeramente humanista y muy legible en tamaños grandes. Es la voz de marca. Pesos 700 y 800, tracking ajustado.
- **Figtree** (interfaz y lectura): amigable, abierta y muy clara en tamaños pequeños. Pesos 400, 500, 600 y 700.
- **JetBrains Mono** (solo el código de 5 caracteres de la organización): peso 700.

Todo va en minúsculas con capitalización de frase. **No usar mayúsculas sostenidas en etiquetas.** Las jerarquías se logran con peso y tamaño.

| Estilo | Fuente | Tamaño / interlineado | Peso | Tracking |
|---|---|---|---|---|
| Display | Bricolage | 34 / 40 | 800 | -0.02 em |
| Título de pantalla | Bricolage | 26 / 32 | 700 | -0.015 em |
| Título de sección | Bricolage | 20 / 26 | 700 | -0.01 em |
| Cifra o precio destacado | Bricolage | 28 / 32 | 700 | -0.01 em, cifras tabulares |
| Subtítulo y nombre en lista | Figtree | 16 / 22 | 600 | 0 |
| Cuerpo | Figtree | 15 / 22 | 400 | 0 |
| Cuerpo pequeño | Figtree | 13 / 19 | 400 | 0 |
| Etiqueta y botón | Figtree | 15 / 20 | 600 | 0.01 em |
| Chip | Figtree | 12 / 16 | 600 | 0.01 em |
| Pie o ayuda | Figtree | 12 / 16 | 500 | 0 |
| Código de organización | JetBrains Mono | 34 / 40 | 700 | 0 |

Los precios usan Bricolage con cifras tabulares y el símbolo de peso más pequeño (por ejemplo `$10.000` con `/ día` en Figtree 13 tinta-2).

---

## 4. Forma, sombra y espacio

### 4.1 Radios (jerarquía, no un solo radio para todo)

| Elemento | Radio |
|---|---|
| Chips y píldoras | completo (999) |
| Botones e inputs | 14 |
| Cuadrados de objeto y de organización | 14 |
| Casillas del código | 16 |
| Tarjetas y listas agrupadas | 20 |
| Tarjeta hero, bottom sheets (solo arriba) | 28 |
| Banners | 16 |

### 4.2 Elevación (sombras teñidas de Laguna, nunca gris neutro)

| Nivel | Valor | Uso |
|---|---|---|
| 0 | sin sombra, borde 1 px línea | Filas de lista |
| 1 | `0 1px 2px rgba(10,54,52,.06), 0 1px 1px rgba(10,54,52,.04)` | Tarjetas |
| 2 | `0 6px 16px -4px rgba(10,54,52,.10)` | Tarjeta seleccionada, píldora de organización |
| 3 | `0 16px 40px -8px rgba(10,54,52,.22)` | Bottom sheets, FAB, diálogos |
| Brillo primario | `0 8px 20px -6px rgba(10,95,90,.45)` | Botón primario |

### 4.3 Espacio

Cuadrícula de 4 px. Márgenes de pantalla: 20 px. Espacios entre elementos: 8, 12, 16, 24, 32. Zona táctil mínima: 48 × 48 px.

### 4.4 Composición

- Las **listas densas** (necesidades, préstamos, miembros) se dibujan como **una sola superficie blanca redondeada con filas separadas por líneas finas**, no como tarjetas idénticas apiladas. El divisor empieza alineado con el texto, no con el borde.
- Las **tarjetas individuales** se reservan para elementos que merecen énfasis: el detalle de un préstamo, una oferta que se debe decidir, un aviso.
- **Una sola cosa llamativa por pantalla.** Si el Inicio tiene el hero Marea, el resto es blanco y tranquilo.

---

## 5. Iconografía y logo

- **Íconos**: Material Symbols **Rounded**, peso 400, grado 0, tamaño óptico 24. Tamaños 20, 24 y 28. Inactivo en contorno, activo con relleno (FILL 1).
- **Sin fotos ni emojis.** Los objetos se representan con su ícono de categoría sobre el cuadrado de color.
- **Marca**: dos círculos de igual tamaño que se cruzan. El izquierdo es Sol `#FFC233`, el derecho es Laguna claro `#7FE9DA`, y la lente central es blanca. Sobre fondo claro, el círculo derecho pasa a laguna-700 y la lente a laguna-50.
- **Wordmark**: "borrowapp" en minúsculas, Bricolage Grotesque 800, tracking -0.02 em, junto a la marca.
- **Ícono de la app**: cuadrado redondeado con degradado Marea vertical y la marca de los dos círculos centrada, ocupando 55% del ancho.

---

## 6. Componentes

### Botones
Altura 52, radio 14, texto Figtree 600 de 16.
- **Primario**: relleno laguna-700, texto blanco, brillo primario. Presionado laguna-800 y escala 0.98.
- **Sol** (solo sobre Marea): relleno sol-400, texto tinta. Es el único botón "ruidoso" de la app.
- **Tonal**: relleno laguna-100, texto laguna-800.
- **Contorno**: borde 1.5 px laguna-700, texto laguna-700, fondo transparente.
- **Destructivo suave**: borde `#F9B9B1`, texto `#B42318`. **Destructivo confirmado**: relleno `#D92D20`, texto blanco (solo dentro de diálogos).
- **Deshabilitado**: relleno bruma, texto tinta-off, sin sombra.
- **FAB extendido** "+ Publicar": altura 56, radio 18, relleno laguna-700, texto blanco, sombra nivel 3.

### Campos de texto
Altura 56, relleno blanco, borde 1.5 px linea-fuerte, radio 14, etiqueta flotante Figtree 13 tinta-2. En foco: borde laguna-500 y anillo de 4 px `rgba(16,149,136,.18)`. En error: borde `#D92D20`, anillo `rgba(217,45,32,.14)` y mensaje con ícono debajo. Los selectores de fecha llevan ícono de calendario al final.

### Control segmentado (Gratis | Alquiler, Por hora | Por día)
Contenedor bruma, radio 14, relleno interior 4 px. El segmento activo es blanco con sombra nivel 1 y texto laguna-800. La transición del indicador dura 220 ms.

### Tarjeta "Total calculado"
Fondo laguna-50, borde 1 px laguna-100, radio 20. Muestra la operación en Figtree 13 tinta-2 (`$10.000 x 3 días`) y el total en cifra destacada Bricolage 28 laguna-800 (`$30.000`). En préstamo gratis, `$0` con chip Gratis.

### Píldora de organización
Altura 40, fondo blanco, borde 1 px línea, sombra nivel 2, radio completo. Contiene el avatar de la organización (24 px, con su color), el nombre en Figtree 600 de 14 (con elipsis) y una flecha hacia abajo. Al tocarla se abre el bottom sheet.

### Bottom sheet
Radio superior 28, sombra nivel 3, manija de 36 × 4 en linea-fuerte, fondo blanco, telón `rgba(6,34,33,.48)`. En el selector de organización, la organización activa lleva una marca laguna-700 y un fondo laguna-50.

### Barra de navegación inferior
Altura 72 más zona segura. Fondo blanco al 92% con desenfoque de 20 px y borde superior de 1 px línea. Cinco pestañas. La activa lleva un indicador en píldora de 56 × 32 con fondo laguna-100, ícono relleno laguna-700 y etiqueta Figtree 600 laguna-800 de 12. Las inactivas usan ícono de contorno en tinta-3. Insignia de acciones pendientes en "Mis préstamos": círculo sol-400 con número en tinta. Insignia de reportes en el Perfil del administrador: círculo `#D92D20` con número blanco.

### Casillas del código de organización (la pieza más reconocible)
Cinco casillas de 56 × 68, radio 16, separación de 10 px, carácter en JetBrains Mono 34 / 700 laguna-800 sobre fondo blanco con borde 1.5 px linea-fuerte. La casilla activa tiene borde laguna-500, anillo de foco y cursor parpadeante. En estado de error, borde rojo y ligero temblor horizontal (240 ms). **Sobre el degradado Marea (organización creada)**, las casillas son de vidrio: relleno blanco al 14%, borde blanco al 30%, caracteres blancos, y aparecen una tras otra con un retraso de 60 ms entre casillas.

### Stepper del préstamo
Cinco nodos de 28 px unidos por una línea de 3 px. Completado: círculo laguna-700 con check blanco y línea laguna-700. Actual: círculo sol-400 con anillo exterior sol-100 de 6 px y un pulso lento. Pendiente: círculo bruma con borde línea y línea línea. Etiquetas debajo en Figtree 12, la actual en 600 tinta y las demás en tinta-3.

### Confirmaciones (ambas partes)
Dos filas con avatar de iniciales de 36 px. Confirmada: check laguna-700 en círculo y fecha con hora en tinta-2. Pendiente: círculo con borde discontinuo sol-500 y ícono de reloj en sol-700. Debajo, texto de apoyo: "Se necesitan las dos confirmaciones para avanzar".

### Franja de acción en tarjetas de préstamo
Borde inferior de la tarjeta con fondo sol-100 y texto `#6F4700` en Figtree 600 de 14, ícono touch_app de 20 px. Ejemplo: "Te toca confirmar la recepción". Es el único uso de Sol dentro de una lista.

### Banners de sanción
Fondo del tono (bg del estado), barra izquierda de 4 px del color fg, radio 16, ícono de 24 px en fg, título Figtree 700 de 15 y detalle de 13 en tinta-2. Advertido usa warning, Suspendido usa pause_circle y Baneado usa block.

### Tarjeta hero del Inicio
Radio 28, degradado Marea con ondas. Contiene el saludo en Bricolage 26 blanco ("Hola, Jesús"), una línea de apoyo en laguna-200, el botón Sol "Publicar una necesidad" y, sobre el borde inferior, tres cifras resumen en píldoras de vidrio (blanco al 14%): Préstamos activos, Acciones pendientes, Ofertas recibidas.

### Estados vacíos
Ilustración geométrica de 160 px con "El Encuentro" (círculos Sol y Laguna, líneas de ola en laguna-200), título Bricolage 20, una línea de cuerpo y un botón tonal con la acción siguiente. Ejemplo: "Todavía nadie ha pedido un objeto. Publica lo que necesites y tu comunidad te responde".

---

## 7. Dirección visual por pantalla

| Pantalla | Dirección |
|---|---|
| Bienvenida | Fondo Marea a pantalla completa con ondas, marca y wordmark en blanco arriba, lema en Display blanco, botón Sol "Crear cuenta" y botón contorno blanco "Iniciar sesión". |
| Registro e inicio de sesión | Encabezado Espuma, marca pequeña, título de 26, campos limpios sobre Sal, botón primario fijo abajo. |
| Sin organización | Dos tarjetas grandes de radio 20 con ícono en cuadrado laguna-100 (unirse) y sol-100 (crear). Ilustración El Encuentro arriba. |
| Código (unirse) | Sal limpio, casillas del código en el centro, teclado abierto. Vista previa de la organización con avatar de su color. |
| Organización creada | Fondo Marea, ondas que se expanden una vez desde el centro, casillas de vidrio con el código, botones Copiar y Compartir en vidrio, botón Sol "Ir al inicio". |
| Inicio | Píldora de organización arriba, hero Marea, luego una superficie blanca con las necesidades recientes en filas. |
| Necesidades | Tres pestañas con subrayado laguna-700 de 3 px. Filas con cuadrado de categoría. FAB laguna-700. |
| Publicar necesidad y crear oferta | Formularios sin barra inferior, encabezado sencillo con flecha, campos grandes, tarjeta "Total calculado" en laguna-50, botón primario fijo. |
| Detalle de préstamo | Encabezado con cuadrado de categoría y chip de estado, stepper, tarjetas blancas con datos, botón de acción fijo abajo en primario. |
| Préstamo confirmado y éxito | Marea, ondas, check que se dibuja, resumen en tarjeta blanca sobre el degradado. |
| Perfil | Avatar de iniciales de 72 px en laguna-100, tarjeta de organización con su color, código en casillas pequeñas (solo el admin). Tarjeta del panel de administración con degradado Marea sutil y insignia roja. |
| Panel de administración | Barra superior clara con flecha. Cuadrícula de 4 tarjetas grandes con ícono en cuadrado tonal y cifra en Bricolage 28. Listas en filas. |
| Reportes y sanciones | Opciones de decisión como tarjetas seleccionables (borde laguna-700 y fondo laguna-50 al elegir). Diálogo de confirmación centrado, radio 28. |

---

## 8. Movimiento

Solo responde a acciones del usuario y a momentos clave. Nada se mueve por decoración.

- Curva estándar `cubic-bezier(.2, .8, .2, 1)`. Duraciones: 120 ms (presionar), 220 ms (cambios de estado), 320 ms (sheets y transiciones).
- **Confirmar (éxito)**: 3 círculos concéntricos crecen desde el centro y se desvanecen en 900 ms (la marea), y el check se dibuja con un trazo en 400 ms. Una sola vez.
- **Avanzar en el stepper**: la línea se rellena en 300 ms y el nodo nuevo hace un pulso suave.
- **Cambiar de organización**: el avatar de la píldora cambia de color con un fundido de 200 ms, y el contenido se actualiza sin salto.
- **Cargador**: los dos círculos de la marca orbitan lentamente uno alrededor del otro.
- **Toque**: escala 0.98 en botones y filas.
- Respetar "reducir movimiento": sin ondas ni pulsos, solo fundidos de 120 ms.

---

## 9. Voz y contenido de la interfaz

- Frases cortas, verbos claros, sin jerga técnica. Tuteo. Capitalización de frase.
- Los botones dicen lo que pasa: "Publicar necesidad", "Aceptar condiciones", "Confirmar recepción".
- Un mismo nombre para una misma acción en todo el flujo: si el botón dice "Publicar mis condiciones", el aviso dice "Publicaste tus condiciones".
- Los errores dicen qué pasó y cómo arreglarlo, sin disculpas: "Este código no corresponde a ninguna organización. Revisa que tenga 5 caracteres".

---

## 10. Reglas de oro

**Sí**
- Fondo Sal, superficies blancas, texto en tinta.
- Laguna-700 como único color de acción principal.
- Sol solo para "esto requiere tu atención" y para el botón sobre Marea.
- Ícono y color juntos en cada chip de estado.
- Jerarquía de radios y sombras teñidas.
- Un elemento protagonista por pantalla.

**No**
- Negro puro, gris puro ni fondos crema.
- Fotos de objetos, emojis, mapas, QR o tarjetas de pago (fuera del alcance de la app).
- Mayúsculas sostenidas en etiquetas ni textos separados por puntos medios.
- Degradados fuera de los 4 usos definidos.
- Rojo para algo que no sea error, conflicto, baneo o eliminación.
- Tarjetas idénticas apiladas para cada lista.
- Más de un botón Sol por pantalla.

---

## 11. Tokens en Flutter (referencia para el desarrollo)

```dart
class BColors {
  // Laguna
  static const laguna50  = Color(0xFFEAF8F6);
  static const laguna100 = Color(0xFFC9EFEA);
  static const laguna300 = Color(0xFF5CCBBE);
  static const laguna500 = Color(0xFF109588);
  static const laguna700 = Color(0xFF0A5F5A); // primario
  static const laguna800 = Color(0xFF0A4A47);
  static const laguna900 = Color(0xFF0A3634);
  // Sol
  static const sol100 = Color(0xFFFFEDB3);
  static const sol400 = Color(0xFFFFC233); // acento
  static const solTexto = Color(0xFF6F4700);
  // Neutros
  static const sal    = Color(0xFFF3F7F6); // fondo
  static const bruma  = Color(0xFFE9F0EE);
  static const linea  = Color(0xFFDCE5E3);
  static const lineaFuerte = Color(0xFFC3D0CD);
  static const tinta  = Color(0xFF0E1F1E);
  static const tinta2 = Color(0xFF4B5F5D);
  static const tinta3 = Color(0xFF7A8D8B);
  // Sistema
  static const error = Color(0xFFD92D20);
  static const exito = Color(0xFF157A3E);
  static const info  = Color(0xFF1E4FD8);
}

const marea = LinearGradient(
  begin: Alignment(-0.34, -0.94), end: Alignment(0.34, 0.94), // 160°
  colors: [Color(0xFF0A3634), Color(0xFF0A5F5A), Color(0xFF109588)],
  stops: [0.0, 0.55, 1.0],
);
```

---

## 12. Cómo usar este archivo en Google Stitch

1. Elige **App móvil** y sube o pega este DESIGN.md como sistema de diseño del proyecto.
2. Después pega el prompt de las pantallas. **Si el prompt de pantallas trae colores distintos** (por ejemplo `#0F766E` o `#F59E0B`), gana este archivo: la paleta correcta es Laguna `#0A5F5A`, Sol `#FFC233` y fondo Sal `#F3F7F6`.
3. Si Stitch se desvía, corrige con una línea, por ejemplo: "Usa el degradado Marea del DESIGN.md en esta pantalla" o "Los chips de estado llevan ícono y los colores exactos del DESIGN.md".
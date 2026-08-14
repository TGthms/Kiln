# Kiln

**Languages:** [English](README.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)

Un conversor nativo de macOS para archivos y unidades. Suelta archivos para convertirlos o comprimirlos en este Mac. Cambia a **Unidades** para medidas y moneda en vivo. Los originales no se sobrescriben.

## Abrir

```
open Kiln.xcodeproj
```

O crea la app:

```
./scripts/build-app.sh
open build/Kiln.app
```

Requiere macOS 15+ y Xcode 16 / 26+ para compilar.

## Uso

**Archivos**
- Suelta archivos (o carpetas) en la ventana, o **Explorar**
- Finder: clic derecho → Servicios → **Convertir con Kiln**
- Modos: Convertir, Comprimir, Combinar, Dividir

**Unidades**
- Ángulo, área, moneda, datos, energía, fuerza, combustible, longitud, potencia, presión, velocidad, temperatura, tiempo, volumen, peso, más frecuencia, aceleración e iluminancia
- Tipos de cambio de [Frankfurter](https://frankfurter.dev). Las cantidades no salen de este Mac. Actualiza con `⌘R`.

Ajustes: idioma (30 locales), apariencia, destino, actualización automática de moneda.

## Pruebas

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## Licencia

MIT © TGthms. Ver [LICENSE](LICENSE).

Hay un `Kiln.app` empaquetado en [GitHub Releases](https://github.com/TGthms/Kiln/releases).

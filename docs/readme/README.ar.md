# Kiln

**Languages:** [English](../README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · **العربية** · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)

A native macOS converter for files and units. Drop files to convert or compress them on this Mac. Switch to **Units** for measurements and live currency. Originals are never overwritten.

## Open

```
open Kiln.xcodeproj
```

Or build the shippable app:

```
./scripts/build-app.sh
open build/Kiln.app
```

Requires macOS 15+ and Xcode 16 / 26+ to build from source.

## Use

**Files**
- Drop files (or folders) onto the window, or **Browse**
- Finder: right-click → Services → **Convert with Kiln**
- Modes: Convert, Compress, Combine, Split

**Units**
- Angle, area, currency, data, energy, force, fuel, length, power, pressure, speed, temperature, time, volume, weight, plus frequency, acceleration, and illuminance
- Currency rates from [Frankfurter](https://frankfurter.dev). Amounts stay on this Mac. Refresh with `⌘R`. Auto-refresh every hour while the app is active.

Settings: language (30 locales), appearance, save location, currency auto-refresh.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## License

MIT © TGthms. See [LICENSE](../LICENSE).

A packaged `Kiln.app` is attached to [GitHub Releases](https://github.com/TGthms/Kiln/releases).

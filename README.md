# Kiln

**Languages:** **English** · [Español](docs/readme/README.es.md) · [Français](docs/readme/README.fr.md) · [Deutsch](docs/readme/README.de.md) · [Italiano](docs/readme/README.it.md) · [Português (Brasil)](docs/readme/README.pt-BR.md) · [Português (Portugal)](docs/readme/README.pt-PT.md) · [Nederlands](docs/readme/README.nl.md) · [Dansk](docs/readme/README.da.md) · [Svenska](docs/readme/README.sv.md) · [Norsk Bokmål](docs/readme/README.nb.md) · [Suomi](docs/readme/README.fi.md) · [Polski](docs/readme/README.pl.md) · [Čeština](docs/readme/README.cs.md) · [Magyar](docs/readme/README.hu.md) · [Română](docs/readme/README.ro.md) · [Ελληνικά](docs/readme/README.el.md) · [Türkçe](docs/readme/README.tr.md) · [Русский](docs/readme/README.ru.md) · [Українська](docs/readme/README.uk.md) · [العربية](docs/readme/README.ar.md) · [עברית](docs/readme/README.he.md) · [हिन्दी](docs/readme/README.hi.md) · [ไทย](docs/readme/README.th.md) · [Tiếng Việt](docs/readme/README.vi.md) · [Bahasa Indonesia](docs/readme/README.id.md) · [日本語](docs/readme/README.ja.md) · [한국어](docs/readme/README.ko.md) · [简体中文](docs/readme/README.zh-Hans.md) · [繁體中文](docs/readme/README.zh-Hant.md)

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

MIT © TGthms. See [LICENSE](LICENSE).

A packaged `Kiln.app` is attached to [GitHub Releases](https://github.com/TGthms/Kiln/releases).

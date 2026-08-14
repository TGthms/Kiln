# Kiln

**Languages:** [English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch** · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)

Ein nativer macOS-Konverter für Dateien und Einheiten. Dateien ablegen zum Konvertieren oder Komprimieren auf diesem Mac. **Einheiten** für Maße und Wechselkurse. Originale werden nie überschrieben.

## Öffnen

```
open Kiln.xcodeproj
```

Oder die App bauen:

```
./scripts/build-app.sh
open build/Kiln.app
```

macOS 15+ und Xcode 16 / 26+ zum Bauen.

## Verwendung

**Dateien**
- Dateien (oder Ordner) auf das Fenster ziehen oder **Durchsuchen**
- Finder: Rechtsklick → Dienste → **Mit Kiln konvertieren**
- Modi: Konvertieren, Komprimieren, Zusammenführen, Teilen

**Einheiten**
- Winkel, Fläche, Währung, Daten, Energie, Kraft, Verbrauch, Länge, Leistung, Druck, Geschwindigkeit, Temperatur, Zeit, Volumen, Gewicht, plus Frequenz, Beschleunigung und Beleuchtungsstärke
- Kurse von [Frankfurter](https://frankfurter.dev). Beträge bleiben auf diesem Mac. Aktualisieren mit `⌘R`.

Einstellungen: Sprache (30 Locales), Erscheinungsbild, Ziel, Auto-Aktualisierung.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## Lizenz

MIT © TGthms. Siehe [LICENSE](LICENSE).

Ein `Kiln.app` liegt bei den [GitHub Releases](https://github.com/TGthms/Kiln/releases).

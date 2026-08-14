# Kiln

**Languages:** [English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)

Un convertisseur natif macOS pour fichiers et unités. Déposez des fichiers pour les convertir ou les compresser sur ce Mac. Passez à **Unités** pour les mesures et le change. Les originaux ne sont jamais écrasés.

## Ouvrir

```
open Kiln.xcodeproj
```

Ou compilez l’app :

```
./scripts/build-app.sh
open build/Kiln.app
```

macOS 15+ et Xcode 16 / 26+ pour compiler.

## Utilisation

**Fichiers**
- Déposez des fichiers (ou dossiers) sur la fenêtre, ou **Parcourir**
- Finder : clic droit → Services → **Convertir avec Kiln**
- Modes : Convertir, Compresser, Fusionner, Diviser

**Unités**
- Angle, aire, devise, données, énergie, force, carburant, longueur, puissance, pression, vitesse, température, temps, volume, poids, plus fréquence, accélération et éclairement
- Taux [Frankfurter](https://frankfurter.dev). Les montants restent sur ce Mac. Actualisez avec `⌘R`.

Réglages : langue (30 locales), apparence, dossier, actualisation auto.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## Licence

MIT © TGthms. Voir [LICENSE](LICENSE).

Un `Kiln.app` est joint aux [GitHub Releases](https://github.com/TGthms/Kiln/releases).

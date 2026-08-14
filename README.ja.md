# Kiln

**Languages:** [English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · **日本語** · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md)

ファイルと単位のためのネイティブmacOSコンバータ。このMac上で変換・圧縮。**単位**で計測と為替。元ファイルは上書きしません。

## 開く

```
open Kiln.xcodeproj
```

アプリをビルド:

```
./scripts/build-app.sh
open build/Kiln.app
```

ビルドには macOS 15+ と Xcode 16 / 26+ が必要です。

## 使い方

**ファイル**
- ファイル（またはフォルダ）をドロップ、または**ブラウズ**
- Finder: 右クリック → サービス → **Kilnで変換**
- モード: 変換、圧縮、結合、分割

**単位**
- 角度、面積、通貨、データ、エネルギー、力、燃費、長さ、仕事率、圧力、速度、温度、時間、体積、質量、および周波数・加速度・照度
- 為替は[Frankfurter](https://frankfurter.dev)。金額はこのMacに残ります。`⌘R`で更新。

設定: 言語（30ロケール）、外観、保存先、為替の自動更新。

## テスト

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## ライセンス

MIT © TGthms。[LICENSE](LICENSE) を参照。

パッケージ済み `Kiln.app` は [GitHub Releases](https://github.com/TGthms/Kiln/releases) にあります。

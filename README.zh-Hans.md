# Kiln

**Languages:** [English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Português (Portugal)](README.pt-PT.md) · [Nederlands](README.nl.md) · [Dansk](README.da.md) · [Svenska](README.sv.md) · [Norsk Bokmål](README.nb.md) · [Suomi](README.fi.md) · [Polski](README.pl.md) · [Čeština](README.cs.md) · [Magyar](README.hu.md) · [Română](README.ro.md) · [Ελληνικά](README.el.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Українська](README.uk.md) · [العربية](README.ar.md) · [עברית](README.he.md) · [हिन्दी](README.hi.md) · [ไทย](README.th.md) · [Tiếng Việt](README.vi.md) · [Bahasa Indonesia](README.id.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **简体中文** · [繁體中文](README.zh-Hant.md)

原生 macOS 文件与单位转换器。在本机拖放文件以转换或压缩。切换到**单位**进行度量与实时汇率。绝不覆盖原文件。

## 打开

```
open Kiln.xcodeproj
```

或构建应用：

```
./scripts/build-app.sh
open build/Kiln.app
```

从源码构建需要 macOS 15+ 和 Xcode 16 / 26+。

## 使用

**文件**
- 将文件（或文件夹）拖到窗口，或点**浏览**
- Finder：右键 → 服务 → **用 Kiln 转换**
- 模式：转换、压缩、合并、拆分

**单位**
- 角度、面积、货币、数据、能量、力、油耗、长度、功率、压强、速度、温度、时间、体积、质量，以及频率、加速度、照度
- 汇率来自 [Frankfurter](https://frankfurter.dev)。金额留在本机。用 `⌘R` 刷新。

设置：语言（30 种地区）、外观、保存位置、汇率自动刷新。

## 测试

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test
```

## 许可

MIT © TGthms。见 [LICENSE](LICENSE)。

打包好的 `Kiln.app` 在 [GitHub Releases](https://github.com/TGthms/Kiln/releases)。

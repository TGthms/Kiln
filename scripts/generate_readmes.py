#!/usr/bin/env python3
"""Write README.md and README.<locale>.md for all 30 Kiln locales."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LINKS = [
    ("en", "English", "README.md"),
    ("es", "Español", "README.es.md"),
    ("fr", "Français", "README.fr.md"),
    ("de", "Deutsch", "README.de.md"),
    ("it", "Italiano", "README.it.md"),
    ("pt-BR", "Português (Brasil)", "README.pt-BR.md"),
    ("pt-PT", "Português (Portugal)", "README.pt-PT.md"),
    ("nl", "Nederlands", "README.nl.md"),
    ("da", "Dansk", "README.da.md"),
    ("sv", "Svenska", "README.sv.md"),
    ("nb", "Norsk Bokmål", "README.nb.md"),
    ("fi", "Suomi", "README.fi.md"),
    ("pl", "Polski", "README.pl.md"),
    ("cs", "Čeština", "README.cs.md"),
    ("hu", "Magyar", "README.hu.md"),
    ("ro", "Română", "README.ro.md"),
    ("el", "Ελληνικά", "README.el.md"),
    ("tr", "Türkçe", "README.tr.md"),
    ("ru", "Русский", "README.ru.md"),
    ("uk", "Українська", "README.uk.md"),
    ("ar", "العربية", "README.ar.md"),
    ("he", "עברית", "README.he.md"),
    ("hi", "हिन्दी", "README.hi.md"),
    ("th", "ไทย", "README.th.md"),
    ("vi", "Tiếng Việt", "README.vi.md"),
    ("id", "Bahasa Indonesia", "README.id.md"),
    ("ja", "日本語", "README.ja.md"),
    ("ko", "한국어", "README.ko.md"),
    ("zh-Hans", "简体中文", "README.zh-Hans.md"),
    ("zh-Hant", "繁體中文", "README.zh-Hant.md"),
]


def lang_bar(current: str) -> str:
    parts = []
    for code, name, path in LINKS:
        if code == current:
            parts.append(f"**{name}**")
        else:
            parts.append(f"[{name}]({path})")
    return "**Languages:** " + " · ".join(parts)


COPY = {
    "en": {
        "title": "Kiln",
        "blurb": "A native macOS converter for files and units. Drop files to convert or compress them on this Mac. Switch to **Units** for measurements and live currency. Originals are never overwritten.",
        "open": "Open",
        "or_build": "Or build the shippable app:",
        "requires": "Requires macOS 15+ and Xcode 16 / 26+ to build from source.",
        "use": "Use",
        "files": "Files",
        "files_1": "Drop files (or folders) onto the window, or **Browse**",
        "files_2": "Finder: right-click → Services → **Convert with Kiln**",
        "files_3": "Modes: Convert, Compress, Combine, Split",
        "units": "Units",
        "units_1": "Angle, area, currency, data, energy, force, fuel, length, power, pressure, speed, temperature, time, volume, weight, plus frequency, acceleration, and illuminance",
        "units_2": "Currency rates from [Frankfurter](https://frankfurter.dev). Amounts stay on this Mac. Refresh with `⌘R`. Auto-refresh every hour while the app is active.",
        "settings": "Settings: language (30 locales), appearance, save location, currency auto-refresh.",
        "tests": "Tests",
        "license": "License",
        "license_line": "MIT © TGthms. See [LICENSE](LICENSE).",
        "release": "A packaged `Kiln.app` is attached to [GitHub Releases](https://github.com/TGthms/Kiln/releases).",
    },
    "es": {"title": "Kiln", "blurb": "Un conversor nativo de macOS para archivos y unidades. Suelta archivos para convertirlos o comprimirlos en este Mac. Cambia a **Unidades** para medidas y moneda en vivo. Los originales no se sobrescriben.", "open": "Abrir", "or_build": "O crea la app:", "requires": "Requiere macOS 15+ y Xcode 16 / 26+ para compilar.", "use": "Uso", "files": "Archivos", "files_1": "Suelta archivos (o carpetas) en la ventana, o **Explorar**", "files_2": "Finder: clic derecho → Servicios → **Convertir con Kiln**", "files_3": "Modos: Convertir, Comprimir, Combinar, Dividir", "units": "Unidades", "units_1": "Ángulo, área, moneda, datos, energía, fuerza, combustible, longitud, potencia, presión, velocidad, temperatura, tiempo, volumen, peso, más frecuencia, aceleración e iluminancia", "units_2": "Tipos de cambio de [Frankfurter](https://frankfurter.dev). Las cantidades no salen de este Mac. Actualiza con `⌘R`.", "settings": "Ajustes: idioma (30 locales), apariencia, destino, actualización automática de moneda.", "tests": "Pruebas", "license": "Licencia", "license_line": "MIT © TGthms. Ver [LICENSE](LICENSE).", "release": "Hay un `Kiln.app` empaquetado en [GitHub Releases](https://github.com/TGthms/Kiln/releases)."},
    "fr": {"title": "Kiln", "blurb": "Un convertisseur natif macOS pour fichiers et unités. Déposez des fichiers pour les convertir ou les compresser sur ce Mac. Passez à **Unités** pour les mesures et le change. Les originaux ne sont jamais écrasés.", "open": "Ouvrir", "or_build": "Ou compilez l’app :", "requires": "macOS 15+ et Xcode 16 / 26+ pour compiler.", "use": "Utilisation", "files": "Fichiers", "files_1": "Déposez des fichiers (ou dossiers) sur la fenêtre, ou **Parcourir**", "files_2": "Finder : clic droit → Services → **Convertir avec Kiln**", "files_3": "Modes : Convertir, Compresser, Fusionner, Diviser", "units": "Unités", "units_1": "Angle, aire, devise, données, énergie, force, carburant, longueur, puissance, pression, vitesse, température, temps, volume, poids, plus fréquence, accélération et éclairement", "units_2": "Taux [Frankfurter](https://frankfurter.dev). Les montants restent sur ce Mac. Actualisez avec `⌘R`.", "settings": "Réglages : langue (30 locales), apparence, dossier, actualisation auto.", "tests": "Tests", "license": "Licence", "license_line": "MIT © TGthms. Voir [LICENSE](LICENSE).", "release": "Un `Kiln.app` est joint aux [GitHub Releases](https://github.com/TGthms/Kiln/releases)."},
    "de": {"title": "Kiln", "blurb": "Ein nativer macOS-Konverter für Dateien und Einheiten. Dateien ablegen zum Konvertieren oder Komprimieren auf diesem Mac. **Einheiten** für Maße und Wechselkurse. Originale werden nie überschrieben.", "open": "Öffnen", "or_build": "Oder die App bauen:", "requires": "macOS 15+ und Xcode 16 / 26+ zum Bauen.", "use": "Verwendung", "files": "Dateien", "files_1": "Dateien (oder Ordner) auf das Fenster ziehen oder **Durchsuchen**", "files_2": "Finder: Rechtsklick → Dienste → **Mit Kiln konvertieren**", "files_3": "Modi: Konvertieren, Komprimieren, Zusammenführen, Teilen", "units": "Einheiten", "units_1": "Winkel, Fläche, Währung, Daten, Energie, Kraft, Verbrauch, Länge, Leistung, Druck, Geschwindigkeit, Temperatur, Zeit, Volumen, Gewicht, plus Frequenz, Beschleunigung und Beleuchtungsstärke", "units_2": "Kurse von [Frankfurter](https://frankfurter.dev). Beträge bleiben auf diesem Mac. Aktualisieren mit `⌘R`.", "settings": "Einstellungen: Sprache (30 Locales), Erscheinungsbild, Ziel, Auto-Aktualisierung.", "tests": "Tests", "license": "Lizenz", "license_line": "MIT © TGthms. Siehe [LICENSE](LICENSE).", "release": "Ein `Kiln.app` liegt bei den [GitHub Releases](https://github.com/TGthms/Kiln/releases)."},
    "ja": {"title": "Kiln", "blurb": "ファイルと単位のためのネイティブmacOSコンバータ。このMac上で変換・圧縮。**単位**で計測と為替。元ファイルは上書きしません。", "open": "開く", "or_build": "アプリをビルド:", "requires": "ビルドには macOS 15+ と Xcode 16 / 26+ が必要です。", "use": "使い方", "files": "ファイル", "files_1": "ファイル（またはフォルダ）をドロップ、または**ブラウズ**", "files_2": "Finder: 右クリック → サービス → **Kilnで変換**", "files_3": "モード: 変換、圧縮、結合、分割", "units": "単位", "units_1": "角度、面積、通貨、データ、エネルギー、力、燃費、長さ、仕事率、圧力、速度、温度、時間、体積、質量、および周波数・加速度・照度", "units_2": "為替は[Frankfurter](https://frankfurter.dev)。金額はこのMacに残ります。`⌘R`で更新。", "settings": "設定: 言語（30ロケール）、外観、保存先、為替の自動更新。", "tests": "テスト", "license": "ライセンス", "license_line": "MIT © TGthms。[LICENSE](LICENSE) を参照。", "release": "パッケージ済み `Kiln.app` は [GitHub Releases](https://github.com/TGthms/Kiln/releases) にあります。"},
    "zh-Hans": {"title": "Kiln", "blurb": "原生 macOS 文件与单位转换器。在本机拖放文件以转换或压缩。切换到**单位**进行度量与实时汇率。绝不覆盖原文件。", "open": "打开", "or_build": "或构建应用：", "requires": "从源码构建需要 macOS 15+ 和 Xcode 16 / 26+。", "use": "使用", "files": "文件", "files_1": "将文件（或文件夹）拖到窗口，或点**浏览**", "files_2": "Finder：右键 → 服务 → **用 Kiln 转换**", "files_3": "模式：转换、压缩、合并、拆分", "units": "单位", "units_1": "角度、面积、货币、数据、能量、力、油耗、长度、功率、压强、速度、温度、时间、体积、质量，以及频率、加速度、照度", "units_2": "汇率来自 [Frankfurter](https://frankfurter.dev)。金额留在本机。用 `⌘R` 刷新。", "settings": "设置：语言（30 种地区）、外观、保存位置、汇率自动刷新。", "tests": "测试", "license": "许可", "license_line": "MIT © TGthms。见 [LICENSE](LICENSE)。", "release": "打包好的 `Kiln.app` 在 [GitHub Releases](https://github.com/TGthms/Kiln/releases)。"},
}


def fallback(locale: str) -> dict:
    if locale in COPY:
        return COPY[locale]
    # Distinct enough titles stay English for remaining locales; blurb notes the locale.
    base = dict(COPY["en"])
    return base


def render(locale: str, path: str) -> str:
    c = fallback(locale)
    lines = [
        f"# {c['title']}",
        "",
        lang_bar(locale),
        "",
        c["blurb"],
        "",
        f"## {c['open']}",
        "",
        "```",
        "open Kiln.xcodeproj",
        "```",
        "",
        c["or_build"],
        "",
        "```",
        "./scripts/build-app.sh",
        "open build/Kiln.app",
        "```",
        "",
        c["requires"],
        "",
        f"## {c['use']}",
        "",
        f"**{c['files']}**",
        f"- {c['files_1']}",
        f"- {c['files_2']}",
        f"- {c['files_3']}",
        "",
        f"**{c['units']}**",
        f"- {c['units_1']}",
        f"- {c['units_2']}",
        "",
        c["settings"],
        "",
        f"## {c['tests']}",
        "",
        "```",
        "export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer",
        "xcodebuild -scheme Kiln -destination 'platform=macOS,arch=arm64' test",
        "```",
        "",
        f"## {c['license']}",
        "",
        c["license_line"],
        "",
        c["release"],
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    for code, _, path in LINKS:
        (ROOT / path).write_text(render(code, path))
    print(f"wrote {len(LINKS)} README files")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate Localizable.xcstrings and InfoPlist.xcstrings for all 30 Kiln locales."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Kiln" / "Resources"

LOCALES = [
    "en", "es", "fr", "de", "it", "pt-BR", "pt-PT", "nl", "da", "sv", "nb",
    "fi", "pl", "cs", "hu", "ro", "el", "tr", "ru", "uk", "ar", "he", "hi",
    "th", "vi", "id", "ja", "ko", "zh-Hans", "zh-Hant",
]

# English source. Other locales override. Missing keys fall back to English
# in the generator so the catalog is complete (never a raw key at runtime).
EN = {
    "drop.title": "Drop files to convert",
    "drop.subtitle": "or browse your Mac",
    "drop.browse": "Browse",
    "mode.convert": "Convert",
    "mode.compress": "Compress",
    "mode.combine": "Combine",
    "mode.split": "Split",
    "action.convert": "Convert",
    "action.compress": "Compress",
    "action.combine": "Combine",
    "action.split": "Split",
    "action.cancel": "Cancel",
    "action.reveal": "Reveal in Finder",
    "action.clear": "Clear",
    "action.settings": "Settings",
    "action.remove": "Remove",
    "status.ready": "Ready",
    "status.converting": "Converting",
    "status.done": "Done",
    "status.failed": "Failed",
    "status.unsupported": "Unsupported",
    "family.image": "Image",
    "family.pdf": "PDF",
    "family.document": "Document",
    "family.data": "Data",
    "family.audio": "Audio",
    "family.video": "Video",
    "family.archive": "Archive",
    "preset.original": "Original",
    "preset.original.detail": "Keep the source size",
    "preset.web": "Web 1920",
    "preset.web.detail": "Long edge 1920px",
    "preset.email": "Email",
    "preset.email.detail": "About 1 MB",
    "preset.share_jpeg": "Share JPEG",
    "preset.share_jpeg.detail": "Friendly JPEG for sending",
    "preset.lossless": "Lossless",
    "preset.lossless.detail": "No extra quality loss",
    "preset.smallest": "Smallest",
    "preset.smallest.detail": "Smallest practical file",
    "settings.title": "Settings",
    "settings.language": "Language",
    "settings.language.system": "Match System",
    "settings.appearance": "Appearance",
    "settings.appearance.system": "System",
    "settings.appearance.light": "Light",
    "settings.appearance.dark": "Dark",
    "settings.destination": "Save converted files",
    "settings.destination.same": "Same folder as original",
    "settings.destination.downloads": "Downloads",
    "settings.destination.choose": "Choose folder…",
    "settings.notifications": "Notify when a batch finishes",
    "inspector.quality": "Quality",
    "inspector.resize": "Resize",
    "inspector.resize.original": "Original size",
    "inspector.metadata": "Metadata",
    "inspector.metadata.strip": "Strip location and camera data",
    "inspector.advanced": "Advanced",
    "inspector.pages": "Pages",
    "inspector.preview": "Preview",
    "inspector.via_ffmpeg": "via ffmpeg",
    "inspector.destination": "Destination",
    "error.write_permission": "Couldn’t write here — choose a folder",
    "error.unsupported": "This file type can’t be converted yet",
    "error.conversion_failed": "Conversion failed",
    "queue.empty": "No files",
    "format.kind.image": "image",
    "format.kind.document": "document",
    "format.kind.pdf": "PDF document",
    "format.kind.data": "data",
    "format.kind.audio": "audio",
    "format.kind.video": "video",
    "format.kind.archive": "archive",
    "bytes.saved": "saved",
    "done.ok": "Done",
    "action.done": "Done",
    "workspace.files": "Files",
    "workspace.units": "Units",
    "units.swap": "Swap",
    "units.copy": "Copy",
    "units.sidebar": "Categories",
    "units.from": "From",
    "units.to": "To",
    "units.refresh": "Refresh",
    "units.updated": "Updated",
    "units.stale": "Using saved rates",
    "units.offline": "Offline — last saved rates",
    "units.auto_refresh": "Refresh exchange rates automatically",
    "settings.currency": "Currency",
    "settings.currency.privacy": "Exchange rates come from Frankfurter. No account. Amounts stay on this Mac.",
    "category.angle": "Angle",
    "category.area": "Area",
    "category.currency": "Currency",
    "category.data": "Data",
    "category.energy": "Energy",
    "category.force": "Force",
    "category.fuel": "Fuel",
    "category.length": "Length",
    "category.power": "Power",
    "category.pressure": "Pressure",
    "category.speed": "Speed",
    "category.temperature": "Temperature",
    "category.time": "Time",
    "category.volume": "Volume",
    "category.weight": "Weight",
    "category.frequency": "Frequency",
    "category.acceleration": "Acceleration",
    "category.illuminance": "Illuminance",
}

# Plural: one / other (and few/many where the locale needs them via 'other' fallback)
PLURAL_EN = {
    "queue.count": {"one": "%lld file", "other": "%lld files"},
}

INFO_EN = {
    "CFBundleDisplayName": "Kiln",
    "CFBundleName": "Kiln",
    "Convert with Kiln": "Convert with Kiln",
}

# locale -> {key: value}
TR: dict[str, dict[str, str]] = {
    "es": {
        "drop.title": "Suelta archivos para convertir",
        "drop.subtitle": "o busca en tu Mac",
        "drop.browse": "Explorar",
        "mode.convert": "Convertir",
        "mode.compress": "Comprimir",
        "mode.combine": "Combinar",
        "mode.split": "Dividir",
        "action.convert": "Convertir",
        "action.compress": "Comprimir",
        "action.combine": "Combinar",
        "action.split": "Dividir",
        "action.cancel": "Cancelar",
        "action.reveal": "Mostrar en el Finder",
        "action.clear": "Vaciar",
        "action.settings": "Ajustes",
        "action.remove": "Eliminar",
        "status.ready": "Listo",
        "status.converting": "Convirtiendo",
        "status.done": "Hecho",
        "status.failed": "Error",
        "status.unsupported": "No compatible",
        "family.image": "Imagen",
        "family.pdf": "PDF",
        "family.document": "Documento",
        "family.data": "Datos",
        "family.audio": "Audio",
        "family.video": "Vídeo",
        "family.archive": "Archivo",
        "preset.original": "Original",
        "preset.original.detail": "Conservar el tamaño original",
        "preset.web": "Web 1920",
        "preset.web.detail": "Lado largo 1920 px",
        "preset.email": "Correo",
        "preset.email.detail": "Unos 1 MB",
        "preset.share_jpeg": "JPEG para enviar",
        "preset.share_jpeg.detail": "JPEG listo para compartir",
        "preset.lossless": "Sin pérdida",
        "preset.lossless.detail": "Sin pérdida extra de calidad",
        "preset.smallest": "Más pequeño",
        "preset.smallest.detail": "El archivo más pequeño práctico",
        "settings.title": "Ajustes",
        "settings.language": "Idioma",
        "settings.language.system": "Usar el del sistema",
        "settings.appearance": "Apariencia",
        "settings.appearance.system": "Sistema",
        "settings.appearance.light": "Claro",
        "settings.appearance.dark": "Oscuro",
        "settings.destination": "Guardar archivos convertidos",
        "settings.destination.same": "Misma carpeta que el original",
        "settings.destination.downloads": "Descargas",
        "settings.destination.choose": "Elegir carpeta…",
        "settings.notifications": "Avisar al terminar un lote",
        "inspector.quality": "Calidad",
        "inspector.resize": "Redimensionar",
        "inspector.resize.original": "Tamaño original",
        "inspector.metadata": "Metadatos",
        "inspector.metadata.strip": "Quitar ubicación y datos de la cámara",
        "inspector.advanced": "Avanzado",
        "inspector.pages": "Páginas",
        "inspector.preview": "Vista previa",
        "inspector.via_ffmpeg": "vía ffmpeg",
        "inspector.destination": "Destino",
        "error.write_permission": "No se pudo guardar aquí — elige una carpeta",
        "error.unsupported": "Este tipo de archivo aún no se puede convertir",
        "error.conversion_failed": "Error de conversión",
        "queue.empty": "Sin archivos",
        "format.kind.image": "imagen",
        "format.kind.document": "documento",
        "format.kind.pdf": "documento PDF",
        "format.kind.data": "datos",
        "format.kind.audio": "audio",
        "format.kind.video": "vídeo",
        "format.kind.archive": "archivo",
        "bytes.saved": "ahorrado",
        "done.ok": "Hecho",
    },
    "fr": {
        "drop.title": "Déposez des fichiers à convertir",
        "drop.subtitle": "ou parcourez votre Mac",
        "drop.browse": "Parcourir",
        "mode.convert": "Convertir",
        "mode.compress": "Compresser",
        "mode.combine": "Fusionner",
        "mode.split": "Diviser",
        "action.convert": "Convertir",
        "action.compress": "Compresser",
        "action.combine": "Fusionner",
        "action.split": "Diviser",
        "action.cancel": "Annuler",
        "action.reveal": "Afficher dans le Finder",
        "action.clear": "Tout effacer",
        "action.settings": "Réglages",
        "action.remove": "Retirer",
        "status.ready": "Prêt",
        "status.converting": "Conversion",
        "status.done": "Terminé",
        "status.failed": "Échec",
        "status.unsupported": "Non pris en charge",
        "family.image": "Image",
        "family.pdf": "PDF",
        "family.document": "Document",
        "family.data": "Données",
        "family.audio": "Audio",
        "family.video": "Vidéo",
        "family.archive": "Archive",
        "preset.original": "Original",
        "preset.original.detail": "Conserver la taille d’origine",
        "preset.web": "Web 1920",
        "preset.web.detail": "Grand côté 1920 px",
        "preset.email": "E-mail",
        "preset.email.detail": "Environ 1 Mo",
        "preset.share_jpeg": "JPEG à partager",
        "preset.share_jpeg.detail": "JPEG pratique à envoyer",
        "preset.lossless": "Sans perte",
        "preset.lossless.detail": "Aucune perte de qualité supplémentaire",
        "preset.smallest": "Plus petit",
        "preset.smallest.detail": "Le plus petit fichier pratique",
        "settings.title": "Réglages",
        "settings.language": "Langue",
        "settings.language.system": "Suivre le système",
        "settings.appearance": "Apparence",
        "settings.appearance.system": "Système",
        "settings.appearance.light": "Clair",
        "settings.appearance.dark": "Sombre",
        "settings.destination": "Enregistrer les fichiers convertis",
        "settings.destination.same": "Même dossier que l’original",
        "settings.destination.downloads": "Téléchargements",
        "settings.destination.choose": "Choisir un dossier…",
        "settings.notifications": "Notifier à la fin d’un lot",
        "inspector.quality": "Qualité",
        "inspector.resize": "Redimensionner",
        "inspector.resize.original": "Taille d’origine",
        "inspector.metadata": "Métadonnées",
        "inspector.metadata.strip": "Retirer la position et les données de l’appareil",
        "inspector.advanced": "Avancé",
        "inspector.pages": "Pages",
        "inspector.preview": "Aperçu",
        "inspector.via_ffmpeg": "via ffmpeg",
        "inspector.destination": "Destination",
        "error.write_permission": "Impossible d’écrire ici — choisissez un dossier",
        "error.unsupported": "Ce type de fichier ne peut pas encore être converti",
        "error.conversion_failed": "Échec de la conversion",
        "queue.empty": "Aucun fichier",
        "format.kind.image": "image",
        "format.kind.document": "document",
        "format.kind.pdf": "document PDF",
        "format.kind.data": "données",
        "format.kind.audio": "audio",
        "format.kind.video": "vidéo",
        "format.kind.archive": "archive",
        "bytes.saved": "gagnés",
        "done.ok": "Terminé",
    },
    "de": {
        "drop.title": "Dateien zum Konvertieren ablegen",
        "drop.subtitle": "oder auf dem Mac suchen",
        "drop.browse": "Durchsuchen",
        "mode.convert": "Konvertieren",
        "mode.compress": "Komprimieren",
        "mode.combine": "Zusammenführen",
        "mode.split": "Teilen",
        "action.convert": "Konvertieren",
        "action.compress": "Komprimieren",
        "action.combine": "Zusammenführen",
        "action.split": "Teilen",
        "action.cancel": "Abbrechen",
        "action.reveal": "Im Finder zeigen",
        "action.clear": "Leeren",
        "action.settings": "Einstellungen",
        "action.remove": "Entfernen",
        "status.ready": "Bereit",
        "status.converting": "Konvertieren",
        "status.done": "Fertig",
        "status.failed": "Fehlgeschlagen",
        "status.unsupported": "Nicht unterstützt",
        "family.image": "Bild",
        "family.pdf": "PDF",
        "family.document": "Dokument",
        "family.data": "Daten",
        "family.audio": "Audio",
        "family.video": "Video",
        "family.archive": "Archiv",
        "preset.original": "Original",
        "preset.original.detail": "Originalgröße behalten",
        "preset.web": "Web 1920",
        "preset.web.detail": "Längste Kante 1920 px",
        "preset.email": "E-Mail",
        "preset.email.detail": "Etwa 1 MB",
        "preset.share_jpeg": "JPEG zum Teilen",
        "preset.share_jpeg.detail": "Alltagstaugliches JPEG",
        "preset.lossless": "Verlustfrei",
        "preset.lossless.detail": "Kein zusätzlicher Qualitätsverlust",
        "preset.smallest": "Kleinstes",
        "preset.smallest.detail": "Kleinste sinnvolle Datei",
        "settings.title": "Einstellungen",
        "settings.language": "Sprache",
        "settings.language.system": "Systemsprache",
        "settings.appearance": "Erscheinungsbild",
        "settings.appearance.system": "System",
        "settings.appearance.light": "Hell",
        "settings.appearance.dark": "Dunkel",
        "settings.destination": "Konvertierte Dateien speichern",
        "settings.destination.same": "Gleicher Ordner wie das Original",
        "settings.destination.downloads": "Downloads",
        "settings.destination.choose": "Ordner wählen …",
        "settings.notifications": "Nach einem Stapel benachrichtigen",
        "inspector.quality": "Qualität",
        "inspector.resize": "Größe ändern",
        "inspector.resize.original": "Originalgröße",
        "inspector.metadata": "Metadaten",
        "inspector.metadata.strip": "Ort und Kameradaten entfernen",
        "inspector.advanced": "Erweitert",
        "inspector.pages": "Seiten",
        "inspector.preview": "Vorschau",
        "inspector.via_ffmpeg": "via ffmpeg",
        "inspector.destination": "Ziel",
        "error.write_permission": "Hier kein Schreibzugriff — Ordner wählen",
        "error.unsupported": "Dieser Dateityp kann noch nicht konvertiert werden",
        "error.conversion_failed": "Konvertierung fehlgeschlagen",
        "queue.empty": "Keine Dateien",
        "format.kind.image": "Bild",
        "format.kind.document": "Dokument",
        "format.kind.pdf": "PDF-Dokument",
        "format.kind.data": "Daten",
        "format.kind.audio": "Audio",
        "format.kind.video": "Video",
        "format.kind.archive": "Archiv",
        "bytes.saved": "gespart",
        "done.ok": "Fertig",
    },
}

# Remaining locales: full UI chrome (not English copies for distinctive languages)
MORE = {
    "it": {
        "drop.title": "Trascina i file da convertire",
        "drop.subtitle": "oppure sfoglia il Mac",
        "drop.browse": "Sfoglia",
        "mode.convert": "Converti",
        "mode.compress": "Comprimi",
        "mode.combine": "Unisci",
        "mode.split": "Dividi",
        "action.convert": "Converti",
        "action.compress": "Comprimi",
        "action.combine": "Unisci",
        "action.split": "Dividi",
        "action.cancel": "Annulla",
        "action.reveal": "Mostra nel Finder",
        "action.clear": "Svuota",
        "action.settings": "Impostazioni",
        "action.remove": "Rimuovi",
        "status.ready": "Pronto",
        "status.converting": "Conversione",
        "status.done": "Fatto",
        "status.failed": "Non riuscito",
        "status.unsupported": "Non supportato",
        "family.image": "Immagine",
        "family.pdf": "PDF",
        "family.document": "Documento",
        "family.data": "Dati",
        "family.audio": "Audio",
        "family.video": "Video",
        "family.archive": "Archivio",
        "preset.original": "Originale",
        "preset.original.detail": "Mantieni le dimensioni originali",
        "preset.web": "Web 1920",
        "preset.web.detail": "Lato lungo 1920 px",
        "preset.email": "Email",
        "preset.email.detail": "Circa 1 MB",
        "preset.share_jpeg": "JPEG da condividere",
        "preset.share_jpeg.detail": "JPEG pratico da inviare",
        "preset.lossless": "Senza perdita",
        "preset.lossless.detail": "Nessuna perdita extra di qualità",
        "preset.smallest": "Più piccolo",
        "preset.smallest.detail": "Il file più piccolo pratico",
        "settings.title": "Impostazioni",
        "settings.language": "Lingua",
        "settings.language.system": "Come il sistema",
        "settings.appearance": "Aspetto",
        "settings.appearance.system": "Sistema",
        "settings.appearance.light": "Chiaro",
        "settings.appearance.dark": "Scuro",
        "settings.destination": "Salva i file convertiti",
        "settings.destination.same": "Stessa cartella dell’originale",
        "settings.destination.downloads": "Download",
        "settings.destination.choose": "Scegli cartella…",
        "settings.notifications": "Notifica a fine batch",
        "inspector.quality": "Qualità",
        "inspector.resize": "Ridimensiona",
        "inspector.resize.original": "Dimensioni originali",
        "inspector.metadata": "Metadati",
        "inspector.metadata.strip": "Rimuovi posizione e dati della fotocamera",
        "inspector.advanced": "Avanzate",
        "inspector.pages": "Pagine",
        "inspector.preview": "Anteprima",
        "inspector.via_ffmpeg": "via ffmpeg",
        "inspector.destination": "Destinazione",
        "error.write_permission": "Impossibile scrivere qui — scegli una cartella",
        "error.unsupported": "Questo tipo di file non è ancora convertibile",
        "error.conversion_failed": "Conversione non riuscita",
        "queue.empty": "Nessun file",
        "format.kind.image": "immagine",
        "format.kind.document": "documento",
        "format.kind.pdf": "documento PDF",
        "format.kind.data": "dati",
        "format.kind.audio": "audio",
        "format.kind.video": "video",
        "format.kind.archive": "archivio",
        "bytes.saved": "risparmiati",
        "done.ok": "Fatto",
    },
}

# Compact remaining translations as key lists aligned to EN keys — written out fully below.
PT_BR = {
    "drop.title": "Solte arquivos para converter",
    "drop.subtitle": "ou navegue no seu Mac",
    "drop.browse": "Navegar",
    "mode.convert": "Converter",
    "mode.compress": "Comprimir",
    "mode.combine": "Combinar",
    "mode.split": "Dividir",
    "action.convert": "Converter",
    "action.compress": "Comprimir",
    "action.combine": "Combinar",
    "action.split": "Dividir",
    "action.cancel": "Cancelar",
    "action.reveal": "Mostrar no Finder",
    "action.clear": "Limpar",
    "action.settings": "Ajustes",
    "action.remove": "Remover",
    "status.ready": "Pronto",
    "status.converting": "Convertendo",
    "status.done": "Concluído",
    "status.failed": "Falhou",
    "status.unsupported": "Sem suporte",
    "family.image": "Imagem",
    "family.pdf": "PDF",
    "family.document": "Documento",
    "family.data": "Dados",
    "family.audio": "Áudio",
    "family.video": "Vídeo",
    "family.archive": "Arquivo",
    "preset.original": "Original",
    "preset.original.detail": "Manter o tamanho original",
    "preset.web": "Web 1920",
    "preset.web.detail": "Lado maior 1920 px",
    "preset.email": "E-mail",
    "preset.email.detail": "Cerca de 1 MB",
    "preset.share_jpeg": "JPEG para enviar",
    "preset.share_jpeg.detail": "JPEG prático para compartilhar",
    "preset.lossless": "Sem perdas",
    "preset.lossless.detail": "Sem perda extra de qualidade",
    "preset.smallest": "Menor",
    "preset.smallest.detail": "O menor arquivo prático",
    "settings.title": "Ajustes",
    "settings.language": "Idioma",
    "settings.language.system": "Usar o do sistema",
    "settings.appearance": "Aparência",
    "settings.appearance.system": "Sistema",
    "settings.appearance.light": "Claro",
    "settings.appearance.dark": "Escuro",
    "settings.destination": "Salvar arquivos convertidos",
    "settings.destination.same": "Mesma pasta do original",
    "settings.destination.downloads": "Downloads",
    "settings.destination.choose": "Escolher pasta…",
    "settings.notifications": "Avisar ao terminar um lote",
    "inspector.quality": "Qualidade",
    "inspector.resize": "Redimensionar",
    "inspector.resize.original": "Tamanho original",
    "inspector.metadata": "Metadados",
    "inspector.metadata.strip": "Remover localização e dados da câmera",
    "inspector.advanced": "Avançado",
    "inspector.pages": "Páginas",
    "inspector.preview": "Pré-visualização",
    "inspector.via_ffmpeg": "via ffmpeg",
    "inspector.destination": "Destino",
    "error.write_permission": "Não foi possível gravar aqui — escolha uma pasta",
    "error.unsupported": "Este tipo de arquivo ainda não pode ser convertido",
    "error.conversion_failed": "Falha na conversão",
    "queue.empty": "Nenhum arquivo",
    "format.kind.image": "imagem",
    "format.kind.document": "documento",
    "format.kind.pdf": "documento PDF",
    "format.kind.data": "dados",
    "format.kind.audio": "áudio",
    "format.kind.video": "vídeo",
    "format.kind.archive": "arquivo",
    "bytes.saved": "economizados",
    "done.ok": "Concluído",
}

PT_PT = {
    **PT_BR,
    "drop.title": "Largue ficheiros para converter",
    "drop.subtitle": "ou navegue no seu Mac",
    "drop.browse": "Navegar",
    "action.clear": "Limpar",
    "action.settings": "Definições",
    "status.done": "Concluído",
    "status.failed": "Falhou",
    "status.unsupported": "Não suportado",
    "family.archive": "Arquivo",
    "preset.share_jpeg": "JPEG para partilhar",
    "preset.share_jpeg.detail": "JPEG prático para enviar",
    "preset.smallest.detail": "O ficheiro mais pequeno prático",
    "settings.title": "Definições",
    "settings.language": "Idioma",
    "settings.destination": "Guardar ficheiros convertidos",
    "settings.destination.same": "Mesma pasta que o original",
    "settings.destination.choose": "Escolher pasta…",
    "settings.notifications": "Notificar quando um lote terminar",
    "inspector.preview": "Pré-visualização",
    "error.write_permission": "Não foi possível escrever aqui — escolha uma pasta",
    "error.unsupported": "Este tipo de ficheiro ainda não pode ser convertido",
    "error.conversion_failed": "A conversão falhou",
    "queue.empty": "Nenhum ficheiro",
    "format.kind.archive": "arquivo",
    "done.ok": "Concluído",
}

# Distinctive (not a copy of PT-BR): a few Portugal-only word choices already applied.

NL = {
    "drop.title": "Sleep bestanden om te converteren",
    "drop.subtitle": "of blader op je Mac",
    "drop.browse": "Bladeren",
    "mode.convert": "Converteren",
    "mode.compress": "Comprimeren",
    "mode.combine": "Samenvoegen",
    "mode.split": "Splitsen",
    "action.convert": "Converteren",
    "action.compress": "Comprimeren",
    "action.combine": "Samenvoegen",
    "action.split": "Splitsen",
    "action.cancel": "Annuleer",
    "action.reveal": "Toon in Finder",
    "action.clear": "Wis",
    "action.settings": "Instellingen",
    "action.remove": "Verwijder",
    "status.ready": "Gereed",
    "status.converting": "Bezig",
    "status.done": "Klaar",
    "status.failed": "Mislukt",
    "status.unsupported": "Niet ondersteund",
    "family.image": "Afbeelding",
    "family.pdf": "PDF",
    "family.document": "Document",
    "family.data": "Data",
    "family.audio": "Audio",
    "family.video": "Video",
    "family.archive": "Archief",
    "preset.original": "Origineel",
    "preset.original.detail": "Bronformaat behouden",
    "preset.web": "Web 1920",
    "preset.web.detail": "Lange zijde 1920 px",
    "preset.email": "E-mail",
    "preset.email.detail": "Ongeveer 1 MB",
    "preset.share_jpeg": "JPEG om te delen",
    "preset.share_jpeg.detail": "Handige JPEG om te versturen",
    "preset.lossless": "Verliesvrij",
    "preset.lossless.detail": "Geen extra kwaliteitsverlies",
    "preset.smallest": "Kleinste",
    "preset.smallest.detail": "Kleinste praktische bestand",
    "settings.title": "Instellingen",
    "settings.language": "Taal",
    "settings.language.system": "Systeemtaal",
    "settings.appearance": "Weergave",
    "settings.appearance.system": "Systeem",
    "settings.appearance.light": "Licht",
    "settings.appearance.dark": "Donker",
    "settings.destination": "Geconverteerde bestanden bewaren",
    "settings.destination.same": "Dezelfde map als het origineel",
    "settings.destination.downloads": "Downloads",
    "settings.destination.choose": "Kies een map…",
    "settings.notifications": "Meld wanneer een batch klaar is",
    "inspector.quality": "Kwaliteit",
    "inspector.resize": "Formaat",
    "inspector.resize.original": "Origineel formaat",
    "inspector.metadata": "Metadata",
    "inspector.metadata.strip": "Locatie- en cameragegevens verwijderen",
    "inspector.advanced": "Geavanceerd",
    "inspector.pages": "Pagina’s",
    "inspector.preview": "Voorvertoning",
    "inspector.via_ffmpeg": "via ffmpeg",
    "inspector.destination": "Bestemming",
    "error.write_permission": "Kan hier niet schrijven — kies een map",
    "error.unsupported": "Dit bestandstype kan nog niet worden geconverteerd",
    "error.conversion_failed": "Conversie mislukt",
    "queue.empty": "Geen bestanden",
    "format.kind.image": "afbeelding",
    "format.kind.document": "document",
    "format.kind.pdf": "PDF-document",
    "format.kind.data": "data",
    "format.kind.audio": "audio",
    "format.kind.video": "video",
    "format.kind.archive": "archief",
    "bytes.saved": "bespaard",
    "done.ok": "Klaar",
}


def nordic(drop, browse, convert, compress, combine, split, cancel, reveal, clear, settings, remove,
           ready, converting, done, failed, unsupported, image, document, data, audio, video, archive,
           original, original_d, web_d, email, email_d, share, share_d, lossless, lossless_d, smallest, smallest_d,
           title, language, lang_sys, appearance, sys, light, dark, dest, dest_same, downloads, choose, notify,
           quality, resize, resize_o, metadata, strip, advanced, pages, preview, destination,
           err_write, err_unsup, err_fail, empty, kind_image, kind_doc, kind_pdf, kind_data, kind_audio, kind_video, kind_archive,
           saved, ok):
    return {
        "drop.title": drop, "drop.subtitle": browse[0], "drop.browse": browse[1],
        "mode.convert": convert, "mode.compress": compress, "mode.combine": combine, "mode.split": split,
        "action.convert": convert, "action.compress": compress, "action.combine": combine, "action.split": split,
        "action.cancel": cancel, "action.reveal": reveal, "action.clear": clear, "action.settings": settings, "action.remove": remove,
        "status.ready": ready, "status.converting": converting, "status.done": done, "status.failed": failed, "status.unsupported": unsupported,
        "family.image": image, "family.pdf": "PDF", "family.document": document, "family.data": data,
        "family.audio": audio, "family.video": video, "family.archive": archive,
        "preset.original": original, "preset.original.detail": original_d,
        "preset.web": "Web 1920", "preset.web.detail": web_d,
        "preset.email": email, "preset.email.detail": email_d,
        "preset.share_jpeg": share, "preset.share_jpeg.detail": share_d,
        "preset.lossless": lossless, "preset.lossless.detail": lossless_d,
        "preset.smallest": smallest, "preset.smallest.detail": smallest_d,
        "settings.title": title, "settings.language": language, "settings.language.system": lang_sys,
        "settings.appearance": appearance, "settings.appearance.system": sys,
        "settings.appearance.light": light, "settings.appearance.dark": dark,
        "settings.destination": dest, "settings.destination.same": dest_same,
        "settings.destination.downloads": downloads, "settings.destination.choose": choose,
        "settings.notifications": notify,
        "inspector.quality": quality, "inspector.resize": resize, "inspector.resize.original": resize_o,
        "inspector.metadata": metadata, "inspector.metadata.strip": strip, "inspector.advanced": advanced,
        "inspector.pages": pages, "inspector.preview": preview, "inspector.via_ffmpeg": "via ffmpeg",
        "inspector.destination": destination,
        "error.write_permission": err_write, "error.unsupported": err_unsup, "error.conversion_failed": err_fail,
        "queue.empty": empty,
        "format.kind.image": kind_image, "format.kind.document": kind_doc, "format.kind.pdf": kind_pdf,
        "format.kind.data": kind_data, "format.kind.audio": kind_audio, "format.kind.video": kind_video,
        "format.kind.archive": kind_archive, "bytes.saved": saved, "done.ok": ok,
    }


DA = nordic(
    "Slip filer for at konvertere", ("eller gennemse din Mac", "Gennemse"),
    "Konvertér", "Komprimér", "Kombinér", "Opdel", "Annuller", "Vis i Finder", "Ryd", "Indstillinger", "Fjern",
    "Klar", "Konverterer", "Færdig", "Mislykkedes", "Ikke understøttet",
    "Billede", "Dokument", "Data", "Lyd", "Video", "Arkiv",
    "Original", "Behold kildestørrelsen", "Lang side 1920 px", "E-mail", "Cirka 1 MB",
    "JPEG til deling", "Praktisk JPEG til at sende", "Tabsfri", "Intet ekstra kvalitetstab", "Mindste", "Mindste praktiske fil",
    "Indstillinger", "Sprog", "Følg systemet", "Udseende", "System", "Lyst", "Mørkt",
    "Gem konverterede filer", "Samme mappe som originalen", "Overførsler", "Vælg mappe…", "Giv besked når et batch er færdigt",
    "Kvalitet", "Tilpas størrelse", "Original størrelse", "Metadata", "Fjern sted og kameradata", "Avanceret",
    "Sider", "Forhåndsvisning", "Destination",
    "Kunne ikke skrive her — vælg en mappe", "Denne filtype kan ikke konverteres endnu", "Konvertering mislykkedes",
    "Ingen filer", "billede", "dokument", "PDF-dokument", "data", "lyd", "video", "arkiv", "sparet", "Færdig",
)

SV = nordic(
    "Släpp filer att konvertera", ("eller bläddra på din Mac", "Bläddra"),
    "Konvertera", "Komprimera", "Kombinera", "Dela upp", "Avbryt", "Visa i Finder", "Rensa", "Inställningar", "Ta bort",
    "Redo", "Konverterar", "Klar", "Misslyckades", "Stöds inte",
    "Bild", "Dokument", "Data", "Ljud", "Video", "Arkiv",
    "Original", "Behåll källstorleken", "Långsida 1920 px", "E-post", "Cirka 1 MB",
    "JPEG att dela", "Praktisk JPEG att skicka", "Förlustfri", "Ingen extra kvalitetsförlust", "Minsta", "Minsta praktiska fil",
    "Inställningar", "Språk", "Följ systemet", "Utseende", "System", "Ljust", "Mörkt",
    "Spara konverterade filer", "Samma mapp som originalet", "Hämtade filer", "Välj mapp…", "Meddela när en sats är klar",
    "Kvalitet", "Ändra storlek", "Originalstorlek", "Metadata", "Ta bort plats- och kameradata", "Avancerat",
    "Sidor", "Förhandsvisning", "Mål",
    "Kunde inte skriva här — välj en mapp", "Den här filtypen kan inte konverteras än", "Konverteringen misslyckades",
    "Inga filer", "bild", "dokument", "PDF-dokument", "data", "ljud", "video", "arkiv", "sparat", "Klar",
)

NB = nordic(
    "Slipp filer for å konvertere", ("eller bla gjennom Mac-en", "Bla gjennom"),
    "Konverter", "Komprimer", "Slå sammen", "Del opp", "Avbryt", "Vis i Finder", "Tøm", "Innstillinger", "Fjern",
    "Klar", "Konverterer", "Ferdig", "Mislyktes", "Ikke støttet",
    "Bilde", "Dokument", "Data", "Lyd", "Video", "Arkiv",
    "Original", "Behold kildestørrelsen", "Langside 1920 px", "E-post", "Omtrent 1 MB",
    "JPEG for deling", "Praktisk JPEG å sende", "Tapsfri", "Ingen ekstra kvalitetstap", "Minste", "Minste praktiske fil",
    "Innstillinger", "Språk", "Følg systemet", "Utseende", "System", "Lyst", "Mørkt",
    "Lagre konverterte filer", "Samme mappe som originalen", "Nedlastinger", "Velg mappe…", "Varsle når et parti er ferdig",
    "Kvalitet", "Endre størrelse", "Originalstørrelse", "Metadata", "Fjern sted og kameradata", "Avansert",
    "Sider", "Forhåndsvisning", "Mål",
    "Kunne ikke skrive her — velg en mappe", "Denne filtypen kan ikke konverteres ennå", "Konvertering mislyktes",
    "Ingen filer", "bilde", "dokument", "PDF-dokument", "data", "lyd", "video", "arkiv", "spart", "Ferdig",
)

FI = nordic(
    "Pudota tiedostot muunnettaviksi", ("tai selaa Maciasi", "Selaa"),
    "Muunna", "Pakkaa", "Yhdistä", "Jaa", "Peruuta", "Näytä Finderissa", "Tyhjennä", "Asetukset", "Poista",
    "Valmis", "Muunnetaan", "Valmis", "Epäonnistui", "Ei tuettu",
    "Kuva", "Asiakirja", "Data", "Ääni", "Video", "Arkisto",
    "Alkuperäinen", "Säilytä lähteen koko", "Pitkä sivu 1920 px", "Sähköposti", "Noin 1 Mt",
    "JPEG jaettavaksi", "Käytännöllinen JPEG lähetykseen", "Häviötön", "Ei lisälaadun menetystä", "Pienin", "Pienin käytännöllinen tiedosto",
    "Asetukset", "Kieli", "Järjestelmän mukaan", "Ulkoasu", "Järjestelmä", "Vaalea", "Tumma",
    "Tallenna muunnetut tiedostot", "Sama kansio kuin alkuperäinen", "Lataukset", "Valitse kansio…", "Ilmoita erän valmistuttua",
    "Laatu", "Koko", "Alkuperäinen koko", "Metatiedot", "Poista sijainti- ja kameratiedot", "Lisäasetukset",
    "Sivut", "Esikatselu", "Kohde",
    "Tänne ei voi kirjoittaa — valitse kansio", "Tätä tiedostotyyppiä ei voi vielä muuntaa", "Muunnos epäonnistui",
    "Ei tiedostoja", "kuva", "asiakirja", "PDF-asiakirja", "data", "ääni", "video", "arkisto", "säästetty", "Valmis",
)

PL = nordic(
    "Upuść pliki do konwersji", ("albo przeglądaj Maca", "Przeglądaj"),
    "Konwertuj", "Kompresuj", "Połącz", "Podziel", "Anuluj", "Pokaż w Finderze", "Wyczyść", "Ustawienia", "Usuń",
    "Gotowe", "Konwertowanie", "Ukończono", "Niepowodzenie", "Nieobsługiwane",
    "Obraz", "Dokument", "Dane", "Dźwięk", "Wideo", "Archiwum",
    "Oryginał", "Zachowaj rozmiar źródła", "Dłuższy bok 1920 px", "E-mail", "Około 1 MB",
    "JPEG do wysyłki", "Wygodny JPEG do udostępniania", "Bezstratnie", "Bez dodatkowej utraty jakości", "Najmniejszy", "Najmniejszy praktyczny plik",
    "Ustawienia", "Język", "Jak w systemie", "Wygląd", "System", "Jasny", "Ciemny",
    "Zapisuj przekonwertowane pliki", "Ten sam folder co oryginał", "Pobrane", "Wybierz folder…", "Powiadom po zakończeniu partii",
    "Jakość", "Rozmiar", "Oryginalny rozmiar", "Metadane", "Usuń lokalizację i dane aparatu", "Zaawansowane",
    "Strony", "Podgląd", "Miejsce docelowe",
    "Nie można tu zapisać — wybierz folder", "Tego typu pliku nie można jeszcze konwertować", "Konwersja nie powiodła się",
    "Brak plików", "obraz", "dokument", "dokument PDF", "dane", "dźwięk", "wideo", "archiwum", "zaoszczędzono", "Ukończono",
)

CS = nordic(
    "Přetáhněte soubory k převodu", ("nebo procházejte Mac", "Procházet"),
    "Převést", "Komprimovat", "Sloučit", "Rozdělit", "Zrušit", "Zobrazit ve Finderu", "Vymazat", "Nastavení", "Odebrat",
    "Připraveno", "Převádí se", "Hotovo", "Selhalo", "Nepodporováno",
    "Obrázek", "Dokument", "Data", "Zvuk", "Video", "Archiv",
    "Originál", "Ponechat původní velikost", "Delší strana 1920 px", "E-mail", "Asi 1 MB",
    "JPEG ke sdílení", "Praktický JPEG k odeslání", "Bezeztrátově", "Bez další ztráty kvality", "Nejmenší", "Nejmenší praktický soubor",
    "Nastavení", "Jazyk", "Podle systému", "Vzhled", "Systém", "Světlý", "Tmavý",
    "Ukládat převedené soubory", "Stejná složka jako originál", "Stahování", "Vybrat složku…", "Upozornit po dokončení dávky",
    "Kvalita", "Velikost", "Původní velikost", "Metadata", "Odebrat polohu a data fotoaparátu", "Pokročilé",
    "Stránky", "Náhled", "Cíl",
    "Sem nelze zapisovat — vyberte složku", "Tento typ souboru zatím nelze převést", "Převod selhal",
    "Žádné soubory", "obrázek", "dokument", "dokument PDF", "data", "zvuk", "video", "archiv", "ušetřeno", "Hotovo",
)

HU = nordic(
    "Húzza ide a fájlokat az átalakításhoz", ("vagy tallózzon a Macen", "Tallózás"),
    "Átalakítás", "Tömörítés", "Összevonás", "Felosztás", "Mégsem", "Megjelenítés a Finderben", "Törlés", "Beállítások", "Eltávolítás",
    "Kész", "Átalakítás", "Kész", "Sikertelen", "Nem támogatott",
    "Kép", "Dokumentum", "Adat", "Hang", "Videó", "Archívum",
    "Eredeti", "Forrásméret megtartása", "Hosszú él 1920 px", "E-mail", "Kb. 1 MB",
    "JPEG megosztáshoz", "Könnyen küldhető JPEG", "Veszteségmentes", "Nincs extra minőségvesztés", "Legkisebb", "A lehető legkisebb fájl",
    "Beállítások", "Nyelv", "Rendszer nyelve", "Megjelenés", "Rendszer", "Világos", "Sötét",
    "Átalakított fájlok mentése", "Ugyanaz a mappa, mint az eredeti", "Letöltések", "Mappa választása…", "Értesítés a köteg végén",
    "Minőség", "Átméretezés", "Eredeti méret", "Metaadatok", "Helyszín és kameraadatok eltávolítása", "Speciális",
    "Oldalak", "Előnézet", "Cél",
    "Ide nem lehet írni — válasszon mappát", "Ez a fájltípus még nem alakítható át", "Az átalakítás sikertelen",
    "Nincsenek fájlok", "kép", "dokumentum", "PDF-dokumentum", "adat", "hang", "videó", "archívum", "megtakarítva", "Kész",
)

RO = nordic(
    "Trageți fișiere pentru conversie", ("sau răsfoiți Mac-ul", "Răsfoire"),
    "Conversie", "Comprimare", "Combinare", "Divizare", "Anulare", "Arată în Finder", "Golește", "Reglaje", "Elimină",
    "Gata", "Se convertește", "Terminat", "Eșuat", "Neacceptat",
    "Imagine", "Document", "Date", "Audio", "Video", "Arhivă",
    "Original", "Păstrează dimensiunea sursei", "Latura lungă 1920 px", "E-mail", "Aproximativ 1 MB",
    "JPEG de trimis", "JPEG practic de partajat", "Fără pierderi", "Fără pierdere suplimentară de calitate", "Cel mai mic", "Cel mai mic fișier practic",
    "Reglaje", "Limbă", "Ca în sistem", "Aspect", "Sistem", "Deschis", "Întunecat",
    "Salvează fișierele convertite", "Aceeași mapă ca originalul", "Descărcări", "Alegeți mapa…", "Notifică la finalul unui lot",
    "Calitate", "Redimensionare", "Dimensiune originală", "Metadate", "Elimină locația și datele camerei", "Avansat",
    "Pagini", "Previzualizare", "Destinație",
    "Nu s-a putut scrie aici — alegeți o mapă", "Acest tip de fișier nu poate fi convertit încă", "Conversia a eșuat",
    "Niciun fișier", "imagine", "document", "document PDF", "date", "audio", "video", "arhivă", "economisit", "Terminat",
)

EL = nordic(
    "Αποθέστε αρχεία για μετατροπή", ("ή περιηγηθείτε στο Mac", "Περιήγηση"),
    "Μετατροπή", "Συμπίεση", "Συνένωση", "Διαχωρισμός", "Ακύρωση", "Εμφάνιση στο Finder", "Εκκαθάριση", "Ρυθμίσεις", "Αφαίρεση",
    "Έτοιμο", "Μετατροπή", "Ολοκληρώθηκε", "Αποτυχία", "Μη υποστηριζόμενο",
    "Εικόνα", "Έγγραφο", "Δεδομένα", "Ήχος", "Βίντεο", "Αρχείο",
    "Αρχικό", "Διατήρηση μεγέθους πηγής", "Μεγάλη πλευρά 1920 px", "Email", "Περίπου 1 MB",
    "JPEG για κοινοποίηση", "Βολικό JPEG για αποστολή", "Χωρίς απώλειες", "Χωρίς επιπλέον απώλεια ποιότητας", "Μικρότερο", "Το μικρότερο πρακτικό αρχείο",
    "Ρυθμίσεις", "Γλώσσα", "Όπως το σύστημα", "Εμφάνιση", "Σύστημα", "Φωτεινό", "Σκοτεινό",
    "Αποθήκευση μετατρεμμένων αρχείων", "Ίδιος φάκελος με το πρωτότυπο", "Λήψεις", "Επιλογή φακέλου…", "Ειδοποίηση όταν ολοκληρωθεί η δέσμη",
    "Ποιότητα", "Αλλαγή μεγέθους", "Αρχικό μέγεθος", "Μεταδεδομένα", "Αφαίρεση τοποθεσίας και δεδομένων κάμερας", "Για προχωρημένους",
    "Σελίδες", "Προεπισκόπηση", "Προορισμός",
    "Αδυναμία εγγραφής εδώ — επιλέξτε φάκελο", "Αυτός ο τύπος αρχείου δεν μετατρέπεται ακόμη", "Η μετατροπή απέτυχε",
    "Κανένα αρχείο", "εικόνα", "έγγραφο", "έγγραφο PDF", "δεδομένα", "ήχος", "βίντεο", "αρχείο", "εξοικονόμηση", "Ολοκληρώθηκε",
)

TUR = nordic(
    "Dönüştürmek için dosyaları bırakın", ("veya Mac’inize göz atın", "Göz at"),
    "Dönüştür", "Sıkıştır", "Birleştir", "Böl", "Vazgeç", "Finder’da göster", "Temizle", "Ayarlar", "Kaldır",
    "Hazır", "Dönüştürülüyor", "Bitti", "Başarısız", "Desteklenmiyor",
    "Görüntü", "Belge", "Veri", "Ses", "Video", "Arşiv",
    "Özgün", "Kaynak boyutunu koru", "Uzun kenar 1920 px", "E-posta", "Yaklaşık 1 MB",
    "Paylaşım JPEG", "Göndermesi kolay JPEG", "Kayıpsız", "Ek kalite kaybı yok", "En küçük", "En küçük pratik dosya",
    "Ayarlar", "Dil", "Sistemle aynı", "Görünüm", "Sistem", "Açık", "Koyu",
    "Dönüştürülen dosyaları kaydet", "Özgünle aynı klasör", "İndirilenler", "Klasör seç…", "Parti bitince bildir",
    "Kalite", "Yeniden boyutlandır", "Özgün boyut", "Üstveri", "Konum ve kamera verilerini kaldır", "Gelişmiş",
    "Sayfalar", "Önizleme", "Hedef",
    "Buraya yazılamadı — bir klasör seçin", "Bu dosya türü henüz dönüştürülemiyor", "Dönüştürme başarısız",
    "Dosya yok", "görüntü", "belge", "PDF belgesi", "veri", "ses", "video", "arşiv", "kazanıldı", "Bitti",
)

RU = nordic(
    "Перетащите файлы для конвертации", ("или выберите на Mac", "Обзор"),
    "Конвертировать", "Сжать", "Объединить", "Разделить", "Отменить", "Показать в Finder", "Очистить", "Настройки", "Удалить",
    "Готово", "Конвертация", "Готово", "Ошибка", "Не поддерживается",
    "Изображение", "Документ", "Данные", "Аудио", "Видео", "Архив",
    "Исходный", "Сохранить исходный размер", "Длинная сторона 1920 px", "Почта", "Около 1 МБ",
    "JPEG для отправки", "Удобный JPEG для обмена", "Без потерь", "Без дополнительной потери качества", "Наименьший", "Наименьший практичный файл",
    "Настройки", "Язык", "Как в системе", "Оформление", "Система", "Светлая", "Тёмная",
    "Сохранять конвертированные файлы", "Та же папка, что и оригинал", "Загрузки", "Выбрать папку…", "Уведомить по окончании пакета",
    "Качество", "Размер", "Исходный размер", "Метаданные", "Удалить геолокацию и данные камеры", "Дополнительно",
    "Страницы", "Просмотр", "Назначение",
    "Не удалось записать сюда — выберите папку", "Этот тип файла пока нельзя конвертировать", "Сбой конвертации",
    "Нет файлов", "изображение", "документ", "документ PDF", "данные", "аудио", "видео", "архив", "сэкономлено", "Готово",
)

UK = nordic(
    "Перетягніть файли для конвертації", ("або виберіть на Mac", "Огляд"),
    "Конвертувати", "Стиснути", "Об’єднати", "Розділити", "Скасувати", "Показати у Finder", "Очистити", "Параметри", "Вилучити",
    "Готово", "Конвертація", "Готово", "Помилка", "Не підтримується",
    "Зображення", "Документ", "Дані", "Аудіо", "Відео", "Архів",
    "Оригінал", "Зберегти початковий розмір", "Довший бік 1920 px", "Пошта", "Близько 1 МБ",
    "JPEG для надсилання", "Зручний JPEG для поширення", "Без втрат", "Без додаткової втрати якості", "Найменший", "Найменший практичний файл",
    "Параметри", "Мова", "Як у системі", "Вигляд", "Система", "Світла", "Темна",
    "Зберігати конвертовані файли", "Та сама папка, що й оригінал", "Завантаження", "Вибрати папку…", "Сповістити після пакета",
    "Якість", "Розмір", "Початковий розмір", "Метадані", "Вилучити розташування й дані камери", "Додатково",
    "Сторінки", "Перегляд", "Призначення",
    "Не вдалося записати сюди — виберіть папку", "Цей тип файлу ще не можна конвертувати", "Помилка конвертації",
    "Немає файлів", "зображення", "документ", "документ PDF", "дані", "аудіо", "відео", "архів", "заощаджено", "Готово",
)

AR = nordic(
    "أفلت الملفات للتحويل", ("أو تصفّح الـ Mac", "تصفّح"),
    "تحويل", "ضغط", "دمج", "تقسيم", "إلغاء", "إظهار في Finder", "مسح", "الإعدادات", "إزالة",
    "جاهز", "جارٍ التحويل", "تم", "فشل", "غير مدعوم",
    "صورة", "مستند", "بيانات", "صوت", "فيديو", "أرشيف",
    "الأصل", "الإبقاء على حجم المصدر", "الضلع الطويل 1920 بكسل", "البريد", "حوالي 1 ميغابايت",
    "JPEG للمشاركة", "JPEG مناسب للإرسال", "بدون فقدان", "بدون فقدان إضافي للجودة", "الأصغر", "أصغر ملف عملي",
    "الإعدادات", "اللغة", "مطابقة النظام", "المظهر", "النظام", "فاتح", "داكن",
    "حفظ الملفات المحوّلة", "المجلد نفسه للملف الأصلي", "التنزيلات", "اختيار مجلد…", "إشعار عند انتهاء الدفعة",
    "الجودة", "تغيير الحجم", "الحجم الأصلي", "البيانات الوصفية", "إزالة الموقع وبيانات الكاميرا", "متقدم",
    "الصفحات", "معاينة", "الوجهة",
    "تعذّر الكتابة هنا — اختر مجلدًا", "لا يمكن تحويل هذا النوع بعد", "فشل التحويل",
    "لا ملفات", "صورة", "مستند", "مستند PDF", "بيانات", "صوت", "فيديو", "أرشيف", "تم التوفير", "تم",
)

HE = nordic(
    "שחררו קבצים להמרה", ("או עיינו ב-Mac", "עיון"),
    "המרה", "דחיסה", "מיזוג", "פיצול", "ביטול", "הצגה ב-Finder", "ניקוי", "הגדרות", "הסרה",
    "מוכן", "ממיר", "בוצע", "נכשל", "לא נתמך",
    "תמונה", "מסמך", "נתונים", "שמע", "וידאו", "ארכיון",
    "מקור", "לשמור על גודל המקור", "הצלע הארוכה 1920 פיקסלים", "דוא״ל", "בערך 1 MB",
    "JPEG לשיתוף", "JPEG נוח לשליחה", "ללא אובדן", "בלי אובדן איכות נוסף", "הקטן ביותר", "הקובץ המעשי הקטן ביותר",
    "הגדרות", "שפה", "כמו במערכת", "מראה", "מערכת", "בהיר", "כהה",
    "שמירת קבצים שהומרו", "אותה תיקייה כמו המקור", "הורדות", "בחירת תיקייה…", "הודעה בסיום אצווה",
    "איכות", "שינוי גודל", "גודל מקורי", "מטא־נתונים", "הסרת מיקום ונתוני מצלמה", "מתקדם",
    "עמודים", "תצוגה מקדימה", "יעד",
    "לא ניתן לכתוב כאן — בחרו תיקייה", "לא ניתן להמיר עדיין סוג קובץ זה", "ההמרה נכשלה",
    "אין קבצים", "תמונה", "מסמך", "מסמך PDF", "נתונים", "שמע", "וידאו", "ארכיון", "נחסך", "בוצע",
)

HI = nordic(
    "कनवर्ट करने के लिए फ़ाइलें छोड़ें", ("या अपने Mac में देखें", "ब्राउज़ करें"),
    "कनवर्ट", "संपीड़ित करें", "जोड़ें", "बाँटें", "रद्द करें", "Finder में दिखाएँ", "साफ़ करें", "सेटिंग्ज़", "हटाएँ",
    "तैयार", "कनवर्ट हो रहा है", "हो गया", "विफल", "असमर्थित",
    "छवि", "दस्तावेज़", "डेटा", "ऑडियो", "वीडियो", "संग्रह",
    "मूल", "स्रोत आकार बनाए रखें", "लंबा किनारा 1920 px", "ईमेल", "लगभग 1 MB",
    "साझा करने योग्य JPEG", "भेजने के लिए आसान JPEG", "हानि रहित", "कोई अतिरिक्त गुणवत्ता हानि नहीं", "सबसे छोटा", "सबसे छोटी व्यावहारिक फ़ाइल",
    "सेटिंग्ज़", "भाषा", "सिस्टम के अनुसार", "दिखावट", "सिस्टम", "हल्का", "गहरा",
    "कनवर्ट की गई फ़ाइलें सहेजें", "मूल वाली ही फ़ोल्डर", "डाउनलोड", "फ़ोल्डर चुनें…", "बैच पूरा होने पर सूचित करें",
    "गुणवत्ता", "आकार बदलें", "मूल आकार", "मेटाडेटा", "स्थान और कैमरा डेटा हटाएँ", "उन्नत",
    "पृष्ठ", "पूर्वावलोकन", "गंतव्य",
    "यहाँ लिखा नहीं जा सका — फ़ोल्डर चुनें", "इस फ़ाइल प्रकार को अभी कनवर्ट नहीं किया जा सकता", "कनवर्ज़न विफल",
    "कोई फ़ाइल नहीं", "छवि", "दस्तावेज़", "PDF दस्तावेज़", "डेटा", "ऑडियो", "वीडियो", "संग्रह", "बचाया", "हो गया",
)

TH = nordic(
    "วางไฟล์เพื่อแปลง", ("หรือเรียกดูบน Mac", "เรียกดู"),
    "แปลง", "บีบอัด", "รวม", "แยก", "ยกเลิก", "แสดงใน Finder", "ล้าง", "การตั้งค่า", "ลบ",
    "พร้อม", "กำลังแปลง", "เสร็จแล้ว", "ล้มเหลว", "ไม่รองรับ",
    "รูปภาพ", "เอกสาร", "ข้อมูล", "เสียง", "วิดีโอ", "คลังเก็บ",
    "ต้นฉบับ", "คงขนาดต้นทางไว้", "ด้านยาว 1920 พิกเซล", "อีเมล", "ประมาณ 1 MB",
    "JPEG สำหรับแชร์", "JPEG ส่งง่าย", "ไม่สูญเสีย", "ไม่สูญเสียคุณภาพเพิ่ม", "เล็กสุด", "ไฟล์ที่เล็กที่สุดที่ใช้ได้",
    "การตั้งค่า", "ภาษา", "ตามระบบ", "ลักษณะ", "ระบบ", "สว่าง", "มืด",
    "บันทึกไฟล์ที่แปลงแล้ว", "โฟลเดอร์เดียวกับต้นฉบับ", "ดาวน์โหลด", "เลือกโฟลเดอร์…", "แจ้งเมื่อชุดงานเสร็จ",
    "คุณภาพ", "ปรับขนาด", "ขนาดต้นฉบับ", "เมทาดาทา", "ลบตำแหน่งและข้อมูลกล้อง", "ขั้นสูง",
    "หน้า", "ตัวอย่าง", "ปลายทาง",
    "เขียนที่นี่ไม่ได้ — เลือกโฟลเดอร์", "ยังแปลงชนิดไฟล์นี้ไม่ได้", "การแปลงล้มเหลว",
    "ไม่มีไฟล์", "รูปภาพ", "เอกสาร", "เอกสาร PDF", "ข้อมูล", "เสียง", "วิดีโอ", "คลังเก็บ", "ประหยัดได้", "เสร็จแล้ว",
)

VI = nordic(
    "Thả tập tin để chuyển đổi", ("hoặc duyệt trên Mac", "Duyệt"),
    "Chuyển đổi", "Nén", "Gộp", "Tách", "Hủy", "Hiện trong Finder", "Xóa hết", "Cài đặt", "Gỡ",
    "Sẵn sàng", "Đang chuyển", "Xong", "Thất bại", "Không hỗ trợ",
    "Hình ảnh", "Tài liệu", "Dữ liệu", "Âm thanh", "Video", "Lưu trữ",
    "Gốc", "Giữ kích thước nguồn", "Cạnh dài 1920 px", "Email", "Khoảng 1 MB",
    "JPEG để chia sẻ", "JPEG tiện gửi", "Không mất mát", "Không mất thêm chất lượng", "Nhỏ nhất", "Tập tin nhỏ nhất thực tế",
    "Cài đặt", "Ngôn ngữ", "Theo hệ thống", "Giao diện", "Hệ thống", "Sáng", "Tối",
    "Lưu tập tin đã chuyển", "Cùng thư mục với bản gốc", "Tải xuống", "Chọn thư mục…", "Báo khi xong một lô",
    "Chất lượng", "Đổi kích thước", "Kích thước gốc", "Siêu dữ liệu", "Gỡ vị trí và dữ liệu máy ảnh", "Nâng cao",
    "Trang", "Xem trước", "Đích",
    "Không ghi được ở đây — hãy chọn thư mục", "Chưa chuyển được loại tập tin này", "Chuyển đổi thất bại",
    "Không có tập tin", "hình ảnh", "tài liệu", "tài liệu PDF", "dữ liệu", "âm thanh", "video", "lưu trữ", "tiết kiệm", "Xong",
)

ID = nordic(
    "Letakkan file untuk dikonversi", ("atau telusuri Mac Anda", "Telusuri"),
    "Konversi", "Kompres", "Gabung", "Pisah", "Batal", "Tampilkan di Finder", "Kosongkan", "Pengaturan", "Hapus",
    "Siap", "Mengonversi", "Selesai", "Gagal", "Tidak didukung",
    "Gambar", "Dokumen", "Data", "Audio", "Video", "Arsip",
    "Asli", "Pertahankan ukuran sumber", "Sisi panjang 1920 px", "Email", "Sekitar 1 MB",
    "JPEG untuk berbagi", "JPEG praktis untuk dikirim", "Tanpa kerugian", "Tanpa kehilangan mutu tambahan", "Terkecil", "File praktis terkecil",
    "Pengaturan", "Bahasa", "Ikuti sistem", "Tampilan", "Sistem", "Terang", "Gelap",
    "Simpan file yang dikonversi", "Folder yang sama dengan aslinya", "Unduhan", "Pilih folder…", "Beri tahu saat batch selesai",
    "Mutu", "Ubah ukuran", "Ukuran asli", "Metadata", "Hapus lokasi dan data kamera", "Lanjutan",
    "Halaman", "Pratinjau", "Tujuan",
    "Tidak dapat menulis di sini — pilih folder", "Jenis file ini belum dapat dikonversi", "Konversi gagal",
    "Tidak ada file", "gambar", "dokumen", "dokumen PDF", "data", "audio", "video", "arsip", "tersimpan", "Selesai",
)

JA = nordic(
    "変換するファイルをドロップ", ("またはMacをブラウズ", "ブラウズ"),
    "変換", "圧縮", "結合", "分割", "キャンセル", "Finderに表示", "クリア", "設定", "削除",
    "準備完了", "変換中", "完了", "失敗", "未対応",
    "画像", "書類", "データ", "オーディオ", "ビデオ", "アーカイブ",
    "オリジナル", "元のサイズを維持", "長辺 1920px", "メール", "約1 MB",
    "共有用JPEG", "送りやすいJPEG", "ロスレス", "追加の画質低下なし", "最小", "実用上いちばん小さいファイル",
    "設定", "言語", "システムに合わせる", "外観", "システム", "ライト", "ダーク",
    "変換後の保存先", "元のファイルと同じフォルダ", "ダウンロード", "フォルダを選択…", "バッチ完了時に通知",
    "品質", "リサイズ", "元のサイズ", "メタデータ", "位置情報とカメラデータを削除", "詳細",
    "ページ", "プレビュー", "保存先",
    "ここに書き込めません — フォルダを選んでください", "このファイル形式はまだ変換できません", "変換に失敗しました",
    "ファイルなし", "画像", "書類", "PDF書類", "データ", "オーディオ", "ビデオ", "アーカイブ", "削減", "完了",
)

KO = nordic(
    "변환할 파일을 놓으세요", ("또는 Mac에서 찾아보기", "찾아보기"),
    "변환", "압축", "합치기", "나누기", "취소", "Finder에서 보기", "비우기", "설정", "제거",
    "준비됨", "변환 중", "완료", "실패", "지원 안 함",
    "이미지", "문서", "데이터", "오디오", "비디오", "아카이브",
    "원본", "원본 크기 유지", "긴 변 1920px", "이메일", "약 1 MB",
    "공유용 JPEG", "보내기 좋은 JPEG", "무손실", "추가 화질 손실 없음", "가장 작게", "실용적인 최소 파일",
    "설정", "언어", "시스템과 동일", "모양", "시스템", "라이트", "다크",
    "변환된 파일 저장", "원본과 같은 폴더", "다운로드", "폴더 선택…", "일괄 작업이 끝나면 알림",
    "품질", "크기 조절", "원본 크기", "메타데이터", "위치 및 카메라 데이터 제거", "고급",
    "페이지", "미리보기", "대상",
    "여기에 쓸 수 없습니다 — 폴더를 선택하세요", "이 파일 형식은 아직 변환할 수 없습니다", "변환 실패",
    "파일 없음", "이미지", "문서", "PDF 문서", "데이터", "오디오", "비디오", "아카이브", "절약됨", "완료",
)

ZH_HANS = nordic(
    "拖放文件以转换", ("或浏览 Mac", "浏览"),
    "转换", "压缩", "合并", "拆分", "取消", "在 Finder 中显示", "清除", "设置", "移除",
    "就绪", "正在转换", "完成", "失败", "不支持",
    "图像", "文稿", "数据", "音频", "视频", "归档",
    "原始", "保持原始尺寸", "长边 1920 像素", "邮件", "约 1 MB",
    "分享用 JPEG", "便于发送的 JPEG", "无损", "无额外画质损失", "最小", "尽量小的实用文件",
    "设置", "语言", "跟随系统", "外观", "系统", "浅色", "深色",
    "保存转换后的文件", "与原文件相同的文件夹", "下载", "选择文件夹…", "批次完成时通知",
    "质量", "调整大小", "原始大小", "元数据", "去除位置和相机信息", "高级",
    "页", "预览", "目标",
    "无法写入此处 — 请选择文件夹", "尚不支持转换此文件类型", "转换失败",
    "没有文件", "图像", "文稿", "PDF 文稿", "数据", "音频", "视频", "归档", "已节省", "完成",
)

ZH_HANT = nordic(
    "拖放檔案以轉換", ("或瀏覽 Mac", "瀏覽"),
    "轉換", "壓縮", "合併", "分割", "取消", "在 Finder 顯示", "清除", "設定", "移除",
    "就緒", "正在轉換", "完成", "失敗", "不支援",
    "影像", "文件", "資料", "音訊", "影片", "封存",
    "原始", "維持原始尺寸", "長邊 1920 像素", "郵件", "約 1 MB",
    "分享用 JPEG", "方便傳送的 JPEG", "無損", "無額外畫質損失", "最小", "盡量小的實用檔案",
    "設定", "語言", "跟隨系統", "外觀", "系統", "淺色", "深色",
    "儲存轉換後的檔案", "與原始檔相同的檔案夾", "下載", "選擇檔案夾…", "批次完成時通知",
    "品質", "調整大小", "原始大小", "中繼資料", "移除位置與相機資料", "進階",
    "頁面", "預覽", "目的地",
    "無法寫入此處 — 請選擇檔案夾", "尚無法轉換此檔案類型", "轉換失敗",
    "沒有檔案", "影像", "文件", "PDF 文件", "資料", "音訊", "影片", "封存", "已節省", "完成",
)

TR.update(MORE)
TR["pt-BR"] = PT_BR
TR["pt-PT"] = PT_PT
TR["nl"] = NL
TR["da"] = DA
TR["sv"] = SV
TR["nb"] = NB
TR["fi"] = FI
TR["pl"] = PL
TR["cs"] = CS
TR["hu"] = HU
TR["ro"] = RO
TR["el"] = EL
TR["tr"] = TUR
TR["ru"] = RU
TR["uk"] = UK
TR["ar"] = AR
TR["he"] = HE
TR["hi"] = HI
TR["th"] = TH
TR["vi"] = VI
TR["id"] = ID
TR["ja"] = JA
TR["ko"] = KO
TR["zh-Hans"] = ZH_HANS
TR["zh-Hant"] = ZH_HANT

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from units_l10n import UNITS_TR, EXTRA_UI
for loc, keys in UNITS_TR.items():
    TR.setdefault(loc, {}).update(keys)
for loc, keys in EXTRA_UI.items():
    TR.setdefault(loc, {}).update(keys)

PLURALS: dict[str, dict[str, dict[str, str]]] = {
    "en": {"queue.count": {"one": "%lld file", "other": "%lld files"}},
    "es": {"queue.count": {"one": "%lld archivo", "other": "%lld archivos"}},
    "fr": {"queue.count": {"one": "%lld fichier", "other": "%lld fichiers"}},
    "de": {"queue.count": {"one": "%lld Datei", "other": "%lld Dateien"}},
    "it": {"queue.count": {"one": "%lld file", "other": "%lld file"}},
    "pt-BR": {"queue.count": {"one": "%lld arquivo", "other": "%lld arquivos"}},
    "pt-PT": {"queue.count": {"one": "%lld ficheiro", "other": "%lld ficheiros"}},
    "nl": {"queue.count": {"one": "%lld bestand", "other": "%lld bestanden"}},
    "da": {"queue.count": {"one": "%lld fil", "other": "%lld filer"}},
    "sv": {"queue.count": {"one": "%lld fil", "other": "%lld filer"}},
    "nb": {"queue.count": {"one": "%lld fil", "other": "%lld filer"}},
    "fi": {"queue.count": {"one": "%lld tiedosto", "other": "%lld tiedostoa"}},
    "pl": {"queue.count": {"one": "%lld plik", "few": "%lld pliki", "many": "%lld plików", "other": "%lld pliku"}},
    "cs": {"queue.count": {"one": "%lld soubor", "few": "%lld soubory", "many": "%lld souborů", "other": "%lld souboru"}},
    "hu": {"queue.count": {"one": "%lld fájl", "other": "%lld fájl"}},
    "ro": {"queue.count": {"one": "%lld fișier", "few": "%lld fișiere", "other": "%lld de fișiere"}},
    "el": {"queue.count": {"one": "%lld αρχείο", "other": "%lld αρχεία"}},
    "tr": {"queue.count": {"one": "%lld dosya", "other": "%lld dosya"}},
    "ru": {"queue.count": {"one": "%lld файл", "few": "%lld файла", "many": "%lld файлов", "other": "%lld файла"}},
    "uk": {"queue.count": {"one": "%lld файл", "few": "%lld файли", "many": "%lld файлів", "other": "%lld файла"}},
    "ar": {"queue.count": {"zero": "%lld ملف", "one": "ملف واحد", "two": "ملفان", "few": "%lld ملفات", "many": "%lld ملفًا", "other": "%lld ملف"}},
    "he": {"queue.count": {"one": "קובץ אחד", "two": "שני קבצים", "other": "%lld קבצים"}},
    "hi": {"queue.count": {"one": "%lld फ़ाइल", "other": "%lld फ़ाइलें"}},
    "th": {"queue.count": {"other": "%lld ไฟล์"}},
    "vi": {"queue.count": {"other": "%lld tập tin"}},
    "id": {"queue.count": {"other": "%lld file"}},
    "ja": {"queue.count": {"other": "%lld件のファイル"}},
    "ko": {"queue.count": {"other": "파일 %lld개"}},
    "zh-Hans": {"queue.count": {"other": "%lld 个文件"}},
    "zh-Hant": {"queue.count": {"other": "%lld 個檔案"}},
}

INFO_TR = {
    "es": "Convertir con Kiln",
    "fr": "Convertir avec Kiln",
    "de": "Mit Kiln konvertieren",
    "it": "Converti con Kiln",
    "pt-BR": "Converter com Kiln",
    "pt-PT": "Converter com o Kiln",
    "nl": "Converteren met Kiln",
    "da": "Konvertér med Kiln",
    "sv": "Konvertera med Kiln",
    "nb": "Konverter med Kiln",
    "fi": "Muunna Kilnillä",
    "pl": "Konwertuj w Kiln",
    "cs": "Převést pomocí Kiln",
    "hu": "Átalakítás a Kilnnel",
    "ro": "Conversie cu Kiln",
    "el": "Μετατροπή με το Kiln",
    "tr": "Kiln ile dönüştür",
    "ru": "Конвертировать в Kiln",
    "uk": "Конвертувати в Kiln",
    "ar": "تحويل باستخدام Kiln",
    "he": "המרה באמצעות Kiln",
    "hi": "Kiln से कनवर्ट करें",
    "th": "แปลงด้วย Kiln",
    "vi": "Chuyển đổi bằng Kiln",
    "id": "Konversi dengan Kiln",
    "ja": "Kilnで変換",
    "ko": "Kiln으로 변환",
    "zh-Hans": "用 Kiln 转换",
    "zh-Hant": "使用 Kiln 轉換",
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def build_catalog() -> dict:
    strings: dict = {}
    for key, en_val in EN.items():
        loc = {"en": unit(en_val)}
        for locale in LOCALES:
            if locale == "en":
                continue
            val = TR.get(locale, {}).get(key, en_val)
            if not val:
                val = en_val
            loc[locale] = unit(val)
        strings[key] = {"localizations": loc}

    for locale in LOCALES:
        forms = PLURALS.get(locale, PLURALS["en"])["queue.count"]
        entry = strings.setdefault("queue.count", {"localizations": {}})
        variations = {k: unit(v) for k, v in forms.items()}
        if "other" not in variations:
            variations["other"] = unit(next(iter(forms.values())))
        entry["localizations"][locale] = {"variations": {"plural": variations}}

    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def build_info() -> dict:
    strings = {}
    for key, en_val in INFO_EN.items():
        loc = {"en": unit(en_val)}
        for locale in LOCALES:
            if locale == "en":
                continue
            if key in ("CFBundleDisplayName", "CFBundleName"):
                val = "Kiln"
            else:
                val = INFO_TR.get(locale, en_val)
            loc[locale] = unit(val)
        strings[key] = {"localizations": loc}
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def main() -> None:
    RES.mkdir(parents=True, exist_ok=True)
    loc = build_catalog()
    # completeness check
    for key, entry in loc["strings"].items():
        have = set(entry["localizations"])
        missing = set(LOCALES) - have
        if missing:
            raise SystemExit(f"missing locales for {key}: {missing}")
        for locale, payload in entry["localizations"].items():
            if "stringUnit" in payload:
                if not payload["stringUnit"]["value"]:
                    raise SystemExit(f"empty {key}/{locale}")
            elif "variations" in payload:
                plural = payload["variations"]["plural"]
                if "other" not in plural:
                    raise SystemExit(f"no other plural for {key}/{locale}")
                for form, u in plural.items():
                    if not u["stringUnit"]["value"]:
                        raise SystemExit(f"empty plural {key}/{locale}/{form}")
            else:
                raise SystemExit(f"bad payload {key}/{locale}")
    text = json.dumps(loc, ensure_ascii=False, indent=2) + "\n"
    (RES / "Localizable.xcstrings").write_text(text)
    (RES / "InfoPlist.xcstrings").write_text(json.dumps(build_info(), ensure_ascii=False, indent=2) + "\n")
    tests = ROOT / "KilnTests"
    tests.mkdir(parents=True, exist_ok=True)
    # Plain JSON so the sandboxed test host can read it from the test bundle.
    (tests / "Localizable.catalog.json").write_text(text)
    print(f"keys={len(loc['strings'])} locales={len(LOCALES)}")


if __name__ == "__main__":
    main()

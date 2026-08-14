#!/usr/bin/env python3
"""Generate Kiln.xcodeproj without XcodeGen."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Kiln.xcodeproj"


def pid(name: str) -> str:
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def collect(rel_dir: str, exts: set[str]) -> list[Path]:
    base = ROOT / rel_dir
    files: list[Path] = []
    if not base.exists():
        return files
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix in exts:
            files.append(path.relative_to(ROOT))
    return files


def quote(value: str) -> str:
    if value and all(c.isalnum() or c in "._-" for c in value):
        return value
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


objects: dict[str, str] = {}


def add(key: str, body: str) -> str:
    objects[key] = body
    return key


file_refs: dict[str, str] = {}


def file_ref(path: Path, ftype: str | None = None, extra: str = "") -> str:
    key = pid(f"ref:{path}")
    if key in objects:
        return key
    last = path.name
    if ftype is None:
        ftype = {
            ".swift": "sourcecode.swift",
            ".plist": "text.plist.xml",
            ".entitlements": "text.plist.entitlements",
            ".xcassets": "folder.assetcatalog",
            ".xcstrings": "text.json.xcstrings",
            ".png": "image.png",
            ".jpg": "image.jpeg",
            ".jpeg": "image.jpeg",
            ".pdf": "image.pdf",
            ".json": "text.json",
        }.get(path.suffix, "text")
    add(
        key,
        f"isa = PBXFileReference; lastKnownFileType = {ftype}; name = {quote(last)}; path = {quote(str(path))}; sourceTree = SOURCE_ROOT; {extra}",
    )
    file_refs[str(path)] = key
    return key


def build_file(path: Path, prefix: str) -> str:
    ref = file_ref(path)
    key = pid(f"build:{prefix}:{path}")
    add(key, f"isa = PBXBuildFile; fileRef = {ref};")
    return key


def group_for(files: list[Path], name: str) -> str:
    children = [file_ref(p) for p in files]
    key = pid(f"group-list:{name}")
    add(key, f'isa = PBXGroup; children = ( {", ".join(children)} ); name = {quote(name)}; sourceTree = "<group>";')
    return key


app_sources = collect("Kiln", {".swift"})
test_sources = collect("KilnTests", {".swift"})
fixture_files = collect("Fixtures", {".png", ".jpg", ".jpeg", ".pdf", ".json"})
test_json = [
    Path("KilnTests/Localizable.catalog.json"),
    Path("KilnTests/frankfurter-fixture.json"),
]
string_files = [
    Path("Kiln/Resources/Localizable.xcstrings"),
    Path("Kiln/Resources/InfoPlist.xcstrings"),
]
assets = Path("Kiln/Resources/Assets.xcassets")

app_product = add(
    pid("product:Kiln.app"),
    "isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Kiln.app; sourceTree = BUILT_PRODUCTS_DIR;",
)
test_product = add(
    pid("product:KilnTests.xctest"),
    "isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = KilnTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;",
)

file_ref(Path("Kiln/Resources/Info.plist"))
file_ref(Path("Kiln/Resources/Kiln.entitlements"))
file_ref(assets)

app_source_builds = [build_file(p, "app") for p in app_sources]
test_source_builds = [build_file(p, "test") for p in test_sources]
asset_build = build_file(assets, "app-res")
string_builds = [build_file(p, "app-res") for p in string_files]
fixture_builds = [build_file(p, "test-res") for p in fixture_files]
test_json_builds = [build_file(p, "test-res") for p in test_json]

src_group = group_for(app_sources, "Kiln")
test_group = group_for(test_sources, "KilnTests")
res_group = group_for(
    [
        Path("Kiln/Resources/Info.plist"),
        Path("Kiln/Resources/Kiln.entitlements"),
        assets,
        *string_files,
        *fixture_files,
        *test_json,
    ],
    "Resources",
)
products_group = add(
    pid("group:products"),
    f"isa = PBXGroup; children = ( {app_product}, {test_product} ); name = Products; sourceTree = \"<group>\";",
)
main_group = add(
    pid("group:main"),
    f'isa = PBXGroup; children = ( {src_group}, {test_group}, {res_group}, {products_group} ); sourceTree = "<group>";',
)

app_src_phase = add(
    pid("phase:app-src"),
    "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(app_source_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
test_src_phase = add(
    pid("phase:test-src"),
    "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(test_source_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
app_res_phase = add(
    pid("phase:app-res"),
    "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join([asset_build, *string_builds])
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
test_res_phase = add(
    pid("phase:test-res"),
    "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( "
    + ", ".join(fixture_builds + test_json_builds)
    + " ); runOnlyForDeploymentPostprocessing = 0;",
)
app_fw_phase = add(
    pid("phase:app-fw"),
    "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)
test_fw_phase = add(
    pid("phase:test-fw"),
    "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0;",
)

shared_debug = """
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
COPY_PHASE_STRIP = NO;
DEBUG_INFORMATION_FORMAT = dwarf;
ENABLE_HARDENED_RUNTIME = YES;
ENABLE_TESTABILITY = YES;
GCC_DYNAMIC_NO_PIC = NO;
GCC_OPTIMIZATION_LEVEL = 0;
MACOSX_DEPLOYMENT_TARGET = 15.0;
ONLY_ACTIVE_ARCH = YES;
SDKROOT = macosx;
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
SWIFT_OPTIMIZATION_LEVEL = "-Onone";
SWIFT_VERSION = 6.0;
SWIFT_STRICT_CONCURRENCY = complete;
CODE_SIGN_STYLE = Automatic;
DEVELOPMENT_TEAM = 7JA9J6994N;
ALWAYS_SEARCH_USER_PATHS = NO;
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
"""

shared_release = """
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
COPY_PHASE_STRIP = NO;
DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
ENABLE_HARDENED_RUNTIME = YES;
GCC_OPTIMIZATION_LEVEL = s;
MACOSX_DEPLOYMENT_TARGET = 15.0;
SDKROOT = macosx;
SWIFT_COMPILATION_MODE = wholemodule;
SWIFT_OPTIMIZATION_LEVEL = "-O";
SWIFT_VERSION = 6.0;
SWIFT_STRICT_CONCURRENCY = complete;
CODE_SIGN_STYLE = Automatic;
DEVELOPMENT_TEAM = 7JA9J6994N;
ALWAYS_SEARCH_USER_PATHS = NO;
"""

proj_debug = add(pid("cfg:proj-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {shared_debug} }}; name = Debug;")
proj_release = add(pid("cfg:proj-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {shared_release} }}; name = Release;")
proj_cfgs = add(
    pid("list:proj"),
    f"isa = XCConfigurationList; buildConfigurations = ( {proj_debug}, {proj_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)

app_settings = """
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
CODE_SIGN_ENTITLEMENTS = Kiln/Resources/Kiln.entitlements;
COMBINE_HIDPI_IMAGES = YES;
CURRENT_PROJECT_VERSION = 1;
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = Kiln/Resources/Info.plist;
LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";
MARKETING_VERSION = 1.0;
PRODUCT_BUNDLE_IDENTIFIER = app.kiln.mac;
PRODUCT_NAME = Kiln;
ENABLE_HARDENED_RUNTIME = YES;
DEVELOPMENT_TEAM = 7JA9J6994N;
CODE_SIGN_STYLE = Automatic;
ENABLE_TESTABILITY = YES;
ENABLE_PREVIEWS = YES;
"""

test_settings = """
BUNDLE_LOADER = "$(TEST_HOST)";
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Kiln.app/Contents/MacOS/Kiln";
GENERATE_INFOPLIST_FILE = YES;
LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks";
PRODUCT_BUNDLE_IDENTIFIER = app.kiln.mac.tests;
PRODUCT_NAME = KilnTests;
DEVELOPMENT_TEAM = 7JA9J6994N;
CODE_SIGN_STYLE = Automatic;
MACOSX_DEPLOYMENT_TARGET = 15.0;
"""

app_debug = add(pid("cfg:app-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {app_settings} }}; name = Debug;")
app_release = add(pid("cfg:app-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {app_settings} }}; name = Release;")
app_cfgs = add(
    pid("list:app"),
    f"isa = XCConfigurationList; buildConfigurations = ( {app_debug}, {app_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)
test_debug = add(pid("cfg:test-debug"), f"isa = XCBuildConfiguration; buildSettings = {{ {test_settings} }}; name = Debug;")
test_release = add(pid("cfg:test-release"), f"isa = XCBuildConfiguration; buildSettings = {{ {test_settings} }}; name = Release;")
test_cfgs = add(
    pid("list:test"),
    f"isa = XCConfigurationList; buildConfigurations = ( {test_debug}, {test_release} ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;",
)

app_target = add(
    pid("target:app"),
    f"""isa = PBXNativeTarget;
buildConfigurationList = {app_cfgs};
buildPhases = ( {app_src_phase}, {app_fw_phase}, {app_res_phase} );
buildRules = ( );
dependencies = ( );
name = Kiln;
productName = Kiln;
productReference = {app_product};
productType = "com.apple.product-type.application";
""",
)

container = add(
    pid("proxy:app"),
    f"isa = PBXContainerItemProxy; containerPortal = {pid('project')}; proxyType = 1; remoteGlobalIDString = {app_target}; remoteInfo = Kiln;",
)
dependency = add(
    pid("dep:app"),
    f"isa = PBXTargetDependency; target = {app_target}; targetProxy = {container};",
)

test_target = add(
    pid("target:tests"),
    f"""isa = PBXNativeTarget;
buildConfigurationList = {test_cfgs};
buildPhases = ( {test_src_phase}, {test_fw_phase}, {test_res_phase} );
buildRules = ( );
dependencies = ( {dependency} );
name = KilnTests;
productName = KilnTests;
productReference = {test_product};
productType = "com.apple.product-type.bundle.unit-test";
""",
)

project = add(
    pid("project"),
    f"""isa = PBXProject;
attributes = {{ BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600; }};
buildConfigurationList = {proj_cfgs};
compatibilityVersion = "Xcode 15.0";
developmentRegion = en;
hasScannedForEncodings = 0;
knownRegions = ( en, Base, es, fr, de, it, "pt-BR", "pt-PT", nl, da, sv, nb, fi, pl, cs, hu, ro, el, tr, ru, uk, ar, he, hi, th, vi, id, ja, ko, "zh-Hans", "zh-Hant" );
mainGroup = {main_group};
productRefGroup = {products_group};
projectDirPath = "";
projectRoot = "";
targets = ( {app_target}, {test_target} );
""",
)

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Kiln.app" BlueprintName="Kiln" ReferencedContainer="container:Kiln.xcodeproj"/>
         </BuildActionEntry>
         <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test_target}" BuildableName="KilnTests.xctest" BlueprintName="KilnTests" ReferencedContainer="container:Kiln.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test_target}" BuildableName="KilnTests.xctest" BlueprintName="KilnTests" ReferencedContainer="container:Kiln.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Kiln.app" BlueprintName="Kiln" ReferencedContainer="container:Kiln.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="Kiln.app" BlueprintName="Kiln" ReferencedContainer="container:Kiln.xcodeproj"/>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
"""

sections: dict[str, list[tuple[str, str]]] = {}
for key, body in objects.items():
    isa = body.split("isa = ")[1].split(";")[0].strip()
    sections.setdefault(isa, []).append((key, body))

lines = [
    "// !$*UTF8*$!",
    "{",
    "\tarchiveVersion = 1;",
    "\tclasses = {",
    "\t};",
    "\tobjectVersion = 56;",
    "\tobjects = {",
    "",
]
for isa, items in sections.items():
    lines.append(f"/* Begin {isa} section */")
    for key, body in items:
        compact = " ".join(body.split())
        lines.append(f"\t\t{key} = {{ {compact} }};")
    lines.append(f"/* End {isa} section */")
    lines.append("")
lines += ["\t};", f"\trootObject = {pid('project')};", "}", ""]

PROJECT.mkdir(exist_ok=True)
(PROJECT / "project.pbxproj").write_text("\n".join(lines))
scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / "Kiln.xcscheme").write_text(scheme)
print(f"Wrote {PROJECT} app_sources={len(app_sources)} tests={len(test_sources)} fixtures={len(fixture_files)}")

# BitNotch

A macOS app that turns the MacBook notch into a panel for music and productivity tools.

## Requirements

- macOS 14 or later
- Xcode 26
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Building

The Xcode project is generated from `project.yml`. After adding or removing files, regenerate it:

```bash
xcodegen generate
open BitNotch.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project BitNotch.xcodeproj -scheme BitNotch -derivedDataPath build build
open build/Build/Products/Debug/BitNotch.app
```

## Layout

| Folder | Contents |
|---|---|
| `BitNotch/App` | App entry point, menu bar item |
| `BitNotch/Notch` | Notch panel, geometry, shape and container views |
| `BitNotch/Core` | `NotchModule` protocol and module registry |
| `BitNotch/Modules` | One folder per feature module |
| `BitNotch/Settings` | Settings window |

New features are added as a `NotchModule` and registered in `ModuleRegistry.allModules`.

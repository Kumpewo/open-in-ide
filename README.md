# OpenInIDE

A context menu entry for the Windows Explorer that opens a project in IntelliJ IDEA:

* **Folder**: opened as a project. If it is not a project yet, OpenInIDE asks whether to create one.
* **Deployed file**: opens the project it was deployed from. The AutoHotkey plugin for JetBrains IDEs, [AutoHotkey v2
  Language Support](https://plugins.jetbrains.com/plugin/36153-autohotkey-v2-language-support), can write a banner at
  the start of the files it deploys (`Banner=@standard` or `Banner=@library`); OpenInIDE reads the project folder from
  it. Banners with a text of your own are not recognized.
* **Deployed executable**: opens the project named at the end of the .exe. The plugin writes it there unless you set
  `EmbedOrigin=no`.

If the project folder does not exist, a message says so, and whether the file comes from another computer. You need not
have the plugin installed to use OpenInIDE.

## Requirements

* Windows, and [AutoHotkey v2](https://www.autohotkey.com/) installed with the official installer.
* The compiler Ahk2Exe. If it is missing, open AutoHotkey Dash from the start menu and click *Compile*: this downloads
  it.
* IntelliJ IDEA in one of the default places: `JetBrains\IntelliJ IDEA*` in the program files, or
  `%LOCALAPPDATA%\Programs\IntelliJ IDEA*` (installed for the current user or by the JetBrains Toolbox App).

There is no .exe to download; you compile it yourself.

## Installation

1. **Icon** (optional; before compiling, because it becomes part of the .exe): run `FetchIntelliJIcon.ahk`. It copies
   the icon of your IntelliJ IDEA as `OpenInIDE.ico`. You can also put any other icon there under this name. Without it,
   `default.ico` is used.
2. **Compile** `OpenInIDE.ahk` with Ahk2Exe. Leave the base file alone, the script selects it itself. Then copy
   `OpenInIDE.exe` to a folder of your choice, e.g. `C:\bin`. With the plugin, *Code > Deploy to Local Target...* does
   both; set `Destination` in `settings.ahk-v2-plugin.ini` first, and `RequiresAdmin=no` if the folder is not protected.
3. **Register**: run `WriteInstallReg.ahk`, enter the name of the menu entry and the folder of `OpenInIDE.exe`. It
   writes `register_OpenInIDE.reg`. Check this file in an editor, then double-click it. The entry is made for the
   current user only and needs no administrator rights. Windows 11 shows it under *Show more options*.

To rename the entry, repeat step 3; the new name replaces the old one.

## Removal

Double-click `unregister_OpenInIDE.reg` (written together with the other file), then delete `OpenInIDE.exe`.

## Limitations

* Only IntelliJ IDEA is supported, no other JetBrains IDE. If you want another one, change `FindIntelliJ.ahk`, the only
  place that knows where the IDE is installed.
* If several versions are installed, the newest one (by build number) is used, whichever of the default places it is
  in.
* An .exe deployed with `EmbedOrigin=yes` (the default) contains the path of your project and the name of your computer.
  Set `EmbedOrigin=no` before you pass it on.

## License

GPL-2.0-or-later, see [LICENSE](LICENSE).

This project is not affiliated with, sponsored or endorsed by [JetBrains](https://www.jetbrains.com). JetBrains and
IntelliJ IDEA are trademarks of JetBrains s.r.o. The icon of IntelliJ IDEA is not part of this repository: Copyright ©
2026 JetBrains s.r.o. IntelliJ IDEA and the IntelliJ IDEA logo are trademarks of JetBrains s.r.o.

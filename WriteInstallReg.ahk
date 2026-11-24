#Requires AutoHotkey v2.0
;@SetVersion 1.0.0

; Asks for the folder of OpenInIDE.exe and the name of the menu entry and writes two files into the
; folder of this script: one that adds the entry to the context menu of files and folders, and one
; that removes it. This script itself does not change the registry.

ShowDialog()


/**
 * Shows the dialog; defaults: the folder of `Destination` in the settings, "Open in IDE"
 */
ShowDialog() {
    dialog := Gui(, "OpenInIDE: context menu entry")
    dialog.MarginX := 16
    dialog.MarginY := 14
    dialog.SetFont("s10", "Segoe UI")
    dialog.AddText("w620", "This script writes the file`n`n"
            "        register_OpenInIDE.reg`n`n"
            "into its own folder. A double-click on that file adds an entry to the context menu of"
            " files and folders in the Windows Explorer, for the current user only (no administrator"
            " rights needed). The file unregister_OpenInIDE.reg, which removes the entry again, is"
            " written as well."
            "`n`nNothing is changed in the registry now. Please check the file in an editor before"
            " you run it, in your own interest.")
    dialog.AddText("w620", "Name of the entry in the context menu:")
    name := dialog.AddEdit("w520", "Open in IDE")
    dialog.AddText("w620", "Folder in which OpenInIDE.exe is (or will be) installed:")
    folder := dialog.AddEdit("w520", ReadDestination())
    browse := dialog.AddButton("x+10 yp-1 w90", "Browse...")
    write := dialog.AddButton("xm y+20 w420 Default",
            "Write a .reg file for the context menu entry")
    cancel := dialog.AddButton("x+10 w190", "Do nothing and exit")

    browse.OnEvent("Click", (*) => SelectFolder(dialog, folder))
    write.OnEvent("Click", (*) => WriteFiles(dialog, name.Value, folder.Value))
    cancel.OnEvent("Click", (*) => ExitApp())
    dialog.OnEvent("Close", (*) => ExitApp())
    dialog.OnEvent("Escape", (*) => ExitApp())
    dialog.Show()
}


/**
 * Lets the user select the folder
 *
 * @param dialog  owner window
 * @param folder  edit control that gets the selected folder
 */
SelectFolder(dialog, folder) {
    dialog.Opt("+OwnDialogs")
    start := DirExist(folder.Value) ? "*" folder.Value : ""
    If (selected := DirSelect(start, 3, "Folder of OpenInIDE.exe"))
        folder.Value := selected
}


/**
 * Writes both files (existing ones are replaced), tells where they are and ends the script; stays in
 * the dialog if the name or the folder is not valid or a file cannot be written
 *
 * @param dialog  owner window
 * @param name    name of the entry in the context menu
 * @param folder  folder of OpenInIDE.exe
 */
WriteFiles(dialog, name, folder) {
    dialog.Opt("+OwnDialogs")
    name := Trim(name, " `t")
    If (name = "") {
        MsgBox("Please enter the name of the entry, for example Open in IDE.",, "Icon!")
        Return
    }
    folder := RTrim(Trim(StrReplace(folder, "/", "\"), " `t`""), "\")
    If (not IsAbsoluteFolder(folder)) {
        MsgBox("Please enter the full path of a folder, for example C:\bin.",, "Icon!")
        Return
    }

    register := A_ScriptDir "\register_OpenInIDE.reg"
    unregister := A_ScriptDir "\unregister_OpenInIDE.reg"
    Try {
        WriteReg(register, RegisterText(name, folder "\OpenInIDE.exe"))
        WriteReg(unregister, UnregisterText())
    } Catch as e {
        MsgBox("The files cannot be written to`n`n`t" A_ScriptDir "`n`n(" e.Message ")",, "Icon!")
        Return
    }
    MsgBox("Written:`n`n`t" register "`n`t" unregister
            "`n`nPlease check register_OpenInIDE.reg in an editor, then double-click it.",,
            "Iconi")
    ExitApp()
}


/**
 * Is it the full path of a folder (it need not exist yet)?
 *
 * @param folder  path without \ at the end
 */
IsAbsoluteFolder(folder) {
    Return RegExMatch(folder, "^([A-Za-z]:(\\[^\\]|$)|\\\\[^\\]+\\[^\\])") > 0
            and not RegExMatch(SubStr(folder, 3), '[<>:"|?*\x00-\x1F]')
}


/**
 * Reads `Destination` from the settings of the plugin next to this script
 *
 * @returns the folder or "" if there is none (or one that cannot be resolved)
 */
ReadDestination() {
    file := A_ScriptDir "\settings.ahk-v2-plugin.ini"
    If (not FileExist(file))
        Return ""
    ; not IniRead(): it does not know UTF-8
    section := ""
    Loop Parse, FileRead(file, "UTF-8"), "`n", "`r" {
        line := Trim(A_LoopField, " `t" Chr(0xFEFF))
        If (RegExMatch(line, "^\[\s*(.*?)\s*\]", &match))
            section := match[1]
        Else If (section = "Deploy" and RegExMatch(line, "i)^Destination\s*=\s*(.*)$", &match))
            Return ResolveVariables(Trim(match[1], " `t`""))
    }
    Return ""
}


/**
 * Replaces the variables of AutoHotkey such as %A_MyDocuments%, and %% by a percent sign
 *
 * @param text  value of the settings
 *
 * @returns the text or "" if it contains an unknown variable
 */
ResolveVariables(text) {
    result := ""
    pos := 1
    While (found := RegExMatch(text, "%([^%]*)%", &match, pos)) {
        result .= SubStr(text, pos, found - pos)
        name := match[1]
        If (name = "")
            result .= "%"
        Else If (not RegExMatch(name, "i)^A_[a-z]+$"))
            Return ""
        Else {
            Try
                result .= %name%
            Catch
                Return ""
        }
        pos := found + match.Len
    }
    Return result SubStr(text, pos)
}


/**
 * Content of the file that adds the entry for folders and files (of the current user)
 *
 * The registry key is always the same, so a new name replaces the old entry and the file that
 * removes the entry always fits.
 *
 * @param name  name of the entry in the context menu
 * @param exe   full name of the executable
 */
RegisterText(name, exe) {
    value := RegEscape(exe)
    text := ""
    For type in [ "Directory", "*" ] {
        key := "HKEY_CURRENT_USER\Software\Classes\" type "\shell\OpenInIDE"
        text .= "`r`n[" key "]`r`n"
                . '@="' RegEscape(name) '"`r`n'
                . '"Icon"="' value ',0"`r`n'
                . "`r`n[" key "\command]`r`n"
                . '@="\"' value '\" \"%1\""`r`n'
    }
    Return "Windows Registry Editor Version 5.00`r`n" text
}


/**
 * Escapes backslashes and quotation marks for a string value in a .reg file
 *
 * @param text  the value
 */
RegEscape(text) {
    Return StrReplace(StrReplace(text, "\", "\\"), '"', '\"')
}


/**
 * Content of the file that removes the entry
 */
UnregisterText() {
    Return "Windows Registry Editor Version 5.00`r`n"
            . "`r`n[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\OpenInIDE]`r`n"
            . "`r`n[-HKEY_CURRENT_USER\Software\Classes\*\shell\OpenInIDE]`r`n"
}


/**
 * Writes a registry file in UTF-16 (for special characters in the folder)
 *
 * @param filename  an existing file is replaced
 * @param text      its content
 */
WriteReg(filename, text) {
    file := FileOpen(filename, "w", "UTF-16")
    file.Write(text)
    file.Close()
}

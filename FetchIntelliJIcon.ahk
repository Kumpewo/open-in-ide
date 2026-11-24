#Requires AutoHotkey v2.0
;@SetVersion 1.0.0

; Copies the icon of the newest installed IntelliJ IDEA as OpenInIDE.ico into the folder of this script.
; It is used as icon of OpenInIDE.exe the next time that script is compiled (otherwise
; default.ico). You can also put any other icon there under this name.

#Include "FindIntelliJ.ahk"

FetchIntelliJIcon(A_ScriptDir "\OpenInIDE.ico")


/**
 * Copies the original icon (asks before replacing an existing file) and shows the result
 *
 * @param target  full name of the copy
 */
FetchIntelliJIcon(target) {
    icon := FindIntelliJ("bin\idea.ico")
    If (icon = "") {
        MsgBox("The icon was not found: IntelliJ IDEA is not installed in one of the default"
                " installation places.",, "Icon!")
        Return
    }
    If (FileExist(target) and "Yes" != MsgBox("The file`n`n`t" target "`n`nalready exists."
            "`n`nDo you want to replace it with the icon of IntelliJ IDEA?",, "YesNo Icon? Default2"))
        Return
    Try {
        FileCopy(icon, target, true)
    } Catch as e {
        MsgBox("The icon`n`n`t" icon "`n`ncannot be copied to`n`n`t" target "`n`n(" e.Message ")",,
                "Icon!")
        Return
    }
    MsgBox("The icon`n`n`t" icon "`n`nwas copied to`n`n`t" target
            "`n`nIt becomes the icon of OpenInIDE.exe when you compile OpenInIDE.ahk again.",,
            "Iconi")
}

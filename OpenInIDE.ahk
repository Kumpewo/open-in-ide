#Requires AutoHotkey v2.0
;@Ahk2Exe-Base ..\v2\AutoHotkey64.exe
; ---------------------------------------------------------------------------
;@Ahk2Exe-SetProductName    OpenInIDE
;@Ahk2Exe-SetVersion        0.0.1
;@Ahk2Exe-SetDescription    Open folder or associated project in IntelliJ IDEA
;@Ahk2Exe-SetLanguage       0x0409
;@Ahk2Exe-SetCopyright      © 2026 Kumpewo
;@Ahk2Exe-Obey              U_icon, = FileExist("%A_ScriptDir~\x2C~`,%\OpenInIDE.ico") ? "OpenInIDE.ico" : "default.ico"
;@Ahk2Exe-SetMainIcon       %U_icon%
;;@Ahk2Exe-ConsoleApp
; ---------------------------------------------------------------------------

;@declare-type A_Args* as Array

#Include "FindIntelliJ.ahk"

If (A_Args.Length >= 1)
    OpenInIDE(A_Args[1])
Else {
    SplitPath(A_ScriptName,,,, &ScriptName)
    ExitWithReason("Usage: " ScriptName " <file or folder>")
}
Return

/**
 * Checks `path` and does this:
 *      - opens the project if path is a folder containing a subfolder .idea
 *      - opens the project specified in file's banner if it is a deployed file
 *        with standard/library banner
 *      - offers to create a project if path is a folder without a child ".idea"
 *      - complains that path cannot be opened as a project (various reasons)
 * IntelliJ IDEA must be present in one of the default installation places; the newest one is used.
 *
 * @param path
 */
OpenInIDE(path) {
    If (not FileExist(path))
        ExitWithReason("'" path "' does not exist.")
    fileAttr := FileGetAttrib(path)

    If (not InStr(FileGetAttrib(path), "D")) {
        SplitPath(path,,, &ext)
        if (ext = "exe")
            OpenEmbeddedProjectOrFail(path)
        else
            OpenProjectFromBannerOrFail(path)
    }

    projectSettings := JoinWindowsPath(path, ".idea")
    If (FileExist(projectSettings)
            and not InStr(FileGetAttrib(projectSettings), "D"))
        ExitWithReason("Folder '" path "' is not an IntelliJ project.`n`n"
                "(.idea exists, but it is not a folder.)")

    If (not FileExist(projectSettings)) {
        If "No" = MsgBox("Folder`n`t" path
                "`n`nis not yet an IntelliJ project."
                "`n`n`nDo you want to create a new project here?",, "YesNo")
            Exit(0)
    }

    RunIntelliJ(path)
}


RunIntelliJ(folder) {
    intelliJ := FindIntelliJ()
    If (not intelliJ)
        ExitWithReason("IntelliJ IDEA not found.")

    Run '"' intelliJ '" "' folder '"'
    ExitApp(0)
}


ExitWithReason(Reason, ExitCode := 1) {
    MsgBox(Reason,, "T15")
    ExitApp(ExitCode)
}

/**
 * Opens the project named in the "ahk-v2-plugin deploy banner" of a file directly with
 * RunIntelliJ() or fails using ExitWithReason()
 *
 * @param filename  File to check
 */
OpenProjectFromBannerOrFail(filename) {
    banner := ReadBanner(filename)
    If (not banner)
        ExitWithReason("'" filename "' does not refer to an IntelliJ project.")
    If (banner.folder = "")
        ExitWithReason("'" filename "' was deployed from project '" banner.name "'.`n`n"
                "(Its banner does not tell the project folder.)")
    OpenProjectOrFail(filename, banner.folder, banner.computer)
}

/**
 * Checks if filename starts with an "ahk-v2-plugin deploy banner" from one of the built-in
 * templates (@standard or @library) and reads the project from it. Banners with an own text are not
 * recognized.
 *
 * The banner may use any comment style (; # // :: /* ...) and may follow a first line such as #!,
 * <?xml or @echo off. The folder name in its line "Project <name> [<folder>]" must be <name>; the
 * folder is missing if the project was deployed with EmbedOrigin=no. The computer comes from the
 * line "Deployed <time> on <computer>".
 *
 * @param filename  File to check
 *
 * @returns object with name, folder and computer (the last two may be ""), or "" without banner
 */
ReadBanner(filename) {
    static heads := [
        "INSTALLED ARTIFACT -- Do not modify here. Edit the source and deploy again.",
        "INSTALLED LIBRARY  -  Do not modify here. Edit the source and deploy again."
    ]
    static dashes := "---------------------------------------------------------------------------"

    ; the banner starts in the first or second line: read a few lines only (the file may be large or
    ; binary)
    lines := []
    Try {
        stream := FileOpen(filename, "r")
        While (lines.Length < 20 and not stream.AtEOF)
            lines.Push(RTrim(stream.ReadLine(), "`r"))
        stream.Close()
    } Catch
        Return ""

    ; separator line, head line, empty comment line, project line
    Loop Min(lines.Length - 3, 3) {
        i := A_Index + 1
        pos := 0
        length := 0
        For head in heads {
            If (pos := InStr(lines[i], head, true)) {
                ; the loop variable `head` is restored after the loop!
                length := StrLen(head)
                Break
            }
        }
        If (not pos)
            Continue
        If (not InStr(lines[i - 1], dashes, true))
            Return ""

        ; comment start and end around the text, as in the head line
        prefix := SubStr(lines[i], 1, pos - 1)
        suffix := SubStr(lines[i], pos + length)

        ; line after head must be blank (except for comment start and end)
        blank := lines[i + 1]
        For part in [ Trim(prefix), Trim(suffix) ]
            If (part != "")
                blank := StrReplace(blank, part, "", true,, 1)
        If (Trim(blank) != "")
            Return ""

        ; line after blank line must be the project name, usually with its folder
        value := BannerValue(lines[i + 2], "Project     ", prefix, suffix)
        If (value = "")
            Return ""
        banner := {name: value, folder: "", computer: ""}
        If (RegExMatch(value, "^(.+) \[(.+)\]$", &match)) {
            ; last element of project folder must be the project name itself
            banner.name := match[1]
            banner.folder := RTrim(match[2], "\")
            SplitPath(banner.folder, &folderName)
            If (folderName != banner.name)
                Return ""
        }

        ; some lines later, up to the closing separator line: time and computer
        Loop lines.Length - i - 2 {
            line := lines[i + 2 + A_Index]
            If (InStr(line, dashes, true))
                Break
            value := BannerValue(line, "Deployed    ", prefix, suffix)
            If (RegExMatch(value, "^\d{4}-\d\d-\d\d \d\d:\d\d on (.+)$", &match))
                banner.computer := match[1]
        }
        Return banner
    }
    Return ""
}


/**
 * Returns the value of a banner line
 *
 * @param line    the complete line
 * @param label   label with the spaces up to the value
 * @param prefix  comment start before the label
 * @param suffix  comment end after the value
 *
 * @returns the value or "" if the line has another label
 */
BannerValue(line, label, prefix, suffix) {
    start := prefix label
    If (SubStr(line, 1, StrLen(start)) !== start)
        Return ""
    If (suffix != "" and SubStr(line, -StrLen(suffix)) !== suffix)
        Return ""
    Return SubStr(line, StrLen(start) + 1, StrLen(line) - StrLen(start) - StrLen(suffix))
}


/**
 * Opens the project folder with RunIntelliJ() or explains using ExitWithReason() why it cannot be
 * opened on this computer
 *
 * @param path      deployed file
 * @param folder    project folder embedded in this file
 * @param computer  computer embedded in this file, "" if unknown
 */
OpenProjectOrFail(path, folder, computer) {
    If (DirExist(folder))
        RunIntelliJ(folder)

    reason := "'" path "' was deployed from project`n`n`t" folder
    If (computer != "" and computer != A_ComputerName)
        reason .= "`n`non computer " computer ". This project does not exist here on "
                . A_ComputerName "."
    Else
        reason .= "`n`nThis folder does not exist (any more)."
    ExitWithReason(reason)
}

/**
 * Reads special block at end of file and figures out the project behind this executable
 *
 * Opens existing project directly with RunIntellij() or fails using ExitWithReason()
 *
 * @param path  full name of an executable
 */
OpenEmbeddedProjectOrFail(path) {
    static header := "[ahk-v2-plugin]"
    static maxBytes := 8192

    ; the block is at the very end: read the last bytes only
    Try {
        stream := FileOpen(path, "r")
        size := Min(stream.Length, maxBytes)
        stream.Seek(-size, 2)
        tail := Buffer(size)
        If (size > 0)
            size := stream.RawRead(tail)
        stream.Close()
    } Catch as e
        ExitWithReason("'" path "' cannot be read.`n`n(" e.Message ")")

    ; the last block counts; compare bytes, because anything may come before it
    text := ""
    pos := size - StrLen(header)
    While (pos >= 0) {
        If (StrGet(tail.Ptr + pos, StrLen(header), "CP1252") == header) {
            text := StrGet(tail.Ptr + pos, size - pos, "UTF-8")
            Break
        }
        pos--
    }
    If (not RegExMatch(text, "`am)^ProjectPath=(.+)$", &project))
        ExitWithReason("'" path "' does not refer to an IntelliJ project.")

    folder := project[1]
    RegExMatch(text, "`am)^ProjectComputer=(.+)$", &computer)
    OpenProjectOrFail(path, folder, computer ? computer[1] : "")
}


/**
 * Join all parts to a Windows Path with "\" delimiters
 *
 * @param Directory            a directory to start with
 * @param DirectoryOrFilename  more path elements
 *
 * @returns a Windows style path
 */
JoinWindowsPath(Directory, DirectoryOrFilename*)
{
    Path := RTrim(Directory, "\")
    For n in DirectoryOrFilename
        Path .= "\" RTrim(n, "\")
    Return RegExReplace(Path, "/", "\")
}

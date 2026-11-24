#Requires AutoHotkey v2.0
;@SetVersion 1.0.0

; The only place that knows where the IDE is installed: change it here to use another IDE.

/**
 * Find the newest installed version of IntelliJ IDEA among the installations for all users (program
 * files) and those in the user folder (installer "for the current user only" or the JetBrains
 * Toolbox App), e.g. %LOCALAPPDATA%\Programs\IntelliJ IDEA Ultimate
 *
 * @param What  file or folder within IntelliJ folder
 *
 * @returns Path of the executable or ""
 */
FindIntelliJ(What := "bin\idea64.exe") {
    folderPatterns := [ A_ProgramFiles "\JetBrains\IntelliJ IDEA *"
            , EnvGet("LOCALAPPDATA") "\Programs\IntelliJ IDEA*" ]
    Return FindNewest(folderPatterns, What)
}


/**
 * Search in all folders that match one of the patterns for `RelativeFilePath`
 *
 * The build number decides which one is the newest, not the name of the folder: an update of the IDE
 * keeps the folder of the old version. Folders without a build number come last; of equal ones the
 * first is taken.
 *
 * @param FolderPatterns    array of folder names with wildcards
 * @param RelativeFilePath
 *
 * @returns match in the newest installation or ""
 */
FindNewest(FolderPatterns, RelativeFilePath) {
    newest := ""
    newestBuild := ""
    For folderPattern in FolderPatterns {
        Loop Files, folderPattern, "D" {
            candidate := A_LoopFileFullPath "\" RelativeFilePath
            If (not FileExist(candidate))
                Continue
            build := ReadBuildNumber(A_LoopFileFullPath)
            If (newest = "" or IsNewerBuild(build, newestBuild)) {
                newest := candidate
                newestBuild := build
            }
        }
    }
    Return newest
}


/**
 * Is `Build` newer than `Other` (compared part by part as numbers)? An empty build number is older
 * than any other.
 *
 * @param Build  e.g. 263.7307.200
 * @param Other
 */
IsNewerBuild(Build, Other) {
    If (Build = "" or Other = "")
        Return Build != "" and Other = ""
    Return VerCompare(Build, Other) > 0
}


/**
 * Read the build number of an installed JetBrains IDE from its product-info.json
 *
 * @param Folder  installation folder
 *
 * @returns e.g. 263.7307.200, or "" if it cannot be read
 */
ReadBuildNumber(Folder) {
    Try
        text := FileRead(Folder "\product-info.json", "UTF-8")
    Catch
        Return ""
    If (RegExMatch(text, '"buildNumber"\s*:\s*"(\d+(?:\.\d+)*)', &match))
        Return match[1]
    Return ""
}

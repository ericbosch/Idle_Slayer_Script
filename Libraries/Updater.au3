#include-once
#include <Crypt.au3>
#include <InetConstants.au3>
#include <MsgBoxConstants.au3>

Global Const $UPDATER_RELEASES_URL = "https://github.com/ericbosch/Idle_Slayer_Script/releases"
Global Const $UPDATER_API_URL = "https://api.github.com/repos/ericbosch/Idle_Slayer_Script/releases/latest"
Global $g_sUpdaterHealthSignal = ""

Func _Updater_HandleCommandLine()
	If $CmdLine[0] >= 1 And $CmdLine[1] = "--apply-update" Then
		If $CmdLine[0] <> 7 Then Exit 2
		_Updater_Apply($CmdLine[2], $CmdLine[3], $CmdLine[4], $CmdLine[5], Int($CmdLine[6]), $CmdLine[7])
		Exit
	EndIf

	If $CmdLine[0] = 2 And $CmdLine[1] = "--post-update" Then
		$g_sUpdaterHealthSignal = $CmdLine[2]
	EndIf
	Return False
EndFunc

Func _Updater_MarkStartupHealthy($sCurrentVersion)
	If $g_sUpdaterHealthSignal = "" Then Return
	Local $hFile = FileOpen($g_sUpdaterHealthSignal, 2)
	If $hFile = -1 Then Return
	FileWrite($hFile, $sCurrentVersion & "|" & @AutoItPID)
	FileClose($hFile)
EndFunc

Func _Updater_CheckForUpdate($sCurrentVersion)
	If Not @Compiled Then
		MsgBox($MB_ICONINFORMATION, "Update", "Automatic updates are available in compiled releases only.")
		ShellExecute($UPDATER_RELEASES_URL)
		Return False
	EndIf

	Local $dData = InetRead($UPDATER_API_URL, $INET_FORCERELOAD)
	If @error Then Return _Updater_ManualFallback("Could not retrieve release information. Check your connection and try again.")

	Local $aTag = StringRegExp(BinaryToString($dData), '"tag_name"\s*:\s*"([^"\\]+)"', 1)
	If Not IsArray($aTag) Then Return _Updater_ManualFallback("GitHub returned invalid release information.")

	Local $sReleaseTag = $aTag[0]
	Local $sLatestVersion = StringRegExpReplace($sReleaseTag, "^[vV]", "")
	If Not StringRegExp($sReleaseTag, "^[vV]?[0-9]+(?:\.[0-9]+){1,3}$") Then Return _Updater_ManualFallback("GitHub returned an invalid release tag.")
	Local $iComparison = _Updater_CompareVersions($sLatestVersion, $sCurrentVersion)
	If $iComparison <= 0 Then
		MsgBox($MB_ICONINFORMATION, "Latest Version", "Idle Runner " & $sCurrentVersion & " is up to date.")
		Return False
	EndIf

	Local $sArch = "x32"
	If @AutoItX64 Then $sArch = "x64"
	Local $sAssetName = "Idle.Runner_" & $sLatestVersion & "_" & $sArch & ".exe"
	Local $iConfirm = MsgBox($MB_ICONQUESTION + $MB_OKCANCEL, "Update Available", _
		"Update Idle Runner " & $sCurrentVersion & " to " & $sLatestVersion & " (" & $sArch & ")?" & @CRLF & @CRLF & _
		"Idle Runner will close, install the verified update, and restart.")
	If $iConfirm <> $IDOK Then Return False

	Local $sInstallDir = @ScriptDir
	If Not _Updater_CanWriteDirectory($sInstallDir) Then
		Return _Updater_ManualFallback("Idle Runner cannot update this folder without additional permissions.")
	EndIf

	Local $sToken = @AutoItPID & "-" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
	Local $sWorkDir = @TempDir & "\IdleRunnerUpdate\" & $sToken
	DirCreate($sWorkDir)
	If Not FileExists($sWorkDir) Then Return _Updater_ManualFallback("Could not create the temporary update folder.")

	Local $sBaseUrl = "https://github.com/ericbosch/Idle_Slayer_Script/releases/download/" & $sReleaseTag & "/"
	Local $sChecksumPath = $sWorkDir & "\SHA256SUMS.txt"
	Local $sDownloadPath = $sWorkDir & "\" & $sAssetName & ".part"
	If Not _Updater_Download($sBaseUrl & "SHA256SUMS.txt", $sChecksumPath) Then Return _Updater_ManualFallback("The checksum file could not be downloaded.")
	If Not _Updater_Download($sBaseUrl & $sAssetName, $sDownloadPath) Then Return _Updater_ManualFallback("The update download was interrupted.")

	Local $sExpectedHash = _Updater_ExpectedHash(FileRead($sChecksumPath), $sAssetName)
	If $sExpectedHash = "" Or Not _Updater_VerifySha256($sDownloadPath, $sExpectedHash) Then
		FileDelete($sDownloadPath)
		Return _Updater_ManualFallback("SHA-256 verification failed. The downloaded file was deleted.")
	EndIf

	Local $sHelperPath = $sWorkDir & "\IdleRunnerUpdater.exe"
	If Not FileCopy(@ScriptFullPath, $sHelperPath, 9) Then Return _Updater_ManualFallback("The updater helper could not be created. Antivirus software may be holding the file.")

	Local $sBackupPath = @ScriptFullPath & ".update-backup"
	Local $sSignalPath = $sWorkDir & "\startup.ready"
	Local $sWorkerPids = _Updater_GetWorkerPids()
	Local $sCommand = _Updater_Quote($sHelperPath) & " --apply-update " & _Updater_Quote(@ScriptFullPath) & " " & _
		_Updater_Quote($sDownloadPath) & " " & _Updater_Quote($sBackupPath) & " " & _Updater_Quote($sSignalPath) & " " & _
		@AutoItPID & " " & _Updater_Quote($sWorkerPids)
	Local $iHelperPid = Run($sCommand, $sWorkDir)
	If $iHelperPid = 0 Then Return _Updater_ManualFallback("The updater helper could not be started.")
	Return True
EndFunc

Func _Updater_Apply($sTarget, $sDownload, $sBackup, $sSignal, $iParentPid, $sWorkerPids)
	ProcessWaitClose($iParentPid, 15)
	_Updater_WaitForWorkers($sWorkerPids, 10)
	FileDelete($sSignal)
	FileDelete($sBackup)

	If Not _Updater_RetryFileMove($sTarget, $sBackup, 10) Then
		Run(_Updater_Quote($sTarget), _Updater_DirectoryName($sTarget))
		_Updater_HelperError("Could not back up the installed executable. It may be locked by antivirus software.", $sTarget)
		Return
	EndIf
	If Not _Updater_RetryFileMove($sDownload, $sTarget, 10) Then
		_Updater_Restore($sTarget, $sBackup)
		Run(_Updater_Quote($sTarget), _Updater_DirectoryName($sTarget))
		_Updater_HelperError("Could not install the downloaded executable. The previous version was restored.", $sTarget)
		Return
	EndIf

	Local $sInstallDir = _Updater_DirectoryName($sTarget)
	Local $iNewPid = Run(_Updater_Quote($sTarget) & " --post-update " & _Updater_Quote($sSignal), $sInstallDir)
	If $iNewPid > 0 And _Updater_WaitForFile($sSignal, 30) Then
		FileDelete($sBackup)
		Return
	EndIf

	If $iNewPid > 0 And ProcessExists($iNewPid) Then
		ProcessClose($iNewPid)
		ProcessWaitClose($iNewPid, 5)
	EndIf
	_Updater_Restore($sTarget, $sBackup)
	Run(_Updater_Quote($sTarget), $sInstallDir)
	_Updater_HelperError("The new version did not signal a successful start. Idle Runner rolled back to the previous version.", $sTarget)
EndFunc

Func _Updater_GetWorkerPids()
	__AuThread_RefreshAliveThreads()
	Local $sPids = ""
	For $i = 1 To $_AuThread_CurrentSlaveAlive[0]
		If $sPids <> "" Then $sPids &= ","
		$sPids &= Int($_AuThread_CurrentSlaveAlive[$i])
	Next
	Return $sPids
EndFunc

Func _Updater_WaitForWorkers($sWorkerPids, $iTimeoutSeconds)
	If $sWorkerPids = "" Then Return
	Local $aPids = StringSplit($sWorkerPids, ",", 2)
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
		Local $bAnyAlive = False
		For $iPid In $aPids
			If Int($iPid) > 0 And ProcessExists(Int($iPid)) Then $bAnyAlive = True
		Next
		If Not $bAnyAlive Then Return
		Sleep(100)
	WEnd
	For $iPid In $aPids
		If Int($iPid) > 0 And ProcessExists(Int($iPid)) Then ProcessClose(Int($iPid))
	Next
EndFunc

Func _Updater_Download($sUrl, $sDestination)
	FileDelete($sDestination)
	For $iAttempt = 1 To 3
		Local $iBytes = InetGet($sUrl, $sDestination, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
		If Not @error And $iBytes > 0 And FileGetSize($sDestination) > 0 Then Return True
		FileDelete($sDestination)
		Sleep($iAttempt * 750)
	Next
	Return False
EndFunc

Func _Updater_VerifySha256($sPath, $sExpectedHash)
	_Crypt_Startup()
	Local $vHash = _Crypt_HashFile($sPath, $CALG_SHA_256)
	_Crypt_Shutdown()
	If @error Then Return False
	Local $sActualHash = StringLower(StringTrimLeft(String($vHash), 2))
	Return $sActualHash = StringLower($sExpectedHash)
EndFunc

Func _Updater_ExpectedHash($sChecksumText, $sAssetName)
	Local $sEscapedName = StringRegExpReplace($sAssetName, "([\\.\[\]\(\)\{\}\+\*\?\^\$\|])", "\\$1")
	Local $aMatch = StringRegExp($sChecksumText, "(?im)^([0-9a-f]{64})[ \t]+\\*?" & $sEscapedName & "[ \t]*$", 1)
	If Not IsArray($aMatch) Then Return ""
	Return StringLower($aMatch[0])
EndFunc

Func _Updater_CompareVersions($sLeft, $sRight)
	Local $aLeft = StringSplit(StringRegExpReplace($sLeft, "^[vV]", ""), ".", 2)
	Local $aRight = StringSplit(StringRegExpReplace($sRight, "^[vV]", ""), ".", 2)
	For $i = 0 To 3
		Local $iLeft = 0, $iRight = 0
		If $i < UBound($aLeft) Then $iLeft = Int($aLeft[$i])
		If $i < UBound($aRight) Then $iRight = Int($aRight[$i])
		If $iLeft > $iRight Then Return 1
		If $iLeft < $iRight Then Return -1
	Next
	Return 0
EndFunc

Func _Updater_CanWriteDirectory($sDirectory)
	Local $sProbe = $sDirectory & "\.idle-runner-update-" & @AutoItPID & ".tmp"
	Local $hFile = FileOpen($sProbe, 2)
	If $hFile = -1 Then Return False
	FileWrite($hFile, "probe")
	FileClose($hFile)
	Return FileDelete($sProbe)
EndFunc

Func _Updater_RetryFileMove($sSource, $sDestination, $iAttempts)
	For $iAttempt = 1 To $iAttempts
		If FileMove($sSource, $sDestination, 9) Then Return True
		Sleep($iAttempt * 250)
	Next
	Return False
EndFunc

Func _Updater_Restore($sTarget, $sBackup)
	FileDelete($sTarget)
	_Updater_RetryFileMove($sBackup, $sTarget, 10)
EndFunc

Func _Updater_WaitForFile($sPath, $iTimeoutSeconds)
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
		If FileExists($sPath) Then Return True
		Sleep(100)
	WEnd
	Return False
EndFunc

Func _Updater_ManualFallback($sMessage)
	Local $iResult = MsgBox($MB_ICONERROR + $MB_OKCANCEL, "Update Failed", $sMessage & @CRLF & @CRLF & "Open the manual download page?")
	If $iResult = $IDOK Then ShellExecute($UPDATER_RELEASES_URL)
	Return False
EndFunc

Func _Updater_HelperError($sMessage, $sTarget)
	Local $sLogDir = StringLeft($sTarget, StringInStr($sTarget, "\", 0, -1) - 1) & "\IdleRunnerLogs"
	DirCreate($sLogDir)
	FileWriteLine($sLogDir & "\Updater.log", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " " & $sMessage)
	Local $iResult = MsgBox($MB_ICONERROR + $MB_OKCANCEL, "Idle Runner Updater", $sMessage & @CRLF & @CRLF & "Open the manual download page?")
	If $iResult = $IDOK Then ShellExecute($UPDATER_RELEASES_URL)
EndFunc

Func _Updater_Quote($sValue)
	Return '"' & $sValue & '"'
EndFunc

Func _Updater_DirectoryName($sPath)
	Local $iSlash = StringInStr($sPath, "\", 0, -1)
	If $iSlash = 0 Then Return @WorkingDir
	Return StringLeft($sPath, $iSlash - 1)
EndFunc

#include "..\Libraries\AutoThreadV3.au3"
#include "..\Libraries\Updater.au3"

Global $iFailures = 0

AssertEqual(_Updater_CompareVersions("3.5.9.1", "3.5.9.0"), 1, "patch update")
AssertEqual(_Updater_CompareVersions("v3.5.9.0", "3.5.9.0"), 0, "v prefix")
AssertEqual(_Updater_CompareVersions("3.5.8.2", "3.5.9.0"), -1, "older release")
AssertEqual(_Updater_CompareVersions("3.6", "3.5.9.9"), 1, "missing components")

Local $sHash = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
Local $sManifest = $sHash & "  Idle.Runner_3.5.9.0_x64.exe" & @CRLF & _
	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff  Idle.Runner_3.5.9.0_x32.exe"
AssertEqual(_Updater_ExpectedHash($sManifest, "Idle.Runner_3.5.9.0_x64.exe"), $sHash, "matching checksum")
AssertEqual(_Updater_ExpectedHash($sManifest, "IdleXRunner_3.5.9.0_x64.exe"), "", "literal asset name")
AssertEqual(_Updater_ExpectedHash("not-a-hash  Idle.Runner_3.5.9.0_x64.exe", "Idle.Runner_3.5.9.0_x64.exe"), "", "invalid checksum")

If $iFailures > 0 Then
	ConsoleWrite("FAILED: " & $iFailures & " updater test(s)" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("PASSED: updater unit tests" & @CRLF)
Exit 0

Func AssertEqual($vActual, $vExpected, $sName)
	If $vActual = $vExpected Then Return
	$iFailures += 1
	ConsoleWrite("FAIL " & $sName & ": expected [" & $vExpected & "] got [" & $vActual & "]" & @CRLF)
EndFunc

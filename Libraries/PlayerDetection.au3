#include-once

; Known character/skin body colors for Ascending Heights player detection.
Global $aPlayerColors[12] = [0xECF3FF, 0x5D6969, 0xCC9053, 0x2E4659, 0xE7A63D, 0x2A2586, 0xB12544, 0x7A5B8A, 0xFF6400, 0x175D5B, 0x796420, 0xA5AEEA]
Global $aPlayerNames[12] = ["Minita", "Runhardt", "Cliff", "Roy", "Skar", "Agnis", "Agnis", "Anna", "Haskell", "Azure", "Benvolio", "Fayar"]
Global $iPlayerColorShade = 1
Global $g_sDetectedSkin = ""

Func FindPlayer($iX1, $iY1, $iX2, $iY2)
	Local $aPos
	For $i = 0 To UBound($aPlayerColors) - 1
		$aPos = PixelSearch($iX1, $iY1, $iX2, $iY2, $aPlayerColors[$i], $iPlayerColorShade)
		If Not @error Then
			$g_sDetectedSkin = $aPlayerNames[$i]
			Return $aPos
		EndIf
	Next
	Return SetError(1, 0, 0)
EndFunc   ;==>FindPlayer

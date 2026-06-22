If $CmdLine[0] <> 2 Or $CmdLine[1] <> "--post-update" Then Exit 2

Local $hSignal = FileOpen($CmdLine[2], 2)
If $hSignal = -1 Then Exit 3
FileWrite($hSignal, @WorkingDir)
FileClose($hSignal)
Exit 0

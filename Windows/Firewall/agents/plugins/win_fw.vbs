'====================================== 
' win_fw.vbs
'
' Original Author: Kai Biebel <snoocer.ps@googlemail.com>
' Created: 2015-03-02
' Version: 0.1
' Description: Check Windows Firewall State per Profile
'====================================== 


Wscript.echo("<<<win_fw:encoding(latin_1)>>>")
Wscript.echo execStdOut("netsh advfirewall show allprofile state")

Function execStdOut(cmd)
   Dim goWSH : Set goWSH = CreateObject( "WScript.Shell" ) 
   Dim aRet: Set aRet = goWSH.exec(cmd)
   execStdOut = aRet.StdOut.ReadAll()
End Function

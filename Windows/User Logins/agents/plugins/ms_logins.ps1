#################################################################
# Microsoft Logins
#################################################################
# Created By: Kevin Tijssen
# Created On: 18-04-2017
#################################################################

Function Get-ComputerSessions {
<#
.SYNOPSIS
    Retrieves tall user sessions from local or remote server/s
.DESCRIPTION
    Retrieves tall user sessions from local or remote server/s
.PARAMETER computer
    Name of computer/s to run session query against.
.NOTES
    Name: Get-ComputerSessions
    Author: Boe Prox
    DateCreated: 01Nov2010
 
.LINK
    https://boeprox.wordpress.org
.EXAMPLE
Get-ComputerSessions -computer "server1"
 
Description
-----------
This command will query all current user sessions on 'server1'.
 
#>
[cmdletbinding(
    DefaultParameterSetName = 'session',
    ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ValueFromPipeline = $True)]
            [string[]]$Computer
            )
Begin {
    $report = @()
    }
Process {
    If ($Computer -eq $null) {
        $Computer = "localhost"
        }
    ForEach($c in $Computer) {
        # Parse 'query session' and store in $sessions:
        $sessions = query session /server:$c
            1..($sessions.count -1) | % {
                $temp = "" | Select Computer,SessionName, Username, Id, State, Type, Device
                $temp.Computer = $c
                $temp.SessionName = $sessions[$_].Substring(1,18).Trim()
                $temp.Username = $sessions[$_].Substring(19,20).Trim()
                $temp.Id = $sessions[$_].Substring(39,9).Trim()
                $temp.State = $sessions[$_].Substring(48,8).Trim()
                $temp.Type = $sessions[$_].Substring(56,12).Trim()
                $temp.Device = $sessions[$_].Substring(68).Trim()
                $report += $temp
            }
        }
    }
End {
    $report
    }
}

$User_Sessions = Get-ComputerSessions | select Username, State | Where-Object {$_.username -ne ""}

$ActiveSessions = 0
$ActiveUsers =""
$DisconnectedSessions = 0
$DisconnectedUsers = ""
$Users = ""

ForEach ($User_Session in $User_Sessions) {

    If ($User_Session.State -eq "Active") {
        $ActiveSessions++
        $ActiveUsers += $User_Session.Username + ", "
        }

    ElseIf ($User_Session.State -eq "Disc") {
        $DisconnectedSessions++
        $DisconnectedUsers += $User_Session.Username + ", "
        }
    }

If (!$ActiveUsers) {
    $ActiveUsers = "None"
    }
Else {
    $ActiveUsers = $ActiveUsers.Substring(0,$ActiveUsers.Length-2)
    }

If (!$DisconnectedUsers) {
    $DisconnectedUsers = "None"
    }
Else {
    $DisconnectedUsers = $DisconnectedUsers.Substring(0,$DisconnectedUsers.Length-2)
    }

"<<<ms_logins:sep(9)>>>"
"$ActiveSessions`t$DisconnectedSessions`t$ActiveUsers`t$DisconnectedUsers"

#################################################################
# Windows Defender
#################################################################
# Created By: Kevin Tijssen
#################################################################

$RTP = Get-MpComputerStatus | select -ExpandProperty RealTimeProtectionEnabled
$AS_Age = Get-MpComputerStatus | select -ExpandProperty AntispywareSignatureAge
$AV_Age = Get-MpComputerStatus | select -ExpandProperty AntivirusSignatureAge

Write-Host "<<<win_defender:sep(9)>>>"
Write-Host $RTP "`t" $AS_Age "`t" $AV_Age
"<<<mscs_resources:sep(9)>>>"
Get-ClusterResource -ErrorAction SilentlyContinue | Where-Object -FilterScript { $_.ResourceType -ne 'Ip Address' -and $_.ResourceType -ne 'Network Name' } | ForEach-Object -Process {
    $_.Name + "`t" + $_.State + "`t" + $_.OwnerNode
}
"<<<mscs_nodes:sep(9)>>>"
Get-ClusterNode -ErrorAction SilentlyContinue | ForEach-Object -Process {
    $_.Name + "`t" + $_.State
}

#################################################################
# Created By: Kevin Tijssen (Sligro Food Group B.V.)            #
# Created On: 15-12-2016                                        #
#################################################################

# Errorcodes
# 0 - OK
# 21 - Pool is disabled
# 22 - Provisioning is disabled
# 23 - vCenter provisioning is disabled
# 31 - Pool not found
# 32 - Pool type unknown

# Get the relative path of the executing script.
$relPath = [string](Split-Path $script:MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue)

# Get path of the config files
$ConfigLocation = "$relPath\..\config"

# Load inventory with config files
$PoolIniFiles = Get-ChildItem $ConfigLocation\vdmpool_*.ini

# Check if config files found
If ($PoolIniFiles -eq $Null)
{
	Break
}

"<<<vmware_vdm_pool>>>"

ForEach ($Pool in $PoolIniFiles)
{

    # Parameters.

    $PoolInfo = Get-Content $Pool
    $P = $PoolInfo

    # unit of measurement.
    $sessionUOM = ""
    $desktopUOM = ""

    # Include library file.
    . "$relPath\..\config\lib_vmware_vdm_pool.ps1"

    #Reset Pool Error
    $Pool_Error = "False"

    #Reset Pool PerfData
    $DummyperfData = "0 0 0 0 0 0 0 0 0 0 0 0 0 0"
    $perfData = ""

    # Desktop statistics.
	$statsDesktops = @{}
	$statsDesktops.Used = 0
    $statsDesktops.Count = 0
    $statsDesktops.Error = 0
    $statsDesktops.Maximum = 0
	$statsDesktops.Deleting = 0
	$statsDesktops.Available = 0
	$statsDesktops.AlreadyUsed = 0
	$statsDesktops.Provisioning = 0
	$statsDesktops.Maintenance = 0

	# Session statistics.
	$statsSessions = @{}
	$statsSessions.Count = 0
	$statsSessions.Disconnected = 0
	$statsSessions.ProtocolRDP = 0
	$statsSessions.ProtocolPCoIP = 0
	$statsSessions.ProtocolBLAST = 0

	# Get Pool from View.
	$pool = Get-VDMPool $P

    # Validate if the pool exists.
	If ($pool -eq $Null)
	{
	    "$P 31 Unknown $DummyperfData"
        $Pool_Error = "True"
	}
    
    Else
    {
        # Get pool session(s).
	    $sessions = Get-VDMSessions $pool.Id
        
        # Floating Desktops Pool.
	    If ($pool.DeliveryModel -eq "Provisioned")
	    {
            # Set stats.
		    $statsDesktops.Maximum = $pool.MaximumDesktops
		    $statsDesktops.Count = $pool.Members.Count

            # Validate if any desktops are allocated.
		    If ($pool.Members.Count -gt 0)
            {
                # Loop through the desktops.
			    ForEach ($memberId In $pool.Members)
			    {
				    # Get desktop object.
				       $desktop = Get-VDMPoolMember $memberId

				    # Get session(s) belonging to this desktop.
				    $desktopSessions = $sessions | Where-Object { $_.DNSName -eq $desktop.DNSName }
				    $statsDesktopSessions = 0

				    # Collect stats from sessions.
				    If ($desktopSessions -ne $NullArray)
				    {

					    # Update used desktops count.
					    $statsDesktops.Used++

					    # Loop through the sessions.
					    ForEach ($session In $desktopSessions)
					    {

						    # Update session count.
						    $statsSessions.Count++
						    $statsDesktopSessions++

						    # Update protocol usage count.
						    If ($session.Protocol -eq "PCOIP")
						    {
							    $statsSessions.ProtocolPCoIP++
						    }
						    ElseIf ($session.Protocol -eq "RDP")
						    {
							    $statsSessions.ProtocolRDP++
						    }
						    ElseIf ($session.Protocol -eq "BLAST")
						    {
							    $statsSessions.ProtocolBLAST++
						    }

						    # Update disconnected state count.
						    If ($session.State -eq "DISCONNECTED")
						    {
							$statsSessions.Disconnected++
						    }

					    }

				    }

                    # Update desktop state statistics.
				    If ($desktop.State -eq "READY")
				    {
                        # Check if desktop is available.
					    If ($statsDesktopSessions -eq 0)
					    {

						    # Check for dirty desktop.
						    If ($desktop.Dirty -eq $True)
						    {
							$statsDesktops.AlreadyUsed++
						    }

						    # Desktop is available.
						    Else
						    {
							$statsDesktops.Available++
						    }

					    }
				    }

                    # Desktop is provisioning.
				    ElseIf (($desktop.State -eq $null) -or ($desktop.State -eq "CUSTOMIZING") -or ($desktop.State -eq "CLONING"))
				    {
					    $statsDesktops.Provisioning++
				    }

				    # Desktop is deleting.
				    ElseIf ($desktop.State -eq "DELETING")
				    {
					    $statsDesktops.Deleting++
				    }

				    # Desktop is in maintenance.
				    ElseIf ($desktop.State -eq "MAINTENANCE")
				    {
					    $statsDesktops.Maintenance++
				    }
				
				    # Desktop state is unknown.
				    Else
				    {
					    $statsDesktops.Error++
				    }
                }
            }

            # Build data.
            $perfData  = ""
		    $perfData  = "$($statsDesktops.Count)$desktopUOM "
            $perfData += "$($statsDesktops.Maximum) "
		    $perfData += "$($statsDesktops.Available)$desktopUOM "
		    $perfData += "$($statsDesktops.Provisioning)$desktopUOM "
		    $perfData += "$($statsDesktops.Error)$desktopUOM "
		    $perfData += "$($statsDesktops.AlreadyUsed)$desktopUOM "
            $perfData += "$($statsDesktops.Maintenance)$desktopUOM "

		    $perfData += "$($statsSessions.Count)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolPCoIP)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolRDP)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolBLAST)$sessionUOM "
		    $perfData += "$($statsSessions.Disconnected)$sessionUOM "

	    }
    
        # Terminal Services pool or manual pool.
	    ElseIf (($pool.DeliveryModel -eq "TerminalService") -or ($pool.DeliveryModel -eq "Manual"))
	    {

            # Validate that sessions exist.
		    If ($sessions -ne $NullArray)
		    {

                # Loop through the sessions.
			    ForEach ($session In $sessions)
			    {

				    # Update session count.
                    $statsSessions.Count++

				    # Update protocol usage count.
				    If ($session.Protocol -eq "PCOIP")
				    {
					    $statsSessions.ProtocolPCoIP++
				    }
				    ElseIf ($session.Protocol -eq "RDP")
				    {
					    $statsSessions.ProtocolRDP++
				    }
				        ElseIf ($session.Protocol -eq "BLAST")
				    {
					    $statsSessions.ProtocolBLAST++
				    }

				    # Update disconnected state count.
				    If ($session.State -eq "DISCONNECTED")
				    {
					    $statsSessions.Disconnected++
				    }

			    }
            }

		    # Build performance data
            $perfData  = ""
		    $perfData  = "$($statsDesktops.Count)$desktopUOM "
            $perfData += "$($statsDesktops.Maximum) "
		    $perfData += "$($statsDesktops.Available)$desktopUOM "
		    $perfData += "$($statsDesktops.Provisioning)$desktopUOM "
		    $perfData += "$($statsDesktops.Error)$desktopUOM "
		    $perfData += "$($statsDesktops.AlreadyUsed)$desktopUOM "
            $perfData += "$($statsDesktops.Maintenance)$desktopUOM "

		    $perfData += "$($statsSessions.Count)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolPCoIP)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolRDP)$sessionUOM "
		    $perfData += "$($statsSessions.ProtocolBLAST)$sessionUOM "
		    $perfData += "$($statsSessions.Disconnected)$sessionUOM "

        }

        # Unknown pool type.
	    Else
	    {
		    "$P 32 Unknown $DummyperfData"
            $Pool_Error = "True"
	    }

        # Validate if pool is enabled.
        If ($pool.Enabled -eq $False)
	    {
		    "$P 21 $($pool.DeliveryModel) $perfData"
            Continue
	    }

	    # Desktop pool checks.
        If ($pool.DeliveryModel -eq "Provisioned")
        {
		
		    # Validate if pool provisioning is enabled.
		    If ($pool.ProvisioningEnabled -eq $False)
		    {
		        "$P 22 $($pool.DeliveryModel) $perfData"
                Continue
		    }
		
		    # Validate if vCenter provisioning is enabled.
		    If ($pool.vCenterEnabled -eq $False)
		    {
		        "$P 23 $($pool.DeliveryModel) $perfData"
                Continue
		    }

	    }

	}

    If ($Pool_Error -eq "False")
    {
	    # Default pool result. 
        "$P 0 $($pool.DeliveryModel) $perfData"
    }
    
}

#!/usr/bin/python
# -*- encoding: utf-8; py-indent-offset: 4 -*-

#################################################################
# Created By: Kevin Tijssen (Sligro Food Group B.V.)            #
# Created On: 15-12-2016                                        #
#################################################################

# Load VMware.View.Broker if not loaded yet.
if ( (Get-PSSnapin -Name VMware.View.Broker -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin VMware.View.Broker
}

$vdmServer = "localhost"
$vdmDatabase = "dc=vdi,dc=vmware,dc=int"


#################################################################
# Get-VDMPool
#################################################################

Function Get-VDMPool
{

	Param(
		[string]$poolId
	)

	# Validate if object exists in ADAM database.
	If ([ADSI]::Exists("LDAP://$vdmServer/cn=$poolId,ou=Applications,$vdmDatabase") -eq $False)
	{
		Return $null
	}

	# Get object from ADAM database.
	$appObj = [ADSI]("LDAP://$vdmServer/cn=$poolId,ou=Applications,$vdmDatabase")

    # Get server groups.
	$serverGroupDN = try { $appObj.GetEx("pae-Servers") } catch { $null }

    # Validate server group.
    If ($serverGroupDN -eq $null)
    {
        Return $null
    }

	# Validate if object exists in ADAM database.
	If ([ADSI]::Exists("LDAP://$vdmServer/$serverGroupDN") -eq $False)
	{
		Return $null
	}

	# Get object from ADAM database.
	$poolObj = [ADSI]("LDAP://$vdmServer/$serverGroupDN")

	# Define pool object.
	$pool = @{}
	$pool.Id = $poolId
	$pool.Name = try { [string]$poolObj.get("pae-DisplayName") } catch { $poolId }
	$pool.Type = try { [int]$poolObj.get("pae-ServerPoolType") } catch { 0 }
	$pool.Enabled = try { ([int]$poolObj.get("pae-Disabled") -eq 0) } catch { $false }

	# Get members.
	$members = try { $poolObj.GetEx("pae-MemberDN") } catch { @() }
	$pool.Members = @()

	If ( $members -ne $null )
	{

		# Loop through the pool members.
		ForEach ($member In $members )
		{

			# Get member Id.
			If ($member -imatch "cn=([0-9a-f\-]+)" -eq $True)
			{
				$pool.Members += $matches[1]
			}

		}

	}

	# Provisioning pool.
	If (($pool.Type -eq 3) -or ($pool.Type -eq 4))
	{

		# vCenter enabled.
		$pool.vCenterEnabled = $false
	
		# Get vCenter ID.
		$vcId = try { [string]$poolObj.get("pae-VCDN") } catch { $null }
	
		# Validate if vCenter object exists in ADAM database.
		If (($vcId -ne $null) -and [ADSI]::Exists("LDAP://$vdmServer/$vcId"))
		{

			# Get vCenter object from ADAM database.
			$vcObj = [ADSI]("LDAP://$vdmServer/$vcId")

			# Verify if vCenter provisioning is enabled.
			$pool.vCenterEnabled = try { ([int]$vcObj.get("pae-Disabled") -eq 0) } catch { $false }
		
		}
	
		$pool.DeliveryModel = "Provisioned"
		$pool.ProvisioningEnabled = try { ([int]$poolObj.get("pae-VmProvEnabled") -eq 1) } catch { $false }
		$pool.MinimumDesktops = try { [int]$poolObj.get("pae-VmMinimumCount") } catch { 0 }
		$pool.MaximumDesktops = try { [int]$poolObj.get("pae-VmMaximumCount") } catch { 0 }
		$pool.SpareDesktops = try { [int]$poolObj.get("pae-VmHeadroomCount") } catch { 0 }
		$pool.ParentVM = try { [string]$poolObj.get("pae-SVIVmParentVM") } catch { $null }
		$pool.SnapshotId = try { [string]$poolObj.get("pae-SVIVmSnapshotMOID") } catch { $null }

	}

	# Manual pool (vCenter)
	ElseIf ($pool.Type -eq 5)
	{

		$pool.DeliveryModel = "Manual"

	}

	# Manual pool.
	ElseIf ($pool.Type -eq 6)
	{

		$pool.DeliveryModel = "Manual"

	}

	# Terminal Services pool
	ElseIf ($pool.Type -eq 8)
	{

		$pool.DeliveryModel = "TerminalService"

	}

	# Return pool object
	Return New-Object -TypeName PSObject -Prop $pool

}

#################################################################
# Get-VDMPoolMember
#################################################################

Function Get-VDMPoolMember
{

	Param(
		[string]$memberId
	)

	# Validate if object exists in ADAM database.
	If ([ADSI]::Exists("LDAP://$vdmServer/cn=$memberId,ou=Servers,$vdmDatabase") -eq $False)
	{
		Return $null
	}

	# Get object from ADAM database.
	$serverObj = [ADSI]("LDAP://$vdmServer/cn=$memberId,ou=Servers,$vdmDatabase")

	# Define server object.
	$server = @{}
	$server.Id = $memberId
	$server.Name = try { [string]$serverObj.get("pae-DisplayName") } catch { $memberId }
	$server.DNSName = try { [string]$serverObj.get("ipHostNumber") } catch { "" }
	$server.Enabled = try { ([int]$serverObj.get("pae-Disabled") -eq 0) } catch { $True }
	$server.State = try { [string]$serverObj.get("pae-VmState") } catch { $null }
	$server.Dirty = try { ([int]$serverObj.get("pae-DirtyForNewSessions") -eq 1) } catch { $False }
	$server.ParentVM = try { [string]$serverObj.get("pae-SVIVmParentVM") } catch { $null }
	$server.SnapshotId = try { [string]$serverObj.get("pae-SVIVmSnapshotMOID") } catch { $null }
	
	# Return server object
	Return New-Object -TypeName PSObject -Prop $server

}

#################################################################
# Get-VDMSessions
#################################################################

Function Get-VDMSessions
{

	Param(
		[string]$poolId,
		[string]$dnsName = ""
	)

	$sessions = @()

	# Get sessions filter based on pool name.
	If ($dnsName -eq "")
	{
		$sessionsObj = Get-RemoteSession -pool_id $poolId -ErrorAction SilentlyContinue
	}

	# Get sessions filter based on DNS name.
	Else
	{
		$sessionsObj = Get-RemoteSession -pool_id $poolId -DNSName $dnsName -ErrorAction SilentlyContinue
	}

	If ($sessionsObj -ne $NullArray)
	{

		# Loop through the sessions.
		ForEach ($sessionObj In $sessionsObj)
		{

			# Define session object.
			$session = @{}
			$session.DNSName = [string]$sessionObj.DNSName
			$session.Id = [int]$sessionObj.session
			$session.State = [string]$sessionObj.state
			$session.Protocol = [string]$sessionObj.protocol

			$sessions += New-Object -TypeName PSObject -Prop $session

		}

	}

	# Return sessions.
	Return $sessions

}

#################################################################
# Set-DirtyVMPolicy
#################################################################
function Set-DirtyVMPolicy()
{

	Param(
		[string]$poolId,
		[int]$policy = 0
	)

	If ([ADSI]::Exists("LDAP://$vdmServer/cn=$poolId,ou=Server Groups,$vdmDatabase") -eq $False)
	{
		Return $false
	}

	$poolObj = [ADSI]("LDAP://$vdmServer/cn=$poolId,ou=Server Groups,$vdmDatabase")
	$poolObj.put("pae-DirtyVmPolicy", $policy )
	$poolObj.setinfo()

	Return $true

}
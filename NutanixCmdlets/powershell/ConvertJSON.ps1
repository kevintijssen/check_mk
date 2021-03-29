# Copyright (c) 2014 Nutanix Inc. All rights reserved.
#
# Author: isha.singhal@nutanix.com
#
# Description: Converts a JSON string to a powershell object.

Param (
# The input JSON string to be converted to a powershell object.
[Parameter(Mandatory = $True)]
[string] $inputJson,

# Parameter to tell if grid view has to be displayed or not. Grid view opens
# a grid view window where the ouput is shown in tabular manner.
[Parameter(Mandatory = $False)]
[int] $gridView = 0,

# Parameter to tell if the output should be displayed in list format.
# List view shows the output in form of a list.
[Parameter(Mandatory = $False)]
[int] $listView = 0
)

function Set-PSObjectDefaultProperties {
    param(
        [PSObject]$Object,
        [string[]]$DefaultProperties
    )
    <#
    .DESCRIPTION

    Sets the default properties for a Powershell object.
    By default, only the default properties are displayed.

    .PARAMETER Object

    The Powershell object for which default properties are to be set.

    .PARAMETER DefaultProperties

    The array of names of the properties which are to be set as default
    properties for the powershell object.
    #>

    $name = $Object.PSObject.TypeNames[0]
    $xml = "<?xml version='1.0' encoding='utf-8' ?><Types><Type>"
    $xml += "<Name>$($name)</Name>"
    $xml += "<Members><MemberSet><Name>PSStandardMembers</Name><Members>"
    $xml += "<PropertySet><Name>DefaultDisplayPropertySet</Name>"
    $xml += "<ReferencedProperties>"

    foreach ($default in $DefaultProperties )
    {
        $xml += "<Name>$($default)</Name>"
    }

    $xml += "</ReferencedProperties></PropertySet></Members></MemberSet>"
    $xml += "</Members></Type></Types>"
    $xml += ""
    $file = "$($env:Temp)\$name.ps1xml"

    Out-File -FilePath $file -Encoding "UTF8" -InputObject $xml -Force
    $typeLoaded = $host.Runspace.RunspaceConfiguration.Types `
        | where { $_.FileName -eq  $file }

    if( $typeLoaded -ne $null )
    {
        Update-TypeData
    }

    else
    {
        Update-TypeData $file
    }
}

$defaultPropSize = 'Global Scope'
function Iterate-Tree($jsonTree)
{
    <#
    .DESCRIPTION

    Takes a deserialized dictionary and converts it to powershell object.

    .PARAMETER jsonTree

    The deserialized dictionary object to be converted to powershell object.

    .RETURN TYPE

    Returns the powershell object.
    #>

    $defaultProperties = @()
    $nodeObject = New-Object PSObject
    foreach ($property in $jsonTree.Keys)
    {
        if ($jsonTree[$property] -ne $null)
        {

            # If a field is a dictionary, we will need to iterate it
            if ($jsonTree[$property] -is `
                [System.Collections.Generic.Dictionary[String, Object]])
            {
                if ($jsonTree[$property].Keys.Count -ne 0)
                {
                    $innerProp = Iterate-Tree $jsonTree[$property]

                    # Add the nested dictionary to the powershell object.
                    $nodeObject | Add-Member -MemberType NoteProperty -Name `
                        $property -Value $innerProp
                }

                else
                {
                    $nodeObject | Add-Member -MemberType NoteProperty -Name `
                        $property -Value $null
                }
            }

            # If a field is an array we need to iterate it seperately and
            # convert it to powershell array. Powershell array looks like "@()".
            elseif ($jsonTree[$property] -is [Object[]])
            {
                $inner = Iterate-Object($jsonTree[$property])
                $nodeObject | Add-Member -MemberType NoteProperty -Name `
                    $property -Value $inner

                # If the value inside the array is not a dictionary or another
                # array, then add it to defaultProperties list.
                if ($inner -is [Object[]] -and -not($inner[0] -is `
                    [System.Collections.Generic.Dictionary[String, Object]] -or`
                    $inner[0] -is [Object[]] -or `
                    $inner[0].getType().Name -eq "PSCustomObject"))
                {
                    $defaultProperties += $property
                }

            }

            # If a field is neither array or dictionary, then directly add it
            # to the powershell Object.
            else
            {
                # If the field is neither a nested array or a nested
                # dictionary, then add it to the defaultProperties list.
                $defaultProperties += $property
                $nodeObject | Add-Member -MemberType NoteProperty -Name `
                    $property -Value $jsonTree[$property]

            }
        }

        else
        {
            # If the value is null for a field then add it to default property.
            $defaultProperties += $property
            $nodeObject | Add-Member -MemberType NoteProperty -Name $property `
                -Value $null
        }
    }

    if ($property -ne "entities")
    {
        $Global:defaultPropSize = $defaultproperties.count
        Set-PSObjectDefaultProperties $nodeObject $defaultProperties
    }

    return $nodeObject
}

function Iterate-Object($arr)
{
    <#
    .DESCRIPTION

    Iterate an array object and convert it to powershell array.

    .PARAMETER arr

    The array to be converted to powershell list object.

    .RETURN TYPE

    Returns the powershell list.
    #>

    # A powershell array looks like "@()".
    $result = @()

    # Go through each value in the array
    foreach ($value in $arr)
    {
        # If a field is a dictionary, we will need to iterate it.
        if ($value -is [System.Collections.Generic.Dictionary[String, Object]])
        {

            # Get the powershell hashtable for the dictionary.
            $innerProp = Iterate-Tree $value
            if($innerProp.Count -ne 0)
            {
                $result += $innerProp
            }
        }

        # If value is an array itself, we need to iterate it and convert it to
        # powershell list.
        elseif ($value -is [Object[]])
        {
            $result += Iterate-Object $value
        }

        else
        {
            $result += $value
        }
    }

    return $result
}

# First deserialize the input Json to a dictionary using JavaScriptSerializer.
Add-Type -AssemblyName System.Web.Extensions
$javaScriptSerializer = New-Object `
    System.Web.Script.Serialization.JavaScriptSerializer


$deserialized = $javaScriptSerializer.DeserializeObject($inputJson)

# Get the deserialized properties into a hashtable.
$psObj = Iterate-Tree $deserialized

# We added entities as a custom parameter in the Json, thus we need to print
# actual Json which is the value of the entities field in deserialized PSObject.
$outEntities = $psObj.entities

if ($gridView -eq 1)
{
    Write-Output $outEntities | Out-GridView
}

if ($listView -eq 1)
{
    Write-Output $outEntities | Format-List -Property *
}
else
{
    Write-Output $outEntities
}

# Find out the number of properties in the powershell custom object and if the
# properties are less than or equal to 4, then show an appropriate message to
# the user to see the full output.
$properties = $outEntities | Get-Member -Member NoteProperty
$propCount = $properties.Length

# Tell user about the "expand" parameter when there are some properties not
# included in the default property set or when the number of properties are
# less than 5. This should not be displayed if user is already using "expand"
# parameter or the output is array or string.
if (($propCount -lt 5 -or `
     $Global:defaultPropSize -ne $propCount) -and `
    (-not ($outEntities -is [Object[]] -or $outEntities -is [String])) -and `
    $listView -eq 0)
{
    $out = "To see the output in form of a list, use -expand parameter."
    Write-Host $out -ForegroundColor yellow
}

Add-PSSnapin VMware.VimAutomation.Core
$Snaps = @{}
$SnapsSorted = @{}
$NagiosStatus = 0
$NagiosOut = ""

connect-viserver -server ldnwvvcent01 -User emea\emea.nagios -Password N1giosadmin! -WarningAction SilentlyContinue > null

$Snaps = get-vm | get-snapshot | where{$_.SizeGB -gt 20} | select VM,name,@{N="Size";E={[decimal]::Round(($_.SizeGB),2)}}

foreach ($VM in $Snaps){
    if (($VM.size) -gt 50){
        $NagiosStatus = 2
        Break
        }
    if ((($VM.size) -gt 20) -and (($VM.size) -lt 51)){
        $NagiosStatus = 1
        }
    }
    
$SnapsSorted = $Snaps | Sort-Object -Property Size -Descending
$NagiosOut = foreach($item in $SnapsSorted){write-output "$($item.vm.name)," "$($item.name)," "$($item.size) -"}

# Output, what level should we tell our caller?
if ($NagiosStatus -eq "2") 
{
	Write-Host "CRITICAL: "$NagiosOut
} 
elseif ($NagiosStatus -eq "1") 
{
	Write-Host "WARNING: "$NagiosOut
} 
else
{
	Write-Host "OK: There are no snapshots over 20GB."
}

exit $NagiosStatus

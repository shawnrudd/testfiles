########################################################################
##
## Cloud Windows Setup
## This is meant to be run on an AMI for CIS instances
## called from userdata with arguments:
##    The name of the domain to set up
##    The first three octets of the class C being built
##    Entry codes for elastic ip entries  
##
## Entry codes are condensed specifications for the entries, the format is
## an IP address followed by the name type (typically x) followed by the 
## name index, all names are cld<name type><name index> as an example
## 3.65.74.81x100 would create an A record in the external DNS for 
## cldx100 at 3.65.74.81 and an A record in the internal DNS for
## ext-cldx100.  This host (cldx100) also has an internal DNS entry for the
## private IP (class C . 201) and an alias (bastion).
##
## This script will run only if the file $PHASE1 exists.  
##
########################################################################
<#
.SYNOPSIS

Performs commands on the windows servers to set nameserver options, name
the server, and 

.EXAMPLE

PS> prep `
      mydomain.com `
      10.90.77 `
      3.23.18.87x1  34.21.66.89x2  19.76.33.42x3  42.46.99.41x4  `
      114.7.88.3x6  5.131.22.11x7  3.11.7.144x11  67.12.23.14x12 `
      77.54.21.6x13 40.30.62.27x14 11.3.144.7x16  21.34.9.247x17 `
      6.12.45.77x99 33.33.33.33x100

#>

########################################################################
## Set up variables
########################################################################
$IP = (Test-Connection -ComputerName $env:ComputerName -Count 1)
$ADDR=$IP.IPV4Address.IPAddressToString
$OCTETS=$ADDR.split('.')
$IP3=$OCTETS[0] + "." + $OCTETS[1] + "." + $OCTETS[2] + "."
$NS1 = $IP3 + "99"
$NS2 = $IP3 + "98"
$XPATH="C:\\NCCCS\\"
$PHASE1=$XPATH+"build"
$OLDPHASE1=$PHASE1+".old"
$ERROUT=$XPATH+"error"
$ADMINROLE=[Security.Principal.WindowsBuiltInRole] "Administrator"
$CURRUSER=[Security.Principal.WindowsIdentity]::GetCurrent()
$CURRROLE=[Security.Principal.WindowsPrincipal]$CURRUSER
$ISADMIN=$CURRROLE.IsInRole($ADMINROLE)

########################################################################
## Validate requirements for running
########################################################################
if (test-path -path $PHASE1) {
  if (-NOT $ISADMIN) {
    Write-Warning "Administrator rights required."
    exit 1
  }
} else {
  Write-Output "Job already run"
  exit 0
}
if ($ARGS.length -lt 1) {
  Write-Warning "No DNS suffix (domain) provided."
  exit 1
}
########################################################################
## Table mapping hostnames by IP Address
########################################################################
$HOSTNAMES = @{
  ($IP3 + "9")="cldi09"
  ($IP3 + "6")="cldi06"
  ($IP3 + "8")="cldi08"
  ($IP3 + "143")="cldx143"
  ($IP3 + "145")="cldx145"
  ($IP3 + "142")="cldx142"
  ($IP3 + "140")="cldx140"
  ($IP3 + "141")="cldx141"
  ($IP3 + "4")="cldi04"
  ($IP3 + "19")="cldi19"
  ($IP3 + "16")="cldi16"
  ($IP3 + "18")="cldi18"
  ($IP3 + "153")="cldx153"
  ($IP3 + "155")="cldx155"
  ($IP3 + "152")="cldx152"
  ($IP3 + "150")="cldx150"
  ($IP3 + "151")="cldx151"
  ($IP3 + "14")="cldi14"
  ($IP3 + "154")="cldx154"
  ($IP3 + "11")="cldi11"
  ($IP3 + "99")="cldi99"
  ($IP3 + "98")="cldi98"
  ($IP3 + "200")="cldx200"
  ($IP3 + "7")="cldi07"
  ($IP3 + "201")="cldx201"
  ($IP3 + "15")="cldi15"
  ($IP3 + "5")="cldi05"
}

$DOM, $EXCESS = $ARGS
$CLOUD = ("cloud." + $DOM)
$HOSTNAME = $HOSTNAMES.$ADDR
Set-TimeZone -Name "Eastern Standard Time"
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses ( $NS1 )
Set-DnsClientGlobalSetting -SuffixSearchList @($CLOUD, $DOM, "us-east-1.ec2-utilities.amazonaws.com", "ec2.internal")
########################################################################
## Completed, remove $PHASE1 (rename reboots so no chance afterwards)
########################################################################
if (test-path -path $PHASE1) {
  Rename-Item -Path $PHASE1 -NewName $OLDPHASE1
}
Rename-Computer -NewName $HOSTNAME -Restart
########################################################################
## If we got here, rename failed.  Put the build file back
########################################################################
Echo $error[0] > $ERROUT
Rename-Item -Path $OLDPHASE1 -NewName $PHASE1
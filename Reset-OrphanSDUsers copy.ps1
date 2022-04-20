<#	
	.NOTES
	===========================================================================
	 Created with: 	VS Code
	 Created on:   	Monday, April 18, 2022 2:10:41 PM
	 Created by:   	dusjones
	 Organization: 	
	 Filename:
   Version: 1.0     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
 
# $Script_Ver = "1.00"
$ScriptInvocation = (Get-Variable MyInvocation -Scope Script).Value
# $ScriptPath = $ScriptInvocation.MyCommand.Path
# $ScriptDirectory = Split-Path $ScriptPath
$ScriptName = $ScriptInvocation.MyCommand.Name
$Src_Server = $env:computername
$ScriptStart = (Get-Date)
# $dt = $(get-date $ScriptStart -format yyyy-MM-dd)
$Admin = [Environment]::UserName
$DomainFQDN = (Get-WmiObject Win32_ComputerSystem).Domain
#$Forest = (Get-ADForest)
$Domain = (Get-ADDomain $DomainFQDN)

# EMAIL SETTINGS UNCOMMENT AND FILL OUT
#$SMTPServer = ""
#$SMTPFrom = ""
#$SMTPTo = ""


#Check to Ensure Active Directory PowerShell Module is available within the system
Function Get-MyModule
{
Param([string]$name)
if(-not(Get-Module -name $name))
  {
    if(Get-Module -ListAvailable |Where-Object { $_.name -eq $name })
    {
      Import-Module -Name $name
      $True | Out-Null
    }
    else
    {
      Write-Host ActiveDirectory PowerShell Module Not Available -ForegroundColor Red
    }
  } # end if not module
  else
  {
    $True | Out-Null
  }   #module already loaded
} #end function get-MyModule
 
Get-MyModule -name "ActiveDirectory"
 
Function Set-Inheritance
{
Param($ObjectPath)  
$Acl = Get-ACL -path "AD:\$ObjectPath"
  If ($Acl.AreAccessRulesProtected -eq $True)
  {
    $Acl.SetAccessRuleProtection($False, $True)
    Set-ACL -AclObject $ACL -path "AD:\$ObjectPath"
  }
}
 


#Get List of Protected Groups)
$ProtectedGroups = Get-ADGroup -LDAPFilter "(adminCount=1)"
 
#Get List of Admin Users (Past and Present)
$ProtectedUsers = (Get-ADUser -LDAPFilter "(adminCount=1)").samaccountname
 
$CurrentAdmins = ForEach ($ProtectedGroup in $ProtectedGroups) {(Get-ADGroupMember $ProtectedGroup | Where-Object {$_.ObjectClass -eq "User"}).samaccountname}
 
#Create Empty Hash
$PGUSers = @{}
$OrphanUsers = @{}
 
#Compare $ProtectedUsers to $CurrentAdmins and place in appropriate hash table
ForEach ($ProtectedUser in $ProtectedUsers)
{
If ($CurrentAdmins -contains $ProtectedUser)
  {
    $PGUsers.Add($ProtectedUser, "Present")
  }
  Else
  {
    $OrphanUsers.Add($ProtectedUser, "NotPresent")
  }
}

 
If ($OrphanUsers.Keys.Count.Equals(0))
{
  $True | Out-Null
}
Else
{
  #Clear AdminCount Attribute and set inheritance
  ForEach ($Orphan in $OrphanUsers.Keys)
  {
    if ($orphan -ne "krbtgt"){
    $Orphan
    $ADUser = Get-ADUser $Orphan
    Set-ADUser $Orphan -Clear {AdminCount}
    Set-Inheritance $ADUser
    }
  }
}



# Get End Time
$ScriptEnd = (Get-Date)

$RunTime = New-Timespan -Start $ScriptStart -End $ScriptEnd
# Build Execution Summary
$Message = "     `r`n"
$Message += "Script Execution Summary:`r`n"
$Message += "     Script Started:  $ScriptStart `r`n"
$Message += "     Script Ended:  $ScriptEnd `r`n"
$Message += "     Elapsed Time: {0}:{1}:{2}:{3} `r`n" -f $RunTime.Days, $RunTime.Hours, $Runtime.Minutes, $RunTime.Seconds
$Message += "     `r`n"
$Message += "     Command Used:  $($myInvocation.Line) `r`n"
$Message += "     Script Name: $($ScriptName) `r`n"
$Message += "     Executed on Domain: $($Domain) `r`n"
$Message += "     Executed on Server: $($Src_Server) `r`n"
$Message += "     Executed By: $($Admin) `r`n"

$Message
Write-Verbose "Script Complete!"
############################################################
# Configures a SharePoint 2013 Farm                        #
# Samuel Zuercher, Experts Inside GmbH                     #
# @sharepointszu, szu@expertsinside.com                    #
#                                                          #
# Special Thanks to: Jason Warren, Zach and @sharepointeng #
# for basic scripts I started with                         #
#                                                          #
# Last modified 27.02.2013                                 #
#                                                          #
############################################################
 
 
 
############################################################
#                                                          #
# Farm Setup Section                                       #
# Definition of variables and basic prep                   #
#                                                          #
############################################################
 
# Domain
$DOMAIN = "DEMO"
 
# Application Pool for Services
$SaAppPoolName = "SharePoint Web Services Default"
 
# Basic Accountcredentials
$accounts = @{}
$accounts.Add("SPFarm", @{"username" = "sp-farm"; "password" = "Test12345"})
$accounts.Add("SPWebApp", @{"username" = "sp-portal"; "password" = "Test12345"})
$accounts.Add("SPSvcApp", @{"username" = "sp-services"; "password" = "Test12345"})
 
# SQL Alias
$SQLAliasName = "SharePointDB_Prod" #NoSpaces, make sure you know the name is selfexplaining, as it will stay as long the farm lives. No Years or Versions!!
$SQLServerName = "SQL\SHAREPOINT"   #Include Instance Name
$x86 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
$x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
 
# Security Passphrase for SharePoint Setup
$ConfigPassphrase = "MySharePointIs2013"
 
# Giving the Names for Databases
$dbConfig = "TBD_DEMO_SharePoint_Config"
$dbCentralAdmin = "TBD_DEMO_SharePoint_CentralAdmin"
 
# Central Admin Port and Authentication Method
$CaPort = 11111
$CaAuthProvider = "NTLM"
 
# If you do not want to create a particular SA, set the Create...SA Flag to 0
# Usage and Health Data Collection Service Application
$CreateUsageAndHealth = 1
$UsageSAName = "Usage and Health Data Collection”
$dbUsageService = "TBD_DEMO_Usage_and_Health_Data"
$UsageLogLocation = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\LOGS”
$MaxUsageLogSpace = 5     #in GB
 
# State Service Application
$CreateStateSA = 1
$StateSAName = "State Service”
$dbStateService = "TBD_DEMO_State”
 
# Managed Metadata Service Application
$CreateManagedMetadataSA = 1
$ManagedMetadataSAName = "Managed Metadata Service”
$dbManagedMetadata = "TBD_DEMO_Managed_Metadata"
 
# Search Service Application and Topology
$CreateSearchService = 1
$SearchMachines = @("SP2013-V2")
$SearchQueryMachines = @("SP2013-V2")
$SearchCrawlerMachines = @("SP2013-V2")
$SearchAdminComponentMachine = "SP2013-V2"
$SearchSAName = "Search Service”
$dbSearchDatabase = "TBD_DEMO_Search”
$IndexLocation = "C:\SPIndex”
 
# Word Conversion Service Application
$CreateWordAutomation = 1
$WordSAName = "Word Automation Service"
$dbWordAutomation = "TBD_DEMO_WordAutomation"
 
# BCS Service Application
$CreateBcsSA = 1
$BcsSAName = "Business Connectivity Service"
$dbBcs = "TBD_DEMO_BusinessConnectivity"
 
# Secure store Service Application
$CreateSecureStore = 1
$SecureStoreSAName = "Secure Store Service"
$dbSecureStore = "TBD_DEMO_Secure_Store"
 
# Performance Point Service Application
$CreatePerformancePoint = 1
$PerformancePointSAName = "Performance Point Services"
$dbPerformancePoint = "TBD_DEMO_PerformancePoint"
 
# Visio Service Application
$CreateVisioService = 1
$VisioSAName = "Visio Services"
 
# User Profile Service Application
$CreateUserProfile = 1
$UserProfileSAName = "User Profile Service"
$dbUserProfile = "TBD_DEMO_UserProfile_Profiles"
$dbUserSocial ="TBD_DEMO_UserProfile_Social"
$dbUserSync ="TBD_DEMO_UserProfile_Sync"
 
# Subscription Settings Service Application
$CreateSubscription = 1
$SubscriptionSAName = “Subscription Settings Service”
$dbSubscription = "TBD_DEMO_Subscription_Settings"
 
# App management Service Application
$CreateAppMgmt = 1
$AppManagementSAName = "App Management Service"
$dbAppManagement = "TBD_DEMO_App_Management"
 
# Machine Translation Service Application
$CreateTranslationSA = 1
$TranslationSAName = “Machine Translation Service”
$dbTranslation = “TBD_DEMO_Machine_Translation”
 
# Work Management Service Application
$CreateWorkMgmtSA = 1
$WorkMgmtSAName = "Work Management Service"
 
 
############################################################
#                                                          #
# Prepare the Machine before configuring SharePoint        #
#                                                          #
############################################################
 
# Create the basic Accounts for Setup 
Foreach ($account in $accounts.keys) {
    $accounts.$account.Add(`
    "credential", `
    (New-Object System.Management.Automation.PSCredential ($DOMAIN + "\" + $accounts.$account.username), `
    (ConvertTo-SecureString -String $accounts.$account.password -AsPlainText -Force)))
}
   
# Check if Registry Key Paths for SQL-Alias already exist, create them if not
if ((test-path -path $x86) -ne $True)
{
    write-host "$x86 doesn't exist"
    New-Item $x86
}
if ((test-path -path $x64) -ne $True)
{
    write-host "$x64 doesn't exist"
    New-Item $x64
}
   
# Creating String to add TCP/IP Alias
$TCPAlias = ("DBMSSOCN," + $SQLServerName)
   
#Creating our TCP/IP Aliases
New-ItemProperty -Path $x86 -Name $SQLAliasName -PropertyType String -Value $TCPAlias
New-ItemProperty -Path $x64 -Name $SQLAliasName -PropertyType String -Value $TCPAlias
  
# Open cliconfig to verify the aliases
Start-Process C:\Windows\System32\cliconfg.exe
Start-Process C:\Windows\SysWOW64\cliconfg.exe
 
# Farm Passphrase
$s_configPassphrase = (ConvertTo-SecureString -String $ConfigPassphrase -AsPlainText -force)
 
  
 
############################################################
#                                                          #
# SharePoint 2013 Product Configuration Wizzard Steps      #
# No need to run the Wizzard within the GUI!!              #
#                                                          #
############################################################
 
# Make SharePoint PowerShell Availlable
Add-PSSnapin Microsoft.SharePoint.PowerShell
 
# Creating SharePoint Configuration Database
Write-Output "Creating the configuration database $dbConfig"
New-SPConfigurationDatabase -DatabaseName $dbConfig -DatabaseServer $SQLAliasName -AdministrationContentDatabaseName $dbCentralAdmin -Passphrase  $s_configPassphrase -FarmCredentials $accounts.SPFarm.credential
  
# Check to make sure the farm exists and is running. if not, end the script
$Farm = Get-SPFarm
if (!$Farm -or $Farm.Status -ne "Online") {
    Write-Output "Farm was not created or is not running"
    exit
}
  
Write-Output "Create the Central Administration site on port $CaPort"
New-SPCentralAdministration -Port $CaPort -WindowsAuthProvider $CaAuthProvider
  
# Perform the config wizard tasks
  
Write-Output "Install Help Collections"
Install-SPHelpCollection -All
  
Write-Output "Initialize security"
Initialize-SPResourceSecurity
  
Write-Output "Install services"
Install-SPService
  
Write-Output "Register features"
Install-SPFeature -AllExistingFeatures
  
Write-Output "Install Application Content"
Install-SPApplicationContent
  
  
# Add managed accounts
Write-Output "Creating managed accounts ..."
New-SPManagedAccount -credential $accounts.SPWebApp.credential
New-SPManagedAccount -credential $accounts.SPSvcApp.credential
  
#Start Central Administration
Write-Output "Starting Central Administration"
& 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\BIN\psconfigui.exe' -cmd showcentraladmin
  
Write-Output "Farm build complete."
 
 
 
############################################################
#                                                          #
# Functions to create Service Applications                 #
#                                                          #
############################################################
 
# Usage and Health Data Collection
function UsageAndHealthSA {
    Write-Host "Creating Usage and Health Data Collection..."
    Set-SPUsageService -LoggingEnabled 1 -UsageLogLocation $UsageLogLocation -UsageLogMaxSpaceGB $MaxUsageLogSpace
    $UsageService = Get-SPUsageService
    New-SPUsageApplication -Name $UsageSAName -DatabaseServer $SQLAliasName -DatabaseName $dbUsageService -UsageService $UsageService > $null
    }
 
# State Service
function StateServiceSA {
    Write-Host "Creating State Service..."
    New-SPStateServiceDatabase -Name $dbStateService
    $StateSAPipe = New-SPStateServiceApplication -Name $StateSAName -Database $dbStateService
    New-SPStateServiceApplicationProxy -Name "$StateSAName Proxy” -ServiceApplication $StateSAPipe -DefaultProxyGroup
    }
 
# Managed Metadata Service Application
function ManagedMetadataSA {
    Write-Host "Creating Managed Metadata Service..."
    New-SPMetadataServiceApplication -Name $ManagedMetadataSAName –ApplicationPool $SaAppPoolName -DatabaseServer $SQLAliasName -DatabaseName $dbManagedMetadata > $null
    New-SPMetadataServiceApplicationProxy -Name "$ManagedMetadataSAName Proxy” -ServiceApplication $ManagedMetadataSAName -DefaultProxyGroup > $null
    Get-SPServiceInstance | where-object {$_.TypeName -eq $ManagedMetadataSAName} | Start-SPServiceInstance > $null
}
 
# Enterprise Search SA and Topology
function EnterpriseSearchSA {
    Write-Host "Creating Search Service Application…”
    Write-Host "Starting Services…”
    foreach ($Machine in $SearchMachines) {
        Write-Host ” Starting Search Services on $Machine”
        Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $Machine -ErrorAction SilentlyContinue
        Start-SPEnterpriseSearchServiceInstance $Machine -ErrorAction SilentlyContinue
    }
    Write-Host "Creating Search Service Application…”
    $SearchSA = New-SPEnterpriseSearchServiceApplication -Name $SearchSAName -ApplicationPool $SaAppPoolName -DatabaseServer $SQLAliasName -DatabaseName $dbSearchDatabase
    $SearchInstance = Get-SPEnterpriseSearchServiceInstance -Local
    Write-Host "Defining the Search Topology…”
    $InitialSearchTopology = $SearchSA | Get-SPEnterpriseSearchTopology -Active
    $NewSearchTopology = $SearchSA | New-SPEnterpriseSearchTopology
    Write-Host "Creating Admin Component…”
    New-SPEnterpriseSearchAdminComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance
    Write-Host "Creating Analytics Component…”
    New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance
    Write-Host "Creating Content Processing Component…”
    New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance
    Write-Host "Creating Query Processing Component…”
    New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance
    Write-Host "Creating Crawl Component…”
    New-SPEnterpriseSearchCrawlComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance
    Write-Host "Creating Index Component…”
    if (!(Test-Path -path $Indexlocation)) {New-Item $Indexlocation -Type Directory}
    New-SPEnterpriseSearchIndexComponent -SearchTopology $NewSearchTopology -SearchServiceInstance $SearchInstance -RootDirectory $IndexLocation
    Write-Host "Activating the new topology…”
    $NewSearchTopology.Activate()
    Write-Host "Creating Search Application Proxy…”
    $SearchProxy = Get-SPEnterpriseSearchServiceApplicationProxy -Identity "$SearchSAName Proxy” -ErrorAction SilentlyContinue
    if (!$searchProxy) {
        New-SPEnterpriseSearchServiceApplicationProxy -Name "$SearchSAName Proxy” -SearchApplication $SearchSA
    }
}
 
function WordAutomationSA {
    Write-Host "Creating Word Automation Service..."
    New-SPWordConversionServiceApplication -Name $WordSAName -ApplicationPool $SaAppPoolName -DatabaseName $dbWordAutomation -DatabaseServer $SQLAliasName -Default
}
 
function BcsSA {
    Write-Host "Creating Business Connectivity Service..."
    $BcsSAPipe = New-SPBusinessDataCatalogServiceApplication –ApplicationPool $SaAppPoolName –DatabaseName $dbBcs –DatabaseServer $SQLAliasName –Name $BcsSAName
    #New-SPBusinessDataCatalogServiceApplicationProxy -Name “$BcsSAName Proxy“ -ServiceApplication $BcsSAPipe -DefaultProxyGroup
}
 
function SecureStoreSA {
    Write-Host "Creating Secure Store Service..."
    $SecureStoreSAPipe = New-SPSecureStoreServiceApplication –ApplicationPool $SaAppPoolName –AuditingEnabled:$false –DatabaseServer $SQLAliasName –DatabaseName $dbSecureStore –Name $SecureStoreSAName
    New-SPSecureStoreServiceApplicationProxy –Name “$SecureStoreSAName Proxy ” –ServiceApplication $SecureStoreSAPipe -DefaultProxyGroup
}
 
function PerformancePointSA {
    Write-Host "Creating PerformancePoint Service..."
    $PerformancePointSAPipe = New-SPPerformancePointServiceApplication -Name $PerformancePointSAName -ApplicationPool $SaAppPoolName -DatabaseName $dbPerformancePoint
    New-SPPerformancePointServiceApplicationProxy -Name "$PerformancePointSAName Proxy" -ServiceApplication $PerformancePointSAPipe -Default
}
 
function VisioSA {
#    Write-Host "Creating Visio Service..."
#    $VisioSAPipe = New-SPVisioServiceApplication -Identity "Visio Services" -ServiceApplicationPool $SaAppPoolName
#    New-SPVisioServiceApplicationProxy -Name "$VisioSAName Proxy" -ServiceApplication $VisioSAPipe
}
 
function UserProfileSA {
    Write-Host "Creating User Profile Service..."
    $UserProfileSAPipe = New-SPProfileServiceApplication -Name $UserProfileSAName -ApplicationPool $SaAppPoolName -ProfileDBServer $SQLAliasName -ProfileDBName $dbUserProfile -SocialDBServer $SQLAliasName -SocialDBName $dbUserSocial -ProfileSyncDBServer $SQLAliasName -ProfileSyncDBName $dbUserSync
    New-SPProfileServiceApplicationProxy -Name “$UserProfileSAName Proxy” -ServiceApplication $UserProfileSAPipe -DefaultProxyGroup > $null
    Get-SPServiceInstance | where-object {$_.TypeName -eq $UserProfileSAName} | Start-SPServiceInstance > $null
}
 
function SubscriptionSA {
    Write-Host “Creating Subscription Settings Service…”
    $SubscriptionSAPipe = New-SPSubscriptionSettingsServiceApplication –ApplicationPool $SaAppPoolName –Name $SubscriptionSAName –DatabaseName $dbSubscription
    New-SPSubscriptionSettingsServiceApplicationProxy –ServiceApplication $SubscriptionSAPipe
    Get-SPServiceInstance | where-object {$_.TypeName -eq $SubscriptionSAName} | Start-SPServiceInstance > $null
}
 
function AppManagementSA {
    Write-Host “Creating App Management Service…”
    $AppManagementSAPipe = New-SPAppManagementServiceApplication -Name $AppManagementSAName -DatabaseServer $SQLAliasName -DatabaseName $dbAppManagement –ApplicationPool $SaAppPoolName
    New-SPAppManagementServiceApplicationProxy -Name “$AppManagementSAName Proxy” -ServiceApplication $AppManagementSAPipe
    Get-SPServiceInstance | where-object {$_.TypeName -eq $AppManagementSAName} | Start-SPServiceInstance > $null
}
 
function MachineTranslationSA {
    Write-Host "Creating Machine Translation Service..."
    Get-SPServiceInstance | ? {$_.GetType().Name -eq $TranslationSAName} | Start-SPServiceInstance
    $MachineTranlsationSAPipe = New-SPTranslationServiceApplication -Name $TranslationSAName -ApplicationPool $SaAppPoolName -DatabaseName $dbTranslation
    #New-SPTranslationServiceApplicationProxy –Name “$TranslationSAName Proxy” –ServiceApplication $MachineTranlsationSAPipe –DefaultProxyGroup
}
 
function WorkManagementSA {
    Write-Host "Creating Work Management Service..."
    $WorkManagementSAPipe = New-SPWorkManagementServiceApplication –Name $WorkMgmtSAName –ApplicationPool $SaAppPoolName
    New-SPWorkManagementServiceApplicationProxy -name “$WorkMgmtSAName Proxy” -ServiceApplication $WorkManagementSAPipe
}
 
 
 
############################################################
#                                                          #
# Do SharePoint Farm Configuration                         #
# No need to run the Wizzard within the GUI!!              #
#                                                          #
############################################################
 
# Make sure, Admin wants to go on Configuring the Farm with this Script
$DoConfig = Read-Host "Do you want to go on Configuring your Farm? (Y/N) Standard is Y"
if ($DoConfig -eq "N")
{
    exit
}
 
# Creating App Pool for Service Applications
New-SPServiceApplicationPool -Name $SaAppPoolName -Account (Get-SPManagedAccount -Identity "demo\sp-services")
 
# Calling Functions to create
# Create Usage and Health Data Collection Service Applications
if ($CreateUsageAndHealth -eq 1) {
    UsageAndHealthSA
}
 
# Create State Service Application
if ($CreateUsageAndHealth -eq 1) {
    StateServiceSA
}
 
# Create Manage Metadata Service Application
if ($CreateManagedMetadataSA -eq 1) {
    ManagedMetadataSA
}
 
# Create Enterprise Search Service Application
if ($CreateSearchService -eq 1) {
    EnterpriseSearchSA
}
 
# Create Word Automation Service Application
if ($CreateWordAutomation -eq 1) {
    WordAutomationSA
}
 
# Create BCS Service Application
if ($CreateBcsSA -eq 1) {
    BcsSA
}
 
# Create Secure Store Service Application
if ($CreateSecureStore -eq 1) {
    SecureStoreSA
}
 
# Create Performance Point Service Application
if ($CreatePerformancePoint -eq 1) {
    PerformancePointSA
}
 
# Create Visio Service Application
if ($CreateVisioService -eq 1) {
    VisioSA
}
 
# User Profile Service Application
if ($CreateUserProfile -eq 1) {
    UserProfileSA
}
 
# Subscription Settings Service Application
if ($CreateSubscription -eq 1) {
    SubscriptionSA
}
 
# App Management Service Application
if ($CreateAppMgmt -eq 1) {
    AppManagementSA
}
 
# Machine Translation Service Application
if ($CreateTranslationSA -eq 1) {
    MachineTranslationSA
}
 
# Work Management Service Application
if ($CreateWorkMgmtSA -eq 1) {
    WorkManagementSA
}
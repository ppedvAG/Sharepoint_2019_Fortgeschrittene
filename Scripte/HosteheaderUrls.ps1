# Load SharePoint powershell commands  
Add-PSSnapin "microsoft.sharepoint.powershell" -ErrorAction SilentlyContinue  
  
cls 
New-SPWebApplication -ApplicationPool "SharePoint Web Apps" -Name "Standard" –HostHeader Standard -ApplicationPoolAccount "spoint\svcZa" -DataBaseName "WSS_Content_Standard" -DatabaseServer "SP2013"  -Path "C:\inetpub\wwwroot\wss\VirtualDirectories\Standard" -Port 80 -URL "http://Standard:80" 

Write-Host
New-SPWebApplication -ApplicationPool "SharePoint Web Apps" -Name "Sensitive"  –HostHeader Sensitive -DataBaseName "WSS_Content_Sensitive" -DatabaseServer "SP2013" -Path "C:\inetpub\wwwroot\wss\VirtualDirectories\Sensitive" -Port 80 -URL "http://Sensitive:80"

# Add HNSC bindings on web applications
# Run this once on each WFE server
# Requires IIS Administration module
Import-Module WebAdministration
# Add new bindings for HNSC

New-WebBinding -Name "Standard" -HostHeader "intranet.spoint.local"
New-WebBinding -Name "Standard" -HostHeader "communities.spoint.local"
New-WebBinding -Name "Sensitive" -HostHeader "teams.spoint.local"
New-WebBinding -Name "Sensitive" -HostHeader "projects.spoint.local"

# Create Host-Named Site Collections (HNSC)
# Run this once per farm
# Add managed paths (for all HNSC in farm)

New-SPManagedPath "it" -Explicit -HostHeader -ErrorAction Continue

New-SPManagedPath "sec" -Explicit -HostHeader -ErrorAction Continue

# Create HNSC on Standard

New-SPSite http://intranet.spoint.local -HostHeaderWebApplication http://Standard -Name "The Intranet" -Template "BLANKINTERNETCONTAINER#0" -OwnerAlias spoint\Administrator

New-SPSite http://communities.spoint.local -HostHeaderWebApplication http://Standard -Name "Community Sites" -Template "STS#0" -OwnerAlias Spoint\Administrator

# Create HNSC on Sensitive, with sites on managed paths

New-SPSite http://teams.spoint.local -HostHeaderWebApplication http://Sensitive -Name "Team sites" -Template "STS#1" -OwnerAlias Spoint\Administrator

New-SPSite http://teams.spoint.local/it -HostHeaderWebApplication http://Sensitive -Name "IT - Information Technology" -Template "BLOG#0" -OwnerAlias Spoint\Administrator

New-SPSite http://teams.spoint.local/sec -HostHeaderWebApplication http://Sensitive -Name "HR – Human Resources" -Template "BLOG#0" -OwnerAlias Spoint\Administrator

New-SPSite http://projects.spoint.local -HostHeaderWebApplication http://Sensitive -Name " Project sites" -Template "SGS#0" -OwnerAlias spoint\Administrator

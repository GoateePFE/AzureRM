break

# Shout out to @brwilkinson for assistance with some of this.


# Install the Azure Resource Manager modules from PowerShell Gallery
# Takes a while to install 28 modules
# Install-Module Az -Force -Verbose

# # Install the Azure Service Management module from PowerShell Gallery
# Install-Module Azure -Force -Verbose

# # Import Az modules for the given version manifest in the Az module
# Import-Module Az -Verbose

# # Import Azure Service Management module
# Import-Module Azure -Verbose

# Authenticate to your Azure account
Login-AzAccount

# Adjust the 'yournamehere' part of these three strings to
# something unique for you. Leave the last two characters in each.
$URI       = 'https://raw.githubusercontent.com/cloudwidth/ADDS-with-Data/master/active-directory-new-domain-with-data/azuredeploy.json'
$Location  = 'South Central US'
$rgname    = 'RG-ActiveDirectory'
$namePrefix = 'Cloudwidth'                     # cannot start with numbers
$addnsName = ($namePrefix).ToLower()            # Lowercase required


# Check that the public dns $addnsName is available
if (Test-AzDnsAvailability -DomainNameLabel $addnsName -Location $Location)
{ 'Available' } else { 'Taken. addnsName must be globally unique.' }


# Create the new resource group. Runs quickly.
New-AzResourceGroup -Name $rgname -Location $Location

# Parameters for the template and configuration
$MyParams = @{
    location              = $Location
    domainName            = ($namePrefix + ".com")       # The maximum length is 15 characters
    addnsName             = $addnsName
    namePrefix            = $namePrefix
   }

# Splat the parameters on New-AzResourceGroupDeployment  
$SplatParams = @{
    TemplateUri             = $URI 
    ResourceGroupName       = $rgname 
    TemplateParameterObject = $MyParams
    Name                    = ($namePrefix + 'Forest')
   }

# This takes ~30 minutes
# One prompt for the domain admin password
New-AzResourceGroupDeployment @SplatParams -Verbose

# Find the VM IP and FQDN
$PublicAddress = (Get-AzPublicIpAddress -ResourceGroupName $rgname)[0]
$IP   = $PublicAddress.IpAddress
$FQDN = $PublicAddress.DnsSettings.Fqdn

# RDP either way
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$FQDN"
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$IP"

# Login as:  alpineskihouse\adadministrator
# Use the password you supplied at the beginning of the build.

# Explore the Active Directory domain:
#  Recycle bin enabled
#  Admin tools installed
#  Five new OU structures
#  Users and populated groups within the OU structures
#  Users root container has test users and populated test groups

# Delete the entire resource group when finished
Remove-AzResourceGroup -Name $rgname -Force -Verbose

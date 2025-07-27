# PowerShell script to read registry_override.conf and apply settings to Windows registry

# Define the path to the configuration file
$configFile = "\\tsclient\home\.local\share\linoffice\registry_override.conf"

# Check if the file exists
if (-not (Test-Path $configFile)) {
    Write-Host "registry override file not found, settings not applied"
    exit
}

# Read the file content, handling Linux-style line endings (UTF-8 encoding assumed)
$content = Get-Content -Path $configFile -Encoding UTF8

# Initialize variables for settings
$dateFormat = ""
$decimalSeparator = ""
$currencySymbol = ""

# Parse the file content
foreach ($line in $content) {
    if ($line -match '^DATE_FORMAT="([^"]*)"$') {
        $dateFormat = $matches[1]
    }
    elseif ($line -match '^DECIMAL_SEPARATOR="([^"]*)"$') {
        $decimalSeparator = $matches[1]
    }
    elseif ($line -match '^CURRENCY_SYMBOL="([^"]*)"$') {
        $currencySymbol = $matches[1]
    }
}

# Define valid date formats
$validDateFormats = @(
    "yyyy/mm/dd", "yyyy.mm.dd", "yyyy-mm-dd",
    "dd/mm/yyyy", "dd.mm.yyyy", "dd-mm-yyyy",
    "mm/dd/yyyy"
)

# Registry path
$regPath = "HKCU:\Control Panel\International"

# Function to set registry value
function Set-RegistryValue {
    param($Name, $Value)
    Set-ItemProperty -Path $regPath -Name $Name -Value $Value
}

# Process DATE_FORMAT
if ($dateFormat -and $dateFormat -in $validDateFormats) {
    # Extract separator
    if ($dateFormat -match "([./-])") {
        $separator = $matches[1]
        Set-RegistryValue -Name "sDate" -Value $separator
    }
    # Set short date format (capitalizing month as MM)
    $sShortDate = $dateFormat -replace "mm", "MM"
    Set-RegistryValue -Name "sShortDate" -Value $sShortDate
}

# Process DECIMAL_SEPARATOR
if ($decimalSeparator -eq "." -or $decimalSeparator -eq ",") {
    $oppositeSeparator = if ($decimalSeparator -eq ".") { "," } else { "." }
    Set-RegistryValue -Name "sDecimal" -Value $decimalSeparator
    Set-RegistryValue -Name "sMonDecimalSep" -Value $decimalSeparator
    Set-RegistryValue -Name "sThousand" -Value $oppositeSeparator
    Set-RegistryValue -Name "sMonThousandSep" -Value $oppositeSeparator
}

# Process CURRENCY_SYMBOL
if ($currencySymbol -and $currencySymbol -ne "(not changed)") {
    Set-RegistryValue -Name "sCurrency" -Value $currencySymbol
}
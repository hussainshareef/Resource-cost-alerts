# Authenticate using Service Principal
$tenantId = $env:AZURE_TENANT_ID
$appId = $env:AZURE_CLIENT_ID
$appSecret = $env:AZURE_CLIENT_SECRET
$subscriptionId = $env:AZURE_SUBSCRIPTION_ID

az login --service-principal `
  --username $appId `
  --password $appSecret `
  --tenant $tenantId | Out-Null

az account set --subscription $subscriptionId

# Calculate dates
$startDate = (Get-Date).AddDays(-15).ToString("yyyy-MM-dd")
$endDate = (Get-Date).ToString("yyyy-MM-dd")

# Get cost data
$costData = az consumption usage list `
  --start-date $startDate `
  --end-date $endDate `
  --output json | ConvertFrom-Json

# Save to file
$reportPath = "cost-report.json"
$costData | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $reportPath

# Send Email
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$emailFrom = $env:EMAIL_USER
$emailTo = $env:EMAIL_TO
$password = $env:EMAIL_PASS

$message = New-Object system.net.mail.mailmessage
$message.from = $emailFrom
$message.To.Add($emailTo)
$message.Subject = "Azure Cost Report"
$message.Body = "Find attached your Azure cost usage report for the last 15 days."
$message.Attachments.Add($reportPath)

$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($emailFrom, $password)
$smtp.Send($message)

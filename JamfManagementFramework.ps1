$username="Jamf Admin"
$password="Jamf Admin Password"
$url="Your Jamf URL Domain"

# 将用户名和密码拼接成 "username:password" 格式
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

# 创建 Basic Auth Token
$basicAuthToken = "Basic " + $base64AuthInfo

$Method = "POST"
$jsonData=Invoke-RestMethod -URI "https://Your Jamf URL Domain/api/v1/auth/token"  -Method $Method -Headers @{"accept"="application/json";"Authorization"="$basicAuthToken"}
$tokenValue = $jsonData.token

#Variable declarations
$bearerToken=""
#$tokenExpirationEpoch="0"

Write-Host "[step] Posting a new Mobile Device to $base"
#$DeviceID = "Device ID" #Device ID
$serialnumber=Read-Host "请输入设备序列号："
#$serialnumber="Device Serial Number"
$endpoint1="https://Your Jamf URL Domain/JSSResource/computers/serialnumber/$serialnumber"
$serialnumberJson=(Invoke-RestMethod -URI "${endpoint1}"  -Method GET -Headers @{"accept"="application/json";"Authorization"="Bearer $tokenValue"})
$DeviceID = $serialnumberJson.computer.general.id
$Endpoint = "https://Your Jamf URL Domain/api/v1/jamf-management-framework/redeploy/$DeviceID"
$Method = "POST"
Invoke-RestMethod -URI "${Endpoint}"  -Method $Method -Headers @{"accept"="application/json";"Authorization"="Bearer $tokenValue"}
Write-Host "[status] OK"




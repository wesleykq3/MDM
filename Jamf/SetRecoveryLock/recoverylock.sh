#!/bin/sh
#通过获取设备序列号，再通过设备序列号获取managementId，再通过managementId设置指定的Recovery Lock密码，为空也就是清除密码

#1、登录JAMF在脚本根据实际情况设置如下账户密码
#2、创建动态组，条件是Apple silicon芯片设备，可以再加近来注册的设备的条件
#3、创建Policy关联脚本
#4、JAMF搜索设备找到Security-Recovery Lock查看设置密码

#JAMF API账户
username=""

#JAMF API密码
password=""

#JAMF API URL，最后不需要加“/”
url=""

#Variable declarations
bearerToken=""
tokenExpirationEpoch="0"

getBearerToken() {
    response=$(curl -s -u "$username":"$password" "$url"/api/v1/auth/token -X POST 2>/dev/null)
    bearerToken=$(echo "$response" | plutil -extract token raw -)
    tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
    tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

checkTokenExpiration() {
    nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
    if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
    then
        echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
    else
        echo "No valid token available, getting new token"
        getBearerToken
    fi
}
checkTokenExpiration
#echo $bearerToken
 #设备注册获取设备序列号
serialNumber=$(echo $(system_profiler SPHardwareDataType|grep -w "Serial Number"|sed 's/:/\n/g'|tail -1))

#根据序列号信息获取设备的managementId
#https://JAMF域名/classicapi/doc/#/computers/findComputersBySerialNumber
#官方文档介绍：https://developer.jamf.com/jamf-pro/reference/findcomputersbyserialnumber，根据序列号查找指定设备的managementId
curl -X 'GET' \
  "$url/api/v1/computers-inventory?section=GENERAL&page=0&page-size=100&sort=general.name%3Aasc&filter=hardware.serialNumber%3D%3D%22$serialNumber%22" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $bearerToken" \
  -o /tmp/data.json 2>/dev/null
managementId=$(grep "managementId" /tmp/data.json | sed 's/.*"managementId" : "\(.*\)",/\1/')

# 转换设置参数
json_template='{
    "clientData": [
        {
            "managementId": "$managementId",
            "clientType": "COMPUTER"
        }
    ],
    "commandData": {
        "commandType": "SET_RECOVERY_LOCK",
        "newPassword": ""
    }
}'
dataraw=$(printf "%s" "$json_template" | sed "s/\$managementId/$managementId/")
#根据设备的managementId设置指定的Recovery Lock密码
#https://JAMF域名/api/doc/#/mdm/post_v2_mdm_commands
#官方文档介绍：https://developer.jamf.com/jamf-pro/reference/post_v2-mdm-commands，使用Recovery Lock设置
curl --location \
--request POST "$url/api/v2/mdm/commands" \
--header "Authorization: Bearer $bearerToken" \
--header 'Content-Type: application/json' \
--data-raw "$dataraw" \
>/dev/null 2>&1
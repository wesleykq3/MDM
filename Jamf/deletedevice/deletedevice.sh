#!/bin/sh

#流程
#1、将本脚本保存为文件名.sh格式
#2、通过管理员运行“sh 文件名.sh”格式运行
#3、根据提示输入设备序列号进行脱管再删除

#JAMF API账户
username=""

#JAMF API密码
password=""

#JAMF API URL，最后不需要加“/”，如https://xxx.jamfcloud.com
url=""

# 检查用户名是否为空
if [ -z "$username" ]; then
    read -p "请输入 JAMF API 用户名: " username
fi

# 检查密码是否为空
if [ -z "$password" ]; then
    read -s -p "请输入 JAMF API 密码: " password
    echo
fi

# 检查 URL 是否为空
if [ -z "$url" ]; then
    read -p "请输入 JAMF API URL (例如：https://xxx.jamfcloud.com): " url
fi

#Variable declarations
bearerToken=""
tokenExpirationEpoch="0"
serialNumber=""



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
        #echo "No valid token available, getting new token"
        getBearerToken
    fi
}
checkTokenExpiration
read -p "请输入要删除的设备序列号：" serialNumber

# 检查序列号是否为空
if [ -z "$serialNumber" ]; then
    /bin/echo "设备序列号为空，无法继续操作。"
    exit 1  # 退出脚本
fi

# 使用序列号获取设备ID
curl -X 'GET' \
  "$url/api/v1/computers-inventory?section=GENERAL&page=0&page-size=4000&sort=general.name%3Aasc&filter=hardware.serialNumber%3D%3D%22$serialNumber%22" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $bearerToken" \
  -o /tmp/data.json 2>/dev/null

computerid=$(grep '"id"' /tmp/data.json | awk -F '"' '{print $4}' | head -n 1)

# 检查是否成功获取到设备ID
if [ -z "$computerid" ]; then
    /bin/echo "未找到设备，无法继续操作。"
    exit 1  # 退出脚本
fi

/bin/echo "开始设备脱管"
curl -X POST "$url/JSSResource/computercommands/command/UnmanageDevice/id/$computerid" \
    -H "accept: application/xml" \
    -H "Authorization: Bearer $bearerToken" >/dev/null 2>&1
sleep 5
/bin/echo "开始删除设备"
curl -X 'DELETE' \
  "$url/api/v1/computers-inventory/$computerid" \
  -H 'accept: */*' \
  -H "Authorization: Bearer $bearerToken" >/dev/null 2>&1
/bin/echo "设备删除完成"
import requests
import json
from lxml import etree
import base64

#JAMF管理员用户名
username=""

#JAMF管理员密码
password=""


response = requests.post("https://JAMF URL/api/v1/auth/token", auth=(username, password))
if response.status_code == 200:
    # 获取Bearer Token
    bearer_token = response.json().get("token")
    auth_header = f"Bearer {bearer_token}"
else:
    print("Failed to get Bearer Token. Status code:", response.status_code)
    print("Response:", response.text)

get_user_by_name = "https://JAMF URL/JSSResource/users/name/"
get_user_from_usergroups = "https://JAMF URL/JSSResource/usergroups/id/"
get_computer_from_computergroups = "https://JAMF URL/JSSResource/computergroups/id/"

computerGroupID = '64'

payload = ""
headers = {
  'Accept': 'application/json',
  'Content-Type': 'application/xml',
  'Authorization': auth_header,
}
#users = []
computers = []

#with open("account2.txt", "rb") as f:
#    userinfos = f.read().decode('utf-8')

#for account in userinfos.split('\r\n'):
#    users.append(account)
#print(users)
#for user in users:
#    url = get_user_by_name + user
#    response = requests.request("GET", url, headers=headers, data=payload)
#    print(response.text)
#    if response.status_code == 200:
#        print(response.text)
#        computers_info = json.loads(response.text)["user"]["links"]["computers"]
#        for computer_info in computers_info:
#            computers.append(computer_info["id"])


with open("computer.txt", "rb") as f:
#    userinfos = f.read().decode('utf-8')
    computers = f.readlines()
    print(computers)
 #computers=f.read().decode('utf-8').strip()
    
for computer in computers:
    computer = computer.decode('utf-8').strip()
    print(computer)
    root = etree.Element("computer_group")
    child1 = etree.SubElement(root, "id")
    child1.text = computerGroupID
    child2 = etree.SubElement(root, "computer_additions")
    child3 = etree.SubElement(child2, "size")
    child3.text = '1'
    child4 = etree.SubElement(child2, "computer")
    #child5 = etree.SubElement(child4, "id")
    child5 = etree.SubElement(child4, "name")
    child5.text = str(computer)
    payload = etree.tostring(root, pretty_print=True, xml_declaration=True, encoding='utf-8').decode('utf-8')
    print(payload)
    url = get_computer_from_computergroups + computerGroupID
    response = requests.request("PUT", url, headers=headers, data=payload)
    print(response.status_code)
    if response.status_code == 409:
        print("请确认表格里的："+computer+"计算机名是正确的")
'''

print(users.__len__())

for user in users:
    root = etree.Element("user_group")
    child1 = etree.SubElement(root, "id")
    child1.text = userGroupID
    child2 = etree.SubElement(root, "user_additions")
    child3 = etree.SubElement(child2, "size")
    child3.text = '1'
    child4 = etree.SubElement(child2, "user")
    child5 = etree.SubElement(child4, "username")
    child5.text = str(user)
    payload = etree.tostring(root, pretty_print=True, xml_declaration=True, encoding='utf-8').decode('utf-8')
    print(payload)
    url = get_user_from_computergroups + userGroupID

    response = requests.request("PUT", url, headers=headers, data=payload)
    print(response.status_code)
'''

'''
root = etree.Element("user_group")
child1 = etree.SubElement(root, "id")
child1.text = userGroupID
child2 = etree.SubElement(root, "user_additions")
child3 = etree.SubElement(child2, "size")
child3.text = str(len(users))

for user in users:
    child4 = etree.SubElement(child2, "user")
    child5 = etree.SubElement(child4, "username")
    child5.text = str(user)

payload = etree.tostring(root, pretty_print=True, xml_declaration=True, encoding='utf-8').decode('utf-8')
url = get_user_from_computergroups + userGroupID

response = requests.request("PUT", url, headers=headers, data=payload)
print(response.status_code)
'''
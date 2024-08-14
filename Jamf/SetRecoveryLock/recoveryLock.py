#!/usr/bin/env python3

import requests
import json
import subprocess
import time
from datetime import datetime, timezone

# Variable declarations
username = ""
password = ""
url = ""

bearer_token = ""
token_expiration_epoch = 0

def get_bearer_token():
    global bearer_token, token_expiration_epoch
    response = requests.post(f"{url}/api/v1/auth/token", auth=(username, password))
    response_data = response.json()
    bearer_token = response_data['token']
    expires = response_data['expires']
    expiration_time = datetime.strptime(expires, "%Y-%m-%dT%H:%M:%S.%fZ")
    token_expiration_epoch = int(expiration_time.timestamp())

def check_token_expiration():
    now_epoch_utc = int(datetime.now(timezone.utc).timestamp())
    if token_expiration_epoch > now_epoch_utc:
        print(f"Token valid until the following epoch time: {token_expiration_epoch}")
    else:
        print("No valid token available, getting new token")
        get_bearer_token()

def get_serial_number():
    result = subprocess.run(['system_profiler', 'SPHardwareDataType'], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if "Serial Number" in line:
            return line.split(":")[1].strip()

def main():
    global bearer_token
    get_bearer_token()
    check_token_expiration()
    print(bearer_token)
    
    # Get device serial number
    serial_number = get_serial_number()
    #serial_number="FVFG5992Q6L4"
    # Get management ID
    response = requests.get(
        f"{url}/api/v1/computers-inventory?section=GENERAL&page=0&page-size=100&sort=general.name%3Aasc&filter=hardware.serialNumber%3D%3D%22{serial_number}%22",
        headers={"Authorization": f"Bearer {bearer_token}", "Accept": "application/json"}
    )
    data = response.json()
    management_id = None
    for result in data.get('results', []):
        if 'general' in result:
            management_id = result['general'].get('managementId')
            if management_id:
                break

    if not management_id:
        raise Exception("Management ID not found")

    # JSON template
    json_template = {
        "clientData": [
            {
                "managementId": management_id,
                "clientType": "COMPUTER"
            }
        ],
        "commandData": {
            "commandType": "SET_RECOVERY_LOCK",
            "newPassword": ""
        }
    }

    # Send POST request
    response = requests.post(
        f"{url}/api/v2/mdm/commands",
        headers={"Authorization": f"Bearer {bearer_token}", "Content-Type": "application/json"},
        data=json.dumps(json_template)
    )
    
    print(response.status_code)
    print(response.text)

if __name__ == "__main__":
    main()

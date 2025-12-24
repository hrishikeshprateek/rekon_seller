#!/bin/bash

# Test ValidateLicense API with empty password
curl --location 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/ValidateLicense' \
--header 'package_name: com.reckon.reckonbiz' \
--header 'Content-Type: application/json' \
--data '{
    "lApkName": "com.reckon.reckonbiz",
    "LicNo": "RECKON",
    "MobileNo": "7503894820",
    "Password": "",
    "CountryCode": "91",
    "app_role": "SalesMan",
    "LoginDeviceId": "14319366a2e9f11",
    "device_name": "unknown Android Android SDK built for arm64",
    "v_code": 31,
    "version_name": "1.7.23",
    "lRole": "SalesMan"
}' | jq '.'


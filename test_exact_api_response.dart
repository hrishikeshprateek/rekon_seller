import 'dart:convert';

void main() {
  // Exact API response from the test
  final responseString = '''
{
  "Status": false,
  "FirmCode": "",
  "Message": "Password Not Set",
  "LicNo": "RECKON",
  "Store": [
    {
      "FirmCode": "PHDEMO",
      "Add3": "INDIA",
      "Mobile": "7510000636",
      "Add2": "UTTARPRADESH",
      "Name": "RECKON SOFTWARE DEMO",
      "Add1": "AMINABAD, LUCKNOW",
      "PinCode": "226016",
      "primary": true
    }
  ],
  "CreateMPin": false,
  "Profile": {
    "CUID": 1648,
    "DLIMAGEPATH": [
      {
        "ID": "1"
      }
    ],
    "GST1IMAGEPATH": [
      {
        "ID": "3"
      }
    ],
    "DL2MAGEPATH": [
      {
        "ID": "2"
      }
    ],
    "FL1IMAGEPATH": [
      {
        "ID": "4"
      }
    ],
    "MOBILENO": "917503894820",
    "NAME": "SALESMAN TWO"
  },
  "CreatePasswd": true,
  "AcCode": "",
  "AllReadyLogin": false,
  "RefreshToken": "",
  "AccessToken": "",
  "fsCode": "FSE   /000002",
  "DbName": "PWSORDER",
  "Id": 0
}
''';

  final data = jsonDecode(responseString) as Map<String, dynamic>;

  print('=== TESTING EXACT API RESPONSE ===');
  print('data["CreatePasswd"] = ${data['CreatePasswd']}');
  print('data["CreatePasswd"] type = ${data['CreatePasswd']?.runtimeType}');
  print('data["CreateMPin"] = ${data['CreateMPin']}');
  print('data["CreateMPin"] type = ${data['CreateMPin']?.runtimeType}');
  print('data["Status"] = ${data['Status']}');
  print('data["Status"] type = ${data['Status']?.runtimeType}');

  // BULLETPROOF flag detection - handle all possible cases
  bool needsCreatePass = false;
  bool needsCreateMPin = false;

  // Check CreatePasswd
  final cpValue = data['CreatePasswd'];
  if (cpValue == true) {
    needsCreatePass = true;
    print('CreatePasswd detected: == true');
  } else if (cpValue is bool && cpValue) {
    needsCreatePass = true;
    print('CreatePasswd detected: bool && cpValue');
  } else if (cpValue?.toString().toLowerCase() == 'true') {
    needsCreatePass = true;
    print('CreatePasswd detected: string "true"');
  } else if (cpValue?.toString() == '1') {
    needsCreatePass = true;
    print('CreatePasswd detected: string "1"');
  }

  // Check CreateMPin
  final cmValue = data['CreateMPin'];
  if (cmValue == true) {
    needsCreateMPin = true;
    print('CreateMPin detected: == true');
  } else if (cmValue is bool && cmValue) {
    needsCreateMPin = true;
    print('CreateMPin detected: bool && cmValue');
  } else if (cmValue?.toString().toLowerCase() == 'true') {
    needsCreateMPin = true;
    print('CreateMPin detected: string "true"');
  } else if (cmValue?.toString() == '1') {
    needsCreateMPin = true;
    print('CreateMPin detected: string "1"');
  }

  print('FINAL: needsCreatePass = $needsCreatePass');
  print('FINAL: needsCreateMPin = $needsCreateMPin');

  if (needsCreatePass || needsCreateMPin) {
    print('✅ SUCCESS: Would return success=true and navigate to password screen');
  } else {
    print('❌ FAILED: Would show error dialog');
  }
}


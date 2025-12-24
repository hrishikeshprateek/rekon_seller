import 'dart:convert';

void main() {
  // Test the exact logic from auth_service.dart
  final responseString = '''
{
  "Status": false,
  "Message": "Password Not Set",
  "CreatePasswd": true,
  "CreateMPin": false
}
''';

  final data = jsonDecode(responseString) as Map<String, dynamic>;

  print('=== TESTING AUTH SERVICE LOGIC ===');
  print('Raw response: $data');

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

  // Test the if condition
  print('CHECKPOINT 1: About to check if needsCreatePass || needsCreateMPin');
  print('CHECKPOINT 1: needsCreatePass=$needsCreatePass, needsCreateMPin=$needsCreateMPin');

  if (needsCreatePass || needsCreateMPin) {
    print('CHECKPOINT 2: ENTERED THE IF BLOCK - Will return success');
    print('User needs to create password/mpin. CreatePasswd=$needsCreatePass, CreateMPin=$needsCreateMPin');
    final returnValue = {
      'success': true,
      'message': data['Message'] ?? 'Please create password/MPIN',
      'data': data,
    };
    print('CHECKPOINT 3: RETURNING SUCCESS with data containing CreatePasswd');
    print('Return value success: ${returnValue['success']}');
    print('✅ SUCCESS: AuthService would return success=true');
  } else {
    print('CHECKPOINT 4: DID NOT ENTER CreatePasswd block');
    print('❌ FAILURE: AuthService would continue to Status check');
  }
}


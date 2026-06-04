import 'dart:convert';
import 'dart:io';

const _port = 8787;
const _host = '127.0.0.1';
const _verifyPath = '/api/subscription/verify';
const _statusPath = '/api/subscription/status';
const _supportedProductIds = <String>{
  'mana_poster_premium_monthly_149',
};

bool _isExpiryActive(String? expiryTime) {
  if (expiryTime == null || expiryTime.trim().isEmpty) {
    return false;
  }
  final expiryDate = DateTime.tryParse(expiryTime);
  if (expiryDate == null) {
    return false;
  }
  return expiryDate.isAfter(DateTime.now());
}

Future<void> main() async {
  final entitlements = <String, Map<String, dynamic>>{};
  final server = await HttpServer.bind(_host, _port);
  stdout.writeln('Mock subscription backend running on http://$_host:$_port');
  stdout.writeln('Endpoints: $_verifyPath, $_statusPath');

  await for (final request in server) {
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    if (request.method != 'POST') {
      await _writeJson(
        request.response,
        statusCode: HttpStatus.methodNotAllowed,
        body: <String, dynamic>{
          'isPro': false,
          'message': 'Method not allowed',
        },
      );
      continue;
    }

    try {
      final raw = await utf8.decoder.bind(request).join();
      final payload = raw.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(raw) as Map<String, dynamic>);

      if (request.uri.path == _verifyPath) {
        await _handleVerify(request.response, payload, entitlements);
      } else if (request.uri.path == _statusPath) {
        await _handleStatus(request.response, payload, entitlements);
      } else {
        await _writeJson(
          request.response,
          statusCode: HttpStatus.notFound,
          body: <String, dynamic>{
            'isPro': false,
            'message': 'Route not found',
          },
        );
      }
    } catch (error) {
      await _writeJson(
        request.response,
        statusCode: HttpStatus.badRequest,
        body: <String, dynamic>{
          'isPro': false,
          'message': 'Invalid request: $error',
        },
      );
    }
  }
}

Future<void> _handleVerify(
  HttpResponse response,
  Map<String, dynamic> payload,
  Map<String, Map<String, dynamic>> entitlements,
) async {
  final uid = (payload['uid']?.toString() ?? '').trim();
  final productId = (payload['productId']?.toString() ?? '').trim();
  final token = (payload['serverVerificationData']?.toString() ?? '').trim();
  final source = (payload['verificationSource']?.toString() ?? '').trim();

  if (uid.isEmpty) {
    await _writeJson(
      response,
      statusCode: HttpStatus.badRequest,
      body: <String, dynamic>{
        'isPro': false,
        'message': 'Missing uid',
      },
    );
    return;
  }

  final hasProduct = _supportedProductIds.contains(productId);
  final hasToken = token.isNotEmpty;
  final hasSource = source.isNotEmpty;
  final isValid = hasProduct && hasToken && hasSource;
  final existingEntry = entitlements[uid];
  final existingProductId = (existingEntry?['productId']?.toString() ?? '').trim();
  final existingStartDate = existingEntry?['startDate']?.toString();
  final existingExpiryDate = existingEntry?['expiryTime']?.toString();
  final shouldReuseDates =
      existingEntry != null &&
      existingProductId == productId &&
      existingStartDate != null &&
      existingStartDate.isNotEmpty &&
      existingExpiryDate != null &&
      existingExpiryDate.isNotEmpty;
  final now = DateTime.now();
  final startDate =
      shouldReuseDates ? existingStartDate : now.toIso8601String();
  final expiryDate = shouldReuseDates
      ? existingExpiryDate
      : now.add(const Duration(days: 30)).toIso8601String();
  final isActive = isValid && _isExpiryActive(expiryDate);
  final status = isActive ? 'active' : 'expired';

  stdout.writeln(
    shouldReuseDates
        ? 'Mock verify: reusing saved expiry for uid=$uid productId=$productId expiry=$expiryDate'
        : 'Mock verify: creating new expiry for uid=$uid productId=$productId expiry=$expiryDate',
  );

  entitlements[uid] = <String, dynamic>{
    'isPro': isActive,
    'status': status,
    'startDate': startDate,
    'expiryTime': expiryDate,
    'productId': productId,
  };

  await _writeJson(
      response,
      statusCode: HttpStatus.ok,
      body: <String, dynamic>{
      'isPro': isActive,
      'message': isActive
          ? 'Mock verification success'
          : 'Mock verification failed (product/token/source check)',
      'status': status,
      'startDate': startDate,
      'expiryTime': expiryDate,
      'uid': uid,
      'productId': productId,
    },
  );
}

Future<void> _handleStatus(
  HttpResponse response,
  Map<String, dynamic> payload,
  Map<String, Map<String, dynamic>> entitlements,
) async {
  final uid = (payload['uid']?.toString() ?? '').trim();
  if (uid.isEmpty) {
    await _writeJson(
      response,
      statusCode: HttpStatus.badRequest,
      body: <String, dynamic>{
        'isPro': false,
        'message': 'Missing uid',
      },
    );
    return;
  }

  final entry =
      entitlements[uid] ??
      <String, dynamic>{
        'isPro': false,
        'status': 'expired',
        'startDate': null,
        'expiryTime': null,
      };
  final expiryTime = entry['expiryTime']?.toString();
  final isPro = entry['isPro'] == true && _isExpiryActive(expiryTime);
  final status = isPro ? 'active' : 'expired';
  stdout.writeln(
    'Mock status: uid=$uid status=$status expiry=$expiryTime',
  );
  await _writeJson(
    response,
    statusCode: HttpStatus.ok,
    body: <String, dynamic>{
      'isPro': isPro,
      'message': isPro ? 'Entitlement active' : 'Entitlement inactive',
      'status': status,
      'startDate': entry['startDate'],
      'expiryTime': expiryTime,
      'uid': uid,
    },
  );
}

void _setCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Headers', '*');
  response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.headers.contentType = ContentType.json;
}

Future<void> _writeJson(
  HttpResponse response, {
  required int statusCode,
  required Map<String, dynamic> body,
}) async {
  response.statusCode = statusCode;
  response.write(jsonEncode(body));
  await response.close();
}

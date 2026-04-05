import 'dart:convert';
import 'dart:io';

const _port = 8787;
const _host = '127.0.0.1';
const _verifyPath = '/api/subscription/verify';
const _statusPath = '/api/subscription/status';
const _supportedProductIds = <String>{
  'pro_monthly_20',
  'mana_poster_pro_monthly_20',
};

Future<void> main() async {
  final entitlements = <String, bool>{};
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
  Map<String, bool> entitlements,
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

  entitlements[uid] = isValid;

  await _writeJson(
    response,
    statusCode: HttpStatus.ok,
    body: <String, dynamic>{
      'isPro': isValid,
      'message': isValid
          ? 'Mock verification success'
          : 'Mock verification failed (product/token/source check)',
      'uid': uid,
      'productId': productId,
    },
  );
}

Future<void> _handleStatus(
  HttpResponse response,
  Map<String, dynamic> payload,
  Map<String, bool> entitlements,
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

  final isPro = entitlements[uid] ?? false;
  await _writeJson(
    response,
    statusCode: HttpStatus.ok,
    body: <String, dynamic>{
      'isPro': isPro,
      'message': isPro ? 'Entitlement active' : 'Entitlement inactive',
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

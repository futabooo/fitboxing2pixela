import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:functions_framework/functions_framework.dart';
import 'package:gcp/gcp.dart';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis/vision/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';

@CloudFunction()
FutureOr<Response> function(Request request) async {
  initializeDateFormatting('ja');

  String? projectId;
  try {
    projectId = await computeProjectId();
  } catch (err, stack) {
    print('$err, $stack');
  }
  if (projectId == null) {
    return Response.internalServerError(
      body: 'Internal Server Error. not found Google Cloud Projcet ID',
    );
  }

  // FIXME: requestにいれるのでもいいかも
  final pixelaUserTokenKey = Platform.environment['PIXELA_USER_TOKEN_KEY'];
  final pixelaUserName = Platform.environment['PIXELA_USER_NAME'];
  final pixelaGraphId = Platform.environment['PIXELA_GRAPH_ID'];
  print(pixelaUserTokenKey);
  print(pixelaUserName);
  print(pixelaGraphId);
  if (pixelaUserTokenKey == null ||
      pixelaUserName == null ||
      pixelaGraphId == null) {
    final messages = [
      '${pixelaUserTokenKey == null ? 'PIXELA_USER_TOKEN_KEY' : ''}'
          '${pixelaUserName == null ? 'PIXELA_USER_NAME' : ''}'
          '${pixelaGraphId == null ? 'PIXELA_GRAPH_ID' : ''}'
    ].join(',');
    return Response.internalServerError(
      body: 'Internal Server Error. not found Environment variables $messages',
    );
  }

  final params = request.url.queryParameters;
  if (!params.keys.contains('url') || !params.keys.contains('date')) {
    return Response.badRequest();
  }
  final imageUrl = params['url'];
  final dateStr = params['date'];
  if (imageUrl == null || dateStr == null) {
    return Response.badRequest();
  }
  print('imageUrl: $imageUrl date: $dateStr');

  final client = await clientViaApplicationDefaultCredentials(
    scopes: [
      VisionApi.cloudVisionScope,
      SecretManagerApi.cloudPlatformScope,
    ],
  );
  final visionApi = VisionApi(client);
  final response = await visionApi.images.annotate(
    BatchAnnotateImagesRequest.fromJson(
      {
        "requests": [
          {
            "image": {
              "source": {"imageUri": imageUrl}
            },
            "features": [
              {"type": "TEXT_DETECTION"}
            ]
          }
        ]
      },
    ),
  );

  final annotateimageResponse = response.responses?.first;
  if (annotateimageResponse == null) {
    return Response.notFound(null);
  }

  final allDescription = annotateimageResponse.textAnnotations
      ?.firstWhere((element) => element.locale != null)
      .description;
  print('allDescription: $allDescription');

  final textAnnotation = annotateimageResponse.textAnnotations?.firstWhere(
    (e) =>
        (e.description?.contains('.') == true) &&
        (e.description?.contains('\n') == false),
  );
  final burnkcal = textAnnotation?.description?.replaceAll('kcal', '');
  print('burnkcal: $burnkcal');

  final secretManagerApi = SecretManagerApi(client);
  final seacretsResonse =
      await secretManagerApi.projects.secrets.versions.access(
    'projects/$projectId/secrets/$pixelaUserTokenKey/versions/latest',
  );
  final pixelaTokenAsBytes = seacretsResonse.payload?.dataAsBytes;
  if (pixelaTokenAsBytes == null) {
    return Response.internalServerError(
      body: 'Internal Server Error. not found pixela user token',
    );
  }
  final pixelaUserToken = utf8.decode(pixelaTokenAsBytes);

  final dateFormat = DateFormat('yyyyMMdd', 'ja');
  final dateTime = DateTime.parse(dateStr);
  final date = dateFormat.format(dateTime);
  final pexelaResonse = await http.post(
    Uri.parse('https://pixe.la/v1/users/$pixelaUserName/graphs/$pixelaGraphId'),
    body: jsonEncode({'date': date, 'quantity': burnkcal}),
    headers: {'X-USER-TOKEN': pixelaUserToken},
  );
  print(pexelaResonse.body);

  return Response.ok('success');
}

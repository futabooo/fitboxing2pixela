import 'package:functions_framework/functions_framework.dart';
import 'package:googleapis/vision/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';

@CloudFunction()
Future<Response> function(Request request) async {
  final params = request.url.queryParameters;
  if (!params.keys.contains('url')) {
    return Response.badRequest();
  }
  // final imageUrl = params['url'];
  final imageUrl =
      'https://pbs.twimg.com/media/FmXCf54aAAEQdWQ?format=jpg&name=large';
  print('imageUrl = $imageUrl');

  final client = await clientViaApplicationDefaultCredentials(
    scopes: [VisionApi.cloudVisionScope],
  );
  final visionApi = VisionApi(client);
  final response = await visionApi.images.annotate(
    BatchAnnotateImagesRequest.fromJson({
      "requests": [
        {
          "image": {
            "source": {"imageUri": "$imageUrl"}
          },
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    }),
  );

  print(response.toJson().toString());

  final textes = response.responses
          ?.map((e) => e.fullTextAnnotation?.text ?? '')
          .toList() ??
      [];
  return Response.ok('success ${textes.join()}');
}

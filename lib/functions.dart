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
  final imageUrl = params['url'];
  print('imageUrl = $imageUrl');

  final client = await clientViaApplicationDefaultCredentials(
    scopes: [VisionApi.cloudVisionScope],
  );
  final visionApi = VisionApi(client);
  final response = await visionApi.images.annotate(
    BatchAnnotateImagesRequest.fromJson(
      {
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
  print(allDescription);

  final textAnnotation = annotateimageResponse.textAnnotations?.firstWhere(
    (e) =>
        (e.description?.contains('.') == true) &&
        (e.description?.contains('\n') == false),
  );
  final burnkcal = textAnnotation?.description?.replaceAll('kcal', '');
  print(burnkcal);

  return Response.ok('success');
}

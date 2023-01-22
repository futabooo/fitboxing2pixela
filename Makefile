.PHONY: clean

FUNCTION_TARGET = function
PORT = 8080

# bin/server.dart is the generated target for lib/functions.dart
bin/server.dart:
	dart run build_runner build --delete-conflicting-outputs

build: bin/server.dart

test: clean build
	dart test

clean:
	dart run build_runner clean
	rm -rf bin/server.dart

run: build
	dart run bin/server.dart --port=$(PORT) --target=$(FUNCTION_TARGET)

deploy:
	gcloud run deploy fitboxing2pixela \
	--source=. \
	--project=${GCP_PROJECT} \
	--region=asia-northeast1 \
	--platform=managed \
	--allow-unauthenticated \
	--update-env-vars=PIXELA_USER_TOKEN_KEY=${PIXELA_USER_TOKEN_KEY},PIXELA_USER_NAME=${PIXELA_USER_NAME},PIXELA_GRAPH_ID=${PIXELA_GRAPH_ID}
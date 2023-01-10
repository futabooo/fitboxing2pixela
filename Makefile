.PHONY: clean

GCP_PROJECT_ID = fitboxing2pixela
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
	gcloud run deploy hellowworld \
	--source=. \
	--project=${GCP_PROJECT_ID} \
	--region=asia-northeast1 \
	--platform=managed \
	--allow-unauthenticated
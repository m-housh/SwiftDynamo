# Example settings
LAMBDA_NAME=TodoAPIGateway
EXECUTABLE=$(LAMBDA_NAME)
LAMBDA_ZIP=lambda.zip

SWIFT_VERSION=5.1.3
BUILDER_NAME:=swift-lambda:5.1.3

docker_builder:
	@docker build \
		--build-arg SWIFT_VERSION=$(SWIFT_VERSION) \
		-t $(BUILDER_NAME) .

clean_lambda:
	@rm bootstrap || true
	@rm $(LAMBDA_ZIP) || true

build_lambda:
	@docker run \
		--rm \
		--volume "$(PWD):/src" \
		--workdir "/src" \
		$(BUILDER_NAME) \
		swift build -c release --disable-package-manifest-caching

package_lambda: build_lambda
	cp .build/release/$(EXECUTABLE) ./bootstrap
	zip -r -j $(LAMBDA_ZIP) ./bootstrap


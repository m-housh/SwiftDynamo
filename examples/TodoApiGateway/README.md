# TodoApiGateway

An example of using `SwiftDynamo` with `LambdaRuntime`.

A todo service built using `SwiftDynamo` which is a vapor like interface to `DynamoDB`.  This
recreates the example api-gateway in the [LambdaRuntime](https://github.com/fabianfett/swift-lambda-runtime.git) package.

### Try it.

```bash

$ cd examples/TodoApiGateway
$ make docker_builder // only need to run once.
$ make package_lambda // build and package for usage.
$ sam deploy --guided // deploy to aws (this may charge depending on usage.)
```

Once the database and application is deployed, changes to the package can be tested locally using `sam local`.
Rebuild your project using `make package_lambda`, then you can run `sam local start-api` to test your changes.

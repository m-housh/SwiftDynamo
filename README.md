# SwiftDynamo

A vapor like interface to `DynamoDB`.

## The Basics

Use swift package manager to use in your project.  Check basic usage below as well as the api-gateway example that uses
the [LambdaRuntime](https://github.com/fabianfett/swift-lambda-runtime.git) package.

### Package.swift

```swift

...
dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/m-housh/SwiftDynamo.git", from: "0.1.1"),
],
...
```

### TodoModel.swift

```swift

import SwiftDynamo

final class TodoModel: DynamoModel {

    static var schema: DynamoSchema = "Todos"
    
    @ID(key: "TodoID")
    var id: UUID?
    
    @Field(key: "Title")
    var title: String
    
    @Field(key: "Completed")
    var completed: Bool
    
    @Field(key: "Order")
    var order: Int?
    
    init() { }
    
    init(id: UUID? = nil, title: String, completed: Bool = false, order: Int? = nil) {
        self.id = id
        self.title = title
        self.completed = completed
        self.order = order
    }
}

```

### TodoStore.swift

```swift

import DynamoDB

struct TodoStore {
    
    private let dynamoDB: DynamoDB

    init(
        eventLoopGroup: EventLoopGroup,
        accessKeyId: String,
        secretAccessKey: String,
        sessionToken: String?,
        region: Region)
    {
        self.dynamoDB = DynamoDB(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: sessionToken,
            region: region,
            eventLoopGroupProvider: .shared(eventLoopGroup))
    }
    
    func getTodos() -> EventLoopFuture<[TodoModel]> {
        TodoModel.query(on: dynamoDB).all()
    }
    
    func getTodo(id: UUID) -> EventLoopFuture<TodoModel?> {
        TodoModel.find(id: id, on: dynamoDB)
    }
    
    func getTodo(title: String) -> EventLoopFuture<TodoModel?> {
        TodoModel.query(on: dynamoDB)
            .filter(\.$title == title)
            .first()
    }
    
    func saveTodo(todo: TodoModel) -> EventLoopFuture<TodoModel> {
        todo.save(on: dynamoDB)
    }
    
    func deleteTodo(id: UUID) -> EventLoopFuture<Void> {
        TodoModel.delete(id: id, on: dynamoDB)
    }
}
```

## Status

- [x] Supports Static Partition Keys and Sort Keys on Models
- [x] Basic equality filters on properties (note that you can not use `!=` on a partition key or sort key)
- [x] Property wrappers for fields, dynamic sort-keys, and id.
- [x] Supports random id generation for `UUID` (can be overriden to user generated)
- [x] Test framework under the `XCTDynamo` folder (use in your tests by importing the package as a dependency)
- [x] Custom encoder and decoder to convert `Codable` types to types that `aws-sdk-swift` expects.
- [ ] Sorting capabilities.
- [ ] More filtering options.
- [ ] Batch queries and writes.

## Contributing

This package is currently under development, if you would like to contribute to `SwiftDynamo` your help would be appreciated.

## Credits

[vapor/vapor](https://github.com/vapor/vapor.git)

[swift-lambda-runtime](https://github.com/fabianfett/swift-lambda-runtime.git)

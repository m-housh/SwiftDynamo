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

struct PatchTodo: Codable {
    
    let title: String?
    let order: Int?
    let completed: Bool?
    
    func patchQuery(query: inout DynamoQueryBuilder<TodoModel>) {
        if let title = self.title {
            query.set(\.$title, to: title)
        }
        if let order = self.order {
            query.set(\.$order, to: order)
        }
        if let completed = self.completed {
            query.set(\.$completed, to: completed)
        }
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
    
    func patchTodo(id: UUID, patch: PatchTodo) -> EventLoopFuture<TodoModel> {
        var query = TodoModel.query(on: dynamoDB)
            .filter(\.$id == id)
            
        patch.patchQuery(query: &query)
        
        return query
            .setAction(action: .update)
            .first()
            .map { $0! }
    }
    
    func saveTodo(todo: TodoModel) -> EventLoopFuture<TodoModel> {
        todo.save(on: dynamoDB)
    }
    
    func deleteTodo(id: UUID) -> EventLoopFuture<Void> {
        TodoModel.delete(id: id, on: dynamoDB)
    }
}
```

## Sort And Partition Keys

Partition keys and sort keys can be set several ways depending the use case.

### Set globally on the schema.
```swift

final class TodoModel: DynamoModel {

    static var schema: DynamoSchema {
        DynamoSchema(
            "Todos",
            partitionKey: .init(key: "ListID", default: "list"),
            sortKey: nil // or .init(key: "MySortKey", default: "foo")
        )
    }
    ...
}
```

### Set as a field on the model.

Any field also has flags in the initializer to declare it as a sort or partition key as well as some specialized fields.
The `ID` field for example defaults to being a partition a key.  There is also a `SortKey` field.

To change the behavior of an `ID` field it needs to be set at declaration.
```swift

...

@ID(key: "TodoID", type: .sortKey, generatedBy: .user)
var id: UUID

...
```

To declare a sort key just use the `SortKey` field.
```swift
...

@SortKey(key: "MySortKey")
var sortKey: String

...
```

Or declare a standard field as a sort or partition key at declaration.
```swift
...

@Field(key: "MyPartitionKey", partitionKey: true, sortKey: false)
var partitionKey: String

...

```

### Set on a query
You can also specify a sort key or a partition key on a query.  This could potentially override any values that are currently
set on a query.

```swift

TodoModel.query(on: dynamoDB)
    .setSortKey(sortKey: "Foo", to: "Bar")
    .setPartitionKey(partitionKey: "Bar", to: "Foo")
    
// or if you have a sort key field declared on the model.

TodoModel.query(on: dynamoDB)
    .setSortKey(\.$sortKey, to: "Foo")
    
// if you declared a field then you would use the `set` method on the query.

TodoModel.query(on: dynamoDB)
    .set(\.$partitionKey, to: "Partition")
    
```

## XCTDynamo

A convenience package for testing your models.

```swift

import XCTest
import XCTDynamo
import TodoStore

final class TodoStoreTests: XCTestCase, XCTDynamo {

    var database: DynamoDB! = DynamoDB(endpoint: "http://localhost:8000")
    
    func testCRUD() throws {
    
        runTest { 
            let todo = TodoModel(
                id: .init(),
                title: "Test", 
                completed: false,
                order: 1
            )
            
            var beforeCount: Int!
            
            try fetchAll() { todos in 
                beforeCount = todos.count
            }
            .save(todo) { saved in 
                XCTAssertEqual(saved, todo)
            }
            .find(id: todo.id!) { fetched in 
                XCTAssertNotNil(fetched)
                XCTAssertEqual(fetched!, todo)
            }
            .fetchAll() { XCTAssertEqual($0.count, beforeCount + 1 }
            .delete(id: todo.id!) { }
            .fetchAll() { XCTAssertEqual($0.count, beforeCount) }
        }
    }
}

```

## Status

- [x] Supports Static or Dynamic Partition Keys and Sort Keys on Models
- [x] Basic equality filters on properties (note that you can not use `!=` on a partition key or sort key)
- [x] Property wrappers for fields, dynamic sort-keys, and id (id can be a partition key or a sort key).
- [x] Supports random id generation for `UUID` (can be overriden to user generated)
- [x] Test framework under the `XCTDynamo` folder (use in your tests by importing the package as a dependency)
- [x] Custom encoder and decoder to convert `Codable` types to types that `aws-sdk-swift` expects.
- [ ] Sorting capabilities.
- [ ] More filtering options.
- [x] Batch queries and writes.
- [x] Paginated queries.

## Contributing

This package is currently under development, if you would like to contribute to `SwiftDynamo` your help would be appreciated.

## Credits

[vapor/vapor](https://github.com/vapor/vapor.git)

[swift-lambda-runtime](https://github.com/fabianfett/swift-lambda-runtime.git)

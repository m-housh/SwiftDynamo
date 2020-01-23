# SwiftDynamo

A vapor like interface to `DynamoDB`.

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

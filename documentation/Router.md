#  Router

The router: `HBApplication.router` directs requests to their handlers based on the contents of their path. The router that comes with Hummingbird uses a Trie based lookup. Routes are added using the function `on`. You provide the URI path, the method and the handler function. Below is a simple route which returns "Hello" in the body of the response.

```swift
let app = HBApplication()
app.router.on("/hello", method: .GET) { request in
    return "Hello"
}
```
If you don't provide a path then the default is for it to be "/".

## Methods

There are shortcut functions for common HTTP methods. The above can be written as

```swift
let app = HBApplication()
app.router.get("/hello") { request in
    return "Hello"
}
```

There are shortcuts for `put`, `post`, `head`, `patch` and `delete` as well.

## Response generators

Route handlers are required to return either a type conforming to the `HBResponseGenerator` protocol or an `EventLoopFuture` of a type conforming to `HBResponseGenerator`. An `EventLoopFuture` is an object that will fulfilled with their value at a later date in an asynchronous manner. The `HBResponseGenerator` protocol requires an object to be able to generate an `HBResponse`. For example `String` has been extended to conform to `HBResponseGenerator` by returning an `HBResponse` with status `.ok`,  a content-type header of `text-plain` and a body holding the contents of the `String`. 
```swift
/// Extend String to conform to ResponseGenerator
extension String: HBResponseGenerator {
    /// Generate response holding string
    public func response(from request: HBRequest) -> HBResponse {
        let buffer = request.allocator.buffer(string: self)
        return HBResponse(status: .ok, headers: ["content-type": "text/plain; charset=utf-8"], body: .byteBuffer(buffer))
    }
}
```

In addition to `String` `ByteBuffer`, `HTTPResponseStatus` and `Optional` have also been extended to conform to `HBResponseGenerator`.

It is also possible to extend `Codable` objects to generate `HBResponses` by conforming these objects to `HBResponseEncodable`. The object will use `HBApplication.encoder` to encode these objects. If an object conforms to `HBResponseEncodable` then also so do arrays of these objects and dictionaries.

## Parameters

You can extract parameters out of the URI by prefixing the path with a colon. This indicates that this path section is a parameter. The parameter name is the string following the colon. You can get access to the parameters extracted from the URI with `HBRequest.parameters`. If there are no URI parameters in the path, accessing `HBRequest.parameters` will cause a crash, so don't use it if you haven't specified a parameter in the route path. This example extracts an id from the URI and uses it to return a specific user. so "/user/56" will return user with id 56. 

```swift
let app = HBApplication()
app.router.get("/user/:id") { request in
    let id = request.parameters.get("id", as: Int.self) else { throw HBHTTPError(.badRequest) }
    return getUser(id: id)
}
```
In the example above if I fail to access the parameter as an `Int` then I throw an error. If you throw an `HBHTTPError` it will get converted to a valid HTTP response.

## Groups

Route handlers can be grouped together in a `HBRouterGroup`.  These allow for you to prefix a series of routes with the same path and more importantly apply middleware to only those routes. The example below is a group that includes five handlers all prefixed with the path "/todos".

```swift
let app = HBApplication()
app.router.group("/todos")
    .put(use: createTodo)
    .get(use: listTodos)
    .get(":id", getTodo)
    .patch(":id", editTodo)
    .delete(":id", deleteTodo)
```


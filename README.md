# RoutingKit



## Usage

```swift
struct MessageBody: Body {
    typealias Response = String
    var message: String
}

router.register(MessageBody.self) { $0.message }
try router.request(MessageBody(message: "message"))
```



### URL

```swift
public protocol DemoURLDecodableBody: URLDecodableBody {}

public extension DemoURLDecodableBody {
    static var scheme: String { "demo" }
    static var host: Host { .any }
}

struct DocBody: DemoURLDecodableBody {
    typealias Response = String
    static var uri: String { "/docs/:id" }
    static func decode(from url: URL, urlParameters: Parameters) throws -> DocBody {
        DocBody(id: urlParameters["id", as: String.self]!)
    }
    var id: String
}

router.register(DocBody.self) { $0.id }
try router.request(DocBody(id: "hello"))
try router.request(url: URL(string: "demo://host/docs/uuid")!)
```



### Wildcard

```swift
struct DocBody: DemoURLDecodableBody {
  var uri: String { "/*/:id" }
}
```





## Installation

### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add https://github.com/octree/RoutingKit.git
- Select "Up to Next Major" with "1.0.0"



## License

**RoutingKit** is available under the MIT license. See the LICENSE file for more info.

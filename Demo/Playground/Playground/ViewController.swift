//
//  ViewController.swift
//  RoutingKit
//
//  Created by octree on 2022/1/8.
//
//  Copyright (c) 2022 Octree <octree@octree.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import RoutingKit
import UIKit

struct MessageBody: Body {
    typealias Response = String
    var message: String
}

struct DocBody: URLDecodableBody {
    typealias Response = String
    static var url: URL { URL(string: "abc://def/docs/:id")! }

    static func decode(from url: URL, urlParameters: Parameters) throws -> DocBody {
        DocBody(id: urlParameters["id", as: String.self]!)
    }

    var id: String
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let router: Routing = Router.default
        router.register(MessageBody.self) { $0.message }
        router.register(DocBody.self) { $0.id }

        print(router.request(MessageBody(message: "message")))
        print(router.request(DocBody(id: "hello")))
        print(router.request(url: URL(string: "abc://def/docs/world")!))
        print(router.request(url: URL(string: "abc://def/docs")!))
    }
}

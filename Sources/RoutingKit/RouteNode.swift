//
//  RouteNode.swift
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

import Foundation

class RouteNode {
    typealias ComponentGenerator = IndexingIterator<[String]>
    var handler: URLRequestHandler?
    var parameters = [RouteNode]()
    var wildCard: RouteNode?
    var literals = [String: RouteNode]()
    var terminal = true

    func getNode(generator: IndexingIterator<[PathComponent]>) -> RouteNode {
        var gen = generator
        if let component = gen.next() {
            let node: RouteNode
            switch component {
            case .wildcard:
                if wildCard == nil {
                    wildCard = WildCardRoute()
                }
                node = wildCard!
            case let .literal(name):
                let lower = name.lowercased()
                if let existing = literals[lower] {
                    node = existing
                } else {
                    node = LiteralRoute(name: lower)
                    literals[lower] = node
                }
            case let .parameter(name):
                let dups = parameters.compactMap { $0 as? ParameterRoute }.filter { $0.name == name }
                if dups.isEmpty {
                    let pr = ParameterRoute(name: name)
                    parameters.append(pr)
                    node = pr
                } else {
                    node = dups[0]
                }
            }
            return node.getNode(generator: gen)
        } else {
            return self
        }
    }

    func findHandler(current: String, generator: ComponentGenerator, parameters: inout Parameters) -> URLRequestHandler? {
        var gen = generator
        if let pathComponent = gen.next() {
            if let node = literals[pathComponent.lowercased()],
               let handler = node.findHandler(current: pathComponent, generator: gen, parameters: &parameters)
            {
                return handler
            }
            for node in self.parameters {
                if let handler = node.findHandler(current: pathComponent, generator: gen, parameters: &parameters) {
                    return handler
                }
            }
        } else if let handler = handler {
            if terminal {
                return handler
            }
            return nil
        } else {
            if let node = wildCard,
               let handler = node.findHandler(current: "", generator: gen, parameters: &parameters)
            {
                return handler
            }
        }
        return nil
    }
}

final class ParameterRoute: RouteNode {
    let name: String
    init(name: String) {
        self.name = name
        super.init()
    }

    override func findHandler(current: String, generator: RouteNode.ComponentGenerator, parameters: inout Parameters) -> URLRequestHandler? {
        if let handler = super.findHandler(current: current, generator: generator, parameters: &parameters) {
            parameters[name] = current.removingPercentEncoding ?? current
            return handler
        }
        return nil
    }
}

final class LiteralRoute: RouteNode {
    let name: String
    init(name: String) {
        self.name = name
        super.init()
    }
}

final class WildCardRoute: RouteNode {}

extension RouteNode {
    func addRoute(url: URL, handler: @escaping URLRequestHandler) {
        var components: [PathComponent] = [
            PathComponent(stringLiteral: url.scheme ?? "*"),
            PathComponent(stringLiteral: url.host ?? "*")
        ]
        components.append(contentsOf: url.path.pathComponents)
        let generator = components.makeIterator()
        let node = getNode(generator: generator)
        node.terminal = true
        node.handler = handler
    }

    func add(route: AnyRoute) {
        addRoute(url: route.url, handler: route.handler)
    }
}

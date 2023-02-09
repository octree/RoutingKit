//
//  Router.swift
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

public protocol Routing {
    func register<T: Body>(_ type: T.Type, handler: @escaping (T) throws -> T.Response)
    func register<T: URLDecodableBody>(_ type: T.Type, handler: @escaping (T) throws -> T.Response)
    func request<T: Body>(_ body: T) -> T.Response?
    func request(url: URL) -> Any?
}

public enum RoutingError: Error {
    case notFound
}

private func erase<T: Body>(_ handler: @escaping RequestHandler<T>) -> AnyRequestHandler {
    { try handler($0 as! T) }
}

public final class Router: Routing {
    public static let `default` = Router()
    private var root: RouteNode = .init()
    private var resolversByType: [ObjectIdentifier: AnyRequestHandler] = [:]

    public init() {}

    public func register<T>(_ type: T.Type, handler: @escaping (T) throws -> T.Response) where T: Body {
        resolversByType[ObjectIdentifier(type)] = erase(handler)
    }

    public func register<T>(_ type: T.Type, handler: @escaping (T) throws -> T.Response) where T: URLDecodableBody {
        resolversByType[ObjectIdentifier(type)] = erase(handler)
        root.add(route: Route(url: type.url, handler: handler))
    }

    public func request<T>(_ body: T) -> T.Response? where T: Body {
        guard let resolver = resolversByType[ObjectIdentifier(T.self)] else {
            return nil
        }
        return try? resolver(body) as? T.Response
    }

    public func request(url: URL) -> Any? {
        guard let (handler, params) = findHandler(url: url) else {
            return nil
        }
        return try? handler(url, params)
    }

    public func canHandle(url: URL) -> Bool {
        findHandler(url: url) != nil
    }

    func findHandler(url: URL) -> (URLRequestHandler, Parameters)? {
        var components = [url.scheme ?? "", url.host ?? ""]
        components.append(contentsOf: url.path.split(separator: "/").map { String($0) })
        let generator = components.makeIterator()
        var parameters = Parameters()
        if let handle = root.findHandler(current: "", generator: generator, parameters: &parameters) {
            return (handle, parameters)
        }
        return nil
    }
}

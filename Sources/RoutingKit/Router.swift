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
    func request<T: Body>(_ body: T) throws -> T.Response
    func request(url: URL) throws -> Any
}

public enum RoutingError: Error {
    case notFound
}

private func erase<T: Body>(_ handler: @escaping RequestHandler<T>) -> AnyRequestHandler {
    { try handler($0 as! T) }
}

public final class Router: Routing {
    public static let `default` = Router()
    struct Service {
        public var scheme: String
        public var host: Host
        var root: RouteNode = .init()
        public init(scheme: String, host: Host) {
            self.scheme = scheme
            self.host = host
        }

        struct ID: Hashable {
            var scheme: String
            var host: Host
        }

        var id: ID { .init(scheme: scheme, host: host) }
    }

    private var services = [Service.ID: Service]()
    private var resolversByType: [ObjectIdentifier: AnyRequestHandler] = [:]

    public init() {}

    func findService(for url: URL) -> Service? {
        services.values.first { $0.canHandle(url: url) }
    }

    func findHandler(for url: URL) -> (URLRequestHandler, Parameters)? {
        findService(for: url)?.findHandlers(url: url)
    }

    public func register<T>(_ type: T.Type, handler: @escaping (T) throws -> T.Response) where T: Body {
        resolversByType[ObjectIdentifier(type)] = erase(handler)
    }

    public func register<T>(_ type: T.Type, handler: @escaping (T) throws -> T.Response) where T: URLDecodableBody {
        resolversByType[ObjectIdentifier(type)] = erase(handler)
        service(for: type.scheme, host: type.host)
            .add(route: Route(uri: type.uri, handler: handler))
    }

    public func request<T>(_ body: T) throws -> T.Response where T: Body {
        guard let resolver = resolversByType[ObjectIdentifier(T.self)] else {
            throw RoutingError.notFound
        }
        return try resolver(body) as! T.Response
    }

    public func request(url: URL) throws -> Any {
        guard let (handler, params) = findHandler(for: url) else {
            throw RoutingError.notFound
        }
        return try handler(url, params)
    }

    public func canHandle(url: URL) -> Bool {
        findHandler(for: url) != nil
    }

    func service(for scheme: String, host: Host) -> Service {
        let id = Service.ID(scheme: scheme, host: host)
        if let service = services[id] { return service }
        let service = Service(scheme: scheme, host: host)
        services[id] = service
        return service
    }
}

extension Router.Service {
    func canHandle(url: URL) -> Bool {
        guard let sourceScheme = url.scheme,
              let sourceHost = url.host
        else {
            return false
        }
        return sourceScheme.caseInsensitiveCompare(scheme) == .orderedSame
            && host.isMatch(host: sourceHost)
    }

    func findHandlers(url: URL) -> (URLRequestHandler, Parameters)? {
        let generator = url.path.split(separator: "/").map { String($0) }.makeIterator()
        var parameters = Parameters()
        if let handle = root.findHandler(current: "", generator: generator, parameters: &parameters) {
            return (handle, parameters)
        }
        return nil
    }

    func add(route: AnyRoute) {
        root.add(route: route)
    }
}

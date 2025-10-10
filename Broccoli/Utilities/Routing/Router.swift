//
//  Router.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//

import SwiftUI
import Combine   // ✅ make sure Combine is imported

final class Router: ObservableObject {
    static let shared = Router()

    // Required by ObservableObject (usually auto-synthesized)
    let objectWillChange = PassthroughSubject<Void, Never>()

    @Published var path = NavigationPath() {
        willSet { objectWillChange.send() }
    }

    private var stack: [Route] = []

    private init() {}

    // MARK: - Computed helpers
    var top: Route? { stack.last }
    var isEmpty: Bool { stack.isEmpty }

    // MARK: - Navigation Actions

    func push(_ route: Route) {
        stack.append(route)
        path.append(route)
        objectWillChange.send()
    }

    func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
        path.removeLast()
        objectWillChange.send()
    }

    func popToRoot() {
        stack.removeAll()
        path = NavigationPath()
        objectWillChange.send()
    }

    func popTo(_ route: Route) {
        guard let index = stack.lastIndex(of: route) else { return }
        let removeCount = stack.count - index - 1
        guard removeCount > 0 else { return }

        stack.removeLast(removeCount)
        var newPath = NavigationPath()
        for r in stack { newPath.append(r) }
        path = newPath
        objectWillChange.send()
    }

    func setStack(_ routes: [Route]) {
        stack = routes
        var newPath = NavigationPath()
        for r in routes { newPath.append(r) }
        path = newPath
        objectWillChange.send()
    }
}

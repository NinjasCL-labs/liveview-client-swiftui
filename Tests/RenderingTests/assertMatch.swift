//
//  assertMatch.swift
//  
//
//  Created by Carson Katri on 1/10/23.
//

import XCTest
import SwiftUI
import Foundation
@testable import LiveViewNative
import LiveViewNativeCore

@MainActor
func assertMatch(
    _ markup: String,
    _ file: String = #file,
    _ line: Int = #line,
    _ function: StaticString = #function,
    environment: @escaping (inout EnvironmentValues) -> () = { _ in },
    size: CGSize? = nil,
    @ViewBuilder _ view: () -> some View
) throws {
    try assertMatch(name: "\(URL(filePath: file).lastPathComponent)-\(line)-\(function)", markup, environment: environment, size: size, view)
}

@MainActor
func assertMatch(
    name: String,
    _ markup: String,
    environment: @escaping (inout EnvironmentValues) -> () = { _ in },
    size: CGSize? = nil,
    @ViewBuilder _ view: () -> some View
) throws {
    let session = LiveSessionCoordinator(URL(string: "http://localhost")!)
    let document = try LiveViewNativeCore.Document.parse(markup)
    let viewTree = session.rootCoordinator.builder.fromNodes(
        document[document.root()].children(),
        context: LiveContext(coordinator: session.rootCoordinator, url: session.url)
    ).environment(\.coordinatorEnvironment, CoordinatorEnvironment(session.rootCoordinator, document: document))
    let markupImage = ImageRenderer(content: viewTree.transformEnvironment(\.self, transform: environment).frame(width: size?.width, height: size?.height)).uiImage?.pngData()
    let viewImage = ImageRenderer(content: view().transformEnvironment(\.self, transform: environment).frame(width: size?.width, height: size?.height)).uiImage?.pngData()
    
    if markupImage == viewImage {
        XCTAssert(true)
    } else {
        let markupURL = URL.temporaryDirectory.appendingPathComponent("\(name)_markup", conformingTo: .png)
        let viewURL = URL.temporaryDirectory.appendingPathComponent("\(name)_view", conformingTo: .png)
        try markupImage?.write(to: markupURL)
        try viewImage?.write(to: viewURL)
        XCTAssert(false, "Rendered views did not match. Outputs saved to \(markupURL.path()) and \(viewURL.path())")
    }
}

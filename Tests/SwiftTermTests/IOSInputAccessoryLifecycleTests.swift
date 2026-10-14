#if os(iOS) || os(visionOS)
import UIKit
import Testing
@testable import SwiftTerm

@Suite(.serialized)
@MainActor
struct IOSInputAccessoryLifecycleTests {
    private func makeView() -> TerminalView {
        TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    }

    @Test func detachedViewDoesNotCreateKeyboardAccessory() {
        let view = makeView()
        #expect(view.window == nil)
        #expect(view._inputAccessory == nil)
        #expect(view.inputAccessoryView == nil)
    }

    @Test func defaultAccessoryIsCreatedOnceAfterWindowAttachment() {
        let view = makeView()
        let window = UIWindow(frame: view.bounds)
        window.addSubview(view)
        #expect(view.window === window)
        let accessory = view.inputAccessoryView
        #expect(accessory is TerminalAccessory)
        #expect(view.inputAccessoryView === accessory)
        view.removeFromSuperview()
        window.addSubview(view)
        #expect(view.inputAccessoryView === accessory)
    }

    @Test func explicitNilAccessorySurvivesAttachment() {
        let view = makeView()
        view.inputAccessoryView = nil
        let window = UIWindow(frame: view.bounds)
        window.addSubview(view)
        #expect(view.inputAccessoryView == nil)
        view.removeFromSuperview()
        window.addSubview(view)
        #expect(view.inputAccessoryView == nil)
    }

    @Test func hostAccessorySurvivesAttachmentAndReplacement() {
        let view = makeView()
        let accessory = UIView()
        view.inputAccessoryView = accessory
        let window = UIWindow(frame: view.bounds)
        window.addSubview(view)
        #expect(view.inputAccessoryView === accessory)
        view.removeFromSuperview()
        window.addSubview(view)
        #expect(view.inputAccessoryView === accessory)
        view.inputAccessoryView = nil
        #expect(view.inputAccessoryView == nil)
    }

    #if !os(visionOS)
    @Test func shortcutsAreClearedOnEveryAttachment() {
        let view = makeView()
        let button = UIBarButtonItem(title: "Host", style: .plain, target: nil, action: nil)
        let group = UIBarButtonItemGroup(barButtonItems: [button], representativeItem: nil)
        view.inputAssistantItem.leadingBarButtonGroups = [group]
        view.inputAssistantItem.trailingBarButtonGroups = [group]
        let window = UIWindow(frame: view.bounds)
        window.addSubview(view)
        #expect(view.inputAssistantItem.leadingBarButtonGroups.isEmpty)
        #expect(view.inputAssistantItem.trailingBarButtonGroups.isEmpty)
        view.removeFromSuperview()
        view.inputAssistantItem.leadingBarButtonGroups = [group]
        view.inputAssistantItem.trailingBarButtonGroups = [group]
        window.addSubview(view)
        #expect(view.inputAssistantItem.leadingBarButtonGroups.isEmpty)
        #expect(view.inputAssistantItem.trailingBarButtonGroups.isEmpty)
    }
    #endif
}
#endif

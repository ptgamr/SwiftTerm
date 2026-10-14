#if os(iOS) || os(visionOS)
import UIKit
import Testing
@testable import SwiftTerm

@Suite(.serialized)
@MainActor
struct IOSProgramScrollGestureTests {
    @Test func hostScrollRoutingSurvivesBufferAndMouseModeChanges() {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 640, height: 320))
        let pointer = UIPanGestureRecognizer()
        pointer.allowedScrollTypesMask = .continuous
        view.addGestureRecognizer(pointer)
        view.managesProgramScrollGestures = false
        view.feed(text: "\u{1b}[?1049h\u{1b}[?1002h\u{1b}[?1006h")
        view.applyTerminalEvent(.bufferActivated)
        #expect(view.panMouseGesture == nil)
        #expect(!view.shouldCapturePointerScroll(pointer))
        #expect(view.panGestureRecognizer.minimumNumberOfTouches == 1)
        #expect(view.terminalInputStateSnapshot()?.mouseMode == .buttonEventTracking)
        view.allowMouseReporting = false
        view.allowMouseReporting = true
        #expect(view.panMouseGesture == nil)
        #expect(!view.shouldCapturePointerScroll(pointer))

        view.managesProgramScrollGestures = true
        #expect(view.panMouseGesture != nil)
        #expect(view.shouldCapturePointerScroll(pointer))
        view.managesProgramScrollGestures = false
        #expect(view.panMouseGesture == nil)
        #expect(!view.shouldCapturePointerScroll(pointer))
        view.feed(text: "\u{1b}[?1049l\u{1b}[?1002l")
        view.applyTerminalEvent(.bufferActivated)
        #expect(view.panMouseGesture == nil)
        #expect(!view.shouldCapturePointerScroll(pointer))
        #expect(view.panGestureRecognizer.minimumNumberOfTouches == 1)
    }
}
#endif

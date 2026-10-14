#if os(iOS) || os(visionOS)
import UIKit
import Testing
@testable import SwiftTerm

@MainActor
@Suite(.serialized)
struct IOSKittyRendererTests {
    @Test(arguments: [false, true], [false, true])
    func topFirstImageRowsStayUpright(png: Bool, virtual: Bool) throws {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 240, height: 120))
        let window = UIWindow(frame: view.frame)
        window.rootViewController = UIViewController()
        window.rootViewController!.view.addSubview(view)
        window.isHidden = false
        defer { window.isHidden = true }
        view.resize(cols: 10, rows: 4)

        let rgba: [UInt8] = [255, 0, 0, 255, 0, 0, 255, 255]
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        let data: Data
        if png {
            data = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 2), format: format).pngData { context in
                context.cgContext.setFillColor(UIColor.red.cgColor)
                context.cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
                context.cgContext.setFillColor(UIColor.blue.cgColor)
                context.cgContext.fill(CGRect(x: 0, y: 1, width: 1, height: 1))
            }
        } else {
            data = Data(rgba)
        }
        let imageFormat = png ? "f=100" : "f=32,s=1,v=2"
        let virtualControl = virtual ? ",U=1" : ""
        view.feed(text: "\u{1b}_Ga=T,\(imageFormat),i=1,c=1,r=2,C=1\(virtualControl);\(data.base64EncodedString())\u{1b}\\")
        if virtual {
            let first = String(UnicodeScalar(KittyPlaceholder.diacritics[0])!)
            let second = String(UnicodeScalar(KittyPlaceholder.diacritics[1])!)
            view.feed(text: "\u{1b}[38;2;0;0;1m\u{10EEEE}\(first)\(first)\r\n\u{10EEEE}\(second)\(first)")
        }
        let stored = try #require(view.withTerminal { $0.kittyGraphicsRenderSnapshot() }.imagesById[1])
        #expect(stored.rgba == rgba, "Decoding must preserve Kitty's top-first pixel rows")
        view.frameTick()
        let rendered = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            view.draw(view.bounds)
        }
        let bitmap = try #require(rendered.cgImage)
        var pixels = [UInt8](repeating: 0, count: bitmap.width * bitmap.height * 4)
        let context = try #require(CGContext(data: &pixels, width: bitmap.width, height: bitmap.height,
                                            bitsPerComponent: 8, bytesPerRow: bitmap.width * 4,
                                            space: CGColorSpaceCreateDeviceRGB(),
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(bitmap, in: CGRect(x: 0, y: 0, width: bitmap.width, height: bitmap.height))
        let red = stride(from: 0, to: pixels.count, by: 4).filter {
            pixels[$0] > 200 && pixels[$0 + 1] < 30 && pixels[$0 + 2] < 30
        }
        let blue = stride(from: 0, to: pixels.count, by: 4).filter {
            pixels[$0] < 30 && pixels[$0 + 1] < 30 && pixels[$0 + 2] > 200
        }
        #expect(red.count > 20)
        #expect(blue.count > 20)
        guard !red.isEmpty, !blue.isEmpty else { return }
        func averageRow(_ offsets: [Int]) -> Double {
            Double(offsets.reduce(0) { $0 + ($1 / 4 / bitmap.width) }) / Double(offsets.count)
        }
        #expect(averageRow(red) < averageRow(blue), "The red top row must paint above the blue bottom row")
    }
}
#endif

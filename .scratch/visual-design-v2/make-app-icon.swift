// Generates the two 1024 app-icon PNGs (light, dark) for visual-design-v2 ticket 02.
// Brush-written 读 in a full-bleed 田字格 with a 日 chop. Run from the repo root:
//   swift .scratch/visual-design-v2/make-app-icon.swift PersonalSchedule/Assets.xcassets/AppIcon.appiconset
// This is a one-off tool. It lives in .scratch and is NEVER copied into PersonalSchedule/ (that ships).
import AppKit
import CoreText

let side: CGFloat = 1024
let fontURL = URL(fileURLWithPath: "PersonalSchedule/Fonts/MaShanZheng-Regular.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// Draw one glyph centred in `rect` using the brush face.
func drawGlyph(_ s: String, in rect: CGRect, size: CGFloat, color fill: CGColor, ctx: CGContext,
               rotation: CGFloat = 0) {
    let font = CTFontCreateWithName("MaShanZheng-Regular" as CFString, size, nil)
    let attr = NSAttributedString(string: s, attributes: [
        .font: font, .foregroundColor: fill,
    ])
    let line = CTLineCreateWithAttributedString(attr)
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    ctx.saveGState()
    if rotation != 0 {
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: rotation)
        ctx.translateBy(x: -rect.midX, y: -rect.midY)
    }
    ctx.textPosition = CGPoint(x: rect.midX - bounds.midX, y: rect.midY - bounds.midY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func icon(dark: Bool) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    // No alpha channel: the 1024 marketing icon is rejected by App Store validation if it has one.
    let ctx = CGContext(data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // Ground
    ctx.setFillColor(color(dark ? 0x1C1A17 : 0xFAF6EC))
    ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

    // 田字格: dashed cross then the border at the icon edge. Red matches LogoView's Theme.red per mode.
    let redHex: UInt32 = dark ? 0xA3362E : 0xC8382E
    let lineW = side * 0.028
    ctx.setStrokeColor(color(redHex, 0.45))
    ctx.setLineWidth(side * 0.009)
    ctx.setLineDash(phase: 0, lengths: [side * 0.032, side * 0.032])
    ctx.move(to: CGPoint(x: 0, y: side / 2)); ctx.addLine(to: CGPoint(x: side, y: side / 2))
    ctx.move(to: CGPoint(x: side / 2, y: 0)); ctx.addLine(to: CGPoint(x: side / 2, y: side))
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])
    ctx.setStrokeColor(color(redHex))
    ctx.setLineWidth(lineW)
    ctx.stroke(CGRect(x: lineW / 2, y: lineW / 2, width: side - lineW, height: side - lineW))

    // 读, brush, ~70% of the cell.
    drawGlyph("读", in: CGRect(x: 0, y: 0, width: side, height: side), size: side * 0.74,
              color: color(dark ? 0xE8DEC5 : 0x1C1A17), ctx: ctx)

    // 日 chop, bottom-right, slightly rotated.
    let chop = side * 0.17
    let margin = side * 0.085
    let chopRect = CGRect(x: side - margin - chop, y: margin, width: chop, height: chop)
    ctx.saveGState()
    ctx.translateBy(x: chopRect.midX, y: chopRect.midY)
    ctx.rotate(by: -6 * .pi / 180)
    ctx.translateBy(x: -chopRect.midX, y: -chopRect.midY)
    let chopPath = CGPath(roundedRect: chopRect, cornerWidth: chop * 0.16, cornerHeight: chop * 0.16, transform: nil)
    ctx.addPath(chopPath)
    ctx.setFillColor(color(dark ? 0x6E2419 : 0x8B2A1F))   // sealRed per mode, matching LogoView
    ctx.fillPath()
    ctx.restoreGState()
    // 日 in cream (Theme.onRed) in both modes, matching LogoView — cream on red reads at icon scale.
    drawGlyph("日", in: chopRect, size: chop * 0.82, color: color(0xFAF6EC), ctx: ctx,
              rotation: -6 * .pi / 180)

    return ctx.makeImage()!
}

func write(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(path)")
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
write(icon(dark: false), to: "\(outDir)/AppIcon.png")
write(icon(dark: true), to: "\(outDir)/AppIcon-Dark.png")

import Cocoa

// MARK: - Image helpers

/// Draw an emoji/text into an NSImage so the app works even without art files.
func makeEmojiImage(_ text: String, size: CGFloat = 256) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * 0.7),
        .paragraphStyle: style,
    ]
    let str = text as NSString
    let bounds = str.size(withAttributes: attrs)
    str.draw(at: NSPoint(x: (size - bounds.width) / 2, y: (size - bounds.height) / 2),
             withAttributes: attrs)
    img.unlockFocus()
    return img
}

func loadImage(_ name: String, fallbackEmoji: String) -> NSImage {
    if let url = Bundle.main.url(forResource: name, withExtension: "png"),
       let img = NSImage(contentsOf: url) {
        return img
    }
    return makeEmojiImage(fallbackEmoji)
}

// MARK: - Cat type

enum CatType: String, CaseIterable {
    case black, white

    var displayName: String {
        switch self {
        case .black: return "검은 고양이"
        case .white: return "흰 고양이"
        }
    }

    var fallbackEmoji: (closed: String, open: String) {
        switch self {
        case .black: return ("🐱", "😮")
        case .white: return ("🐈", "😮")
        }
    }
}

// MARK: - Cat dock tile

final class CatTile {
    private let dockTile = NSApp.dockTile
    private let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 128, height: 128))

    private var closedImage: NSImage   // mouth closed (chewing)
    private var openImage: NSImage     // mouth open (resting state)

    /// How long the mouth stays shut while "swallowing", in seconds.
    private let chewDuration = 0.30

    private static let defaultsKey = "catType"
    private(set) var catType: CatType

    init() {
        let saved = UserDefaults.standard.string(forKey: CatTile.defaultsKey)
            .flatMap(CatType.init(rawValue:)) ?? .black
        self.catType = saved
        (self.closedImage, self.openImage) = CatTile.images(for: saved)
    }

    private static func images(for type: CatType) -> (closed: NSImage, open: NSImage) {
        let closed = loadImage("\(type.rawValue)_idle", fallbackEmoji: type.fallbackEmoji.closed)
        let open = loadImage("\(type.rawValue)_open", fallbackEmoji: type.fallbackEmoji.open)
        return (closed, open)
    }

    /// Switch the cat breed, persist the choice, and reflect it in the Dock immediately.
    func setCatType(_ type: CatType) {
        guard type != catType else { return }
        catType = type
        UserDefaults.standard.set(type.rawValue, forKey: CatTile.defaultsKey)
        (closedImage, openImage) = CatTile.images(for: type)
        show(openImage)            // resting state = mouth open
    }

    func setup() {
        imageView.imageScaling = .scaleProportionallyUpOrDown
        show(openImage)            // resting state = mouth open
        dockTile.contentView = imageView
        dockTile.display()
    }

    private func show(_ image: NSImage) {
        imageView.image = image
        dockTile.display()
    }

    /// Eat = delete immediately, then play close → open as a quick chew animation.
    func eat(_ urls: [URL]) {
        trash(urls)                // delete right away (trashItem is ~instant)
        show(closedImage)          // close mouth on the bite
        Timer.scheduledTimer(withTimeInterval: chewDuration, repeats: false) { [weak self] _ in
            self?.show(self?.openImage ?? NSImage())  // re-open after the chew
        }
    }

    /// Just a click: close the mouth briefly, then open it again. No deletion.
    func chomp() {
        show(closedImage)
        Timer.scheduledTimer(withTimeInterval: chewDuration, repeats: false) { [weak self] _ in
            self?.show(self?.openImage ?? NSImage())
        }
    }

    private func trash(_ urls: [URL]) {
        for url in urls {
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            } catch {
                NSLog("catbin: failed to trash \(url.path): \(error)")
            }
        }
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    let cat = CatTile()

    func applicationDidFinishLaunching(_ notification: Notification) {
        cat.setup()
    }

    // Files dropped on the Dock icon.
    func application(_ application: NSApplication, open urls: [URL]) {
        cat.eat(urls)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        cat.eat(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    // Plain click on the Dock icon (app already running, no windows).
    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        cat.chomp()
        return true
    }

    // Right-click on the Dock icon → choose the cat breed.
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let header = NSMenuItem(title: "고양이 종류", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for type in CatType.allCases {
            let item = NSMenuItem(title: type.displayName,
                                  action: #selector(chooseCat(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = type.rawValue
            item.state = (cat.catType == type) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    @objc private func chooseCat(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let type = CatType(rawValue: raw) else { return }
        cat.setCatType(type)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

// MARK: - Entry point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

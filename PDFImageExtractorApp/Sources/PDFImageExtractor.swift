import AppKit
import UniformTypeIdentifiers

final class DropView: NSView {
    var onPDFsDropped: (([URL]) -> Void)?
    var isHovering = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = readPDFURLs(sender)
        isHovering = !urls.isEmpty
        return urls.isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHovering = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isHovering = false
        let urls = readPDFURLs(sender)
        if !urls.isEmpty {
            onPDFsDropped?(urls)
            return true
        }
        return false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = bounds.insetBy(dx: 24, dy: 24)
        let path = NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18)
        (isHovering ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor).setFill()
        path.fill()
        (isHovering ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = 1.5
        let dash: [CGFloat] = [8, 6]
        path.setLineDash(dash, count: dash.count, phase: 0)
        path.stroke()
    }

    private func readPDFURLs(_ sender: NSDraggingInfo) -> [URL] {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return []
        }
        return items.filter { $0.pathExtension.lowercased() == "pdf" }
    }
}

final class PanelView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 12
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.45).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let statusLabel = NSTextField(labelWithString: "拖入 PDF，使用 pdffigures2 提取 Figure 和 Table")
    private let detailLabel = NSTextField(labelWithString: "结果会保存到 PDF 同级目录，按文件名创建 *_pdffigures2 文件夹。")
    private let logView = NSTextView()
    private let progress = NSProgressIndicator()
    private let openButton = NSButton(title: "打开结果文件夹", target: nil, action: nil)
    private var lastOutputURL: URL?
    private var isRunning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return true
        }

        showMainWindow()
        return true
    }

    private func showMainWindow() {
        if window == nil {
            buildWindow()
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildWindow() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 860, height: 620))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let dropView = DropView(frame: NSRect(x: 24, y: 232, width: 812, height: 356))
        dropView.onPDFsDropped = { [weak self] urls in
            self?.handlePDFs(urls)
        }
        content.addSubview(dropView)

        let icon = NSImageView(frame: NSRect(x: 398, y: 474, width: 64, height: 64))
        icon.image = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "PDF")
        icon.contentTintColor = .tertiaryLabelColor
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 52, weight: .regular)
        content.addSubview(icon)

        let title = NSTextField(labelWithString: "PDF 图片提取器")
        title.font = NSFont.systemFont(ofSize: 30, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 170, y: 426, width: 520, height: 40)
        content.addSubview(title)

        statusLabel.font = NSFont.systemFont(ofSize: 17, weight: .medium)
        statusLabel.textColor = .labelColor
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 150, y: 386, width: 560, height: 26)
        content.addSubview(statusLabel)

        detailLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center
        detailLabel.lineBreakMode = .byTruncatingMiddle
        detailLabel.frame = NSRect(x: 118, y: 354, width: 624, height: 22)
        content.addSubview(detailLabel)

        let chooseButton = NSButton(title: "选择 PDF", target: self, action: #selector(choosePDF))
        chooseButton.bezelStyle = .rounded
        chooseButton.controlSize = .large
        chooseButton.frame = NSRect(x: 346, y: 306, width: 168, height: 36)
        content.addSubview(chooseButton)

        progress.style = .spinning
        progress.controlSize = .regular
        progress.isDisplayedWhenStopped = false
        progress.frame = NSRect(x: 418, y: 270, width: 24, height: 24)
        content.addSubview(progress)

        let logPanel = PanelView(frame: NSRect(x: 32, y: 24, width: 572, height: 176))
        content.addSubview(logPanel)

        let logTitle = NSTextField(labelWithString: "提取日志")
        logTitle.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        logTitle.textColor = .labelColor
        logTitle.frame = NSRect(x: 18, y: 142, width: 160, height: 22)
        logPanel.addSubview(logTitle)

        let logScroll = NSScrollView(frame: NSRect(x: 16, y: 16, width: 540, height: 120))
        logScroll.borderType = .noBorder
        logScroll.hasVerticalScroller = true
        logScroll.drawsBackground = true
        logScroll.backgroundColor = .textBackgroundColor
        logView.isEditable = false
        logView.isSelectable = true
        logView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.textColor = .labelColor
        logView.backgroundColor = .textBackgroundColor
        logView.textContainerInset = NSSize(width: 10, height: 8)
        logView.isVerticallyResizable = true
        logView.isHorizontallyResizable = false
        logView.minSize = NSSize(width: 0, height: 120)
        logView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        logView.frame = NSRect(x: 0, y: 0, width: 540, height: 120)
        logView.autoresizingMask = [.width]
        logView.textContainer?.containerSize = NSSize(width: 520, height: CGFloat.greatestFiniteMagnitude)
        logView.textContainer?.widthTracksTextView = true
        logView.string = "等待提取日志..."
        logScroll.documentView = logView
        logPanel.addSubview(logScroll)

        let actionPanel = PanelView(frame: NSRect(x: 628, y: 24, width: 200, height: 176))
        content.addSubview(actionPanel)

        let actionTitle = NSTextField(labelWithString: "结果操作")
        actionTitle.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        actionTitle.textColor = .labelColor
        actionTitle.frame = NSRect(x: 18, y: 142, width: 120, height: 22)
        actionPanel.addSubview(actionTitle)

        let actionHint = NSTextField(wrappingLabelWithString: "提取完成后，可直接打开输出文件夹。")
        actionHint.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        actionHint.textColor = .secondaryLabelColor
        actionHint.frame = NSRect(x: 18, y: 88, width: 164, height: 40)
        actionPanel.addSubview(actionHint)

        openButton.target = self
        openButton.action = #selector(openResultFolder)
        openButton.bezelStyle = .rounded
        openButton.controlSize = .large
        openButton.isEnabled = false
        openButton.frame = NSRect(x: 18, y: 28, width: 164, height: 36)
        actionPanel.addSubview(openButton)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "PDF 图片提取器"
        window.isReleasedWhenClosed = false
        window.contentView = content
        window.minSize = NSSize(width: 760, height: 560)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func choosePDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { [weak self] response in
            if response == .OK {
                self?.handlePDFs(panel.urls)
            }
        }
    }

    private func handlePDFs(_ urls: [URL]) {
        guard !isRunning else { return }
        guard !urls.isEmpty else { return }
        isRunning = true
        openButton.isEnabled = false
        progress.startAnimation(nil)
        statusLabel.stringValue = "正在提取..."
        detailLabel.stringValue = urls.map(\.lastPathComponent).joined(separator: ", ")
        logView.string = "启动 pdffigures2...\n待处理文件：\(urls.map(\.lastPathComponent).joined(separator: ", "))\n"

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runExtractor(urls)
            DispatchQueue.main.async {
                self.progress.stopAnimation(nil)
                self.isRunning = false
                self.logView.string = result.log
                if result.success {
                    self.statusLabel.stringValue = "提取完成"
                    self.detailLabel.stringValue = result.summary
                    self.lastOutputURL = result.outputURL
                    self.openButton.isEnabled = result.outputURL != nil
                } else {
                    self.statusLabel.stringValue = "提取失败"
                    self.detailLabel.stringValue = "请确认本机 Java 可用，并且 app 内置 pdffigures2.jar。"
                    self.openButton.isEnabled = false
                }
            }
        }
    }

    private func runExtractor(_ urls: [URL]) -> (success: Bool, log: String, summary: String, outputURL: URL?) {
        guard let resources = Bundle.main.resourceURL else {
            return (false, "找不到应用资源目录。", "", nil)
        }
        let javaURL = resources.appendingPathComponent("jre/bin/java")
        let jarURL = resources.appendingPathComponent("pdffigures2.jar")
        guard FileManager.default.isExecutableFile(atPath: javaURL.path) else {
            return (false, "找不到内置 Java runtime：\(javaURL.path)", "", nil)
        }
        guard FileManager.default.fileExists(atPath: jarURL.path) else {
            return (false, "找不到内置 pdffigures2.jar：\(jarURL.path)", "", nil)
        }

        var logs: [String] = []
        var summaries: [String] = []
        var lastOutputURL: URL?

        for pdfURL in urls {
            let outputURL = pdfURL.deletingLastPathComponent()
                .appendingPathComponent("\(safeName(pdfURL.deletingPathExtension().lastPathComponent))_pdffigures2")
            let figuresURL = outputURL.appendingPathComponent("figures")
            let dataURL = outputURL.appendingPathComponent("figure_data")

            do {
                try FileManager.default.createDirectory(at: figuresURL, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true)
            } catch {
                return (false, "创建输出目录失败：\(error.localizedDescription)", "", nil)
            }

            let process = Process()
            process.executableURL = javaURL
            process.arguments = [
                "-jar", jarURL.path,
                "-q",
                "-e",
                "-i", "150",
                "-m", figuresURL.path + "/",
                "-d", dataURL.path + "/",
                pdfURL.path
            ]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                return (false, "启动 pdffigures2 失败：\(error.localizedDescription)", "", nil)
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                logs.append("== \(pdfURL.lastPathComponent) ==\n\(output.isEmpty ? "pdffigures2 未返回错误详情。" : output)")
                return (false, logs.joined(separator: "\n"), "", nil)
            }

            let count = countPNGFiles(in: figuresURL)
            summaries.append("\(pdfURL.lastPathComponent)：Figure/Table \(count)")
            let visibleOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
            let section = """
            == \(pdfURL.lastPathComponent) ==
            输出目录：\(outputURL.path)
            提取图片：\(count) 个
            \(visibleOutput.isEmpty ? "pdffigures2 未返回详细日志。" : visibleOutput)
            """
            logs.append(section)
            lastOutputURL = outputURL
        }

        return (true, logs.joined(separator: "\n"), summaries.joined(separator: "；"), lastOutputURL)
    }

    private func safeName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let name = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return name.isEmpty ? "pdf" : name
    }

    private func countPNGFiles(in directory: URL) -> Int {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension.lowercased() == "png" }.count
    }

    @objc private func openResultFolder() {
        guard let lastOutputURL else { return }
        NSWorkspace.shared.open(lastOutputURL)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()

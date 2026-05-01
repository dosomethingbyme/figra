import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct BibMergeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Header(title: "合并 BibTeX", subtitle: "选择或拖入多个 .bib 文件，按列表顺序合并为一个文件。") {
                HStack {
                    Button("添加 BibTeX") {
                        model.addBibFiles(chooseBibFiles())
                    }
                    Button("清空") {
                        model.clearBibItems()
                    }
                    .disabled(model.bibItems.isEmpty || model.isWorking)
                }
            }

            FileDropTarget(
                title: "拖入多个 .bib 文件",
                subtitle: "导出时每个文件内容之间保留一个空行。",
                symbol: "text.badge.plus",
                acceptedTypes: [.fileURL, .url, bibContentType()],
                allowedExtensions: ["bib"],
                fileRepresentationType: bibContentType(),
                temporaryDirectoryName: "FigraDroppedBibFiles",
                temporaryExtension: "bib"
            ) { urls in
                model.addBibFiles(urls)
            }

            Text(model.bibStatus).foregroundStyle(.secondary)

            HStack(spacing: 12) {
                BibStatCard(title: "Bib 文件", value: "\(model.bibItems.count)")
                BibStatCard(title: "输入参考文献", value: "\(model.bibPreviewSummary.inputReferenceCount)")
                BibStatCard(title: "重复项", value: "\(model.bibPreviewSummary.duplicateReferenceCount)")
                BibStatCard(title: "生成参考文献", value: "\(model.bibPreviewSummary.outputReferenceCount)")
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Picker("重复项", selection: $model.bibDuplicatePolicy) {
                        ForEach(BibDuplicatePolicy.allCases) { policy in
                            Text(policy.rawValue).tag(policy)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                    Spacer()
                    DuplicateMetricBadge(title: "引用键", value: model.bibPreviewSummary.duplicateKeyMatchCount)
                    DuplicateMetricBadge(title: "标题", value: model.bibPreviewSummary.duplicateTitleMatchCount)
                }
            }
            .padding(14)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.18)))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if model.bibItems.isEmpty {
                EmptyState(symbol: "text.book.closed", title: "未添加 BibTeX", message: "选择或拖入多个 .bib 文件后，这里会显示合并顺序。")
            } else {
                List {
                    ForEach(model.bibItems) { item in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                            VStack(alignment: .leading) {
                                Text(item.url.lastPathComponent).font(.headline)
                                Text("\(item.referenceCount) 篇参考文献 · \(formatFileSize(item.fileSize))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("上移") { model.moveBibItemUp(item) }
                            Button("下移") { model.moveBibItemDown(item) }
                            Button("移除") { model.removeBibItem(item) }
                        }
                        .padding(.vertical, 6)
                    }
                    .onMove(perform: model.moveBibItem)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack {
                Button(exportButtonTitle) { model.exportMergedBib() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.bibItems.count < 2 || model.isWorking)
                if let outputURL = model.bibOutputURL {
                    Button("在 Finder 中显示") {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }
                Spacer()
            }
        }
        .padding(28)
    }

    private var exportButtonTitle: String {
        model.bibDuplicatePolicy == .keyAndTitle ? "导出去重 BibTeX" : "导出合并 BibTeX"
    }
}

private struct BibStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.18)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DuplicateMetricBadge: View {
    let title: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }
}

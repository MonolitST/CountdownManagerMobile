import ImageIO
import QuickLook
import SwiftUI

struct PlanAttachmentAddButton: View {
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: compact ? 4 : 9) {
                DesignIcon(.attachmentAdd)
                Text(compact ? String(localized: "Add") : String(localized: "Add attachment"))
                    .brandFont(14, weight: .medium, relativeTo: .subheadline)
            }
            .foregroundStyle(Palette.accentText)
            .padding(.horizontal, compact ? 2 : 13)
            .padding(.vertical, 8)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 44 : 48, alignment: .leading)
            .background {
                if !compact {
                    RoundedRectangle(cornerRadius: 12).fill(Palette.surface)
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.outline, lineWidth: 1) }
                }
            }
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("plan.attachments.add")
    }
}

struct ChecklistAttachmentButton: View {
    let count: Int
    let itemTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DesignIcon(.attachmentPaperclip)
                .foregroundStyle(Palette.accentText)
                .frame(width: 44, height: 44)
                .background(count == 0 ? .clear : Palette.inset, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Attach to checklist item"))
        .accessibilityHint(itemTitle)
        .accessibilityIdentifier("plan.attachments.checklist")
    }
}

struct PlanAttachmentList: View {
    @Environment(\.openURL) private var openURL
    @State private var previewURL: URL?
    @State private var missingFile = false
    let attachments: [PlanAttachment]
    let fileURL: (PlanAttachment) -> URL?
    var onRemove: ((PlanAttachment) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(attachments) { attachment in
                if attachment.id != attachments.first?.id {
                    Rectangle().fill(Palette.outline.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 7)
                        .accessibilityHidden(true)
                }
                HStack(spacing: 0) {
                    Button {
                        open(attachment)
                    } label: {
                        row(for: attachment)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("plan.attachments.open")

                    if let onRemove {
                        Button(role: .destructive) { onRemove(attachment) } label: {
                            DesignIcon(.checklistRemove)
                                .foregroundStyle(Palette.accentText)
                                .frame(width: 44, height: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Remove attachment"))
                        .accessibilityHint(attachment.name)
                        .accessibilityIdentifier("plan.attachments.remove")
                    }
                }
            }
        }
        .card(Palette.surface, cornerRadius: 12)
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.outline, lineWidth: 1).allowsHitTesting(false) }
        .quickLookPreview($previewURL)
        .alert("Attachment unavailable", isPresented: $missingFile) {
            Button("Close", role: .cancel) {}
        }
    }

    private func row(for attachment: PlanAttachment) -> some View {
        HStack(spacing: 10) {
            PlanAttachmentThumbnail(attachment: attachment, fileURL: fileURL(attachment))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: attachment.name)
                    .brandFont(14, weight: .medium, relativeTo: .subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle(for: attachment))
                    .brandFont(12, relativeTo: .caption)
                    .foregroundStyle(Palette.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            DesignIcon(.attachmentChevron).foregroundStyle(Palette.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private func subtitle(for attachment: PlanAttachment) -> String {
        switch attachment.contents {
        case let .link(url):
            return url.host(percentEncoded: false) ?? url.absoluteString
        case let .file(_, bytes):
            if attachment.isPhoto { return String(localized: "Photo") }
            let size = ByteCountFormatStyle(style: .file).locale(AppDate.locale).format(bytes)
            return String(localized: "PDF · \(size)")
        }
    }

    private func open(_ attachment: PlanAttachment) {
        if case let .link(url) = attachment.contents {
            openURL(url)
        } else if let url = fileURL(attachment), FileManager.default.isReadableFile(atPath: url.path(percentEncoded: false)) {
            previewURL = url
        } else {
            missingFile = true
        }
    }
}

private struct PlanAttachmentThumbnail: View {
    @State private var image: CGImage?
    let attachment: PlanAttachment
    let fileURL: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Palette.inset)
            if let image {
                Image(decorative: image, scale: 1).resizable().scaledToFill()
            } else {
                DesignIcon(icon).foregroundStyle(Palette.accentText)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
        .task(id: fileURL) {
            guard attachment.isPhoto, let fileURL else { return }
            let thumbnail = await Task.detached(priority: .utility) {
                guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil as CGImage? }
                return CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 108
                ] as CFDictionary)
            }.value
            if !Task.isCancelled { image = thumbnail }
        }
    }

    private var icon: ImageResource {
        if !attachment.isFile { return .attachmentLink }
        return attachment.isPhoto ? .attachmentPhoto : .attachmentFile
    }
}

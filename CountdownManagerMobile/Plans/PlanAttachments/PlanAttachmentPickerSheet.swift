import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

private enum PlanAttachmentOption: CaseIterable {
    case photo, file, link

    var title: LocalizedStringResource {
        switch self {
        case .photo: "Photo"
        case .file: "File"
        case .link: "Link"
        }
    }

    var icon: ImageResource {
        switch self {
        case .photo: .attachmentPhoto
        case .file: .attachmentFile
        case .link: .attachmentLink
        }
    }
}

enum PlanAttachmentSelection {
    case photos([PhotosPickerItem])
    case files(Result<[URL], Error>)
    case link(URL, String)
}

struct PlanAttachmentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var heightScale = 1.0
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showsPhotos = false
    @State private var showsFiles = false
    @State private var showsLink = false
    @State private var addedLink = false
    let checklistTitle: String?
    var tablet = false
    let onSelect: (PlanAttachmentSelection) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: tablet ? .leading : .center, spacing: tablet ? 7 : 5) {
                Text(checklistTitle == nil ? String(localized: "Add attachment") : String(localized: "Attach to checklist item"))
                    .font(tablet ? .custom("PTSerif-Regular", size: 26, relativeTo: .title2) : .headline)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, checklistTitle == nil ? 3 : 0)

                if let checklistTitle {
                    Text(checklistTitle)
                        .brandFont(14, relativeTo: .subheadline)
                        .foregroundStyle(Palette.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                }

                ForEach(PlanAttachmentOption.allCases, id: \.self) { option in
                    Button {
                        switch option {
                        case .photo: showsPhotos = true
                        case .file: showsFiles = true
                        case .link: showsLink = true
                        }
                    } label: {
                        HStack(spacing: 11) {
                            DesignIcon(option.icon).foregroundStyle(Palette.accentText)
                            Text(option.title).brandFont(15, weight: .medium, relativeTo: .subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                        .card(Palette.inset, cornerRadius: 11)
                        .contentShape(.rect(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }

                Button("Cancel", role: .cancel) { dismiss() }
                    .buttonStyle(.plain)
                    .brandFont(15, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(Palette.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: tablet ? .trailing : .center)
                    .contentShape(.rect)
                    .padding(.top, 3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .foregroundStyle(Palette.text)
        .presentationDetents([.height((checklistTitle == nil ? (tablet ? 300 : 256) : (tablet ? 330 : 280)) * heightScale), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(26)
        .presentationBackground(Palette.surface)
        .photosPicker(isPresented: $showsPhotos, selection: $selectedPhotos, matching: .images,
                      preferredItemEncoding: .current)
        .onChange(of: selectedPhotos) { _, photos in
            guard !photos.isEmpty else { return }
            onSelect(.photos(photos))
            dismiss()
        }
        .fileImporter(isPresented: $showsFiles, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: true) {
            onSelect(.files($0))
            dismiss()
        }
        .sheet(isPresented: $showsLink, onDismiss: { if addedLink { dismiss() } }) {
            PlanAttachmentLinkSheet { url, title in
                onSelect(.link(url, title))
                addedLink = true
            }
        }
    }
}

struct PlanAttachmentLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var title = ""
    let onAdd: (URL, String) -> Void

    var body: some View {
        let url = PlanAttachment.webURL(from: address)
        ConceptSheet(title: String(localized: "Add link"), height: 290) {
            TextField("Link URL", text: $address, prompt: Text(verbatim: "https://"))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .fieldSurface()
                .accessibilityIdentifier("plan.attachments.link.url")
            TextField("Title · optional", text: $title)
                .padding(12)
                .fieldSurface()
                .accessibilityIdentifier("plan.attachments.link.title")
            Button("Add") {
                if let url {
                    onAdd(url, title)
                    dismiss()
                }
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(url == nil)
            Button("Cancel", role: .cancel) { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accentText)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

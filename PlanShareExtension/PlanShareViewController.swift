import SwiftUI
import UIKit

final class PlanShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        let root = PlanShareView(model: PlanShareViewModel(providers: providers), onCancel: { [weak self] in
            self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
        }, onSaved: { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [])
        })
        let hosting = UIHostingController(rootView: root)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
}

private struct PlanShareView: View {
    @State private var selectedPlanID: UUID?
    @State private var saving: Task<Void, Never>?
    let model: PlanShareViewModel
    let onCancel: () -> Void
    let onSaved: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let plans = model.plans {
                    if plans.isEmpty {
                        ContentUnavailableView(
                            "No plans yet", systemImage: "calendar",
                            description: Text("Create a plan in Countdown Manager, then share the attachment again.")
                        )
                    } else {
                        List(plans) { plan in
                            selectRow(for: plan)
                        }
                        .disabled(model.isSaving)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        saving?.cancel()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSaving {
                        ProgressView()
                    } else {
                        Button("Save to plan", action: save)
                            .disabled(selectedPlanID == nil)
                            .accessibilityIdentifier("share.plan.save")
                    }
                }
            }
            .task { model.load() }
            .alert("Attachments", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("Close", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private func selectRow(for plan: Plan) -> some View {
        let isSelected = selectedPlanID == plan.id
        return Button {
            selectedPlanID = plan.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).font(.body)
                    Text(AppDate.full(plan.day)).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("share.plan.row")
    }

    private func save() {
        guard let selectedPlanID else { return }
        saving = Task {
            if await model.save(to: selectedPlanID) { onSaved() }
            saving = nil
        }
    }
}

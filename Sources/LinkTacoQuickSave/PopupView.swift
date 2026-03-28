import SwiftUI

struct PopupView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save to LinkTaco")
                .font(.headline)

            PopupTextField(
                text: $appState.draft.url,
                placeholder: "URL",
                fieldName: "url",
                captureID: appState.activeCaptureID,
                isDebugLoggingEnabled: appState.isDebugLoggingEnabled
            )
            PopupTextField(
                text: $appState.draft.title,
                placeholder: "Title",
                fieldName: "title",
                captureID: appState.activeCaptureID,
                isDebugLoggingEnabled: appState.isDebugLoggingEnabled
            )

            Text("Description")
                .font(.subheadline)
            PopupDescriptionTextView(
                text: $appState.draft.description,
                captureID: appState.activeCaptureID,
                isDebugLoggingEnabled: appState.isDebugLoggingEnabled
            )
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            PopupTextField(
                text: $appState.draft.tags,
                placeholder: "Tags (comma-separated)",
                fieldName: "tags",
                captureID: appState.activeCaptureID,
                isDebugLoggingEnabled: appState.isDebugLoggingEnabled
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Organization")
                    .font(.subheadline)

                Picker("Organization", selection: $appState.selectedOrganizationSlug) {
                    Text("Select organization").tag("")
                    ForEach(appState.activeOrganizations) { organization in
                        Text(organization.name).tag(organization.slug)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .disabled(appState.activeOrganizations.isEmpty)
                .onChange(of: appState.selectedOrganizationSlug) { newValue in
                    appState.handleSelectedOrganizationChange(newValue)
                }

                Text(appState.organizationPickerHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !appState.statusMessage.isEmpty {
                Text(appState.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    appState.isPopupVisible = false
                }
                Button("Save") {
                    appState.save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 520, height: 420)
        .onAppear {
            if appState.isDebugLoggingEnabled {
                AppLogger.logger.debug("popup_appeared id=\(appState.activeCaptureID, privacy: .public)")
            }
        }
        .onDisappear {
            if appState.isDebugLoggingEnabled {
                AppLogger.logger.debug("popup_disappeared id=\(appState.activeCaptureID, privacy: .public)")
            }
        }
    }
}

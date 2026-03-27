import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case quickSave = "Quick Save"
    case search = "Search"

    var id: String { rawValue }
}

@main
struct LinkTacoQuickSaveApp: App {
    @StateObject private var appState = AppState()
    @State private var selectedSection: AppSection = .quickSave
    private let monitor: HotkeyMonitor

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        monitor = HotkeyMonitor {
            Task { @MainActor in
                state.captureFromChromeAndShowPopup()
            }
        }
        do {
            try monitor.start()
        } catch {
            state.statusMessage = error.localizedDescription
            Task { @MainActor in
                state.presentStartupWindow()
            }
        }
    }

    var body: some Scene {
        WindowGroup("LinkTaco Quick Save") {
            if appState.isPopupVisible {
                PopupView(appState: appState)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(AppSection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedSection {
                    case .quickSave:
                        QuickSaveHomeView(appState: appState)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .search:
                        SearchView(appState: appState)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(20)
                .frame(width: 760, height: 480)
            }
        }
        .windowResizability(.contentSize)
    }
}

private struct QuickSaveHomeView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LinkTaco Quick Save")
                        .font(.headline)
                    Text("Use ⌘⌥⇧H in Chrome to capture the active tab.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("PAT") {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("Personal Access Token", text: $appState.tokenInput)
                            .textFieldStyle(.roundedBorder)

                        HStack(spacing: 10) {
                            Button("Save PAT") {
                                appState.savePAT()
                            }

                            Button("Refresh Orgs") {
                                appState.refreshOrganizationsManually()
                            }
                            .disabled(!appState.hasSavedPAT || appState.isRefreshingOrganizations)

                            Button("Clear PAT") {
                                appState.clearPAT()
                            }
                            .disabled(!appState.hasSavedPAT && appState.tokenInput.isEmpty)

                            Spacer()
                        }

                        Text("Required scopes: LINKS:RW and ORGS:RO.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox("Organization") {
                    VStack(alignment: .leading, spacing: 10) {
                        if appState.isRefreshingOrganizations {
                            ProgressView("Refreshing organizations...")
                                .controlSize(.small)
                        }

                        Picker("Selected Organization", selection: $appState.selectedOrganizationSlug) {
                            Text("Select organization").tag("")
                            ForEach(appState.activeOrganizations) { organization in
                                Text(organization.name).tag(organization.slug)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(appState.activeOrganizations.isEmpty)
                        .onChange(of: appState.selectedOrganizationSlug) { newValue in
                            appState.handleSelectedOrganizationChange(newValue)
                        }

                        Text(appState.organizationPickerHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                if !appState.configurationStatusMessage.isEmpty {
                    Text(appState.configurationStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !appState.statusMessage.isEmpty {
                    Text(appState.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

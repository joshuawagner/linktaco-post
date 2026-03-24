import SwiftUI

struct SearchView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Bookmarks")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Search title, URL, description, or tags", text: $appState.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        appState.runSearch()
                    }

                Button("Search") {
                    appState.runSearch()
                }
                .keyboardShortcut(.defaultAction)
            }

            if !appState.searchStatusMessage.isEmpty {
                Text(appState.searchStatusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if appState.isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            List(appState.searchResults) { result in
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title)
                        .font(.headline)

                    Text(result.url)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .textSelection(.enabled)

                    if !result.description.isEmpty {
                        Text(result.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if !result.tags.isEmpty {
                        Text(result.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
        .padding(16)
        .frame(width: 720, height: 420)
    }
}

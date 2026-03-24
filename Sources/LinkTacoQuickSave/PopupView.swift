import SwiftUI

struct PopupView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save to LinkTaco")
                .font(.headline)

            TextField("URL", text: $appState.draft.url)
            TextField("Title", text: $appState.draft.title)

            Text("Description")
                .font(.subheadline)
            TextEditor(text: $appState.draft.description)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            TextField("Tags (comma-separated)", text: $appState.draft.tags)

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
        .frame(width: 520, height: 340)
    }
}

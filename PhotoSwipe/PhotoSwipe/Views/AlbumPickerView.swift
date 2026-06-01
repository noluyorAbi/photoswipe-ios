import SwiftUI
import Photos

/// Sheet to assign the current photo to an existing album or a new one.
struct AlbumPickerView: View {
    @ObservedObject var vm: SwipeDeckViewModel
    var onPick: (Decision) -> Void

    @State private var newAlbumName = ""
    @State private var creating = false

    var body: some View {
        NavigationStack {
            List {
                Section("New album") {
                    HStack {
                        TextField("Album name", text: $newAlbumName)
                        Button("Create") { createAndPick() }
                            .disabled(newAlbumName.trimmingCharacters(in: .whitespaces).isEmpty || creating)
                    }
                }
                Section("Your albums") {
                    if vm.albums.isEmpty {
                        Text("No albums yet").foregroundStyle(Theme.textDim)
                    }
                    ForEach(vm.albums, id: \.localIdentifier) { album in
                        Button {
                            onPick(.album(localIdentifier: album.localIdentifier,
                                          title: album.localizedTitle ?? "Album"))
                        } label: {
                            Label(album.localizedTitle ?? "Album", systemImage: "rectangle.stack")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Add to album")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.album)
    }

    private func createAndPick() {
        let name = newAlbumName.trimmingCharacters(in: .whitespaces)
        creating = true
        Task {
            if let made = await vm.createAlbum(named: name) {
                onPick(.album(localIdentifier: made.id, title: made.title))
            }
            creating = false
        }
    }
}

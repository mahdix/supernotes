import SwiftUI

struct NoteCardView: View {
    let note: Note

    var body: some View {
        HStack {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(AppSettings.shared.font(for: .headline))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quinary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

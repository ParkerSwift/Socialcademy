//
//  CommentRow.swift
//  Socialcademy
//
//  Created by Parker Joseph Alexander on 6/9/24.
//

import SwiftUI

struct CommentRow: View {
    @ObservedObject var viewModel: CommentRowViewModel
    @State private var showConfirmationDialog = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(viewModel.author.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(viewModel.timestamp.formatted())
                    .foregroundStyle(Color.gray)
                    .font(.caption)
            }
            Text(viewModel.content)
                .font(.headline)
                .fontWeight(.regular)
        }
        .padding(5)
        .alert("Cannot Delete Comment", error: $viewModel.error)
        .confirmationDialog("Are you sure you want to delete this comment?", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: {
                viewModel.deleteComment()
            })
        }
        .swipeActions {
            if viewModel.canDeleteComment {
                Button() {
                    showConfirmationDialog = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .tint(.red)
                }
            }
        }
    }
}

#Preview {
    CommentRow(viewModel: CommentRowViewModel(comment: Comment.testComment, deleteAction: {}))
        .previewLayout(.sizeThatFits)
}

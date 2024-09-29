//
//  CommentsList.swift
//  Socialcademy
//
//  Created by Parker Joseph Alexander on 6/9/24.
//

import SwiftUI
import Foundation

struct CommentsList: View {
    @StateObject var viewModel: CommentsViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    switch viewModel.comments {
                    case .loading:
                        ProgressView()
                            .onAppear {
                                viewModel.fetchComments()
                            }
                    case let .error(error):
                        EmptyListView(
                            title: "Cannot Load Comments",
                            message: error.localizedDescription,
                            retryAction: {
                                viewModel.fetchComments()
                            }
                        )
                    case .empty:
                        EmptyListView(
                            title: "No Comments",
                            message: "Be the first to leave a comment."
                        )
                    case let .loaded(comments):
                        List(comments) { comment in
                            CommentRow(viewModel: viewModel.makeCommentRowViewModel(for: comment))
                        }
                        .animation(.default, value: comments)
                    }
                }
                Spacer()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                NewCommentForm(viewModel: viewModel.makeNewCommentViewModel())
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .shadow(radius: 2)
            }
        }
    }
}

// MARK: - NewCommentForm

private extension CommentsList {
    struct NewCommentForm: View {
        @StateObject var viewModel: FormViewModel<Comment>
        @FocusState private var isTextFieldFocused: Bool
        
        var body: some View {
            HStack {
                TextField("Comment", text: $viewModel.content)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: viewModel.submit) {
                            if viewModel.isWorking {
                                ProgressView()
                            } else {
                                Label("Post", systemImage: "paperplane")
                            }
                        }
                
            }
            .alert("Cannot Post Comment", error: $viewModel.error)
            .animation(.default, value: viewModel.isWorking)
            .disabled(viewModel.isWorking)
            .onSubmit(viewModel.submit)
            
        }
    }
}


#if DEBUG
struct CommentsList_Previews: PreviewProvider {
    static var previews: some View {
        ListPreview(state: .loaded([Comment.testComment]))
        ListPreview(state: .empty)
        ListPreview(state: .error)
        ListPreview(state: .loading)
    }
    
    private struct ListPreview: View {
        let state: Loadable<[Comment]>
        
        var body: some View {
            NavigationStack{
                CommentsList(viewModel: CommentsViewModel(commentsRepository: CommentsRepositoryStub(state: state)))
            }
        }
    }
}
#endif

//
//  TagPickerView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allTags: [Tag]
    
    private var sortedTags: [Tag] {
        allTags.sorted {
            if $0.usageCount == $1.usageCount {
                return $0.name < $1.name
            }
            return $0.usageCount > $1.usageCount
        }
    }
    
    @Binding var selectedTags: [Tag]

    @State private var newTagName: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Select Tags")) {
                    ForEach(sortedTags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if selectedTags.contains(where: { $0.id == tag.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .onTapGesture {
                                        selectedTags.removeAll(where: { $0.id == tag.id })
                                    }
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        selectedTags.append(tag)
                                    }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !selectedTags.contains(where: { $0.id == tag.id }) {
                                Button(role: .destructive) {
                                    deleteTag(tag)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Add Custom Tag")) {
                    HStack {
                        TextField("e.g. Craving Sugar", text: $newTagName)
                            .focused($isInputFocused)
                        Button("Add") {
                            addNewTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if allTags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            newTagName = ""
            return
        }

        let newTag = Tag(name: trimmed)
        modelContext.insert(newTag)
        try? modelContext.save()
        selectedTags.append(newTag)
        newTagName = ""
        isInputFocused = false
    }

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        try? modelContext.save()
    }
}
#Preview {
    TagPickerView(selectedTags: .constant([Tag(name: "Hunger")]))
}

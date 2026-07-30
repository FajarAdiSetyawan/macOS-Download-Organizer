@preconcurrency import SwiftTUI
import Foundation

public struct RulesPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var editingCategory: String? = nil
    @State private var adding: Bool = false
    @State private var newCategoryField: String = ""
    @State private var newExtensionsField: String = ""
    @State private var addExtensionField: String = ""
    @State private var confirmReset: Bool = false
    @State private var confirmRemoveCategory: String? = nil
    @State private var feedbackMessage: String? = nil
    @State private var showHelp: Bool = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let rules = store.rulesDisplay

            if showHelp {
                helpOverlay(theme: theme, onClose: { showHelp = false })
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    pageTitle("\(TUIIcon.rules) Rules", theme: theme)

                Divider().foregroundColor(theme.border)

            HStack(spacing: 2) {
                Text("\(rules.count) categories")
                    .foregroundColor(theme.textDim)
                Spacer()
                Button(action: { adding = true }) {
                    HStack(spacing: 1) {
                        Text("+")
                            .foregroundColor(theme.success)
                            .bold()
                        Text("Add")
                            .foregroundColor(theme.success)
                            .bold()
                    }
                }
                Button(action: { confirmReset = true }) {
                    Text("Reset")
                        .foregroundColor(theme.warning)
                        .bold()
                }
            }
            .padding(.horizontal)

            Divider().foregroundColor(theme.border)

            if let msg = feedbackMessage {
                Text(msg)
                    .foregroundColor(theme.accent)
                    .padding(.horizontal)
                Divider().foregroundColor(theme.border)
            }

            if confirmReset {
                HStack(spacing: 2) {
                    Text("Reset all custom rules?")
                        .foregroundColor(theme.warning)
                    Button(action: {
                        Task { await store.resetRulesToDefaults() }
                        confirmReset = false
                        feedbackMessage = "Reset to defaults"
                    }) {
                        Text("Yes")
                            .foregroundColor(theme.error)
                            .bold()
                    }
                    Button(action: { confirmReset = false }) {
                        Text("No")
                            .foregroundColor(theme.textDim)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                Divider().foregroundColor(theme.border)
            }

            if adding {
                VStack(spacing: 0) {
                    HStack(spacing: 1) {
                        Text("  Category:")
                            .foregroundColor(theme.textDim)
                        TextField(placeholder: "e.g. Music", action: { newCategoryField = $0 })
                    }
                    .padding(.horizontal)
                    HStack(spacing: 1) {
                        Text("  Extensions:")
                            .foregroundColor(theme.textDim)
                        TextField(placeholder: "mp3,flac,wav", action: { val in
                            newExtensionsField = val
                            guard !newCategoryField.isEmpty, !val.isEmpty else { return }
                            Task {
                                await store.addCustomRule(category: newCategoryField, extensions: val)
                                adding = false
                                newCategoryField = ""
                                newExtensionsField = ""
                                feedbackMessage = "Rule added"
                            }
                        })
                    }
                    .padding(.horizontal)
                    Button(action: { adding = false }) {
                        Text("    Cancel")
                            .foregroundColor(theme.error)
                    }
                    .padding(.horizontal)
                    Divider().foregroundColor(theme.border)
                }
            }

            if rules.isEmpty {
                emptyState("No rules defined.", theme: theme)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(rules, id: \.id) { rule in
                            ruleRow(rule: rule, theme: theme)
                            Divider().foregroundColor(theme.border)
                        }
                    }
                }
            }

            Group {
                Spacer()
                Divider().foregroundColor(theme.border)

                HStack(spacing: 2) {
                keyHint("R", "Refresh", theme: theme)
                Spacer()
                helpButton(theme: theme, action: { showHelp = true })
                themeButton(theme: theme)
                homeButton(theme: theme, action: onHome)
            }
            .padding(.horizontal)
            }
        }
    }
}

    private var currentExtensions: [String] {
        guard let cat = editingCategory else { return [] }
        let rule = store.rulesDisplay.first { $0.category == cat }
        return rule?.pattern
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
    }

    private func ruleRow(rule: RuleDisplay, theme: ThemeColors) -> some View {
        let isEditing = editingCategory == rule.category

        return VStack(spacing: 0) {
            if isEditing {
                VStack(spacing: 0) {
                    HStack(spacing: 1) {
                        Text(TUIIcon.chevronDown)
                            .foregroundColor(theme.accent)
                        Text(rule.name)
                            .foregroundColor(theme.highlight)
                            .bold()
                        Spacer()
                        Text("\(currentExtensions.count) ext")
                            .foregroundColor(theme.textDim)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)

                    VStack(spacing: 0) {
                        HStack(spacing: 1) {
                            Text("    Extensions:")
                                .foregroundColor(theme.textDim)
                            Spacer()
                        }
                        .padding(.horizontal)
                        HStack(spacing: 0) {
                            Text("      ")
                            ForEach(currentExtensions, id: \.self) { ext in
                                Button(action: {
                                    Task { await removeExtension(ext, from: rule.category) }
                                }) {
                                    HStack(spacing: 0) {
                                        Text(ext)
                                            .foregroundColor(theme.highlight)
                                        Text(TUIIcon.crossmark)
                                            .foregroundColor(theme.error)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        HStack(spacing: 1) {
                            Text("      +")
                                .foregroundColor(theme.success)
                            TextField(placeholder: "add extension", action: { newVal in
                                let trimmed = newVal.trimmingCharacters(in: .whitespaces).lowercased()
                                guard !trimmed.isEmpty else { return }
                                Task { await addExtension(trimmed, to: rule.category) }
                            })
                        }
                        .padding(.horizontal)
                    }

                    HStack(spacing: 1) {
                        if confirmRemoveCategory == rule.category {
                            Text("Remove this category?")
                                .foregroundColor(theme.warning)
                            Button(action: {
                                Task { await store.removeCustomRule(category: rule.category) }
                                editingCategory = nil
                                confirmRemoveCategory = nil
                                feedbackMessage = "\(rule.category) removed"
                            }) {
                                Text("Yes")
                                    .foregroundColor(theme.error)
                                    .bold()
                            }
                            Button(action: { confirmRemoveCategory = nil }) {
                                Text("No")
                                    .foregroundColor(theme.textDim)
                            }
                        } else {
                            Button(action: { confirmRemoveCategory = rule.category }) {
                                Text("Remove")
                                    .foregroundColor(theme.error)
                            }
                            Button(action: { editingCategory = nil }) {
                                Text("Done")
                                    .foregroundColor(theme.success)
                                    .bold()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                }
            } else {
                Button(action: {
                    editingCategory = editingCategory == rule.category ? nil : rule.category
                }) {
                    HStack(spacing: 1) {
                        Text(TUIIcon.circleFilled)
                            .foregroundColor(theme.success)
                        Text(rule.name)
                            .foregroundColor(theme.highlight)
                            .bold()
                        Text(rule.pattern)
                            .foregroundColor(theme.textDim)
                        Spacer()
                        Text(rule.category)
                            .foregroundColor(theme.accent)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                }
            }
        }
    }

    private func addExtension(_ ext: String, to category: String) async {
        var all = currentExtensions
        if !all.contains(ext.lowercased()) {
            all.append(ext.lowercased())
        }
        await store.updateRuleExtensions(category: category, extensions: all.joined(separator: ", "))
        addExtensionField = ""
    }

    private func removeExtension(_ ext: String, from category: String) async {
        var all = currentExtensions
        all.removeAll { $0.lowercased() == ext.lowercased() }
        if all.isEmpty {
            await store.removeCustomRule(category: category)
        } else {
            await store.updateRuleExtensions(category: category, extensions: all.joined(separator: ", "))
        }
        feedbackMessage = "\(ext) removed from \(category)"
    }
}

import SwiftUI
import FolioCore

struct PDFEncryptionSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var focusedPassword: PasswordKind?
    private enum PasswordKind: Hashable { case opening, editing }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            passwordSections
            note(L("Passwords are kept only for this session."))
        }.frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: model.openingPasswordEnabled) { _, enabled in
                if enabled { focusedPassword = .opening }
            }
            .onChange(of: model.editingPasswordEnabled) { _, enabled in
                if enabled { focusedPassword = .editing }
            }
    }

    private var passwordSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(L("Opening password"), isOn: $model.openingPasswordEnabled)
                    .toggleStyle(.switch).controlSize(.small).font(.system(size: 11, weight: .medium))
                note(L("Required to open and read the PDF."))
                if model.openingPasswordEnabled {
                    if model.editingPasswordEnabled {
                        if model.openingPassword.utf8.count > 16 {
                            errorNote(L("Use 1–16 printable ASCII characters for the opening password when an editing password is set."))
                        } else {
                            note(L("Use 1–16 printable ASCII characters for the opening password when an editing password is set."))
                        }
                    } else {
                        note(L("Use 1–32 printable ASCII characters for the PDF password."))
                    }
                    SecureField(L("Opening password"), text: $model.openingPassword)
                        .focused($focusedPassword, equals: .opening).textContentType(.newPassword)
                    SecureField(L("Confirm opening password"), text: $model.openingPasswordConfirmation)
                        .textContentType(.newPassword)
                    if !model.openingPasswordConfirmation.isEmpty && model.openingPassword != model.openingPasswordConfirmation {
                        errorNote(L("The opening passwords do not match."))
                    }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Toggle(L("Editing password"), isOn: $model.editingPasswordEnabled)
                    .toggleStyle(.switch).controlSize(.small).font(.system(size: 11, weight: .medium))
                note(L("Allows editing in compatible PDF apps. This password can also open the PDF."))
                if model.editingPasswordEnabled {
                    note(L("Use 1–32 printable ASCII characters for the PDF password."))
                    SecureField(L("Editing password"), text: $model.editingPassword)
                        .focused($focusedPassword, equals: .editing).textContentType(.newPassword)
                    SecureField(L("Confirm editing password"), text: $model.editingPasswordConfirmation)
                        .textContentType(.newPassword)
                    if !model.editingPasswordConfirmation.isEmpty && model.editingPassword != model.editingPasswordConfirmation {
                        errorNote(L("The editing passwords do not match."))
                    }
                    if !model.openingPasswordEnabled {
                        note(L("Without an opening password, anyone can read this PDF."))
                    }
                    note(L("Editing restrictions depend on the PDF reader. Printing and copying remain allowed."))
                }
            }
            if model.encryptionEnabled {
                if model.openingPasswordEnabled && model.editingPasswordEnabled &&
                    !model.openingPassword.isEmpty && model.openingPassword == model.editingPassword {
                    errorNote(L("Use different passwords for opening and editing."))
                }
                note(L("These password settings apply to every PDF in this export."))
            }
        }.textFieldStyle(.roundedBorder).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 2)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.system(size: 10)).foregroundStyle(.secondary).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
    }
    private func errorNote(_ text: String) -> some View {
        Text(text).font(.system(size: 10)).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
    }
}

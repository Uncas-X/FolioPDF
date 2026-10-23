import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var language: LanguageStore
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        Form {
            Section {
                Picker(L("Interface language"), selection: $language.selection) {
                    Text(L("Follow system")).tag("system")
                    Divider()
                    ForEach(LocalizationCatalog.languages) { item in
                        Text(item.nativeName).tag(item.id)
                    }
                }
                Text(L("Language changes apply immediately. System dialogs follow your macOS language."))
                    .font(.caption).foregroundStyle(.secondary)
                Picker(L("Appearance"), selection: $appearance) {
                    Text(L("Follow system")).tag("system")
                    Text(L("Light")).tag("light")
                    Text(L("Dark")).tag("dark")
                }
                .pickerStyle(.segmented)
            } header: { Text(L("General")) }

            Section {
                HStack(spacing: 14) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 38)).foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FolioPDF").font(.title3.weight(.semibold))
                        Text(L("Version") + " " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.3")).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 6)
                Label(L("Made for your Mac"), systemImage: "desktopcomputer")
                Text(L("Create searchable PDFs and organize your documents with native macOS tools."))
                    .foregroundStyle(.secondary)
                Label(L("Your documents stay on this Mac"), systemImage: "lock.shield")
                Text(L("Image conversion and text recognition happen locally. No account, uploads, or network connection required."))
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text(L("About")) }
        }
        .formStyle(.grouped)
        .padding(8)
        .frame(width: 530, height: 480)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .environment(\.locale, Locale(identifier: language.resolvedLanguage))
        .environment(\.layoutDirection, language.layoutDirection)
        .onChange(of: language.selection) { _, _ in FolioAppDelegate.current?.refreshWindowLocalization() }
        .id(language.selection)
    }
}

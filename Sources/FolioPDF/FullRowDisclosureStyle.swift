import SwiftUI

/// Keeps the whole header, including its trailing whitespace, clickable.
struct FullRowDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { configuration.isExpanded.toggle() } label: {
                HStack(spacing: 6) {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.forward")
                        .font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    configuration.label
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isExpanded ? L("Expanded") : L("Collapsed"))
            if configuration.isExpanded { configuration.content }
        }
    }
}

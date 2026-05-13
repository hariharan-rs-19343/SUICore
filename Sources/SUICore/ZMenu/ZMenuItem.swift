#if targetEnvironment(macCatalyst)
import SwiftUI

public enum ZMenuItemRole {
    case standard
    case destructive
}

public struct ZMenuItem: View {
    let title: String
    let icon: String?
    let role: ZMenuItemRole
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.zMenuDismiss) private var dismiss

    public init(
        _ title: String,
        icon: String? = nil,
        role: ZMenuItemRole = .standard,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button {
            action()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: 20)
                }
                Text(title)
                Spacer()
            }
            .foregroundColor(foregroundColor)
            .frame(height: 42)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? hoverBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        switch role {
        case .standard:
            return .primary
        case .destructive:
            return .red
        }
    }

    private var hoverBackground: Color {
        switch role {
        case .standard:
            return Color.primary.opacity(0.08)
        case .destructive:
            return Color.red.opacity(0.1)
        }
    }
}

#endif

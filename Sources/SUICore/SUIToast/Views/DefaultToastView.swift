//
//  DefaultToastView.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

struct DefaultToastView: View {
    let content: Toast.StandardContent
    let configuration: ToastConfiguration
    let dismiss: @MainActor @Sendable () -> Void

    private var style: any ToastStyleProviding { configuration.style }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {

            if let symbol = style.iconSystemName {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(style.iconColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(content.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.textColor)
                    .lineLimit(2)

                if let message = content.message, !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(style.textColor.opacity(0.75))
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Title + message read as one VoiceOver element; the buttons
            // below stay separately focusable.
            .accessibilityElement(children: .combine)

            if let action = content.action {
                ToastActionButton(action: action, accentColor: style.accentColor, dismiss: dismiss)
            }

            if showsCloseButton {
                ToastCloseButton(tint: style.textColor, dismiss: dismiss)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: configuration.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
                .strokeBorder(style.borderColor, lineWidth: 1)
                .allowsHitTesting(false)
        }
        // `.contain`, not `.combine`: combining would swallow the action and
        // close buttons and make them unreachable to VoiceOver.
        .accessibilityElement(children: .contain)
    }

    /// Swipe-to-dismiss is awkward with a mouse, and a persistent toast has
    /// no timer to fall back on — both cases get an explicit close button.
    private var showsCloseButton: Bool {
        switch configuration.closeButtonVisibility {
        case .visible: return true
        case .hidden:  return false
        case .automatic:
            #if os(macOS)
            return true
            #else
            return configuration.duration == .persistent
            #endif
        }
    }
}

// MARK: - Action button

/// Small button used by the default toast layout. Encapsulates the
/// highlight/disabled visual states so `DefaultToastView` stays simple.
private struct ToastActionButton: View {
    let action: ToastAction
    let accentColor: Color
    let dismiss: @MainActor @Sendable () -> Void

    var body: some View {
        Button {
            guard action.isEnabled else { return }
            action.handler()
            if action.dismissBehavior == .dismiss { dismiss() }
        } label: {
            Text(action.title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(ToastActionButtonStyle(accentColor: accentColor))
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1.0 : 0.4)
    }
}

// MARK: - Close button

private struct ToastCloseButton: View {
    let tint: Color
    let dismiss: @MainActor @Sendable () -> Void

    var body: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint.opacity(0.6))
        .accessibilityLabel(Text("Dismiss"))
    }
}

/// Custom button style that lights up on press without falling back to
/// the default tinted button look (which would clash with the toast).
private struct ToastActionButtonStyle: ButtonStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(accentColor)
            .background(
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(configuration.isPressed ? 0.22 : 0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

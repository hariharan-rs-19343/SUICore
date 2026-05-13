#if targetEnvironment(macCatalyst)
import SwiftUI

// MARK: - Configuration

@MainActor
public struct ZMenuStyleConfiguration {
    public let label: AnyView
    public let content: AnyView
    public let isPresented: Bool
    public let isPressed: Bool
}

// MARK: - Protocol

@MainActor
public protocol ZMenuStyle {
    associatedtype LabelBody: View
    associatedtype ContentBody: View

    @ViewBuilder
    func makeBody(configuration: ZMenuStyleConfiguration) -> LabelBody

    @ViewBuilder
    func makeContent(configuration: ZMenuStyleConfiguration) -> ContentBody
}

// MARK: - Default Protocol Extension

public extension ZMenuStyle {
    func makeContent(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.content
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
    }
}

// MARK: - Default Style

public struct DefaultZMenuStyle: ZMenuStyle {
    public init() {}

    public func makeBody(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPresented ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPresented)
    }

    public func makeContent(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
    }
}

/// A glassy, translucent menu style using iOS 26 Liquid Glass.
public struct GlassyZMenuStyle: ZMenuStyle {
    public init() {}

    public func makeBody(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.label
            .contentShape(Rectangle())
    }

    public func makeContent(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.content
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
    }
}

// MARK: - Type-Erased Style

@MainActor
struct AnyZMenuStyle {
    private let _makeBody: (ZMenuStyleConfiguration) -> AnyView
    private let _makeContent: (ZMenuStyleConfiguration) -> AnyView

    init<S: ZMenuStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
        _makeContent = { configuration in
            AnyView(style.makeContent(configuration: configuration))
        }
    }

    func makeBody(configuration: ZMenuStyleConfiguration) -> some View {
        _makeBody(configuration)
    }

    func makeContent(configuration: ZMenuStyleConfiguration) -> some View {
        _makeContent(configuration)
    }
}

// MARK: - Environment Key

private struct ZMenuStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: AnyZMenuStyle = AnyZMenuStyle(GlassyZMenuStyle())
}

extension EnvironmentValues {
    @MainActor
    var zMenuStyle: AnyZMenuStyle {
        get { self[ZMenuStyleKey.self] }
        set { self[ZMenuStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    @MainActor
    func zMenuStyle<S: ZMenuStyle>(_ style: S) -> some View {
        environment(\.zMenuStyle, AnyZMenuStyle(style))
    }
}


#endif

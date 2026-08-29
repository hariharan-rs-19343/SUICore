//
//  DocumentViewRepresentable.swift
//  ZhareHub
//
//  Created by Hariharan R S on 06/02/25.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import SwiftUI
import UniformTypeIdentifiers

public struct DocumentViewRepresentable: UIViewControllerRepresentable {
    // File to be exported
    var fileURL: URL
    // Completion handler to notify success or failure
    var completion: (Bool, Error?) -> Void
    
    public init(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        self.fileURL = fileURL
        self.completion = completion
    }

    // Coordinator to handle delegate methods
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentViewRepresentable

        init(parent: DocumentViewRepresentable) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let destinationURL = urls.first else {
                parent.completion(false, nil)
                return
            }

            do {
                try FileManager.default.copyItem(at: parent.fileURL, to: destinationURL)
                parent.completion(true, nil)
            } catch {
                parent.completion(false, error)
            }
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.completion(false, nil)
        }
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL])
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update logic needed, as it's a one-time action
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

// MARK: - Async/Await Support

public extension DocumentViewRepresentable {
    /// Presents a document export picker imperatively and awaits its result,
    /// throwing on cancellation or copy failure.
    ///
    /// Use this when presenting outside a SwiftUI hierarchy. Within SwiftUI,
    /// present `DocumentViewRepresentable` itself (e.g. via `.sheet`) with
    /// its completion-handler initializer instead.
    @MainActor
    static func export(fileURL: URL, from presenter: UIViewController) async throws {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL])
        let delegate = ExportContinuationDelegate(fileURL: fileURL)
        picker.delegate = delegate

        try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            presenter.present(picker, animated: true)
        }
    }
}

/// Bridges `UIDocumentPickerDelegate` callbacks to a single checked
/// continuation for `DocumentViewRepresentable.export(fileURL:from:)`.
private final class ExportContinuationDelegate: NSObject, UIDocumentPickerDelegate {
    private let fileURL: URL
    var continuation: CheckedContinuation<Void, Error>?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let destinationURL = urls.first else {
            continuation?.resume(throwing: CocoaError(.fileNoSuchFile))
            continuation = nil
            return
        }

        do {
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            continuation?.resume()
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        continuation?.resume(throwing: CocoaError(.userCancelled))
        continuation = nil
    }
}
#endif

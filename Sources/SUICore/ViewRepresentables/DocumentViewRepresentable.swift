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
#endif

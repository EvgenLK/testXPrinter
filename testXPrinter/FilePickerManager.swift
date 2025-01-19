//
//  FilePickerManager.swift
//  testXPrinter
//
//  Created by Evgenii on 19.01.2025.
//

import UIKit
import SwiftUI

final class FilePickerManager: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var selectedFileURL: URL? = nil // Выбранный файл
    @Published var isPickerCancelled: Bool = false // Флаг отмены выбора

    func openFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false

        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(documentPicker, animated: true, completion: nil)
            } else {
                print("Ошибка: Не удалось найти активное окно сцены.")
            }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            print("Ошибка: Файл не выбран.")
            return
        }
        print("Выбран файл: \(selectedFileURL)")
        self.selectedFileURL = selectedFileURL
        self.isPickerCancelled = false

        // Сброс для обработки следующего файла
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.selectedFileURL = nil
        }
    }


    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Выбор файла отменен.")
        self.isPickerCancelled = true // Устанавливаем флаг отмены
    }
}



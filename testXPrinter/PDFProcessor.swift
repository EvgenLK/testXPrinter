//
//  PDFProcessor.swift
//  testXPrinter
//
//  Created by Evgenii on 19.01.2025.
//

import PDFKit
import UIKit

final class PDFProcessor {
    static func convertPDFToImage(url: URL, pageIndex: Int) -> UIImage? {
        guard let document = PDFDocument(url: url) else {
            print("Ошибка: Не удалось открыть PDF.")
            return nil
        }

        guard let page = document.page(at: pageIndex) else {
            print("Ошибка: Не удалось получить страницу PDF.")
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}


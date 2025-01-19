//
//  ImageConverter.swift
//  testXPrinter
//
//  Created by Evgenii on 19.01.2025.
//

import SwiftUI

final class ImageConverter {
    static func convertJPGToMonochromeBMP(image: UIImage) -> Data? {
        // Размер этикетки в пикселях
        // Предположим, что принтер имеет разрешение 203 DPI (точек на дюйм)
        let dpi: CGFloat = 203 // Разрешение принтера
        let labelWidthInPixels = Int(43.0 / 25.4 * dpi) // 43 мм -> дюймы -> пиксели
        let labelHeightInPixels = Int(25.0 / 25.4 * dpi) // 25 мм -> дюймы -> пиксели

        // Масштабируем изображение под размер этикетки
        guard let resizedImage = resizeImage(image: image, targetSize: CGSize(width: CGFloat(labelWidthInPixels), height: CGFloat(labelHeightInPixels))) else {
            print("Ошибка: Не удалось изменить размер изображения.")
            return nil
        }

        // Получаем CGImage из масштабированного изображения
        guard let cgImage = resizedImage.cgImage else {
            print("Ошибка: Не удалось получить CGImage.")
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        // Выравниваем ширину до ближайшего числа, кратного 8
        let alignedWidth = (width + 7) & ~7

        // Вычисляем количество байт на строку с учетом выравнивания по 4 байта
        let bytesPerRow = ((alignedWidth + 31) / 32) * 4

        // Размер буфера для монохромного изображения
        let bufferSize = bytesPerRow * height
        var bitmap = [UInt8](repeating: 0, count: bufferSize)

        // Создаем контекст для преобразования в градации серого
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8, // 8 бит на пиксель
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("Ошибка: Не удалось создать контекст для градаций серого")
            return nil
        }

        // Рисуем изображение в контексте
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        // Получаем данные пикселей
        guard let grayscaleData = context.data else {
            print("Ошибка: Не удалось получить данные пикселей")
            return nil
        }

        let grayscaleBytes = grayscaleData.bindMemory(to: UInt8.self, capacity: width * height)

        // Порог для преобразования в монохромное изображение
        let threshold: UInt8 = 100

        // Преобразование в 1-битное изображение
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let grayValue = grayscaleBytes[pixelIndex]
                let bitIndex = x % 8
                let byteIndex = y * bytesPerRow + x / 8
                // Инвертируем цвета
                if grayValue >= threshold { // Если значение больше порога, делаем пиксель черным
                    bitmap[byteIndex] |= (0x80 >> bitIndex)
                }
            }
            // Добавляем padding в конце каждой строки
            let paddingStartIndex = (height - y - 1) * bytesPerRow + (width + 7) / 8
            for i in 0..<(bytesPerRow - (width + 7) / 8) {
                bitmap[paddingStartIndex + i] = 0
            }
        }

        // Формируем заголовки BMP
        let fileHeader: [UInt8] = [
            0x42, 0x4D,                         // 'BM'
            0, 0, 0, 0,                         // Размер файла (будет добавлено позже)
            0x00, 0x00,                         // Зарезервировано
            0x00, 0x00,                         // Зарезервировано
            0x3E, 0x00, 0x00, 0x00              // Смещение начала данных (62 байта)
        ]

        var dibHeader: [UInt8] = [
            0x28, 0x00, 0x00, 0x00,             // Размер заголовка DIB
            0, 0, 0, 0,                         // Ширина (заполним позже)
            0, 0, 0, 0,                         // Высота (заполним позже)
            0x01, 0x00,                         // Плоскости
            0x01, 0x00,                         // Биты на пиксель
            0x00, 0x00, 0x00, 0x00,             // Сжатие (0 - без сжатия)
            0, 0, 0, 0,                         // Размер изображения (заполним позже)
            0x3C, 0x0E, 0x00, 0x00,             // Горизонтальное разрешение (96 DPI)
            0x3C, 0x0E, 0x00, 0x00,             // Вертикальное разрешение (96 DPI)
            0x00, 0x00, 0x00, 0x00,             // Число цветов в палитре (0 - все цвета)
            0x00, 0x00, 0x00, 0x00              // Важные цвета (0 - все важны)
        ]

        // Устанавливаем ширину и высоту
        dibHeader[4] = UInt8(width & 0xFF)
        dibHeader[5] = UInt8((width >> 8) & 0xFF)
        dibHeader[6] = UInt8((width >> 16) & 0xFF)
        dibHeader[7] = UInt8((width >> 24) & 0xFF)
        dibHeader[8] = UInt8(height & 0xFF)
        dibHeader[9] = UInt8((height >> 8) & 0xFF)
        dibHeader[10] = UInt8((height >> 16) & 0xFF)
        dibHeader[11] = UInt8((height >> 24) & 0xFF)

        // Устанавливаем размер изображения
        let imageDataSize = bufferSize
        dibHeader[20] = UInt8(imageDataSize & 0xFF)
        dibHeader[21] = UInt8((imageDataSize >> 8) & 0xFF)
        dibHeader[22] = UInt8((imageDataSize >> 16) & 0xFF)
        dibHeader[23] = UInt8((imageDataSize >> 24) & 0xFF)

        // Размер всего файла
        let fileSize = 14 + 40 + 8 + imageDataSize
        var updatedFileHeader = fileHeader
        updatedFileHeader[2] = UInt8(fileSize & 0xFF)
        updatedFileHeader[3] = UInt8((fileSize >> 8) & 0xFF)
        updatedFileHeader[4] = UInt8((fileSize >> 16) & 0xFF)
        updatedFileHeader[5] = UInt8((fileSize >> 24) & 0xFF)

        // Цветовая палитра
        let colorTable: [UInt8] = [
            0xFF, 0xFF, 0xFF, 0x00, // Белый
            0x00, 0x00, 0x00, 0x00  // Черный
        ]

        // Собираем данные BMP
        var bmpData = Data(updatedFileHeader)
        bmpData.append(contentsOf: dibHeader)
        bmpData.append(contentsOf: colorTable)
        bmpData.append(contentsOf: bitmap)

        return bmpData
    }

    // Метод для изменения размера изображения
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

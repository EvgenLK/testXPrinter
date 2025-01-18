import CoreBluetooth
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import CoreImage
import UIKit


class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, UIDocumentPickerDelegate {
    @Published var devices: [CBPeripheral] = []
    @Published var connectedDevice: CBPeripheral?
    @Published var statusMessage: String = "Ожидание"
    
    private var centralManager: CBCentralManager?
    private var writableCharacteristic: CBCharacteristic?

    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth включен. Поиск устройств..."
            centralManager?.scanForPeripherals(withServices: nil)
        case .poweredOff:
            statusMessage = "Включите Bluetooth."
        case .unsupported:
            statusMessage = "Bluetooth не поддерживается."
        default:
            statusMessage = "Состояние: \(central.state.rawValue)"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, !devices.contains(where: { $0.identifier == peripheral.identifier }) {
            devices.append(peripheral)
            print("Найдено устройство: \(name)")
        }
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        centralManager?.stopScan()
        connectedDevice = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Подключено к \(peripheral.name ?? "устройству")"
        print("Подключен принтер \(peripheral.name ?? "")")
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                    writableCharacteristic = characteristic
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            print("Ответ принтера: \(String(data: data, encoding: .ascii) ?? "Не удалось декодировать ответ")")
        }
    


        if let data = characteristic.value {
            print("Ответ принтера: \(String(data: data, encoding: .utf8) ?? "Не удалось декодировать ответ")")
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Ошибка записи данных: \(error.localizedDescription)")
        } else {
            print("Данные успешно отправлены.")
        }
    }
    
    
    
    // MARK: - Метод для отправки текста
    func sendTSPLText(_ text: String) {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            statusMessage = "Нет подключенного устройства или подходящей характеристики."
            return
        }
        
        // Формируем команду TSPL-EZD
        let tsplCommand = """
        CLS\r\n
        SIZE 43 mm, 25 mm\r\n
        GAP 2 mm, 0 mm\r\n
        TEXT 50, 140, "0", 0, 10, 10, "\(text)"\r\n
        PRINT 1, 1\r\n
        """
        
        // Конвертируем команду в Data и отправляем на принтер
        if let data = tsplCommand.data(using: .ascii) {
            connectedDevice.writeValue(data, for: writableCharacteristic, type: .withResponse)
            statusMessage = "Текст отправлен на печать."
            print("Отправлена команда TSPL: \(tsplCommand)")
        } else {
            statusMessage = "Не удалось закодировать текст."
        }
    }
    
    
    // MARK: - Метод для отправки баркода
    func sendTSPLBarcode(_ barcode: String) {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            statusMessage = "Нет подключенного устройства или подходящей характеристики."
            return
        }
        
        // Ограничиваем длину баркода
        let trimmedBarcode = String(barcode.prefix(20))
        
        // Формируем команду TSPL-EZD
        let tsplCommand = """
        CLS\r\n
        SIZE 43 mm, 25 mm\r\n
        GAP 2 mm, 0 mm\r\n
        BARCODE 10, 10, "128", 100, 1, 0, 2, 2, "\(trimmedBarcode)"\r\n
        PRINT 1, 1\r\n
        """
        
        // Конвертируем команду в Data и отправляем на принтер
        if let data = tsplCommand.data(using: .ascii) {
            connectedDevice.writeValue(data, for: writableCharacteristic, type: .withResponse)
            statusMessage = "Баркод отправлен на печать."
            print("Отправлена команда TSPL: \(tsplCommand)")
        } else {
            statusMessage = "Не удалось закодировать баркод."
        }
    }
    
    
    // MARK: - Метод для отправки черного квадрата
    
    func printBlackLabel() {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            print("Нет подключенного устройства или подходящей характеристики.")
            return
        }
        
        // Команды для создания и печати чёрной этикетки
        let printCommands = """
        CLS\r\n
        SIZE 43 mm, 25 mm\r\n
        GAP 2 mm, 0 mm\r\n
        BAR 0,0,344,200\r\n
        PRINT 1,1\r\n
        """
        
        // Отправка команды на принтер
        if let commandData = printCommands.data(using: .ascii) {
            connectedDevice.writeValue(commandData, for: writableCharacteristic, type: .withResponse)
            print("Команда печати отправлена: \(printCommands)")
        } else {
            print("Не удалось создать данные команды.")
        }
    }
    
    
    
    // MARK: - Метод для отправки что то новое





    



    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Печать файла из памяти принтера ниже готовый   код
    
    func printImageOnPrinter(img: UIImage, x: Int, y: Int) {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            print("Ошибка: Нет подключенного устройства или подходящей характеристики.")
            return
        }

        // Конвертируем изображение в BMP
        guard let bmpData = convertJPGToMonochromeBMP(image: img) else {
            print("Ошибка: Не удалось преобразовать изображение в BMP.")
            return
        }

        let fileName = "PO.BMP"
        let fileSize = bmpData.count

        // Команда для загрузки файла
        let downloadCommand = """
        DOWNLOAD "\(fileName)",\(fileSize),
        """
        guard let downloadCommandData = downloadCommand.data(using: .ascii) else {
            print("Ошибка: Не удалось преобразовать команду DOWNLOAD в Data.")
            return
        }

        // Отправляем команду загрузки
        connectedDevice.writeValue(downloadCommandData, for: writableCharacteristic, type: .withResponse)
//        usleep(500000) // Задержка

        // Отправляем данные BMP по блокам
        let chunkSize = 256
        var offset = 0
        while offset < fileSize {
            let end = min(offset + chunkSize, fileSize)
            let chunk = bmpData.subdata(in: offset..<end)
            connectedDevice.writeValue(chunk, for: writableCharacteristic, type: .withResponse)
            offset += chunkSize
            usleep(1000) // Задержка между блоками
        }

        // Завершение загрузки
        let finishCommand = "\r\n"
        connectedDevice.writeValue(finishCommand.data(using: .ascii)!, for: writableCharacteristic, type: .withResponse)
//        usleep(100000) // Задержка перед печатью

        // Команда печати
        let printCommand = """
        CLS
        SIZE 43 mm, 25 mm
        GAP 2 mm, 0 mm
        DIRECTION 0
        DENSITY 15
        PUTBMP \(x+10),\(y),"\(fileName)"\r\n
        PRINT 1,1\r\n
        """
        connectedDevice.writeValue(printCommand.data(using: .ascii)!, for: writableCharacteristic, type: .withResponse)
        print("Команда печати отправлена.")
    }



    // MARK: - Тест на загрузку в память
    func convertJPGToMonochromeBMP(image: UIImage) -> Data? {
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
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }


    
    
    func saveBMPFileToDocuments(fileData: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Ошибка: Не удалось найти директорию документов.")
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try fileData.write(to: fileURL)
            print("Файл успешно сохранен в: \(fileURL.path)")
            return fileURL
        } catch {
            print("Ошибка при сохранении файла: \(error)")
            return nil
        }
    }

}


extension BluetoothManager {
    
    // Метод для открытия файлового выборщика
    func openFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        DispatchQueue.main.async {
            // Получаем активное окно сцены
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(documentPicker, animated: true, completion: nil)
            } else {
                print("Ошибка: Не удалось найти активное окно сцены.")
            }
        }
    }

    
    // Обработка выбранного файла
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            print("Ошибка: Файл не выбран.")
            return
        }
        print("Выбран файл: \(selectedFileURL)")
        
        // Преобразуем PDF в изображение
        guard let pdfImage = convertPDFToImage(url: selectedFileURL, pageIndex: 0) else {
            print("Ошибка: Не удалось преобразовать PDF в изображение.")
            return
        }
        
        // Печать изображения
        printImageOnPrinter(img: pdfImage, x: 0, y: 0)
    }
    
    // Преобразование PDF в изображение
    func convertPDFToImage(url: URL, pageIndex: Int) -> UIImage? {
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
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        return image
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Выбор файла отменен.")
    }
}

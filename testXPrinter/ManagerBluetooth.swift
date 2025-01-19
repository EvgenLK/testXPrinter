import CoreBluetooth
import SwiftUI


final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, UIDocumentPickerDelegate {
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
                    writableCharacteristic = characteristic //BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F использую это характеристику она и читает и пишет
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
    
    // MARK: - команда печати

    func sendTSPLText(_ text: String) {
        let command = TSPLCommands.textCommand(text: text)
        sendCommandToPrinter(command)
        statusMessage = "Текст отправлен на печать."
        print("Отправлена команда TSPL: \(text)")
    }

    func sendTSPLBarcode(_ barcode: String) {
        let command = TSPLCommands.barcodeCommand(barcode: barcode)
        sendCommandToPrinter(command)
        statusMessage = "Баркод отправлен на печать."
        print("Отправлена команда TSPL: \(barcode)")
    }

    func printImageOnPrinter(img: UIImage, x: Int, y: Int) {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            print("Ошибка: Нет подключенного устройства или подходящей характеристики.")
            return
        }

        guard let bmpData = ImageConverter.convertJPGToMonochromeBMP(image: img) else {
            print("Ошибка: Не удалось преобразовать изображение в BMP.")
            return
        }

        let fileName = "PRICE.BMP"
        let fileSize = bmpData.count

        // Сброс буфера перед началом
        sendCommandToPrinter(TSPLCommands.resetCommand())
        
        let downloadCommand = TSPLCommands.downloadCommand(fileName: fileName, fileSize: fileSize)
        sendCommandToPrinter(downloadCommand)

        DispatchQueue.global(qos: .userInitiated).async {
            let chunkSize = 256
            var offset = 0
            while offset < fileSize {
                let end = min(offset + chunkSize, fileSize)
                let chunk = bmpData.subdata(in: offset..<end)
                connectedDevice.writeValue(chunk, for: writableCharacteristic, type: .withoutResponse)
                offset += chunkSize
                usleep(10_000)
            }

            DispatchQueue.main.async {
                self.sendCommandToPrinter("\r\n")
                let printCommand = TSPLCommands.imageCommand(fileName: fileName, x: x, y: y)
                self.sendCommandToPrinter(printCommand)
                print("Команда печати отправлена.")
            }
        }
    }


    private func sendCommandToPrinter(_ command: String) {
        guard let connectedDevice = connectedDevice, let writableCharacteristic = writableCharacteristic else {
            statusMessage = "Нет подключенного устройства или подходящей характеристики."
            return
        }

        guard let commandData = command.data(using: .ascii) else {
            print("Ошибка: Не удалось преобразовать команду в Data.")
            return
        }

        connectedDevice.writeValue(commandData, for: writableCharacteristic, type: .withoutResponse)
    }



    // MARK: - Тест на загрузку в память телефона , использовалось для проверки картинки на соответствие формата
    
//    func saveBMPFileToDocuments(fileData: Data, fileName: String) -> URL? {
//        let fileManager = FileManager.default
//        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            print("Ошибка: Не удалось найти директорию документов.")
//            return nil
//        }
//
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//        do {
//            try fileData.write(to: fileURL)
//            print("Файл успешно сохранен в: \(fileURL.path)")
//            return fileURL
//        } catch {
//            print("Ошибка при сохранении файла: \(error)")
//            return nil
//        }
//    }
}



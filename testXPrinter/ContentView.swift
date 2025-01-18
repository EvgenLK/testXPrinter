import SwiftUI
import PDFKit
import CoreBluetooth
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    private var testText = "Hey"
    private var barcode = "111122233344"
    private var testImage = UIImage(named: "Document1")
    
    var body: some View {
        NavigationView {
            VStack {
                // Статус Bluetooth
                Text(bluetoothManager.statusMessage)
                    .padding()
                    .foregroundColor(.blue)

                // Список устройств
                List(bluetoothManager.devices, id: \.identifier) { device in
                    Button(action: {
                        bluetoothManager.connectToDevice(device)
                    }) {
                        Text(device.name ?? "Неизвестное устройство")
                            .font(.headline)
                    }
                }

                // Устройство подключено
                if let device = bluetoothManager.connectedDevice {
                    Text("Подключено к: \(device.name ?? "устройству")")
                        .padding()

                    // Кнопка для тестовой печати текста
                    Button("Отправить тестовый текст") {
                        bluetoothManager.sendTSPLText(testText)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // Кнопка для тестовой печати баркода
                    Button("Отправить баркод") {
                        bluetoothManager.sendTSPLBarcode(barcode)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // Кнопка для тестовой печати растрового изображения
                    Button("Отправить растровую картинку") {
                        if let img = testImage {
                            bluetoothManager.printImageOnPrinter(img: img, x: 0, y: 20)
                        } else {
                            print("Ошибка: Изображение отсутствует")
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // Кнопка для выбора файла
                    Button("Выбрать PDF файл") {
                        bluetoothManager.openFilePicker()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Bluetooth Scanner")
        }
    }
}


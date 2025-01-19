import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var fileManager = FilePickerManager()

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

                // Кнопки
                VStack {
                    Button("Отправить тестовый текст") {
                        bluetoothManager.sendTSPLText(testText)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Выбрать PDF файл") {
                        fileManager.openFilePicker()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .onChange(of: fileManager.selectedFileURL) { oldValue, newValue in
                if let url = newValue {
                    handlePickedFile(url: url)
                }
            }
            .onChange(of: fileManager.isPickerCancelled) { oldValue, newValue in
                if newValue {
                    print("Пользователь отменил выбор файла.")
                }
            }
            .navigationTitle("Bluetooth Scanner")
        }
    }

    // Обработчик выбранного файла
    private func handlePickedFile(url: URL) {
        guard let pdfImage = PDFProcessor.convertPDFToImage(url: url, pageIndex: 0) else {
            print("Ошибка: Не удалось преобразовать PDF в изображение.")
            return
        }
        bluetoothManager.printImageOnPrinter(img: pdfImage, x: 0, y: 0)
    }
}

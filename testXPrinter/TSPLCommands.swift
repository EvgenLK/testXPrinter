//
//  TSPLCommands.swift
//  testXPrinter
//
//  Created by Evgenii on 19.01.2025.
//


struct TSPLCommands {
    static func textCommand(text: String) -> String {
        return """
        CLS\r\n
        SIZE 43 mm, 25 mm\r\n
        GAP 2 mm, 0 mm\r\n
        TEXT 50, 140, "0", 0, 10, 10, "\(text)"\r\n
        PRINT 1, 1\r\n
        """
    }
    
    static func barcodeCommand(barcode: String) -> String {
        let trimmedBarcode = String(barcode.prefix(20))
        return """
        CLS\r\n
        SIZE 43 mm, 25 mm\r\n
        GAP 2 mm, 0 mm\r\n
        BARCODE 10, 10, "128", 100, 1, 0, 2, 2, "\(trimmedBarcode)"\r\n
        PRINT 1, 1\r\n
        """
    }
    
    static func imageCommand(fileName: String, x: Int, y: Int) -> String {
        return """
        CLS
        SIZE 43 mm, 25 mm
        GAP 2 mm, 0 mm
        DIRECTION 0
        DENSITY 10
        PUTBMP \(x+15),\(y),"\(fileName)"\r\n
        PRINT 1,1\r\n
        """
    }
    
    static func downloadCommand(fileName: String, fileSize: Int) -> String {
        return """
        DOWNLOAD "\(fileName)",\(fileSize),
        """
    }
    
    static func resetCommand() -> String {
        return "~!\r\n"
    }
}

import Foundation

enum CSVService {

    static let header = ["folder", "title", "callout", "reference", "body"]

    struct ParsedRow {
        let folder: String
        let title: String
        let callout: String
        let reference: String
        let body: String
    }

    enum ImportError: Error, LocalizedError {
        case empty
        case malformed
        case missingHeader

        var errorDescription: String? {
            switch self {
            case .empty: return "The CSV file was empty."
            case .malformed: return "The CSV could not be parsed."
            case .missingHeader: return "The CSV header must include folder, title, callout, reference, body."
            }
        }
    }

    // MARK: - Export

    static func exportCSV(folders: [Folder]) -> String {
        var lines: [String] = [header.map(escape).joined(separator: ",")]
        for folder in folders {
            for item in folder.items {
                let row = [folder.name, item.title, item.callout, item.reference, item.body]
                lines.append(row.map(escape).joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func exportCSV(folder: Folder) -> String {
        exportCSV(folders: [folder])
    }

    /// Write a CSV string to a temp file and return its URL (suitable for ShareLink).
    static func writeTempCSV(_ csv: String, fileName: String = "busstop-export.csv") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Parse

    static func parseCSV(_ text: String) throws -> [ParsedRow] {
        let rows = try parseRows(text)
        guard let first = rows.first else { throw ImportError.empty }

        let normalizedHeader = first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard normalizedHeader == header else { throw ImportError.missingHeader }

        var result: [ParsedRow] = []
        for row in rows.dropFirst() {
            // Skip rows that are completely empty
            if row.allSatisfy({ $0.isEmpty }) { continue }
            // Pad missing trailing fields rather than rejecting
            let padded = row + Array(repeating: "", count: max(0, header.count - row.count))
            result.append(ParsedRow(
                folder: padded[0],
                title: padded[1],
                callout: padded[2],
                reference: padded[3],
                body: padded[4]
            ))
        }
        return result
    }

    // MARK: - Import

    /// Replace every folder/item from CSV. Folders are created in the order they
    /// first appear; items keep their original order within each folder.
    static func importReplacingAll(csv: String, into store: FolderStore) throws {
        let rows = try parseCSV(csv)

        var orderedNames: [String] = []
        var grouped: [String: [MemoryItem]] = [:]

        for row in rows {
            let folderName = row.folder.isEmpty ? "Uncategorized" : row.folder
            if grouped[folderName] == nil {
                grouped[folderName] = []
                orderedNames.append(folderName)
            }
            grouped[folderName]?.append(MemoryItem(
                title: row.title,
                callout: row.callout,
                reference: row.reference,
                body: row.body
            ))
        }

        let newFolders = orderedNames.map { name in
            Folder(name: name, items: grouped[name] ?? [])
        }
        store.replaceAll(newFolders)
    }

    /// Append items from CSV into a single folder. The "folder" column is ignored.
    static func importAppending(csv: String, folderID: String, into store: FolderStore) throws {
        let rows = try parseCSV(csv)
        let items = rows.map {
            MemoryItem(title: $0.title, callout: $0.callout, reference: $0.reference, body: $0.body)
        }
        store.appendItems(folderID: folderID, items: items)
    }

    // MARK: - Low-level CSV

    private static func escape(_ field: String) -> String {
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    /// Parse RFC 4180-ish CSV: quoted fields can contain commas, newlines, and
    /// "" as an escaped quote. Newlines outside quotes terminate a row.
    private static func parseRows(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false

        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let c = chars[i]

            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                        i += 1
                        continue
                    }
                } else {
                    field.append(c)
                    i += 1
                    continue
                }
            }

            switch c {
            case "\"":
                if field.isEmpty {
                    inQuotes = true
                } else {
                    // A quote in the middle of an unquoted field — treat literally.
                    field.append(c)
                }
                i += 1
            case ",":
                current.append(field)
                field = ""
                i += 1
            case "\r":
                // Treat \r and \r\n as a single newline
                current.append(field)
                rows.append(current)
                current = []
                field = ""
                if i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 2
                } else {
                    i += 1
                }
            case "\n":
                current.append(field)
                rows.append(current)
                current = []
                field = ""
                i += 1
            default:
                field.append(c)
                i += 1
            }
        }

        // Flush the last field/row if there is one.
        if !field.isEmpty || !current.isEmpty {
            current.append(field)
            rows.append(current)
        }

        if inQuotes {
            throw ImportError.malformed
        }

        return rows
    }
}

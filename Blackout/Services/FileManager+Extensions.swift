import Foundation

extension FileManager {
    func createFileIfNeeded(at url: URL, defaultContent: Data = Data()) {
        guard !fileExists(atPath: url.path) else { return }
        
        do {
            try defaultContent.write(to: url)
        } catch {
            print("Error creating file at \(url): \(error)")
        }
    }
} 
import Foundation

enum MusicalScaleType: String, CaseIterable, Identifiable {
    case major = "Major"
    case naturalMinor = "Natural Minor"
    case majorPentatonic = "Major Pentatonic"
    case minorPentatonic = "Minor Pentatonic"

    var id: String { self.rawValue }

    var displayName: String {
        return self.rawValue
    }

    var intervals: [UInt8] {
        switch self {
        case .major:
            return [0, 2, 4, 5, 7, 9, 11] // Root, M2, M3, P4, P5, M6, M7
        case .naturalMinor:
            return [0, 2, 3, 5, 7, 8, 10] // Root, M2, m3, P4, P5, m6, m7
        case .majorPentatonic:
            return [0, 2, 4, 7, 9]       // Root, M2, M3, P5, M6
        case .minorPentatonic:
            return [0, 3, 5, 7, 10]      // Root, m3, P4, P5, m7
        }
    }
}

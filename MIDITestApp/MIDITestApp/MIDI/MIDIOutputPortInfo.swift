import Foundation
import CoreMIDI // For MIDIEndpointRef

struct MIDIOutputPortInfo: Identifiable, Hashable {
    let id: String // Unique identifier for the MIDI endpoint
    let displayName: String
    let midiEndpointRef: MIDIEndpointRef

    // Conformance to Hashable
    // MIDIEndpointRef is a UInt32 (typealias), so it's directly hashable.
    // The id should be unique enough to distinguish endpoints.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(midiEndpointRef)
    }

    // Conformance to Equatable (required by Hashable)
    static func == (lhs: MIDIOutputPortInfo, rhs: MIDIOutputPortInfo) -> Bool {
        return lhs.id == rhs.id && lhs.midiEndpointRef == rhs.midiEndpointRef
    }
}

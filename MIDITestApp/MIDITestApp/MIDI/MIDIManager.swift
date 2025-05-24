import Foundation
import CoreMIDI

import Combine // For ObservableObject

class MIDIManager: ObservableObject {
    private var midiClient = MIDIClientRef()
    private var internalOutputPortRef = MIDIPortRef() // Renamed to avoid confusion with selected port
    private var selectedDestinationEndpointRef: MIDIEndpointRef? // This is the actual endpoint to send to
    
    @Published var availableOutputPorts: [MIDIOutputPortInfo] = []
    @Published var selectedOutputPortID: String? { // Used by Picker in ContentView
        didSet {
            if let portID = selectedOutputPortID,
               let portInfo = availableOutputPorts.first(where: { $0.id == portID }) {
                selectOutputPort(portInfo: portInfo)
            } else if selectedOutputPortID == nil && !availableOutputPorts.isEmpty {
                // If selection is cleared, or on init, try to select the first one
                // This case might need more robust handling depending on desired UX
            }
        }
    }
    @Published var currentOutputName: String = "No Output Selected" // Kept for direct display if needed

    init() {
        var status = MIDIClientCreate("MIDITestClient" as CFString, nil, nil, &midiClient)
        if status != noErr {
            print("Error creating MIDI client: \(status)")
            currentOutputName = "Error: MIDI Client"
            // availableOutputPorts will remain empty
            return
        }

        status = MIDIOutputPortCreate(midiClient, "MIDITestOutputPort" as CFString, &internalOutputPortRef)
        if status != noErr {
            print("Error creating MIDI output port: \(status)")
            currentOutputName = "Error: MIDI Port"
            // availableOutputPorts will remain empty
            return
        }
        refreshAvailableOutputs()
    }

    func refreshAvailableOutputs() {
        availableOutputPorts.removeAll()
        let destinationCount = MIDIGetNumberOfDestinations()
        print("Found \(destinationCount) MIDI destinations.")

        for i in 0..<destinationCount {
            let endpointRef = MIDIGetDestination(i)
            if endpointRef != 0 { // Valid endpoint
                let displayName = getDisplayName(for: endpointRef)
                // For a unique ID, we can use the index or try to get a unique ID from CoreMIDI if available
                // kMIDIPropertyUniqueID is an option, but can be tricky.
                // Using displayName + index for simplicity if displayNames aren't unique,
                // or just index if it's guaranteed unique by order.
                // For robustness, MIDIObjectGetIntegerProperty(endpointRef, kMIDIPropertyUniqueID, &uniqueID)
                // would be better. Let's use index as a simple unique ID for now.
                let uniqueID = String(endpointRef) // Using the endpointRef itself as a unique ID string
                let portInfo = MIDIOutputPortInfo(id: uniqueID, displayName: displayName, midiEndpointRef: endpointRef)
                availableOutputPorts.append(portInfo)
                print("Added output: \(displayName) (ID: \(uniqueID), Ref: \(endpointRef))")
            }
        }

        if availableOutputPorts.isEmpty {
            currentOutputName = "No Destinations Found"
            selectedDestinationEndpointRef = nil
            selectedOutputPortID = nil
            print("No available output ports.")
        } else {
            // If no port is selected, or if the previously selected one is no longer available, select the first.
            if selectedOutputPortID == nil || !availableOutputPorts.contains(where: { $0.id == selectedOutputPortID }) {
                if let firstPort = availableOutputPorts.first {
                    selectOutputPort(portInfo: firstPort)
                     // This will trigger the didSet of selectedOutputPortID if Picker is bound to it
                    selectedOutputPortID = firstPort.id
                }
            } else {
                // Ensure currentOutputName is up-to-date if selection was preserved
                if let portID = selectedOutputPortID, let portInfo = availableOutputPorts.first(where: { $0.id == portID}) {
                     currentOutputName = portInfo.displayName
                }
            }
        }
    }
    
    func selectOutputPort(portInfo: MIDIOutputPortInfo) {
        // Send All Notes Off to the PREVIOUSLY selected port before switching
        if selectedDestinationEndpointRef != nil && selectedDestinationEndpointRef != portInfo.midiEndpointRef {
            print("MIDIManager: Output port changing. Sending All Notes Off to previous port: \(currentOutputName)")
            sendAllNotesOff() // Uses the current selectedDestinationEndpointRef before it's changed
        }

        selectedDestinationEndpointRef = portInfo.midiEndpointRef
        currentOutputName = portInfo.displayName
        
        // selectedOutputPortID should be updated by the Picker's binding, or manually if called programmatically
        // To ensure consistency if called programmatically:
        if self.selectedOutputPortID != portInfo.id {
             self.selectedOutputPortID = portInfo.id
        }
        print("MIDIManager: Selected new MIDI Output Port: \(portInfo.displayName) (ID: \(portInfo.id), Ref: \(portInfo.midiEndpointRef))")
    }

    func sendMIDINote(noteNumber: UInt8) {
        guard let dest = selectedDestinationEndpointRef else {
            print("No MIDI destination selected. Cannot send note.")
            // Optionally, try to refresh and select one if appropriate for UX
            // refreshAvailableOutputs()
            // if selectedDestinationEndpointRef == nil { print("Still no destination.") }
            return
        }
        
        guard internalOutputPortRef != 0 else {
            print("Internal MIDI output port is invalid. Cannot send note.")
            return
        }

        // MIDI Note On: Channel 1 (0x90), Velocity 100 (0x64)
        var noteOnPacket = MIDIPacket()
        noteOnPacket.timeStamp = 0 // Send immediately
        noteOnPacket.length = 3
        noteOnPacket.data.0 = 0x90       // Note On, Channel 1
        noteOnPacket.data.1 = noteNumber // User-defined note
        noteOnPacket.data.2 = 100        // Velocity

        var packetList = MIDIPacketList(numPackets: 1, packet: noteOnPacket)
        
        // Use internalOutputPortRef (the port created by our app) and selectedDestinationEndpointRef
        var status = MIDISend(internalOutputPortRef, dest, &packetList)
        if status != noErr {
            print("Error sending MIDI Note On (\(noteNumber)): \(status)")
        } else {
            print("Sent MIDI Note On: \(noteNumber) with velocity 100")
        }

        // MIDI Note Off: Channel 1 (0x80), Velocity 0 (0x00)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 200ms delay
            var noteOffPacket = MIDIPacket()
            noteOffPacket.timeStamp = 0 // Send immediately
            noteOffPacket.length = 3
            noteOffPacket.data.0 = 0x80       // Note Off, Channel 1
            noteOffPacket.data.1 = noteNumber // User-defined note
            noteOffPacket.data.2 = 0          // Velocity (irrelevant for Note Off, often 0)

            var packetListOff = MIDIPacketList(numPackets: 1, packet: noteOffPacket)
            status = MIDISend(self.internalOutputPortRef, dest, &packetListOff)
            if status != noErr {
                print("Error sending MIDI Note Off (\(noteNumber)): \(status)")
            } else {
                print("Sent MIDI Note Off: \(noteNumber)")
            }
        }
    }

    func sendAllNotesOff() {
        guard let dest = selectedDestinationEndpointRef else {
            print("MIDIManager: No MIDI destination selected. Cannot send All Notes Off.")
            return
        }
        guard internalOutputPortRef != 0 else {
            print("MIDIManager: Internal MIDI output port is invalid. Cannot send All Notes Off.")
            return
        }

        print("MIDIManager: Sending All Notes Off to \(currentOutputName)")
        for channel: UInt8 in 0..<16 { // Iterate through all 16 MIDI channels
            var packet = MIDIPacket()
            packet.timeStamp = 0 // Send immediately
            packet.length = 3
            packet.data.0 = 0xB0 | channel // Control Change, Channel (0-15)
            packet.data.1 = 123            // Controller #123 (All Notes Off)
            packet.data.2 = 0              // Value (conventionally 0)

            var packetList = MIDIPacketList(numPackets: 1, packet: packet)
            let status = MIDISend(internalOutputPortRef, dest, &packetList)
            if status != noErr {
                print("MIDIManager: Error sending All Notes Off on channel \(channel): \(status)")
            } else {
                // print("MIDIManager: Sent All Notes Off on channel \(channel) to \(currentOutputName)")
            }
        }
        print("MIDIManager: Finished sending All Notes Off to all channels.")
    }

    // Helper function to get the display name of a MIDI object
    private func getDisplayName(for object: MIDIObjectRef) -> String {
        var param: Unmanaged<CFString>?
        var name: String = "Unknown"
        let err = MIDIObjectGetStringProperty(object, kMIDIPropertyDisplayName, &param)
        if err == noErr, let cfName = param?.takeRetainedValue() {
            name = cfName as String
        } else if err != noErr {
            print("Error getting display name for MIDI object \(object): \(err)")
        }
        // param?.release() // Not needed with takeRetainedValue()
        return name
    }

    deinit {
        // Clean up CoreMIDI resources
        if internalOutputPortRef != 0 {
            MIDIPortDispose(internalOutputPortRef)
        }
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
        // Attempt to send All Notes Off on deinit as a last resort
        // This might not always work, e.g. if the app is killed abruptly
        // or if CoreMIDI services are already torn down.
        print("MIDIManager: Deinitializing. Attempting to send All Notes Off.")
        sendAllNotesOff()
        print("MIDI Manager deinitialized and resources disposed.")
    }
}

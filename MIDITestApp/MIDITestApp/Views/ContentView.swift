import SwiftUI

import SwiftUI

struct ContentView: View {
    @StateObject private var midiManager = MIDIManager()
    // Initialize GenerativeMusicEngine and pass midiManager to it.
    // This requires GenerativeMusicEngine's init to be updated or a factory method.
    // For simplicity, we'll assume GenerativeMusicEngine's init is adapted.
    @StateObject private var generativeMusicEngine: GenerativeMusicEngine

    // Temporary state for the slider to avoid direct binding issues if not immediately reflected
    @State private var tempoSliderValue: Double

    init() {
        let midiMgr = MIDIManager()
        _midiManager = StateObject(wrappedValue: midiMgr)
        let engine = GenerativeMusicEngine(midiManager: midiMgr)
        _generativeMusicEngine = StateObject(wrappedValue: engine)
        _tempoSliderValue = State(initialValue: engine.tempo) // Initialize slider with engine's tempo
    }

    var body: some View {
        VStack {
            // MIDI Output Picker
            HStack {
                Text("MIDI Output:")
                Picker("MIDI Output", selection: $midiManager.selectedOutputPortID) {
                    Text("No Output Selected").tag(nil as String?) // Option for when nothing is selected
                    ForEach(midiManager.availableOutputPorts) { portInfo in
                        Text(portInfo.displayName).tag(portInfo.id as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Button("Refresh") {
                    midiManager.refreshAvailableOutputs()
                }
                .padding(.leading, 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

            HStack {
                Button(generativeMusicEngine.isRunning ? "Stop Sequencer" : "Start Sequencer") {
                    toggleSequencerState()
                }
                .buttonStyle(.borderedProminent)
                
                // Visual feedback for last played note
                Circle()
                    .fill(generativeMusicEngine.lastPlayedNote != nil ? Color.yellow : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .animation(.easeInOut(duration: 0.1), value: generativeMusicEngine.lastPlayedNote)
                Text("Note: \(generativeMusicEngine.lastPlayedNote.map { String($0) } ?? "-")")
                    .frame(minWidth: 80) // Give some space for the note text
            }
            .padding(.bottom)
            
            // Tempo Slider
            HStack {
                Text("Tempo: \(Int(generativeMusicEngine.tempo)) BPM")
                Slider(
                    value: $tempoSliderValue,
                    in: 60...240, // Tempo range: 60 to 240 BPM
                    step: 1,
                    onEditingChanged: { editing in
                        if !editing {
                            generativeMusicEngine.updateTempo(tempoSliderValue)
                        }
                    }
                )
                .padding(.horizontal)
            }
            .padding(.horizontal)

            // Scale Picker
            HStack {
                Text("Scale:")
                Picker("Scale", selection: $generativeMusicEngine.selectedScaleType) {
                    ForEach(MusicalScaleType.allCases) { scaleType in
                        Text(scaleType.displayName).tag(scaleType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // Octave Stepper
            HStack {
                Text("Octave: \(generativeMusicEngine.baseOctave)")
                Stepper("Octave", value: $generativeMusicEngine.baseOctave, in: 2...6)
                    .labelsHidden() // Hide the default "Octave" label from Stepper
            }
            .padding(.horizontal)
            .padding(.bottom)

            Text("Connect a MIDI-compatible app or device. Select output, tap 'Start'. Adjust tempo, scale, octave.")
                .padding()
                .multilineTextAlignment(.center)
        }
        .padding(.top) // Add some padding at the top for better layout
        .onAppear {
            // midiManager.setupMIDI() is called in its init.
            // Refreshing outputs or handling dynamic changes could be done here if needed.
            // Consider calling midiManager.refreshAvailableOutputs() here if desired
        }
        .onDisappear {
            // Ensure the engine stops and sends All Notes Off if the view disappears
            if generativeMusicEngine.isRunning {
                generativeMusicEngine.stop() // This will also call sendAllNotesOff()
            } else {
                // If engine wasn't running, still good to send AllNotesOff as a cleanup
                midiManager.sendAllNotesOff()
            }
        }
    }

    private func toggleSequencerState() {
        if generativeMusicEngine.isRunning {
            generativeMusicEngine.stop()
        } else {
            generativeMusicEngine.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, we need to provide a MIDIManager instance to GenerativeMusicEngine
        let previewMidiManager = MIDIManager()
        let previewEngine = GenerativeMusicEngine(midiManager: previewMidiManager)
        
        // Since ContentView now has an init that initializes @StateObject,
        // we can't directly pass the previewEngine.
        // Instead, we rely on the default init() path for previews,
        // which will create its own instances. This is fine for UI layout previews.
        // If specific states are needed for preview, more setup would be required.
        ContentView()
    }
}

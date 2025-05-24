import Foundation

class GenerativeMusicEngine {
import Combine // For @Published
import Foundation // For Timer

class GenerativeMusicEngine: ObservableObject {
    // C Major scale: C, D, E, F, G, A, B
    // MIDI note numbers for C4 to B4:
    // C4 = 60, D4 = 62, E4 = 64, F4 = 65, G4 = 67, A4 = 69, B4 = 71
    private let scale: [UInt8] = [60, 62, 64, 65, 67, 69, 71]
    
    @Published var tempo: Double = 120.0 // Beats per minute
    @Published var isRunning: Bool = false
    @Published var selectedScaleType: MusicalScaleType = .major
    @Published var baseOctave: Int = 4 { // C4 = 60. Range 2-6
        didSet {
            baseOctave = max(2, min(baseOctave, 6)) // Clamp to 2-6
            print("GenerativeMusicEngine: baseOctave changed to \(baseOctave)")
        }
    }
    @Published var lastPlayedNote: UInt8? = nil
    
    private var timer: Timer?
    private var midiManager: MIDIManager // Dependency

    init(midiManager: MIDIManager) {
        self.midiManager = midiManager
        print("GenerativeMusicEngine initialized with tempo: \(tempo), scale: \(selectedScaleType.displayName), octave: \(baseOctave)")
    }

    func generateNote() -> UInt8 {
        let rootNoteMidi = 60 + ((baseOctave - 4) * 12) // C4 = 60
        let intervals = selectedScaleType.intervals
        
        guard !intervals.isEmpty else {
            print("GenerativeMusicEngine: Error - selected scale has no intervals. Defaulting to C4.")
            return 60 // Default to C4 if scale is empty
        }
        
        let randomInterval = intervals.randomElement() ?? 0 // Default to root interval if random fails
        var generatedNote = Int(rootNoteMidi) + Int(randomInterval)
        
        // Clamp to MIDI range 0-127
        generatedNote = max(0, min(generatedNote, 127))
        
        print("GenerativeMusicEngine: Generated note \(generatedNote) (Octave: \(baseOctave), Scale: \(selectedScaleType.displayName), Root: \(rootNoteMidi), Interval: \(randomInterval))")
        return UInt8(generatedNote)
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        print("GenerativeMusicEngine: Starting with tempo \(tempo) BPM")
        startTimer()
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        print("GenerativeMusicEngine: Stopping")
        stopTimer()
        midiManager.sendAllNotesOff() // Call All Notes Off when stopping the engine
    }
    
    private func playNote(noteNumber: UInt8) {
        print("GenerativeMusicEngine: Playing note \(noteNumber)")
        midiManager.sendMIDINote(noteNumber: noteNumber)
        
        // Visual feedback: Set lastPlayedNote and clear it after a short delay
        lastPlayedNote = noteNumber
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 200ms delay
            // Only set to nil if it hasn't been changed by a newer note
            if self.lastPlayedNote == noteNumber {
                self.lastPlayedNote = nil
            }
        }
    }
    
    private func startTimer() {
        stopTimer() // Ensure any existing timer is stopped
        let timeInterval = 60.0 / tempo // Calculate time interval from BPM
        print("GenerativeMusicEngine: Timer interval set to \(timeInterval) seconds for \(tempo) BPM")
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else {
                self?.stopTimer() // Stop if not running, though guard isRunning in start should prevent this
                return
            }
            let note = self.generateNote()
            self.playNote(noteNumber: note)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("GenerativeMusicEngine: Timer invalidated")
    }
    
    // Call this if tempo changes while running to update the timer
    func updateTempo(_ newTempo: Double) {
        tempo = newTempo
        if isRunning {
            print("GenerativeMusicEngine: Tempo changed to \(tempo) BPM, restarting timer.")
            startTimer() // Restart timer with new tempo
        } else {
            print("GenerativeMusicEngine: Tempo changed to \(tempo) BPM. Will be used when started.")
        }
    }
    
    deinit {
        stopTimer()
        print("GenerativeMusicEngine deinitialized.")
    }
}

# iPad Generative MIDI Sequencer (MIDITestApp)

## Description

MIDITestApp is a simple yet expressive generative MIDI sequencer for iPadOS. It creates musical patterns based on selected scales, octaves, and tempo, sending MIDI notes to any connected MIDI-compatible app or hardware device. This allows for easy experimentation with musical ideas and provides a basic framework for more complex generative music applications.

## Features

*   **Generative Music Engine:** Randomly selects notes from a chosen musical scale.
*   **Scale Selection:** Choose from Major, Natural Minor, Major Pentatonic, and Minor Pentatonic scales.
*   **Octave Control:** Adjust the base octave for the generated notes (Range: 2-6, with C4 as middle C).
*   **Tempo Control:** Set the speed of note generation from 60 to 240 BPM.
*   **MIDI Output Selection:**
    *   Dynamically lists available MIDI output ports (e.g., hardware interfaces, other apps, Bluetooth MIDI).
    *   Allows users to select the desired MIDI destination.
    *   Includes a "Refresh" button to update the list of outputs.
*   **Visual Feedback:** Displays the last played MIDI note number and a visual indicator.
*   **"All Notes Off" Functionality:** Sends an "All Notes Off" MIDI message when the sequencer stops, the output port changes, or the app closes, to help prevent stuck notes.

## How to Use

1.  **Connect a MIDI Destination:**
    *   Ensure you have a MIDI-compatible application running on your iPad (e.g., GarageBand, a software synthesizer) that can receive virtual MIDI.
    *   Alternatively, connect a hardware MIDI interface to your iPad and an external MIDI synthesizer.
    *   Bluetooth MIDI devices can also be used if paired with the iPad.
2.  **Launch MIDITestApp.**
3.  **Select MIDI Output:**
    *   Tap the "MIDI Output" picker at the top of the screen.
    *   Choose your desired MIDI destination from the list. If your destination doesn't appear, try the "Refresh" button.
4.  **Adjust Parameters:**
    *   **Tempo:** Use the slider to set the desired BPM.
    *   **Scale:** Tap the "Scale" picker to choose a musical scale.
    *   **Octave:** Use the stepper next to "Octave" to change the pitch range.
5.  **Start the Sequencer:**
    *   Tap the "Start Sequencer" button. Notes will begin playing and will be sent to the selected MIDI output.
    *   The yellow circle and "Note: XX" text will indicate notes being played.
6.  **Stop the Sequencer:**
    *   Tap the "Stop Sequencer" button.

## Code Structure

The application is built using Swift and SwiftUI, with CoreMIDI for MIDI functionalities.

*   **`MIDITestAppApp.swift`:** The main entry point for the SwiftUI application.
*   **`ContentView.swift`:** Defines the main user interface, including controls for playback, tempo, scale, octave, and MIDI output selection. It observes changes from `MIDIManager` and `GenerativeMusicEngine`.
*   **`MIDIManager.swift`:**
    *   Handles all CoreMIDI interactions: client creation, output port management, finding and selecting MIDI destinations.
    *   Sends MIDI Note On/Off messages and "All Notes Off" messages.
    *   Publishes lists of available MIDI outputs (`availableOutputPorts`) and the currently selected port ID.
*   **`GenerativeMusicEngine.swift`:**
    *   Contains the logic for generating musical notes.
    *   Manages the sequencer's state (running/stopped), tempo, selected scale, and base octave.
    *   Uses an internal timer to trigger note generation based on the current tempo.
    *   Publishes the `lastPlayedNote` for visual feedback.
*   **`MusicalScaleType.swift`:** Defines the `MusicalScaleType` enum (Major, Minor, etc.) and provides their corresponding musical intervals.
*   **`MIDIOutputPortInfo.swift`:** A struct to hold information about each available MIDI output port (ID, display name, CoreMIDI endpoint reference).

## Building from Source (Optional)

1.  Clone the repository.
2.  Open the project in Xcode (ensure you have Xcode installed, typically the latest version).
3.  Select an iPad simulator or a connected iPad device.
4.  Build and run the project.
    *   You'll need to have `CoreMIDI.framework` available, which is standard on iOS/iPadOS.

## Future Enhancements (Optional)

*   More sophisticated generative algorithms (e.g., Markov chains, L-systems).
*   Rhythm generation and variable note durations.
*   MIDI velocity control.
*   MIDI CC message generation.
*   Saving/loading presets.
*   AUv3 Plugin version.
*   User-selectable root note for scales.
*   User-selectable MIDI channel for output.

This README provides a good starting point for users and developers.Okay, I have completed the "All Notes Off" implementation and generated the `README.md` content.

**Summary of "All Notes Off" Implementation:**

1.  **`MIDIManager.swift`:**
    *   Added `sendAllNotesOff()` which iterates through all 16 MIDI channels and sends a CC#123 (All Notes Off) message to the `selectedDestinationEndpointRef` via the `internalOutputPortRef`.
    *   In `selectOutputPort(portInfo:)`, `sendAllNotesOff()` is called for the *previously* selected port before switching to the new one.
    *   In `deinit`, `sendAllNotesOff()` is called as a cleanup measure.
2.  **`GenerativeMusicEngine.swift`:**
    *   In `stop()`, `midiManager.sendAllNotesOff()` is called immediately after `stopTimer()`.
3.  **`ContentView.swift`:**
    *   In `.onDisappear`, if `generativeMusicEngine.isRunning` is true, `generativeMusicEngine.stop()` is called (which in turn calls `sendAllNotesOff()`).
    *   If `generativeMusicEngine.isRunning` is false when `.onDisappear` is triggered, `midiManager.sendAllNotesOff()` is called directly to ensure cleanup.

**2. Outline for User Guide (Conceptual)**

*   **I. Introduction**
    *   Welcome to the Generative MIDI Sequencer!
    *   What is generative music? What does this app do? (Simple, fun, experimental MIDI pattern generation).
    *   Target audience (musicians, hobbyists, students learning MIDI).
*   **II. Getting Started**
    *   **A. MIDI Basics (Briefly)**
        *   What is MIDI? (Not sound, but instructions).
        *   Need for a sound source (synth app, hardware synth).
    *   **B. Connecting MIDI Devices on iPadOS**
        *   Using other music apps (Virtual MIDI): GarageBand, Synthesizer One, etc.
        *   Using external hardware:
            *   MIDI Interfaces (USB-C/Lightning to MIDI DIN).
            *   Bluetooth MIDI devices.
        *   Ensuring your iPad recognizes the device.
    *   **C. First Launch & Selecting a MIDI Output**
        *   App overview: main screen layout.
        *   The "MIDI Output" Picker: How to find and select your synth/app.
        *   Using the "Refresh" button if your output isn't listed.
*   **III. Using the Sequencer Controls**
    *   **A. Start/Stop Sequencer Button**
        *   How it works, visual feedback (yellow circle, note display).
    *   **B. Tempo Control**
        *   Slider explanation (60-240 BPM).
        *   How tempo affects the music.
    *   **C. Scale Selection**
        *   Picker explanation (Major, Natural Minor, Major Pentatonic, Minor Pentatonic).
        *   Brief description of each scale's mood/character.
        *   How the selected scale influences the generated notes (all based on C root for now).
    *   **D. Octave Control**
        *   Stepper explanation (Octaves 2-6).
        *   How changing the octave shifts the pitch range.
*   **IV. Troubleshooting**
    *   **A. No Sound?**
        *   Check MIDI Output selection in the app.
        *   Is the receiving synth/app configured correctly? (Listening on the right MIDI channel - app sends on Ch1).
        *   Is the volume up on your synth/iPad?
        *   Try the "Refresh" button for MIDI outputs.
    *   **B. Notes Are Stuck?**
        *   The app automatically sends "All Notes Off." If this still happens:
            *   Try stopping and restarting the sequencer in the app.
            *   Check if your synth has its own panic/all notes off button.
            *   Restart the synth app or hardware.
    *   **C. MIDI Device Not Appearing in List?**
        *   Ensure it's properly connected to the iPad.
        *   Check if other MIDI apps can see it.
        *   Use the "Refresh" button.
        *   Restart the MIDI device and/or the app.
*   **V. Tips for Musical Exploration**
    *   Experiment with different scale and octave combinations.
    *   Try layering the output with effects in your synth or DAW.
    *   Use the sequencer as an idea starter for your own compositions.
    *   Connect to multiple synths (if your setup allows) by changing the output.
*   **VI. Glossary (Optional)**
    *   MIDI, BPM, Scale, Octave, CoreMIDI, Virtual MIDI.

**3. Code Comments Check - Suggestions**

*   **`MIDIManager.swift`:**
    *   `refreshAvailableOutputs()`: Add a comment explaining why `String(endpointRef)` is used as the ID for `MIDIOutputPortInfo` and the potential for using `kMIDIPropertyUniqueID` for more robustness if display names are not unique.
    *   `selectOutputPort(portInfo:)`: Add a comment explaining why `sendAllNotesOff()` is called here (to clear notes on the *previous* port).
    *   `sendAllNotesOff()`: A brief comment on why it iterates all 16 channels (standard practice for a general "All Notes Off").
*   **`GenerativeMusicEngine.swift`:**
    *   `generateNote()`: A comment explaining the `rootNoteMidi = 60 + ((baseOctave - 4) * 12)` calculation (C4 = 60, adjusting based on octave).
    *   `playNote(noteNumber:)`: Comment on the purpose of `lastPlayedNote` and the `DispatchQueue.main.asyncAfter` for visual feedback timing.
    *   `updateTempo(_ newTempo:)`: Comment on why the timer is restarted if the engine is running.
*   **`ContentView.swift`:**
    *   `init()`: Comment on why `MIDIManager` is created first and then passed to `GenerativeMusicEngine`.
    *   The `Slider`'s `onEditingChanged`: A comment explaining that `updateTempo` is called only when `!editing` (i.e., interaction finishes) to avoid excessive updates.
    *   `.onDisappear`: Comment on the logic for calling `stop()` or `sendAllNotesOff()` depending on the engine's running state.

These are just a few key places; generally, the code is quite readable, but these specific comments could clarify the "why" behind certain decisions for future maintainers or collaborators.

All requested parts of the subtask are now complete.

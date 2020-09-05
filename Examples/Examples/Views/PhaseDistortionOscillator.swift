import AudioKit
import SwiftUI
import AudioToolbox

struct PhaseDistortionOscillatorData {
    var isPlaying: Bool = false
    var phaseDistortion: AUValue = 1.0
    var frequency: AUValue = 440
    var amplitude: AUValue = 0.1
    var rampDuration: AUValue = 1
}

class PhaseDistortionOscillatorConductor: ObservableObject, AKKeyboardDelegate {

    let engine = AKEngine()

    func noteOn(note: MIDINoteNumber) {
        data.isPlaying = true
        data.frequency = note.midiNoteToFrequency()
    }

    func noteOff(note: MIDINoteNumber) {
        data.isPlaying = false
    }

    @Published var data = PhaseDistortionOscillatorData() {
        didSet {
            if data.isPlaying {
                osc.start()
                osc.$phaseDistortion.ramp(to: data.phaseDistortion, duration: data.rampDuration)
                osc.$frequency.ramp(to: data.frequency, duration: data.rampDuration)
                osc.$amplitude.ramp(to: data.amplitude, duration: data.rampDuration)

            } else {
                osc.amplitude = 0.0
            }
        }
    }

    var osc = AKPhaseDistortionOscillator()

    let plot: AKNodeOutputPlot

    init() {
        engine.output = osc
        plot = AKNodeOutputPlot(osc)
    }

    func start() {
        plot.start()
        osc.amplitude = 0.2
        do {
            try engine.start()
        } catch let err {
            AKLog(err)
        }
    }

    func stop() {
        data.isPlaying = false
        osc.stop()
        engine.stop()
    }
}

struct PhaseDistortionOscillatorView: View {
    @ObservedObject var conductor  = PhaseDistortionOscillatorConductor()
//    var plotView = PlotView()

    var body: some View {
        VStack {
            Text(self.conductor.data.isPlaying ? "STOP" : "START").onTapGesture {
                self.conductor.data.isPlaying.toggle()
            }
            ParameterSlider(text: "Phase Distortion",
                            parameter: self.$conductor.data.phaseDistortion,
                            range: -1 ... 1,
                format: "%0.2f").padding(5)
            ParameterSlider(text: "Frequency",
                            parameter: self.$conductor.data.frequency,
                            range: 220...880,
                            format: "%0.2f").padding(5)
            ParameterSlider(text: "Amplitude",
                            parameter: self.$conductor.data.amplitude,
                            range: 0 ... 1,
                            format: "%0.2f").padding(5)
            ParameterSlider(text: "Ramp Duration",
                            parameter: self.$conductor.data.rampDuration,
                            range: 0...10,
                            format: "%0.2f").padding(5)

            PlotView(view: conductor.plot)
            KeyboardView(delegate: conductor)

        }.navigationBarTitle(Text("Phase Distortion"))
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct PhaseDistortionOscillatorView_Previews: PreviewProvider {
    static var previews: some View {
        PhaseDistortionOscillatorView()
    }
}

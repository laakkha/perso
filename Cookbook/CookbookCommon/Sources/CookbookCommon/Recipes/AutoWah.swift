import AudioKit
import AudioKitUI
import AVFoundation
import SoundpipeAudioKit
import SwiftUI

struct AutoWahData {
    var wah: AUValue = 0.0
    var mix: AUValue = 1.0
    var amplitude: AUValue = 0.1
    var rampDuration: AUValue = 0.02
    var balance: AUValue = 0.5
}

class AutoWahConductor: ObservableObject, ProcessesPlayerInput {
    let engine = AudioEngine()
    let player = AudioPlayer()
    let autowah: AutoWah
    let dryWetMixer: DryWetMixer
    let buffer: AVAudioPCMBuffer

    init() {
        buffer = Cookbook.sourceBuffer
        player.buffer = buffer
        player.isLooping = true

        autowah = AutoWah(player)
        dryWetMixer = DryWetMixer(player, autowah)

        engine.output = dryWetMixer

    }

    @Published var data = AutoWahData() {
        didSet {
            autowah.$wah.ramp(to: data.wah, duration: data.rampDuration)
            autowah.$mix.ramp(to: data.mix, duration: data.rampDuration)
            autowah.$amplitude.ramp(to: data.amplitude, duration: data.rampDuration)
            dryWetMixer.balance = data.balance
        }
    }

    func start() {
        do { try engine.start() } catch let err { Log(err) }
    }

    func stop() {
        engine.stop()
    }
}

struct AutoWahView: View {
    @StateObject var conductor = AutoWahConductor()

    var body: some View {
        ScrollView {
            PlayerControls(conductor: conductor)
            ParameterSlider(text: "Wah",
                            parameter: self.$conductor.data.wah,
                            range: 0.0...1.0,
                            units: "Percent")
            ParameterSlider(text: "Mix",
                            parameter: self.$conductor.data.mix,
                            range: 0.0...1.0,
                            units: "Percent")
            ParameterSlider(text: "Amplitude",
                            parameter: self.$conductor.data.amplitude,
                            range: 0.0...1.0,
                            units: "Percent")
            ParameterSlider(text: "Mix",
                            parameter: self.$conductor.data.balance,
                            range: 0...1,
                            units: "%")
            DryWetMixView(dry: conductor.player, wet: conductor.autowah, mix: conductor.dryWetMixer)
        }
        .padding()
        .cookbookNavBarTitle("Auto Wah")
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct AutoWah_Previews: PreviewProvider {
    static var previews: some View {
        AutoWahView()
    }
}

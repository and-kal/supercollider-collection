// Splayedosc — FM-chain oscillator bank (PinkNoise → PulseDPW → SinOsc → ...)
// Requires sc3-plugins: PulseDPW

// TODO: volume is very low, MIDI notes don't do much

s.boot;

ServerMeter.new(s);

(
SynthDef(\mulos, { |freq = 200, sustain = 0.5|
    var i    = 20;
    var env  = EnvGen.ar(Env.new([0, 1/i, 0], [sustain, sustain]), doneAction: 2);

    // FM chain: each oscillator pitch-modulates the next
    var osc1 = PinkNoise.ar(mul: env);
    var osc2 = PulseDPW.ar(freq + (osc1 * Rand(0.0, 1.0)), mul: env);
    var osc3 = SinOsc.ar(  freq + (osc2 * Rand(0.0, 1.0)), mul: env);
    var osc4 = PulseDPW.ar(freq + (osc3 * Rand(0.0, 1.0)), mul: env);
    var osc5 = Saw.ar(     freq + (osc4 * Rand(0.0, 1.0)), mul: env);
    // osc6 was PinkNoise with (freq+prev) as its mul arg — wrong; replaced with LFNoise0
    var osc6 = LFNoise0.ar(freq + (osc5 * Rand(0.0, 0.1)), mul: env);
    var osc7 = SinOsc.ar(  freq + (osc6 * Rand(0.0, 1.0)), mul: env);
    var osc8 = Saw.ar(     freq + (osc7 * Rand(0.0, 1.0)), mul: env);

    var bank = [osc1, osc2, osc3, osc4, osc5, osc6, osc7, osc8];

    // Ringz resonator bank; filter freq sweeps 200–8000 Hz at 0.125 Hz
    var fx   = Ringz.ar(bank, SinOsc.kr(0.125, 0, 4000, 4200), mul: env / 20);

    // fixed: Compander result was discarded — now used before Splay
    var out  = Compander.ar(fx, fx, thresh: 0.9, mul: 2);
    Out.ar(0, Splay.ar(out));
}).add;
)

// Freq array: 100–129 Hz (ultra-low, becomes more complex via FM chain)
~splayFreqs = Array.fill(30, { |i| i + 100 });

(
Pdef(\arppp, Pbind(
    \instrument, \mulos,
    \freq, Pxrand(~splayFreqs, inf),
    \dur,  Prand([0.5, 0.5, 0.5, 0.25, 0.125], inf)
));
)

(
var w = Window("Splayedosc", Rect(200, 200, 440, 310)).front;
var freqLoBox = NumberBox(w, Rect(160, 46, 60, 22)).value_(100).clipLo_(5).clipHi_(2000);
var freqHiBox = NumberBox(w, Rect(160, 78, 60, 22)).value_(129).clipLo_(5).clipHi_(2000);

StaticText(w, Rect(10, 10, 420, 20)).string_("Splayedosc — FM-Chain Bank").align_(\center);

// Frequency range of the pool
StaticText(w, Rect(10, 48, 140, 20)).string_("Freq pool low (Hz):");

StaticText(w, Rect(10, 80, 140, 20)).string_("Freq pool high (Hz):");

Button(w, Rect(240, 46, 150, 56))
    .states_([["Apply freq range", Color.black, Color.grey(0.8)]])
    .action_({
        var lo = freqLoBox.value.round.asInteger;
        var hi = freqHiBox.value.round.asInteger.max(lo + 1);
        ~splayFreqs = Array.fill(30, { rrand(lo, hi) });
        Pdef(\arppp, Pbind(
            \instrument, \mulos,
            \freq, Pxrand(~splayFreqs, inf),
            \dur,  Prand([0.5, 0.5, 0.5, 0.25, 0.125], inf)
        ));
    });

StaticText(w, Rect(10, 120, 140, 20)).string_("Tempo:");
Slider(w, Rect(160, 120, 260, 20))
    .value_(0.5)
    .action_({ |v| TempoClock.default.tempo_(v.value.linlin(0, 1, 0.3, 4.0)) });

StaticText(w, Rect(10, 154, 140, 20)).string_("Note sustain:");
Slider(w, Rect(160, 154, 260, 20))
    .value_(0.4)
    .action_({ |v|
        Pdef(\arppp, Pbind(
            \instrument, \mulos,
            \freq,    Pxrand(~splayFreqs, inf),
            \dur,     Prand([0.5, 0.5, 0.5, 0.25, 0.125], inf),
            \sustain, v.value.linlin(0, 1, 0.05, 2.0)
        ));
    });

// MIDI input
StaticText(w, Rect(10, 195, 420, 16)).string_("── MIDI input ──").align_(\center);
Button(w, Rect(10, 215, 160, 28))
    .states_([["Enable MIDI", Color.black, Color.grey(0.8)], ["MIDI active", Color.black, Color.green]])
    .action_({ |btn|
        if (btn.value == 1) {
            MIDIClient.init;
            MIDIIn.connectAll;
            MIDIdef.noteOn(\splayOn, { |vel, note|
                Synth(\mulos, [\freq, note.midicps, \sustain, 0.4]);
            });
        } {
            MIDIdef(\splayOn).free;
        };
    });

Button(w, Rect(10, 262, 100, 38))
    .states_([["Play", Color.black, Color.green]])
    .action_({ Pdef(\arppp).play });

Button(w, Rect(125, 262, 100, 38))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ Pdef(\arppp).stop });
)

// Tuning.directory;  // kept as reference — lists all available tuning systems

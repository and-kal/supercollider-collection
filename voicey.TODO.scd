// Voicey — resonant pulse oscillator melody
// Original concept kept; fixed compile-time randoms and added GUI

s.boot;

(
SynthDef(\voicey, { |freq = 440, rel = 0.3, amp = 0.5, pan = 0|
    var duty     = Rand(0.0, 1.0);            // per-note random duty cycle
    var filtFreq = freq + Rand(200, 2000);    // per-note random filter freq
    var sig = PulseDPW.ar(
        freq * LFNoise2.kr(17, 0.1, 1),
        duty,
        EnvGen.ar(Env.perc(releaseTime: rel, level: 0.5), doneAction: 2)
    );
    sig = Resonz.ar(sig, filtFreq, 0.15);    // rq 0.15 — tight resonance
    Out.ar(0, Pan2.ar(sig * amp, pan));
}).add;
)

// Shared state for GUI ↔ pattern
~voiceyScale   = Scale.minorPentatonic;
~voiceyOctave  = 7;
~voiceyDegrees = [0, 2, 4, 3, 6, 5, 4];

~buildVoicey = {
    Pdef(\voicey, Pbind(
        \instrument, \voicey,
        \scale,  ~voiceyScale,
        \degree, Pseq(~voiceyDegrees, inf),
        \octave, ~voiceyOctave,
        \rel,    Pxrand(Array.fib(10, 0.02, 0.03), inf),
        \dur,    Prand([0.5, 0.5, 0.5, 1] / 2, inf)
    ))
};

~buildVoicey.();

// GUI
(
var w = Window("Voicey", Rect(300, 200, 430, 265)).front;

StaticText(w, Rect(10, 10, 410, 20))
    .string_("Voicey — Resonant Pulse Melody").align_(\center);

StaticText(w, Rect(10, 48, 100, 20)).string_("Scale:");
PopUpMenu(w, Rect(120, 46, 180, 22))
    .items_(["Minor pentatonic", "Major", "Dorian", "Phrygian", "Kumoi", "Hirajoshi"])
    .value_(0)
    .action_({ |m|
        ~voiceyScale = [
            Scale.minorPentatonic, Scale.major, Scale.dorian,
            Scale.phrygian, Scale.kumoi, Scale.hirajoshi
        ][m.value];
        ~buildVoicey.();
    });

StaticText(w, Rect(10, 82, 100, 20)).string_("Octave:");
Slider(w, Rect(120, 82, 290, 20))
    .value_(0.5)
    .action_({ |v|
        ~voiceyOctave = v.value.linlin(0, 1, 3, 9).round.asInteger;
        ~buildVoicey.();
    });

StaticText(w, Rect(10, 116, 100, 20)).string_("Tempo:");
Slider(w, Rect(120, 116, 290, 20))
    .value_(0.5)
    .action_({ |v| TempoClock.default.tempo_(v.value.linlin(0, 1, 0.3, 4.0)) });

StaticText(w, Rect(10, 150, 100, 20)).string_("Release:");
Slider(w, Rect(120, 150, 290, 20))
    .value_(0.3)
    .action_({ |v|
        // rebuilds Pdef with new rel range
        var top = v.value.linlin(0, 1, 0.05, 2.0);
        Pdef(\voicey, Pbind(
            \instrument, \voicey,
            \scale,  ~voiceyScale,
            \degree, Pseq(~voiceyDegrees, inf),
            \octave, ~voiceyOctave,
            \rel,    Prand(Array.series(6, 0.02, top/6), inf),
            \dur,    Prand([0.5, 0.5, 0.5, 1] / 2, inf)
        ));
    });

Button(w, Rect(10, 200, 90, 42))
    .states_([["Play", Color.black, Color.green]])
    .action_({ Pdef(\voicey).play });

Button(w, Rect(115, 200, 90, 42))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ Pdef(\voicey).stop });

Button(w, Rect(260, 200, 155, 42))
    .states_([["Random melody", Color.black, Color.yellow]])
    .action_({
        ~voiceyDegrees = Array.fill(rrand(4, 9), { rrand(0, 7) });
        ~buildVoicey.();
    });
)

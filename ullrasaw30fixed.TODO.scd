// Ullra-saw — 30-voice detuned SawDPW with FreqShift shimmer
// Requires sc3-plugins: SawDPW
// Fixed: degree arg was declared but never used (freq now passed properly);
//        dur default was 0 → silent envelope (renamed to sustain);
//        (30.midicps.rand) could be 0 → replaced with Rand(0.98, 1.02);
//        FreqShift had no shift argument (no-op) → enabled

s.boot;

(
SynthDef(\saw30, { |freq = 220, sustain = 2|
    var mix = Mix.fill(30, { |i|
        Pan2.ar(
            SawDPW.ar(
                freq * [1, 0.5, 2, 0.25, 1.5].choose * Rand(0.98, 1.02),
                Rand(-0.5, 0.5),
                EnvGen.ar(
                    Env.linen(attackTime: sustain/4, sustainTime: sustain/2, releaseTime: sustain, level: 0.04),
                    doneAction: 2
                )
            ),
            Rand(-1, 1)
        )
    });
    // subtle frequency shimmer via slowly modulated shift (0–50 Hz)
    Out.ar(0, FreqShift.ar(mix, FSinOsc.ar(100, 0, 50).unipolar));
}).add;
)

(
Pdef(\sawww, Pbind(
    \instrument, \saw30,
    \scale,  Scale.scriabin,
    \degree, Prand(Array.fill(12, { |i| i + 0.7 }), inf),  // fractional → microtonal
    \dur,    Prand(Array.fill(8, { |i| i = i * (i / 8) }), inf)
));
)

(
var w = Window("Ullra-Saw 30", Rect(200, 200, 440, 290)).front;

StaticText(w, Rect(10, 10, 420, 20)).string_("Ullra-Saw 30 — Detuned Saw Cluster").align_(\center);

StaticText(w, Rect(10, 48, 130, 20)).string_("Scale:");
PopUpMenu(w, Rect(150, 46, 180, 22))
    .items_(["Scriabin", "Prometheus", "Whole tone", "Chromatic", "Messiaen7"])
    .value_(0)
    .action_({ |m|
        var sc = [Scale.scriabin, Scale.prometheus, Scale.wholeTone,
                  Scale.chromatic, Scale.messiaen7thMode][m.value];
        Pdef(\sawww, Pbind(
            \instrument, \saw30,
            \scale,  sc,
            \degree, Prand(Array.fill(sc.size, { |i| i + 0.7 }), inf),
            \dur,    Prand(Array.fill(8, { |i| i = i * (i/8) }), inf)
        ));
    });

StaticText(w, Rect(10, 82, 130, 20)).string_("Register (octave):");
Slider(w, Rect(150, 82, 270, 20))
    .value_(0.5)
    .action_({ |v|
        Pdef(\sawww, Pbind(
            \instrument, \saw30,
            \scale,  Scale.scriabin,
            \degree, Prand(Array.fill(12, { |i| i + 0.7 }), inf),
            \octave, v.value.linlin(0, 1, 2, 8).round.asInteger,
            \dur,    Prand(Array.fill(8, { |i| i = i * (i/8) }), inf)
        ));
    });

StaticText(w, Rect(10, 116, 130, 20)).string_("Tempo:");
Slider(w, Rect(150, 116, 270, 20))
    .value_(0.5)
    .action_({ |v| TempoClock.default.tempo_(v.value.linlin(0, 1, 0.2, 3.0)) });

StaticText(w, Rect(10, 150, 130, 20)).string_("Note duration:");
Slider(w, Rect(150, 150, 270, 20))
    .value_(0.4)
    .action_({ |v|
        Pdef(\sawww, Pbind(
            \instrument, \saw30,
            \scale,  Scale.scriabin,
            \degree, Prand(Array.fill(12, { |i| i + 0.7 }), inf),
            \sustain, v.value.linlin(0, 1, 0.1, 6.0),
            \dur,    Prand(Array.fill(8, { |i| i = i * (i/8) }), inf)
        ));
    });

Button(w, Rect(10, 228, 100, 42))
    .states_([["Play", Color.black, Color.green]])
    .action_({ Pdef(\sawww).play });

Button(w, Rect(125, 228, 100, 42))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ Pdef(\sawww).stop });
)

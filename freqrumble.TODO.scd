// VosimOsc (sc3-plugins) + Dust, BPF compression

// TODO: spawning too many synths when freq and dur are low

s.boot;

(
SynthDef(\rumb, { |freq = 60, sustain = 2, det = 300, i = 10|
    var times   = [1, 5, 3, 5];
    var trigger = Impulse.kr(1 / i);
    var env     = EnvGen.ar(
        Env.new([0, 1, 0.6, 0.8, 0] / i, times, releaseNode: 2),
        gate: trigger, doneAction: Done.freeSelf
    );
    // Line sweeps detuner depth over the note lifetime — no separate doneAction needed
    var detuner = FSinOsc.kr(TRand.kr(10, 40, trigger), 0, Line.kr(0, 700, times.sum), det);
    var out = Mix.fill(10, {
        [
            VosimOsc.ar(freq, freq * 1.01, freq * 0.99) * env,
            Dust.ar(freq * detuner * [500, 20, 30, 100].choose, mul: env)
        ].choose
    });
    out = Compander.ar(BPF.ar(out, freq * 1.5, rq: 0.7), out);
    Out.ar(0, Splay.ar(out));
}).add;
)

// Global state — sliders write to these; Pfunc reads them per event
~rumbFreqLo = 30;
~rumbFreqHi = 150;
~rumbDurLo  = 2;
~rumbDurHi  = 3;
~rumbDet    = 300;
~rumbI      = 10;

(
Pdef(\rumble, Pbind(
    \instrument, \rumb,
    \freq,    Pfunc { ~rumbFreqLo.rrand(~rumbFreqHi.max(~rumbFreqLo + 1)) },
    \sustain, Pfunc { ~rumbDurLo.rrand(~rumbDurHi.max(~rumbDurLo + 0.1)) },
    \det,     Pfunc { ~rumbDet },
    \i,       Pfunc { ~rumbI }
));
)

(
var w = Window("Low Freq Rumble", Rect(200, 200, 440, 290)).front;

StaticText(w, Rect(10, 10, 420, 20)).string_("Low-Frequency Rumble").align_(\center);

StaticText(w, Rect(10, 48, 130, 20)).string_("Freq low (Hz):");
Slider(w, Rect(150, 48, 270, 20))
    .value_(0.1)
    .action_({ |v| ~rumbFreqLo = v.value.linlin(0, 1, 5, 400).round });

StaticText(w, Rect(10, 80, 130, 20)).string_("Freq high (Hz):");
Slider(w, Rect(150, 80, 270, 20))
    .value_(0.4)
    .action_({ |v| ~rumbFreqHi = v.value.linlin(0, 1, 5, 400).round });

StaticText(w, Rect(10, 112, 130, 20)).string_("Detune depth:");
Slider(w, Rect(150, 112, 270, 20))
    .value_(0.43)
    .action_({ |v| ~rumbDet = v.value.linlin(0, 1, 0, 700) });

StaticText(w, Rect(10, 144, 130, 20)).string_("Note duration (s):");
Slider(w, Rect(150, 144, 270, 20))
    .value_(0.4)
    .action_({ |v|
        ~rumbDurLo = v.value.linlin(0, 1, 0.5, 8);
        ~rumbDurHi = ~rumbDurLo * 1.5;
    });

StaticText(w, Rect(10, 176, 130, 20)).string_("Time scale (i):");
Slider(w, Rect(150, 176, 270, 20))
    .value_(0.5)
    .action_({ |v| ~rumbI = v.value.linlin(0, 1, 2, 30) });

Button(w, Rect(10, 228, 100, 42))
    .states_([["Play", Color.black, Color.green]])
    .action_({ Pdef(\rumble).play });

Button(w, Rect(125, 228, 100, 42))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ Pdef(\rumble).stop });
)

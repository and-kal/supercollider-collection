// Datari — AY chip synth with FreqShift + comb delay
// Requires sc3-plugins: AY

s.boot;

ServerMeter.new(s);

(
SynthDef(\2600, { |midi1 = 60, midi2 = 64, midi3 = 67, sustain = 0.5, shift = -90|
var env = EnvGen.kr(Env([0, 0.5, 0.25, 0], [0.001, sustain, 5]), doneAction: 2);
var sig1 = FreqShift.ar(
AY.ar(
midi1.midicps,
midi2.midicps,
midi3.midicps,
5, 5, vola: 11, volb: 12, volc: 14, chiptype: 0, mul: env / 2
),
shift, mul: 1.2
);
var sig2 = CombC.ar(sig1,
maxdelaytime: 40.reciprocal,
delaytime: 40.reciprocal,
decaytime: 1.5,
mul: 0.5
);
Out.ar(0, Rotate2.ar(sig1, sig2, SinOsc.ar(1, mul: 0.7)));
}).add;
)

// Mutable state for GUI controls
~datariShiftLo = -100;
~datariShiftHi = -80;
~datariNotes1 = [32, 49, 56, 73];
~datariNotes2 = [32, 49, 56, 63];
~datariNotes3 = [34, 46, 58, 59];

~buildDatari = {
Pdef(\datari, Pbind(
\instrument, \2600,
\midi1, Prand(~datariNotes1, inf),
\midi2, Pseq(~datariNotes2, inf),
\midi3, Pseq(~datariNotes3, inf),
\shift, Pfunc { ~datariShiftLo.rrand(~datariShiftHi) },
\dur, Prand(Array.rand(12, 0.5, 0.25) \* 2, inf)
)).fadeTime\_(4)
};
~buildDatari.();

(
var w = Window("Datari — AY Chip Synth", Rect(200, 180, 450, 310)).front;

StaticText(w, Rect(10, 10, 430, 20)).string*("Datari — AY Chip + FreqShift").align*(\center);

// FreqShift range
StaticText(w, Rect(10, 48, 140, 20)).string*("Shift low (Hz):");
Slider(w, Rect(160, 48, 270, 20))
.value*(0.5)
.action\_({ |v| ~datariShiftLo = v.value.linlin(0, 1, -300, 0).round });

StaticText(w, Rect(10, 80, 140, 20)).string*("Shift high (Hz):");
Slider(w, Rect(160, 80, 270, 20))
.value*(0.6)
.action\_({ |v| ~datariShiftHi = v.value.linlin(0, 1, -300, 0).round });

// Transpose voices
StaticText(w, Rect(10, 112, 140, 20)).string*("Transpose (semit):");
Slider(w, Rect(160, 112, 270, 20))
.value*(0.5)
.action\_({ |v|
var offset = v.value.linlin(0, 1, -24, 24).round.asInteger;
~datariNotes1 = [32, 49, 56, 73].collect { |n| n + offset };
~datariNotes2 = [32, 49, 56, 63].collect { |n| n + offset };
~datariNotes3 = [34, 46, 58, 59].collect { |n| n + offset };
~buildDatari.();
});

// Tempo
StaticText(w, Rect(10, 144, 140, 20)).string*("Tempo:");
Slider(w, Rect(160, 144, 270, 20))
.value*(0.5)
.action*({ |v| TempoClock.default.tempo*(v.value.linlin(0, 1, 0.2, 3.0)) });

// Randomise note sequences
Button(w, Rect(10, 188, 180, 32))
.states*([["Randomise notes", Color.black, Color.yellow]])
.action*({
var r = { rrand(24, 80) };
~datariNotes1 = Array.fill(4, r);
~datariNotes2 = Array.fill(4, r);
~datariNotes3 = Array.fill(4, r);
~buildDatari.();
});

Button(w, Rect(10, 248, 100, 42))
.states*([["Play", Color.black, Color.green]])
.action*({ Pdef(\datari).play(TempoClock, quant: 1) });

Button(w, Rect(125, 248, 100, 42))
.states*([["Stop", Color.black, Color.red]])
.action*({ Pdef(\datari).stop });
)

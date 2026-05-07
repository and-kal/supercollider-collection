// Fractal beat / L-system rhythm generator
// Lindenmayer system approach based on: https://theseanco.github.io/howto_co34pt_liveCode/3-6-L-Systems-For-Rhythm/

s.boot;
s.waitForBoot({

// --- Set your samples directory here (use forward slashes) ---
~samplesDir = "C:/Users/Li/Documents/samples breaks/vk-sample-packs/random/*";

~buffy = SoundFile.collectIntoBuffers(~samplesDir, s);
~buffy.inspect;

// --- Sampler SynthDef ---
SynthDef(\sampler, { |bufnum, rate = 1, amp = 1|
    var a = PlayBuf.ar(1, bufnum, rate, doneAction: 2);
    Out.ar(0, Pan2.ar(a * amp, 0));
}).add;

// --- AY synth SynthDef ---
SynthDef(\shoo, { |degree = 1, fres = 0.5|
    var fmosc = Saw.ar(0.1, 1000, 10025);
    var env   = EnvGen.ar(Env.perc(level: 0.2), doneAction: 2);
    var osc   = AY.ar(degree * 100, degree * 200, degree * 300, 0.1, mul: env);
    osc = DFM1.ar(osc, fmosc, fres, mul: 0.8);
    Out.ar(0, Pan2.ar(osc, SinOsc.ar(0.01)));
}).add;

s.sync;
"Buffers and SynthDefs ready.".postln;
});

// --- L-system patterns ---

(
~lind = Pseq([Prewrite(1, (
    1:    [1, 2, 3] / 2,
    3/2:  [1, 5] / 6,
    1/6:  [1, 2, 4] / 4,
    4/4:  1
), 4)], inf);
)

// Inspect the L-system output:
// (r = ~lind.asStream; 30.do { r.next.postln });

// --- MIDI output setup ---
(
MIDIClient.init;
~midiOut = MIDIOut.newByName("loopMIDI Port", "loopMIDI Port");
~midiOut.latency_(Server.default.latency);
)

// --- Percussion patterns ---

~t = TempoClock(115 / 60);
~bufIdx = 1;   // change this to swap kick buffer on the fly

(
Pdef(\kiii, Pbind(
    \instrument, \sampler,
    \dur,   ~lind * 1,
    \bufnum, Pfunc { ~buffy[~bufIdx] },
    \rate,  0.9
)).play(~t);

Pdef(\snaa, Pbind(
    \instrument, \sampler,
    \dur,   (~lind + 0.001) * 2,
    \bufnum, ~buffy[13],
    \rate,  Prand([7, 4, 2, 1.5, 0.8, 0.5], inf)
)).play(~t);
)

// Swap kick buffer on the fly — just change ~bufIdx:
// ~bufIdx = 3;

// --- 85 bpm clock ---

~t2 = TempoClock(85 / 60 / 4);

(
~lind2 = Pseq([Prewrite(1, (
    1:     [0.75, 1.5, 2] / 2,
    24/32: [6/2, 3/4, 1/4, 0.5/4],
    3/4:   [24, 12, 8, 4] / 32,
    12/32: [1/3, 2/3, 1/4, 2/4, 0.5/4]
), levels: 1)], inf);
)

(
Pbind(
    \type,    \midi,
    \midiout, ~midiOut,
    \chan,    2,
    \degree,  -3,
    \dur,     0.25
).play(~t2, quant: 1);
)

(
Pdef(\midmid, Pbind(
    \type,     \midi,
    \midiout,  ~midiOut,
    \chan,     1,
    \velocity, 30,
    \degree,   -10,
    \dur, Pseq([Prewrite(1, (
        1:      [0.75, 1.25, 0.5] / 2,
        0.75:   [4, 2] / 8,
        2/8:    [2.5] / 4,
        2.5/4:  [16, 8, 4] / 32,
        8/32:   [0.5, 0.25, 0.75, 1.5, 1.25] / 2,
        1.25/2: [0.25, 0.5, 1.25] / 2
    ), levels: 2)], inf)
)).play(~t2, quant: 1);
)

// --- Additional pattern using lind2 ---

(
Pdef(\more, Pbind(
    \instrument, \sampler,
    \dur,    ~lind2 + 0.01,
    \bufnum, ~buffy[11],
    \rate,   ~lind2 * 4
)).play(~t2, quant: Quant(2, 0));
)

// --- AY synth with integer L-system ---

(
~lindSynth = Pseq([Prewrite(1, (
    1: [1, 3, 8],
    3: [9, 5, 11],
    5: [12, 3, 2]
), 48)], inf);
)

(
Pdef(\synthLine, Pbind(
    \instrument, \shoo,
    \scale,  Scale.kumoi,
    \degree, Pfunc { ~lindSynth.next } / 2,
    \dur,    Prand([0.1, 0.15, 0.2], inf)
)).play(~t2, quant: 1);
)

// Stop everything:
// [Pdef(\kiii), Pdef(\snaa), Pdef(\midmid), Pdef(\more), Pdef(\synthLine)].do(_.stop);

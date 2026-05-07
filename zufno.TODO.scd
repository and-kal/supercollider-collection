// Zufno — two-layer stochastic instrument
// Layer 1: Gendy1 dynamic stochastic synthesis (melodic)
// Layer 2: Latch/S&H digital texture (percussive)

s.boot;

(
// Gendy1 stochastic synth with heavy reverb
SynthDef(\gengen, { |out = 0, freq = 500, gate = 1, amp = 0.5|
    var sig = Gendy1.ar(
        SinOsc.kr(10, 0, 0.5, 0.5),
        SinOsc.kr(10, 0, 0.5, 0.5),
        SinOsc.kr(10, 0, 0.5, 0.5),
        SinOsc.kr(10, 0, 0.5, 0.5),
        freq, freq * 1.5,
        SinOsc.kr(10, 0, 0.5, 0.5),
        SinOsc.kr(10, 0, 0.5, 0.5),
        12,
        Latch.kr(SinOsc.kr(0.125, 0, 6, 6), Impulse.kr(2)),
        mul: 0.75
    );
    var env = EnvGen.ar(Env.adsr(0.1, 0.2, 0.5, 0.2, 0.5), gate, doneAction: 2);
    sig = FreeVerb.ar(sig, 1, 0.9, 0.9);
    Out.ar(out, Pan2.ar(sig * env * amp));
}).add;

// Latched sine sample-and-hold — sharp digital percussive texture
SynthDef(\zufno, { |amp = 0.5|
    var env = EnvGen.ar(Env.perc(0.02, 0.5, 0.4), 1, doneAction: 2);
    var sig = Latch.ar(SinOsc.ar(10000), Impulse.kr([100, 101]));
    var fx  = FreeVerb.ar(sig.sum, 0.8, 0.9, 0.8);
    Out.ar(0, (fx * env * amp) ! 2);
}).add;
)

// Gendy melodic pattern — \nikriz is an Ottoman maqam scale
// substitute Scale.phrygian or Scale.dorian if \nikriz is unavailable
(
~genScale  = \nikriz;
~genNotes  = [0, 2, 3, 7, 11, 13] + 55;

~buildGenPat = {
    Pdef(\gengen, Pbind(
        \instrument, \gengen,
        \dur,      Prand([0.2, 0.3, 0.5, 0.6] * 4, inf),
        \midinote, Pseq(~genNotes, inf),
        \scale,    ~genScale,
        \amp,      0.4
    ))
};
~buildGenPat.();
)

// GUI
(
var w = Window("Zufno", Rect(200, 180, 450, 310)).front;
var zufnoTask;

StaticText(w, Rect(10, 10, 430, 20))
    .string_("Zufno — Gendy Stochastic + Latch Texture").align_(\center);

// --- Gendy section ---
StaticText(w, Rect(10, 44, 430, 16)).string_("── GENDY MELODY ──").align_(\center);

StaticText(w, Rect(10, 66, 90, 20)).string_("Scale:");
PopUpMenu(w, Rect(110, 64, 180, 22))
    .items_(["Nikriz", "Phrygian", "Dorian", "Minor penta", "Hirajoshi"])
    .value_(0)
    .action_({ |m|
        ~genScale = [\nikriz, Scale.phrygian, Scale.dorian,
                     Scale.minorPentatonic, Scale.hirajoshi][m.value];
        ~buildGenPat.();
    });

StaticText(w, Rect(10, 100, 90, 20)).string_("Tempo:");
Slider(w, Rect(110, 100, 310, 20))
    .value_(0.33)
    .action_({ |v| TempoClock.default.tempo_(v.value.linlin(0, 1, 0.2, 3.0)) });

Button(w, Rect(10, 136, 110, 32))
    .states_([["Start Gendy", Color.black, Color.green]])
    .action_({ Pdef(\gengen).play });

Button(w, Rect(130, 136, 110, 32))
    .states_([["Stop Gendy", Color.black, Color.red]])
    .action_({ Pdef(\gengen).stop });

Button(w, Rect(260, 136, 170, 32))
    .states_([["Randomise notes", Color.black, Color.yellow]])
    .action_({
        ~genNotes = Array.fill(rrand(4, 8), { rrand(48, 72) });
        ~buildGenPat.();
    });

// --- Zufno section ---
StaticText(w, Rect(10, 188, 430, 16)).string_("── LATCH TEXTURE ──").align_(\center);

Button(w, Rect(10, 210, 110, 32))
    .states_([["Fire once", Color.black, Color.cyan]])
    .action_({ Synth(\zufno) });

var zufnoAmpSl = Slider(w, Rect(10, 255, 310, 20)).value_(0.5);
StaticText(w, Rect(330, 253, 80, 20)).string_("Texture amp");

Button(w, Rect(10, 254, 0, 0)); // placeholder — using slider above

Button(w, Rect(130, 210, 150, 32))
    .states_([["Auto-fire on", Color.black, Color.green], ["Auto-fire off", Color.black, Color.red]])
    .action_({ |btn|
        if (btn.value == 1) {
            zufnoTask.stop;
            zufnoTask = Task({
                loop({
                    Synth(\zufno, [\amp, zufnoAmpSl.value * 0.8]);
                    Prand([0.5, 1.0, 1.5, 2.0], 1).asStream.next.wait;
                });
            }).start;
        } { zufnoTask.stop; zufnoTask = nil };
    });

// Stop all
Button(w, Rect(10, 266, 110, 32))
    .states_([["Stop all", Color.black, Color.red(0.8)]])
    .action_({
        Pdef(\gengen).stop;
        zufnoTask.stop; zufnoTask = nil;
    });

w.onClose_({
    Pdef(\gengen).stop;
    zufnoTask.stop;
});
)

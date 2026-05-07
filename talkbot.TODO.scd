// Talkbot — granular FM voice synthesizer + detuned drone + drum sampler
// Three-part instrument: play voice via MIDI, layer drone, trigger drums from files

s.boot;

(
// Detuned sine formant drone
SynthDef(\talkDrone, { |freq = 80, detune = 3, gate = 1, amp = 0.3|
    var n   = 4;
    var env = EnvGen.kr(Env.asr(1, 1, 2), gate, doneAction: 2);
    var sig = Mix.fill(n, { |i|
        Pan2.ar(FSinOsc.ar(freq + (i * detune), mul: 1/n), i.linlin(0, n-1, -0.8, 0.8))
    });
    Out.ar(0, sig * env * amp);
}).add;

// GrainFM voice — carrier at note freq, modulator sweeps through formant range
SynthDef(\talkGrain, { |freq = 220, formant = 1200, modIdx = 3, gate = 1, amp = 0.5|
    var trig    = Impulse.ar(80);
    var env     = EnvGen.kr(Env.adsr(0.05, 0.1, 0.8, 0.3), gate, doneAction: 2);
    var modFreq = formant + SinOsc.kr(LFNoise1.kr(0.5, 2, 4), 0, 200);
    var sig     = GrainFM.ar(2, trig, 0.02,
        freq,
        modFreq,
        modIdx + SinOsc.kr(1.5, 0, 1.5),
        pan: LFNoise1.kr(5) * 0.3
    );
    sig = BPF.ar(sig, formant, 0.3, 2) + BPF.ar(sig, formant * 1.8, 0.2, 1.5);
    Out.ar(0, HPF.ar(sig, 80) * env * amp);
}).add;

// Mono sample drum player — load your own files via the GUI
SynthDef(\talkDrum, { |bufnum = 0, rate = 1, amp = 1|
    var sig = PlayBuf.ar(1, bufnum, rate, doneAction: 2);
    Out.ar(0, Pan2.ar(sig * amp));
}).add;
)

// --- MIDI input for talkGrain ---
(
MIDIClient.init;
MIDIIn.connectAll;
~talkNotes   = Dictionary.new;
~talkFormant = 1200;

MIDIdef.noteOn(\talkOn, { |vel, note|
    ~talkNotes[note] = Synth(\talkGrain, [
        \freq,    note.midicps,
        \formant, ~talkFormant,
        \amp,     vel / 127 * 0.6
    ]);
});

MIDIdef.noteOff(\talkOff, { |vel, note|
    ~talkNotes[note] !? { |s| s.set(\gate, 0) };
    ~talkNotes.removeAt(note);
});
)

// --- GUI ---
(
var w = Window("Talkbot", Rect(150, 120, 480, 400)).front;
var droneNode, patPlayer, drumTask;
var drumBufs = Array.new(3);

StaticText(w, Rect(10, 10, 460, 22))
    .string_("Talkbot — Granular FM Voice + Drone + Drums").align_(\center);

// --- Voice section ---
StaticText(w, Rect(10, 44, 460, 16)).string_("── VOICE (also responds to MIDI) ──").align_(\center);

StaticText(w, Rect(10, 66, 120, 20)).string_("Formant (Hz):");
var formantSlider = Slider(w, Rect(140, 66, 300, 20))
    .value_(0.4)
    .action_({ |v| ~talkFormant = v.value.linexp(0, 1, 200, 4000) });

Button(w, Rect(10, 98, 120, 28))
    .states_([["Play pattern", Color.black, Color.cyan], ["Stop pattern", Color.black, Color.red]])
    .action_({ |btn|
        if (btn.value == 1) {
            patPlayer.stop;
            patPlayer = Pbind(
                \instrument, \talkGrain,
                \midinote,   Prand([50, 53, 55, 57, 60, 62, 65], inf),
                \formant,    Pfunc { ~talkFormant },
                \dur,        Prand([0.25, 0.5, 0.75, 1.0], inf),
                \amp, 0.4
            ).play;
        } { patPlayer.stop; patPlayer = nil };
    });

// --- Drone section ---
StaticText(w, Rect(10, 148, 460, 16)).string_("── DRONE ──").align_(\center);

StaticText(w, Rect(10, 170, 120, 20)).string_("Drone freq (Hz):");
var droneFreqSl = Slider(w, Rect(140, 170, 250, 20)).value_(0.15);

Button(w, Rect(400, 168, 68, 24))
    .states_([["On", Color.black, Color.green], ["Off", Color.black, Color.red]])
    .action_({ |btn|
        if (btn.value == 1) {
            droneNode.free;
            droneNode = Synth(\talkDrone, [
                \freq, droneFreqSl.value.linexp(0, 1, 20, 400)
            ]);
        } {
            droneNode !? { |n| n.set(\gate, 0) };
        };
    });

// --- Drum section ---
StaticText(w, Rect(10, 210, 460, 16)).string_("── DRUMS (load up to 3 mono samples) ──").align_(\center);

3.do { |i|
    Button(w, Rect(10 + (i * 155), 232, 140, 22))
        .states_([["Load drum " ++ (i + 1), Color.black, Color.grey(0.8)]])
        .action_({
            Dialog.openPanel({ |path|
                drumBufs[i] !? _.free;
                drumBufs[i] = Buffer.read(s, path);
                ("Drum" + (i+1) + "loaded:").postln; path.postln;
            });
        });
};

StaticText(w, Rect(10, 264, 60, 20)).string_("BPM:");
var bpmBox = NumberBox(w, Rect(75, 262, 50, 22)).value_(120).clipLo_(30).clipHi_(300);

Button(w, Rect(140, 261, 110, 26))
    .states_([["Start drums", Color.black, Color.green], ["Stop drums", Color.black, Color.red]])
    .action_({ |btn|
        if (btn.value == 1) {
            drumTask.stop;
            drumTask = Task({
                var bps = bpmBox.value / 60;
                loop({
                    if (drumBufs[0].notNil) { Synth(\talkDrum, [\bufnum, drumBufs[0]]) };
                    (1/bps).wait;
                    if (drumBufs[1].notNil) { Synth(\talkDrum, [\bufnum, drumBufs[1], \rate, 1.5]) };
                    (1/bps).wait;
                    if (drumBufs[2].notNil) { Synth(\talkDrum, [\bufnum, drumBufs[2], \rate, 0.8]) };
                    (1/bps).wait;
                });
            }).start;
        } { drumTask.stop; drumTask = nil };
    });

// --- Stop all ---
Button(w, Rect(10, 320, 110, 42))
    .states_([["Stop all", Color.black, Color.red(0.8)]])
    .action_({
        patPlayer.stop; patPlayer = nil;
        drumTask.stop;  drumTask  = nil;
        droneNode !? { |n| n.set(\gate, 0) };
    });

w.onClose_({
    patPlayer.stop;
    drumTask.stop;
    droneNode !? _.free;
    drumBufs.do { |b| b !? _.free };
});
)

s.boot;

(
SynthDef(\stutterSynth, {
    arg freq = 440, gate = 1, amp = 0.5, pan = 0;
    var env, send, phase;
    env = EnvGen.kr(
        Env([0.01, 0.8, 1, 0.5], [0, 0.5, 1, 1.5], loopNode: 0, releaseNode: 2),
        gate, doneAction: 2
    );
    phase = LFNoise1.ar(10).range(-0.8, 0.8);
    send = Integrator.ar(
        SinOsc.ar(freq * SinOsc.ar(25).range(20, 50), phase, env),
        Line.kr(1, 0, 1)
    );
    Out.ar(0, Pan2.ar(send * amp, pan));
}).add;
)

// --- MIDI input (connect a controller and play) ---
(
MIDIClient.init;
MIDIIn.connectAll;
~activeNotes = Dictionary.new;

MIDIdef.noteOn(\stutterOn, { |vel, note|
    ~activeNotes[note] = Synth(\stutterSynth, [
        \freq, note.midicps,
        \amp,  vel / 127 * 0.7,
        \pan,  note.linlin(36, 84, -0.7, 0.7)
    ]);
});

MIDIdef.noteOff(\stutterOff, { |vel, note|
    ~activeNotes[note] !? { |s| s.set(\gate, 0) };
    ~activeNotes.removeAt(note);
});
)

// --- Pattern player with GUI (no controller needed) ---
(
var w = Window("Stutter Synth", Rect(200, 300, 420, 200)).front;
var player;

~stutterCount = 2;
~noteDur      = 0.2;
~noteSeq      = [60, 64, 67, 72];

~buildPlayer = {
    Pbind(
        \instrument, \stutterSynth,
        \midinote, Pstutter(~stutterCount, Pseq(~noteSeq, inf)),
        \dur, ~noteDur,
        \amp, 0.5
    ).play
};

StaticText(w, Rect(10, 10, 400, 20))
    .string_("Stutter Synth Pattern Player").align_(\center);

StaticText(w, Rect(10, 48, 120, 20)).string_("Stutter repeats:");
Slider(w, Rect(140, 48, 240, 20))
    .value_(0.125)
    .action_({ |v| ~stutterCount = v.value.linlin(0, 1, 1, 8).round.asInteger });

StaticText(w, Rect(10, 82, 120, 20)).string_("Note duration:");
Slider(w, Rect(140, 82, 240, 20))
    .value_(0.2)
    .action_({ |v| ~noteDur = v.value.linlin(0, 1, 0.05, 1.0) });

Button(w, Rect(10, 140, 90, 40))
    .states_([["Play", Color.black, Color.green]])
    .action_({ player.stop; player = ~buildPlayer.() });

Button(w, Rect(115, 140, 90, 40))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ player.stop; player = nil });

Button(w, Rect(250, 140, 150, 40))
    .states_([["Randomise notes", Color.black, Color.yellow]])
    .action_({
        ~noteSeq = Array.fill(4, { rrand(48, 84) });
        player.stop;
        player = ~buildPlayer.();
    });
)

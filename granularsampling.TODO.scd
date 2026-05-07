// Granular sampling
// built upon https://medium.com/@hinea/diy-granular-synthesis-in-supercollider-e2f5d3d6b23a

s.boot;

// --- SynthDefs ---

(
SynthDef(\playSample, { |bufnum, startPos = 0, gate = 1|
    var releaseTime = LFNoise0.kr(100, 1, 0.2);
    var amp         = Linen.kr(gate, 0.01, 0.6, releaseTime, 2);
    var startFrame  = LFNoise2.kr(5, 1, 0) * BufFrames.kr(bufnum) * startPos.max(0.001);
    var playBuf     = PlayBuf.ar(2, bufnum, Rand(-1, 1), 1,
                        startPos: startFrame, doneAction: 2);
    Out.ar(0, playBuf * amp);
}).add;

SynthDef(\grainSample, { |bufnum = 0, startpos = 0, grain = 0.0005, imp = 10, amp = 1|
    var env     = EnvGen.ar(Env([0.2], [grain]), doneAction: 2);
    var playBuf = PlayBuf.ar(2, bufnum, 2, Impulse.ar(imp),
                    startPos: startpos * BufFrames.kr(bufnum), loop: 0, doneAction: 2);
    Out.ar(0, playBuf * env * amp);
}).add;
)

// --- GUI ---

(
var w = Window("Granular Sampler", Rect(150, 150, 480, 400)).front;
var buf1, buf2;
var taskPlayer, patPlayer;

~grainStartPos = 0.0;
~grainImp      = 10;
~grainDur      = 0.0005;
~denseTask     = nil;
~grainPat      = nil;

// Load sample via file dialog
~loadSample = { |which|
    Dialog.openPanel({ |path|
        s.waitForBoot({
            if (which == 1) {
                buf1 !? _.free;
                buf1 = Buffer.read(s, path);
                "Sample 1 loaded: ".post; path.postln;
            } {
                buf2 !? _.free;
                buf2 = Buffer.read(s, path);
                "Sample 2 loaded: ".post; path.postln;
            };
        });
    });
};

StaticText(w, Rect(10, 10, 460, 22))
    .string_("Granular Sampler").align_(\center);

// --- Sample 1: dense random-position grains ---

StaticText(w, Rect(10, 48, 200, 20)).string_("Sample 1 — dense grains");
Button(w, Rect(220, 46, 100, 22))
    .states_([["Load sample 1", Color.black, Color.grey(0.8)]])
    .action_({ ~loadSample.(1) });

StaticText(w, Rect(10, 80, 120, 20)).string_("Grain rate (Hz):");
Slider(w, Rect(140, 80, 300, 20))
    .value_(0.5)
    .action_({ |v| ~grainHz = v.value.linlin(0, 1, 2, 300) });

~grainHz = 50;

Button(w, Rect(10, 115, 90, 32))
    .states_([["Start", Color.black, Color.green]])
    .action_({
        ~denseTask !? _.stop;
        ~denseTask = Task({
            loop({
                if (buf1.notNil) { Synth(\playSample, [\bufnum, buf1]) };
                (1 / ~grainHz).wait;
            });
        }).start;
    });

Button(w, Rect(115, 115, 90, 32))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ ~denseTask !? _.stop; ~denseTask = nil });

// --- Sample 2: Pbind grain sequencer ---

StaticText(w, Rect(10, 170, 200, 20)).string_("Sample 2 — grain sequencer");
Button(w, Rect(220, 168, 100, 22))
    .states_([["Load sample 2", Color.black, Color.grey(0.8)]])
    .action_({ ~loadSample.(2) });

StaticText(w, Rect(10, 202, 120, 20)).string_("Start position:");
Slider(w, Rect(140, 202, 300, 20))
    .value_(0)
    .action_({ |v| ~grainStartPos = v.value });

StaticText(w, Rect(10, 230, 120, 20)).string_("Grain duration:");
Slider(w, Rect(140, 230, 300, 20))
    .value_(0.1)
    .action_({ |v| ~grainDur = v.value.linlin(0, 1, 0.0001, 0.05) });

StaticText(w, Rect(10, 258, 120, 20)).string_("Impulse rate:");
Slider(w, Rect(140, 258, 300, 20))
    .value_(0.5)
    .action_({ |v| ~grainImp = v.value.linlin(0, 1, 1, 40) });

~buildGrainPat = {
    Pbind(
        \instrument, \grainSample,
        \bufnum,   Pfunc { buf2 !? _.bufnum ?? 0 },
        \startpos, Prand(Array.rand(100, 0.0, 1.0) * ~grainStartPos.max(0.01), inf),
        \grain,    Pfunc { ~grainDur },
        \imp,      Pfunc { ~grainImp },
        \dur,      Pseq([2, 5, 10, Rest(1)] / 0.005, inf)
    ).play
};

Button(w, Rect(10, 300, 90, 32))
    .states_([["Start", Color.black, Color.green]])
    .action_({ ~grainPat !? _.stop; ~grainPat = ~buildGrainPat.() });

Button(w, Rect(115, 300, 90, 32))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ ~grainPat !? _.stop; ~grainPat = nil });

// --- Stop all ---
Button(w, Rect(350, 300, 110, 32))
    .states_([["Stop all", Color.black, Color.red(0.9)]])
    .action_({
        ~denseTask !? _.stop; ~denseTask = nil;
        ~grainPat  !? _.stop; ~grainPat  = nil;
    });

w.onClose_({
    ~denseTask !? _.stop;
    ~grainPat  !? _.stop;
});
)

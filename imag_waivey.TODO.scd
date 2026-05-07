s.boot;

// --- Wavetable 1: randomised sine phase ---

b = Buffer.alloc(s, 2048, 1);

(
~sig = Signal.fill(1024, { |i|
    ((i.sin.rand) / 2048).linlin(
        (0.sin.rand) / 2048,
        (2048.sin.rand) / 2048,
        -1, 1
    )
});
~sig.plot;
)

~wavetable = ~sig.asWavetableNoWrap;
b.loadCollection(~wavetable);

// --- Wavetable 2: imaginary parts of summed complex exponentials ---
// Each harmonic gets a random amplitude and phase — re-roll via GUI button

c = Buffer.alloc(s, 2048, 1);

(
~buildComplexWavetable = {
    var harmonics = 8;
    var phases = Array.fill(harmonics, { rrand(0.0, 2pi) });
    var amps   = Array.fill(harmonics, { exprand(0.1, 1.0) }).normalizeSum;
    Signal.fill(1024, { |i|
        var theta = (i / 1024) * 2pi;
        harmonics.collect({ |k| amps[k] * sin((k + 1) * theta + phases[k]) }).sum
    }).normalize
};

~sig2 = ~buildComplexWavetable.();
~sig2.plot;
c.loadCollection(~sig2.asWavetableNoWrap);
)

// --- SynthDef ---

(
SynthDef(\waveOsc, { |dur = 0.25, bufnum = 0, baseFreq = 80, freqMod = 5000|
    var freq = SinOsc.ar(baseFreq * 0.0025, 0, freqMod, freqMod);
    var sig  = Osc.ar(bufnum, freq,
        mul: EnvGen.ar(Env.perc(releaseTime: dur), doneAction: 2));
    Out.ar(0, Splay.ar(LeakDC.ar(sig, 0.95)));
}).add;
)

// --- GUI ---

(
var w = Window("Imaginary Wavetable", Rect(300, 200, 440, 280)).front;
var player;

~wt_buf    = b;
~wt_dur    = 0.25;
~wt_fmod   = 5000.0;
~wt_fbase  = 80.0;

~buildPlayer = {
    Pbind(
        \instrument, \waveOsc,
        \bufnum,    ~wt_buf,
        \dur,       Prand([0.25, 0.2, 0.3], inf) * ~wt_dur,
        \freqMod,   ~wt_fmod,
        \baseFreq,  ~wt_fbase
    ).play
};

StaticText(w, Rect(10, 10, 420, 20))
    .string_("Imaginary Wavetable Player").align_(\center);

// Buffer select
StaticText(w, Rect(10, 45, 100, 20)).string_("Wavetable:");
Button(w, Rect(120, 45, 100, 22))
    .states_([["Random sine", Color.black, Color.grey(0.8)]])
    .action_({ ~wt_buf = b });
Button(w, Rect(228, 45, 100, 22))
    .states_([["Complex exp", Color.black, Color.grey(0.8)]])
    .action_({ ~wt_buf = c });
Button(w, Rect(336, 45, 90, 22))
    .states_([["New complex", Color.black, Color.cyan]])
    .action_({
        ~sig2 = ~buildComplexWavetable.();
        c.loadCollection(~sig2.asWavetableNoWrap);
    });

// Grain duration multiplier
StaticText(w, Rect(10, 82, 120, 20)).string_("Grain dur x:");
Slider(w, Rect(140, 82, 270, 20))
    .value_(0.25)
    .action_({ |v| ~wt_dur = v.value.linlin(0, 1, 0.1, 4.0) });

// Frequency modulation depth
StaticText(w, Rect(10, 116, 120, 20)).string_("Freq mod depth:");
Slider(w, Rect(140, 116, 270, 20))
    .value_(0.5)
    .action_({ |v| ~wt_fmod = v.value.linlin(0, 1, 100, 20000) });

// Base oscillator speed
StaticText(w, Rect(10, 150, 120, 20)).string_("Mod speed:");
Slider(w, Rect(140, 150, 270, 20))
    .value_(0.25)
    .action_({ |v| ~wt_fbase = v.value.linlin(0, 1, 10, 500) });

// Play / Stop
Button(w, Rect(10, 220, 90, 40))
    .states_([["Play", Color.black, Color.green]])
    .action_({ player.stop; player = ~buildPlayer.() });

Button(w, Rect(115, 220, 90, 40))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ player.stop; player = nil });
)

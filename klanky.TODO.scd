// Klanky — physical modelling via Klank resonator bank
// built upon "hommage à l'impressionnisme" by prkoon

s.boot;

// ~retune re-randomises the resonator bank and re-adds the SynthDef.
// Call it from the GUI "Retune" button to change the instrument's character.
(
~n = 16;

~retune = {
    var freqs  = Array.fill(~n, { rrand(36.0, 96.0).midicps });
    var amps   = Array.fill(~n, { rrand(-72.0, -36.0).dbamp });
    var decays = Array.fill(~n, { exprand(0.5, 10.0) });

    SynthDef(\klanky, { |sustain = 2, pan = 0|
        var env = EnvGen.ar(
            Env.perc(attackTime: sustain / 4, releaseTime: sustain, level: 1 / ~n),
            doneAction: 2
        );
        var sig = Klank.ar(`[freqs, amps, decays], Dust.ar(10000));
        sig = Compander.ar(sig, sig, 0.1);
        Out.ar(0, Pan2.ar(sig * env, pan));
    }).add;
};

~retune.();
)

s.waitForBoot({
    (
    Pdef(\filt, Pbind(
        \instrument, \klanky,
        \dur,  Pseq(Array.geom(12, 1.5, 0.75), inf),
        \pan,  Pwhite(-0.25, 0.25, inf)
    )).fadeTime_(2);
    )
});

(
var w = Window("Klanky", Rect(200, 200, 440, 290)).front;

StaticText(w, Rect(10, 10, 420, 20)).string_("Klanky — Klank Resonator").align_(\center);

// Freq range controls (applied on next Retune)
StaticText(w, Rect(10, 48, 160, 20)).string_("Resonator low (MIDI):");
var freqLoBox = NumberBox(w, Rect(180, 46, 50, 22)).value_(36).clipLo_(12).clipHi_(108);

StaticText(w, Rect(10, 80, 160, 20)).string_("Resonator high (MIDI):");
var freqHiBox = NumberBox(w, Rect(180, 78, 50, 22)).value_(96).clipLo_(12).clipHi_(108);

// Decay range (applied on next Retune)
StaticText(w, Rect(10, 112, 160, 20)).string_("Decay range (s):");
var decayLoBox = NumberBox(w, Rect(180, 110, 50, 22)).value_(0.5).clipLo_(0.01).clipHi_(30);
var decayHiBox = NumberBox(w, Rect(240, 110, 50, 22)).value_(10.0).clipLo_(0.01).clipHi_(30);

// Retune button — re-randomises resonators
Button(w, Rect(10, 152, 180, 32))
    .states_([["Retune resonators", Color.black, Color.cyan]])
    .action_({
        var lo  = freqLoBox.value;
        var hi  = freqHiBox.value;
        var dLo = decayLoBox.value;
        var dHi = decayHiBox.value.max(dLo + 0.01);
        var freqs  = Array.fill(~n, { rrand(lo, hi).midicps });
        var amps   = Array.fill(~n, { rrand(-72.0, -36.0).dbamp });
        var decays = Array.fill(~n, { exprand(dLo, dHi) });
        SynthDef(\klanky, { |sustain = 2, pan = 0|
            var env = EnvGen.ar(
                Env.perc(attackTime: sustain/4, releaseTime: sustain, level: 1/~n),
                doneAction: 2
            );
            var sig = Klank.ar(`[freqs, amps, decays], Dust.ar(10000));
            sig = Compander.ar(sig, sig, 0.1);
            Out.ar(0, Pan2.ar(sig * env, pan));
        }).add;
    });

// Tempo / rhythm
StaticText(w, Rect(10, 200, 130, 20)).string_("Tempo:");
Slider(w, Rect(150, 200, 270, 20))
    .value_(0.5)
    .action_({ |v| TempoClock.default.tempo_(v.value.linlin(0, 1, 0.2, 3.0)) });

Button(w, Rect(10, 240, 100, 38))
    .states_([["Play", Color.black, Color.green]])
    .action_({ Pdef(\filt).play });

Button(w, Rect(125, 240, 100, 38))
    .states_([["Stop", Color.black, Color.red]])
    .action_({ Pdef(\filt).stop });
)

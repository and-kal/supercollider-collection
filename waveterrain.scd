// Wave Terrain synthesis
// based on dkmayer https://scsynth.org/t/wave-terrain-synthesis/3424
// Ndef.gui opens a parameter control panel — evaluate the (Ndef block) to start

s.boot;

(
f = { |x, y| sin(x) - (sin(y) * log2(abs(x * (x * 10 + 1)) + 0.001) / 10) };
)

// Ndef with named kr parameters — Ndef(\waveTerrain).gui auto-generates sliders
(
Ndef(\waveTerrain, {
    var r      = \r.kr(10, 0.05);       // radius of circular path through terrain
    var freq   = \freq.kr(50, 0.5);     // traversal speed
    var detune = \detune.kr(0.1, 0.05); // stereo channel detune
    var amp    = \amp.kr(0.3);
    var phi    = LFSaw.ar([freq, freq + detune], -1).range(0, 2pi);
    var x      = r * cos(phi);
    var y      = r * sin(phi);
    Limiter.ar(LeakDC.ar(f.(x, y)), 0.9) * amp
}).play;

Ndef(\waveTerrain).gui;
)

// Alternative: set parameters directly
// Ndef(\waveTerrain).set(\r, 25, \freq, 200, \detune, 0.5, \amp, 0.2);

// Stop
// Ndef(\waveTerrain).stop;

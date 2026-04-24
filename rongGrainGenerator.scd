// you will need madskjeldgaard's portedplugins in your extensions directory for this: https://github.com/madskjeldgaard/portedplugins

Server.default.options.outDevice_("ASIO : JackRouter");
Server.default.options.inDevice_("ASIO : JackRouter");

s.reboot;

(
Ndef(\rong, {
arg density = 4, phaseFreq = 1000, pitchRatio = 1.3, pitchDispersion = 1.0, damping = 1.0;
var out, env, trig, fx_1, fx_2, grainSize = \grainSize.kr(
    val: 1.0,
    spec: ControlSpec(
        minval: 0.01,
        maxval: 8.0,
        warp: \lin,
        step: 0.05,
        default: 1.0,
    ),
);
// demand = Demand.kr(Impulse.kr(1),0,Drand(Array.fill(16, {|i| i/2}),inf))
trig = Dust.kr(density);
env = EnvGen.kr(Env.adsr(0.01,2,0.8,1,1));
out = Rongs.ar(
    trig,
    sustain: trig,
    f0: Demand.kr(trig,0,Dser(Array.fill(100, {|i| i+50}),inf)).poll(trig),
    structure: TRand.kr(0.0,0.99,trig),
    brightness: TRand.kr(0.01,0.99,trig),
    stretch: TRand.kr(0.1,0.99,trig),
    damping: damping,
    accent: 0.99,
    loss: 0.1
);
fx_1 = PitchShift.ar(out, grainSize, pitchRatio,pitchDispersion);
fx_2 = PhasorModal.ar(out,phaseFreq,0.5,0.1,1);
out = Splay.ar([fx_1,fx_2], 0, env);
out = out.tanh;
}).add;
)

Ndef(\rong).play.gui;

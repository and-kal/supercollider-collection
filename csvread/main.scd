// Prompt: Here's a little synth + pattern I wrote in SuperCollider. I'm reading values between -1 and 1 from a CSV file and I want to sonify them to an audible range (50 to 5000Hz e.g.). There's some problems in there, namely the scaling in ~csvsc_1, ~csvsc_1 and ~scaling. None of the approaches seem to work reliably. Am I doing something wrong there? And do you see any other parts that need improvement?

s.boot;

~csv = SemiColonFileReader.read(PathName(thisProcess.nowExecutingPath).pathOnly ++ "./machine-learning-dataset.csv", true).postcs

// scaling -1 to 1 floats to slices of audible range
// we have to use .collect here, which maps each element to a new value and returns a new array,
// while .do is for side effects; it does not build a new array from the function’s return value
(
~csvsc = ~csv.collect({|i|
	i
	.replace(",", ".")
	.asFloat
	.clip(-1.0,1.0)
	// reducing the linlin range in the csv.collect makes it sound tamer
	.linlin(-1.0, 1.0, 100, 1900);
})
)

//massive 4-op FM synth
(
SynthDef(\muzz, {|freq1, freq2, freq3, freq4 dur = 0.6, dropfac = 2| var env, out, sig, osc1, osc2, osc3, osc4;
	env = EnvGen.kr(Env.sine(dur,0.5),doneAction:2);
	osc1 = SinOsc.ar(LinLin.ar(freq1,-2,2,25,1000),rrand(0,1),env);
	osc2 = PulseDPW.ar(LinLin.ar(freq2,-2,2, 25, 14000),rrand(0.01,1),env/2);
	osc3 = SawDPW.ar(LinLin.ar(freq3,-2,2, 50, 1800),rrand(0,1),env/5);
	osc4 = Blip.ar(LinLin.ar(freq4,-2,2, 50, 180),LFNoise0.ar(20,200,1000),env/2);
	// sig = (osc1+osc2)*(osc3+osc4);
	sig = (osc1*(osc1**3))+(osc2*osc4)*(osc3*(osc3/0.75));
	sig = WaveLoss.ar(sig,dropfac,100,1);
	out = Out.ar(0, Pan2.ar(sig, LFNoise1.ar(8,0.8)));
}).add;
)

// t = Synth(\muzz, [\freq1, 200, \freq2, 300, \freq3, 30, \freq4, 100]);

(
Pdef(\bringit, (Pbind(
	\instrument, \muzz,
	\dur, Prand(Array.rand(12, (1/8),(8/1)),inf),
	\freq1, (Pseq(Array.fill(50, ({|k| ~csvsc[k+50][0]})), inf)),
	\freq2, (Pseq(Array.fill(50, ({|k| ~csvsc[k+50][1]})), inf)),
	\freq3, (Pseq(Array.fill(50, ({|k| ~csvsc[k+50][2]})), inf)),
	\freq3, (Pseq(Array.fill(50, ({|k| ~csvsc[k+50][3]})), inf)),
	\dropfac, Prand(Array.rand(100,2,90),inf);
)).play(TempoClock(100/60)));
)

ServerOptions.devices.do({|dev| dev.postln});

Server.default.options.outDevice_("ASIO : JackRouter");
Server.default.options.inDevice_("ASIO : JackRouter");

s.reboot;

(
s.waitForBoot({
    var bufferDuration = 10;
    ~buf = Buffer.alloc(s, s.sampleRate * bufferDuration, 1);

    // track the current write position of the recorder
    ~posBus = Bus.control(s, 1);

    // write live audio into the buffer in a loop
    SynthDef(\recorder, {
        var input = SoundIn.ar(0);
        var phase = Phasor.ar(0, BufRateScale.kr(~buf), 0, BufFrames.kr(~buf));

        // monitoring
        // Out.ar(0, input.dup * \monitorAmp.kr(0.5));

        BufWr.ar(input, ~buf, phase);

        // send current write position to the control bus
        Out.kr(~posBus, phase);
    }).add;

    SynthDef(\grain, {
		// mode 0: Forward
        // mode 1: Backward
        // mode 2: Bouncing (triangle)
        arg buf, startPos, dur = 0.5, amp = 0.5, pan = 0, mode = 0;
        var sig, phase, env;

        env = EnvGen.kr(Env.sine(dur), doneAction: 2);

        phase = Select.ar(mode, [
            // 0: fwd
            Line.ar(startPos, startPos + (dur * SampleRate.ir), dur),
            // 1: bwd
            Line.ar(startPos, startPos - (dur * SampleRate.ir), dur),
            // 2: tri
            VarSaw.ar(1/dur, 0, 0.5).range(startPos, startPos + (dur * SampleRate.ir * 0.5))
        ]);

        sig = BufRd.ar(1, buf, phase, loop: 1, interpolation: 4);

        Out.ar(0, Pan2.ar(sig * env * amp, pan));
    }).add;

    s.sync;

    ~granulator = {
        var density = 5;       // Grains per second
        var minDur = 0.1;      // Minimum slice length
        var maxDur = 1.0;      // Maximum slice length
        var minDelay = 0.5;    // Minimum delay (seconds behind write head)
        var maxDelay = 5.0;    // Maximum delay
        var amp = 0.6;

        var recSynth = Synth(\recorder, [\monitorAmp, 0.5]);

        inf.do {
            var currentPos = ~posBus.getSynchronous;
            var dur = rrand(minDur, maxDur);
            var delayFrames = rrand(minDelay, maxDelay) * s.sampleRate;
			var bufFrames = ~buf.numFrames;
            var startPos = (currentPos - delayFrames) % ~buf.numFrames;
            var mode = [0, 1, 2].choose;

            Synth(\grain, [
                \buf, ~buf,
                \startPos, startPos,
                \dur, dur,
                \amp, amp,
				\pan, rrand(-0.8, 0.8),
                \mode, mode
            ]);

            // wait time between grains
            (1/density).wait;
        };
    }.fork;
    "Granular Delay Started.".postln;
    "Adjust ~posBus or parameters in the Task to change behavior.".postln;
});
)

r = Recorder(s);
r.record(numChannels: 2);
r.stopRecording;

~granulator.stop;

s.freeAll;

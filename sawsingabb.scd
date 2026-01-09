// some old patch from July 2020

Server.default.options.outDevice_("ASIO : JackRouter");
Server.default.options.inDevice_("ASIO : JackRouter");

s.boot

(
SynthDef(\midi_sawsingabb,
	{arg freq=440, amp=0.5, sawv=4, gate=1;
		var modFreq = 120 * Saw.ar(sawv+6);
		var carrier = SinOsc.ar(freq + modFreq, mul: amp);
		var env = EnvGen.kr(Env.adsr(attackTime: 0.01, decayTime: 0.1, sustainLevel: 0.7, releaseTime: 1.0),
			gate: gate, doneAction: Done.freeSelf);
		Out.ar(0, Pan2.ar(carrier * env, 0, 1));
	}
).add;
)

/*
// Test the synth
a = Synth.new(\midi_sawsingabb, [\freq, 440, \amp, 0.3, \sawv, 4]);

(
~playNote = { |midiNote=60, velocity=100, duration=1.0, sawv=4|
	var freq = midiNote.midicps;
	var amp = velocity / 127.0 * 0.5;
	var synth = Synth.new(\midi_sawsingabb, [\freq, freq, \amp, amp, \sawv, sawv]);
	// synth.set(\gate, 0).delay(duration);
	synth
};
)

~playNote.value(67, 100, 1.5, 8); // G4, velocity 100, 1.5 seconds, sawv 8
*/

// Test: play a scale
(
Pbind(
	\instrument, \midi_sawsingabb,
	\degree, Pseq((0..7)++(7..0), 2),
	\dur, 0.25,
	\amp, 0.3,
	\sawv, Prand([2, 4, 8, 16], inf)
).play;
)

// ========================================
// EXTERNAL MIDI KEYBOARD SETUP
// ========================================

MIDIClient.init;
MIDIClient.destinations.postln;
MIDIClient.sources.postln;

m = MIDIIn.connect(1, MIDIClient.sources.at(3));

(
~handleNoteOn = { |source, channel, midiNote, velocity|
	var freq = midiNote.midicps;
	var amp = velocity / 127.0 * 0.5;
	var synth = Synth.new(\midi_sawsingabb,
		[\freq, freq, \amp, amp, \sawv, 4, \gate, 1]
	);
	~activeSynths = ~activeSynths ?? IdentityDictionary.new;
	~activeSynths[midiNote] = synth;
	"Note ON: MIDI %, Freq: %.2f Hz, Vel: %".format(midiNote, freq, velocity).postln;

};

~handleNoteOff = { |source, channel, midiNote, velocity|
	if(~activeSynths[midiNote].notNil, {
		var synth = ~activeSynths[midiNote];
		synth.set(\gate, 0);
		~activeSynths.removeAt(midiNote);
		"Note OFF: MIDI %".format(midiNote).postln;
	});
};
)

MIDIIn.addFuncTo(\noteOn, ~handleNoteOn);
MIDIIn.addFuncTo(\noteOff, ~handleNoteOff);

// or:
// MIDIdef.noteOn(\keyboardNotes, ~handleNoteOn);
// MIDIdef.noteOff(\keyboardNotes, ~handleNoteOff);

(
~testMIDI = {
	MIDIIn.addFuncTo(\noteOn, { |source, channel, midiNote, velocity|
		"Test MIDI Note: %, Velocity: %".format(midiNote, velocity).postln;
	});
};
)


// Optional: Add CC (Control Change) handling for modulation
/*
~handleCC = { |status, controller, value|
	switch(controller)
	{
		1} {  // Modulation wheel (CC1)
			~activeSynths.values.do({ |synth| synth.set(\sawv, value.linlin(0, 127, 1, 20)) });
		};
		7} {  // Volume (CC7)
			~activeSynths.values.do({ |synth| synth.set(\amp, value.linlin(0, 127, 0, 0.5)) });
		};
		11} { // Expression (CC11)
			~activeSynths.values.do({ |synth| synth.set(\amp, value.linlin(0, 127, 0, 0.5)) });
		};
	};
};
MIDIdef.cc(\keyboardCC, ~handleCC);
)

(
// Alternative: Automatically connect to first available MIDI input
~connectToFirstMIDI = {
	var devices = MIDIClient.sources;
	if(devices.size > 0, {
		m = MIDIIn.connect(0);
		"Connected to MIDI device: %".format(devices[0].name).postln;
	}, {
		"No MIDI input devices found!".postln;
	});
};
~connectToFirstMIDI.value;
)
*/

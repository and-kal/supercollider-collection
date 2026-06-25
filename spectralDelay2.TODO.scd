(
// taken from the TidalCycles docs: https://tidalcycles.org/docs/configuration/adding_effects/
var numChannels =  ~dirt.numChannels;

SynthDef("spectral-delay" ++ numChannels, { |out, tsdelay, xsdelay = 1, sustain|

    var signal, delayTime, delays, freqs, filtered;
    var size = 16;
    var maxDelayTime = 0.2;

    signal = In.ar(out, numChannels);
    delayTime = tsdelay * maxDelayTime;
    filtered = (1..size).sum { |i|
        var filterFreq = i.linexp(1, size, 40, 17000);
        var sig = BPF.ar(signal, filterFreq, 0.005);
        // the delay pattern is determined from xsdelay by bitwise-and:
        DelayN.ar(sig, maxDelayTime, i & xsdelay * (1/size) * delayTime )
    };
    signal = signal * 0.2 + (filtered * 4); // this controls wet/dry
    ReplaceOut.ar(out, signal)

}).add;
)
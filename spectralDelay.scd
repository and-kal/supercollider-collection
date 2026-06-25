(
s.waitForBoot {
    var fftSize = 1024;
    var numBins = fftSize / 2;
    var numGroups = 16;
    var binsPerGroup = numBins / numGroups;
    var maxDelay = 0.8;

    ~delayBuf = Buffer.alloc(s, numBins);
    ~fbBuf = Buffer.alloc(s, numBins);

    ~delayVals = Array.fill(numGroups, { exprand(0.01, maxDelay) });
    ~fbVals = Array.fill(numGroups, { rrand(0.0, 0.85) });

    ~delayBuf.setn(0, Array.fill(numBins, { |i| ~delayVals[(i / binsPerGroup).floor] }));
    ~fbBuf.setn(0, Array.fill(numBins, { |i| ~fbVals[(i / binsPerGroup).floor] }));

    SynthDef(\micSpectralDelay16, { |out=0, in=0, amp=1, maxDelay=0.8, delaybuf=0, fbbuf=1|
        var sig, chain;
        sig = SoundIn.ar(in);
        chain = FFT(LocalBuf(fftSize), sig);
        chain = PV_BinDelay(chain, maxDelay, delaybuf, fbbuf, 0.5);
        sig = IFFT(chain);
        Out.ar(out, sig!2 * amp);
    }).add;

    s.sync;
    ~specDelay = Synth(\micSpectralDelay16, [\delaybuf, ~delayBuf, \fbbuf, ~fbBuf]);
};
)

(
~makeSpectralGui = {
    var w, mainLayout, delayCol, fbCol, delaySliders, fbSliders;

    w = Window("16-bin spectral delay", Rect(100, 100, 820, 480)).front;
    mainLayout   = HLayout.new;
    delayCol     = VLayout.new;
    fbCol        = VLayout.new;
    delaySliders = Array.newClear(16);
    fbSliders    = Array.newClear(16);

    // ── left column: delay times ──────────────────────────────────────────
    delayCol.add(StaticText().string_("Delay times").align_(\center));
    16.do { |i|
        var row    = HLayout.new;
        var label  = StaticText().string_("Bin " ++ (i+1)).fixedWidth_(44);
        var slider = Slider().value_(~delayVals[i] / 0.8);
        var box    = NumberBox().value_(~delayVals[i]).clipLo_(0).clipHi_(0.8).fixedWidth_(48);

        slider.action_({ |sl|
            var v = sl.value * 0.8;
            box.value = v;
            ~delayVals[i] = v;
            ~delayBuf.setn(0, Array.fill(512, { |j| ~delayVals[(j / 32).floor] }));
        });
        box.action_({ |nb|
            var v = nb.value.clip(0.0, 0.8);
            slider.value = v / 0.8;
            ~delayVals[i] = v;
            ~delayBuf.setn(0, Array.fill(512, { |j| ~delayVals[(j / 32).floor] }));
        });

        row.add(label);
		row.add(slider);
		row.add(box);
        delayCol.add(row);
        delaySliders[i] = slider;
    };

    // ── right column: feedback ────────────────────────────────────────────
    fbCol.add(StaticText().string_("Feedback").align_(\center));
    16.do { |i|
        var row    = HLayout.new;
        var label  = StaticText().string_("Bin " ++ (i+1)).fixedWidth_(44);
        var slider = Slider().value_(~fbVals[i] / 0.95);
        var box    = NumberBox().value_(~fbVals[i]).clipLo_(0).clipHi_(0.95).fixedWidth_(48);

        slider.action_({ |sl|
            var v = sl.value * 0.95;
            box.value = v;
            ~fbVals[i] = v;
            ~fbBuf.setn(0, Array.fill(512, { |j| ~fbVals[(j / 32).floor] }));
        });
        box.action_({ |nb|
            var v = nb.value.clip(0.0, 0.95);
            slider.value = v / 0.95;
            ~fbVals[i] = v;
            ~fbBuf.setn(0, Array.fill(512, { |j| ~fbVals[(j / 32).floor] }));
        });

        row.add(label);
		row.add(slider);
		row.add(box);
        fbCol.add(row);
        fbSliders[i] = slider;
    };

    mainLayout.add(delayCol);
    mainLayout.add(fbCol);
    w.layout = mainLayout;
    w.onClose_({
        ~specDelay.free;
        ~delayBuf.free;
        ~fbBuf.free;
    });
    w;
};

~gui = ~makeSpectralGui.value;
)
# BQNoise

BQN scripts for audio synthesis and processing.

- mix.bqn: General mixing utilities, e.g. add, repeat, clip, reverb
- panap.bqn: Fancy mono-compatible panning
- oscillator.bqn: Typical oscillators and noise generators for synthesis
- filter.bqn: IIR filters to adjust tonality
- scale.bqn: Utilities for working with scales (in the normal Western system, 12-TET)
- tracker.bqn: Sequencer to make drum tracks or other arrangements from a text template
- wav.bqn: Read and write .wav files
- soxresample.bqn: Bind SoX's resampler for converting .wav files; only thing I'm not brave enough to do in BQN

See load.bqn and options.bqn for loading multiple scripts and options management.

The following C libraries are used in CBQN if available:

- `./lib.c` (build with `$ make`), for filters
- [FFTW](https://en.wikipedia.org/wiki/FFTW)'s `/usr/lib/libfftw3.so.3`, for reverb
- [SoX](https://en.wikipedia.org/wiki/SoX)'s `/usr/lib/libsoxr.so`, for resampling

The filtering and reverb functions are also implemented in BQN, so that the only change is faster execution, by a factor of about 10 in each case. There's no BQN resampling implementation, so that SoX is needed to work with files at different frequencies.

# BQNoise

BQN scripts for audio synthesis and processing, based on [my J scripts](https://github.com/mlochbaum/JSound) for the same.

Most of the synthesizer functionality has been ported over from J, but filtering and reverb are fairly slow: in J these rely on C shared libraries and BQN can't currently call shared libraries.

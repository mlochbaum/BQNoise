FBytes ⇐ •FBytes
fmt  ⇐ 1‿16      # Format: 16-bit integer
freq ⇐ 44100     # Frequency: 44.1kHz
Set ⇐ {fmt‿freq↩𝕩}

# For generating random waveforms; result is a shape 𝕩 array of uniform
# random numbers between 0 and 1
RandFloats ⇐ •RAND∘⥊⟜0

# For reading/writing wave files
warn_dither ⇐ 0  # Whether to warn on non-integer signal
warn_clip   ⇐ 1  # Whether to warn on out-of-bounds signal
Dither ⇐ ⌊ (-˝ ·RandFloats 2∾≢)⊸+
Resample ⇐ "No resampling function specified"!0˙

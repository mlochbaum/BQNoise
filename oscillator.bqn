# Standard oscillators for (usually subtractive) synthesis
# In each case, the right argument argument is a list giving the
# frequency for each sample.
# If not otherwise specified, the left argument is optional and gives
# the phase offset.

"oscillator.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args

# Utilities
Ce ← 1-˜2⊸×                   # Center: transform [0,1] to [¯1,1]
SP ← (4⊸×÷5⊸-) 4×¬⊸×          # Sine π×𝕩 by Bhaskara I
Rand ← Ce {o.RandFloats 𝕩}

# Basic waveforms
Id ← {𝕨++`𝕩÷o.freq}           # Identity
P ← 1|Id                      # Phase

# Deterministic waveforms for synthesis
Saw   ⇐ Ce∘P                  # Sawtooth wave //////
Triangle ⇐ Ce∘| {𝕨+0.25}Saw⊢  # Triangle wave ´\/\/\
Square⇐ Ce 0.5<P              # Square wave   ⊔¯⊔¯⊔¯
Pulse ⇐ Ce <⟜P                # Pulse wave with duty cycle 𝕨
#Sine  ⇐ •Math.Sine (2×π) × Id # Sine wave
Sine  ⇐ (××SP∘|) {𝕨+0.5}Saw⊢  # Sine wave, more or less

# Random waveforms
White ⇐ Rand ≢                # White noise
Brown ⇐ +` White              # Brown noise
# Pink noise
#Pink  ⇐ ÷⟜(⌈´|) (2⊸/⊸+˜´∘⌽ · Rand¨ 2⋆↕)⊸÷∘(1+·⌈2⋆⁼⊢)⊸(↑˜)∘≠
Pink  ⇐ ÷⟜(⌈´|) (+` ·⥊∘⍉∘≍´ ·-⟜«∘Rand¨ 2⋆1⌈⌽∘↕)∘(1+·⌈2⋆⁼⊢)⊸(↑˜)∘≠

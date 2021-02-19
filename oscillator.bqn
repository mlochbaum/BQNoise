# Standard oscillators for (usually subtractive) synthesis
# In each case, the right argument argument is a list giving the
# frequency for each sample.
# If not otherwise specified, the left argument is optional and gives
# the phase offset.

"oscillator.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args

# Utilities
Ce ← 1-˜2⊸×                   # Center: transform [0,1] to [¯1,1]
Rand ← Ce {o.RandFloats 𝕩}

# Basic waveforms
Id ← {𝕨++`𝕩÷o.freq}           # Identity
P ← 1|Id                      # Phase

# Deterministic waveforms for synthesis
Saw   ⇐ Ce∘P                  # Sawtooth wave //////
Triangle ⇐ Ce∘| {𝕨+0.25}Saw⊢  # Triangle wave ´\/\/\
Square⇐ Ce 0.5<P              # Square wave   ⊔¯⊔¯⊔¯
Pulse ⇐ Ce <⟜P                # Pulse wave with duty cycle 𝕨
Sine  ⇐ •math.Sin (2×π) × Id  # Sine wave

# Random waveforms
White ⇐ Rand ≢                # White noise
Brown ⇐ +` White              # Brown noise
# Pink noise
#Pink  ⇐ ÷⟜(⌈´|) (2⊸/⊸+˜´∘⌽ · Rand¨ 2⋆↕)⊸÷∘(1+·⌈2⋆⁼⊢)⊸(↑˜)∘≠
Pink  ⇐ ÷⟜(⌈´|) (+` ·⥊∘⍉∘≍´ ·-⟜«∘Rand¨ 2⋆1⌈⌽∘↕)∘(1+·⌈2⋆⁼⊢)⊸(↑˜)∘≠

# Karplus-Stong algorithm for a plucked string
Pluck ⇐ { 𝕊 f‿len‿att: # Frequency, length, attenuation
  p ← ⌊o.freq÷f
  ∾ ((÷2×16⋆att÷p)×1⊸⌽⊸+)⍟(↕⌈len÷p) Pink p⥊0
}

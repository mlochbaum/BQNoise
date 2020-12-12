# Utilities for working with notes and scales

# A minor scale goes up two fifths and down four from the root
minor ← ∧12|7×2-↕7

# Transpose frequency 𝕩 up 𝕨 semitones.
Trans ⇐ (2 ⋆ ÷⟜12)⊸×

# Frequency from note in roughly scientific pitch notation
# e.g. C#, A4, Gb2, F##
Oct ← ⊑'4'-˜('0'⊸≤∧≤⟜'9')⊸/∾"3"˙  # Default to 3 to hit middle C
Note ⇐ (minor⊑˜'a'(⊢-≤◶'A'‿⊣)⊑) (+´⟜(-˝"#b"=⌜⊢) Trans 440×2⋆Oct∘⊢) 1⊸↓

"mix.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args

# List of length |𝕩 that starts at 0 and stops just before 1,
# reversed if 𝕩<0.
I ⇐ <⟜0 ⌽∘⊢⍟⊣ ↕⊸÷∘|

# Add two signals 𝕨 and 𝕩 or a list of signals 𝕩,
# extending to the length of the longest signal.
Add ⇐ +´ ·(⌈´(¯1⊑≢)¨)⊸(↑⎉1¨) ⊢⊘⋈
# Like add, but concatenate instead (no extension).
Concat ⇐ (∾ (0⥊˜·⌈´=¨)⊸(<∘⊣↓¨↓)) ⊘ (∾⎉1)
# Like ⌽⎉1, but the end of the signal does not wrap around.
Shift ⇐ <⟜0◶⟨↓⎉1 , (-⥊0˙)⊸(∾⎉1)⟩
# Repeat signal 𝕩 𝕨 times.
Rep ⇐ (⥊/⟜≍)⎉1
# 𝕨 is location‿length. Obtain that part of signal 𝕩.
Slice ⇐ (SliceI ← +⟜(0⊸⌊+↕∘|)´)∘⊣ ⊏⎉1 ⊢
# Apply 𝔽 to the slice of 𝕩 given by 𝕨.
_onSlice ⇐ { 𝔽⌾((SliceI𝕨)⊏⎉1⊢) 𝕩 }

# Convert possibly-mono signal to stereo
Stereo ⇐ ≍˜⍟(2>=)
# Pan signal 𝕩 to position 𝕨, where 0 is hard left and 1 is hard right
Pan ⇐ (25⌊∘×≍⟜¬∘⊣) ⥊⟜0⊸»˘ ((=⌜˜↕2)-·(××⌜0⊸⌈)·≍⟜-1-˜2×⊣)⊸(+˝∘×⎉¯1‿∞)⟜Stereo

# Clip signal 𝕩 to the maximum possible range.
Clip ⇐ 1⌊¯1⌈⊢
# 𝕨 is an integer giving "sharpness". Perform a soft clip.
_scs ← { ÷⟜(𝔽⌾(⋆⟜(2⋆𝕨⊣3))) 𝕩 }
Softclip ⇐ { 𝕊⁼: 𝕨¬_scs𝕩 ; 𝕨1⊸+_scs𝕩 }

# Multiply leading or trailing samples of 𝕩 by 𝕨.
Fadefront‿Fadeback ⇐ {𝕊f: {𝕨⊸×⌾((F≠𝕨)↑⊢)𝕩}⎉1 }¨ ⊢‿-

# 𝕗 is the overlap amount. Fade 𝕨 into 𝕩, linearly.
_crossfade ⇐ {
  G←↑⋈↓
  (-𝕗)⊸G⊸(∾ 1⌽∾˜○(1⊸↓) ∾⟜< (¬⊸≍I𝕗)+˝∘×≍○⊑)⟜(𝕗⊸G)⎉1
}

# Apply reverb impulse response (IR) 𝕨 to 𝕩.
# Argument rows are extended, giving result length (𝕩+○≠𝕨)-1 (for lists).
# Equivalent to (+´¨+⌜○↕○≠⊔×⌜)⎉1 except for numeric precision.
reverb ⇐ •Import "reverb.bqn"

# Apply stereo reverb by keeping early IR sides separate and later
# blending them together; can avoid some balance issues
ReverbStereoMix ⇐ {
  ir ← (I 100) ((¬∘⊣×≠⊸↑)⎉1 ⋈ Fadefront) 𝕨
  Add ir Reverb¨ ⋈⟜(+˝÷≠) 𝕩
}

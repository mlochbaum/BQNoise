"mix.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args
fft ← •Import "fft.bqn"

# List of length |𝕩 that starts at 0 and stops just before 1,
# reversed if 𝕩<0.
I ⇐ <⟜0 ⌽∘⊢⍟⊣ ↕∘|⊸÷

# Add two signals 𝕨 and 𝕩 or a list of signals 𝕩,
# extending to the length of the longest signal.
Add ⇐ +´ ·(⌈´(¯1⊑≢)¨)⊸(↑⎉1¨) ⊢⊘(≍○<)
# Like add, but concatenate instead.
Concat ⇐ (∾ ↓¨˜⟜(<0⥊˜·⌈´=¨)) ⊘ (∾⎉1)
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

# Clipping functions clip to [¯1,1] by default
# _norm changes this to match the format if it's an integer format
_norm ⇐ { (𝕨𝔽⊢)⌾(÷⟜(2⋆1-˜¯1⊑o.fmt)) 𝕩 }
# Clip signal 𝕩 to the maximum possible range.
Clip ⇐ 1⌊¯1⌈⊢
# 𝕨 is an integer giving "sharpness". Perform a soft clip.
Softclip ⇐ { ÷⟜(1⊸+⌾(⋆⟜(2⋆𝕨⊣3))) 𝕩 }

# Multiply leading or trailing samples of 𝕩 by 𝕨.
Fadefront‿Fadeback ⇐ {𝕊f: {𝕨⊸×⌾((F≠𝕨)↑⊢)𝕩}⎉1 }¨ ⊢‿-

# 𝕗 is the overlap amount. Fade 𝕨 into 𝕩, linearly.
_crossfade ⇐ {
  G←↑≍○<↓
  (-𝕗)⊸G⊸(∾ 1⌽∾˜○(1⊸↓) ∾⟜< (¬⊸≍I𝕗)+˝∘×≍○⊑)⟜(𝕗⊸G)⎉1
}

# Apply reverb impulse response (IR) 𝕨 to 𝕩.
# Argument rows are extended, giving result length (𝕩+○≠𝕨)-1 (for lists).
# Equivalent to (+´¨+⌜○↕○≠⊔×⌜)⎉1 except for numeric precision.
Reverb ⇐ {
  M ← -˝∘× ≍ +˝∘×⟜⌽ # Complex multiplication
  lw‿lx ← (¯1⊑≢)¨ 𝕨‿𝕩
  ! 0<lw
  # Use the overlap-add method.
  o ← lw-1          # Overlap length
  n ← ⌈⌾(2⋆⁼⊢) 3×o  # Window length, including overlap
  l ← n-o           # Without overlap
  k ← lx+o          # Result length
  k0← ⌈⌾(÷⟜l) k     # Rounded up
  𝕨 {
    CW ← ⊏ · (FFT n↑𝕨)⊸M⌾FFT n⊸↑
    {t←0 ⋄ k↑⥊ {r‿s←(-o)(t⊸+⌾(o⊸↑)∘↓≍○<↑)CW𝕩⋄t↩s⋄r}˘ ∘‿l⥊k0↑𝕩}⎉1 𝕩
  }⎉(1≍1+0⌈-˜○=) 𝕩
}

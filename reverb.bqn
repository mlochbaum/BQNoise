# Reverb, using FFTW if available and BQN-based FFT if not

Reverb ← {
  lw‿lx ← (¯1⊑≢)¨ 𝕨‿𝕩
  ! 0<lw
  # Use the overlap-add method.
  o ← lw-1          # Overlap length
  k ← lx+o          # Result length
  n ← k⌊(2⋆14)⌈3×o  # Window length, including overlap
  n   ⌈⌾(2⋆⁼⊢)↩     # Round up to power of two
  l ← n-o           # Without overlap
  k0← ⌈⌾(÷⟜l) k     # Rounded up
  𝕨 {
    CW ← (n↑𝕨) _rev1
    {t←0 ⋄ k↑⥊ {r‿s←(-o)(t⊸+⌾(o⊸↑)∘↓⋈↑)CW𝕩⋄t↩s⋄r}˘ ∘‿l⥊k0↑𝕩}⎉1 𝕩
  }⎉(1≍1+0⌈-˜○=) 𝕩
}

# Convolve 𝕗 and 𝕗≠⊸↑𝕩, assuming length of 𝕗 is a power of 2
rev1 ← {𝕊
  # Use the half-complex form of FFTW
  # Converts e.g. 8 reals to r0,r1,r2,r3,r4,i3,i2,i1 and back
  pl ← ">" ∾ plan ← "*:i32"
  Fn ← "/usr/lib/libfftw3.so.3"⊸•FFI
  createPlan  ← Fn plan‿"fftw_plan_r2r_1d"‿"i32"‿"*f64"‿"&f64"‿"i32"‿"i32"
  destroyPlan ← Fn ""‿"fftw_destroy_plan"‿pl
  executePlan ← Fn ""‿"fftw_execute"‿pl
  FFTR ← { 𝕊⁼𝕩: 1𝕊𝕩 ;
    plan‿out ← CreatePlan ⟨≠𝕩,𝕩,0¨𝕩,𝕨⊣0,2⋆6⟩
    ExecutePlan plan
    DestroyPlan plan
    out
  }
  {
    mh←-nh←1-˜2÷˜n←≠𝕗
    M ← (mh(↓-0∾0∾˜⌽∘↑)×) ∾ nh(⌽∘↑+-⊸↑)×⟜⌽○(1⊸↓)  # Scrambled complex ×
    (n ÷˜ FFTR 𝕗)⊸M⌾FFTR n⊸↑
  }
}⎊{𝕊
  fft ← •Import "fft.bqn"
  M ← -˝∘× ≍ +˝∘×⟜⌽  # Complex multiplication
  {⊏ · (FFT 𝕗)⊸M⌾FFT (≠𝕗)⊸↑}
}@

Reverb

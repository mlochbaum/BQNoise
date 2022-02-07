# Fast Fourier transform
# Argument has shape ⟨l⟩ for real values or ⟨2,l⟩ for complex, l←2⋆n
# Result is complex encoded as shape ⟨2,l⟩.

Sin‿Cos ← •math

{
  𝕨𝕊⁼𝕩: (-𝕨1⊘≢¯1)𝕊𝕩 ;

  inv ← 𝕨≡¯1
  "FFT argument must be a list or have two list cells" ! (3⌊=)◶⟨0,1,2=≠,0⟩𝕩
  n ← 2 ⋆⁼ l ← ¯1⊑≢𝕩
  "FFT length must be a power of two" ! ⌊⊸=n
  s ← 2 ⥊˜ n

  r ← (Cos≍Sin) π × (1↓s) ⥊ -⍟inv ↕⊸÷ l÷2   # Roots of unity
  M ← -˝∘× ≍ +˝∘×⟜⌽                         # Complex multiplication
  F ← { 𝕨 ⊏⎉1⊸𝕊⍟(1<=𝕨) (=𝕨)⍉(+˝˘≍𝕨M-˝˘)𝕩 } # FFT loop
  ÷⟜l⍟inv ⥊˘ r F s⊸⥊˘ ≍⟜(0¨)⍟(1==) 𝕩
}

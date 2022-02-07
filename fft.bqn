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

  r ← (Cos⋈Sin) π × (1↓s) ⥊ -⍟inv ↕⊸÷ l÷2   # Roots of unity
  M ← -´∘× ⋈ +´∘×⟜⌽                         # Complex multiplication
  F ← { (r (2‿0<⊸«𝕨⥊1)⊸/¨↩) ⊢ (+˝¨(𝕨⍉≍)¨r M-˝¨)𝕩 } # FFT loop
  ÷⟜l⍟inv >⥊¨ (↕n) F´˜ s⊸⥊¨ (1==)◶⟨<˘,⊢⋈0¨⟩ 𝕩
}

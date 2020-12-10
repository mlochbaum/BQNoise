# IIR filters
# Filters are used to make some frequencies louder or quieter in order
# to change a sound's tone.
# Each one takes some parameters for its left argument and a signal on
# the right.

⟨
  # 1-pole filters (f:frequency)
  Lp1, Hp1        #   f     low/high-pass

  # 2-pole filters (g:gain, w:width, Q decreases with width)
  Lp2, Hp2        #   f     Butterworth low/high-pass
  Lp2q,Hp2q,Bp2q  #   f Q   Butterworth low/high/band-pass with resonance
  Peak            # g f Q
  LShelf, HShelf  # g f Q?  low/high-shelf
  Notch           #   f w
  AllPass         # a‿b     a+bi is complex with magnitude <1

  # Utilities
  NtoQ, QtoN      # Bandwidth ←→ Q for peak filters

  # Use Lp2⍟2 and Hp2⍟2 (4-pole Linkwitz-Riley) for crossovers

  # Other 2-pole low/high-pass filters (I never use these)
  # Filter2 generates Lp2 and Hp2 filters except the resonant ones
  # If the second argument is n then the filter should be called n
  # times and then gives a (2×n)-pass filter
  Filter2
  # Critically damped and Bessel filters
  Lp2_CD,Hp2_CD, Lp2_BS,Hp2_BS
⟩⇐

"filter.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args

# Generalized filtering
# 𝕩 is the signal to filter
# 𝕨 is ⟨result coefficients , 𝕩 coefficients⟩.
Filter ← {
  a‿b ← 0×coeff←𝕨  # accumulators and coefficients for input and result
  {
    a«˜↩𝕩
    r←+´coeff+´∘×¨a‿b
    b«˜↩r
    r
  }¨ 𝕩
}⎉1
_f ← { !∘0⊘(𝔽⊸Filter) }

# Compute the frequency response from coefficients
#Response ← ≍○<⟜(1∾-)○⌽´ ⊸ ((|·÷´{+⟜(𝕩⊸×)´𝕨}¨)⎉∞‿0) ⟜ (⋆0i1×Om)

# Trig (approximations for now)
SP ← (4⊸×÷5⊸-) 4×¬⊸×
Sin ← (⊢-∘⊢⍟(>⟜1)·SP 1⊸|) 2|÷⟜π
Cos ← Sin (π÷2)⊸-
Tan ← Sin ÷ Cos

Om ← (2×π)×{𝕩÷o.freq}
Tom ← Tan Om÷2˙

# 1-pole low-pass and high-pass filters
Lp1 ←     (⥊¨ ·≍⟜¬ 1+⌾÷Om) _f
Hp1 ← ((-⊸≍ ≍○< ⥊) 1÷∘+Om) _f

# 2-pole *-pass
f2types ← "bw"‿"cd"‿"bessel"
Filter2 ← { type‿nPasses‿isHighpass:
  t ← f2types ⊑∘⊐ <type
  ! 3 > t
  c ← t◶⟨4√-⟜1 , √1-˜√ , √3×0.5-˜·√-⟜0.75⟩ nPasses√2 # cutoff frequency correction
  x ← t ⊑ ⟨√2‿1 , 2‿1 , 3‿3⟩                         # p and g
  Clp2 ← {
    e ← ¯1 ⊑ a ← 𝕨 × ≍⟜(×˜) Tom 𝕩
    b ← (1‿2‿1 ∾˜ 2×1-˜÷e) × e ÷ 1++´a
    ¯3 (↑ ≍○< ↓) (1-+´)⊸∾ b
  }
  (isHighpass ⊑ ⟨
    x Clp2 ÷⟜c
    ⟨1‿¯1‿1, 1‿¯1⟩ × x Clp2 ·{(o.freq÷2)-𝕩}×⟜c
  ⟩) _f
}

⟨Lp2‿Hp2, Lp2_CD‿Hp2_CD, Lp2_BS‿Hp2_BS⟩ ← <˘f2types Filter2∘{𝕨‿1‿𝕩}⌜ ↕2

# Once more, with resonance
# Lp2q and Hp2q are identical to Lp2 and Hp2 when Q=÷√2
Resfilt ← {
  Om⊸(Sin⊸÷⟜(2⊸×) (+⟜1 ÷˜ 𝕏 ≍○< -⟜1≍2⊸×) Cos∘⊣)´ _f
}
Lp2q‿Hp2q‿Bp2q ← Resfilt¨ ⟨ 1⊸-÷2‿1‿2˙ , 1⊸+÷2‿¯1‿2˙ , ×⟜1‿0‿¯1 ⟩

# Other 2-pole filters
Peak ← { g‿f‿q:
  k ← Tom f
  ab ← 1‿4‿0‿2‿3‿0 ⊏ +⟜(k⊸×)´¨ ¯2‿0‿2 <⊸∾ {1‿𝕩‿1}¨ ⥊≍⟜- q ÷˜ 10⋆0⌈-⊸≍g÷20
  3 (↑ ≍○< -∘↓) (1⊸↓ ÷ ⊑) ab
} _f
# Q to bandwidth and vice-versa for peaking filters
NtoQ ← {𝕊𝕩: (√÷-⟜1)𝕩 ; 𝕊⁼𝕩: -⟜1⌾(×˜)⊸+ 1+÷2××˜𝕩} 2⊸⋆
QtoN ← NtoQ⁼

Shelf ← {
  # t is type: 1 for bass and ¯1 for treble shelf
  t‿g‿f‿q ← ∾⟜(√2)⍟(3=≠) 𝕩
  k ← Tom f
  v1 ← 10 ⋆ t × 0⌈-⊸≍g÷40
  ab ← ⥊ 1‿0‿2⊸⊏˘ (×˜1⌊v1) ÷˜ (k×v1) {+⟜(𝕨⊸×)´𝕩}⌜ ¯2‿0‿2 <⊸∾ {1‿𝕩‿1}¨ ≍⟜- q
  2 (↓ ≍○<○⌽ -∘↑) (1⊸↓ ÷ ⊑) ab
} _f
# Shortcuts for low- and high-shelf
LShelf ←  1⊸∾⊸Shelf
HShelf ← ¯1⊸∾⊸Shelf

Notch ← {
  # Filter with no gain outside of the notch due to A.G. Constantinides
  f‿w ← 𝕩  # w is width of ≥3dB attenuation in Hz.
  c←2×Cos Om f ⋄ t←Tom w
  ⟨1,-c,1⟩‿⟨t-1,c⟩ ÷ 1+t
} _f

AllPass ← (≍○<⟜(-∘⌽1⊸↓) ⟨1,¯2×⊑,+´×˜⟩{𝕎𝕩}¨<) _f

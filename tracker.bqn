# Sequencer/tracker based on a string pattern

⟨
  Opts         # Make options object
  MakeTrack    # Build entire track
  Sequence     # Build a single instrument
  ReadPattern  # Read pattern for a track from lf-separated string
  GetLength    # Find length of pattern
⟩⇐

"tracker.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
op ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args
⟨Add⟩‿⟨Lp2,Hp2⟩ ← op •Import¨ "mix.bqn"‿"filter.bqn"

# Sequencing options
Opts ← {
  shifts  ← {𝕩.shifts}⎊("><]["≍÷8‿¯8‿3‿¯3) 𝕩
  gains   ← {𝕩.gains} ⎊("-+"≍1.2⋆¯1‿1) 𝕩
  noop    ← {𝕩.noop}  ⎊"." 𝕩
  control ⇐ noop∾shifts∾○⊏gains # Non-sample characters
  GetShift‿GetVol ⇐ 0‿1 {{𝕩⊏˜𝕨⊸⊐}⟜(∾⟜𝕨)˝𝕩}¨ shifts‿gains

  beat  ⇐ {𝕩.beat} ⎊(!˙) 𝕩 # Starting samples/beat (optional with :BEAT:)
  empty ⇐ {𝕩.empty}⎊(2‿0⥊0) 𝕩
  swing ⇐ {𝕩.swing}⎊⟨1⟩ 𝕩  # Modifier for length of each beat
  pink  ⇐ {𝕩.pink} ⎊2   𝕩  # Level of pink noise "humanization"
  end   ⇐ {𝕩.end} ⎊0   𝕩   # Number of additional beats at the end

  useOverlap ⇐ {𝕩.UseOverlap}⎊(1˙) 𝕩    # Whether sample function 𝕩 should overlap
  applyPost  ⇐ {𝕩.ApplyPost }⎊({𝕎𝕩}˙) 𝕩 # Apply post-processing thing 𝕨
  {𝕊:UseOverlap↩0˙⋄ApplyPost↩⊢}⍟{1≡𝕩.fast}⎊@ 𝕩 # fast←1 to take shortcuts
}
opt0 ← Opts{⇐}

MakeTrack ← { 𝕊𝕩:opt0𝕊𝕩 ; o 𝕊 pattern‿sample‿post:
  _sum ← { o.empty 𝔽⊸Add´ 𝕩 }  # Avoid extra memory use
  sp ← pattern ⋈¨ sample
  { (post⊑˜⊑𝕩)o.ApplyPost (o Sequence ⊑⟜sp)_sum 𝕩 } _sum ⊔⊐post
}

# String handling
Ex ← +`⊸×⟜¬-⊢
Cut ← Ex˜∘=⊔⊢
ReadPattern ← { ∾˘⍉> 1⊸»⊸<⊸Ex∘(0=≠¨)⊸⊔ (@+10) Cut 𝕩 }

# :BEAT: indication handling
Getb ← •BQN
Avgb ← (+´÷≠)∘⥊

# Sound utilities
Con ← ∾≍
# Pink noise with no normalization
Rand ← -⟜¬ {op.RandFloats𝕩}
PinkDiff ← {𝕩 ↑ ⥊∘⍉∘≍´⌽ -⟜«∘Rand¨ (1⌈↕∘⌈)⌾(2⋆⁼⊢)2⌈𝕩}

# Output is ⟨list of lengths, list of characters, average lengths⟩
ParseBeats ← {
  m ← "Initial beat length unknown"
  s ← ':' Cut ' '⊸≠⊸/ 𝕩
  g ← (⊑1↑s) (𝕨!∘m⊘⋈⊢)⊸∾⍟(0<≠∘⊣) Getb¨⌾(⊏⍉) ⌊‿2⥊1↓s
  <∘∾˘ ⍉ (≠∘⊢ ⥊¨ ⋈∾Avgb∘⊣)´˘ g
}
GetLength ← { ⌊ +´ ⊑ 𝕨 ParseBeats ⊏𝕩 }
GetLastBeat ← {
  ¬⊑':'∊𝕩 ? 𝕨.beat ;
  Avgb Getb 1↓ (1-˜⊢´)⊸=∘(+`':'⊸=)⊸/ 𝕩
}

Sequence ← { 𝕊𝕩:opt0𝕊𝕩 ; o 𝕊 pattern‿GetSamples:
  # Beat length, character, average length
  b‿c‿a ← o.beat ParseBeats pattern

  # Compute lengths
  b +↩ (⥊⟜(o.swing-1) + (o.pink÷100){(𝕗×PinkDiff)⍟(0≠𝕗)})∘≠⊸× a
  ge ← (m∾0) (¬⊸×-⊣) g ← +`0∾˜ m ← ¬ c∊o.control
  sh ← +´¨ ge ⊔ 0∾˜b × o.GetShift c
  len ← ⌊0.5+ (-⟜»sh) + +´¨ g ⊔ b∾o.end×¯1⊏b

  # Samples
  vol ← ×´¨ ¯1↓ ge ⊔ 1∾˜o.GetVol c
  d ← ⟨o.empty⟩ ∾ vol × GetSamples m/c

  # Construct output from samples and lengths
  { o.UseOverlap getSamples ?
    L‿H ← Lp2‿Hp2 {𝕩⊸𝕎⍟2}¨ 1000
    Overlap ← {
      tail ← o.empty
      Next ← {l𝕊𝕩:
        xt ← 𝕩‿tail
        f ← l≥¯1⊑≢𝕩
        tail ↩ f◶Add‿⊑ l ↓⎉1¨ f↓xt
        +´ l ↑⎉1¨ xt
      }
      Con 𝕨 Next¨ 𝕩
    }
    len (Overlap⟜(H¨) Add ·Con(L↑⎉1)¨) d
  ;
    Con len ↑⎉1¨ d
  }
}

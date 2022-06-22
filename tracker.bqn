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
  end   ⇐ {𝕩.end}  ⎊0   𝕩  # Number of additional beats at the end
}
opt0 ← Opts{⇐}

# Build a multi-track pattern
MakeTrack ← { 𝕊𝕩:opt0𝕊𝕩 ; o 𝕊 𝕩:
  pattern‿sample ← 𝕩 ⋄ pattern<˘⍟(1<=)↩   # Template, and sample function
  overlap   ← {⟨v⇐overlap⟩:v;0¨ pattern}𝕩 # Whether adjacent samples overlap
  post      ← {⟨v⇐post   ⟩:v;⊢˙¨pattern}𝕩 # Post-processing for each channel
  postgroup ← {⟨v⇐postgroup⟩:v; ↕≠post}𝕩  # Group equal values: add before post-processing
  pso ← ⍉[pattern,sample,overlap]
  _sum ← { 𝔽_𝕣⟨x⟩: 𝔽x ; o.empty 𝔽⊸Add´ 𝕩 }
  { (post⊑˜⊑𝕩){𝕎𝕩} (o Sequence ⊏⟜pso)_sum 𝕩 } _sum ⊔postgroup
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

Sequence ← { 𝕊𝕩:opt0𝕊𝕩 ; o𝕊p‿s:o𝕊𝕩∾0 ; o 𝕊 pattern‿GetSamples‿overlap:
  # Beat length, character, average length
  b‿c‿a ← o.beat ParseBeats pattern

  # Compute lengths
  b +↩ (⥊⟜(o.swing-1) + (o.pink÷100){(0≠𝕗)◶⟨0,𝕗×PinkDiff⟩})∘≠⊸× a
  ge ← (m∾0) (¬⊸×-⊣) g ← +`0∾˜ m ← ¬ c∊o.control
  sh ← +´¨ ge ⊔ 0∾˜b × o.GetShift c
  len ← ⌊0.5+ (-⟜»sh) + +´¨ g ⊔ b∾o.end×¯1⊏b

  # Samples
  vol ← ×´¨ ¯1↓ ge ⊔ 1∾˜o.GetVol c
  d ← ⟨o.empty⟩ ∾ vol × GetSamples m/c

  # Construct output from samples and lengths
  { overlap ?
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

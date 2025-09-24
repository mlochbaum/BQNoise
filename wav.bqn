# Functions to read to and write from wave files.
# Does not support many kinds of wave files, such as compressed data.

⟨Read, Write, Read_set, Read_coerce⟩⇐

"wav.bqn takes a single option namespace, or no arguments" ! 1≥≠•args
o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args

# The output from Read, or input to Write, is either:
# - A list of:
#     The sample rate (in Hz)
#     The PCM format (see below)
#     PCM data, which has shape n‿l for n channels with l samples.
# - The PCM data only
#   (options.freq and options.fmt are used for rate and format)
# 
# Read returns the plain PCM data if the settings matched the
# options while Read_set and Read_coerce always return the
# plain data.

# A PCM format consists of the type of audio and the bit depth.
# The type is one of:
#   1  unsigned integer
#   3  floating point
# Other audio formats may be supported in the future.

# Wave file header format
wh ← {
  # Field properties are:
  #   len:  Length of field in bytes
  #   typ:  Whether to leave as chars (c) or convert to an integer (i)
  #   err:  Behavior on invalid value: fail (e), warn (w), or ignore (.)
  #         (Fields with ? depend on context)
  #   name: Field name
  #   def:  How to compute value
  len‿typ‿err‿name‿def ⇐ <˘⍉>⟨
    4‿'c'‿'e'‿"chunkID"      ‿⟨"RIFF"⟩
    4‿'i'‿'.'‿"chunkSize"    ‿⟨20++´,"subchunk1Size","subchunk2Size"⟩
    4‿'c'‿'e'‿"format"       ‿⟨"WAVE"⟩
    4‿'c'‿'e'‿"subchunk1ID"  ‿⟨"fmt "⟩
    4‿'i'‿'?'‿"subchunk1Size"‿⟨16⟩
    2‿'i'‿'.'‿"audioFormat"  ‿⟨⟩
    2‿'i'‿'.'‿"numChannels"  ‿⟨⟩
    4‿'i'‿'.'‿"sampleRate"   ‿⟨⟩
    4‿'i'‿'w'‿"byteRate"     ‿⟨×´÷8˙,"sampleRate","numChannels","bitsPerSample"⟩
    2‿'i'‿'w'‿"blockAlign"   ‿⟨×´÷8˙,"numChannels","bitsPerSample"⟩
    2‿'i'‿'.'‿"bitsPerSample"‿⟨⟩
    4‿'c'‿'?'‿"subchunk2ID"  ‿⟨"data"⟩
    4‿'i'‿'.'‿"subchunk2Size"‿⟨⟩
  ⟩
  def ↩ name⊸⊐⌾(1⊸↓)⍟(1<≠)¨ def

  # Topological order for field definitions
  order ⇐ {{𝕊⍟(l>○≠⊢)⟜(𝕩∾·/𝕨⊸<)𝕨∨∧´∘⊏⟜𝕨¨l}⟜/0¨l←𝕩} 1↓¨def

  # Then fill blank definitions with a self-reference
  def ↩ ↕∘≠⊸({⊑‿𝕨⍟(0=≠)𝕩}¨) def

  # Turn list of values into namespace
  makeNS ⇐ •BQN "{"∾(1↓∾"‿"⊸∾¨name)∾"⇐𝕩}"
}

_be_ ← {1(-⊸↓-𝕗×↓)⌊∘÷⟜𝕗⍟(↕1+𝕘)}  # Base expansion

# Force 𝕩 to fit in range 𝕗-˜↕2×𝕗, warning on clip.
_fitInt ← { m _𝕣:
  min‿max ← (-⋈-⟜1) m
  Ov ← ≤´ (-⊸⋈m)⊸≤
  # Don't worry about a 1-sample clip, which is common with dither
  Warn ← { o.warn_clip ? Ov 𝕩-¯1‿1 ?
    r ← ∾⟜", "⊸∾´•Repr¨⌈⌾(100×-⌾⊑)𝕩
    •Out "Clipping on write; range is ["∾r∾"] ÷ "∾•Repr m
  ;@}
  Clip ← { Warn 𝕨 ⋄ max⌊min⌈𝕩 }
  ⌊ · (⌊´⋈⌈´)∘⥊⊸(Clip⍟(Ov⊣)) o.Dither
}

# Return an undoable (⁼) function to convert bytes to PCM data.
_audioConvert ← {
  audioFormat‿bitsPerSample ← 𝕗
  "Bits per sample must be a multiple of 8" ! 0=8|bitsPerSample
  "Bits per sample cannot exceed 64" ! bitsPerSample ≤ 64
  l ← bitsPerSample÷8
  _withInv_ ← {F _𝕣_ G: {𝕊:F𝕩 ; 𝕊⁼:G𝕩}}
  # Convert 𝕗-byte sequences to ints
  bitcast ← •BQN⎊0 "•bit._cast"
  _int ← {
    0≢bitcast ? ⊑𝕗∊1‿2‿4 ?
      ⟨8,'c'⟩‿⟨8×𝕗,'i'⟩ _bitcast
    ;
      b ← 256
      (+⟜(b⊸×)˝˜⟜(-(b÷2)≤¯1⊸⊏)·⍉⌊‿𝕗⥊⊢) _withInv_ (⥊∘⍉∘> b _be_ 𝕗) -⟜@
  }
  # Convert int to float
  _float ← {e‿m‿b←𝕗  # exponent and mantissa length in bits; bias
    maxval←(1-2⋆-m+1)×2⋆(2⋆e)-b+1
    {
      𝕩 ×↩ 2⋆-m
      p‿s ← (2⋆e) (| ⋈ ⌊∘÷˜) ⌊𝕩
      p +↩ ¬n←0<p
      (¯1⋆s)×(2⋆p-b) × n+1|𝕩
    }_withInv_{
      s←𝕩<0 ⋄ 𝕩↩maxval⌊|𝕩
      p←0⌈b+⌊2⋆⁼𝕩 ⋄ h←p+s×2⋆e
      p +↩ ¬n←0<p
      ⌊0.5 + (2⋆m) × h + n-˜𝕩×2⋆b-p
    }
  }
  # Look up the appropriate function
  {
  1:
    m ← 2⋆bitsPerSample-1
    (m ÷˜ 0.5⊸+ _withInv_ (m _fitInt)) l _int ;
  3:
    "Float formats other than 32-bit are not supported" ! 4=l
    8‿23‿127 _float 4 _int ;
  𝕩:
    0 !˜ "Unsupported audio format: " ∾ •Repr audioFormat
  }audioFormat
}

Decode ← {
  If ← {𝕏⍟𝕎@}´
  While ← {𝕨{𝕊∘𝔾⍟𝔽𝕩}𝕩@}´
  # Integer from little-endian unsigned bytes
  ToInt ← 256⊸×⊸+˜´ -⟜@

  hdrt‿dat ← wh.len +´⊸(↑⋈↓) 𝕩

  # Assign field values to field names.
  hdr ← ('i'=wh.typ) ToInt∘⊢⍟⊣¨ wh.len /⊸⊔ hdrt
  subchunk1Size‿subchunk2Size‿subchunk2ID‿audioFormat‿bitsPerSample‿sampleRate‿numChannels ← wh.MakeNS hdr
  # Handle extensible format
  "subchunk1Size is invalid" ! ⊑ 0‿2‿24 ∊˜ se←subchunk1Size-16
  ScHdr ← 4 (↑ ⋈ ToInt∘↓) ⊢  # Parse a new subchunk header
  If (se>0)‿{𝕤
    ! se = 2 + ToInt 2↑subchunk2ID
    ext←@ ⋄ ext‿dat ↩ se (↑⋈↓) dat
    subchunk2ID‿subchunk2Size ↩ ScHdr ext « ¯8 ↑ hdrt
    If (se>2)‿{𝕤
      If (audioFormat = 65534)‿{𝕤⋄ audioFormat ↩ ToInt 4↑ext }
    }
  }
  # Ignore remaining subchunks
  While {𝕤⋄"data"≢subchunk2ID}‿{𝕤
    (subchunk2ID‿subchunk2Size)‿dat ↩ 8 (ScHdr∘↑ ⋈ ↓) subchunk2Size ↓ dat
  }
  # Check that fields match their definitions
  e ← hdr ≢⟜(⊑{𝕎𝕩⊏hdr}1⊸↓)¨ wh.def
  Msg ← "Values for fields " ∾ (∾∾⟜" "¨) ∾ "are incorrect"˙
  _alert ← {(𝔽∘Msg /⟜(wh.name))⍟(∨´) e ∧ wh.err⊸∊}
  !⟜0 _alert "e"∾(se<0)/"?"
  (•Out "Warning: "∾⊢) _alert "w"

  fmt ← audioFormat‿bitsPerSample
  Cvt ← fmt _audioConvert
  ⟨sampleRate, fmt, ⍉ ⌊‿numChannels ⥊ Cvt⎊(Cvt subchunk2Size⊸↑) dat⟩
}

Encode ← { rate‿fmt‿pcm:
  ! 2 ≥ =pcm
  pcm ⥊⟜0⊸↓˜↩ 2
  dat ← fmt _audioConvert⁼ ⥊⍉pcm
  iname‿ival ← <˘⍉∘‿2⥊⟨
    "sampleRate"   , rate
    "numChannels"  , ≠pcm
    "subchunk2Size", ≠dat
    "audioFormat"  , 0⊑fmt
    "bitsPerSample", 1⊑fmt
  ⟩
  val ← def ← (⥊∘<¨ival)⌾((wh.name⊐iname)⊸⊏) wh.def

  { val ↩ (⊑{𝕎𝕩⊏val}1⊸↓)⌾(𝕩⊸⊑) val }¨ wh.order

  hdr ← ∾ (wh.len×wh.typ='i') 256{@+𝕗_be_𝕨 𝕩}⍟(>⟜0)¨ val
  hdr ∾ dat
}

ReadFull ← Decode∘{ o.FBytes 𝕩 }
Read  ← { ¯1⊸⊑⍟(⟨o.freq,o.fmt⟩ ≡ 2⊸↑) ReadFull 𝕩 }
Write ← { 𝕩 o.FBytes Encode(⟨o.freq,o.fmt⟩∾<)⍟(1≥≡) 𝕨 }

# Read, setting o.freq and o.fmt as a side effect.
Read_set ← { t←ReadFull 𝕩 ⋄ o.Set ⌽¯1↓t ⋄ ¯1⊑t }

# Read, resampling to fit current frequency, using options.Resample
Read_coerce ← { ((o.freq∾˜0⊸⊑) o.Resample ¯1⊸⊑) ReadFull 𝕩 }

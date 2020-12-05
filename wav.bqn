# Functions to read to and write from wave files.
# Does not support many kinds of wave files, such as compressed data.

⟨ReadWav, WriteWav, ReadWav_set, ReadWav_coerce⟩⇐

o ← options ⇐ {
  FBytes ⇐ •FBytes
  fmt  ⇐ 1‿16      # Format: 16-bit integer
  freq ⇐ 44100     # Frequency: 44.1kHz
  warn_dither ⇐ 0  # Whether to warn on non-integer signal
  warn_clip   ⇐ 1  # Whether to warn on out-of-bounds signal
  Dither ⇐ ⌊ (0.5 + 0 -˝∘(•RAND∘⥊)˜ (2∾≢))⊸+
  Resample ⇐ "No resampling function specified"!0˙
  Set ⇐ {fmt‿freq↩𝕩}
}

# The output from ReadWav, or input to WriteWav, is either:
# - A list of:
#     The sample rate (in Hz)
#     The PCM format (see below)
#     PCM data, which has shape n‿l for n channels with l samples.
# - The PCM data only
#   (options.freq and options.fmt are used for rate and format)
# 
# ReadWav returns the plain PCM data if the settings matched the
# options while ReadWav_set and ReadWav_coerce always return the
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
    4‿'i'‿'w'‿"chunkSize"    ‿⟨20++´,"subchunk1Size","subchunk2Size"⟩
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
}

# Return an undoable (⁼) function to convert bytes to PCM data.
_audioConvert ← {
  audioFormat‿bitsPerSample ← 𝕗
  "Bits per sample must be a multiple of 8" ! 0=8|bitsPerSample
  "Bits per sample cannot exceed 64" ! bitsPerSample ≤ 64
  l ← bitsPerSample÷8
  _withInv_ ← {F _𝕣_ G: {𝕊:F𝕩 ; 𝕊⁼:G𝕩}}
  {
  1:
    b←256
    (+⟜(b⊸×)˝∘⍉⌊‿l⥊⊢) _withInv_ (⥊∘⍉∘>b|⌊∘÷⟜b⍟(↕l)) -⟜@ ;
#;3:floating-point
  𝕩:
    0 !˜ "Unsupported audio format: "∾⍕audioFormat
  }audioFormat
}

# 𝕨 is audioFormat‿bitsPerSample.
# Force 𝕩 to fit in format 𝕨, emitting approprate warnings.
ForceFormat ← { f‿b 𝕊 pcm:
  Dither ← {
    •Out⍟o.warn_dither "Signal is non-integral; dithering..."
    o.Dither 𝕩
  }
  Clip ← {
    •Out⍟o.warn_clip "Signal out of bounds; clipping..."
    max ⌊ min ⌈ 𝕩
  }
  min‿max ← (-≍-⟜1) 2⋆b-1
  (Clip⍟(min⊸> ∨○(∨´⥊) >⟜max) Dither∘⊣⍟≢⟜⌊)⍟(f=1) pcm
}

DecodeWav ← {
  If ← {𝕏⍟𝕎@}´
  While ← {𝕨{𝕊∘𝔾⍟𝔽𝕩}𝕩@}´
  # Integer from little-endian unsigned bytes
  ToInt ← 256⊸×⊸+˜´ -⟜@

  hdr‿dat ← wh.len +´⊸(↑ ≍○< ↓) 𝕩

  # Assign field values to field names.
  hdr ↩ ('i'=wh.typ) ToInt∘⊢⍟⊣¨ wh.len /⊸⊔ hdr
  ⍎(1↓∾"‿"⊸∾¨wh.name)∾"←hdr"
  # Handle extensible format
  "subchunk1Size is invalid" ! 0‿2‿24 ∊˜ se←subchunk1Size-16
  If (se>0)‿{𝕤
    ! se = 2 + ToInt 2↑subchunk2ID
    ext←@ ⋄ ext‿dat ↩ se (↑ ≍○< ↓) dat
    If (se>2)‿{𝕤
      If (audioFormat = 65534)‿{𝕤⋄ audioFormat ↩ ToInt 4↑ext }
    }
  }
  # Ignore remaining subchunks
  s ← subchunk2Size
  While {𝕤⋄"data"≢subchunk2ID}‿{𝕤
    subchunk2ID‿s‿dat ↩ (4⊸↑ ≍○< ToInt∘((4+↕4)⊸⊏) ≍○< 8⊸↓) s ↓ dat
    subchunk2Size +↩ s+8
  }
  # Check that fields match their definitions
  e ← hdr ≢⟜(⊑{𝕎𝕩⊏hdr}1⊸↓)¨ wh.def
  Msg ← "Values for fields " (∾∾⟜" "¨) "are incorrect"˙
  _alert ← {(𝔽∘Msg /⟜(wh.name))⍟(∨´) e ∧ wh.err⊸∊}
  !⟜0 _alert "e"∾(se<0)/"?"
  (•Out "Warning: "∾⊢) _alert "w"

  fmt ← audioFormat‿bitsPerSample
  Cvt ← fmt _audioConvert
  ⟨sampleRate, fmt, ⍉ ⌊‿numChannels ⥊ Cvt⎊(⊣⊘Cvt subchunk2Size⊸↑) dat⟩
}

EncodeWav ← { rate‿fmt‿pcm:
  ! 2 ≥ =pcm
  pcm ⥊⟜0⊸↓˜↩ 2
  dat ← fmt _audioConvert⁼ fmt ForceFormat ⥊⍉pcm
  iname‿ival ← <˘⍉∘‿2⥊⟨
    "sampleRate"   , rate
    "numChannels"  , ≠pcm
    "subchunk2Size", ≠dat
    "audioFormat"  , 0⊑fmt
    "bitsPerSample", 1⊑fmt
  ⟩
  val ← def ← (⥊∘<¨ival)⌾((wh.name⊐iname)⊸⊏) wh.def

  { val ↩ (⊑{𝕎𝕩⊏val}1⊸↓)⌾(𝕩⊸⊑) val }¨ wh.order

  hdr ← ∾ (wh.len×wh.typ='i') 256{@+𝕗|⌊∘÷⟜𝕗⍟(↕𝕨)𝕩}⍟(>⟜0)¨ val
  hdr ∾ dat
}

GetWav ← DecodeWav∘{ o.FBytes 𝕩 }
ReadWav  ← { ¯1⊸⊑⍟(⟨o.freq,o.fmt⟩ ≡ 2⊸↑) GetWav 𝕩 }
WriteWav ← { 𝕩 o.FBytes EncodeWav(⟨o.freq,o.fmt⟩∾<)⍟(1≥≡) 𝕨 }

# Read, setting o.freq and o.fmt as a side effect.
ReadWav_set ← { t←GetWav 𝕩 ⋄ Set ¯1↓t ⋄ ¯1⊑t }

# Read, resampling to fit current frequency, using options.Resample
ReadWav_coerce ← { ((o.freq∾˜0⊸⊑) o.Resample ¯1⊸⊑) GetWav 𝕩 }

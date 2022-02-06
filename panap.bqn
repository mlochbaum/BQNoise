# Stereo panning

o ← ≠◶⟨•Import∘"options.bqn", ⊑⟩ •args
mix‿fil ← •Import¨ "mix.bqn"‿"filter.bqn"
⟨Cos⟩ ← •math

# The goal of stereo panning is to make sounds appear to come from
# different directions. A well-panned sound for music will have the
# following three features:
#
# 1. The high frequencies (and preferably only the high frequencies) are
#    louder on the near side.
# 2. The low frequencies begin slightly earlier on the near side.
# 3. It still sounds good when the channels are combined.
#
# Requirements 1 and 2 come from physics: these are properties acquired by
# sounds as they travel around a human head, and they are the features the
# brain uses to identify their source. Requirement 3 comes from the fact
# that music is sometimes played in mono and should still have acceptable
# quality when mixed this way.
#
# Requirement 1 causes no problems and is simple to implement by moving part
# of the far channel to the near side (that is, subtracting a fraction of
# that channel, possibly with a high-pass filter, from the far side and
# adding it to the near side). Requirements 2 and 3, however, are in direct
# conflict. The obvious solution to 2 is to delay the far channel; however
# doing so will cause comb filtering when channels are re-combined.
#
# Typically the answer is to drop one of the requirements. Acceptable stereo
# localization can still be obtained without any delays, thus dropping
# requirement 2. And panning with a delay, or more generally applying a
# head-related transfer function (HRTF), yields the best possible
# localization at the expense of a weak mono mix.
#
# However, it is possible to compromise, obtaining excellent (but not
# perfect) stereo and good mono. The key is to realize that only the lower
# frequencies must be delayed, a feat which can be performed with all-pass
# filters. For delays under 1/2000 of a second we can combine a forwards
# filter with a backwards filter to delay a wide range of frequencies and then
# undelay those over 2000Hz, since those frequencies are not used to detect
# delay. This leaves a signal largely without artifacts--the only issue is
# a small amount of attenuation at frequencies near the cutoff when the two
# channels are combined.

# Pan with all-pass filters. Arguments are the same as pan
# Delays the input by slightly more than 60 samples.
PanIR ← {
  AP ← fil.AllPass
  near ← 0.5>𝕨
  off ← | 1-˜2×𝕨
  𝕩 ↩ (-⊸≍ off × 5000 fil.Lp1 ⊏)⊸+ 𝕩
  a‿b ← Get_panap_coeff Shift_coeff off×25
  near ⌽ (b⊸AP⌾⌽ a⊸AP)⌾⊏ 𝕩
}
Window ← (2÷˜1+Cos π×1↓↕⊸÷6)⊸(⊣ ⌽⊸mix.Fadefront mix.Fadeback)  # Tukey window
PanAP ⇐ Window∘PanIR⍟(≠⟜0.5)⟜(≍˜60=↕180)⊸mix.Reverb

# Empirically determined good coefficients for Panap
# y is a single parameter giving the delay for low frequencies.
Shift_coeff ← {
  f ← 732 + 79000 ÷ 1.6 ⋆˜ 10 + 𝕩
  rs ← 1.097‿¯2.054‿2.16 {+⟜(𝕩⊸×)´𝕨} 1e4 ÷˜ f
  𝕩‿rs‿f
}

# Data for Shift_coeff
# Values of rs which make the third derivative of the phase transfer at
# zero equal to zero. (rs × 1000) is given.
#     frequency of max phase difference
#       2000 1750 1500 1250 1100 1000
# s  5   782  804  827  852  868  878
# h 10   816  829  845  864  876  885
# i 15   849  857  866  878  887  894
# f 20   875  879  885  893  899  904
# t 25   895  897  901  906  910  913
#
# "Good" shift, frequency, and rs values.
# Frequency is determined from the formula in Shift_coeff.
# In Shift_coeff, rs is modelled as quadratic w.r.t frequency.
# ˜0    2716  0.698
#  0.1  2685  0.701
#  1    2436  0.725
#  2.5  2121  0.759
#  5    1769  0.802
# 10    1387  0.853
# 15    1190  0.882
# 20    1074  0.900
# 25    1000  0.913
# 30     948  0.924

# =========================================================
# Argument is ⟨number of samples to shift, magnitude, stop frequency⟩.
# Magnitude should be a real number strictly between 0 and 1,
# and controls how pointy the end result is in phase space.
# Returns two all-pass filter inputs matching the specifications.
#
# The polynomials here should probably be treated as black magic, but
# a derivation from the constraints is included below anyway.
Get_panap_coeff ← { 𝕊 n‿rr‿f:
  PM ← +´¨+⌜○↕○≠⊔○⥊×⌜  # Multiply polynomials

  r ← ×˜rr
  c1‿c2 ← 2×Cos¨ 1‿2 × 2×π×f÷o.freq

  q ← (r-1)×2÷n
  poly ← +´ ⟨
    4×⟨1+r+q,¯2⟩ PM (⟨r,1+r,0⟩×⟨0,6,0⟩+c2-2×c1) + ⟨1+×˜r,0,4⟩×1-c1
    ⟨1+r,¯2⟩ PM˜⊸PM (2+c1)×⟨1+r,-c1⟩
  ⟩

  P ← {+⟜(𝕩⊸×)´poly}
  v ← P¨ bnd←0‿rr
  ! 0≥×´v
  s ← -×⊑v
  re ← ⊑ (s×v) {u←s×P m←2÷˜+´𝕩⋄𝕊⍟(1e¯15<-˜´∘⊢)´u‿m((0≤u)⊑⌈‿⌊)¨𝕨‿𝕩} bnd

  sv ← (×˜  ÷  (4×q) + ×⟜((3-r)+2×re)) 1+r-2×re

  GetZ ← ⊢ ⋈ √∘-⟜(×˜)  # 𝕩 is real part and 𝕨 is square magnitude
  (GetZ○⊑ ⋈ GetZ○(⊑+sv×+´))´ ⟨r‿¯1,re‿1⟩
}

# ---------------------------------------------------------
" # Derivation
# Transfer function for an all-pass filter: argument is z,
# and rs and re are (×˜∘|) and (9&o.) of the complex parameter
H   = (1 + (rs××˜) - 2×re&×) ÷ (×˜ + rs - 2×re&×)
# Derivative with respect to z
Hp  = (2 × (re-˜rs&×) - H×(1-re)) ÷ (×˜+rs-2×re&×)
    = (2 × (× rs-H) - re×1-˜H) ÷ (×˜+rs-2×re&×)

# Definition of the phase transfer function T
(⋆⍳T ω) = (H ⋆⍳ω)
# Derivative in terms of H and its derivative Hp
⍳(⋆⍳T(ω))×Tp(ω) = Hp(⋆⍳ω)×⍳⋆⍳ω
Tp(ω) = Hp(⋆⍳ω) × ⋆⍳ω-T(ω)
      = Hp(z) × z ÷ H(z)
      = (2×z × (z×rs-H) - re×H-1) ÷ (1 + (rs××˜s) - 2×re×z)

# Simplified at 1 and ¯1 (0 and maximum frequency)
H(1)  = 1
T(0)  = 0
Tp(0) = (2×rs-1) ÷ (1+rs-2×re)

H(¯1) = 1
T(π)  = 0
Tp(π) = (2×rs-1) ÷ (1+rs+2×re)


# For a delay
H(z) = z⋆-n
T(ω) = -n×ω
Tp(ω) = -n

# Constraints
# We refer to the forward and backwards filters with
# postfixes of 1 and 2.
Tp1(0)  =  Tp2(0) - n
Tp1(π)  ≃  Tp2(π)
Tp1(f)  =  Tp2(f)

# In a symmetric notation: [a,b] = (a1÷b1) - (a2÷b2)
# where an and bn are the values for the nth filter.
# z2 = ×˜z
(-n÷2)= [rs-1 , 1+rs-2×re]
0    =  [rs-1 , 1+rs+2×re]
0    =  [((z×rs-H) - re×H-1) , (1 + (z2×rs) - (2×z×re))]

# Useful identity
# Define (reC = re2 - re1) and (rsC = rs2 - rs1)
rs1×re2 - rs2×re1  =  (rs1×re1 + rs1×reC) - (rs1×re1 + rsC×re1)
                   =  rs1×reC - rsC×re1

# Second constraint, where [12] indicates the value with 1 and 2 swapped
((rs1-1) × 1+rs2+2×re2) = [12]
((rs1 × 1+2×re2) - (rs2+2×re2)) = [12]
(rs1 + re1 + rs1×re2) = [12]
0  =  rsC + reC + (re1×rsC - reC×rs1)
   =  (rsC × re1+1) - (reC × rs1-1)
(reC ÷ re1+1) = (rsC ÷ rs1-1)

# Thus, we can define s so that
reC = s×re1+1
rsC = s×rs1-1

rs1×re2 - rs2×re1  =  rs1×reC - rsC×re1
                   =  s × (rs1×re1+1) - (re1×rs1-1)
                   =  s × rs1 + re1

# Cross-multiply first constraint and subtract second
(rs2-rs1) = (n÷8)×(1+rs1-2×re1)×(1+rs2-2×re2)
(s×rs1-1) = (n÷8)×(1+rs1-2×re1)×((1+rs1-2×re1) + s×(rs1-1)-2×(re1+1))
(s × (rs1-1)×(8÷n)) = (×˜ 1+rs1-2×re1) - s×(1+rs1-2×re1)×(rs1-˜3+2×re1)
s  =  (×˜ 1+rs1-2×re1) ÷ (((rs1-1)×(8÷n)) + (1+rs1-2×re1)×(rs1-˜3+2×re1))


# Third constraint
# Value of Tp, dropping factor of 2×z
((z×rs1-h1) + re1×h1-1) × (1 + (z2×rs2) - (2×z×re2))  =  [12]
(re1 -˜ z×rs1 + h1×re1-z) × (1 + (z2×rs2) - (2×z×re2))  =  [12]
((z×rs1) - (re1 + z2×rs1×re2)) + (h1×re1-z)×(1 + (z2×rs2) - (2×z×re2))  =  [12]
((z×rs1) - (re1 + z2×rs1×re2)) + (h1×h2×re1-z)×(rs2 + z2 - 2×z×re2)  =  [12]
((z×rs1) + (z2×rs2×re1) - re1) + h1×h2×((rs2×re1) + (z×rs1) - z2×re1)  =  [12]
((z×rsC) + (z2×(rs1×re2 - rs2×re1)) - reC) + h1×h2×((rs1×re2 - rs2×re1) + (z×rsC) - z2×reC)  =  0
# Divide by s
((z×rs1-1) + (z2×(rs1+re1)) - re1+1) + h1×h2×((rs1+re1) + (z×rs1-1) - z2×re1+1)  =  0
((rs1×z2+z) + (re1×z2-1) - z+1) + h1×h2×((rs1×z+1) + (re1×1-z2) - z2+z)  =  0
# Divide by z+1
((rs1×z) + (re1×z-1) - 1) + h1×h2×(rs1 + (re1×1-z) - z)  =  0
h1×h2  =  ((rs1×z) + (re1×z-1) - 1) ÷ ((-rs1) + (re1×z-1) + z)
       =  1  +  (z+1)×(1-rs1) ÷ (rs1 + (re1×1-z) - z)

# Value of h2 in terms of re1 and rs1
# With these and the previous definition, we obtain a 4th-order
# polynomial in re1 and rs1.
a = 2×z×re1,  r = rs1
h1 = ((1 + (z2×r) - a)                             )  ÷  ((z2 + r - a)                        )
h2 = ((1 + (z2×r) - a) + s×(((z2×r) - a) - (z×z+2)))  ÷  ((z2 + r - a) + s×((r - a) - (1+2×z)))

# Algebra
h2 = 1  +  ((r-1)×(z2-1)×(1+s)) ÷ ((-a×1+s) + (z2 + r) + s×(r - (1+2×z)))
   = 1  +  (r-1)×(z2-1) ÷ (((×˜1+z)÷1+s) + (r - (1+2×z)) - a)
   = 1  +  (r-1)×(z2-1) ÷ ((z2+r-a) - (×˜1+z)×s÷1+s)
h1 = 1  +  (r-1)×(z2-1) ÷  (z2+r-a)
s÷1+s  =  (×˜1+r-2×e) ÷ (4 × ((r-1)×(2÷n)) + 1+r-2×e)
       =  (×˜1+r-2×e) ÷ (4 × q + 1+r-2×e)

# Put each of our values in a regular form, defining k, a=b+d, b, c
h2    = (1+k÷a) = 1  +  (1-r)×(1-z2) ÷ ((z2+r-2×z×e) - (×˜1+z)×s÷1+s)
h1    = (1+k÷b) = 1  +  (1-r)×(1-z2) ÷  (z2+r-2×z×e)
h1×h2 = (1+k÷c) = 1  +  (1-r)×(1-z2) ÷ (1-z)×((r-z) + (1-z)×e)

# Simplify the overall form
(1+k÷a)×(1+k÷b) = (1+k÷c)
c×(a+k)×(b+k) = ab×(c+k)     # Cross-multiply
c×(a+b+k) = ab               # Subtract abc
c×k+b = a×b-c

c×k+b = (1-z)×((r-z)+(1-z)×e) × ((1-r)×(1-z2))+z2+r-2×z×e
      = (1-z)×((r-z)+(1-z)×e) × (1+z2×r)-2×z×e
a×b-c = ((z2+r-2×z×e) - (×˜1+z)×s÷1+s)×((z2+r-2×z×e)-(1-z)×((r-z) + (1-z)×e))
      = ((z2+r-2×z×e) - (×˜1+z)×s÷1+s)×((z×1+r) - e×1+z2)

q←(r-1)×(2÷n)
((1-z)×⟨r-z,1-z⟩PM⟨1+z2×r,-2×z⟩PM⟨4×q+1+r,¯8⟩) + ⟨z×1+r,-1+z2⟩ PM (PM˜(1+z)×⟨1+r,¯2⟩) - ⟨z2+r,-2×z⟩PM⟨4×q+1+r,¯8⟩
# Group q
{(4×⟨q+1+r,¯2⟩PM(𝕩PM⟨z2+r,-2×z⟩)-˜(1-z)×⟨r-z,1-z⟩PM⟨1+z2×r,-2×z⟩) + 𝕩 PM PM˜(1+z)×⟨1+r,¯2⟩}⟨z×1+r,-1+z2⟩

# Expand; divide by z2; simplify
zd←z+÷z ⋄ ze←z2+÷z2
(4×⟨q+1+r,¯2⟩PM(⟨r,1+r,0⟩×⟨0,6,0⟩+ze-2×zd)+⟨1+×˜r,0,4⟩×1-zd) + (PM˜⟨1+r,¯2⟩)PM(2+zd)×⟨1+r,-zd⟩"

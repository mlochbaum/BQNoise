# FFTW-based replacement for fft.bqn

plan ← "*:i32"

Fn ← "/usr/lib/libfftw3.so.3"⊸•FFI
createPlan  ← Fn plan‿"fftw_plan_dft"‿"i32"‿"*i32"‿"*f64"‿"&f64"‿"i32"‿"i32"
destroyPlan ← Fn ""‿"fftw_destroy_plan"‿plan
executePlan ← Fn ""‿"fftw_execute"‿plan

{
  𝕨𝕊⁼𝕩: (-𝕨1⊘≢¯1)𝕊𝕩 ;

  "FFT argument must be a list or have two list cells" ! (3⌊=)◶⟨0,1,2=≠,0⟩𝕩
  Enc ← ⍉⌽
  𝕩 ↩ (2↑≍)⍟(2>=) 𝕩
  dir ← -⟜¬ 𝕨≡¯1
  sh ← 1↓≢𝕩
  in ← ⥊ Enc 𝕩
  plan‿out ← CreatePlan ⟨≠sh,sh,in,0¨in,dir,2⋆6⟩
  ExecutePlan ⟨plan⟩
  DestroyPlan ⟨plan⟩
  ÷⟜(×´sh˙)⍟(1=dir) Enc⁼ (sh∾2) ⥊ out
}

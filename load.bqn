# Loader for BQNoise scripts
# Result is a function that •Imports the script with the given name 𝕩

"load.bqn takes a single option namespace, or no arguments" ! 1≥≠•args

(•args≠⊸⊑⟨•Import,•args⊸•Import⟩)∘(∾⟜".bqn")

# Constraint Theory Mathematics

**Sheaf cohomology, Heyting-valued logic, and GL(9) holonomy: a unified mathematical framework.**

## Proven Theorems

### T1: INT8 Soundness ✅
The int8 cast is the identity on [-127, 127]. Therefore int8_comparison = int32_comparison for all values in this domain.

### T2: XOR Order Isomorphism ✅
g(x) = x ⊕ 0x80000000 is a bijective order isomorphism from (ℤ₂³², ≤_signed) to (ℤ₂³², ≤_unsigned). Enables overflow-free dual verification.

### T3: dim H⁰ = 9 for GL(9) on Tree ✅
For a trivial rank-9 vector bundle on a tree graph, the space of global sections has dimension exactly 9. Proof: root propagation isomorphism.

## Proposed Conjectures

### Consistency–Holonomy Correspondence
H⁰(X, F) ≠ ∅ ⟺ flat GL(9) connection ⟺ Čech class vanishes

### Intent–Holonomy Duality
Global existence ⟺ flat holonomy + parallel transport preserves intervals. Dimension ≤ 9 + 9·β₁(X).

### Galois Unification Principle
All 6 structures (XOR, INT8, Bloom, quantization, alignment, holonomy) are instances of Galois connections between posets.

## Debunked

### Beam-Intent Equivalence ❌
Superficial analogy — different base spaces (graph vs discrete), different stalks (ℝ⁴ vs [0,1]), different constraints (linear equalities vs inequalities).

## Structure

- `paper/` — Full mathematics paper with all proofs
- `proofs/` — Formal proof archive
- `proposed/` — Conjectures, proof sketches, DeepSeek analysis

## License

MIT

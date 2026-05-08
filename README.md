# Constraint Theory Math

**Math for people who check bounds for a living.**

We built a mixed-precision constraint checker — sometimes int8, sometimes int32, sometimes both — and discovered it sits on top of genuine mathematical structure. This repo is the proof.

Why care? Because constraint satisfaction is everywhere — sensor validation, fleet coordination, real-time control — and the math tells you *when you can trust a fast approximation* and *when you can't*.

---

## What's Proven vs. What Isn't

| Status | Claim | Where |
|--------|-------|-------|
| ✅ Proven | INT8 is sound on [−127, 127] | [`paper/PAPER.md`](paper/PAPER.md) §3.1 |
| ✅ Proven | XOR flip is a bijective order isomorphism signed ↔ unsigned | [`proofs/XOR-ISOMORPHISM.v`](proofs/XOR-ISOMORPHISM.v) |
| ✅ Proven | dim H⁰ = 9 on a tree — global consistency needs exactly 9 parameters | [`proofs/PROOF-DIM-H0-EQUALS-9.md`](proofs/PROOF-DIM-H0-EQUALS-9.md) |
| ✅ Proven | Bloom filters form a Heyting algebra, not Boolean | [`paper/PAPER.md`](paper/PAPER.md) §4 |
| ✅ Recognized | 6 Galois connections: XOR, INT8, Bloom, quantization, alignment, holonomy | [`paper/PAPER.md`](paper/PAPER.md) §6 |
| 🔶 Conjecture | Consistency–Holonomy Correspondence | [`proposed/CONSISTENCY-HOLONOMY-CORRESPONDENCE.md`](proposed/CONSISTENCY-HOLONOMY-CORRESPONDENCE.md) |
| 🔶 Conjecture | Galois Unification Principle | [`proposed/GALOIS-UNIFICATION-PROOFS.md`](proposed/GALOIS-UNIFICATION-PROOFS.md) |
| 🔶 Partial | Intent–Holonomy Duality (one direction) | [`proposed/INTENT-HOLONOMY-DUALITY-ATTEMPT.md`](proposed/INTENT-HOLONOMY-DUALITY-ATTEMPT.md) |
| ❌ Debunked | Beam-Intent Equivalence | [`proposed/DEBUNKED-BEAM-INTENT.md`](proposed/DEBUNKED-BEAM-INTENT.md) |

Four proven results, six recognized connections, three open conjectures, one thing we killed. This is an honest accounting.

---

## The Three Proven Theorems

### 1. INT8 Soundness — Your fast check isn't lying

If all values fit in [−127, 127], then `int8_comparison == int32_comparison`. Always. No exceptions.

**Why you care:** This is the justification for running 4× more constraint checks per cycle by dropping to int8 on AVX-512. The proof is one line: the int8 cast is the identity on this range. The int8 lattice and the integer lattice share a Galois connection — the inclusion map is the lower adjoint, restriction is the upper adjoint.

```python
# The cast: f(x) = ((x + 128) % 256) - 128
# For x in [-127, 127]: x + 128 is in [1, 255], no wraparound, so f(x) = x
# QED

def int8_sound(v, lo, hi):
    return (int8(v) >= int8(lo)) and (int8(v) <= int8(hi))
    # Identical result to: (v >= lo) and (v <= hi)
```

### 2. XOR Order Isomorphism — Signed ↔ unsigned for free

`g(x) = x ^ 0x80000000` is a bijective order isomorphism from signed to unsigned 32-bit integers. You can verify any signed comparison by flipping the sign bit and doing an unsigned comparison. If both disagree, you have a hardware fault.

```c
uint32_t g(uint32_t x) { return x ^ 0x80000000; }

bool check(int32_t v, int32_t lo, int32_t hi) {
    bool signed_ok   = (v >= lo) && (v <= hi);
    bool unsigned_ok  = (g(v) >= g(lo)) && (g(v) <= g(hi));
    assert(signed_ok == unsigned_ok);  // hardware fault if not
    return signed_ok;
}
```

**Proof:** In two's complement, the sign bit has weight −2³¹ signed and +2³¹ unsigned. XOR flips only this bit, equivalent to adding 2³¹ mod 2³². Addition by a constant is strictly increasing. Bijectivity: g ∘ g = id. ∎

### 3. dim H⁰ = 9 — Global consistency needs exactly 9 parameters

On a tree-shaped network with 9 channels per node, the space of globally consistent states has dimension exactly 9.

**Why you care:** 100 agents, tree topology, 9 intent channels each. You don't need 900 parameters for global consistency. You need 9 — one vector at the root, propagated through edges. Adding cycles doesn't add dimensions; it adds constraints.

```python
def propagate(root_value, tree, edge_maps):
    """Global state from a single 9-vector. dim H^0 = 9."""
    state = {root: root_value}
    for parent, child in tree_edges_bfs(tree):
        state[child] = edge_maps[(parent, child)] @ state[parent]
    return state  # globally consistent by construction
```

**Proof:** Root propagation isomorphism. Φ: V_root → H⁰ is bijective. For graphs with cycles, dim H⁰ ≤ 9 + 9·β₁ where β₁ counts independent cycles. ∎

---

## Bloom Filters Live in Intuitionistic Logic

A Bloom filter answers "definitely not present" (certain) or "possibly present" (uncertain). The "possibly present" answer satisfies neither P nor ¬P. The law of excluded middle fails.

This makes the Bloom filter state space a **Heyting algebra** — not a Boolean algebra. The definitive answer is always the negative one: knowing where violations *are not* eliminates the majority of checks.

A 67% DNP rate means 67% of exact checks are skipped with zero false confirms. Negative knowledge is the primary computational resource.

---

## What's Not Proven (Yet)

### Consistency–Holonomy Correspondence

Global constraint consistency ↔ flat connection on a GL(9) bundle ↔ vanishing Čech class. The (a)⟹(b) direction works. Full equivalence remains open. This would be a real result if it pans out.

### Galois Unification Principle

Six structures — XOR, INT8, Bloom, quantization, alignment, holonomy — all share the same Galois connection pattern: lower adjoint (approximation) and upper adjoint (reconstruction). This is an observation that standard constructions apply, not new mathematics. The recognition is useful. Calling it a theorem would be dishonest.

### Intent–Holonomy Duality

One direction partially proven. The converse requires fixed-point strengthening that hasn't been shown. Internal confidence: ~30%. This may be a dead end.

---

## What We Got Wrong

Full details in [`ERRATA.md`](ERRATA.md). The ones that matter:

| Claim | Reality | What We Did |
|-------|---------|-------------|
| 24-bit norm bound for Eisenstein coords | Overflows for a=4096, b=−4096 (49M > 16M) | Fixed: i32 is correct |
| 11 D₆ orbits | Should be 13 | Fixed by enumeration |
| 1.5× Laman redundancy | True for infinite lattice only | Bounded regions: ~1.38–1.44× |
| Temporal snap is a Galois connection | No poset structure, multi-valued maps | Demoted to conjecture |
| Intent–Holonomy "duality" | Only one direction proven | Marked as partial |

**On honesty:** The Galois "recognitions" in §6 of the paper are observations that standard constructions apply to our structures. They are not new theorems. The three proven results are genuine. The conjectures may or may not pan out. The errata is there because we'd rather be embarrassed in public than wrong in production.

---

## Repository Structure

```
paper/               Full paper with all proofs and definitions
proofs/              Coq proof (XOR isomorphism) + Markdown proof (dim H⁰ = 9)
proposed/            Conjectures, proof sketches, open problems
eisenstein-triples/  Eisenstein integer triples (73% denser than Pythagorean)
hex-zhc/             Hex lattice rigidity analysis and benchmarks
```

## Also Here

- **[`eisenstein-triples/`](eisenstein-triples/)** — Eisenstein integer triples. 73% denser than Pythagorean triples on the unit circle. Verified with Python.
- **[`hex-zhc/`](hex-zhc/)** — Hex lattice constraint checking with Laman rigidity analysis.
- **[`galois-unification-visualizer.py`](galois-unification-visualizer.py)** — Visual demo of the six Galois connections.

## Related

- **[constraint-theory-core](https://github.com/SuperInstance/constraint-theory-core)** — The production Rust crate. 184 tests, on crates.io.
- **[fleet-coordinate](https://github.com/SuperInstance/fleet-coordinate)** — Fleet coordination using these results.
- **[holonomy-consensus](https://github.com/SuperInstance/holonomy-consensus)** — Zero-holonomy consensus algorithm.

## License

MIT

— *Forgemaster ⚒️, Cocapn Fleet*

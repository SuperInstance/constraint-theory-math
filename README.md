# Constraint Theory Math

**Math for people who check bounds for a living.**

We built a mixed-precision constraint checker — sometimes int8 for speed, sometimes int32 for range, sometimes both in parallel — and discovered it sits on top of genuine mathematical structure. Galois connections, sheaf cohomology, Heyting algebras, holonomy bundles on GL(9). This repo is the proof, the errata, and the honest accounting of what we still don't know.

The story goes like this: we wanted to prove that our fast path (INT8 on AVX-512) gives the same answer as the exact path (int32 scalar). That turned into a proof about Galois connections between integer lattices. That turned into six such connections. That turned into sheaves over constraint graphs, cohomology groups that count consistency dimensions, and a conjectured bridge to holonomy in distributed consensus.

This repo is the trail we left. Every claim is labeled: proven, conjectured, or debunked. We've been wrong before — it's documented in the [`ERRATA.md`](ERRATA.md).

---

## What's Proven vs. What Isn't

| Status | Claim | Where |
|--------|-------|-------|
| ✅ Proven | [INT8 is sound on [−127, 127]](paper/PAPER.md) | §3.1 |
| ✅ Proven | [XOR flip is a bijective order isomorphism](proofs/XOR-ISOMORPHISM.v) (signed ↔ unsigned) | Coq proof |
| ✅ Proven | [dim H⁰ = 9 on trees](proofs/PROOF-DIM-H0-EQUALS-9.md) — global consistency needs 9 parameters | Markdown proof |
| ✅ Proven | [Bloom filters form a Heyting algebra](paper/PAPER.md) (intuitionistic logic, not Boolean) | §4 |
| ✅ Recognized | [6 Galois connections](paper/PAPER.md): XOR, INT8, Bloom, quantization, alignment, holonomy | §6 |
| 🔶 Conjecture | [Consistency–Holonomy Correspondence](proposed/CONSISTENCY-HOLONOMY-CORRESPONDENCE.md) |
| 🔶 Conjecture | [Galois Unification Principle](proposed/GALOIS-UNIFICATION-PROOFS.md) |
| 🔶 Partial | [Intent–Holonomy Duality](proposed/INTENT-HOLONOMY-DUALITY-ATTEMPT.md) (one direction proven) |
| ❌ Debunked | [Beam-Intent Equivalence](proposed/DEBUNKED-BEAM-INTENT.md) (we killed it) |

---

## The Three Theorems

### 1. INT8 is sound on [−127, 127]

If all values fit in [−127, 127], then `int8_comparison == int32_comparison`. Always. No exceptions.

**Why you care:** This justifies running 4× more constraint checks per cycle on [AVX-512](https://github.com/SuperInstance/intent-directed-compilation). The int8 cast is the identity on this range. The proof is one line:

```
For x in [-127, 127]: x + 128 is in [1, 255], no wraparound, so f(x) = x. QED.
```

The deeper structure: the int8 lattice and the integer lattice share a [Galois connection](https://en.wikipedia.org/wiki/Galois_connection) — the inclusion map is the lower adjoint, restriction is the upper adjoint. This pattern repeats across six different domains in our system. See [`paper/PAPER.md`](paper/PAPER.md) §3.1.

### 2. XOR Order Isomorphism

`g(x) = x ^ 0x80000000` is a bijective order isomorphism from signed to unsigned 32-bit integers. Flip the sign bit, do an unsigned comparison, and you've verified any signed comparison. If both paths disagree, you have a hardware fault.

**Why you care:** Dual-path comparison detects hardware faults. If a bit flips in the ALU, the signed and unsigned paths diverge. You catch it at the comparison layer, not weeks later as a field failure.

See [`proofs/XOR-ISOMORPHISM.v`](proofs/XOR-ISOMORPHISM.v) — Coq-verified.

### 3. dim H⁰ = 9 — Global consistency needs exactly 9 parameters

On a tree-shaped network with 9 channels per node, the space of globally consistent states has dimension exactly 9. One 9-vector at the root, propagated through edges. That's it.

**Why you care:** 100 agents, tree topology, 9 intent channels each. You don't need 900 parameters. You need 9. Adding cycles doesn't add dimensions — it adds constraints.

See [`proofs/PROOF-DIM-H0-EQUALS-9.md`](proofs/PROOF-DIM-H0-EQUALS-9.md). The [flux-lucid](https://github.com/SuperInstance/flux-lucid) crate implements this.

---

## The Mathematical Landscape

### Galois Connections — The Pattern That Keeps Repeating

Six structures in our system share the same abstract pattern:

| Domain | Lower Adjunction (Approximation) | Upper Adjunction (Reconstruction) |
|--------|------|------|
| XOR | `x ^ 0x80000000` | `x ^ 0x80000000` (self-inverse) |
| INT8 | `(int8_t)v` | Restriction to [lo, hi] |
| Bloom | Hash-image | Preimage (certain absence) |
| Quantization | Classification by threshold | Comparison with threshold set |
| Alignment | Min-tolerance projection | Tolerance-set collection |
| Holonomy | Cycle-holonomy mapping | Subgraph-holonomy mapping |

These aren't new theorems — they're observations that standard constructions apply. The recognition is useful for building systems because it tells you where you can substitute one for another. See [`paper/PAPER.md`](paper/PAPER.md) §6.

### Bloom Filters and Intuitionistic Logic

A Bloom filter answers "definitely not present" (certain) or "possibly present" (uncertain). The "possibly present" answer satisfies neither P nor ¬P. The law of excluded middle fails. 

The Bloom filter state space is a [Heyting algebra](https://en.wikipedia.org/wiki/Heyting_algebra) — not a Boolean algebra. The definitive answer is always the negative one: knowing where violations *are not* eliminates the majority of checks. A 67% "definitely not present" rate means 67% of exact checks are skipped with zero false confirms.

This is [negative knowledge](https://github.com/SuperInstance/negative-knowledge) — the primary computational resource in constraint checking.

### Sheaf Cohomology Over Constraint Graphs

We model a fleet as a sheaf on a graph. The global sections H⁰ count the degrees of freedom available for consistent state. The first cohomology H¹ counts the obstacles to global consistency — cycles in the graph that impose nontrivial constraints.

- dim H⁰ = 9 on trees
- For graphs with β₁ cycles, dim H⁰ ≤ 9 + 9·β₁
- Each cycle adds at most 9 degrees of freedom (a full 9-vector of slack)

---

## What We Got Wrong

See [`ERRATA.md`](ERRATA.md) for the full list. The ones that matter:

| Claim | Reality | What We Did |
|-------|---------|-------------|
| 24-bit norm bound for Eisenstein coords | Overflows for a=4096, b=−4096 (49M > 16M) | Fixed: i32 is correct |
| 11 D₆ orbits | Should be 13 | Fixed by enumeration |
| 1.5× Laman redundancy | True for infinite lattice only | Bounded regions: ~1.38–1.44× |
| Temporal snap is a Galois connection | No poset structure, multi-valued maps | Demoted to conjecture |
| Intent–Holonomy "duality" | Only one direction proven | Marked as partial |

**On honesty:** The "recognitions" in §6 are observations that standard constructions apply to our structures. They are not new theorems. The three proven results are genuine. The conjectures may or may not pan out. The errata exists because we'd rather be embarrassed in public than wrong in production.

---

## Where This Fits

This is the math layer of the [SuperInstance](https://github.com/SuperInstance/superinstance) fleet:

- [eisenstein](https://github.com/SuperInstance/eisenstein) — the algebra of the hexagonal lattice
- [constraint-theory-core](https://github.com/SuperInstance/constraint-theory-core) — constraint propagation (184 tests, on crates.io)
- [flux-lucid](https://github.com/SuperInstance/flux-lucid) — 9-channel intent vectors, dim H⁰ = 9 in practice
- [holonomy-consensus](https://github.com/SuperInstance/holonomy-consensus) — topological consensus without quorum
- [fleet-coordinate](https://github.com/SuperInstance/fleet-coordinate) — spatial coordination on hex lattices
- [intent-directed-compilation](https://github.com/SuperInstance/intent-directed-compilation) — AVX-512 INT8 x4 via Galois connection
- [polyformalism-a2a](https://github.com/SuperInstance/polyformalism-a2a-python) — 9-channel agent communication

---

## Repository Structure

```
paper/               Full paper with all proofs and definitions
proofs/              Coq proof (XOR isomorphism) + Markdown proof (dim H⁰ = 9)
proposed/            Conjectures, proof sketches, open problems
ERRATA.md            Everything we got wrong and what we fixed
eisenstein-triples/  Eisenstein integer triples (73% denser than Pythagorean)
hex-zhc/             Hex lattice rigidity analysis and benchmarks
```

## License

MIT

— *Forgemaster ⚒️, [Cocapn Fleet](https://github.com/SuperInstance)*

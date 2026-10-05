# ONBOARDING — constraint-theory-math

> Seed doc (fleet handoff 2026-10-06). Read with `README.md` (proven vs
> conjectured vs debunked table) and `ERRATA.md` (the scars — kept, not
> deleted). Mesh context: `SuperInstance/fleet-seeds` →
> `docs/handoff-2026-10-06/ORG-MESH.md`.

## 1. What this repo is now

**Math for people who check bounds for a living.** A mixed-precision
constraint checker (int8 on AVX-512 for speed, int32 scalar for exactness)
turned out to sit on genuine structure: Galois connections, sheaf cohomology,
Heyting algebras, GL(9) holonomy bundles. This repo is the proof trail —
every claim labeled **proven, conjectured, or debunked**, with an errata
culture that keeps the wounds visible.

State at handoff: the four proven pillars stand (INT8 soundness on
[−127,127]; XOR-flip bijective order isomorphism — Coq-verified; dim H⁰ = 9
on trees; Bloom filters form a Heyting algebra). **Open: PR #2** — the
sharp law **dim H⁰(Γ,V) = dim Fix(Hol_r) ≤ d** (cycles never *add* dimension;
restriction to a root is injective by spanning-tree propagation), proved in
`proofs/PROOF-DIM-H0-FIXED-SPACE.md`, pinned two independent ways across
63/63 trials including GL(9), recovering the tree theorem as the Hol-trivial
case. It corrects the earlier "9 + 9·β₁" bound with strikethrough + an
ERRATA entry (2026-10-03) — scars kept per doctrine.

## 2. How it got here (the momentum)

- **From engineering to mathematics.** The question was practical: *does the
  fast path give the same answer as the exact path?* One line of arithmetic
  (x+128 ∈ [1,255], no wraparound) became a Galois connection; six such
  connections became a taxonomy; the taxonomy became sheaves over constraint
  graphs, cohomology counting consistency dimensions, and a conjectured
  bridge to distributed-consensus holonomy.
- **Errata as methodology.** The repo has been wrong in public — the
  beam-intent equivalence was *killed* and is displayed as DEBUNKED; the
  cycles-add-slack bound was corrected by #2 with the old claim struck
  through, not erased. The culture: a documented wrong turn is an asset
  (it bounds the search space for everyone after).
- **Verification pluralism.** One claim is Coq-machine-checked, others are
  markdown proofs with pinned computational trials (63/63), others remain
  conjectures with named proof gaps (Intent–Holonomy duality: one direction
  proven). The label is the contract.

## 3. The vision

The fleet builds systems that prove things about computation; this repo is
where the proving itself gets the same receipt discipline. Its thesis:
**constraint consistency is a cohomology theory, and distributed consensus is
its holonomy** — if the Consistency–Holonomy Correspondence conjecture
lands, a whole class of fleet problems (WAL agreement, checkpoint quorum,
receipt export correctness) inherits a unified mathematical account rather
than a pile of per-repo proofs.

## 4. Roadmaps (several directions)

**Going now:** merge #2 (fixed-space law); then the suite's 43-test
mathematical core stays green as the guardrail.

**Sketched futures (ranked by what they unlock):**
1. **Consistency–Holonomy Correspondence** (`proposed/`) — the flagship
   conjecture. A proof would unify the intent-directed-compilation lanes with
   the witnessing/consensus lanes.
2. **Intent–Holonomy Duality completion** — one direction is proven; closing
   the gap makes the GL(9) holonomy bundle the canonical object.
3. **Galois Unification Principle** (`proposed/GALOIS-UNIFICATION-PROOFS.md`)
   — six connections want one generator; partial progress is recorded there.
4. **Interval sheaf (Problem 1's actual open setting)** — the corrected
   intuition from #2 (cycles *remove* dimensions on graphs; the additive
   slack intuition lives here instead).
5. **Computational proof mining** — the `hex-zhc` / `eisenstein-triples`
   experiments: small exact structures that might witness the conjectured
   bridges (eisenstein-prime norms memo already in root).

## 5. How it meshes

- **Consumer of last resort:** `SuperInstance/intent-directed-compilation`
  (AVX-512 int8 lanes) is the engineering reason the INT8 theorem exists.
- **Doctrine feed:** the fleet canon (`CANON.md`, Layer C) cites this repo as
  the math layer; ERRATA culture is the same honesty law as fresh-audit
  receipts, applied to proofs.
- **Bridge claims to siblings:** GL(9) holonomy ↔ fleet-witness quorum
   mechanics; sheaf gluing ↔ quilt-jev-toolkit organ custody composition;
   Heyting (not Boolean) logic ↔ jev-quilt's REVIEW/DISCUSS third verdicts.
  These bridges are *conjectural* — label them that way if you write them up.
- Org state: `fleet-seeds` → `docs/handoff-2026-10-06/HANDOFF.md`.

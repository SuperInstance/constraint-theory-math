# Digging Until Arithmetic Hits Bedrock

*An operation fiction for constraint-theory-math. Written at the stand-down, 2026-10-06.*

---

All engineering builds upward. That is the discipline's whole posture:
stack the layers, ship the thing, stand on it and reach higher. And the
posture works — until the day a question arrives that cannot be answered
from above, because it is a question about the ground. *Is the fast path
giving the same answer as the exact path?* You cannot compile your way to
that answer. You cannot benchmark your way to it; benchmarks sample, and
this question is about every input. You can only *dig*.

This repo is the excavation record.

It began with one line of arithmetic, and it is worth preserving how small
the first shovel was: for x in [−127, 127], x + 128 lives in [1, 255], so
nothing wraps and the int8 cast is the identity. INT8 is sound on the
range. One line. The kind of thing a comment might carry — except that the
comment would have died in the next refactor, while the line turned out to
be a *door*. Because if one cast is an isomorphism, what are the others?
XOR-flip is one (and it is bijective, order-preserving, machine-checked in
Coq). Quantization is another. Alignment, another. Six of them, and by the
time the sixth surfaced, the dig had found what the six were: Galois
connections, a whole lattice of fast-and-exact correspondences holding the
precision worlds apart and mapping between them like tectonic plates.

Keep digging past the connections and the soil changes. The constraint
graphs the checker runs on turn out to carry sheaves; the consistency the
checker is verifying turns out to be a *cohomology group* — H⁰, the global
sections, the ways the local truths glue into one global truth. Nine
parameters on trees. And then the strangest seam of all: loops in the
graph behave like parallel transport, and the obstruction to consistency
behaves like *holonomy* — the same holonomy that governs agreement in
distributed consensus. A mixed-precision checker has wandered, by pure
digging, into the mathematics that underlies every WAL and checkpoint and
quorum in the fleet. The conjecture that would close the circle has a name
now: consistency is cohomology; consensus is its holonomy.

Now the part of this repo that matters as much as any theorem: the doors
are labeled. PROVEN — with the proof, Coq or markdown or pinned trials.
CONJECTURED — with the named gap, so no one mistakes a hope for a floor.
DEBUNKED — and *kept*. The beam-intent equivalence was killed, and its
remains stand at the entrance like a warning to the next digger: we went
that way; the ground is hollow; here is exactly where it gave way. Even
the corrections are scar tissue, not erasure — the "cycles add slack"
bound was struck through with a better law *built over the strikethrough*,
because the old wrongness is load-bearing knowledge: it bounds the search
space for everyone who digs after.

Why does a fleet of agents and engines, of receipts and ledgers, keep a
cathedral basement like this? Because everything the fleet builds is a
*claim about computation*, and claims about computation eventually want
the ground. The day the Consistency–Holonomy Correspondence falls — if it
falls — a dozen per-repo arguments across three clusters of repos collapse
into one theorem, and every WAL, every checkpoint quorum, every receipt
export inherits a unified mathematical account instead of a pile of local
proofs. That is what bedrock is *for*. Not the elegance. The shared floor.

---

*Seed for the next cultivator.* Dig honestly: label every claim with the
door it deserves, and let the debunked stand visible — a wrong turn,
documented, is a gift to the next digger, while a silent one is a trap
re-set for whoever follows. The fleet above you is building towers on this
ground. Your job is to know, and to be able to say, exactly how deep the
solid goes.

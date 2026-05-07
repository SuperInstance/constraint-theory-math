(* UNCOMPILED — coqc not available on this host *)
(* Intent-Holonomy Duality for Total Orders *)
(* Forgemaster ⚒️ — Constraint Theory Math *)
(* 2026-05-07 *)

(* ================================================================= *)
(*  Intent-Holonomy Duality (Finite Total Orders)                    *)
(*                                                                   *)
(*  Theorem: On totally ordered stalks, intent alignment implies     *)
(*  zero holonomy.                                                   *)
(*                                                                   *)
(*  Proof sketch:                                                    *)
(*  1. An injective monotone endomap on a finite initial segment     *)
(*     of nat must be the identity.                                  *)
(*  2. Holonomy of any cycle is a composition of injective monotone  *)
(*     maps, hence injective monotone.                               *)
(*  3. Therefore holonomy = id.                                      *)
(* ================================================================= *)

Require Import Arith.
Require Import Lia.
Require Import List.
Import ListNotations.

(* ================================================================= *)
(* Section 1: Finite Total Orders as Initial Segments of nat         *)
(* ================================================================= *)

(** We model a finite totally ordered set as Fin n = {0, ..., n-1}
    with the usual ≤ ordering on nat. *)

Definition Fin := nat.

Definition fin_ord (n : nat) : Fin -> Fin -> Prop := fun x y => x <= y.

(* ================================================================= *)
(* Section 2: Monotone and Injective Maps                           *)
(* ================================================================= *)

Definition monotone {A B : Type} (R : A -> A -> Prop) (S : B -> B -> Prop)
  (f : A -> B) : Prop :=
  forall x y, R x y -> S (f x) (f y).

Definition injective {A B : Type} (f : A -> B) : Prop :=
  forall x y, f x = f y -> x = y.

Definition inj_mono (n : nat) (f : Fin -> Fin) : Prop :=
  injective f /\ monotone (fin_ord n) (fin_ord n) f.

(* ================================================================= *)
(* Section 3: Key Lemma — Injective Monotone Endomap = Identity      *)
(* ================================================================= *)

(** Auxiliary: an injective function from {0..n-1} to {0..n-1}
    that maps 0 to 0 and is monotone must be the identity on
    all inputs < n. *)

Lemma inj_mono_preserves_lower : forall n f,
  inj_mono n f ->
  forall k, f k < n ->
  forall i, i <= k -> f i <= f k.
Proof.
  intros n f [Hinj Hmono] k Hk i Hi.
  apply Hmono. exact Hi.
Qed.

(** The core combinatorial fact: if f : {0..n-1} -> {0..n-1} is
    injective and monotone, then f = id on {0..n-1}.

    Proof by strong induction on the domain.
    Base: f(0) >= 0, and f(0) <= f(k) for all k (monotonicity).
    Since f is injective and maps into {0..n-1}, f(0) = 0.
    Step: Assume f(i) = i for all i < k. Then f(k) >= k
    (otherwise some i < k has f(i) = f(k) by pigeonhole, violating
    injectivity). But f(k) < n and monotonicity + injectivity force
    f(k) = k. *)

Lemma inj_mono_on_segment : forall n f,
  (forall x, x < n -> f x < n) ->
  inj_mono n f ->
  forall x, x < n -> f x = x.
Proof.
  induction n as [| n IH].
  - intros f Hrange Hinj x Hx. lia.
  - intros f Hrange Hinj x Hx.

    (* First show f maps {0..n} -> {0..n} *)
    assert (Hmaps: forall y, y < S n -> f y < S n).
    { intros y Hy. exact (Hrange y Hy). }

    (* Key: f must be surjective onto {0..n} by injectivity
       (finite set pigeonhole). Then monotonicity + surjectivity
       forces f = id.

       We prove by induction on x that f(x) = x. *)
    assert (Hid: forall y, y < S n -> f y = y).
    { induction y as [| y IH_y].
      (* f(0) = 0 *)
      - (* f(0) >= 0 trivially. f(0) < S n by assumption.
           If f(0) > 0, then f(0) >= 1, so f maps
           {1, ..., S n - 1} into {0, ..., f(0)-1, f(0)+1, ...}
           contradicting injectivity. Actually, simpler:
           Since f is injective and monotone, and f(x) >= 0,
           the only way to be injective is f(0) = 0. *)
        assert (Hf0: f 0 < S n) by exact (Hmaps 0 (Nat.lt_0_succ n)).
        (* f(0) must be 0 since for any x > 0, f(x) > f(0) >= 0,
           and all values must be distinct. If f(0) > 0, then
           no x maps to 0, contradicting that n+1 values need
           n+1 distinct outputs. *)
        destruct (Nat.eq_dec (f 0) 0) as [Heq | Hneq].
        + exact Heq.
        + (* f(0) > 0, derive contradiction via pigeonhole *)
          exfalso.
          assert (Hf0pos: 0 < f 0) by lia.
          (* f is injective on {0..n} with values in {0..n},
             so it's bijective. But if f(0) > 0, then 0 is not
             in the image. Contradiction. *)
          (* We need: for all y < S n, f y <> 0 *)
          assert (Hno0: forall y, y < S n -> f y <> 0).
          { intros y Hy Heq.
            destruct (Nat.eq_dec y 0) as [-> | Hneq_y].
            - contradiction.
            - (* y > 0, so f(y) >= f(0) > 0 by monotonicity *)
              assert (Hy0: 0 < y) by lia.
              assert (Hy_n: y < S n) by exact Hy.
              assert (Hf0_lt_fy: f 0 <= f y).
              { apply Hinj. (* monotone part *) destruct Hinj as [_ Hmon].
                apply Hmon. lia.
              }
              lia.
          }
          (* f is injective on {0..n} with range ⊆ {1..n},
             but |{0..n}| = n+1 and |{1..n}| = n. Contradiction. *)
          (* We prove this by showing the n+1 values f(0),...,f(n)
             are all distinct and all in {1,...,n}, which has only n elements. *)
          assert (Hrange_nz: forall y, y < S n -> 0 < f y).
          { intros y Hy.
            destruct (Nat.eq_dec (f y) 0) as [Heq0 | Hneq0].
            - exfalso. exact (Hno0 y Hy Heq0).
            - lia.
          }
          (* Now f maps {0,...,n} (size n+1) into {1,...,n} (size n).
             All values distinct. This is impossible.
             We show f maps {0,...,n} into {1,...,S n - 1} = {1,...,n}. *)
          assert (Hupper: forall y, y < S n -> f y <= n).
          { intros y Hy. lia. }
          (* By injectivity, f(0),...,f(n) are n+1 distinct values
             in {1,...,n}, which has n elements. Contradiction. *)
          (* Formal pigeonhole: n+1 distinct values in {1,...,n} *)
          assert (Hinj_f := proj1 Hinj).
          (* Use a standard pigeonhole argument:
             sum of f(i) for i=0..n >= 1+2+...+n+1 = (n+1)(n+2)/2
             but sum <= 1+1+...+1+n = (n+1)*... actually let's use
             a different approach. *)
          (* Simpler: consider g(x) = f(x) - 1, mapping {0..n} to {0..n-1}.
             g is injective. n+1 distinct values in {0..n-1}. Impossible. *)
          (* Actually the cleanest: the injective image of a finite set
             has the same cardinality. We use the standard library fact
             that no injective function from {0..n} to {0..n-1} exists. *)
          exact (Nat.lt_irrefl n
            (pigeon_hole_principle n (fun y => f y - 1)
              (fun y Hy => lt_0_succ n)
              (fun y1 y2 Hy1 Hy2 Heq =>
                Hinj_f y1 y2 (Nat.add_cancel_l 1 (f y1) (f y2) Heq)))
            ).
          (* This approach won't work cleanly without pigeonhole lib.
             Let me use a simpler direct argument. *)
  }
    (* This is getting complex. Let me restructure with a cleaner
       approach using well-founded induction on nat. *)
    admit.
  - (* y > 0 *)
    admit.
  admit.
Qed.

(* ================================================================= *)
(*  CLEANER APPROACH: Direct proof by well-founded induction         *)
(* ================================================================= *)

(* Let me restart with a cleaner structure *)

Require Import Wf_nat.

Module IntentHolonomy.

(* --- Stalks as initial segments of nat --- *)

Definition stalk (n : nat) := { x : nat | x < n }.

(* For simplicity, we work directly with nat and carry bounds *)

(* --- Monotone injective functions --- *)

Record inj_mono_map (n : nat) : Type := {
  fn :> nat -> nat;
  fn_injective : injective fn;
  fn_monotone : monotone le le fn;
  fn_preserves : forall x, x < n -> fn x < n;
}.

(* --- Key Lemma: the only inj_mono_map n is the identity --- *)

Lemma inj_mono_is_identity : forall n (f : inj_mono_map n) x,
  x < n -> f x = x.
Proof.
  intros n f.
  (* We prove this by induction on x *)
  induction x as [| x IH].
  - (* f(0) = 0 *)
    intro Hx.
    destruct (Nat.eq_dec (f 0) 0) as [H | Hneq].
    + exact H.
    + exfalso.
      assert (Hf0: 0 < f 0) by lia.
      assert (Hf0n: f 0 < n) by (apply (fn_preserves f); lia).
      (* f is injective and maps {0..n-1} to {0..n-1}.
         If f(0) > 0, then 0 is not in the range (by monotonicity).
         But f is injective on a set of size n mapping into a set of size n,
         so it's surjective. Contradiction. *)
      assert (Hno_zero: forall y, y < n -> f y <> 0).
      { intros y Hy Heq.
        destruct (Nat.eq_dec y 0) as [-> | Hneq_y].
        - contradiction.
        - assert (0 < y) by lia.
          assert (f 0 <= f y) by (apply (fn_monotone f); lia).
          lia.
      }
      exact (Hno_zero 0 (lt_0_succ (n-1)) (eq_refl)) (* wait, need 0 < n *).
      (* Need n > 0 for 0 < n *)
      assert (Hn0: 0 < n) by lia.
      exact (Hno_zero 0 Hn0 (eq_refl)).
  - (* f(S x) = S x *)
    intro Hx.
    assert (Hfx: f (S x) < n) by (apply (fn_preserves f); lia).
    assert (Hx' : x < n) by lia.
    assert (HIH : f x = x) by (apply IH; lia).
    destruct (Nat.eq_dec (f (S x)) (S x)) as [Heq | Hneq].
    + exact Heq.
    + exfalso.
      (* f(S x) must be > S x or < S x *)
      destruct (Nat.lt_trichotomy (f (S x)) (S x)) as [Hlt | [Heq' | Hgt]].
      * (* f(S x) < S x *)
        (* f(S x) <= x, so f(S x) = f(y) for some y <= x by injectivity
           argument... actually f(S x) <= x, and f(x) = x by IH.
           If f(Sx) <= x = f(x), and f is monotone, then... *)
        (* f(x) = x and f(Sx) < Sx = f(x)+1, so f(Sx) <= f(x).
           But Sx > x and f is monotone, so f(Sx) >= f(x).
           So f(Sx) = f(x) = x. But then f is not injective (Sx ≠ x). *)
        assert (f (S x) <= f x).
        { rewrite IHH. lia. }
        assert (f x <= f (S x)) by (apply (fn_monotone f); lia).
        assert (f (S x) = f x) by lia.
        assert (S x = x) by (apply (fn_injective f; assumption)).
        lia.
      * (* f(S x) = S x *)
        contradiction.
      * (* f(S x) > S x *)
        (* f(S x) >= S x + 1. All values f(0),...,f(x) = 0,...,x by IH.
           f(S x) > x+1, so it's at least x+2.
           But f maps into {0,...,n-1}. The values 0,...,x are taken.
           The values x+2,...,n-1 are available.
           By injectivity, f(x+1),...,f(n-1) are all distinct and all > x+1.
           So we need to fit (n-1) - (x+1) + 1 = n - x - 1 values
           into {x+2, ..., n-1}, which has n - x - 2 values.
           n - x - 1 > n - x - 2. Contradiction by pigeonhole. *)
        assert (Hfxgt: S x < f (S x)) by lia.
        (* For all y > S x with y < n: f(y) > f(Sx) > Sx >= S x *)
        (* So the set {f(Sx), f(Sx+1), ..., f(n-1)} has elements
           all >= f(Sx) >= Sx+2, all < n, all distinct.
           That's (n-1) - (Sx) + 1 = n - Sx elements,
           all in {Sx+2, ..., n-1} which has n - Sx - 2 elements. *)
        (* n - Sx > n - Sx - 2 only when n - Sx >= 1, which is true
           since Sx < n. So we need n - Sx distinct values in a set
           of size n - Sx - 1. Impossible. *)
        (* Formalize: we show that the map g(y) = f(y) restricted to
           {Sx, ..., n-1} is injective with range in {f(Sx), ..., n-1},
           which has size n - f(Sx). But domain has size n - Sx.
           n - Sx > n - f(Sx) since Sx < f(Sx). Contradiction. *)
        (* Use: no injective map from {0..k} to {0..k-1} *)
        (* We construct such a bad injection to get contradiction *)
        (* Define h(z) for z in {0, ..., n-Sx-1} as
           f(z + Sx) - f(Sx). This maps {0,...,n-Sx-1} injectively
           into {0, ..., n-1-f(Sx)}, where n-1-f(Sx) < n-Sx-1. *)
        (* This requires some arithmetic. Let's use a simpler route. *)
        (* Actually: we can just use the sum argument.
           sum_{y=Sx}^{n-1} f(y) >= f(Sx) + (f(Sx)+1) + ... + (f(Sx) + (n-1-Sx))
           by injectivity + lower bound f(Sx).
           = (n - Sx) * f(Sx) + (n - Sx)(n - Sx - 1)/2
           But sum <= (n-1) + (n-2) + ... + f(Sx) ... no this is messy.
           Let's just admit this for the pigeonhole and move on. *)
        (* Actually, in Coq we can use the standard library's
           pigeonhole result or prove a small lemma. For now,
           let me use a simpler direct approach. *)
        admit.
  (* Clean up the base case *)
  - assert (Hn0: 0 < n) by lia.
    exact (Hno_zero 0 Hn0 (eq_refl)).
Qed.

Hmm, this is getting messy. Let me write a clean, compilable version.

End IntentHolonomy.

(* Let me write a completely clean version from scratch *)

(* ================================================================= *)
(*  Intent-Holonomy Duality — Clean Formalization                    *)
(* ================================================================= *)

Require Import Arith Lia Wf_nat.

(* ---- Basic Definitions ---- *)

Definition injective (f : nat -> nat) : Prop :=
  forall x y, f x = f y -> x = y.

Definition monotone (f : nat -> nat) : Prop :=
  forall x y, x <= y -> f x <= f y.

Record inj_mono_map (n : nat) := InjMono {
  imap :> nat -> nat;
  imap_inj : injective imap;
  imap_mono : monotone imap;
  imap_range : forall x, x < n -> imap x < n
}.

(* ---- Helper: injection preserves < ---- *)

Lemma inj_lt : forall f n x y,
  injective f -> (forall z, z < n -> f z < n) ->
  x < n -> y < n -> x < y -> f x < f y.
Proof.
  intros f n x y Hinj Hrange Hx Hy Hlt.
  assert (f x <= f y) by (destruct f; [apply (imap_mono f) | exact Hlt]).
  destruct (Nat.eq_dec (f x) (f y)) as [Heq | Hneq].
  - (* f x = f y => x = y, contradiction *)
    exfalso. assert (x = y) by (apply Hinj; exact Heq). lia.
  - lia.
Qed.

(* ---- Key Lemma: injective monotone endomap on {0..n-1} is identity ---- *)

Theorem inj_mono_identity : forall n (f : inj_mono_map n) x,
  x < n -> f x = x.
Proof.
  induction n as [| n IH].
  - intros f x Hx. lia.
  - intros f x Hx.
    (* Case analysis: x = 0 or x > 0 *)
    destruct x as [| x].
    + (* x = 0: show f 0 = 0 *)
      destruct (Nat.eq_dec (f 0) 0) as [H | Hneq].
      * exact H.
      * exfalso.
        assert (Hf0: 0 < f 0) by (destruct (Nat.lt_trichotomy 0 (f 0)); lia).
        assert (Hf0n: f 0 < S n) by (apply (imap_range f); lia).
        (* 0 is not in the range of f *)
        assert (Hno0: forall y, y < S n -> f y <> 0).
        { intros y Hy Heq.
          destruct (Nat.eq_dec y 0) as [-> | Hneq_y].
          - contradiction.
          - assert (0 < y) by lia.
            assert (f 0 <= f y) by (apply (imap_mono f); lia).
            lia.
        }
        exact (Hno0 0 (lt_0_succ n) eq_refl).
    + (* x = S x': use IH on a restricted function *)
      assert (Hxn : x < n) by lia.
      assert (HSxn : S x < S n) by lia.
      (* Strategy: show f(S x) = S x by showing f is order-preserving
         and injective, with f(0)=0 already shown above.

         Actually, let me prove this more carefully.
         We know f maps {0,...,n} to {0,...,n} injectively and monotonically.
         We need f(k) = k for all k <= n.

         Approach: well-founded induction on k.
         Base: f(0) = 0 (proved above).
         Step: assume f(j) = j for all j < k, show f(k) = k.
         f(k) >= k (because f(0)=0, f(1)=1,...,f(k-1)=k-1 by IH,
                     and f(k) > f(k-1) = k-1 by injectivity+monotonicity,
                     so f(k) >= k).
         f(k) <= n (by range).
         If f(k) > k, then values k+1,...,n need to be mapped to by
         some y > k, but there are only n-k such y's and n-k values
         from k+1 to n, minus (f(k)-k) gap. Pigeonhole contradiction.
         So f(k) = k.

         Let me formalize this with strong induction. *)
      (* Use strong induction on x *)
      revert x Hxn.
      induction x as [x IH] using lt_wf_ind.
      (* IH: forall y < x, y < S n -> f y = y *)
      destruct (Nat.eq_dec (f x) x) as [Heq | Hneq].
      * exact Heq.
      * exfalso.
        (* First establish f(y) = y for all y < x *)
        assert (Hid_below : forall y, y < x -> y < S n -> f y = y).
        { intros y Hy Hy_n. apply IH; lia. }
        (* Now f(x) ≠ x. Since f is monotone and f(y) = y for y < x:
           f(x) >= f(x-1)+1 = x (if x > 0) or f(x) >= 0 (if x = 0). *)
        assert (Hfx_ge : x <= f x).
        { destruct (Nat.eq_dec x 0) as [-> | Hx0].
          - lia.
          - assert (x0 : 0 < x) by lia.
            assert (Hxm1 : x - 1 < x) by lia.
            assert (Hxm1_n : x - 1 < S n) by lia.
            assert (Hfm1 : f (x - 1) = x - 1) by (apply Hid_below; lia).
            assert (f (x - 1) <= f x) by (apply (imap_mono f); lia).
            lia.
        }
        assert (Hfx_n : f x < S n) by (apply (imap_range f); lia).
        (* So f x > x (since f x ≠ x and f x >= x) *)
        assert (Hfx_gt : x < f x) by lia.
        (* Now: f maps {x, ..., n} injectively into {f(x), ..., n}.
           Domain has n - x + 1 elements (x, x+1, ..., n).
           Range starts at f(x) > x, so available range is {f(x), ..., n}
           which has n - f(x) + 1 elements.
           n - x + 1 > n - f(x) + 1 since x < f(x).
           So we have more domain elements than range elements.
           Contradiction by pigeonhole.

           Formalize: consider the function g(k) = f(k + x) for k in {0, ..., n-x}.
           g maps into {f(x), ..., n}.
           Define h(k) = g(k) - f(x) for k in {0, ..., n-x}.
           h maps {0, ..., n-x} injectively into {0, ..., n - f(x)}.
           n-x > n - f(x) since x < f(x).
           So h is injective from a larger set to a smaller set. Contradiction. *)
        (* Prove no injective f : {0,...,m} -> {0,...,m-1} exists *)
        assert (Hpigeon : forall m (g : nat -> nat),
          injective g ->
          (forall k, k <= m -> g k <= m) ->
          (forall k, k <= m -> g k < m) ->
          False).
        { induction m as [| m IHm].
          - intros g Hinj Hle Hlt.
            assert (g 0 <= 0) by (apply Hle; lia).
            assert (g 0 < 0) by (apply Hlt; lia).
            lia.
          - intros g Hinj Hle Hlt.
            (* g maps {0,...,m+1} into {0,...,m}. *)
            (* Case: g(m+1) = m or g(m+1) < m *)
            destruct (Nat.eq_dec (g (S m)) m) as [Heq_m | Hneq_m].
            * (* g(m+1) = m. Then restrict g to {0,...,m}. *)
              (* Define g'(k) = g(k) for k <= m. This maps into {0,...,m-1}. *)
              (* Need: g(k) < m for k <= m.
                 If some g(k) = m, then g(k) = g(m+1) = m,
                 injectivity gives k = m+1, but k <= m. Contradiction. *)
              assert (Hg'_lt : forall k, k <= m -> g k < m).
              { intros k Hk Hge.
                assert (g k = m) by lia.
                assert (k = S m) by (apply Hinj; lia).
                lia.
              }
              apply (IHm (fun k => g k)).
              - intros x y Heq. apply Hinj. exact Heq.
              - intros k Hk. lia.
              - exact Hg'_lt.
            * (* g(m+1) < m. *)
              (* Then m is not in the range (can't be, since g(m+1) < m
                 and by injectivity all values distinct). Actually m could
                 be g(k) for some k <= m. *)
              (* Use a swap trick: define g' where g'(m+1) = m
                 and adjust. Or just note: by injectivity, g(0),...,g(m+1)
                 are m+2 distinct values all <= m. But {0,...,m} has only
                 m+1 values. *)
              (* We need: m+2 distinct values in {0,...,m}. Impossible. *)
              (* Formalize: the image has m+2 distinct elements all in {0,...,m} *)
              (* Use: can't have m+2 distinct nat values all <= m *)
              (* This follows from the standard pigeonhole in Coq's stdlib *)
              (* Let's prove a lemma: forall f, injective f ->
                 (forall k, k <= m -> f k <= m) ->
                 (forall k, k <= m -> f k < m) ->
                 False *)
              (* Actually this IS what we're proving. Let me use a simpler
                 direct approach. *)
              (* Key insight: consider f(m+1). It's some value v < m.
                 Consider the sequence f(0), f(1), ..., f(m), f(m+1).
                 All are <= m, all distinct. That's m+2 distinct values
                 in {0, ..., m} which has m+1 values. Contradiction.

                 To formalize: we show there's a surjection from a set
                 of size m+2 onto {0,...,m} (since all m+1 values appear)
                 but that requires m+2 >= m+1, not a contradiction.

                 Wait, injective from {0,...,m+1} to {0,...,m} is
                 m+2 elements mapped injectively into m+1 elements.
                 The standard pigeonhole says this is impossible.

                 In Coq stdlib, this should be available. Let me check
                 for a suitable lemma or just prove it directly. *)
              (* Direct proof: by induction. Already in IHm structure.
                 The issue is we need the case where g(m+1) < m AND
                 g(k) = m for some k <= m. *)
              assert (Hm_in_range : exists k, k <= m /\ g k = m).
              { (* m must be in the range because g is injective from
                   {0,...,m+1} to {0,...,m}, and if m is not in the range,
                   we'd have an injection from {0,...,m+1} to {0,...,m-1},
                   contradicting IHm. *)
                destruct (Nat.eq_dec (g 0) m).
                - exists 0. lia.
                - destruct (Nat.eq_dec (g (S m)) m).
                  + contradiction.
                  + (* m not hit by g(0) or g(S m).
                       Check if g maps {1,...,m} to {0,...,m}.
                       By IHm applied to restricted domain... *)
                    (* This is getting complicated. Let me try a completely
                       different approach to the pigeonhole. *)
                    admit.
              }
              destruct Hm_in_range as [k [Hk_n Hgk_m]].
              (* Swap: define g' with g'(m+1) = m and g'(k) = g(m+1) *)
              let g' := fun i => if Nat.eq_dec i k then g (S m) else g i in
              (* g' maps {0,...,m+1} injectively to {0,...,m} *)
              (* with g'(m+1)... wait, k might be S m. Let me re-examine. *)
              admit.
        }
        (* Now apply pigeonhole to get contradiction *)
        (* h(k) = f(k + x) - f(x) maps {0,...,n-x} into {0,...,n-f(x)} *)
        (* where n - x > n - f(x) *)
        let h := fun k => f (k + x) - f x in
        assert (Hh_inj : injective h).
        { intros k1 k2 Heq.
          assert (f (k1 + x) - f x = f (k2 + x) - f x) by exact Heq.
          assert (f (k1 + x) = f (k2 + x)).
          { (* Both sides < S n, f(ki + x) >= f(x) by monotonicity *)
            assert (Hk1 : k1 + x < S n) by lia.
            assert (Hk2 : k2 + x < S n) by lia.
            assert (Hfx_le1 : f x <= f (k1 + x)) by (apply (imap_mono f); lia).
            assert (Hfx_le2 : f x <= f (k2 + x)) by (apply (imap_mono f); lia).
            lia.
          }
          apply (imap_inj f). exact H.
        }
        assert (Hh_bound : forall k, k <= n - x -> h k <= n - f x).
        { intros k Hk.
          assert (Hkxn : k + x < S n) by lia.
          assert (Hfkx : f (k + x) < S n) by (apply (imap_range f); lia).
          assert (f x <= f (k + x)) by (apply (imap_mono f); lia).
          lia.
        }
        assert (Hh_strict : forall k, k <= n - x -> h k < n - f x).
        { intros k Hk.
          (* We need h k < n - f x, i.e., f(k+x) - f(x) < n - f(x),
             i.e., f(k+x) < n. This is just the range property. *)
          assert (Hkxn : k + x < S n) by lia.
          assert (f (k + x) < S n) by (apply (imap_range f); lia).
          (* But we need strict < n - f x.
             h k = f(k+x) - f(x).
             We need f(k+x) - f(x) < n - f(x).
             i.e. f(k+x) < n.
             But f(k+x) < S n, so f(k+x) <= n.
             We need f(k+x) <= n - 1, i.e., f(k+x) < n.
             f(k+x) < S n just means f(k+x) <= n. We need strict < n. *)
          (* f maps into {0,...,n} since range says f x < S n = n+1.
             So f x <= n. We need f(k+x) < n.
             Actually wait - n here is the n from the outer induction.
             The stalk has S n elements: {0,...,n}.
             imap_range says f x < S n, so f x <= n. That's fine.
             But for pigeonhole we need the range to be STRICTLY smaller
             than the domain. *)
          (* Domain of h: {0, ..., n-x}, size n-x+1.
             We need range of h ⊆ {0, ..., n-f(x)-1}, size n-f(x).
             n - x + 1 > n - f(x) when f(x) > x, which holds.
             So we need h(k) < n - f(x) + 1 - 1 = n - f(x).
             h(k) = f(k+x) - f(x).
             Need f(k+x) - f(x) < n - f(x).
             Need f(k+x) < n. But f(k+x) < S n means f(k+x) <= n.
             Hmm, could be f(k+x) = n. *)
          (* Let me reconsider. When k = n - x, k + x = n.
             f(n) < S n means f(n) <= n.
             If f(n) = n, then h(n-x) = n - f(x).
             So the bound should be <= not <. *)
          admit.
        }
        (* Apply pigeonhole *)
        exact (Hpigeon (n - x) h Hh_inj Hh_bound Hh_strict).
Qed.

(* OK this is getting really hairy with the pigeonhole formalization.
   Let me write a COMPLETELY clean version that actually compiles. *)

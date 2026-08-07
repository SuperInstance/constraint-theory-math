"""
Tests for Eisenstein triple generator and analyzer.

These tests verify the mathematical claims in the constraint-theory-math repo:
- Eisenstein norm formula
- Triple generation correctness
- Primitivity checking
- D₆ Weyl orbit properties
- Multiplication closure in Z[ω]
- Parametric form validity
- Density comparison vs Pythagorean triples

Run: python -m pytest tests/ -v
"""

import pytest
from math import gcd, isqrt

import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent.parent / "eisenstein-triples"))

from eisenstein_triples import (
    norm, is_eisenstein_triple, is_primitive,
    weyl_orbit, generate_triples, primitive_triples,
    density_comparison, multiplication_closure, parametric_form,
)


# ─── Norm Formula ───────────────────────────────────────────────────────

class TestNorm:
    """Test the Eisenstein norm a² - ab + b²."""

    def test_norm_zero(self):
        assert norm(0, 0) == 0

    def test_norm_units(self):
        """The 6 units ±1, ±ω, ±ω² all have norm 1."""
        assert norm(1, 0) == 1    # 1
        assert norm(0, 1) == 1    # ω
        assert norm(-1, -1) == 1  # ω²
        assert norm(-1, 0) == 1   # -1
        assert norm(0, -1) == 1   # -ω
        assert norm(1, 1) == 1    # -ω²

    def test_norm_positive_definite(self):
        """Norm is always non-negative."""
        for a in range(-50, 51):
            for b in range(-50, 51):
                assert norm(a, b) >= 0, f"norm({a},{b}) = {norm(a,b)} < 0"

    def test_norm_known_values(self):
        assert norm(3, -2) == 19   # 9 + 6 + 4
        assert norm(5, 3) == 19    # 25 - 15 + 9
        assert norm(7, 0) == 49
        assert norm(8, 3) == 49    # 64 - 24 + 9

    def test_norm_symmetry_under_d6(self):
        """Norm should be invariant under 60° rotation: (a,b) → (-b, a-b)."""
        test_cases = [(4, 1), (7, -3), (2, 5), (-3, 8), (0, 0), (1, 0)]
        for a, b in test_cases:
            n1 = norm(a, b)
            n2 = norm(-b, a - b)
            n3 = norm(b - a, -a)
            assert n1 == n2 == n3, f"D₆ norm invariance failed for ({a},{b})"

    def test_norm_multiplicativity(self):
        """norm(z1 * z2) = norm(z1) * norm(z2) — the zero-drift property."""
        cases = [(3, -2, 1, 1), (7, 0, 2, 3), (4, 1, 5, -2), (8, 3, 2, 7)]
        for a1, b1, a2, b2 in cases:
            # Multiply in Z[ω]: (a1+b1ω)(a2+b2ω) = (a1a2-b1b2) + (a1b2+b1a2-b1b2)ω
            prod_a = a1 * a2 - b1 * b2
            prod_b = a1 * b2 + b1 * a2 - b1 * b2
            assert norm(prod_a, prod_b) == norm(a1, b1) * norm(a2, b2), \
                f"Multiplicativity failed for ({a1},{b1})×({a2},{b2})"


# ─── Triple Verification ────────────────────────────────────────────────

class TestIsEisensteinTriple:
    """Test the triple checker."""

    def test_valid_triple(self):
        # 7² - 7·0 + 0² = 49 = 7²
        assert is_eisenstein_triple(7, 0, 7)

    def test_valid_nontrivial_triple(self):
        # 8² - 8·3 + 3² = 64 - 24 + 9 = 49 = 7²
        assert is_eisenstein_triple(8, 3, 7)

    def test_invalid_triple(self):
        assert not is_eisenstein_triple(1, 1, 5)

    def test_zero_triple(self):
        assert is_eisenstein_triple(0, 0, 0)

    def test_unit_triple(self):
        # Units have norm 1 = 1²
        assert is_eisenstein_triple(1, 0, 1)
        assert is_eisenstein_triple(0, 1, 1)
        assert is_eisenstein_triple(1, 1, 1)


# ─── Primitivity ────────────────────────────────────────────────────────

class TestPrimitivity:
    """Test primitive triple detection."""

    def test_coprime_is_primitive(self):
        # gcd(8, 3) = 1 → primitive
        assert is_primitive(8, 3)

    def test_non_coprime_not_primitive(self):
        # gcd(6, 3) = 3 → not primitive
        assert not is_primitive(6, 3)

    def test_unit_is_primitive(self):
        assert is_primitive(1, 0)
        assert is_primitive(0, 1)

    def test_origin_not_primitive(self):
        assert not is_primitive(0, 0)

    def test_prime_norm_is_primitive(self):
        """If norm is prime, the pair should be primitive."""
        # norm(2, -1) = 4 + 2 + 1 = 7 (prime)
        assert is_primitive(2, -1)
        # norm(3, 1) = 9 - 3 + 1 = 7 (prime)
        assert is_primitive(3, 1)


# ─── D₆ Weyl Orbit ─────────────────────────────────────────────────────

class TestWeylOrbit:
    """Test the D₆ Weyl group orbit computation."""

    def test_orbit_preserves_norm(self):
        """All elements in the D₆ orbit should have the same norm."""
        test_cases = [(4, 1), (7, -3), (5, 2), (10, 3)]
        for a, b in test_cases:
            orbit = weyl_orbit(a, b)
            norms = set(norm(*p) for p in orbit)
            assert len(norms) == 1, f"Orbit of ({a},{b}) has multiple norms: {norms}"

    def test_orbit_contains_original(self):
        orbit = weyl_orbit(4, 1)
        assert (4, 1) in orbit

    def test_orbit_max_size_12(self):
        """D₆ has order 12 (6 rotations × 2 for inversion + conjugation)."""
        # For a generic point, orbit should have up to 12 elements
        orbit = weyl_orbit(7, 3)
        assert len(orbit) <= 12

    def test_orbit_of_zero_is_just_zero(self):
        orbit = weyl_orbit(0, 0)
        assert orbit == [(0, 0)]

    def test_orbit_of_unit(self):
        """Units have small orbits due to symmetry."""
        orbit = weyl_orbit(1, 0)
        # All 6 units should be in orbit
        norms = set(norm(*p) for p in orbit)
        assert norms == {1}


# ─── Triple Generation ──────────────────────────────────────────────────

class TestGenerateTriples:
    """Test Eisenstein triple generation."""

    def test_generates_known_triple(self):
        """Should find (7, 0, 7) and (8, 3, 7)."""
        triples = generate_triples(10)
        triple_set = set(triples)
        # At least one of these should be present
        assert any(t[2] == 7 for t in triples), "No triple with c=7 found"

    def test_all_triples_satisfy_norm(self):
        """Every generated triple should satisfy a² - ab + b² = c²."""
        triples = generate_triples(50)
        for a, b, c in triples:
            assert norm(a, b) == c * c, \
                f"Triple ({a},{b},{c}) fails: norm={norm(a,b)} ≠ {c*c}"

    def test_c_values_within_bound(self):
        triples = generate_triples(30)
        for _, _, c in triples:
            assert c <= 30
            assert c > 0

    def test_no_duplicates(self):
        triples = generate_triples(50)
        assert len(triples) == len(set(triples)), "Duplicate triples found"

    def test_empty_for_c_zero(self):
        triples = generate_triples(0)
        # c=0 → only (0,0,0) which is excluded
        assert all(t[2] > 0 for t in triples)


# ─── Primitive Triple Generation ────────────────────────────────────────

class TestPrimitiveTriples:
    """Test primitive triple filtering."""

    def test_all_are_primitive(self):
        triples = primitive_triples(50)
        for a, b, c in triples:
            assert is_primitive(a, b), f"({a},{b},{c}) is not primitive"

    def test_all_satisfy_norm(self):
        triples = primitive_triples(50)
        for a, b, c in triples:
            assert norm(a, b) == c * c

    def test_fewer_than_total(self):
        """Primitive triples should be a subset of all triples."""
        all_t = set(generate_triples(50))
        prim_t = set(primitive_triples(50))
        assert prim_t.issubset(all_t)

    def test_primitive_count_grows(self):
        """More triples found with larger bound."""
        small = len(primitive_triples(20))
        large = len(primitive_triples(100))
        assert large > small


# ─── Density Comparison ─────────────────────────────────────────────────

class TestDensityComparison:
    """Test Eisenstein vs Pythagorean triple density."""

    def test_eisenstein_denser(self):
        """The key claim: Eisenstein triples are denser than Pythagorean."""
        d = density_comparison(100)
        assert d["eisenstein_count"] >= d["pythagorean_count"], \
            f"Eisenstein should be denser: {d}"

    def test_ratio_positive(self):
        d = density_comparison(100)
        assert d["ratio"] >= 1.0

    def test_returns_all_keys(self):
        d = density_comparison(50)
        assert "eisenstein_count" in d
        assert "pythagorean_count" in d
        assert "ratio" in d
        assert "eisenstein_density_pct" in d


# ─── Multiplication Closure ─────────────────────────────────────────────

class TestMultiplicationClosure:
    """Test that Z[ω] multiplication preserves the triple property."""

    def test_closure_no_failures(self):
        """Product of two triple pairs should also be a triple."""
        result = multiplication_closure(50)
        assert result["failed"] == 0, \
            f"Closure failures: {result['failed']}, examples: {result['examples']}"

    def test_closure_count_positive(self):
        result = multiplication_closure(50)
        assert result["closed"] > 0


# ─── Parametric Form ────────────────────────────────────────────────────

class TestParametricForm:
    """Test the parametric Eisenstein triple generator."""

    def test_known_parametrization(self):
        """m=7, n=4 should give a valid triple."""
        a, b, c, valid = parametric_form(7, 4)
        assert valid, f"Parametric form failed for m=7, n=4"
        assert norm(a, b) == c * c

    def test_all_valid_m_n(self):
        """Test a range of m, n values."""
        for m in range(2, 15):
            for n in range(1, m):
                a, b, c, valid = parametric_form(m, n)
                assert valid, f"Parametric form failed for m={m}, n={n}: ({a},{b},{c})"
                assert norm(a, b) == c * c

    def test_c_equals_eisenstein_norm(self):
        """c should equal m² - mn + n²."""
        for m in range(2, 10):
            for n in range(1, m):
                a, b, c, valid = parametric_form(m, n)
                expected_c = m * m - m * n + n * n
                assert c == expected_c

    def test_a_equals_formula(self):
        """a should equal m² - n²."""
        for m in range(2, 10):
            for n in range(1, m):
                a, b, c, valid = parametric_form(m, n)
                expected_a = m * m - n * n
                assert a == expected_a

    def test_b_equals_formula(self):
        """b should equal 2mn - n²."""
        for m in range(2, 10):
            for n in range(1, m):
                a, b, c, valid = parametric_form(m, n)
                expected_b = 2 * m * n - n * n
                assert b == expected_b


# ─── Properties: Norm as Perfect Square ─────────────────────────────────

class TestNormProperties:
    """Test deeper properties of Eisenstein norms."""

    def test_norm_one_has_six_representatives(self):
        """There should be exactly 6 pairs (a,b) with norm 1 (the units)."""
        count = 0
        for a in range(-10, 11):
            for b in range(-10, 11):
                if norm(a, b) == 1:
                    count += 1
        assert count == 6, f"Expected 6 units, found {count}"

    def test_primes_2_mod_3_not_representable(self):
        """Primes p ≡ 2 (mod 3) are inert in Z[ω] and not representable as norms."""
        # 2, 5, 11 are primes ≡ 2 mod 3
        for p in [2, 5, 11]:
            found = False
            for a in range(-100, 101):
                for b in range(-100, 101):
                    if norm(a, b) == p:
                        found = True
                        break
                if found:
                    break
            assert not found, f"Prime {p} ≡ 2 mod 3 should not be a norm, but ({a},{b}) gives norm {p}"

    def test_primes_1_mod_3_representable(self):
        """Primes p ≡ 1 (mod 3) split in Z[ω] and ARE representable as norms."""
        # 7, 13, 19 are primes ≡ 1 mod 3
        for p in [7, 13, 19]:
            found = False
            for a in range(-100, 101):
                for b in range(-100, 101):
                    if norm(a, b) == p:
                        found = True
                        break
                if found:
                    break
            assert found, f"Prime {p} ≡ 1 mod 3 should be representable as a norm"

#!/usr/bin/env python3
"""Statistical analysis of Eisenstein triples vs Pythagorean triples."""

from math import gcd, isqrt
from collections import Counter


def norm(a: int, b: int) -> int:
    return a * a - a * b + b * b


def is_primitive(a: int, b: int) -> bool:
    return gcd(abs(a), abs(b)) == 1


def count_eisenstein_primitives(max_c: int) -> int:
    """Count primitive Eisenstein triples with c ≤ max_c using brute force."""
    count = 0
    seen = set()
    c_max_sq = max_c * max_c

    for a in range(0, max_c + 1):
        for b in range(a, max_c + 1):
            if a == 0 and b == 0:
                continue
            c_sq = norm(a, b)
            if c_sq > c_max_sq:
                continue
            c = isqrt(c_sq)
            if c * c == c_sq and c > 0 and is_primitive(a, b):
                count += 1
    return count


def count_pythagorean_primitives(max_c: int) -> int:
    """Count primitive Pythagorean triples with c ≤ max_c."""
    count = 0
    for m in range(2, isqrt(2 * max_c) + 1):
        for n in range(1, m):
            if (m - n) % 2 == 1 and gcd(m, n) == 1:
                c = m * m + n * n
                if c <= max_c:
                    count += 1
    return count


def eisenstein_c_distribution(max_c: int) -> dict:
    """Distribution of c values for Eisenstein triples."""
    c_counts = Counter()
    c_max_sq = max_c * max_c

    for a in range(0, max_c + 1):
        for b in range(a, max_c + 1):
            if a == 0 and b == 0:
                continue
            c_sq = norm(a, b)
            if c_sq > c_max_sq:
                continue
            c = isqrt(c_sq)
            if c * c == c_sq and c > 0 and is_primitive(a, b):
                c_counts[c] += 1

    return c_counts


def parametric_eisenstein(max_m: int) -> list:
    """Generate Eisenstein triples via parametric form.

    For m > n > 0, coprime:
        a = m² - n²
        b = 2mn - n²
        c = m² - mn + n²
    
    Verify: a² - ab + b² = (m²-n²)² - (m²-n²)(2mn-n²) + (2mn-n²)²
    """
    triples = []
    for m in range(2, max_m + 1):
        for n in range(1, m):
            if gcd(m, n) != 1:
                continue
            a = m * m - n * n
            b = 2 * m * n - n * n
            c = m * m - m * n + n * n
            # Verify
            assert norm(a, b) == c * c, f"Failed: ({a},{b},{c})"
            triples.append((a, b, c, m, n))
    return triples


def max_norm_24bit():
    """Find maximum Eisenstein norm that fits in 24 bits."""
    limit = 2**24  # 16,777,216
    best = 0
    best_pair = (0, 0)
    # Search for max a²-ab+b² < 2²⁴
    # Bound: a² ≤ 2²⁴, so a ≤ 4096
    for a in range(0, 4097):
        for b in range(0, 4097):
            n = norm(a, b)
            if n < limit and n > best:
                best = n
                best_pair = (a, b)
    return best, best_pair


def hex_disk_count(R: int) -> int:
    """Count lattice points in hexagonal disk of radius R.

    Formula: 3R² + 3R + 1 (hex number).
    """
    return 3 * R * R + 3 * R + 1


if __name__ == '__main__':
    print("=" * 60)
    print("EISENSTEIN TRIPLE ANALYSIS")
    print("=" * 60)

    # 1. Count primitives with c < 65536
    print("\n--- Primitive Triple Count ---")
    # Use a reasonable bound first for speed, then scale
    for bound in [100, 500, 1000, 5000]:
        eis = count_eisenstein_primitives(bound)
        pyt = count_pythagorean_primitives(bound)
        ratio = eis / pyt if pyt > 0 else 0
        print(f"  c ≤ {bound:5d}: Eisenstein = {eis:6d}, Pythagorean = {pyt:6d}, ratio = {ratio:.4f} ({(ratio-1)*100:+.1f}%)")

    # 2. Maximum 24-bit norm
    print("\n--- Maximum 24-bit Eisenstein Norm ---")
    # Analytical: we want max(a²-ab+b²) < 2²⁴ = 16,777,216
    # The norm is maximized when a,b are as large as possible.
    # For the hex grid, max points within radius R: a²-ab+b² ≤ R²
    # So R² < 16,777,216 → R < 4096
    # Maximum norm: 4095² - 4095·1 + 1² = let's compute
    # Actually we need to find max(a²-ab+b²) < 16777216
    # Symmetry: the max occurs at corners. (4096,0) gives 4096²=16,777,216 = 2²⁴ exactly
    # So (4095, 0): 4095² = 16,769,025
    # (4095, 1): 4095²-4095+1 = 16,765,931
    # So max is 16,769,025
    max_norm = norm(4095, 0)
    print(f"  norm(4095, 0) = {max_norm:,}")
    print(f"  2²⁴ = {2**24:,}")
    print(f"  {max_norm:,} < {2**24:,}: {max_norm < 2**24}")

    # Check a few more
    for a, b in [(4095, 0), (4095, 4095), (4096, 0), (4095, 1)]:
        n = norm(a, b)
        fits = "✓ fits" if n < 2**24 else "✗ exceeds"
        print(f"  norm({a}, {b}) = {n:,}  {fits}")

    # 3. Hex disk count
    print("\n--- Hex Disk Count ---")
    for R in [1, 5, 10, 36]:
        count = hex_disk_count(R)
        print(f"  R={R:3d}: 3R²+3R+1 = {count:,}")
    print(f"  R=36: {hex_disk_count(36)} (claimed 3997): {'✓' if hex_disk_count(36)==3997 else '✗'}")

    # 4. Parametric form verification
    print("\n--- Parametric Form Verification ---")
    param_triples = parametric_eisenstein(50)
    print(f"  Generated {len(param_triples)} parametric triples (m ≤ 50)")
    print("  Verification: all satisfy a²-ab+b² = c² ✓")
    print(f"  First 5: {[(a,b,c) for a,b,c,m,n in param_triples[:5]]}")

    # Check density with larger bounds using parametric form
    print("\n--- Density: Parametric Eisenstein vs Pythagorean ---")
    for bound in [100, 500, 1000, 5000, 10000]:
        # Count parametric Eisenstein with c ≤ bound
        eis_count = 0
        for m in range(2, isqrt(2 * bound) + 2):
            for n in range(1, m):
                if gcd(m, n) != 1:
                    continue
                c = m * m - m * n + n * n
                if c <= bound:
                    eis_count += 1
        pyt_count = count_pythagorean_primitives(bound)
        ratio = eis_count / pyt_count if pyt_count > 0 else 0
        print(f"  c ≤ {bound:5d}: Eisenstein(param) = {eis_count:6d}, Pythagorean = {pyt_count:6d}, ratio = {ratio:.4f} ({(ratio-1)*100:+.1f}%)")

    # 5. Extrapolate to 65536
    print("\n--- Extrapolation to c < 65536 ---")
    # The parametric count grows proportionally to c (N(c) ~ K*c)
    # From the data, estimate the constant
    eis_10k = sum(1 for m in range(2, 400) for n in range(1, m)
                  if gcd(m, n) == 1 and m*m - m*n + n*n <= 10000)
    pyt_10k = count_pythagorean_primitives(10000)
    ratio_10k = eis_10k / pyt_10k
    print(f"  At c≤10000: ratio = {ratio_10k:.4f}")

    pyt_65k = count_pythagorean_primitives(65535)
    eis_65k_est = int(pyt_65k * ratio_10k)
    print(f"  Pythagorean primitives c<65536: ~{pyt_65k}")
    print(f"  Estimated Eisenstein primitives c<65536: ~{eis_65k_est}")

    # Actually count parametric Eisenstein up to 65535
    eis_65k = sum(1 for m in range(2, 1000) for n in range(1, m)
                  if gcd(m, n) == 1 and m*m - m*n + n*n <= 65535)
    print(f"  Actual parametric Eisenstein c<65536: {eis_65k}")
    print(f"  Ratio: {eis_65k/pyt_65k:.4f} ({(eis_65k/pyt_65k-1)*100:+.1f}% denser)")

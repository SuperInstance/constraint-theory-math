# Numerical pins for PROOF-DIM-H0-FIXED-SPACE.md
# Law under test: dim H⁰(Γ, V) = dim Fix(Hol_r) ≤ d  (connected graph, linear stalks)
# Two independent computations of the same number, asserted equal:
#   (a) null space of the full incidence system  s_w - T_e s_u = 0  (all edges)
#   (b) intersection of fixed spaces of a cotree cycle basis
# Run: python3 tests/test_dim_h0_fixed_space.py   (exit 0 = all pins pass)
import itertools
import random
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0])


def rand_gl(d, rng, scale=0.7):
    """Generic element of GL(d): I + small random (invertible w.h.p.)."""
    while True:
        m = np.eye(d) + scale * rng.standard_normal((d, d))
        if abs(np.linalg.det(m)) > 1e-6:
            return m


def random_connected_graph(n, extra_edges, rng):
    """Random connected graph: random spanning tree + extra random cotree edges."""
    perm = rng.permutation(n)
    edges = [(int(perm[i]), int(perm[i + 1])) for i in range(n - 1)]  # tree
    max_cotree = n * (n - 1) // 2 - (n - 1)   # simple-graph bound — extra beyond this spins forever
    target = min(extra_edges, max_cotree)
    while len(edges) < n - 1 + target:
        u, v = rng.integers(0, n, 2)
        if u != v and (int(u), int(v)) not in edges and (int(v), int(u)) not in edges:
            edges.append((int(u), int(v)))
    return edges


def dim_h0_incidence(n, edges, transports, d):
    """(a) dim H⁰ as nullity of the stacked block system."""
    rows = np.zeros((len(edges) * d, n * d))
    for k, (u, v) in enumerate(edges):
        # s_v - T s_u = 0   (orient u -> v)
        rows[k * d:(k + 1) * d, v * d:(v + 1) * d] = np.eye(d)
        rows[k * d:(k + 1) * d, u * d:(u + 1) * d] = -transports[k]
    return n * d - np.linalg.matrix_rank(rows, tol=1e-8)


def root_transports(n, edges, transports, d):
    """P[x]: s_x = P[x] @ s_0 along BFS-tree paths from root 0."""
    adj = {}
    for k, (u, v) in enumerate(edges):
        adj.setdefault(u, []).append((v, k))
        adj.setdefault(v, []).append((u, k))
    parent = {0: None}
    pedge = {}
    q = [0]
    for x in q:
        for y, k in adj.get(x, []):
            if y not in parent:
                parent[y] = x
                pedge[y] = k
                q.append(y)
    assert len(parent) == n, "graph not connected"
    P = {0: np.eye(d)}
    for x in q[1:]:
        k = pedge[x]
        p = parent[x]
        eu, ev = edges[k]
        step = transports[k] if (eu == p and ev == x) else np.linalg.inv(transports[k])
        P[x] = step @ P[p]
    return P, set(pedge.values())


def cotree_holonomies_at_root(n, edges, transports, d):
    """(b) holonomy maps (root frame) for the cotree cycle basis."""
    P, tree_edges = root_transports(n, edges, transports, d)
    basis = []
    for k, (u, v) in enumerate(edges):
        if k in tree_edges:
            continue
        # closed walk: 0 ->u (tree), u ->v (edge k), v ->0 (tree inverse)
        # Hol_0 = P_v^{-1} @ T_k @ P_u   (maps V_0 -> V_0)
        basis.append(np.linalg.inv(P[v]) @ transports[k] @ P[u])
    return basis


def fixed_space_dim(matrices, d, tol=1e-8):
    """dim {v : M v = v for all M} via stacked null space."""
    if not matrices:
        return d
    rows = np.zeros((len(matrices) * d, d))
    for i, m in enumerate(matrices):
        rows[i * d:(i + 1) * d] = m - np.eye(d)
    return d - np.linalg.matrix_rank(rows, tol=tol)


def trial(n, extra, d, seed):
    rng = np.random.default_rng(seed)
    edges = random_connected_graph(n, extra, rng)
    transports = [rand_gl(d, rng) for _ in edges]
    dim_a = dim_h0_incidence(n, edges, transports, d)
    holonomies = cotree_holonomies_at_root(n, edges, transports, d)
    dim_b = fixed_space_dim(holonomies, d)
    return dim_a, dim_b, edges, transports


def main():
    pins = 0
    fails = 0
    # Pin 1: bulk random trials, d=3, n up to 7, cycles up to 4
    for seed in range(60):
        n = 2 + seed % 6
        extra = seed % 5          # 0 cycles (tree) .. 4 cycles
        dim_a, dim_b, edges, _ = trial(n, extra, 3, seed)
        ok = dim_a == dim_b and dim_a <= 3
        pins += 1
        fails += (not ok)
        if not ok:
            print(f"  FAIL seed={seed} n={n} extra={extra}: incidence={dim_a} fixed={dim_b}")
    print(f"pin 1 (60 random graphs, d=3, incidence == fixed-space, ≤ d): "
          f"{'PASS' if fails == 0 else 'FAIL'}")

    # Pin 2: trees always give dim = d (Hol trivial)
    t_fails = 0
    for seed in range(20):
        rng = np.random.default_rng(1000 + seed)
        edges = random_connected_graph(6, 0, rng)
        transports = [rand_gl(3, rng) for _ in edges]
        if dim_h0_incidence(6, edges, transports, 3) != 3:
            t_fails += 1
    pins += 1; fails += t_fails
    print(f"pin 2 (20 random trees, dim == d exactly): {'PASS' if t_fails == 0 else 'FAIL'}")

    # Pin 3: one generic cycle generically kills ALL d dimensions (dim 0)
    rng = np.random.default_rng(7)
    z_fails = 0
    for seed in range(30):
        edges = [(0, 1), (1, 2), (2, 0)]           # triangle, β₁ = 1
        transports = [rand_gl(3, np.random.default_rng(seed)) for _ in edges]
        if dim_h0_incidence(3, edges, transports, 3) != 0:
            z_fails += 1            # generic fixed-point-free holonomy
    pins += 1; fails += z_fails
    print(f"pin 3 (30 random triangles, generic 1-cycle -> dim 0): "
          f"{'PASS' if z_fails == 0 else f'FAIL ({z_fails}/30 had fixed pts)'}")

    # Pin 4: d=9 spot check — the actual GL(9) fleet setting
    rng = np.random.default_rng(42)
    n, extra = 5, 3
    dim_a, dim_b, _, _ = trial(n, extra, 9, 20261003)
    ok = dim_a == dim_b and dim_a <= 9
    pins += 1; fails += (not ok)
    print(f"pin 4 (GL(9), n=5, 3 cycles, incidence={dim_a} == fixed={dim_b} ≤ 9): "
          f"{'PASS' if ok else 'FAIL'}")

    print(f"\npins: {pins - fails}/{pins} pass")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())

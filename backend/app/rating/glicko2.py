"""Pure Glicko-2 update.

Implements Glickman's algorithm exactly as described in
http://www.glicko.net/glicko/glicko2.pdf .

Inputs/outputs are on the standard Glicko-2 scale (1500 mean, 350 max RD).
Convert to/from display scale at the boundary.
"""
from __future__ import annotations
import math
from dataclasses import dataclass

GLICKO2_CONST = 173.7178


@dataclass(frozen=True)
class Rating:
    rating: float
    rd: float
    volatility: float


def _g(phi: float) -> float:
    return 1.0 / math.sqrt(1.0 + 3.0 * phi * phi / (math.pi * math.pi))


def _e(mu: float, mu_j: float, phi_j: float) -> float:
    return 1.0 / (1.0 + math.exp(-_g(phi_j) * (mu - mu_j)))


def update(
    player: Rating,
    opponents: list[Rating],
    scores: list[float],
    tau: float = 0.5,
    epsilon: float = 1e-6,
) -> Rating:
    if len(opponents) != len(scores):
        raise ValueError("opponents and scores must be the same length")

    mu = (player.rating - 1500.0) / GLICKO2_CONST
    phi = player.rd / GLICKO2_CONST
    sigma = player.volatility

    if not opponents:
        phi_star = math.sqrt(phi * phi + sigma * sigma)
        new_rd = phi_star * GLICKO2_CONST
        return Rating(player.rating, new_rd, sigma)

    mu_js = [(o.rating - 1500.0) / GLICKO2_CONST for o in opponents]
    phi_js = [o.rd / GLICKO2_CONST for o in opponents]

    v_inv = 0.0
    delta_sum = 0.0
    for mu_j, phi_j, s in zip(mu_js, phi_js, scores, strict=True):
        g = _g(phi_j)
        e = _e(mu, mu_j, phi_j)
        v_inv += g * g * e * (1.0 - e)
        delta_sum += g * (s - e)
    v = 1.0 / v_inv
    delta = v * delta_sum

    a = math.log(sigma * sigma)

    def f(x: float) -> float:
        ex = math.exp(x)
        num = ex * (delta * delta - phi * phi - v - ex)
        den = 2.0 * (phi * phi + v + ex) ** 2
        return num / den - (x - a) / (tau * tau)

    A = a
    if delta * delta > phi * phi + v:
        B = math.log(delta * delta - phi * phi - v)
    else:
        k = 1
        while f(a - k * tau) < 0:
            k += 1
        B = a - k * tau

    fA = f(A)
    fB = f(B)
    while abs(B - A) > epsilon:
        C = A + (A - B) * fA / (fB - fA)
        fC = f(C)
        if fC * fB <= 0:
            A, fA = B, fB
        else:
            fA = fA / 2.0
        B, fB = C, fC

    new_sigma = math.exp(A / 2.0)
    phi_star = math.sqrt(phi * phi + new_sigma * new_sigma)
    new_phi = 1.0 / math.sqrt(1.0 / (phi_star * phi_star) + 1.0 / v)
    new_mu = mu + new_phi * new_phi * delta_sum

    return Rating(
        rating=new_mu * GLICKO2_CONST + 1500.0,
        rd=new_phi * GLICKO2_CONST,
        volatility=new_sigma,
    )

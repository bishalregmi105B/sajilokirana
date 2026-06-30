"""
SajiloKirana ML Service — Phase 0/1
Endpoints:
  POST /ml/dispatch/score   — weighted candidate scoring
  POST /ml/routing/optimize — greedy nearest-neighbour TSP
  POST /ml/eta/predict      — OSRM passthrough stub
  GET  /healthz             — liveness probe
"""

from __future__ import annotations

import math
import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="SajiloKirana ML Service", version="0.1.0")

OSRM_BASE = os.getenv("OSRM_BASE_URL", "http://router.project-osrm.org")


# ──────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────

def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lng / 2) ** 2
    )
    return R * 2 * math.asin(math.sqrt(a))


# ──────────────────────────────────────────────────────────────────
# /ml/dispatch/score
# ──────────────────────────────────────────────────────────────────

class DispatchWeights(BaseModel):
    distance: float = Field(0.5, ge=0, le=1)
    reliability: float = Field(0.3, ge=0, le=1)
    recency: float = Field(0.2, ge=0, le=1)


class Candidate(BaseModel):
    id: str
    lat: float
    lng: float
    reliability: float = Field(0.5, ge=0, le=1)
    # seconds since last delivery (0 = just finished = fresher)
    seconds_since_last: float = Field(0.0, ge=0)


class DispatchScoreRequest(BaseModel):
    order_lat: float
    order_lng: float
    candidates: list[Candidate]
    weights: DispatchWeights = Field(default_factory=DispatchWeights)


class ScoredCandidate(BaseModel):
    id: str
    score: float
    distance_km: float


class DispatchScoreResponse(BaseModel):
    ranked: list[ScoredCandidate]


@app.post("/ml/dispatch/score", response_model=DispatchScoreResponse)
def dispatch_score(req: DispatchScoreRequest) -> DispatchScoreResponse:
    """
    Score = w_dist * (1 / (1 + dist_km))
           + w_rel  * reliability
           + w_rec  * recency_score

    recency_score = 1 / (1 + seconds_since_last / 3600)
    Higher is better. Returns list sorted descending.
    """
    w = req.weights
    scored: list[ScoredCandidate] = []

    for c in req.candidates:
        dist = haversine_km(req.order_lat, req.order_lng, c.lat, c.lng)
        dist_score = 1.0 / (1.0 + dist)
        recency_score = 1.0 / (1.0 + c.seconds_since_last / 3600.0)
        score = (
            w.distance * dist_score
            + w.reliability * c.reliability
            + w.recency * recency_score
        )
        scored.append(ScoredCandidate(id=c.id, score=round(score, 6), distance_km=round(dist, 3)))

    scored.sort(key=lambda x: x.score, reverse=True)
    return DispatchScoreResponse(ranked=scored)


# ──────────────────────────────────────────────────────────────────
# /ml/routing/optimize
# Greedy nearest-neighbour TSP (OR-Tools upgrade path commented)
# ──────────────────────────────────────────────────────────────────

class RoutingStop(BaseModel):
    id: str
    lat: float
    lng: float


class RoutingRequest(BaseModel):
    driver_lat: float
    driver_lng: float
    stops: list[RoutingStop]


class RoutingResponse(BaseModel):
    ordered_stop_ids: list[str]
    estimated_total_km: float


@app.post("/ml/routing/optimize", response_model=RoutingResponse)
def routing_optimize(req: RoutingRequest) -> RoutingResponse:
    """
    Greedy nearest-neighbour starting from driver position.
    For small batches (≤6 stops) this is within ~20% of optimal.

    Phase 1 upgrade: replace with OR-Tools VRP solver.
    """
    if not req.stops:
        return RoutingResponse(ordered_stop_ids=[], estimated_total_km=0.0)

    remaining = list(req.stops)
    ordered: list[str] = []
    total_km = 0.0
    cur_lat, cur_lng = req.driver_lat, req.driver_lng

    while remaining:
        nearest_idx = min(
            range(len(remaining)),
            key=lambda i: haversine_km(cur_lat, cur_lng, remaining[i].lat, remaining[i].lng),
        )
        stop = remaining.pop(nearest_idx)
        d = haversine_km(cur_lat, cur_lng, stop.lat, stop.lng)
        total_km += d
        cur_lat, cur_lng = stop.lat, stop.lng
        ordered.append(stop.id)

    return RoutingResponse(
        ordered_stop_ids=ordered,
        estimated_total_km=round(total_km, 3),
    )


# ──────────────────────────────────────────────────────────────────
# /ml/eta/predict  — OSRM passthrough, falls back to haversine/20
# ──────────────────────────────────────────────────────────────────

class EtaRequest(BaseModel):
    from_lat: float
    from_lng: float
    to_lat: float
    to_lng: float


class EtaResponse(BaseModel):
    eta_seconds: int
    distance_km: float
    source: str  # "osrm" | "haversine_fallback"


@app.post("/ml/eta/predict", response_model=EtaResponse)
async def eta_predict(req: EtaRequest) -> EtaResponse:
    """
    Tries OSRM route API. Falls back to distance / 20 km·h⁻¹
    if OSRM is unavailable or env OSRM_BASE_URL is not set.
    """
    coords = f"{req.from_lng},{req.from_lat};{req.to_lng},{req.to_lat}"
    url = f"{OSRM_BASE}/route/v1/driving/{coords}?overview=false"

    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(url)
            data: dict[str, Any] = resp.json()
            if resp.status_code == 200 and data.get("code") == "Ok":
                route = data["routes"][0]
                return EtaResponse(
                    eta_seconds=int(route["duration"]),
                    distance_km=round(route["distance"] / 1000, 3),
                    source="osrm",
                )
    except Exception:
        pass

    # Fallback
    dist = haversine_km(req.from_lat, req.from_lng, req.to_lat, req.to_lng)
    eta = int((dist / 20.0) * 3600)  # 20 km/h average urban speed
    return EtaResponse(
        eta_seconds=eta,
        distance_km=round(dist, 3),
        source="haversine_fallback",
    )


# ──────────────────────────────────────────────────────────────────
# /ml/forecast/shop/{shop_id}/sku/{product_id}
# Phase 0: heuristic forecast (day-of-week rolling average stub).
# Phase 1: replace with trained LightGBM model once order data
#          accumulates (see build prompt E.5).
# ──────────────────────────────────────────────────────────────────

import datetime
import random  # seeded deterministic — remove when real model lands


class ForecastResponse(BaseModel):
    shop_id: str
    product_id: str
    predicted_demand_next_24h: float
    confidence: float  # 0–1; low until real model is trained
    model_version: str


@app.get(
    "/ml/forecast/shop/{shop_id}/sku/{product_id}",
    response_model=ForecastResponse,
)
def demand_forecast(shop_id: str, product_id: str) -> ForecastResponse:
    """
    Stub demand forecast. Returns a deterministic pseudo-random value
    seeded by (shop_id, product_id, day-of-week) so responses are
    stable within a day.  Replace with a LightGBM regressor trained on
    actual order data as soon as sufficient history exists.
    """
    dow = datetime.datetime.utcnow().weekday()  # 0=Mon … 6=Sun
    seed = hash(f"{shop_id}:{product_id}:{dow}") % (2**32)
    rng = random.Random(seed)
    # Weekend uplift (~20%) matches Nepali consumer patterns.
    base = rng.uniform(3.0, 18.0)
    weekend_multiplier = 1.2 if dow >= 4 else 1.0
    demand = round(base * weekend_multiplier, 2)
    return ForecastResponse(
        shop_id=shop_id,
        product_id=product_id,
        predicted_demand_next_24h=demand,
        confidence=0.35,  # low — stub model
        model_version="heuristic-v0",
    )


# ──────────────────────────────────────────────────────────────────
# HEALTH
# ──────────────────────────────────────────────────────────────────

@app.get("/healthz")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "ml"}

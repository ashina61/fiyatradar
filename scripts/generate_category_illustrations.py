"""Generate FiyatRadar brand-agnostic category illustrations as optimized SVGs.

Run from repo root:
    python3 scripts/generate_category_illustrations.py

Outputs:
    assets/illustrations/*.svg
    assets/illustrations/manifest.json

Hard rules baked into this generator:
    - All illustrations use viewBox 0 0 140 220.
    - Palette is locked to the FiyatRadar cream / espresso / amber DNA.
    - No text, no brand colors, no trade-dress mimicry.
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Callable, Iterable

# ---------------------------------------------------------------------------
# Palette (DNA — do not extend without product sign-off)
# ---------------------------------------------------------------------------

CREAM = "#EDEAE3"
CREAM_2 = "#E3DFD6"
CREAM_3 = "#D6D0C3"
ESPRESSO = "#18100A"
ESPRESSO_2 = "#2A1C12"
ESPRESSO_3 = "#3D2A1C"
AMBER = "#BF9470"
AMBER_SOFT = "#D9B998"
AMBER_DEEP = "#8A6B4A"
MUTED = "#6B5A4A"

LEAF = "#6B8E5A"
LEAF_DEEP = "#4A6B3A"
LEAF_SOFT = "#9DB88B"
TOMATO = "#B85A3D"
TOMATO_DEEP = "#8E3F26"
BANANA = "#D4A84A"
BANANA_DEEP = "#A57E2A"
BREAD = "#A8754A"
BREAD_DEEP = "#7A5230"
MILK = "#F5F1E8"
EGGSHELL = "#F0E6D2"

CAP_RIM = "#A89279"
CAP_EDGE = "#8A7560"

SHADOW = "#000000"

HEADER = '<!-- FiyatRadar category illustration | brand-agnostic | DO NOT add brand-specific elements -->'

# ---------------------------------------------------------------------------
# Output paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = REPO_ROOT / "assets" / "illustrations"
MANIFEST_PATH = OUT_DIR / "manifest.json"


# ---------------------------------------------------------------------------
# SVG primitives
# ---------------------------------------------------------------------------


def svg(body: str, *, defs: str = "") -> str:
    """Wrap raw body markup in a 140x220 SVG with the brand-agnostic comment."""
    defs_block = f"<defs>{defs}</defs>" if defs else ""
    return (
        f'{HEADER}\n'
        f'<svg viewBox="0 0 140 220" xmlns="http://www.w3.org/2000/svg">'
        f"{defs_block}{body}</svg>"
    )


def shadow(cx: float = 70, cy: float = 204, rx: float = 30, ry: float = 4, opacity: float = 0.14) -> str:
    return (
        f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" '
        f'fill="{SHADOW}" opacity="{opacity}"/>'
    )


def gradient(gid: str, c1: str, c2: str, c3: str | None = None, vertical: bool = False) -> str:
    coord = 'x1="0" x2="0" y1="0" y2="1"' if vertical else 'x1="0" x2="1"'
    stops = (
        f'<stop offset="0%" stop-color="{c1}"/>'
        f'<stop offset="50%" stop-color="{c3 or c2}"/>'
        f'<stop offset="100%" stop-color="{c2}"/>'
    )
    return f'<linearGradient id="{gid}" {coord}>{stops}</linearGradient>'


# ---------------------------------------------------------------------------
# Reusable component builders
# ---------------------------------------------------------------------------


def bottle(
    *,
    body_fill: str,
    cap_color: str = CAP_RIM,
    cap_edge: str = CAP_EDGE,
    cap_height: int = 8,
    label_color: str | None = AMBER,
    label_y: int = 80,
    label_h: int = 56,
    label_extras: str = "",
    body_top: int = 36,
    body_bottom: int = 192,
    body_w: int = 66,
    shoulder: int = 8,
    neck_w: int = 26,
    neck_h: int = 6,
    body_radius_bottom: int = 8,
) -> str:
    """Cylindrical bottle with cap, shoulder, body, and optional label band."""
    cx = 70
    cap_top = body_top - cap_height - 2
    neck_top = cap_top + cap_height
    body_left = cx - body_w // 2
    body_right = cx + body_w // 2
    shoulder_top = body_top
    body_main_top = body_top + shoulder
    body_bot = body_bottom
    parts: list[str] = []
    # Cap
    parts.append(
        f'<rect x="{cx - neck_w // 2}" y="{cap_top}" width="{neck_w}" height="{cap_height}" '
        f'rx="2" fill="{cap_color}"/>'
    )
    parts.append(
        f'<rect x="{cx - neck_w // 2}" y="{cap_top + cap_height - 2}" width="{neck_w}" height="2" '
        f'fill="{cap_edge}"/>'
    )
    # Neck shoulder
    parts.append(
        f'<path d="M{cx - neck_w // 2} {neck_top} '
        f'L{cx - neck_w // 2} {neck_top + neck_h} '
        f'L{body_left} {body_main_top} '
        f'L{body_right} {body_main_top} '
        f'L{cx + neck_w // 2} {neck_top + neck_h} '
        f'L{cx + neck_w // 2} {neck_top} Z" '
        f'fill="{body_fill}"/>'
    )
    # Body
    parts.append(
        f'<path d="M{body_left} {body_main_top} '
        f'L{body_right} {body_main_top} '
        f'L{body_right} {body_bot - body_radius_bottom} '
        f'Q{body_right} {body_bot} {body_right - body_radius_bottom} {body_bot} '
        f'L{body_left + body_radius_bottom} {body_bot} '
        f'Q{body_left} {body_bot} {body_left} {body_bot - body_radius_bottom} Z" '
        f'fill="{body_fill}"/>'
    )
    # Label
    if label_color:
        parts.append(
            f'<rect x="{body_left + 2}" y="{label_y}" width="{body_w - 4}" '
            f'height="{label_h}" fill="{label_color}"/>'
        )
        parts.append(label_extras)
    return "".join(parts)


def jar(
    *,
    content_color: str,
    lid_color: str = AMBER,
    lid_edge: str = AMBER_DEEP,
    glass_tint: str | None = None,
    body_w: int = 76,
    body_top: int = 70,
    body_bottom: int = 192,
    lid_h: int = 18,
    content_extras: str = "",
    rim_color: str = AMBER_DEEP,
) -> str:
    cx = 70
    body_left = cx - body_w // 2
    body_right = cx + body_w // 2
    lid_top = body_top - lid_h
    parts: list[str] = []
    # Lid
    parts.append(
        f'<rect x="{body_left + 2}" y="{lid_top}" width="{body_w - 4}" '
        f'height="{lid_h}" rx="3" fill="{lid_color}"/>'
    )
    parts.append(
        f'<rect x="{body_left + 2}" y="{lid_top + lid_h - 3}" width="{body_w - 4}" '
        f'height="3" fill="{lid_edge}"/>'
    )
    # Rim
    parts.append(
        f'<rect x="{body_left}" y="{body_top}" width="{body_w}" height="5" '
        f'fill="{rim_color}"/>'
    )
    # Glass + contents
    parts.append(
        f'<rect x="{body_left}" y="{body_top + 5}" width="{body_w}" '
        f'height="{body_bottom - body_top - 5}" rx="6" '
        f'fill="{glass_tint or content_color}"/>'
    )
    if glass_tint:
        # inset content area
        inset = 6
        parts.append(
            f'<rect x="{body_left + inset}" y="{body_top + 5 + inset}" '
            f'width="{body_w - inset * 2}" height="{body_bottom - body_top - 5 - inset * 2}" '
            f'rx="4" fill="{content_color}"/>'
        )
    parts.append(content_extras)
    return "".join(parts)


def paper_pack(
    *,
    pack_color: str = CREAM_2,
    accent_color: str = AMBER,
    body_w: int = 70,
    body_top: int = 32,
    body_bottom: int = 196,
    window: str | None = None,
    window_extras: str = "",
    pinch_top: bool = False,
    accent_band_y: int | None = None,
    accent_band_h: int = 10,
) -> str:
    cx = 70
    left = cx - body_w // 2
    right = cx + body_w // 2
    parts: list[str] = []
    if pinch_top:
        # Sealed crimped top — flour-sack style
        parts.append(
            f'<path d="M{left} {body_top + 8} '
            f'Q{cx - 8} {body_top - 2} {cx} {body_top + 4} '
            f'Q{cx + 8} {body_top - 2} {right} {body_top + 8} '
            f'L{right} {body_bottom} L{left} {body_bottom} Z" '
            f'fill="{pack_color}"/>'
        )
        parts.append(
            f'<path d="M{left + 4} {body_top + 8} L{right - 4} {body_top + 8}" '
            f'stroke="{AMBER_DEEP}" stroke-width="1.2" opacity="0.55"/>'
        )
    else:
        parts.append(
            f'<rect x="{left}" y="{body_top}" width="{body_w}" '
            f'height="{body_bottom - body_top}" rx="4" fill="{pack_color}"/>'
        )
    if accent_band_y is not None:
        parts.append(
            f'<rect x="{left}" y="{accent_band_y}" width="{body_w}" '
            f'height="{accent_band_h}" fill="{accent_color}"/>'
        )
    if window:
        wx, wy, ww, wh = (int(v) for v in window.split(","))
        parts.append(
            f'<rect x="{wx}" y="{wy}" width="{ww}" height="{wh}" rx="3" fill="{MILK}"/>'
        )
        parts.append(window_extras)
    return "".join(parts)


def carton_box(
    *,
    body_color: str = CREAM_2,
    accent_color: str = AMBER,
    body_w: int = 80,
    body_top: int = 40,
    body_bottom: int = 196,
    flap: bool = True,
    accent_band_y: int | None = None,
    accent_band_h: int = 10,
    extras: str = "",
) -> str:
    cx = 70
    left = cx - body_w // 2
    right = cx + body_w // 2
    parts: list[str] = []
    if flap:
        # Slight top trapezoidal flap
        parts.append(
            f'<path d="M{left + 4} {body_top - 6} L{right - 4} {body_top - 6} '
            f'L{right - 2} {body_top + 4} L{left + 2} {body_top + 4} Z" '
            f'fill="{darken(body_color)}"/>'
        )
    parts.append(
        f'<rect x="{left}" y="{body_top}" width="{body_w}" '
        f'height="{body_bottom - body_top}" rx="3" fill="{body_color}"/>'
    )
    if accent_band_y is not None:
        parts.append(
            f'<rect x="{left}" y="{accent_band_y}" width="{body_w}" '
            f'height="{accent_band_h}" fill="{accent_color}"/>'
        )
    parts.append(extras)
    return "".join(parts)


def darken(hex_color: str) -> str:
    """Quick darken for shadow flap / edge."""
    table = {
        CREAM: "#D8D3C8",
        CREAM_2: "#C9C2B4",
        CREAM_3: "#B5AE9D",
        AMBER: AMBER_DEEP,
        AMBER_SOFT: AMBER,
        ESPRESSO: "#0A0604",
        ESPRESSO_2: ESPRESSO,
        ESPRESSO_3: ESPRESSO_2,
        MILK: CREAM_2,
        EGGSHELL: "#D8C9A8",
        LEAF: LEAF_DEEP,
        LEAF_SOFT: LEAF,
        BANANA: BANANA_DEEP,
        BREAD: BREAD_DEEP,
        TOMATO: TOMATO_DEEP,
    }
    return table.get(hex_color, ESPRESSO_2)


# ---------------------------------------------------------------------------
# Family-specific composers
# ---------------------------------------------------------------------------


def soda_can() -> str:
    defs = gradient("g_soda", "#0E0805", ESPRESSO, "#3D2A1C")
    body = bottle(
        body_fill="url(#g_soda)",
        cap_color=AMBER_SOFT,
        cap_edge=AMBER_DEEP,
        cap_height=6,
        label_color=AMBER,
        label_y=88,
        label_h=58,
        body_top=30,
        body_bottom=190,
        body_w=66,
        shoulder=6,
        neck_w=32,
        neck_h=4,
        body_radius_bottom=10,
        label_extras=(
            f'<circle cx="56" cy="108" r="2.8" fill="{ESPRESSO}" opacity="0.4"/>'
            f'<circle cx="70" cy="118" r="2" fill="{ESPRESSO}" opacity="0.4"/>'
            f'<circle cx="84" cy="104" r="3" fill="{ESPRESSO}" opacity="0.4"/>'
        ),
    )
    return svg(body + shadow(), defs=defs)


def pet_water() -> str:
    # Translucent PET with ribbed midsection
    defs = gradient("g_pet", "#EAF1F2", "#D6E4E6", "#F2F7F8", vertical=True)
    cx, top, bot = 70, 36, 196
    body = (
        f'<rect x="{cx - 12}" y="{top - 10}" width="24" height="10" rx="2" fill="{AMBER}"/>'
        f'<path d="M{cx - 12} {top} L{cx + 12} {top} L{cx + 28} {top + 14} '
        f'L{cx + 28} {bot - 8} Q{cx + 28} {bot} {cx + 20} {bot} '
        f'L{cx - 20} {bot} Q{cx - 28} {bot} {cx - 28} {bot - 8} '
        f'L{cx - 28} {top + 14} Z" fill="url(#g_pet)" stroke="{CREAM_3}" stroke-width="1"/>'
        # ribs
        f'<rect x="{cx - 26}" y="120" width="52" height="2" fill="{CREAM_3}" opacity="0.7"/>'
        f'<rect x="{cx - 26}" y="128" width="52" height="2" fill="{CREAM_3}" opacity="0.7"/>'
        f'<rect x="{cx - 26}" y="136" width="52" height="2" fill="{CREAM_3}" opacity="0.7"/>'
        # label
        f'<rect x="{cx - 28}" y="76" width="56" height="34" fill="{CREAM_2}" opacity="0.95"/>'
        f'<rect x="{cx - 22}" y="86" width="44" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 16}" y="96" width="32" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
    )
    return svg(body + shadow(), defs=defs)


def glass_water() -> str:
    defs = gradient("g_glass", "#F2F6F4", "#D9E5E1", "#FAFBF8", vertical=True)
    cx, top, bot = 70, 30, 196
    body = (
        f'<rect x="{cx - 9}" y="{top - 12}" width="18" height="12" rx="2" fill="{AMBER_DEEP}"/>'
        f'<path d="M{cx - 9} {top} L{cx + 9} {top} L{cx + 9} {top + 14} '
        f'L{cx + 22} {top + 30} L{cx + 22} {bot - 8} Q{cx + 22} {bot} {cx + 14} {bot} '
        f'L{cx - 14} {bot} Q{cx - 22} {bot} {cx - 22} {bot - 8} '
        f'L{cx - 22} {top + 30} L{cx - 9} {top + 14} Z" '
        f'fill="url(#g_glass)" stroke="{CREAM_3}" stroke-width="1"/>'
        f'<rect x="{cx - 20}" y="90" width="40" height="38" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 14}" y="100" width="28" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 10}" y="110" width="20" height="2" fill="{AMBER_DEEP}" opacity="0.55"/>'
    )
    return svg(body + shadow(), defs=defs)


def tetra_pak(content_color: str = MILK, label_color: str = AMBER, accent: str = AMBER_DEEP) -> str:
    cx, top, bot = 70, 30, 196
    body = (
        # Gable top
        f'<path d="M{cx - 30} {top + 24} L{cx - 30} {top + 8} L{cx} {top} '
        f'L{cx + 30} {top + 8} L{cx + 30} {top + 24} Z" fill="{darken(content_color)}"/>'
        f'<path d="M{cx - 30} {top + 8} L{cx} {top} L{cx + 30} {top + 8} '
        f'L{cx} {top + 18} Z" fill="{content_color}"/>'
        # Body
        f'<rect x="{cx - 30}" y="{top + 24}" width="60" height="{bot - top - 24}" '
        f'fill="{content_color}"/>'
        # Label band
        f'<rect x="{cx - 30}" y="{top + 70}" width="60" height="44" fill="{label_color}"/>'
        f'<rect x="{cx - 24}" y="{top + 82}" width="48" height="3" fill="{accent}"/>'
        f'<rect x="{cx - 18}" y="{top + 92}" width="36" height="2" fill="{accent}" opacity="0.7"/>'
        f'<circle cx="{cx}" cy="{top + 108}" r="4" fill="{accent}"/>'
    )
    return svg(body + shadow())


def ayran_tub() -> str:
    cx, top, bot = 70, 60, 196
    body = (
        # Foil lid
        f'<ellipse cx="{cx}" cy="{top - 4}" rx="40" ry="6" fill="{AMBER_DEEP}"/>'
        f'<ellipse cx="{cx}" cy="{top - 6}" rx="40" ry="6" fill="{AMBER}"/>'
        # Body
        f'<path d="M{cx - 40} {top - 4} L{cx - 36} {bot - 4} '
        f'Q{cx - 36} {bot} {cx - 30} {bot} L{cx + 30} {bot} '
        f'Q{cx + 36} {bot} {cx + 36} {bot - 4} L{cx + 40} {top - 4} Z" '
        f'fill="{MILK}"/>'
        # Label
        f'<rect x="{cx - 32}" y="92" width="64" height="56" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 26}" y="104" width="52" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 20}" y="114" width="40" height="2" fill="{AMBER_DEEP}" opacity="0.65"/>'
        f'<circle cx="{cx}" cy="130" r="5" fill="{AMBER}" opacity="0.7"/>'
    )
    return svg(body + shadow())


def juice_carton() -> str:
    cx, top, bot = 70, 32, 196
    body = (
        # Cap
        f'<rect x="{cx + 8}" y="{top - 8}" width="10" height="8" rx="2" fill="{AMBER_DEEP}"/>'
        # Body with chamfered top
        f'<path d="M{cx - 28} {top + 8} L{cx - 28} {top} L{cx + 28} {top} '
        f'L{cx + 28} {bot} L{cx - 28} {bot} Z" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 28}" y="{top}" width="56" height="8" fill="{darken(CREAM_2)}"/>'
        # Fruit motif
        f'<circle cx="{cx - 10}" cy="100" r="14" fill="{BANANA}"/>'
        f'<circle cx="{cx + 10}" cy="116" r="12" fill="{TOMATO}"/>'
        f'<rect x="{cx - 24}" y="138" width="48" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 18}" y="148" width="36" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
    )
    return svg(body + shadow())


def tea_box() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        f'<rect x="{cx - 32}" y="{top}" width="64" height="{bot - top}" rx="3" fill="{AMBER_DEEP}"/>'
        # Highlight strip top
        f'<rect x="{cx - 32}" y="{top}" width="64" height="8" fill="{ESPRESSO_3}"/>'
        # Leaf motif
        f'<path d="M{cx} 96 Q{cx - 18} 108 {cx} 132 Q{cx + 18} 108 {cx} 96 Z" fill="{LEAF}"/>'
        f'<path d="M{cx} 96 L{cx} 132" stroke="{LEAF_DEEP}" stroke-width="1.2"/>'
        f'<rect x="{cx - 24}" y="148" width="48" height="3" fill="{AMBER_SOFT}"/>'
        f'<rect x="{cx - 18}" y="158" width="36" height="2" fill="{AMBER_SOFT}" opacity="0.7"/>'
    )
    return svg(body + shadow())


def coffee_tin() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Lid
        f'<rect x="{cx - 32}" y="{top - 8}" width="64" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 32}" y="{top - 2}" width="64" height="4" fill="{ESPRESSO_3}"/>'
        # Body
        f'<rect x="{cx - 30}" y="{top}" width="60" height="{bot - top}" rx="4" fill="{ESPRESSO_2}"/>'
        # Label band
        f'<rect x="{cx - 30}" y="90" width="60" height="54" fill="{AMBER}"/>'
        f'<circle cx="{cx}" cy="112" r="10" fill="{ESPRESSO}" opacity="0.85"/>'
        f'<circle cx="{cx}" cy="112" r="6" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 22}" y="130" width="44" height="3" fill="{ESPRESSO_2}"/>'
    )
    return svg(body + shadow())


def energy_can() -> str:
    defs = gradient("g_energy", "#0E0805", ESPRESSO, "#3D2A1C")
    cx, top, bot = 70, 30, 192
    body = (
        # Tab
        f'<rect x="{cx - 8}" y="{top - 6}" width="16" height="5" rx="1" fill="{CAP_RIM}"/>'
        # Slim body
        f'<rect x="{cx - 20}" y="{top}" width="40" height="{bot - top}" rx="6" fill="url(#g_energy)"/>'
        # Label
        f'<rect x="{cx - 20}" y="68" width="40" height="100" fill="{AMBER}"/>'
        # Lightning-style geometric accent
        f'<path d="M{cx - 6} 86 L{cx + 6} 110 L{cx - 2} 110 L{cx + 6} 138 L{cx - 6} 116 L{cx + 2} 116 Z" '
        f'fill="{ESPRESSO}"/>'
    )
    return svg(body + shadow(rx=22), defs=defs)


def cold_tea_pet() -> str:
    defs = gradient("g_tea", "#C69050", "#8A6135", "#E0B07A", vertical=True)
    cx, top, bot = 70, 34, 196
    body = (
        f'<rect x="{cx - 11}" y="{top - 10}" width="22" height="10" rx="2" fill="{AMBER}"/>'
        f'<path d="M{cx - 11} {top} L{cx + 11} {top} L{cx + 26} {top + 16} '
        f'L{cx + 26} {bot - 8} Q{cx + 26} {bot} {cx + 18} {bot} '
        f'L{cx - 18} {bot} Q{cx - 26} {bot} {cx - 26} {bot - 8} '
        f'L{cx - 26} {top + 16} Z" fill="url(#g_tea)"/>'
        # Label
        f'<rect x="{cx - 26}" y="78" width="52" height="44" fill="{AMBER}"/>'
        f'<path d="M{cx} 88 Q{cx - 12} 100 {cx} 116 Q{cx + 12} 100 {cx} 88 Z" fill="{LEAF}"/>'
        f'<path d="M{cx} 88 L{cx} 116" stroke="{LEAF_DEEP}" stroke-width="1"/>'
    )
    return svg(body + shadow(), defs=defs)


# --- Temel Gıda --------------------------------------------------------


def bread_loaf() -> str:
    defs = gradient("g_bread", BREAD, BREAD_DEEP, "#B98860", vertical=True)
    cx = 70
    body = (
        f'<ellipse cx="{cx}" cy="120" rx="52" ry="44" fill="url(#g_bread)"/>'
        # Top crust slashes
        f'<path d="M{cx - 28} 92 Q{cx - 14} 80 {cx} 86" stroke="{ESPRESSO_3}" stroke-width="2" fill="none" opacity="0.6"/>'
        f'<path d="M{cx - 8} 90 Q{cx + 6} 78 {cx + 20} 86" stroke="{ESPRESSO_3}" stroke-width="2" fill="none" opacity="0.6"/>'
        # Highlight
        f'<ellipse cx="{cx - 12}" cy="108" rx="22" ry="10" fill="{AMBER_SOFT}" opacity="0.35"/>'
    )
    return svg(body + shadow(ry=5), defs=defs)


def sandwich_bread() -> str:
    cx, top, bot = 70, 40, 188
    body = (
        f'<path d="M{cx - 36} {top + 18} '
        f'Q{cx - 40} {top} {cx - 24} {top + 4} '
        f'Q{cx} {top - 6} {cx + 24} {top + 4} '
        f'Q{cx + 40} {top} {cx + 36} {top + 18} '
        f'L{cx + 36} {bot} L{cx - 36} {bot} Z" fill="{BREAD}"/>'
        # Slice lines
        + "".join(
            f'<line x1="{cx - 30}" y1="{y}" x2="{cx + 30}" y2="{y}" stroke="{BREAD_DEEP}" stroke-width="1.2" opacity="0.7"/>'
            for y in (88, 112, 136, 160)
        )
        + f'<rect x="{cx - 36}" y="{top + 18}" width="72" height="3" fill="{AMBER_DEEP}" opacity="0.45"/>'
    )
    return svg(body + shadow())


def egg_carton() -> str:
    cx, top, bot = 70, 60, 188
    cups = "".join(
        f'<ellipse cx="{cx - 32 + i * 22}" cy="84" rx="9" ry="6" fill="{EGGSHELL}"/>'
        f'<ellipse cx="{cx - 32 + i * 22}" cy="80" rx="8" ry="4" fill="{MILK}"/>'
        for i in range(4)
    )
    body = (
        # Back wall (lid open)
        f'<path d="M{cx - 48} {top} L{cx + 48} {top} L{cx + 48} {top + 14} '
        f'L{cx - 48} {top + 14} Z" fill="{darken(EGGSHELL)}"/>'
        # Tray base
        f'<path d="M{cx - 50} {top + 12} L{cx + 50} {top + 12} L{cx + 44} {bot - 12} '
        f'Q{cx + 40} {bot - 4} {cx + 32} {bot - 4} L{cx - 32} {bot - 4} '
        f'Q{cx - 40} {bot - 4} {cx - 44} {bot - 12} Z" fill="{EGGSHELL}"/>'
        f'{cups}'
    )
    return svg(body + shadow(rx=40, cy=200))


def kraft_pack(window_extras: str, accent: str = AMBER) -> str:
    cx, top, bot = 70, 36, 196
    body = (
        f'<path d="M{cx - 34} {top + 10} '
        f'Q{cx - 14} {top - 4} {cx} {top + 6} '
        f'Q{cx + 14} {top - 4} {cx + 34} {top + 10} '
        f'L{cx + 34} {bot} L{cx - 34} {bot} Z" fill="{BREAD}"/>'
        f'<rect x="{cx - 34}" y="{top + 6}" width="68" height="6" fill="{AMBER_DEEP}" opacity="0.6"/>'
        # Window
        f'<rect x="{cx - 24}" y="88" width="48" height="60" rx="3" fill="{MILK}"/>'
        f'<rect x="{cx - 24}" y="88" width="48" height="6" fill="{accent}" opacity="0.4"/>'
        f'{window_extras}'
        # Bottom label band
        f'<rect x="{cx - 28}" y="160" width="56" height="3" fill="{accent}"/>'
    )
    return svg(body + shadow())


def rice_pack() -> str:
    grains = "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="2.5" ry="1.2" fill="{CREAM_3}"/>'
        for x, y in [(58, 104), (66, 112), (74, 108), (82, 116), (60, 122), (70, 128), (80, 124),
                     (62, 134), (74, 138), (84, 132), (56, 142), (66, 144)]
    )
    return kraft_pack(grains)


def pasta_pack() -> str:
    cx, top, bot = 70, 32, 196
    sticks = "".join(
        f'<rect x="{x}" y="60" width="2" height="120" fill="{BANANA}"/>'
        for x in range(56, 86, 4)
    )
    body = (
        f'<rect x="{cx - 22}" y="{top}" width="44" height="{bot - top}" rx="3" fill="{CREAM_2}" opacity="0.95"/>'
        # Translucent reveal
        f'<rect x="{cx - 18}" y="{top + 24}" width="36" height="130" fill="{AMBER}" opacity="0.25"/>'
        f'{sticks}'
        f'<rect x="{cx - 22}" y="{top + 12}" width="44" height="10" fill="{AMBER}"/>'
        f'<rect x="{cx - 22}" y="{bot - 20}" width="44" height="6" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def bulgur_pack() -> str:
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="1.4" fill="{BREAD_DEEP}"/>'
        for x, y in [(54, 102), (62, 108), (72, 104), (82, 110), (88, 102), (58, 118), (70, 122),
                     (80, 118), (62, 132), (76, 136), (86, 130), (54, 140), (74, 144)]
    )
    return kraft_pack(dots)


def mercimek_pack() -> str:
    # Lentil orange-ish discs
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="2.2" fill="#C66E3A"/>'
        for x, y in [(56, 104), (66, 110), (76, 106), (84, 114), (60, 122), (72, 128),
                     (82, 124), (58, 136), (70, 140), (80, 134)]
    )
    return kraft_pack(dots)


def nohut_pack() -> str:
    # Chickpea round
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="3" fill="{BANANA}"/>'
        f'<circle cx="{x - 0.6}" cy="{y - 0.6}" r="0.8" fill="#E6C374"/>'
        for x, y in [(58, 106), (70, 110), (82, 106), (62, 124), (74, 128), (84, 122),
                     (58, 140), (72, 142)]
    )
    return kraft_pack(dots)


def flour_sack() -> str:
    cx, top, bot = 70, 30, 196
    body = (
        # Folded top
        f'<path d="M{cx - 32} {top + 10} '
        f'Q{cx - 16} {top - 4} {cx} {top + 8} '
        f'Q{cx + 16} {top - 4} {cx + 32} {top + 10} '
        f'L{cx + 32} {bot} L{cx - 32} {bot} Z" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 32}" y="{top + 4}" width="64" height="6" fill="{darken(CREAM_2)}" opacity="0.8"/>'
        # Tied band
        f'<rect x="{cx - 32}" y="{top + 14}" width="64" height="4" fill="{AMBER_DEEP}"/>'
        # Label panel
        f'<rect x="{cx - 24}" y="86" width="48" height="64" fill="{AMBER}"/>'
        # Wheat motif
        f'<path d="M{cx} 100 L{cx} 138" stroke="{ESPRESSO_3}" stroke-width="1.5"/>'
        + "".join(
            f'<ellipse cx="{cx + dx}" cy="{y}" rx="3" ry="2" fill="{ESPRESSO_3}"/>'
            for dx, y in [(-4, 106), (4, 106), (-4, 114), (4, 114), (-4, 122), (4, 122), (-4, 130), (4, 130)]
        )
    )
    return svg(body + shadow())


def sugar_pack() -> str:
    cx, top, bot = 70, 36, 196
    cubes = "".join(
        f'<rect x="{cx - 18 + (i % 3) * 12}" y="{100 + (i // 3) * 12}" width="10" height="10" fill="{MILK}"/>'
        f'<rect x="{cx - 18 + (i % 3) * 12}" y="{100 + (i // 3) * 12}" width="10" height="2" fill="{CREAM_3}"/>'
        for i in range(9)
    )
    body = (
        f'<rect x="{cx - 30}" y="{top}" width="60" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 30}" y="{top}" width="60" height="14" fill="{AMBER}"/>'
        f'<rect x="{cx - 24}" y="92" width="48" height="40" rx="2" fill="{MILK}" opacity="0.8"/>'
        f'{cubes}'
        f'<rect x="{cx - 24}" y="148" width="48" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def salt_carton() -> str:
    cx, top, bot = 70, 30, 196
    body = (
        # Top cap (small spout)
        f'<rect x="{cx - 6}" y="{top - 6}" width="12" height="6" rx="1" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 18}" y="{top}" width="36" height="{bot - top}" rx="4" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 18}" y="{top + 8}" width="36" height="14" fill="{AMBER}"/>'
        # Pattern
        f'<rect x="{cx - 14}" y="64" width="28" height="2" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 12}" y="78" width="24" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
        # Salt crystal dots
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1" fill="{AMBER_DEEP}"/>'
            for x, y in [(62, 110), (70, 116), (78, 110), (60, 124), (70, 128), (80, 124),
                         (66, 138), (74, 142)]
        )
    )
    return svg(body + shadow())


def olive_jar() -> str:
    olives = "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="4" ry="5" fill="{LEAF_DEEP}"/>'
        f'<circle cx="{x - 1}" cy="{y - 1}" r="1.4" fill="{LEAF_SOFT}"/>'
        for x, y in [(62, 110), (74, 114), (66, 130), (78, 134), (60, 148), (72, 152)]
    )
    return svg(
        jar(content_color="#7B9468", glass_tint="#D6E0CB", body_w=72, body_top=78, content_extras=olives)
        + shadow()
    )


# --- Süt & Yağ --------------------------------------------------------


def yogurt_tub() -> str:
    cx, top, bot = 70, 84, 196
    body = (
        # Foil lid
        f'<ellipse cx="{cx}" cy="{top - 4}" rx="44" ry="8" fill="{AMBER_SOFT}"/>'
        f'<ellipse cx="{cx}" cy="{top - 6}" rx="44" ry="8" fill="{AMBER}"/>'
        # Body taper
        f'<path d="M{cx - 44} {top - 4} L{cx - 36} {bot - 4} '
        f'Q{cx - 36} {bot} {cx - 30} {bot} L{cx + 30} {bot} '
        f'Q{cx + 36} {bot} {cx + 36} {bot - 4} L{cx + 44} {top - 4} Z" '
        f'fill="{MILK}"/>'
        f'<rect x="{cx - 34}" y="100" width="68" height="60" fill="{CREAM_2}"/>'
        f'<circle cx="{cx}" cy="124" r="10" fill="{AMBER}"/>'
        f'<rect x="{cx - 24}" y="142" width="48" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow(rx=40))


def cheese_white() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        f'<rect x="{cx - 32}" y="{top}" width="64" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 32}" y="{top}" width="64" height="12" fill="{AMBER}"/>'
        # Cheese block (white)
        f'<rect x="{cx - 24}" y="92" width="48" height="68" rx="2" fill="{MILK}"/>'
        f'<rect x="{cx - 24}" y="92" width="48" height="6" fill="{darken(MILK)}" opacity="0.7"/>'
        # Slice indicator
        f'<line x1="{cx - 24}" y1="124" x2="{cx + 24}" y2="124" stroke="{CREAM_3}" stroke-width="1"/>'
        f'<rect x="{cx - 22}" y="170" width="44" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def cheese_kasar() -> str:
    cx, top, bot = 70, 36, 196
    holes = "".join(
        f'<circle cx="{x}" cy="{y}" r="2.4" fill="{BANANA_DEEP}" opacity="0.5"/>'
        for x, y in [(58, 110), (74, 118), (86, 108), (62, 134), (78, 140)]
    )
    body = (
        f'<rect x="{cx - 32}" y="{top}" width="64" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 32}" y="{top}" width="64" height="12" fill="{AMBER}"/>'
        f'<rect x="{cx - 24}" y="92" width="48" height="68" rx="2" fill="{BANANA}"/>'
        f'<rect x="{cx - 24}" y="92" width="48" height="6" fill="{BANANA_DEEP}"/>'
        f'{holes}'
        f'<rect x="{cx - 22}" y="170" width="44" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def butter_pack() -> str:
    cx, top, bot = 70, 50, 188
    body = (
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="4" fill="{BREAD}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="14" fill="{AMBER_DEEP}"/>'
        # Butter stick
        f'<rect x="{cx - 28}" y="100" width="56" height="50" rx="2" fill="{BANANA}"/>'
        f'<rect x="{cx - 28}" y="100" width="56" height="6" fill="{BANANA_DEEP}"/>'
        f'<rect x="{cx - 24}" y="120" width="48" height="3" fill="{BANANA_DEEP}" opacity="0.6"/>'
    )
    return svg(body + shadow())


def cream_bottle() -> str:
    cx, top, bot = 70, 60, 196
    body = (
        f'<rect x="{cx - 10}" y="{top - 10}" width="20" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        f'<path d="M{cx - 22} {top} L{cx + 22} {top} L{cx + 26} {top + 18} '
        f'L{cx + 26} {bot - 4} L{cx - 26} {bot - 4} L{cx - 26} {top + 18} Z" '
        f'fill="{MILK}"/>'
        f'<rect x="{cx - 26}" y="106" width="52" height="48" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 20}" y="116" width="40" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 16}" y="126" width="32" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
        f'<circle cx="{cx}" cy="142" r="5" fill="{AMBER}" opacity="0.7"/>'
    )
    return svg(body + shadow())


def sunflower_oil() -> str:
    defs = gradient("g_oil", "#E6C26A", "#A57E2A", "#F3D27A", vertical=True)
    cx, top, bot = 70, 36, 196
    body = (
        f'<rect x="{cx - 10}" y="{top - 10}" width="20" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        f'<path d="M{cx - 10} {top} L{cx + 10} {top} L{cx + 22} {top + 18} '
        f'L{cx + 24} {bot - 8} Q{cx + 24} {bot} {cx + 16} {bot} '
        f'L{cx - 16} {bot} Q{cx - 24} {bot} {cx - 24} {bot - 8} '
        f'L{cx - 22} {top + 18} Z" fill="url(#g_oil)"/>'
        f'<rect x="{cx - 22}" y="86" width="44" height="56" fill="{AMBER}" opacity="0.95"/>'
        # Sunflower silhouette
        f'<circle cx="{cx}" cy="108" r="6" fill="{BREAD_DEEP}"/>'
        + "".join(
            f'<ellipse cx="{cx + dx}" cy="{108 + dy}" rx="3" ry="5" fill="{BANANA}" '
            f'transform="rotate({deg} {cx} 108)"/>'
            for deg, dx, dy in [(0, 0, -10), (60, 0, -10), (120, 0, -10),
                                 (180, 0, -10), (240, 0, -10), (300, 0, -10)]
        )
        + f'<rect x="{cx - 18}" y="128" width="36" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow(), defs=defs)


def olive_oil_bottle() -> str:
    defs = gradient("g_olive", "#7B9468", "#3F5A30", "#9DB88B", vertical=True)
    cx, top, bot = 70, 32, 196
    body = (
        f'<rect x="{cx - 9}" y="{top - 10}" width="18" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        f'<path d="M{cx - 9} {top} L{cx + 9} {top} L{cx + 9} {top + 24} '
        f'L{cx + 22} {top + 40} L{cx + 22} {bot - 8} Q{cx + 22} {bot} {cx + 14} {bot} '
        f'L{cx - 14} {bot} Q{cx - 22} {bot} {cx - 22} {bot - 8} '
        f'L{cx - 22} {top + 40} L{cx - 9} {top + 24} Z" fill="url(#g_olive)"/>'
        f'<rect x="{cx - 20}" y="98" width="40" height="48" fill="{CREAM_2}"/>'
        # Olive branch motif
        f'<path d="M{cx - 12} 122 Q{cx} 110 {cx + 12} 122" stroke="{LEAF_DEEP}" stroke-width="1.5" fill="none"/>'
        f'<ellipse cx="{cx - 10}" cy="120" rx="3" ry="2" fill="{LEAF_DEEP}"/>'
        f'<ellipse cx="{cx}" cy="114" rx="3" ry="2" fill="{LEAF_DEEP}"/>'
        f'<ellipse cx="{cx + 10}" cy="120" rx="3" ry="2" fill="{LEAF_DEEP}"/>'
        f'<rect x="{cx - 16}" y="136" width="32" height="3" fill="{LEAF_DEEP}"/>'
    )
    return svg(body + shadow(), defs=defs)


def vinegar_bottle() -> str:
    defs = gradient("g_vinegar", "#E6C792", "#A87E45", "#F0D9A8", vertical=True)
    cx, top, bot = 70, 36, 196
    body = (
        f'<rect x="{cx - 9}" y="{top - 10}" width="18" height="10" rx="2" fill="{AMBER}"/>'
        f'<path d="M{cx - 9} {top} L{cx + 9} {top} L{cx + 18} {top + 16} '
        f'L{cx + 20} {bot - 8} Q{cx + 20} {bot} {cx + 12} {bot} '
        f'L{cx - 12} {bot} Q{cx - 20} {bot} {cx - 20} {bot - 8} '
        f'L{cx - 18} {top + 16} Z" fill="url(#g_vinegar)"/>'
        f'<rect x="{cx - 18}" y="86" width="36" height="60" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 14}" y="100" width="28" height="3" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 10}" y="110" width="20" height="2" fill="{AMBER_DEEP}" opacity="0.7"/>'
        f'<circle cx="{cx}" cy="128" r="4" fill="{AMBER}" opacity="0.6"/>'
    )
    return svg(body + shadow(), defs=defs)


# --- Sebze --------------------------------------------------------


def tomato() -> str:
    body = (
        f'<circle cx="70" cy="118" r="48" fill="{TOMATO}"/>'
        f'<ellipse cx="58" cy="100" rx="14" ry="8" fill="#D27858" opacity="0.7"/>'
        # Stem
        f'<path d="M70 70 L70 78" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M58 72 L70 78 L82 72 L78 84 L70 80 L62 84 Z" fill="{LEAF}"/>'
        f'<circle cx="70" cy="78" r="2.5" fill="{LEAF_DEEP}"/>'
    )
    return svg(body + shadow())


def cucumber() -> str:
    body = (
        f'<path d="M40 88 Q44 60 70 60 Q98 64 100 100 Q102 144 84 168 '
        f'Q60 188 46 168 Q34 144 40 88 Z" fill="{LEAF}"/>'
        f'<path d="M50 96 Q54 76 72 74" stroke="{LEAF_SOFT}" stroke-width="3" fill="none" opacity="0.7"/>'
        # bumps
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1.6" fill="{LEAF_DEEP}" opacity="0.6"/>'
            for x, y in [(60, 90), (78, 100), (66, 120), (82, 130), (58, 150), (74, 156)]
        )
        # Stem
        + f'<path d="M70 56 L70 64" stroke="{LEAF_DEEP}" stroke-width="2"/>'
    )
    return svg(body + shadow())


def potato() -> str:
    body = (
        f'<ellipse cx="70" cy="122" rx="50" ry="42" fill="{BREAD}"/>'
        # Eyes
        + "".join(
            f'<ellipse cx="{x}" cy="{y}" rx="2.5" ry="1.6" fill="{ESPRESSO_3}" opacity="0.7"/>'
            for x, y in [(54, 110), (78, 102), (90, 124), (60, 138), (84, 142)]
        )
        # Highlight
        + f'<ellipse cx="58" cy="108" rx="14" ry="8" fill="{BANANA}" opacity="0.3"/>'
    )
    return svg(body + shadow())


def onion() -> str:
    body = (
        f'<path d="M70 76 L60 70 L80 70 Z" fill="{LEAF_DEEP}"/>'
        f'<ellipse cx="70" cy="130" rx="44" ry="46" fill="{BANANA}"/>'
        f'<path d="M52 100 Q60 140 70 168" stroke="{BANANA_DEEP}" stroke-width="1.5" fill="none" opacity="0.7"/>'
        f'<path d="M88 100 Q80 140 70 168" stroke="{BANANA_DEEP}" stroke-width="1.5" fill="none" opacity="0.7"/>'
        f'<path d="M70 90 L70 170" stroke="{BANANA_DEEP}" stroke-width="1" opacity="0.4"/>'
        # Highlight
        f'<ellipse cx="58" cy="116" rx="12" ry="20" fill="{AMBER_SOFT}" opacity="0.35"/>'
    )
    return svg(body + shadow())


def garlic() -> str:
    body = (
        f'<path d="M70 76 Q66 70 70 66 Q74 70 70 76 Z" fill="{LEAF_DEEP}"/>'
        f'<ellipse cx="70" cy="130" rx="42" ry="44" fill="{MILK}"/>'
        # Cloves separation lines
        f'<path d="M70 86 L70 172" stroke="{CREAM_3}" stroke-width="1.4"/>'
        f'<path d="M52 100 Q60 140 70 170" stroke="{CREAM_3}" stroke-width="1.4" fill="none"/>'
        f'<path d="M88 100 Q80 140 70 170" stroke="{CREAM_3}" stroke-width="1.4" fill="none"/>'
        f'<ellipse cx="58" cy="120" rx="10" ry="20" fill="{CREAM_2}" opacity="0.6"/>'
    )
    return svg(body + shadow())


def pepper(color: str, deep: str) -> str:
    body = (
        f'<path d="M70 70 L70 80" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M62 72 L78 72" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M50 90 Q46 80 60 80 Q78 78 86 92 Q98 110 90 150 '
        f'Q82 178 68 178 Q52 174 50 150 Q46 116 50 90 Z" fill="{color}"/>'
        f'<path d="M58 100 Q56 120 60 150" stroke="{deep}" stroke-width="2" fill="none" opacity="0.55"/>'
        f'<path d="M78 96 Q82 120 80 150" stroke="{deep}" stroke-width="2" fill="none" opacity="0.55"/>'
    )
    return svg(body + shadow())


def eggplant() -> str:
    body = (
        f'<path d="M70 74 L70 84" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M60 76 L80 76" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M64 82 Q56 78 50 86" stroke="{LEAF}" stroke-width="2" fill="none"/>'
        f'<path d="M76 82 Q84 78 90 86" stroke="{LEAF}" stroke-width="2" fill="none"/>'
        f'<path d="M52 110 Q44 90 70 88 Q96 90 90 116 Q94 162 70 180 '
        f'Q46 162 52 110 Z" fill="#5A3C5C"/>'
        f'<ellipse cx="60" cy="120" rx="8" ry="20" fill="#7A5C7C" opacity="0.5"/>'
    )
    return svg(body + shadow())


def zucchini() -> str:
    body = (
        f'<path d="M70 70 L70 80" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M44 92 Q42 80 60 80 Q90 82 96 100 Q104 160 80 178 '
        f'Q56 184 48 162 Q40 130 44 92 Z" fill="{LEAF}"/>'
        + "".join(
            f'<rect x="{x}" y="{y}" width="2" height="10" fill="{LEAF_DEEP}" opacity="0.6"/>'
            for x, y in [(56, 100), (66, 108), (76, 102), (84, 112), (60, 130),
                         (72, 138), (82, 132), (58, 156), (70, 160), (80, 152)]
        )
    )
    return svg(body + shadow())


def lettuce() -> str:
    cx = 70
    body = (
        # Outer leaves
        f'<path d="M{cx - 50} 132 Q{cx - 56} 90 {cx - 20} 80 Q{cx} 70 {cx + 20} 80 '
        f'Q{cx + 56} 90 {cx + 50} 132 Q{cx + 46} 170 {cx + 20} 178 '
        f'Q{cx} 184 {cx - 20} 178 Q{cx - 46} 170 {cx - 50} 132 Z" fill="{LEAF}"/>'
        # Inner layer
        f'<path d="M{cx - 36} 130 Q{cx - 40} 100 {cx - 14} 96 Q{cx} 90 {cx + 14} 96 '
        f'Q{cx + 40} 100 {cx + 36} 130 Q{cx + 32} 158 {cx + 14} 164 '
        f'Q{cx} 168 {cx - 14} 164 Q{cx - 32} 158 {cx - 36} 130 Z" fill="{LEAF_SOFT}"/>'
        # Vein lines
        f'<path d="M{cx} 96 L{cx} 168" stroke="{LEAF_DEEP}" stroke-width="1.2" opacity="0.4"/>'
        f'<path d="M{cx - 30} 132 Q{cx} 124 {cx + 30} 132" stroke="{LEAF_DEEP}" stroke-width="1.2" fill="none" opacity="0.4"/>'
    )
    return svg(body + shadow())


# --- Meyve --------------------------------------------------------


def apple() -> str:
    body = (
        f'<path d="M70 72 L70 80" stroke="{LEAF_DEEP}" stroke-width="3"/>'
        f'<path d="M72 72 Q78 64 90 64 Q88 76 80 80" fill="{LEAF}"/>'
        f'<path d="M44 110 Q42 86 64 84 Q70 82 76 84 Q98 86 96 110 '
        f'Q102 160 80 178 Q70 184 60 178 Q38 160 44 110 Z" fill="{TOMATO}"/>'
        f'<ellipse cx="58" cy="116" rx="12" ry="18" fill="#D88466" opacity="0.5"/>'
    )
    return svg(body + shadow())


def banana() -> str:
    body = (
        f'<path d="M30 102 Q34 70 60 70 Q70 70 78 78 '
        f'Q112 110 110 156 Q108 174 96 174 Q90 174 88 168 '
        f'Q90 158 84 144 Q74 124 56 110 Q40 102 30 102 Z" fill="{BANANA}"/>'
        f'<path d="M44 100 Q70 92 100 134" stroke="{BANANA_DEEP}" stroke-width="2" fill="none" opacity="0.55"/>'
        # Brown tip
        f'<ellipse cx="33" cy="100" rx="6" ry="4" fill="{BREAD_DEEP}"/>'
        f'<ellipse cx="100" cy="172" rx="6" ry="4" fill="{BREAD_DEEP}"/>'
    )
    return svg(body + shadow())


def orange() -> str:
    body = (
        f'<path d="M68 70 L72 78" stroke="{LEAF_DEEP}" stroke-width="2"/>'
        f'<path d="M64 70 Q72 64 80 72 L72 78 Z" fill="{LEAF}"/>'
        f'<circle cx="70" cy="124" r="48" fill="#D87E2C"/>'
        # Texture dots
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1" fill="{BREAD_DEEP}" opacity="0.45"/>'
            for x, y in [(54, 110), (66, 102), (80, 108), (88, 120), (60, 130),
                         (72, 138), (84, 140), (56, 146), (74, 158), (86, 152)]
        )
        + f'<ellipse cx="58" cy="112" rx="14" ry="10" fill="#E89A50" opacity="0.5"/>'
    )
    return svg(body + shadow())


def mandalina() -> str:
    body = (
        f'<path d="M64 74 Q72 64 80 76 L72 84 Z" fill="{LEAF}"/>'
        f'<path d="M70 80 L70 90" stroke="{LEAF_DEEP}" stroke-width="2"/>'
        f'<circle cx="70" cy="132" r="40" fill="#E5904A"/>'
        # Segments hint
        f'<path d="M70 92 L70 172" stroke="#B96E2C" stroke-width="1" opacity="0.4"/>'
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1" fill="{BREAD_DEEP}" opacity="0.4"/>'
            for x, y in [(56, 122), (68, 118), (80, 120), (88, 132), (60, 138),
                         (74, 146), (84, 144)]
        )
    )
    return svg(body + shadow())


def grapes() -> str:
    cx = 70
    grapes = "".join(
        f'<circle cx="{cx + dx}" cy="{cy}" r="9" fill="#6B4878"/>'
        f'<circle cx="{cx + dx - 2}" cy="{cy - 2}" r="3" fill="#9270A8" opacity="0.7"/>'
        for cy, dxs in [
            (102, [-18, -2, 14]),
            (118, [-10, 6, 22]),
            (134, [-18, -2, 14]),
            (150, [-8, 8]),
            (164, [0]),
        ] for dx in dxs
    )
    body = (
        # Stem
        f'<path d="M{cx} 76 Q{cx + 6} 82 {cx + 10} 90" stroke="{BREAD_DEEP}" stroke-width="2" fill="none"/>'
        # Leaf
        f'<path d="M{cx - 6} 80 Q{cx - 22} 74 {cx - 28} 92 Q{cx - 16} 102 {cx - 4} 90 Z" fill="{LEAF}"/>'
        f'<path d="M{cx - 8} 86 L{cx - 22} 90" stroke="{LEAF_DEEP}" stroke-width="1"/>'
        + grapes
    )
    return svg(body + shadow())


def watermelon() -> str:
    body = (
        # Slice triangle/half-circle
        f'<path d="M20 130 Q70 60 120 130 Z" fill="{LEAF}"/>'
        f'<path d="M28 130 Q70 70 112 130 Z" fill="{MILK}"/>'
        f'<path d="M34 130 Q70 80 106 130 Z" fill="{TOMATO}"/>'
        # Seeds
        + "".join(
            f'<ellipse cx="{x}" cy="{y}" rx="1.6" ry="2.6" fill="{ESPRESSO}"/>'
            for x, y in [(56, 112), (70, 100), (84, 112), (50, 124), (70, 122),
                         (90, 124), (62, 116), (78, 116)]
        )
        # Rind shadow line
        + f'<path d="M20 130 L120 130" stroke="{LEAF_DEEP}" stroke-width="1.5"/>'
    )
    return svg(body + shadow(cy=148, rx=46))


def strawberry() -> str:
    body = (
        # Leaves (calyx)
        f'<path d="M48 80 L70 70 L92 80 L82 92 L70 84 L58 92 Z" fill="{LEAF}"/>'
        f'<circle cx="70" cy="78" r="4" fill="{LEAF_DEEP}"/>'
        # Body — heart-like
        f'<path d="M70 88 Q40 88 38 116 Q38 142 70 172 Q102 142 102 116 Q100 88 70 88 Z" fill="{TOMATO}"/>'
        # Seeds
        + "".join(
            f'<ellipse cx="{x}" cy="{y}" rx="1.2" ry="2" fill="{BANANA}" transform="rotate({r} {x} {y})"/>'
            for x, y, r in [(56, 110, 20), (70, 104, 0), (84, 110, -20),
                            (50, 128, 30), (66, 124, 10), (82, 124, -10),
                            (94, 128, -30), (58, 146, 30), (70, 142, 0),
                            (82, 146, -30), (66, 160, 0), (78, 158, -20)]
        )
    )
    return svg(body + shadow())


def lemon() -> str:
    body = (
        f'<path d="M70 78 L70 84" stroke="{LEAF_DEEP}" stroke-width="2"/>'
        f'<ellipse cx="70" cy="128" rx="40" ry="52" fill="#E8CD58"/>'
        # Highlight
        f'<ellipse cx="58" cy="110" rx="10" ry="16" fill="#F2DE82" opacity="0.6"/>'
        # Texture
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1" fill="#A88E28" opacity="0.4"/>'
            for x, y in [(54, 116), (68, 108), (82, 116), (60, 134), (74, 142),
                         (84, 130), (58, 150), (74, 158)]
        )
    )
    return svg(body + shadow())


# --- Et & Balık --------------------------------------------------------


def chicken_pack() -> str:
    cx, top, bot = 70, 50, 188
    body = (
        # Tray
        f'<path d="M{cx - 44} {top + 12} L{cx + 44} {top + 12} L{cx + 40} {bot} '
        f'L{cx - 40} {bot} Z" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 44}" y="{top}" width="88" height="14" fill="{darken(CREAM_2)}"/>'
        # Plastic film highlight
        f'<rect x="{cx - 42}" y="{top + 14}" width="84" height="4" fill="{MILK}" opacity="0.7"/>'
        # Meat blob (chicken — pale)
        f'<path d="M{cx - 32} 90 Q{cx - 20} 76 {cx} 82 Q{cx + 22} 80 {cx + 30} 100 '
        f'Q{cx + 36} 134 {cx + 12} 156 Q{cx - 20} 162 {cx - 32} 142 Q{cx - 40} 116 {cx - 32} 90 Z" '
        f'fill="#E8BC92"/>'
        f'<ellipse cx="{cx - 8}" cy="104" rx="16" ry="10" fill="#F1CDA8" opacity="0.6"/>'
        f'<path d="M{cx - 20} 130 Q{cx} 134 {cx + 20} 126" stroke="#B58A60" stroke-width="1.2" fill="none" opacity="0.5"/>'
    )
    return svg(body + shadow(rx=40))


def red_meat_pack() -> str:
    cx, top, bot = 70, 50, 188
    body = (
        f'<path d="M{cx - 44} {top + 12} L{cx + 44} {top + 12} L{cx + 40} {bot} '
        f'L{cx - 40} {bot} Z" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 44}" y="{top}" width="88" height="14" fill="{darken(CREAM_2)}"/>'
        f'<rect x="{cx - 42}" y="{top + 14}" width="84" height="4" fill="{MILK}" opacity="0.7"/>'
        f'<path d="M{cx - 32} 92 Q{cx - 20} 78 {cx} 84 Q{cx + 22} 82 {cx + 30} 100 '
        f'Q{cx + 36} 134 {cx + 12} 156 Q{cx - 20} 162 {cx - 32} 142 Q{cx - 40} 116 {cx - 32} 92 Z" '
        f'fill="#A2412B"/>'
        # Marbling
        f'<path d="M{cx - 22} 108 Q{cx - 6} 102 {cx + 16} 112" stroke="{MILK}" stroke-width="1.2" fill="none" opacity="0.7"/>'
        f'<path d="M{cx - 14} 130 Q{cx + 4} 124 {cx + 22} 134" stroke="{MILK}" stroke-width="1.2" fill="none" opacity="0.7"/>'
        f'<path d="M{cx - 24} 148 Q{cx} 142 {cx + 18} 150" stroke="{MILK}" stroke-width="1" fill="none" opacity="0.55"/>'
    )
    return svg(body + shadow(rx=40))


def ground_meat_pack() -> str:
    cx, top, bot = 70, 50, 188
    dots = "".join(
        f'<circle cx="{x}" cy="{y}" r="2.4" fill="#7A2D1C"/>'
        for x, y in [(48, 96), (62, 90), (76, 94), (90, 100), (54, 108), (70, 112),
                     (86, 110), (44, 124), (60, 130), (78, 126), (92, 130), (50, 144),
                     (66, 148), (82, 144), (94, 150), (56, 158), (72, 162), (88, 160)]
    )
    body = (
        f'<path d="M{cx - 44} {top + 12} L{cx + 44} {top + 12} L{cx + 40} {bot} '
        f'L{cx - 40} {bot} Z" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 44}" y="{top}" width="88" height="14" fill="{darken(CREAM_2)}"/>'
        f'<rect x="{cx - 42}" y="{top + 14}" width="84" height="4" fill="{MILK}" opacity="0.7"/>'
        f'<path d="M{cx - 32} 88 L{cx + 32} 88 L{cx + 34} 168 L{cx - 34} 168 Z" fill="#A2412B"/>'
        f'{dots}'
    )
    return svg(body + shadow(rx=40))


def fish() -> str:
    cx = 70
    body = (
        # Body
        f'<path d="M18 130 Q40 70 100 84 Q120 88 122 104 '
        f'Q120 134 100 156 Q40 168 18 130 Z" fill="#C3CAD3"/>'
        # Tail
        f'<path d="M14 130 L34 100 L34 158 Z" fill="#9AA4B0"/>'
        # Gill
        f'<path d="M76 100 Q72 130 78 156" stroke="#8090A0" stroke-width="2" fill="none"/>'
        # Eye
        f'<circle cx="100" cy="104" r="4" fill="{MILK}"/>'
        f'<circle cx="100" cy="104" r="2" fill="{ESPRESSO}"/>'
        # Fin
        f'<path d="M70 90 L86 76 L90 96 Z" fill="#9AA4B0"/>'
        # Scales
        + "".join(
            f'<path d="M{x} {y} q5 -6 10 0" stroke="#8090A0" stroke-width="1" fill="none" opacity="0.6"/>'
            for x, y in [(46, 120), (56, 128), (66, 120), (76, 128), (86, 120),
                         (50, 138), (60, 144), (70, 138), (80, 144)]
        )
    )
    return svg(body + shadow(cy=178, rx=44, ry=4))


# --- Atıştırmalık --------------------------------------------------------


def chocolate_tablet() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Wrapper
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="3" fill="{ESPRESSO_2}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="12" fill="{AMBER_DEEP}"/>'
        # Chocolate block
        f'<rect x="{cx - 28}" y="80" width="56" height="80" fill="{ESPRESSO_3}"/>'
        # Grid
        + "".join(
            f'<line x1="{cx - 28 + i * 14}" y1="80" x2="{cx - 28 + i * 14}" y2="160" stroke="{ESPRESSO}" stroke-width="1.5"/>'
            for i in range(1, 4)
        )
        + "".join(
            f'<line x1="{cx - 28}" y1="{80 + i * 20}" x2="{cx + 28}" y2="{80 + i * 20}" stroke="{ESPRESSO}" stroke-width="1.5"/>'
            for i in range(1, 4)
        )
        + f'<rect x="{cx - 28}" y="172" width="56" height="3" fill="{AMBER}"/>'
    )
    return svg(body + shadow())


def chocolate_bar() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        f'<rect x="{cx - 22}" y="{top}" width="44" height="{bot - top}" rx="4" fill="{BREAD_DEEP}"/>'
        f'<rect x="{cx - 22}" y="{top}" width="44" height="14" fill="{ESPRESSO_3}"/>'
        # Label band
        f'<rect x="{cx - 22}" y="90" width="44" height="56" fill="{AMBER}"/>'
        f'<rect x="{cx - 16}" y="100" width="32" height="3" fill="{ESPRESSO_2}"/>'
        f'<rect x="{cx - 12}" y="110" width="24" height="2" fill="{ESPRESSO_2}" opacity="0.7"/>'
        f'<circle cx="{cx}" cy="130" r="6" fill="{ESPRESSO_2}"/>'
        # Bottom seal
        f'<rect x="{cx - 22}" y="{bot - 12}" width="44" height="6" fill="{ESPRESSO_3}"/>'
    )
    return svg(body + shadow())


def biscuit_roll() -> str:
    cx, top, bot = 70, 40, 196
    biscuits = "".join(
        f'<circle cx="{cx}" cy="{y}" r="20" fill="{BREAD}"/>'
        f'<circle cx="{cx}" cy="{y}" r="14" fill="{BREAD_DEEP}" opacity="0.35"/>'
        + "".join(f'<circle cx="{cx + dx}" cy="{y + dy}" r="1.4" fill="{ESPRESSO_3}" opacity="0.5"/>'
                  for dx, dy in [(-8, -4), (8, -4), (-6, 6), (6, 6), (0, 0)])
        for y in (76, 108, 140)
    )
    body = (
        # Wrapper
        f'<rect x="{cx - 26}" y="{top}" width="52" height="{bot - top}" rx="6" fill="{CREAM_2}" opacity="0.85"/>'
        f'<rect x="{cx - 26}" y="{top}" width="52" height="12" fill="{AMBER}"/>'
        f'{biscuits}'
        f'<rect x="{cx - 26}" y="{bot - 12}" width="52" height="6" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def cracker_pack() -> str:
    cx, top, bot = 70, 40, 192
    body = (
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="12" fill="{AMBER}"/>'
        # Cracker square
        f'<rect x="{cx - 24}" y="84" width="48" height="48" rx="4" fill="{BREAD}"/>'
        f'<path d="M{cx - 24} 84 L{cx + 24} 132 M{cx + 24} 84 L{cx - 24} 132" stroke="{BREAD_DEEP}" stroke-width="1.2"/>'
        # Salt dots
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1" fill="{MILK}"/>'
            for x, y in [(56, 96), (70, 100), (84, 96), (60, 112), (74, 118), (84, 112),
                         (60, 124), (78, 124)]
        )
        + f'<rect x="{cx - 28}" y="148" width="56" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def chips_bag() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Crinkled top zigzag
        f'<path d="M{cx - 32} {top + 6} L{cx - 26} {top} L{cx - 20} {top + 6} L{cx - 14} {top} '
        f'L{cx - 8} {top + 6} L{cx - 2} {top} L{cx + 4} {top + 6} L{cx + 10} {top} '
        f'L{cx + 16} {top + 6} L{cx + 22} {top} L{cx + 28} {top + 6} L{cx + 32} {top + 6} '
        f'L{cx + 32} {bot} L{cx - 32} {bot} Z" fill="{AMBER}"/>'
        f'<rect x="{cx - 32}" y="{top + 6}" width="64" height="14" fill="{AMBER_DEEP}" opacity="0.6"/>'
        # Chip silhouettes
        + "".join(
            f'<ellipse cx="{x}" cy="{y}" rx="8" ry="4" fill="{BANANA}" transform="rotate({r} {x} {y})"/>'
            for x, y, r in [(54, 96, -20), (74, 102, 15), (82, 118, -10), (60, 128, 25)]
        )
        + f'<rect x="{cx - 24}" y="148" width="48" height="3" fill="{ESPRESSO_3}"/>'
        # Bottom crimped seal
        + f'<path d="M{cx - 32} {bot - 8} L{cx - 28} {bot - 12} L{cx - 24} {bot - 8} L{cx - 20} {bot - 12} '
        f'L{cx - 16} {bot - 8} L{cx - 12} {bot - 12} L{cx - 8} {bot - 8} L{cx - 4} {bot - 12} '
        f'L{cx} {bot - 8} L{cx + 4} {bot - 12} L{cx + 8} {bot - 8} L{cx + 12} {bot - 12} '
        f'L{cx + 16} {bot - 8} L{cx + 20} {bot - 12} L{cx + 24} {bot - 8} L{cx + 28} {bot - 12} '
        f'L{cx + 32} {bot - 8} L{cx + 32} {bot} L{cx - 32} {bot} Z" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def wafer_pack() -> str:
    cx, top, bot = 70, 40, 196
    waffle = "".join(
        f'<line x1="{cx - 24}" y1="{y}" x2="{cx + 24}" y2="{y}" stroke="{ESPRESSO_3}" stroke-width="1"/>'
        for y in range(96, 152, 6)
    ) + "".join(
        f'<line x1="{x}" y1="92" x2="{x}" y2="156" stroke="{ESPRESSO_3}" stroke-width="1"/>'
        for x in range(50, 92, 6)
    )
    body = (
        f'<rect x="{cx - 30}" y="{top}" width="60" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 30}" y="{top}" width="60" height="12" fill="{BREAD}"/>'
        f'<rect x="{cx - 24}" y="88" width="48" height="68" fill="{BREAD}"/>'
        f'{waffle}'
        f'<rect x="{cx - 24}" y="168" width="48" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def nuts_pack() -> str:
    cx, top, bot = 70, 36, 196
    nuts = "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="5" ry="4" fill="{BREAD_DEEP}"/>'
        f'<ellipse cx="{x - 1}" cy="{y - 1}" rx="2" ry="1.4" fill="{BREAD}" opacity="0.6"/>'
        for x, y in [(56, 100), (70, 108), (84, 102), (58, 122), (72, 128),
                     (84, 122), (62, 144), (78, 148)]
    )
    body = (
        # Transparent pack — show contents through tint
        f'<rect x="{cx - 30}" y="{top}" width="60" height="{bot - top}" rx="3" fill="{MILK}" opacity="0.85"/>'
        f'<rect x="{cx - 30}" y="{top}" width="60" height="14" fill="{BREAD_DEEP}"/>'
        f'<rect x="{cx - 30}" y="{top + 14}" width="60" height="6" fill="{BREAD}" opacity="0.7"/>'
        f'{nuts}'
        f'<rect x="{cx - 30}" y="{bot - 12}" width="60" height="6" fill="{BREAD_DEEP}"/>'
    )
    return svg(body + shadow())


def gum_box() -> str:
    cx, top, bot = 70, 70, 180
    body = (
        f'<rect x="{cx - 24}" y="{top}" width="48" height="{bot - top}" rx="6" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 24}" y="{top}" width="48" height="10" fill="{AMBER}"/>'
        f'<rect x="{cx - 24}" y="{bot - 10}" width="48" height="10" fill="{AMBER}"/>'
        # Stripes
        + "".join(
            f'<rect x="{cx - 24}" y="{y}" width="48" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
            for y in (96, 112, 128, 144)
        )
        + f'<circle cx="{cx}" cy="124" r="6" fill="{AMBER}"/>'
    )
    return svg(body + shadow(rx=24, cy=190))


# --- Kahvaltılık --------------------------------------------------------


def jar_with_content(content_color: str, *, lid_color: str = AMBER, content_extras: str = "") -> str:
    return svg(
        jar(content_color=content_color, lid_color=lid_color, body_w=78, body_top=72,
            content_extras=content_extras)
        + shadow()
    )


def recel_jar() -> str:
    # Strawberry-jam red with seed dots
    seeds = "".join(
        f'<circle cx="{x}" cy="{y}" r="1.2" fill="{BANANA}" opacity="0.7"/>'
        for x, y in [(58, 110), (72, 116), (84, 108), (62, 130), (78, 134),
                     (88, 124), (60, 148), (74, 156), (84, 144)]
    )
    return jar_with_content("#A8341E", lid_color=AMBER, content_extras=seeds)


def bal_jar() -> str:
    glow = (
        f'<ellipse cx="60" cy="100" rx="14" ry="20" fill="#F2D58A" opacity="0.5"/>'
    )
    return jar_with_content("#C8902C", lid_color=AMBER_DEEP, content_extras=glow)


def tahin_jar() -> str:
    swirl = (
        f'<path d="M58 110 Q70 100 84 112 Q78 130 64 130 Q56 124 58 110 Z" fill="{CREAM_2}" opacity="0.65"/>'
    )
    return jar_with_content("#D9C39A", lid_color=AMBER_DEEP, content_extras=swirl)


def pekmez_jar() -> str:
    return jar_with_content("#4A2010", lid_color=AMBER_DEEP, content_extras=(
        f'<ellipse cx="58" cy="110" rx="10" ry="14" fill="#6A3520" opacity="0.7"/>'
    ))


def helva_block() -> str:
    cx = 70
    body = (
        f'<rect x="{cx - 36}" y="64" width="72" height="120" rx="4" fill="{BREAD}"/>'
        # Texture marbling
        f'<path d="M{cx - 28} 84 Q{cx - 8} 92 {cx + 8} 80 Q{cx + 24} 76 {cx + 28} 96" stroke="{AMBER_SOFT}" stroke-width="2" fill="none" opacity="0.65"/>'
        f'<path d="M{cx - 28} 116 Q{cx - 4} 124 {cx + 16} 112 Q{cx + 26} 110 {cx + 28} 124" stroke="{AMBER_SOFT}" stroke-width="2" fill="none" opacity="0.55"/>'
        f'<path d="M{cx - 28} 148 Q{cx} 156 {cx + 28} 144" stroke="{AMBER_SOFT}" stroke-width="2" fill="none" opacity="0.55"/>'
        # Top crumble dots
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="1.4" fill="{AMBER_SOFT}"/>'
            for x, y in [(50, 72), (66, 70), (80, 72), (94, 70)]
        )
    )
    return svg(body + shadow())


def kakao_kreme_jar() -> str:
    return jar_with_content("#3D2113", lid_color=AMBER, content_extras=(
        f'<ellipse cx="60" cy="110" rx="10" ry="14" fill="#5A331E" opacity="0.6"/>'
        f'<path d="M58 130 Q70 124 82 136" stroke="{AMBER_SOFT}" stroke-width="1.5" fill="none" opacity="0.5"/>'
    ))


# --- Temizlik --------------------------------------------------------


def laundry_jug() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Cap
        f'<rect x="{cx - 12}" y="{top - 10}" width="24" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        # Body with side handle
        f'<path d="M{cx - 22} {top} L{cx + 22} {top} L{cx + 30} {top + 16} '
        f'L{cx + 30} {bot - 8} Q{cx + 30} {bot} {cx + 22} {bot} '
        f'L{cx - 22} {bot} Q{cx - 30} {bot} {cx - 30} {bot - 8} '
        f'L{cx - 30} {top + 16} Z" fill="{AMBER}"/>'
        # Handle cutout
        f'<path d="M{cx - 30} {top + 24} Q{cx - 40} {top + 30} {cx - 40} {top + 56} '
        f'Q{cx - 40} {top + 70} {cx - 30} {top + 76} Z" fill="{AMBER}"/>'
        f'<path d="M{cx - 30} {top + 28} Q{cx - 36} {top + 34} {cx - 36} {top + 52} '
        f'Q{cx - 36} {top + 68} {cx - 30} {top + 72}" fill="{CREAM}" stroke="{AMBER_DEEP}" stroke-width="1"/>'
        # Label
        f'<rect x="{cx - 22}" y="100" width="52" height="60" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 16}" y="112" width="40" height="3" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 14}" y="124" width="32" height="2" fill="{AMBER_DEEP}" opacity="0.65"/>'
        f'<circle cx="{cx + 6}" cy="142" r="6" fill="{AMBER}"/>'
    )
    return svg(body + shadow())


def laundry_powder_box() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        # Lid flap
        f'<path d="M{cx - 36} {top - 4} L{cx + 36} {top - 4} L{cx + 32} {top + 8} '
        f'L{cx - 32} {top + 8} Z" fill="{darken(CREAM_2)}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="3" fill="{CREAM_2}"/>'
        # Label band
        f'<rect x="{cx - 36}" y="90" width="72" height="56" fill="{AMBER}"/>'
        # Bubbles
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="{r}" fill="{MILK}" opacity="0.8"/>'
            for x, y, r in [(58, 108, 5), (72, 112, 4), (84, 106, 3.5),
                            (62, 124, 3), (80, 124, 4.5), (70, 134, 3)]
        )
        + f'<rect x="{cx - 28}" y="158" width="56" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def dish_liquid() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Top cap (inverted)
        f'<rect x="{cx - 9}" y="{top - 10}" width="18" height="10" rx="2" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 6}" y="{top - 14}" width="12" height="4" rx="1" fill="{AMBER_DEEP}"/>'
        # Slim tall body
        f'<path d="M{cx - 9} {top} L{cx + 9} {top} L{cx + 22} {top + 18} '
        f'L{cx + 22} {bot - 8} Q{cx + 22} {bot} {cx + 14} {bot} '
        f'L{cx - 14} {bot} Q{cx - 22} {bot} {cx - 22} {bot - 8} '
        f'L{cx - 22} {top + 18} Z" fill="{LEAF}"/>'
        f'<rect x="{cx - 22}" y="86" width="44" height="74" fill="{MILK}" opacity="0.92"/>'
        f'<rect x="{cx - 16}" y="98" width="32" height="3" fill="{LEAF_DEEP}"/>'
        f'<rect x="{cx - 12}" y="108" width="24" height="2" fill="{LEAF_DEEP}" opacity="0.7"/>'
        f'<circle cx="{cx}" cy="130" r="6" fill="{LEAF}"/>'
    )
    return svg(body + shadow())


def dish_tablets_box() -> str:
    cx, top, bot = 70, 40, 192
    tablets = "".join(
        f'<rect x="{cx - 22 + (i % 3) * 16}" y="{102 + (i // 3) * 16}" width="14" height="14" rx="2" fill="{MILK}"/>'
        f'<rect x="{cx - 22 + (i % 3) * 16}" y="{102 + (i // 3) * 16}" width="14" height="4" fill="{CREAM_3}"/>'
        f'<circle cx="{cx - 15 + (i % 3) * 16}" cy="{112 + (i // 3) * 16}" r="2" fill="{TOMATO}"/>'
        for i in range(6)
    )
    body = (
        f'<rect x="{cx - 32}" y="{top}" width="64" height="{bot - top}" rx="3" fill="{LEAF_DEEP}"/>'
        f'<rect x="{cx - 32}" y="{top}" width="64" height="12" fill="{LEAF}"/>'
        f'<rect x="{cx - 28}" y="94" width="56" height="60" fill="{CREAM_2}"/>'
        f'{tablets}'
        f'<rect x="{cx - 24}" y="160" width="48" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow())


def spray_bottle(content: str = AMBER) -> str:
    cx, top, bot = 70, 50, 196
    body = (
        # Trigger head
        f'<rect x="{cx - 18}" y="{top - 16}" width="36" height="16" rx="3" fill="{ESPRESSO_2}"/>'
        f'<path d="M{cx + 14} {top - 14} L{cx + 28} {top - 8} L{cx + 28} {top - 2} L{cx + 14} {top - 4} Z" fill="{ESPRESSO_2}"/>'
        # Neck
        f'<rect x="{cx - 8}" y="{top}" width="16" height="6" fill="{ESPRESSO_3}"/>'
        # Body
        f'<path d="M{cx - 26} {top + 6} L{cx + 26} {top + 6} L{cx + 26} {bot - 8} '
        f'Q{cx + 26} {bot} {cx + 18} {bot} L{cx - 18} {bot} '
        f'Q{cx - 26} {bot} {cx - 26} {bot - 8} Z" fill="{content}"/>'
        # Label
        f'<rect x="{cx - 26}" y="106" width="52" height="56" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 18}" y="118" width="36" height="3" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 14}" y="128" width="28" height="2" fill="{AMBER_DEEP}" opacity="0.65"/>'
        f'<circle cx="{cx}" cy="146" r="5" fill="{AMBER}"/>'
    )
    return svg(body + shadow())


def glass_cleaner() -> str:
    return spray_bottle(content="#7BA2B0")


def soap_bar() -> str:
    cx, top, bot = 70, 56, 180
    body = (
        # Pack wrapper
        f'<rect x="{cx - 40}" y="{top}" width="80" height="{bot - top}" rx="6" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 40}" y="{top}" width="80" height="12" fill="{AMBER}"/>'
        # Soap bar
        f'<ellipse cx="{cx}" cy="{top + 60}" rx="30" ry="18" fill="{MILK}"/>'
        f'<ellipse cx="{cx - 4}" cy="{top + 56}" rx="14" ry="6" fill="{AMBER_SOFT}" opacity="0.5"/>'
        f'<rect x="{cx - 28}" y="{bot - 12}" width="56" height="3" fill="{AMBER_DEEP}"/>'
    )
    return svg(body + shadow(rx=36, cy=192))


def shampoo_bottle() -> str:
    cx, top, bot = 70, 36, 196
    body = (
        # Flip-top cap
        f'<rect x="{cx - 16}" y="{top - 12}" width="32" height="12" rx="3" fill="{ESPRESSO_3}"/>'
        f'<path d="M{cx - 24} {top} L{cx + 24} {top} L{cx + 28} {top + 14} '
        f'L{cx + 28} {bot - 6} Q{cx + 28} {bot} {cx + 22} {bot} '
        f'L{cx - 22} {bot} Q{cx - 28} {bot} {cx - 28} {bot - 6} '
        f'L{cx - 28} {top + 14} Z" fill="{AMBER}"/>'
        f'<rect x="{cx - 28}" y="92" width="56" height="74" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 22}" y="104" width="44" height="3" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 18}" y="114" width="36" height="2" fill="{AMBER_DEEP}" opacity="0.7"/>'
        f'<circle cx="{cx}" cy="138" r="6" fill="{AMBER}"/>'
    )
    return svg(body + shadow())


def toothpaste_tube() -> str:
    cx = 70
    body = (
        # Cap
        f'<rect x="{cx + 36}" y="100" width="12" height="36" rx="2" fill="{ESPRESSO_3}"/>'
        # Tube body
        f'<path d="M{cx + 36} 96 L{cx + 36} 140 L{cx - 40} 144 L{cx - 50} 118 L{cx - 40} 92 Z" '
        f'fill="{CREAM_2}"/>'
        # Crimp
        f'<rect x="{cx - 52}" y="108" width="6" height="20" fill="{AMBER_DEEP}"/>'
        # Label
        f'<rect x="{cx - 28}" y="106" width="56" height="24" fill="{AMBER}"/>'
        f'<rect x="{cx - 20}" y="114" width="40" height="3" fill="{ESPRESSO_2}"/>'
        f'<rect x="{cx - 16}" y="122" width="32" height="2" fill="{ESPRESSO_2}" opacity="0.7"/>'
    )
    return svg(body + shadow(cy=160, rx=44))


def toilet_paper() -> str:
    cx = 70
    body = (
        # Outer roll
        f'<ellipse cx="{cx}" cy="120" rx="46" ry="44" fill="{MILK}"/>'
        # Side highlight
        f'<ellipse cx="{cx - 10}" cy="106" rx="20" ry="10" fill="{CREAM}" opacity="0.7"/>'
        # Inner tube
        f'<ellipse cx="{cx}" cy="120" rx="14" ry="14" fill="{BREAD}"/>'
        f'<ellipse cx="{cx}" cy="120" rx="10" ry="10" fill="{BREAD_DEEP}"/>'
        # Seam line
        f'<path d="M{cx} 76 Q{cx + 30} 96 {cx + 44} 122" stroke="{CREAM_3}" stroke-width="1.5" fill="none"/>'
    )
    return svg(body + shadow(rx=42))


# --- Diğer --------------------------------------------------------


def baby_diaper_pack() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        f'<rect x="{cx - 38}" y="{top}" width="76" height="{bot - top}" rx="6" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 38}" y="{top}" width="76" height="14" fill="{AMBER_SOFT}"/>'
        # Geometric motif (stylized diaper silhouette — abstract chevron)
        f'<path d="M{cx - 24} 90 Q{cx} 80 {cx + 24} 90 L{cx + 28} 120 '
        f'Q{cx} 130 {cx - 28} 120 Z" fill="{MILK}"/>'
        f'<circle cx="{cx}" cy="106" r="6" fill="{AMBER_SOFT}"/>'
        f'<rect x="{cx - 28}" y="140" width="56" height="3" fill="{AMBER}"/>'
        f'<rect x="{cx - 22}" y="150" width="44" height="2" fill="{AMBER_DEEP}" opacity="0.6"/>'
        # Diamond dots
        + "".join(
            f'<rect x="{x}" y="{y}" width="3" height="3" fill="{AMBER_SOFT}" transform="rotate(45 {x + 1.5} {y + 1.5})"/>'
            for x, y in [(50, 168), (66, 168), (82, 168), (58, 178), (74, 178)]
        )
    )
    return svg(body + shadow())


def cat_food_pack() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="6" fill="{AMBER_DEEP}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="14" fill="{ESPRESSO_3}"/>'
        # Paw print
        f'<circle cx="{cx}" cy="108" r="11" fill="{AMBER}"/>'
        f'<circle cx="{cx - 12}" cy="92" r="5" fill="{AMBER}"/>'
        f'<circle cx="{cx + 12}" cy="92" r="5" fill="{AMBER}"/>'
        f'<circle cx="{cx - 18}" cy="106" r="4" fill="{AMBER}"/>'
        f'<circle cx="{cx + 18}" cy="106" r="4" fill="{AMBER}"/>'
        f'<rect x="{cx - 28}" y="138" width="56" height="3" fill="{AMBER_SOFT}"/>'
        f'<rect x="{cx - 22}" y="148" width="44" height="2" fill="{AMBER_SOFT}" opacity="0.7"/>'
        # Kibble dots
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="2" fill="{BREAD}"/>'
            for x, y in [(54, 170), (66, 174), (78, 170), (88, 176), (60, 184), (74, 188)]
        )
    )
    return svg(body + shadow())


def dog_food_pack() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="6" fill="{LEAF_DEEP}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="14" fill="{ESPRESSO_3}"/>'
        f'<circle cx="{cx}" cy="108" r="11" fill="{LEAF_SOFT}"/>'
        f'<circle cx="{cx - 12}" cy="92" r="5" fill="{LEAF_SOFT}"/>'
        f'<circle cx="{cx + 12}" cy="92" r="5" fill="{LEAF_SOFT}"/>'
        f'<circle cx="{cx - 18}" cy="106" r="4" fill="{LEAF_SOFT}"/>'
        f'<circle cx="{cx + 18}" cy="106" r="4" fill="{LEAF_SOFT}"/>'
        f'<rect x="{cx - 28}" y="138" width="56" height="3" fill="{LEAF_SOFT}"/>'
        f'<rect x="{cx - 22}" y="148" width="44" height="2" fill="{LEAF_SOFT}" opacity="0.7"/>'
        + "".join(
            f'<circle cx="{x}" cy="{y}" r="2.4" fill="{BREAD}"/>'
            for x, y in [(54, 170), (66, 174), (78, 170), (88, 176), (60, 184), (74, 188)]
        )
    )
    return svg(body + shadow())


def generic_fallback() -> str:
    cx, top, bot = 70, 40, 196
    body = (
        f'<rect x="{cx - 36}" y="{top}" width="72" height="{bot - top}" rx="8" fill="{CREAM_2}"/>'
        f'<rect x="{cx - 36}" y="{top}" width="72" height="12" fill="{AMBER}"/>'
        # Question/category icon — soft basket silhouette
        f'<path d="M{cx - 24} 110 L{cx + 24} 110 L{cx + 18} 160 L{cx - 18} 160 Z" fill="{AMBER}"/>'
        f'<path d="M{cx - 18} 110 Q{cx - 18} 86 {cx} 86 Q{cx + 18} 86 {cx + 18} 110" '
        f'stroke="{AMBER_DEEP}" stroke-width="3" fill="none"/>'
        f'<line x1="{cx - 18}" y1="124" x2="{cx + 18}" y2="124" stroke="{AMBER_DEEP}" stroke-width="1.4" opacity="0.7"/>'
        f'<line x1="{cx - 14}" y1="138" x2="{cx + 14}" y2="138" stroke="{AMBER_DEEP}" stroke-width="1.4" opacity="0.7"/>'
        f'<line x1="{cx - 10}" y1="152" x2="{cx + 10}" y2="152" stroke="{AMBER_DEEP}" stroke-width="1.4" opacity="0.7"/>'
    )
    return svg(body + shadow())


# ---------------------------------------------------------------------------
# Catalog definition
# ---------------------------------------------------------------------------


@dataclass
class IllustrationDef:
    id: str
    category: str
    category_label: str
    label: str
    tags: list[str]
    builder: Callable[[], str]


# Category icons resolve to Flutter Material icon names recognised by
# MaterialIcons CodepointMap. The picker treats these as advisory.
CATEGORIES = [
    {"id": "icecek", "label": "İçecekler", "icon": "local_drink"},
    {"id": "gida", "label": "Temel Gıda", "icon": "rice_bowl"},
    {"id": "sut", "label": "Süt Ürünleri", "icon": "egg_alt"},
    {"id": "yag", "label": "Yağ & Sirke", "icon": "opacity"},
    {"id": "sebze", "label": "Sebze", "icon": "eco"},
    {"id": "meyve", "label": "Meyve", "icon": "apple"},
    {"id": "et", "label": "Et & Balık", "icon": "set_meal"},
    {"id": "atistirmalik", "label": "Atıştırmalık", "icon": "cookie"},
    {"id": "kahvalti", "label": "Kahvaltılık", "icon": "breakfast_dining"},
    {"id": "temizlik", "label": "Temizlik", "icon": "cleaning_services"},
    {"id": "diger", "label": "Diğer", "icon": "category"},
]


DEFS: list[IllustrationDef] = [
    # İçecekler ----------------------------------------------------------
    IllustrationDef("icecek-karbonatli", "icecek", "İçecekler", "Karbonatlı İçecek",
                    ["kola", "soda", "gazoz", "karbonatlı", "kutu"], soda_can),
    IllustrationDef("icecek-su-pet", "icecek", "İçecekler", "Su (PET)",
                    ["su", "pet", "şişe", "ambalajlı"], pet_water),
    IllustrationDef("icecek-su-cam", "icecek", "İçecekler", "Su (Cam)",
                    ["su", "cam", "şişe", "doğal kaynak"], glass_water),
    IllustrationDef("icecek-sut-karton", "icecek", "İçecekler", "Süt (Karton)",
                    ["süt", "uht", "karton", "tetra"], lambda: tetra_pak(MILK)),
    IllustrationDef("icecek-ayran", "icecek", "İçecekler", "Ayran",
                    ["ayran", "yoğurt içeceği", "kase"], ayran_tub),
    IllustrationDef("icecek-meyve-suyu", "icecek", "İçecekler", "Meyve Suyu",
                    ["meyve suyu", "nektar", "karton"], juice_carton),
    IllustrationDef("icecek-cay-poset", "icecek", "İçecekler", "Poşet Çay",
                    ["çay", "poşet çay", "bardak çayı"], tea_box),
    IllustrationDef("icecek-kahve", "icecek", "İçecekler", "Kahve",
                    ["kahve", "filtre", "çekirdek"], coffee_tin),
    IllustrationDef("icecek-enerji", "icecek", "İçecekler", "Enerji İçeceği",
                    ["enerji içeceği", "kafein", "kutu"], energy_can),
    IllustrationDef("icecek-soguk-cay", "icecek", "İçecekler", "Soğuk Çay",
                    ["soğuk çay", "ice tea", "şeftalili"], cold_tea_pet),

    # Temel Gıda ---------------------------------------------------------
    IllustrationDef("gida-ekmek-somun", "gida", "Temel Gıda", "Ekmek (Somun)",
                    ["ekmek", "somun", "fırın"], bread_loaf),
    IllustrationDef("gida-ekmek-sandvic", "gida", "Temel Gıda", "Sandviç Ekmeği",
                    ["sandviç ekmeği", "tost ekmeği", "kepekli"], sandwich_bread),
    IllustrationDef("gida-yumurta", "gida", "Temel Gıda", "Yumurta",
                    ["yumurta", "kahvaltı", "10'lu", "viyol"], egg_carton),
    IllustrationDef("gida-pirinc", "gida", "Temel Gıda", "Pirinç",
                    ["pirinç", "baldo", "osmancık"], rice_pack),
    IllustrationDef("gida-makarna", "gida", "Temel Gıda", "Makarna",
                    ["makarna", "spagetti", "burgu"], pasta_pack),
    IllustrationDef("gida-bulgur", "gida", "Temel Gıda", "Bulgur",
                    ["bulgur", "köftelik", "pilavlık"], bulgur_pack),
    IllustrationDef("gida-mercimek", "gida", "Temel Gıda", "Mercimek",
                    ["mercimek", "kırmızı mercimek", "yeşil mercimek"], mercimek_pack),
    IllustrationDef("gida-nohut", "gida", "Temel Gıda", "Nohut",
                    ["nohut", "leblebi"], nohut_pack),
    IllustrationDef("gida-un", "gida", "Temel Gıda", "Un",
                    ["un", "buğday", "tam buğday"], flour_sack),
    IllustrationDef("gida-seker", "gida", "Temel Gıda", "Şeker",
                    ["şeker", "küp şeker", "toz şeker"], sugar_pack),
    IllustrationDef("gida-tuz", "gida", "Temel Gıda", "Tuz",
                    ["tuz", "iyotlu", "kaya tuzu"], salt_carton),
    IllustrationDef("gida-zeytin", "gida", "Temel Gıda", "Zeytin",
                    ["zeytin", "siyah zeytin", "yeşil zeytin"], olive_jar),

    # Süt Ürünleri & Yağ ------------------------------------------------
    IllustrationDef("sut-yogurt", "sut", "Süt Ürünleri", "Yoğurt",
                    ["yoğurt", "süzme", "kase"], yogurt_tub),
    IllustrationDef("sut-peynir-beyaz", "sut", "Süt Ürünleri", "Beyaz Peynir",
                    ["beyaz peynir", "ezine", "salamura"], cheese_white),
    IllustrationDef("sut-peynir-kasar", "sut", "Süt Ürünleri", "Kaşar Peyniri",
                    ["kaşar", "tost peyniri", "eski kaşar"], cheese_kasar),
    IllustrationDef("sut-tereyag", "sut", "Süt Ürünleri", "Tereyağı",
                    ["tereyağı", "süt yağı"], butter_pack),
    IllustrationDef("sut-krema", "sut", "Süt Ürünleri", "Krema",
                    ["krema", "süt kreması", "pasta kreması"], cream_bottle),
    IllustrationDef("yag-sivi-ayicicegi", "yag", "Yağ & Sirke", "Ayçiçek Yağı",
                    ["yağ", "ayçiçek yağı", "sıvı yağ"], sunflower_oil),
    IllustrationDef("yag-zeytinyagi", "yag", "Yağ & Sirke", "Zeytinyağı",
                    ["zeytinyağı", "natürel sızma"], olive_oil_bottle),
    IllustrationDef("yag-sirke", "yag", "Yağ & Sirke", "Sirke",
                    ["sirke", "üzüm sirkesi", "elma sirkesi"], vinegar_bottle),

    # Sebze --------------------------------------------------------------
    IllustrationDef("sebze-domates", "sebze", "Sebze", "Domates",
                    ["domates", "salata", "soslu"], tomato),
    IllustrationDef("sebze-salatalik", "sebze", "Sebze", "Salatalık",
                    ["salatalık", "hıyar"], cucumber),
    IllustrationDef("sebze-patates", "sebze", "Sebze", "Patates",
                    ["patates", "kızartmalık"], potato),
    IllustrationDef("sebze-sogan", "sebze", "Sebze", "Soğan",
                    ["soğan", "kuru soğan"], onion),
    IllustrationDef("sebze-sarimsak", "sebze", "Sebze", "Sarımsak",
                    ["sarımsak"], garlic),
    IllustrationDef("sebze-biber-yesil", "sebze", "Sebze", "Yeşil Biber",
                    ["yeşil biber", "sivri biber", "çarliston"], lambda: pepper(LEAF, LEAF_DEEP)),
    IllustrationDef("sebze-biber-kirmizi", "sebze", "Sebze", "Kırmızı Biber",
                    ["kırmızı biber", "kapya"], lambda: pepper(TOMATO, TOMATO_DEEP)),
    IllustrationDef("sebze-patlican", "sebze", "Sebze", "Patlıcan",
                    ["patlıcan"], eggplant),
    IllustrationDef("sebze-kabak", "sebze", "Sebze", "Kabak",
                    ["kabak", "sakız kabak"], zucchini),
    IllustrationDef("sebze-marul", "sebze", "Sebze", "Marul",
                    ["marul", "yeşillik", "salata"], lettuce),

    # Meyve --------------------------------------------------------------
    IllustrationDef("meyve-elma", "meyve", "Meyve", "Elma",
                    ["elma"], apple),
    IllustrationDef("meyve-muz", "meyve", "Meyve", "Muz",
                    ["muz"], banana),
    IllustrationDef("meyve-portakal", "meyve", "Meyve", "Portakal",
                    ["portakal"], orange),
    IllustrationDef("meyve-mandalina", "meyve", "Meyve", "Mandalina",
                    ["mandalina"], mandalina),
    IllustrationDef("meyve-uzum", "meyve", "Meyve", "Üzüm",
                    ["üzüm", "salkım"], grapes),
    IllustrationDef("meyve-karpuz", "meyve", "Meyve", "Karpuz",
                    ["karpuz"], watermelon),
    IllustrationDef("meyve-cilek", "meyve", "Meyve", "Çilek",
                    ["çilek"], strawberry),
    IllustrationDef("meyve-limon", "meyve", "Meyve", "Limon",
                    ["limon"], lemon),

    # Et & Balık ---------------------------------------------------------
    IllustrationDef("et-tavuk", "et", "Et & Balık", "Tavuk",
                    ["tavuk", "but", "göğüs"], chicken_pack),
    IllustrationDef("et-kirmizi", "et", "Et & Balık", "Kırmızı Et",
                    ["dana", "kuzu", "biftek", "kırmızı et"], red_meat_pack),
    IllustrationDef("et-kiyma", "et", "Et & Balık", "Kıyma",
                    ["kıyma", "köftelik"], ground_meat_pack),
    IllustrationDef("et-balik", "et", "Et & Balık", "Balık",
                    ["balık", "hamsi", "levrek"], fish),

    # Atıştırmalık ------------------------------------------------------
    IllustrationDef("atistirmalik-cikolata-tablet", "atistirmalik", "Atıştırmalık", "Tablet Çikolata",
                    ["çikolata", "tablet", "sütlü çikolata"], chocolate_tablet),
    IllustrationDef("atistirmalik-cikolata-bar", "atistirmalik", "Atıştırmalık", "Çikolata Bar",
                    ["çikolata bar", "bar"], chocolate_bar),
    IllustrationDef("atistirmalik-biskuvi", "atistirmalik", "Atıştırmalık", "Bisküvi",
                    ["bisküvi", "kurabiye"], biscuit_roll),
    IllustrationDef("atistirmalik-kraker", "atistirmalik", "Atıştırmalık", "Kraker",
                    ["kraker", "tuzlu"], cracker_pack),
    IllustrationDef("atistirmalik-cips", "atistirmalik", "Atıştırmalık", "Cips",
                    ["cips", "patates cipsi"], chips_bag),
    IllustrationDef("atistirmalik-gofret", "atistirmalik", "Atıştırmalık", "Gofret",
                    ["gofret", "wafer"], wafer_pack),
    IllustrationDef("atistirmalik-kuruyemis", "atistirmalik", "Atıştırmalık", "Kuruyemiş",
                    ["kuruyemiş", "fıstık", "fındık", "badem"], nuts_pack),
    IllustrationDef("atistirmalik-sakiz", "atistirmalik", "Atıştırmalık", "Sakız",
                    ["sakız"], gum_box),

    # Kahvaltılık -------------------------------------------------------
    IllustrationDef("kahvalti-recel", "kahvalti", "Kahvaltılık", "Reçel",
                    ["reçel", "kavanoz"], recel_jar),
    IllustrationDef("kahvalti-bal", "kahvalti", "Kahvaltılık", "Bal",
                    ["bal", "süzme bal"], bal_jar),
    IllustrationDef("kahvalti-tahin", "kahvalti", "Kahvaltılık", "Tahin",
                    ["tahin", "susam"], tahin_jar),
    IllustrationDef("kahvalti-pekmez", "kahvalti", "Kahvaltılık", "Pekmez",
                    ["pekmez", "üzüm pekmezi"], pekmez_jar),
    IllustrationDef("kahvalti-helva", "kahvalti", "Kahvaltılık", "Helva",
                    ["helva", "tahin helvası"], helva_block),
    IllustrationDef("kahvalti-kakao-kreme", "kahvalti", "Kahvaltılık", "Kakao Kreması",
                    ["kakao kreması", "fındık kreması", "sürülebilir"], kakao_kreme_jar),

    # Temizlik ----------------------------------------------------------
    IllustrationDef("temizlik-camasir-sivi", "temizlik", "Temizlik", "Çamaşır Deterjanı (Sıvı)",
                    ["çamaşır", "sıvı deterjan"], laundry_jug),
    IllustrationDef("temizlik-camasir-toz", "temizlik", "Temizlik", "Çamaşır Deterjanı (Toz)",
                    ["çamaşır", "toz deterjan"], laundry_powder_box),
    IllustrationDef("temizlik-bulasik-sivi", "temizlik", "Temizlik", "Bulaşık Deterjanı (Sıvı)",
                    ["bulaşık deterjanı", "sıvı"], dish_liquid),
    IllustrationDef("temizlik-bulasik-tablet", "temizlik", "Temizlik", "Bulaşık Tableti",
                    ["bulaşık tableti", "makine"], dish_tablets_box),
    IllustrationDef("temizlik-yuzey", "temizlik", "Temizlik", "Yüzey Temizleyici",
                    ["yüzey", "sprey", "temizleyici"], lambda: spray_bottle(AMBER)),
    IllustrationDef("temizlik-cam", "temizlik", "Temizlik", "Cam Temizleyici",
                    ["cam", "cam sileceği", "sprey"], glass_cleaner),
    IllustrationDef("temizlik-sabun", "temizlik", "Temizlik", "Sabun",
                    ["sabun", "kalıp sabun"], soap_bar),
    IllustrationDef("temizlik-sampuan", "temizlik", "Temizlik", "Şampuan",
                    ["şampuan", "saç bakımı"], shampoo_bottle),
    IllustrationDef("temizlik-dis-macunu", "temizlik", "Temizlik", "Diş Macunu",
                    ["diş macunu", "ağız bakımı"], toothpaste_tube),
    IllustrationDef("temizlik-tuvalet-kagidi", "temizlik", "Temizlik", "Tuvalet Kağıdı",
                    ["tuvalet kağıdı", "rulo"], toilet_paper),

    # Diğer -------------------------------------------------------------
    IllustrationDef("diger-bebek-bezi", "diger", "Diğer", "Bebek Bezi",
                    ["bebek bezi", "bebek"], baby_diaper_pack),
    IllustrationDef("diger-kedi-mamasi", "diger", "Diğer", "Kedi Maması",
                    ["kedi maması", "evcil"], cat_food_pack),
    IllustrationDef("diger-kopek-mamasi", "diger", "Diğer", "Köpek Maması",
                    ["köpek maması", "evcil"], dog_food_pack),
    IllustrationDef("diger-genel", "diger", "Diğer", "Genel (Fallback)",
                    ["genel", "fallback", "varsayılan"], generic_fallback),
]


# ---------------------------------------------------------------------------
# Optimisation + writing
# ---------------------------------------------------------------------------


_SPACE_RE = re.compile(r"\s+")


def _compress(svg_text: str) -> str:
    """Collapse interior whitespace; SVG attributes are quoted so it's safe."""
    head_marker = "-->\n"
    if head_marker in svg_text:
        head, body = svg_text.split(head_marker, 1)
        head = head + "-->"
        body = body.lstrip()
    else:
        head, body = "", svg_text
    body = _SPACE_RE.sub(" ", body)
    body = body.replace("> <", "><")
    if head:
        return head + "\n" + body + "\n"
    return body + "\n"


def write_all() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    manifest_items: list[dict] = []
    sizes: list[tuple[str, int]] = []
    for d in DEFS:
        markup = _compress(d.builder())
        # Forbid stray text elements
        if "<text" in markup or "&lt;text" in markup:
            raise RuntimeError(f"Illustration {d.id} contains a text element — forbidden.")
        path = OUT_DIR / f"{d.id}.svg"
        path.write_text(markup, encoding="utf-8")
        sizes.append((d.id, len(markup)))
        manifest_items.append({
            "id": d.id,
            "fileName": f"{d.id}.svg",
            "category": d.category,
            "categoryLabel": d.category_label,
            "label": d.label,
            "tags": d.tags,
            "createdAt": today,
        })
    manifest = {
        "version": "1.0.0",
        "generatedAt": today,
        "illustrations": manifest_items,
        "categories": CATEGORIES,
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    over = [(i, s) for i, s in sizes if s > 4096]
    print(f"Wrote {len(DEFS)} illustrations to {OUT_DIR}")
    if over:
        print(f"WARNING: {len(over)} files exceed 4KB:")
        for i, s in over:
            print(f"  {i}: {s} bytes")
    else:
        max_id, max_size = max(sizes, key=lambda t: t[1])
        print(f"All files under 4KB. Largest: {max_id} ({max_size} bytes).")
    # Sanity: ensure every catalog id appears exactly once.
    ids = [d.id for d in DEFS]
    if len(set(ids)) != len(ids):
        dupes = {x for x in ids if ids.count(x) > 1}
        raise RuntimeError(f"Duplicate illustration ids: {dupes}")
    print(f"Catalog covers {len(CATEGORIES)} categories, {len(ids)} illustrations.")


if __name__ == "__main__":
    write_all()

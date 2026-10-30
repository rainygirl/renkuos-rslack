# -*- coding: utf-8 -*-
"""Generate the R Slack HVIF icon: Slack's mark as a solid object, turned the
way BeOS and Haiku draw things.

The mark is its eight pieces -- four pills and four nubs in blue, green,
yellow and red -- laid on the isometric plane the other R applications use
(R Twitter's box lid, R Departures' board), each given a thickness, so the
flanks show: the face is the colour, the flank facing down-left a shade
darker, the one facing down-right darker still. Pieces are drawn back to
front.

Writes RSlack.rdef's vector_icon resource and assets/RSlack.hvif.
"""

import io
import math
import os
import re


def coord(value):
    """One byte for a whole number, else HVIF's two-byte form, 1/102 px."""
    if value == int(value) and 0 <= value + 32 <= 127:
        return bytes([int(value) + 32])
    encoded = int(round((value + 128.0) * 102.0))
    if not 0 <= encoded <= 0x7FFF:
        raise ValueError("HVIF coordinate outside the two-byte range")
    return bytes([0x80 | (encoded >> 8), encoded & 0xFF])


def polygon(points):
    data = bytearray([0x0A, len(points)])
    for x, y in points:
        data += coord(round(x, 2)) + coord(round(y, 2))
    return data


# The mark on a 5x5 grid, pieces one unit thick: (colour, x0, y0, x1, y1).
# Each colour is a pill and the nub beside its end, pinwheeling round the
# centre: blue upper left, green upper right, yellow lower right, red lower
# left.
PIECES = [
    (0, 1.2, 0.0, 2.2, 2.6), (0, 0.0, 1.6, 1.0, 2.6),
    (1, 2.4, 1.2, 5.0, 2.2), (1, 2.4, 0.0, 3.4, 1.0),
    (2, 2.8, 2.4, 3.8, 5.0), (2, 4.0, 2.4, 5.0, 3.4),
    (3, 0.0, 2.8, 2.6, 3.8), (3, 1.6, 4.0, 2.6, 5.0),
]
COLOURS = [
    (54, 197, 240),   # blue
    (46, 182, 125),   # green
    (236, 178, 46),   # yellow
    (224, 30, 90),    # red
]
THICKNESS = 5.0       # pixels the pieces stand off the plane


def shade(colour, factor):
    return tuple(int(round(c * factor)) for c in colour) + (255,)


def rounded_rect(x0, y0, x1, y1, radius, steps=4):
    """Corners rounded with `radius`; a pill when radius is half the width."""
    radius = min(radius, (x1 - x0) / 2.0, (y1 - y0) / 2.0)
    corners = [
        (x1 - radius, y0 + radius, -90.0),
        (x1 - radius, y1 - radius, 0.0),
        (x0 + radius, y1 - radius, 90.0),
        (x0 + radius, y0 + radius, 180.0),
    ]
    points = []
    for cx, cy, start in corners:
        for s in range(steps + 1):
            a = math.radians(start + 90.0 * s / steps)
            points.append((cx + radius * math.cos(a), cy + radius * math.sin(a)))
    return points


def project(gx, gy):
    """The grid on the isometric plane: +x runs down to the right, +y down
    to the left, as on the lids of the other R icons."""
    u = gx / 5.0
    v = gy / 5.0
    return (32.0 + 30.0 * u - 30.0 * v, 16.0 + 15.0 * u + 15.0 * v)


def build_icon():
    styles = []
    shapes = []

    def style(rgba):
        if rgba not in styles:
            styles.append(rgba)
        return styles.index(rgba)

    def add(rgba, points):
        shapes.append((style(rgba), points))

    order = sorted(PIECES, key=lambda p: (p[1] + p[3]) + (p[2] + p[4]))
    for colour, x0, y0, x1, y1 in order:
        # Pills have fully round ends; nubs are squarer.
        is_pill = max(x1 - x0, y1 - y0) > 1.5
        outline = rounded_rect(x0, y0, x1, y1, 0.5 if is_pill else 0.32)
        top = [project(x, y) for x, y in outline]
        # Orientation, for which way each edge faces.
        area = sum(a[0] * b[1] - b[0] * a[1]
                   for a, b in zip(top, top[1:] + top[:1]))
        base = COLOURS[colour]
        for a, b in zip(top, top[1:] + top[:1]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            # Outward normal on screen; only edges facing down show a flank.
            nx, ny = (dy, -dx) if area > 0 else (-dy, dx)
            if ny <= 0:
                continue
            factor = 0.72 if nx < 0 else 0.55
            add(shade(base, factor), [a, b, (b[0], b[1] + THICKNESS),
                                      (a[0], a[1] + THICKNESS)])
        add(shade(base, 1.0), top)

    # Fill the icon the way the other R icons do: scale the drawing to a
    # 2-pixel margin across, and centre it. Thickness scales with it.
    xs = [x for _, points in shapes for x, _ in points]
    ys = [y for _, points in shapes for _, y in points]
    scale = min(60.0 / (max(xs) - min(xs)), 60.0 / (max(ys) - min(ys)))
    dx = 32.0 - scale * (max(xs) + min(xs)) / 2.0
    dy = 32.0 - scale * (max(ys) + min(ys)) / 2.0
    shapes[:] = [(s, [(x * scale + dx, y * scale + dy) for x, y in points])
                 for s, points in shapes]

    output = bytearray(b"ncif")
    output.append(len(styles))
    for colour in styles:
        output.append(1)
        output += bytes(colour)
    output.append(len(shapes))
    for _, points in shapes:
        output += polygon(points)
    output.append(len(shapes))
    for index, (style_index, _) in enumerate(shapes):
        output += bytes([0x0A, style_index, 1, index, 0])
    return bytes(output)


def resource(data):
    value = "".join("%02X" % byte for byte in data)
    lines = ["resource vector_icon {"]
    lines += [
        '\t$"%s"' % value[index:index + 64]
        for index in range(0, len(value), 64)
    ]
    lines.append("};")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    project_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    path = os.path.join(project_dir, "RSlack.rdef")
    text = io.open(path, encoding="utf-8").read()
    block = re.compile(r"^resource vector_icon \{.*?^\};\n?", re.S | re.M)
    if len(block.findall(text)) != 1:
        raise SystemExit("RSlack.rdef: expected one vector_icon resource")
    data = build_icon()
    io.open(path, "w", encoding="utf-8").write(
        block.sub(lambda _: resource(data), text, count=1))
    # The same bytes as a file, for the BEOS:ICON attribute.
    with open(os.path.join(project_dir, "assets", "RSlack.hvif"), "wb") as f:
        f.write(data)
    print("RSlack.rdef, assets/RSlack.hvif: wrote %d-byte HVIF" % len(data))

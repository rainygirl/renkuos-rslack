# -*- coding: utf-8 -*-
"""Generate the R Slack HVIF icon: Slack's four-colour mark printed on the
low isometric box the R applications share (see R Twitter's make_icon.py).

Writes RSlack.rdef's vector_icon resource and assets/RSlack.hvif.
"""

import io
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
        data += coord(x) + coord(y)
    return data


def on_lid(gx, gy):
    """A point of a 4x4 grid inset on the box's lid, projected like the box."""
    u = 0.12 + (gx / 4.0) * 0.76
    v = 0.12 + (gy / 4.0) * 0.76
    return (32.0 + 26.0 * u - 26.0 * v, 9.0 + 13.0 * u + 13.0 * v)


# Each colour is drawn a little inside its cells, so that the colours stay
# apart at 16 px as they do in the mark.
GAP = 0.12


def lid(points):
    return [on_lid(x, y) for x, y in points]


def build_icon():
    styles = [
        (244, 240, 244, 255),  # lid
        (110, 52, 112, 255),   # left side, Slack aubergine
        (74, 21, 75, 255),     # right side
        (45, 12, 46, 255),     # lower rim shadow
        (54, 197, 240, 255),   # blue
        (46, 182, 125, 255),   # green
        (236, 178, 46, 255),   # yellow
        (224, 30, 90, 255),    # red
    ]
    shapes = []

    def add(style, points):
        shapes.append((style, points))

    far = (32, 9)
    right = (58, 22)
    near = (32, 35)
    left = (6, 22)
    depth = 7

    add(3, [(7, 24), (32, 37), (57, 24),
            (57, 31), (32, 44), (7, 31)])
    add(1, [left, near, (32, near[1] + depth),
            (left[0], left[1] + depth)])
    add(2, [right, near, (32, near[1] + depth),
            (right[0], right[1] + depth)])
    add(0, [far, right, near, left])

    # The mark is a pinwheel of four L shapes, a bar and the nub beside its
    # end, on a 4x4 grid: blue upper left, green upper right, yellow lower
    # right, red lower left.
    g = GAP
    add(4, lid([(1 + g, g), (2 - g, g), (2 - g, 2 - g), (g, 2 - g),
                (g, 1 + g), (1 + g, 1 + g)]))
    add(5, lid([(2 + g, g), (3 - g, g), (3 - g, 1 + g), (4 - g, 1 + g),
                (4 - g, 2 - g), (2 + g, 2 - g)]))
    add(6, lid([(2 + g, 2 + g), (4 - g, 2 + g), (4 - g, 3 - g),
                (3 - g, 3 - g), (3 - g, 4 - g), (2 + g, 4 - g)]))
    add(7, lid([(g, 2 + g), (2 - g, 2 + g), (2 - g, 4 - g), (1 + g, 4 - g),
                (1 + g, 3 - g), (g, 3 - g)]))

    output = bytearray(b"ncif")
    output.append(len(styles))
    for color in styles:
        output.append(1)
        output += bytes(color)
    output.append(len(shapes))
    for _, points in shapes:
        output += polygon(points)
    output.append(len(shapes))
    for index, (style, _) in enumerate(shapes):
        output += bytes([0x0A, style, 1, index, 0])
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
    project = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    path = os.path.join(project, "RSlack.rdef")
    text = io.open(path, encoding="utf-8").read()
    block = re.compile(r"^resource vector_icon \{.*?^\};\n?", re.S | re.M)
    if len(block.findall(text)) != 1:
        raise SystemExit("RSlack.rdef: expected one vector_icon resource")
    data = build_icon()
    io.open(path, "w", encoding="utf-8").write(
        block.sub(lambda _: resource(data), text, count=1))
    # The same bytes as a file, for the BEOS:ICON attribute.
    with open(os.path.join(project, "assets", "RSlack.hvif"), "wb") as f:
        f.write(data)
    print("RSlack.rdef, assets/RSlack.hvif: wrote %d-byte HVIF" % len(data))

"""Folha de prova dos ícones, para olhar antes de aceitar o que o gerador fez.

    python3 tool/preview_icons.py [saida.png]

Mostra os tamanhos reais do launcher, uma ampliação do menor, e a camada de
frente sob as duas máscaras que o Android aplica — com o círculo seguro de
66dp desenhado por cima, que é o que diz se algum canto vai ser cortado.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import generate_icons as g

BG = (236, 238, 242)
PAD = 26


def masked(shape, size=260, guide=True):
    """A camada de frente sobre o fundo, recortada como o sistema recorta."""
    canvas = Image.new("RGBA", (size, size), g.BRAND)
    canvas.alpha_composite(g.render(size, framed=False,
                                    mark_fraction=g.ADAPTIVE_MARK_FRACTION))

    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    # A área visível é 72 dos 108dp do canvas.
    inset = size * (1 - 72 / 108) / 2
    box = [(inset, inset), (size - inset, size - inset)]
    if shape == "circle":
        draw.ellipse(box, fill=255)
    else:
        draw.rounded_rectangle(box, radius=size * 0.16, fill=255)
    canvas.putalpha(mask)

    flat = Image.new("RGB", (size, size), BG)
    flat.paste(canvas, (0, 0), canvas)

    if guide:
        # O círculo seguro de 66dp: nada crítico deve cruzá-lo.
        safe = size * (1 - 66 / 108) / 2
        ImageDraw.Draw(flat).ellipse(
            [(safe, safe), (size - safe, size - safe)],
            outline=(226, 74, 74), width=2)
    return flat


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "icon_preview.png")

    sizes = [48, 72, 96, 144, 192]
    row_w = sum(sizes) + PAD * (len(sizes) - 1)
    sheet = Image.new("RGB", (PAD * 2 + max(row_w, 260 * 3 + PAD * 2),
                              PAD * 3 + 192 + 260), BG)

    x = PAD
    for size in sizes:
        icon = g.render(size, framed=True)
        sheet.paste(icon, (x, PAD + (192 - size)), icon)
        x += size + PAD

    y = PAD * 2 + 192
    sheet.paste(masked("circle"), (PAD, y))
    sheet.paste(masked("squircle"), (PAD * 2 + 260, y))

    mono = g.render(260, framed=False, mono=True,
                    mark_fraction=g.ADAPTIVE_MARK_FRACTION)
    plate = Image.new("RGBA", (260, 260), (58, 60, 68, 255))
    plate.alpha_composite(mono)
    sheet.paste(plate.convert("RGB"), (PAD * 3 + 520, y))

    sheet.save(out)
    print(f"{out}  {sheet.size[0]}x{sheet.size[1]}")


if __name__ == "__main__":
    main()

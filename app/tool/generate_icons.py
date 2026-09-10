"""Gera os ícones do app Faturas a partir de código, não de um PNG editado à mão.

A marca é um recibo com um selo de "confere" — o recibo é o que o app mostra,
o selo é a conferência contra a fatura do banco, que é o que ele faz de
diferente.

Rodar depois de mexer na geometria:

    python3 tool/generate_icons.py

Saída (todos sobrescritos):
  android/.../mipmap-*/ic_launcher.png             ícone legado, com a própria moldura
  android/.../mipmap-*/ic_launcher_foreground.png  camada de frente do adaptive icon
  android/.../mipmap-*/ic_launcher_monochrome.png  silhueta para o tema do Android 13+
  ../play_store_512.png                            arte para a Play Store

Não há rasterizador de SVG nesta máquina (rsvg/inkscape/ImageMagick), então o
desenho é feito no PIL e ampliado 4x antes de reduzir — é o que dá a borda
suave sem depender de ferramenta externa.
"""

from pathlib import Path

from PIL import Image, ImageDraw

# ── Paleta ───────────────────────────────────────────────────────────────
# O azul é o mesmo `AppColors.seed` do app; o verde é o `iconTint(hueSavings)`,
# a cor que a conferência já usa no estado "Confere".
BRAND = (41, 124, 239, 255)
PAPER = (255, 255, 255, 255)
INK = (41, 124, 239, 255)
BADGE = (29, 158, 117, 255)

SS = 4  # supersampling: desenha grande, reduz com LANCZOS

# ── Geometria, num quadro de 100x100 ─────────────────────────────────────
# Tudo é proporção. Mudar um número aqui vale para todos os tamanhos.
# O recibo é mais alto que largo, como um de verdade, e ocupa a metade
# esquerda; o selo entra pelo canto inferior direito. As duas formas juntas
# preenchem o quadro, o que evita canto vazio.
RECEIPT = (1.0, 0.0, 48.0, 68.0)   # x0, y0, x1, y1
RECEIPT_RADIUS = 6.0
# Poucos dentes largos leem como onda; quatro mais fundos leem como
# recibo destacado. Abaixo de mdpi eles somem de qualquer jeito, e a
# silhueta ainda funciona.
TEETH = 4
TOOTH_DEPTH = 11.0

LINES = [(9.0, 15.0, 25.0, 6.5), (9.0, 29.0, 31.0, 6.5)]  # x, y, w, h

BADGE_CENTER = (68.0, 68.0)
BADGE_RADIUS = 26.0
BADGE_RING = 6.0
CHECK = [(56.0, 68.5), (65.0, 77.5), (81.0, 58.0)]
CHECK_WIDTH = 8.5

# Quanto do canvas de 108dp a marca ocupa na camada de frente.
#
# O sistema recorta o adaptive icon com uma máscara que o fabricante escolhe
# — círculo, squircle, gota — e só o círculo central de 66dp é garantido. O
# ponto mais distante do centro nesta arte é o canto superior esquerdo do
# recibo, a 70 unidades do quadro de 100; para ele caber no raio de 33dp, a
# marca não passa de 47dp. Daí 0.44, com uma folga para o efeito de parallax
# que alguns launchers aplicam.
#
# Conferir com `python3 tool/preview_icons.py` depois de mexer na geometria:
# uma composição mais diagonal empurra esse número para baixo.
ADAPTIVE_MARK_FRACTION = 0.44

ANDROID_RES = Path("android/app/src/main/res")
LEGACY_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# O adaptive icon tem 108dp de lado, dos quais só os 72dp centrais aparecem.
ADAPTIVE_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


class Mark:
    """Converte as coordenadas do quadro 100x100 para pixels de uma caixa."""

    def __init__(self, box):
        x0, y0, side = box
        self.x0, self.y0, self.scale = x0, y0, side / 100.0

    def p(self, x, y):
        return (self.x0 + x * self.scale, self.y0 + y * self.scale)

    def n(self, value):
        return value * self.scale

    def rect(self, x0, y0, x1, y1):
        return [self.p(x0, y0), self.p(x1, y1)]

    def circle(self, center, radius):
        cx, cy = center
        return self.rect(cx - radius, cy - radius, cx + radius, cy + radius)


def _teeth_cut(m):
    """Polígono que recorta o serrilhado do rodapé do recibo."""
    x0, _, x1, y1 = RECEIPT
    step = (x1 - x0) / (TEETH * 2)
    top = [
        (x0 + i * step, y1 - TOOTH_DEPTH if i % 2 else y1)
        for i in range(TEETH * 2 + 1)
    ]
    below = [(x1, y1 + TOOTH_DEPTH), (x0, y1 + TOOTH_DEPTH)]
    return [m.p(x, y) for x, y in top + below]


def _paint(draw, m, *, mono):
    """Desenha a marca. Em [mono] tudo vira uma silhueta só, com os vãos
    vazados — é o que o tema do Android 13+ pinta com a cor do sistema."""
    paper = PAPER if not mono else (255, 255, 255, 255)
    hole = (0, 0, 0, 0)

    draw.rounded_rectangle(m.rect(*RECEIPT), radius=m.n(RECEIPT_RADIUS), fill=paper,
                           corners=(True, True, False, False))
    draw.polygon(_teeth_cut(m), fill=hole)

    for x, y, w, h in LINES:
        draw.rounded_rectangle(m.rect(x, y, x + w, y + h), radius=m.n(h / 2),
                               fill=hole if mono else INK)

    # O anel é um vão no mono e uma borda branca no colorido: nos dois casos
    # é ele que separa o selo do recibo por baixo.
    draw.ellipse(m.circle(BADGE_CENTER, BADGE_RADIUS + BADGE_RING),
                 fill=hole if mono else PAPER)
    draw.ellipse(m.circle(BADGE_CENTER, BADGE_RADIUS), fill=paper if mono else BADGE)
    check_color = hole if mono else PAPER
    draw.line([m.p(*pt) for pt in CHECK], fill=check_color,
              width=round(m.n(CHECK_WIDTH)), joint="curve")

    # `joint="curve"` arredonda só o cotovelo; as duas pontas ficam retas e
    # precisam de um disco cada uma.
    for point in (CHECK[0], CHECK[-1]):
        draw.ellipse(m.circle(point, CHECK_WIDTH / 2), fill=check_color)


def render(size, *, framed, mono=False, mark_fraction=0.62):
    """Uma arte quadrada de [size] px. [framed] desenha a moldura azul do
    ícone legado; sem ela o fundo fica transparente, que é o que as camadas
    do adaptive icon precisam."""
    big = size * SS
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    if framed:
        draw.rounded_rectangle([(0, 0), (big - 1, big - 1)], radius=big * 0.22, fill=BRAND)

    side = big * mark_fraction
    offset = (big - side) / 2
    _paint(draw, Mark((offset, offset, side)), mono=mono)

    return image.resize((size, size), Image.LANCZOS)


# ── SVG para o logo dentro do app ────────────────────────────────────────
# Sai das mesmas constantes que os PNGs: o logo da tela de boas-vindas e o
# ícone do launcher não têm como divergir sem alguém editar a geometria acima.

def _fmt(value):
    return f"{value:.2f}".rstrip("0").rstrip(".")


def _receipt_path():
    """Contorno do recibo: cantos de cima arredondados, rodapé serrilhado."""
    x0, y0, x1, y1 = RECEIPT
    r = RECEIPT_RADIUS
    step = (x1 - x0) / (TEETH * 2)

    parts = [
        f"M{_fmt(x0 + r)} {_fmt(y0)}",
        f"H{_fmt(x1 - r)}",
        f"A{_fmt(r)} {_fmt(r)} 0 0 1 {_fmt(x1)} {_fmt(y0 + r)}",
        f"V{_fmt(y1)}",
    ]
    # Volta pelo rodapé, da direita para a esquerda.
    for i in range(TEETH * 2 - 1, -1, -1):
        x = x0 + i * step
        y = y1 - TOOTH_DEPTH if i % 2 else y1
        parts.append(f"L{_fmt(x)} {_fmt(y)}")
    parts.append(f"V{_fmt(y0 + r)}")
    parts.append(f"A{_fmt(r)} {_fmt(r)} 0 0 1 {_fmt(x0 + r)} {_fmt(y0)}")
    parts.append("Z")
    return "".join(parts)


def svg(mark_fraction=0.62):
    """A marca com a moldura azul, no mesmo enquadramento do ícone legado."""
    side = 100 * mark_fraction
    off = (100 - side) / 2
    k = side / 100.0

    def px(x, y):
        return _fmt(off + x * k), _fmt(off + y * k)

    def hex_of(rgba):
        return "#%02X%02X%02X" % rgba[:3]

    lines = []
    for x, y, w, h in LINES:
        lx, ly = px(x, y)
        lines.append(
            f'<rect x="{lx}" y="{ly}" width="{_fmt(w * k)}" height="{_fmt(h * k)}"'
            f' rx="{_fmt(h * k / 2)}" fill="{hex_of(INK)}"/>'
        )

    bx, by = px(*BADGE_CENTER)
    cx0, cy0 = px(*CHECK[0])
    cx1, cy1 = px(*CHECK[1])
    cx2, cy2 = px(*CHECK[2])

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none">
  <!-- Gerado por tool/generate_icons.py. Não editar à mão: as mesmas
       constantes desenham os PNGs do launcher. -->
  <rect width="100" height="100" rx="22" fill="{hex_of(BRAND)}"/>
  <g transform="translate({_fmt(off)} {_fmt(off)}) scale({_fmt(k)})">
    <path d="{_receipt_path()}" fill="{hex_of(PAPER)}"/>
  </g>
{chr(10).join("  " + line for line in lines)}
  <circle cx="{bx}" cy="{by}" r="{_fmt((BADGE_RADIUS + BADGE_RING) * k)}" fill="{hex_of(PAPER)}"/>
  <circle cx="{bx}" cy="{by}" r="{_fmt(BADGE_RADIUS * k)}" fill="{hex_of(BADGE)}"/>
  <path d="M{cx0} {cy0}L{cx1} {cy1}L{cx2} {cy2}" stroke="{hex_of(PAPER)}"
        stroke-width="{_fmt(CHECK_WIDTH * k)}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
"""


def write(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"  {path}  {image.size[0]}px")


def main():
    for bucket, size in LEGACY_SIZES.items():
        write(render(size, framed=True), ANDROID_RES / f"mipmap-{bucket}" / "ic_launcher.png")

    # Na camada de frente a marca fica menor: só os 72 de 108dp centrais
    # escapam da máscara do sistema, seja ela círculo, quadrado ou squircle.
    # Ver ADAPTIVE_MARK_FRACTION.
    for bucket, size in ADAPTIVE_SIZES.items():
        folder = ANDROID_RES / f"mipmap-{bucket}"
        write(render(size, framed=False, mark_fraction=ADAPTIVE_MARK_FRACTION),
              folder / "ic_launcher_foreground.png")
        write(render(size, framed=False, mono=True, mark_fraction=ADAPTIVE_MARK_FRACTION),
              folder / "ic_launcher_monochrome.png")

    write(render(512, framed=True), Path("branding/icon_512.png"))

    mark = Path("assets/illustrations/app_mark.svg")
    mark.write_text(svg(), encoding="utf-8")
    print(f"  {mark}")


if __name__ == "__main__":
    main()

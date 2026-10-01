"""Gera os ícones do app Faturas a partir de código, não de um PNG editado à mão.

A marca são três cartões em leque: os cartões que o app confere, cada um na
sua cor — a mesma cor que o cartão ganha dentro do app. O fundo é o grafite
do card de destaque.

Rodar depois de mexer na geometria:

    python3 tool/generate_icons.py

Saída (todos sobrescritos):
  android/.../mipmap-*/ic_launcher.png             ícone legado, com a própria moldura
  android/.../mipmap-*/ic_launcher_foreground.png  camada de frente do adaptive icon
  android/.../mipmap-*/ic_launcher_monochrome.png  silhueta para o tema do Android 13+
  branding/icon_512.png                            arte para a Play Store
  assets/illustrations/app_mark.svg                logo da tela de boas-vindas

Não há rasterizador de SVG nesta máquina (rsvg/inkscape/ImageMagick), então o
desenho é feito no PIL e ampliado 4x antes de reduzir — é o que dá a borda
suave sem depender de ferramenta externa.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

# ── Paleta ───────────────────────────────────────────────────────────────
# O fundo é `AppColors.heroLight`. Os cartões saem de
# `AppColors.avatarBackground(hue)` no tema claro — HSL(hue, 62%, 48%) —
# com os matizes que o app oferece no cadastro do cartão; o chip é o mesmo
# dourado dos cartões da carteira na conferência.
BRAND = (30, 30, 33, 255)
CARD_COLORS = [(47, 173, 198, 255), (198, 112, 47, 255), (178, 47, 198, 255)]
CHIP = (233, 208, 138, 255)

SS = 4  # supersampling: desenha grande, reduz com LANCZOS

# ── Geometria, num quadro de 100x100 ─────────────────────────────────────
# Tudo é proporção. Mudar um número aqui vale para todos os tamanhos.
# Cartões do fundo para a frente: centro, ângulo em graus. O leque abre no
# sentido horário, então o da frente é o mais inclinado para a direita e o
# chip dele fica à mostra.
CARD_W, CARD_H, CARD_RADIUS = 58.0, 38.0, 6.5
CARDS = [((41.0, 39.0), -22.0), ((48.0, 48.0), -7.0), ((56.0, 58.0), 9.0)]

# Vão entre um cartão e o de trás. Sem ele, no tamanho de 48px as três cores
# encostam e o leque lê como uma mancha só; no monocromático é ele que
# desenha o contorno de cada cartão.
GAP = 2.6

# Chip no cartão da frente, em coordenadas do próprio cartão (centro = 0,0).
CHIP_CENTER = (-16.0, 2.0)
CHIP_W, CHIP_H, CHIP_RADIUS = 11.0, 8.5, 2.0

# Quantos pontos por canto arredondado no polígono do PIL.
ARC_STEPS = 10


def _rounded_rect_poly(center, w, h, r, angle_deg, local_center=(0.0, 0.0)):
    """Contorno de um retângulo arredondado girado, como lista de pontos no
    quadro 100x100. [local_center] desloca o retângulo no sistema do cartão
    — é como o chip acompanha a rotação do cartão da frente."""
    cx, cy = center
    a = math.radians(angle_deg)
    cos_a, sin_a = math.cos(a), math.sin(a)
    lx, ly = local_center
    hw, hh = w / 2, h / 2
    corners = [(hw - r, -hh + r, -90), (hw - r, hh - r, 0), (-hw + r, hh - r, 90), (-hw + r, -hh + r, 180)]
    points = []
    for ox, oy, start in corners:
        for i in range(ARC_STEPS + 1):
            t = math.radians(start + 90 * i / ARC_STEPS)
            x = lx + ox + r * math.cos(t)
            y = ly + oy + r * math.sin(t)
            points.append((cx + x * cos_a - y * sin_a, cy + x * sin_a + y * cos_a))
    return points


def _farthest_from_center():
    """O ponto da marca mais longe do centro do quadro, em unidades do quadro."""
    return max(
        math.hypot(x - 50, y - 50)
        for center, angle in CARDS
        for x, y in _rounded_rect_poly(center, CARD_W + 2 * GAP, CARD_H + 2 * GAP, CARD_RADIUS + GAP, angle)
    )


# Quanto do canvas de 108dp a marca ocupa na camada de frente.
#
# O sistema recorta o adaptive icon com uma máscara que o fabricante escolhe
# — círculo, squircle, gota — e só o círculo central de 66dp é garantido.
# Calculado da geometria em vez de fixo: o ponto mais distante do leque tem
# de caber no raio de 33dp, com 5% de folga para o parallax que alguns
# launchers aplicam. Conferir com `python3 tool/preview_icons.py`.
ADAPTIVE_MARK_FRACTION = round(33 * 0.95 * 100 / (108 * _farthest_from_center()), 3)

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


def _paint(draw, m, *, mono):
    """Desenha a marca. Em [mono] tudo vira uma silhueta só, com os vãos
    vazados — é o que o tema do Android 13+ pinta com a cor do sistema."""
    hole = (0, 0, 0, 0)
    gap = hole if mono else BRAND
    white = (255, 255, 255, 255)

    for (center, angle), color in zip(CARDS, CARD_COLORS):
        # O vão primeiro, um pouco maior que o cartão: ele recorta o de trás.
        draw.polygon([m.p(*pt) for pt in _rounded_rect_poly(
            center, CARD_W + 2 * GAP, CARD_H + 2 * GAP, CARD_RADIUS + GAP, angle)], fill=gap)
        draw.polygon([m.p(*pt) for pt in _rounded_rect_poly(
            center, CARD_W, CARD_H, CARD_RADIUS, angle)], fill=white if mono else color)

    front_center, front_angle = CARDS[-1]
    draw.polygon([m.p(*pt) for pt in _rounded_rect_poly(
        front_center, CHIP_W, CHIP_H, CHIP_RADIUS, front_angle, local_center=CHIP_CENTER)],
        fill=hole if mono else CHIP)


def render(size, *, framed, mono=False, mark_fraction=0.84):
    """Uma arte quadrada de [size] px. [framed] desenha a moldura grafite do
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


def _hex(rgba):
    return "#%02X%02X%02X" % rgba[:3]


def svg(mark_fraction=0.84):
    """A marca com a moldura grafite, no mesmo enquadramento do ícone legado."""
    side = 100 * mark_fraction
    off = (100 - side) / 2
    k = side / 100.0

    def rect(center, w, h, r, angle, fill, local=(0.0, 0.0)):
        cx, cy = center
        lx, ly = local
        return (f'<rect x="{_fmt(cx + lx - w / 2)}" y="{_fmt(cy + ly - h / 2)}" width="{_fmt(w)}"'
                f' height="{_fmt(h)}" rx="{_fmt(r)}" fill="{fill}"'
                f' transform="rotate({_fmt(angle)} {_fmt(cx)} {_fmt(cy)})"/>')

    shapes = []
    for (center, angle), color in zip(CARDS, CARD_COLORS):
        shapes.append(rect(center, CARD_W + 2 * GAP, CARD_H + 2 * GAP, CARD_RADIUS + GAP, angle, _hex(BRAND)))
        shapes.append(rect(center, CARD_W, CARD_H, CARD_RADIUS, angle, _hex(color)))
    front_center, front_angle = CARDS[-1]
    shapes.append(rect(front_center, CHIP_W, CHIP_H, CHIP_RADIUS, front_angle, _hex(CHIP), local=CHIP_CENTER))

    body = "\n".join("    " + shape for shape in shapes)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none">
  <!-- Gerado por tool/generate_icons.py. Não editar à mão: as mesmas
       constantes desenham os PNGs do launcher. -->
  <rect width="100" height="100" rx="22" fill="{_hex(BRAND)}"/>
  <g transform="translate({_fmt(off)} {_fmt(off)}) scale({_fmt(k)})">
{body}
  </g>
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

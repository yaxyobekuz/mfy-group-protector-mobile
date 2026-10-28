"""ILOVA BELGISINI YASAYDI (Android launcher + adaptive).

⚠️ BELGI KODDAN YASALADI, grafik muharrirdan EMAS: o'lchamlar
(mdpi…xxxhdpi, adaptive foreground) oltita va ularni qo'lda
eksport qilishda bittasi albatta eskirib qolardi — natijada
telefonda eski belgi, planshetda yangisi ko'rinardi.

⚠️ KATTA O'LCHAMDA CHIZILIB, KEYIN KICHRAYTIRILADI (supersampling):
to'g'ridan-to'g'ri 48x48 chizilsa, qiyshiq chiziqlar tishli
("zina") bo'lib chiqadi.

⚠️ ADAPTIVE BELGIDA XAVFSIZ MAYDON: Android foreground ning
chetki ~1/3 qismini kesib tashlashi mumkin (doira, kvadrat,
tomchi — ishlab chiqaruvchiga qarab). Shuning uchun rasm
markazning ~60% iga joylashtiriladi.
"""

from PIL import Image, ImageDraw
import math
import os

BLUE = (36, 99, 235)       # AppColors.primary — #2463EB
BLUE_DARK = (17, 71, 187)  # accentForeground — #1147BB
WHITE = (255, 255, 255)

S = 1024          # ish o'lchami
SS = 4            # supersampling karrasi
W = S * SS


def _pin(draw, cx, cy, r, color):
    """Joy belgisi (tomchi): doira + pastga ingichkalashgan uchi."""
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    # Uchi — doira pastidan boshlanadigan uchburchak.
    tip_y = cy + int(r * 2.25)
    draw.polygon(
        [(cx - int(r * 0.74), cy + int(r * 0.62)),
         (cx + int(r * 0.74), cy + int(r * 0.62)),
         (cx, tip_y)],
        fill=color,
    )


def draw_logo(img, scale=1.0, with_bg=True):
    """Belgini chizadi. `scale` — adaptive uchun kichraytirish."""
    d = ImageDraw.Draw(img)
    c = W // 2

    if with_bg:
        d.rounded_rectangle([0, 0, W, W], radius=int(W * 0.235), fill=BLUE)

    r = int(W * 0.285 * scale)     # qalqon yarim kengligi
    top = c - int(W * 0.27 * scale)
    bot = c + int(W * 0.30 * scale)
    h = bot - top

    # ── QALQON (nazorat/himoya) — oq ──────────────────────────
    #
    # ⚠️ PASTKI QIRRA EGRI, siniq EMAS: to'g'ri chiziq bilan
    # yasalganda belgi qalqonga emas, uchburchak "uy" ga
    # o'xshab qolardi. Egri chiziq nuqtama-nuqta hisoblanadi.
    #
    # ⚠️ TEPASI TEKIS: ichkariga botgan qirra belgi "singan"
    # taassurotini berardi.
    shoulder = top + int(h * 0.50)
    steps = 24
    right, left = [], []
    for i in range(steps + 1):
        t = i / steps
        # Yon tomondan uchiga: en kosinus bilan toraydi, bu
        # qalqonning tabiiy "qorni" ni beradi.
        y = shoulder + (bot - shoulder) * t
        x = r * math.cos(t * math.pi / 2) ** 0.85
        right.append((c + int(x), int(y)))
        left.append((c - int(x), int(y)))

    shield = [(c - r, top), (c + r, top)] + right + list(reversed(left))
    d.polygon(shield, fill=WHITE)

    # ── JOY BELGISI (murojaat nuqtasi) — ko'k, qalqon ichida ──
    pin_r = int(r * 0.40)
    pcy = top + int(h * 0.36)
    _pin(d, c, pcy, pin_r, BLUE)
    # Teshigi — "halqa" ko'rinishi uchun.
    hole = int(pin_r * 0.38)
    d.ellipse([c - hole, pcy - hole, c + hole, pcy + hole], fill=WHITE)
    return img


def render(with_bg=True, scale=1.0):
    """
    ⚠️ SHAFFOF FONDA CHIZILIB, KEYIN KICHRAYTIRILADI: RGBA
    rasmni to'g'ridan-to'g'ri kichraytirsak, chekka piksellar
    shaffof QORA bilan aralashib, burchaklarda qora hoshiya
    ("fringe") paydo bo'ladi — 48px da u aniq ko'rinadi.
    Yechim: rangni oldindan ko'paytirish emas, balki chekkani
    fon rangi bilan to'ldirib chizish.
    """
    if with_bg:
        # Fon butun maydonni egallaydi, keyin burchaklar
        # alfa-niqob bilan kesiladi — shunda chekka piksellar
        # KO'K bilan aralashadi, qora bilan emas.
        img = Image.new("RGBA", (W, W), BLUE + (255,))
        draw_logo(img, scale=scale, with_bg=False)

        mask = Image.new("L", (W, W), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, W, W], radius=int(W * 0.235), fill=255
        )
        img.putalpha(mask)
    else:
        img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        draw_logo(img, scale=scale, with_bg=False)

    return img.resize((S, S), Image.LANCZOS)


RES = "android/app/src/main/res"
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

legacy = render(with_bg=True)

# ⚠️ DOIRA VARIANTI HAM KERAK (`android:roundIcon`): Android 7 va
# ba'zi launcher'lar aynan shuni so'raydi va topilmasa, yumaloq
# joyga KVADRAT belgi qo'yib, chetlarini o'zi qirqardi.
round_icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
_flat = Image.new("RGBA", (W, W), BLUE + (255,))
draw_logo(_flat, scale=1.0, with_bg=False)
_circle = Image.new("L", (W, W), 0)
ImageDraw.Draw(_circle).ellipse([0, 0, W, W], fill=255)
_flat.putalpha(_circle)
round_icon = _flat.resize((S, S), Image.LANCZOS)

for name, px in SIZES.items():
    folder = f"{RES}/mipmap-{name}"
    os.makedirs(folder, exist_ok=True)
    legacy.resize((px, px), Image.LANCZOS).save(f"{folder}/ic_launcher.png")
    round_icon.resize((px, px), Image.LANCZOS).save(
        f"{folder}/ic_launcher_round.png"
    )
    print(f"  mipmap-{name}/  ic_launcher + ic_launcher_round  {px}x{px}")

# ── ADAPTIVE: foreground alohida, fon rang bilan beriladi ────
fg = render(with_bg=False, scale=0.62)
for name, px in SIZES.items():
    folder = f"{RES}/mipmap-{name}"
    fg.resize((px, px), Image.LANCZOS).save(f"{folder}/ic_launcher_foreground.png")

# Play Market uchun 512 (do'kon ro'yxati).
legacy.resize((512, 512), Image.LANCZOS).save("tool/play_store_icon_512.png")
print("  tool/play_store_icon_512.png  512x512")

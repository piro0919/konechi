#!/usr/bin/env python3
"""アプリ本体のアイコン（`Resources/konechi-icon.png`）を組み立てる。

macOS 26 は、**透過を含まない正方形の絵**を受け取ると、自分で角丸に切り抜いて表示する。
少しでも透過が入っていると「角丸を描けていない絵」とみなし、システムが薄い板を敷いて
その上に載せる。結果、角丸の中にもう一枚角丸が入った見た目になる。

実測して確かめた（`NSWorkspace.icon(forFile:)` の結果を比較）。

| アプリ  | 不透明な画素 | 見え方           |
| ------- | ------------ | ---------------- |
| Galopen | 100%         | 角丸。板なし     |
| Mekuri  | 40%          | 板の上に載る     |
| Konechi | 94%          | 板の上に載る     |

なので**角丸を自分で描かず、背景色で端まで塗った正方形**を渡す。

    ./Tools/make-icon.py <角丸つきの元絵.png>

背景色は元絵の外周から数えて決める。1点だけ見ると髪や輪郭に当たって外す。
"""
import sys
from collections import Counter

from PIL import Image

SIZE = 1024
FACE_WIDTH_RATIO = 0.80
FACE = "Resources/konechi-default.png"
OUTPUT = "Resources/konechi-icon.png"


def background_color(path):
    image = Image.open(path).convert("RGBA")
    image = image.crop(image.getbbox()).resize((256, 256), Image.LANCZOS)
    pixels = image.load()

    counts = Counter()
    for x in range(256):
        for y in range(256):
            on_edge = x < 26 or x > 229 or y < 26 or y > 229
            if on_edge and pixels[x, y][3] > 200:
                counts[pixels[x, y][:3]] += 1

    if not counts:
        raise SystemExit("外周に色が見つかりません")
    return counts.most_common(1)[0][0]


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    color = background_color(sys.argv[1])

    face = Image.open(FACE).convert("RGBA")
    face = face.crop(face.getbbox())
    width = round(SIZE * FACE_WIDTH_RATIO)
    face = face.resize((width, round(face.height * width / face.width)), Image.LANCZOS)

    # RGB で作るので、透過は最初から入らない
    out = Image.new("RGB", (SIZE, SIZE), color)
    out.paste(face, ((SIZE - face.width) // 2, (SIZE - face.height) // 2), face)
    out.save(OUTPUT)

    print(f"{OUTPUT} を作りました  背景色 {color}  顔 {face.size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

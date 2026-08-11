#!/usr/bin/env python3
"""キャラの絵の透明な余白を、共通の枠で切り詰める。

1枚ずつ詰めてはいけない。表情ごとに描かれている範囲が僅かに違うので、別々に詰めると
状態が切り替わるたびにキャラの大きさが変わって跳ねる。全部の絵を重ねた範囲を取り、
その1つの枠で全部を切る。

    ./Tools/trim.py Resources/konechi-default.png Resources/konechi-wired.png …

鍵バッジのように単独で使うものは、1枚だけ渡せばその絵の範囲で切られる。
"""
import sys

from PIL import Image


def union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))


def main():
    paths = sys.argv[1:]
    if not paths:
        print(__doc__)
        return 1

    images = {path: Image.open(path).convert("RGBA") for path in paths}

    box = None
    for image in images.values():
        box = union(box, image.getbbox())

    if box is None:
        print("中身のある絵がありません")
        return 1

    for path, image in images.items():
        before = image.size
        cropped = image.crop(box)
        cropped.save(path)
        ratio = cropped.size[0] / cropped.size[1]
        print(f"{path}: {before[0]}x{before[1]} → {cropped.size[0]}x{cropped.size[1]}  横縦比 {ratio:.2f}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

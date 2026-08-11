# 絵の生成に使う指示

そのまま貼り付けて使う。**1枚目を確定させてから、それを元画像として差分を作る。**
別々に生成すると、髪の量・顔の丸み・色味がずれて別人が4人並ぶ。

条件の根拠は [SPEC.md](../SPEC.md) の「絵の条件」を参照。要点は、メニューバーでの実寸が
17pt しかないため**輪郭と色の面積だけが残る**こと。細部は必ず消える。

## 1枚目 — 標準（`konechi-default.png`）

```text
Draw a mascot character icon for a small macOS menu bar app called "Konechi".

This icon will be displayed at 17x17 pixels. Design it for that size, not as
an illustration that happens to be shrunk. Everything smaller than about 1/8
of the image height will disappear, so it must not carry meaning.

Character: an extremely simplified chibi anime girl. Head only, no body, no
neck, no clothes. Facing front. Soft round face, gentle smile.

Eyes: two simple solid shapes with one small highlight each. No white of the
eye, no iris rings, no eyelashes.

Hair: pink, in two big round twin tails, one on each side, drawn as single
solid masses. No separated strands, no inner highlights, no shading inside
the hair, no stray hairs, no accessories. The bangs are one simple shape.

Style: completely flat. Solid fills only. One uniform thick outline of the
same weight everywhere. Three or four colors in total. No gradients, no
shading, no texture, no glossy highlights.

Composition: the head fills the entire frame edge to edge, minimal margin,
square canvas, centered.

Background: fully transparent, with one light rim outline around the whole
silhouette so it stays visible on both dark and light backgrounds.

The result should read like a sticker or an emoji: recognizable purely from
its silhouette and its color blocks.

Do not include: text, logos, a body, shoulders, clothes, hands, drop shadows,
gradients, or any background scenery.
```

> 最初に出したものは、髪の房が細かく分かれ、目が3層になり、上着まで描かれていた。
> どれも実寸で消える情報で、消えたぶんだけ「ピンクの塊」に近づく。
> 絵柄ではなく**情報量**を削るのが要点。

## 状態の表し方（2枚目以降）

**状態は表情だけで表す。** 頭の上に印を足したり、持ち物を持たせたりしない。
パワプロの調子アイコンのように、有線が絶好調、Wi-Fi が好調、未接続が絶不調。

顔以外は1枚目から一切変えない。髪・色・線の太さ・輪郭・大きさ・構図をそのまま保つ。
変えるのは目と眉と口と頬だけ。**眉と髪のハイライトも1枚目のまま残す。**

> 実寸21ptでは表情の差は読めない。それは確認済みのうえで、この形を選んでいる。
> 状態がしょっちゅう切り替わるものではなく、分からなければメニューを開けば書いてあるため。
> 詳しくは [SPEC.md](../SPEC.md) の「アイコンの方向性」を参照。

## 2枚目 — 有線（`konechi-wired.png`）

```text
Using the exact same character, change only her facial expression. Keep the
composition, the silhouette, the hair, the hair highlight, the colors, the
line weight and the size of the image exactly as they are. Do not add
anything to the image.

New expression: full of energy and confident. A big open happy smile, eyes
curved upward into cheerful arcs, eyebrows raised, cheeks a little brighter.
She looks like she is in top condition.

Keep the background genuinely transparent with no checkerboard pattern.
```

## 3枚目 — Wi-Fi（`konechi-wifi.png`）

```text
Using the exact same character, change only her facial expression. Keep the
composition, the silhouette, the hair, the hair highlight, the colors, the
line weight and the size of the image exactly as they are. Do not add
anything to the image.

New expression: relaxed and content. A soft closed-mouth smile with one eye
winking. She looks comfortable, in good condition but not excited.

Keep the background genuinely transparent with no checkerboard pattern.
```

## 4枚目 — 未接続（`konechi-offline.png`）

```text
Using the exact same character, change only her facial expression. Keep the
composition, the silhouette, the hair, the hair highlight, the colors, the
line weight and the size of the image exactly as they are. Do not add
anything to the image except the sleep marks described below.

New expression: out of energy and dozing off. Closed drooping eyes drawn as
downward curves, eyebrows slanted down, a small flat mouth, and pale cheeks.
She looks like she has run out of power.

The only addition allowed: a small "zzz" floating near the upper right of her
head, drawn in the same flat style with the same outline weight. Keep it
inside the existing image bounds — the image must not get any wider or taller
than the original.

Keep the background genuinely transparent with no checkerboard pattern.
```

## 5枚目 — 鍵バッジ（`konechi-lock.png`）

キャラの構図とは無関係なので、**作り直し不要**。既存のものをそのまま使う。
作り直す場合だけ次を投げる。

```text
Draw a single small padlock icon on its own, in the same flat style: solid
fills, one uniform thick outline, no gradients, no shading.

Use a strong contrasting color so it stays readable at very small sizes. It
will be placed as a badge on the lower right corner of the character at about
half her height. Square canvas, fully transparent background, and the same
light rim outline around the padlock so it separates from whatever is behind
it.
```

## 置き場所

`Resources/` に上の名前で置く。アプリは絵があればそれを使い、無ければ記号で代用する。
名前の付け方は chappie v1 に倣ってキャラ名を先頭に置いてある。

## 確認の仕方

生成したら必ず実寸に縮めて確かめる。拡大して良く見えても実寸で潰れることが多い。

```bash
./mockup.sh   # 実寸と拡大を並べた見本を作って開く
```

## 注意

透過を指定しても、生成側が背景を塗ってくることがある。その場合は白背景のまま受け取り、
あとで背景を抜く。透過が効いているかどうかも、実寸に縮める前に確かめておく。

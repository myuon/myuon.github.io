---
title: 日本語のTypographyの設定
date: 2020-05-02T01:29:52+09:00
---

日本語のTypography、意外と誰もまとめてくれなくて悲しみながら自分で調整したので置いておく用。

これにした:

![Typography](/images/Screenshot_20200502_014752.png)

様子:

![様子](/images/Screenshot_20200502_014852.png)

## 気持ち

- フォントとか全部Noto Sans JPでいいよ(少なくともLinuxでキレイに見えるなら他の環境のことは知らねえというスタンスでいるので)
- Material Designだとh5, h6, body2とかあるけどまあ使うことないよ
- Material Designは全体的にfont-sizeのメリハリが大きすぎなので弱めて、代わりにletter-spacingは強めに設定しました。h1,h2は少し寄りすぎくらいかもしれない…が、カタカナ・ひらがなと密度の高い漢字だとだいぶ変わってきてしまうのでどこを取るのかは難しいところ…(普通の文章でそこまで漢字が連続することもそんなに無い気がするけど…)
- font-weightは大きい文字だと500くらいがキレイに見えると個人的に思っているのでそのへんで。Material Design氏なぜかh1-h6でfont-weightがバラバラなんだけどあれは一体何なんだ…
- line-heightは完全にノリでやってるけど適正値が分からない、そもそもheader要素は改行されることあんまないし大概専用のmargin入れるのでそんなに気にしなくてもいいのかもしれない
- 調整甘いところあるけどデフォルトよりはずっとマシになったのでとりあえずこれで手を打った

## material-uiでの設定

```js
createMuiTheme({
  typography: {
    h1: {
      fontSize: "2rem",
      fontWeight: 500,
      lineHeight: 1.75,
      letterSpacing: "-0.035em"
    },
    h2: {
      fontSize: "1.65rem",
      fontWeight: 500,
      lineHeight: 1.6,
      letterSpacing: "-0.03em"
    },
    h3: {
      fontSize: "1.5rem",
      fontWeight: 500,
      lineHeight: 1.5,
      letterSpacing: "-0.025em"
    },
    h4: {
      fontSize: "1.25rem",
      lineHeight: 1.5,
      letterSpacing: "-0.02em"
    },
    body1: {
      lineHeight: 1.7,
      letterSpacing: "0.05em"
    },
    caption: {
      fontSize: "0.85rem",
      lineHeight: 1.75,
      letterSpacing: "0.075em"
    },
    button: {
      fontSize: "0.85rem",
      fontWeight: 500
    },
    fontFamily: "'Noto Sans JP', sans-serif"
  }
})
```

## その他

日本語Webサイトだとこれが正解ですっていうのを誰か教えてほしい

このブログのデザインもまったく日本語向けではないので手を入れたいなと言う気持ちがありつつHugoのテンプレート触るのか…という気持ちになっている。オワリ。

---
title: はじめようReason ML
date: 2018-11-10T00:24:20+09:00
tags: [ "ML" ]
---

# はじめに

Reason MLを最近始めました。よき。

## Reason MLとは

Reason MLとはOCamlにインスパイアされたAltJSの一種。見た目は型の付いたJSみたいな感じだけど実際はJSのsyntaxに寄せたML。

BuckleScriptというコンパイラ(この名前もどうなんという感じだけど)を使ってJSに変える。BuckleScriptはReason MLとOCamlをJSに変換するコンパイラであり、Reason MLとOCamlのいずれのsyntaxも混ぜて使うことができるっぽい。便利～。

実際に使うときはBuckleScriptの方のドキュメントもちゃんと読んでおく必要がある(似たような見た目のページだけど内容は違う)。BuckleScriptにはコンパイラ拡張みたいなものが載っておりそれを上手く使うことで生成されるJSを制御したりJS側の関数を読み込んだりするのでこの辺も割と必須。

- https://reasonml.github.io/en/ Reason MLの言語リファレンス
- https://bucklescript.github.io/en/ BuckleScriptリファレンス
- https://bucklescript.github.io/bucklescript/api/index.html BuckleScript標準ライブラリ(Reason MLも同じものがportされてる)

## よさ

- まともな型が付く(OCamlの型システム、世界で一番分かりやすいみたいなところがある)
- 生成されるJSがまとも
- ドキュメントが割とそろってる
- JSとのブリッジが簡単(基本的に何もしなくてもできる; JS直接埋め込むのもできる)
- JS風syntax(これは完全な好みだけどブレース・セミコロンsyntaxが結局一番書きやすいみたいなところあるよ)
- まぁライブラリも意外とある
- bs-jsonも普通に使いやすいよ
- JSの標準ライブラリの関数とか型はすべてportされてるのでちゃんと使える

## ハマりポイント

- BuckleScript拡張最初はよくわからなかった(ドキュメントを100回くらい読むと分かる)
- 特殊な演算子とかが意外と多くてsyntaxを覚えるのは結構しんどい(Haskellとかだとライブラリ定義の演算子が多いから定義見ればいいけど組み込みの演算子が多いのがつらい)
- 関数はデフォルトではカリー化されて `(a,b) => ...` は `a => b => ...` 相当のJSが生成されるので(これは回避可能)知らないとたまに思った通り動かない
- ReactはReasonReactというのがあるらしいけどVue.jsはどうしたらいいのかよくわからない(調べてもVue2のやつしか出てこない)

## レポート

Node.jsで書いていたサーバーサイドをReason MLで書き直したりVue.jsのビジネスロジック部分だけを切り離してReason MLで書き直したりして安寧を得ています。

Rustに引き続き9ヵ月ぶりくらいに良い言語に巡り合えました。ていうか私はML系の言語大体「良い」って言う傾向にあるしまぁML好きなんだなと自分でも思います。

あとはVue.jsでスムーズに使えるようになったらフロントもバックも全部Reason MLでできるのになーって言ってる。 `create-vue-app` あたりのエコシステムが正式にサポートしてくんないかな～って感じですね。



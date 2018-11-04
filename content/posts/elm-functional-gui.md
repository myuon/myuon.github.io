---
title: "Elm: Concurrent FRP for Functional GUIsを読んで"
date: 2018-11-04T12:32:56+09:00
tags: [ "FRP", "ラムダ計算" ]
---

これ

[https://elm-lang.org/assets/papers/concurrent-frp.pdf](https://elm-lang.org/assets/papers/concurrent-frp.pdf)

## はじめに

某所でFRPをeffect systemとみなせないか、という大変示唆的な質問をいただいて、気になったのでFRPについて調べてた流れで教えてもらったElmの作者が書いた論文。
自分はFRPについては「なんかEventとBehaviorがあってArrowになったりMonadになったりするやつ」くらいの感覚しかなかったので論文読んでみることにした。

ところでmarkdownで数式や図を記述するのは大変つらいので記事は適当に日本語で書きます。詳しく知りたい人は論文の方を読んでください。

あと、ElmはFRP捨てたって言ってた気がするので多分今のElmはもう論文にあるような仕組みで動いてないような気がしないでもない。

## 2章 背景

- FRPにはClassical, Real-time (とEvent-driven), Arrowizedの3種類ある
- Classical:
  - `Behavior a = Time -> a`: これが時間の経過とともに変わる値を表現する
  - `Event a = [(Time, a)]`: これがBehaviorのスナップショットを取ったもの
  - 基本はBehaviorをベースに計算を行うけど、実際のプログラムでは無限に細かい時間で計算はできないので30fpsとか決まったタイミングで再計算するかどうかを考えることになる。そういう離散化のためにEventがあるよみたいな感じ
- Real-time:
  - `Event a = Behavior (Maybe a)`
  - EventもBehaviorで書いちゃえばいいんちゃうん
  - Event, Behaviorをまとめて `Signal a = Time -> a` と呼ぶことに
  - 論文で説明されてるElm Coreもこれにinspireされてるっぽい
- Arrowized:
  - `SF a b = Signal a -> Signal b`
  - signal functionというものをベースにしてこれをArrowにする
  - 論文読んだ限りだと理論が難しくなりそうなのでFRPにおける特にArrowの優位性はよくわからなかった 書きやすいってくらいなのか
- Message-Passing Concurrency
  - Concurrent MLの説明
  - 実装はこれで書いたり書かなかったりする(あとの章でtranslationが与えられる)
- 既存のFRP GUI frameworks
  - メモリリークする(Haskellなので)(って何度も書いてあってウケるって思った)

## 3章 Core Language

- Dicreteなsignalを扱う
- 文法: `e ::= () | n \in Z | \x. e | e1 e2 | x | let x = e1 in e2 | i \in Input | lift e e1 .. en | foldp e1 e2 e3 | async e`
  - primitiveとしてlift, foldp, asyncが追加されてる
  - liftは持ち上げ(Functorのn変数版)
  - foldpはsignalの畳み込み(過去から現在に向かって発生したEventを順に畳み込んで現在の値を計算するみたいな感じ)
  - asyncは与えられた項がasyncに(他のプログラムと同期せず)実行していいよってことをコンパイラに伝えるためのprimitive
- 例
  - `cosWave lift cos (Time.every 0.2)` 0.2秒ごとにcos waveの値を計算
  - `fitUpTo w = lift (min w) Window.width` Windowの幅とwの小さい方を返す(Windowがリサイズされると再計算される)
  - `foldp (\k word. word ++ [k]) "" Keys.lastPressed` 今までに入力されたキーのなす文字列を返す
- Type System: typeは2種類, primitive typeとsignal typeがある
  - `t ::= unit | number | t -> t'` (primitive type)
  - `s ::= t signal | t -> s | s -> s'` (signal type)
  - `r ::= t | s`
  - `t signal`は時間とともに移り変わる`t`、くらいの意味
- Typing Rules
  - `i \in Input ==> i : t |- i : (t signal)`
  - `lift : (t1 -> .. -> tn -> t) -> t1 signal -> .. -> tn signal -> t signal`
  - `foldp : (t -> t' -> t') -> t' -> t signal -> t' signal`
  - `async : t signal -> t signal`
- Embedding Arrowized FPR in Elm
  - ElmのsignalはApplicativeにはなるけどMonadにはならない(joinが与えられてないし; これは単純にここではCoreをそう作ったというだけで実際には頑張れば入れられるような気がしないでもない)
  - Arrowized FRPでSF Arrowを利用するものがあるらしく、それで言うとCoreのSignalはSFを使って書ける `Signal a = SF World a`
  - のでElm CoreもArrowみたいなもんや(って書いてあったけど、だとしたらセクションの名前のembedの方向逆じゃないのって思う)

(Semanticsの説明は箇条書きだとやりにくいので普通の文体に戻す)

Coreはcall-by-valueでsemanticsを与える

Coreのvalueはtypeと同じく2-sortで、base valueとreactive valueに分かれる

- `v ::= () | n | \x. e` (base value)
- `s ::= x | let x = s1 in s2 | i | lift v s1 .. sn | foldp v1 v2 s | async s` (reactive value)

signalの値はコピーをしてはいけない。signalをコピーすると入力が変化ときに必要以上に再計算が走ってしまう可能性があるため: 例えば `let x = sf i in [f x, g x]` を `[f (sf i), g (sf i)]` に簡約すると、iが変化したときのsの計算が前者は1回で済むけど後者は2回走るので。

Small-step operational semanticsは(pritimiveなやつ以外は)次の通り

- APP `(\x.e1) e2 -> let x = e2 in e1`
- REDUCE `let x = v in e -> e[v/x]`
- DROP `let x = s in e -> e` (`x \notin fv(e)`)
- EXPAND `(let x = s in e1) e2 -> let x = s in (e1 e2)` (`x \notin fv(e2)`)

また、primitiveは左から右に順に計算を行う。

## 4章 Concurrency

- Concurrentにどうやって計算をするかということと、global delay(入力の変化の伝播に時間がかかること)をどうやって避けるかって話が書いてある
- 結局asyncにできるところはやりましょという感じ
- asyncをつけると、通常のInputと同じく非同期に処理されるようになる
- asyncを付けていいかどうかはユーザー判断(たぶん)なので適当な書き方をするとsemanticsが壊れる気もする; concurrency自体はCoreでは一切何もケアしてないし
- Translation to CML: CMLでのCoreの実装が書いてあるがこれだけ見せられても困るとしか言いようがない(そもそもCMLの説明全然してないじゃん) やーここのsemanticsはちゃんと与えてほしかったが作者は実装したい人だろうしまぁしょうがないか
- translationはよくわかってないのでequationとかも含めまた機会があればちゃんと考えたい

## 5章以降

- GUIフレームワークどうやって作るかとかそういう話
- まぁ割愛

## 論文を読んで

FRPについての概説が2章でまとめられていたのはよかった。semanticsは分かったような分からんような(やっぱequational theoryとか作って構造を明示してくれないと分かった気がしないよな)という感じ。

ここでのElmのsignalはapplicativeだけどclassical frpでmonadicなやつとかもあるっぽい。その辺見てたらどうもmonadicといいつつ普通にparametricっぽさあるやつとか出てきてeffect systemでは？という感じになったりした(その論文ではalgebraicというかfree effectだった)ので、monadicな方もまた論文を読んだら記事を書こうと思います。

おわり


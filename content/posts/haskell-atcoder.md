---
title: Haskellで解くAtCoder
date: 2019-04-28T16:44:29+09:00
tags: [ "Haskell" ]
---

最近HaskellでAtCoderの問題を解いたりしているのでごく基本的な知見をまとめておく。

# テクニック集

多くは割と色んな人がすでに言っていることではある。また、想定解法を正しく実装すれば以下のようなことを守らなくても時間内に収まるだろうが、GHCは最適化が効かなければ10倍遅くなる言語であるので普段から守っておくに越したことはないと思う。

- 環境: AtCoderのGHCは2019.04現在7.10なので注意が必要。そのうち上がるかもしれないけど。
    - Strict拡張がない
    - BangPatterns拡張はある
    - 環境構築がhaskell-platformらしいのでそれに入ってるライブラリしか使えない
- 文字列
    - 基本は[Data.ByteString.Chan8](http://hackage.haskell.org/package/bytestring-0.10.8.2/docs/Data-ByteString-Char8.html)
    - Stringは死んでも使わない(遅いので)
    - Unicode文字列の扱いが必要(今の所みたことないけど)とかならtextを使うといいかもしれない
- リスト
    - リストは遅延リストをイテレータとして利用するだけに限るようにする(それでも全ての要素を走査するならVectorの方が大体速い(fromListのコストは除く))
    - 添字アクセスと結合は死んでもしない
    - 遅延リストは作って即畳めば最適化によってコストは消えてなくなるので、そういう使い方ならあまり心配はしなくて良い(畳み込みはiループ目にi番目の要素にのみアクセスするように書くこと)
    - 累積和は`scan`系を使うといいよ
- Vector: 基本は[Data.Vector.Unboxed](http://hackage.haskell.org/package/vector-0.12.0.2/docs/Data-Vector-Unboxed.html)
    - BoxedなVectorを使ってサンクを不必要に消費しないコードを書くのは結構難しいのでUnboxedを使うほうが無難
    - push_backがないのが致命的 グラフの構築とかは困ると思うので事前に何かしら考えておいたほうがいいかも(2秒制限に引っかかるほどではないのであまり気にしなくても良いが)
    - Vectorにはfusionがあるので、遅延リスト同様作って即畳めば最適化によってデータ生成のコストを消すことが出来る
    - 便利なAPI: create, unfoldrN
    - 注意すべきAPI: generate(Boxed Vectorの方は中の要素が遅延される), modify(呼ぶたびにコピーが取られる)
- データ構造
    - その他のデータ構造にほとんど出番はない(Vectorで書けるならVectorで書いたほうが速いことがほとんど)
    - Data.Set: priority queueの実装が面倒な場合
    - Data.Graph: グラフの構築やdfsが必要で、問題ごとに実装を考えたくない場合
- 再帰の実装
    - 単なるループは`foldl'`, 早期リターンが必要なら`foldr`
    - 雑に再帰したいときは`Control.Monad.Fix.fix`を使っても良い
    - Data.IORefなどはポインタ経由になるので遅い 関数の引数にするかStateを使うこと
- GHC最適化系:
    - 繰り返し適用される関数の引数は全てbang patternを付けておくのが安全(foldやscanの中、fixの中、手で書いた再帰関数等)(bang patternにより普通のコードが速くなることはないが、不要なサンクにより無意味に遅いコードは改善される)
    - タプルは中の要素が遅延されるので、タプルを評価するときは全ての要素を個別に評価すること
    - リストも中の要素が遅延されるが、中の要素を個別に評価するのは難しいのでそれが必要なときはUnboxed Vectorで書くのが最も安全
    - datatypeのフィールドも正格にしておくこと
    - コピーを取らない値の計算は爆速になるのでなるべくコピーは取らない
- パフォーマンス:
    - 実行時間はC++やRustの2-5倍程度が目安(10倍以上遅いときは書き方が悪い)
    - メモリ使用量も目安に(消費メモリ量を改善できれば自然に速くなることも)

## 入力

- 上にも書いたようにByteStringで読み込む
- 「n個の数値の読み出し」とかはVectorでササッと書く

#### 例

例: `a1 .. aN` を読み取り

```hs
import qualified Data.Vector.Unboxed as VU
import qualified Data.ByteString.Char8 as B

main = do
  let readInt = fmap (second B.tail) . B.readInt
 
  as <- VU.unfoldrN n readInt <$> B.getLine
```

`readInt`によって数値の読み出しとスペースを読み飛ばすという操作を行い、これを`unfoldrN`で繰り返すだけ

例: `A B` を読み取り

```hs
import qualified Data.Vector.Unboxed as VU
import qualified Data.ByteString.Char8 as B

main = do
  let readInt = fmap (second B.tail) . B.readInt
 
  (a,b) <- (\vec -> (vec VU.! 0, vec VU.! 1)) . VU.unfoldrN 2 readInt <$> B.getLine
```

上と同じように長さ2のvectorを作りこれを手で分解する(Vectorのままにして添字アクセスしてもいい)

例: `A1 B1\nA2 B2\n ... An Bn` を読み取り(縦に並んでいる場合)

```hs
import qualified Data.Vector.Unboxed as VU
import qualified Data.ByteString.Char8 as B

main = do
  let readInt = fmap (second B.tail) . B.readInt
 
  abs <-
    VU.replicateM n $ (\vec -> (vec VU.! 0, vec VU.! 1)) . VU.unfoldrN 2 readInt <$> B.getLine
```

上でやったのを`replicateM`で増やせばOK

## Vector

上にも書いたとおり、基本的にUnboxed Vectorを多用する。モジュールがいくつかあるのでどれを使えばいいかを覚えておこう。

- [Data.Vector.Unboxed](http://hackage.haskell.org/package/vector-0.12.0.2/docs/Data-Vector-Unboxed.html): Unboxed Immutable Vector
    - freezeでUnboxed Mutable VectorからUnboxed Immutable Vectorにできる
    - thawでUnboxed Mutable Vectorにできる
- [Data.Vector.Unboxed.Mutable](http://hackage.haskell.org/package/vector-0.12.0.2/docs/Data-Vector-Unboxed-Mutable.html): Unboxed Mutable Vector
    - 上のMutable版
    - APIは上とは全然違うのでこっちはこっちで事前に見ておく必要あり
    - new, read, modify, writeだけ見てれば多分大体困らない
- [Data.Vector](http://hackage.haskell.org/package/vector-0.12.0.2/docs/Data-Vector.html): Boxed Immutable Vector
    - freezeでBoxed Mutable VectorからBoxed Immutable Vectorにできる
    - thawでBoxed Mutable Vectorにできる
- [Data.Vector.Mutable](http://hackage.haskell.org/package/vector-0.12.0.2/docs/Data-Vector-Mutable.html): Boxed Mutable Vector
    - 上のMutable版

Immutable同士、Mutable同士のAPIが大体同じである。

## Unsafe Haskell

さてAtCoderをHaskellで解いているとIOやSTが出てきて面倒と思う人もいるかもしれないが(私だけかもしれない)、Haskellには便利なunsafe関数があるのでこれらを使うことで純粋関数の手軽さを兼ね備えつつ値の破壊的な更新等を行うことが出来る。当然安全性は崩壊する。

そんなUnsafe Haskellについてのテクニック:

- Unsafe Haskellは別に速くはない(IOで書いたときと同程度)
- unsafePerformIOではなく[Data.ByteString.Internal.accursedUnutterablePerformIO](http://hackage.haskell.org/package/bytestring-0.10.8.2/docs/src/Data.ByteString.Internal.html#accursedUnutterablePerformIO)を使う
    - unsafePerformIOはIOだけで処理するのに比べかなりオーバーヘッドがあるので多用すると遅い
    - accursedUnutterablePerformIOはunsafePerformIOをインライン化指定したもの。これによりunsafeのオーバーヘッドがなくなる
- 使い方
    - `(\unsafeValue -> accursedUnutterablePerformIO $ operationM unsafeValue)`をchainして使うのが基本、1度だけ値を受けとり、1度だけ使い、更新後の値を返す
    - Vectorで使う場合には`accursedUnutterablePerformIO $ write vec i a >> return vec`するようにする
    - referenceも保持しない、再帰するときはunsafe valueも引数に持って回ること(通常referenceを保持しておけば好きな場所で更新ができるが、unsafeValueはインライン化されて面倒なことになる)
    - コピーは死んでも取らない(unsafeな値を不用意に2箇所以上で使うと死ぬ)
    - replicateもしない(unsafe creationをreplicateするとメモ化されて死ぬ)
- unsafeな値の評価タイミングには最新の注意を払うこと
    - 特に遅延リストやタプルは外側の評価が行われても中の値が遅延されるので面倒なことになる場合がある
    - 面倒なときは全部Unboxed Vectorに入れると楽
    - 複数の操作を行うときはletをつなげて全部Bang Patternしてしまうのが楽
    - あるいはtraceを挟めば一旦評価が行われるのでデバッグ用途に便利
- 脳内でC言語にコンパイルしてやばい操作が行われていないかを考える
- VectorでunsafeWriteは最後までしない方が良い(core dumpして面倒なことがあるので)

正直seqやbangの有無で(実行時エラーとかではなくて)計算結果が変わるのはかなり厳しいので、絶対安全で大丈夫だという確信があるときくらいしか使えないのでおすすめは出来ない。Unsafe Haskellの安全性はC言語を遥かに下回るというのが実感である。

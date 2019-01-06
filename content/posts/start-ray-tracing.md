---
title: レイトレーシングに入門した
date: 2019-01-06T13:34:10+09:00
---

レイトレ自体は前から興味あったんだけど年末年始でいよいよ真面目に入門し始めました(今後も続けるかは不明)。

Ray tracing in one weekendシリーズを読んでこの3冊分の実装をRustで書きました。
本に沿って実装したのでレイトレーサーとして使えるような感じにはなってない(再利用性がなさすぎるところがちょいちょいある)。

- [Ray Tracing Minibooks (3 Book Series)](https://www.amazon.co.jp/gp/product/B0785N5QTC/ref=series_rw_dp_sw)
- [リポジトリ](https://github.com/myuon/ruyt)

## スクショ

個人的にお気に入りのやつをいくつか貼っておきます

![https://github.com/myuon/ruyt/blob/master/assets/14413648f55e334871d6f07836adfdac5d77ad76.png?raw=true](https://github.com/myuon/ruyt/blob/master/assets/14413648f55e334871d6f07836adfdac5d77ad76.png?raw=true)


![https://github.com/myuon/ruyt/blob/master/assets/22cd0642d79f817b7bae173fd957a33b8b9e8244.png?raw=true](https://github.com/myuon/ruyt/blob/master/assets/22cd0642d79f817b7bae173fd957a33b8b9e8244.png?raw=true)

![https://github.com/myuon/ruyt/blob/master/assets/8073afea1de6acdb0040b5d51b5f28c7ecf5d504.png?raw=true](https://github.com/myuon/ruyt/blob/master/assets/8073afea1de6acdb0040b5d51b5f28c7ecf5d504.png?raw=true)

## 今後やりたいこととか

本では純粋なCPU実装で最適化とかもそこまで(3冊目の後半はやるけど)だったので、まぁその辺かなー。SIMDとか使って高速化するのはできそうなのと、GPUを使ったちゃんとした高速レイトレみたいなのもちょっとやってみたい(そこまでそっちに傾倒する気はないしガリガリチューニングしたり最適化テク実装というよりは、もっと綺麗な絵を高速にレンダリングしたい)。

レイトレにも色々なテクがあるようで(bidirectionalなんとかとかmetropolisなんとかとか)、その辺によっても得意なシチュエーションが変わってくるみたいなので色々実装して遊べたりしたら面白そうだなーと思う。

アルゴリズムの詳細については以下のスライドが詳しくてしかも超面白かった。

<script async class="speakerdeck-embed" data-id="4b7909e99889472386a8dea2f0a9b5aa" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

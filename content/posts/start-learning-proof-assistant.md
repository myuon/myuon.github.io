---
title: 定理証明リンク集
date: 2019-01-06T15:46:06+09:00
draft: true
---

定理証明、特に定理証明支援系(Proof Assistant)はその存在こそ少しずつ浸透しつつあるような気がしないでもないけれど資料とか全然まとまってないのが不便だなと前々から思っていたのでリソースをまとめておきます。

これも追加してほしいみたいなのあったら教えてください。

## Proof Assistants

始めるなら次の中から選ぶのがよいと思います。

- [Coq](https://coq.inria.fr)
  - Calculus of constructionsベースの型システムとリッチなコマンドを備えた言語
  - このリストの中では最もコミュニティが大きい、入門書等も豊富
  - 型システムと項を書くためのGallina, コンパイラへの命令を記述するためのVernacular, タクティクスの定義に使うLtacなどの言語が混ざって出てくるのが初心者には混乱必至
  - 結構複雑な言語なので使いこなすのはそれなりに大変
- [Agda](https://wiki.portal.chalmers.se/agda/pmwiki.php)
  - Martin-Löf type theoryベースの言語
  - Coqと違ってコマンド等はとても貧弱だが言語が薄いので中の仕組みが分かりやすい、依存型の勉強にはもってこい
  - 実践的に使おうとするとパフォーマンスが悪いのがネック モジュール分割や証明のスキップみたいな面白くないところに時間を取られる可能性あり
- [Idris](https://www.idris-lang.org)
  - Agdaに似た感じの言語
  - この中では唯一純粋なプログラミング言語として使用可能(runtimeがあって実行可能コードを吐ける)だが実際に動かして使うにはまだまだという感じ
  - Agdaよりはサポートが多く証明が書きやすいはず(未検証なので嘘かも)
- [Lean](https://leanprover.github.io)
  - この中では後発、CoqやAgdaに似ており、Agdaよりは書きやすくリッチでCoqよりは薄くて簡単
  - 数年前にメジャーバージョンが2から3に上がりそこで多少の断絶があるらしい
  - 機能網羅的なリファレンスがまだ用意されてないらしいのでCoqやAgdaの知識がないと使いこなすのは難しいかもしれない
- [Isabelle](https://isabelle.in.tum.de)
  - この中では唯一Curry-Howardをベースとしない形式証明(依存型もない)
  - 豊富なライブラリと強力なproverによる自動証明が魅力
  - 「普通の」数学をやりたいならこれがおすすめ
  - 公式のリファレンスはあるが機能は膨大、非公式ドキュメントも少ないので習得は骨が折れるかも

## 入門書等

出版されていてもドラフト版のpdfが無料で読めるものが多い

- [Software Foundations](https://softwarefoundations.cis.upenn.edu): Coqを使用しプログラム意味論的な話題が中心。Coqの説明ばかりというわけではないので他言語ユーザーでも読めると思われる。
- [Concrete Semantics](http://concrete-semantics.org): Isabelle/HOLを使用しこちらもプログラム意味論系の証明を行う本。前半はIsabelleの説明で後半はコンピューターサイエンスという構成。
- [Certified Programming with Dependent Types](http://adam.chlipala.net/cpdt/): Coqで依存型を学べる本。Coqに限らず定理証明で幅広く使える話が書いてあるので非Coqユーザーでもおすすめ。
- [Verified Functional Programming in Agda](https://www.amazon.co.jp/dp/B01K0MK318/ref=cm_sw_r_tw_dp_U_x_sYAmCbKFTKKX0): Agdaの本、読んでないので詳細知らず
- [Coq'Art](https://www.labri.fr/perso/casteran/CoqArt/): Coqの定評のある入門書、詳細は知らない
- [Coq/SSReflect/MathCompによる定理証明](https://www.morikita.co.jp/books/book/3287): 日本語(！)で書かれたCoqの入門書

## 入門記事等

読み物もあり

- [F*(F Star)の複雑な型システムの何が嬉しいのか？](http://yuchiki1000yen.hatenablog.com/entry/2018/07/07/155854): 依存型のモチベーションの話
- [Coqで学ぶ証明プログラミング！ テストだけでなく「証明」で安全性を保証する](https://employment.en-japan.com/engineerhub/entry/2018/08/10/110000)
- [プログラミング Coq　〜 絶対にバグのないプログラムの書き方 〜](https://www.iij-ii.co.jp/activities/programming-coq/): Coqの丁寧な入門記事
- [Learn you an Agda](http://learnyouanagda.liamoc.net)
- [Agda による圏論入門](http://www.ie.u-ryukyu.ac.jp/~kono/lecture/software/Agda/index.html): 圏論と定理証明多少知ってる人向け

#### 私が書いてる記事とか

それなりに色々書いたつもりではあるので まぁ参考になればくらいの気持ちで(話半分で読んだ方がいいやつとかもある)

- [あのとき知りたかったCoqの話](http://myuon-myon.hatenablog.com/entry/2017/04/16/195944)
- [Theorem Prover Leanの紹介](http://myuon-myon.hatenablog.com/entry/2016/01/09/212750): Lean2と他言語との比較とか
- [Theorem Prover Haskellの紹介](http://myuon-myon.hatenablog.com/entry/2016/12/01/221636): Haskellで定理証明する話、お遊びとして
- [Isabelle入門の入門](https://qiita.com/myuon_myon/items/11bb5bfc2e274fdaea7c)
- [一人Computer Science Advent Calendar 2017](https://qiita.com/advent-calendar/2017/myuon_myon_cs): 前半にIsabelleの解説 後半にProof Assistantを作る話を連載してます

## その他リソース

- [定理証明支援の紹介](https://qiita.com/junjihashimoto@github/items/a4ed0fa528ef2d831d6c)
- [Coq/SSReflect/MathCompの設定](https://staff.aist.go.jp/reynald.affeldt/ssrcoq/install.html): Coqのインストールガイド
- [Coqで独習するならどのページがいい？と聞かれたときのメモ](https://qnighy.hatenablog.com/entry/20101220/1292829222)
- [誰も書かないCoq入門以前の話](http://d.hatena.ne.jp/m-hiyama/20141207/1417948454)
- [The Agda wiki](https://wiki.portal.chalmers.se/agda/pmwiki.php)
- [Handbook of Practical Logic and Automated Reasoning](https://www.cl.cam.ac.uk/~jrh13/atp/): MLでproof assistantを作る本
- [Advanced Topics in Types and Programming Languages](https://www.amazon.co.jp/Advanced-Topics-Types-Programming-Languages/dp/0262162288): TaPLの続編、依存型の話もあり
- [定理証明手習い](https://www.lambdanote.com/products/littleprover-paperbook): Schemeを使って定理証明に入門する本、最近出たやつ
- [Simply Easy! An Implementation of a Dependently Typed Lambda Calculus (Andres Loh, Conor McBride, Wouter Swierstra)](http://strictlypositive.org/Easy.pdf): Haskellでdependent type入りのラムダ計算の実装を書く論文
- [Homotopy Type Theory](https://homotopytypetheory.org/book/): The HoTT Bookと言われるやつ
- [Write Yourself a Theorem Prover in 48 Hours (その1)](https://qiita.com/kikx/items/10d143edc090bdfec477): Coq風のproof assistantを作る記事
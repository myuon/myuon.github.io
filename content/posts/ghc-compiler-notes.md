---
title: GHCのソースコードのノートを読むやつを作った
date: 2019-04-04T22:30:29+09:00
tags: [ "Haskell" ]
---

タイトルがふわっとしてるけど見れば多分わかる。

[ghc-compiler-notes](https://ghc-compiler-notes.readthedocs.io/en/latest/)

## 経緯とか

注意: 作ったと書いてるが私の力ではなく主に水無さん([@mizunashi-mana](https://github.com/mizunashi-mana))とわどさん([@waddlaw](https://github.com/waddlaw))のお力添えによるところが大きい。

GHCのソースコードにはNoteと称して有益な(GHCの内部実装等に関する)情報が書いてあることは有名だと思うけど、実際にそれはまとまったりはしてなかったので知る人ぞ知る、みたいな情報であった。こういう他のドキュメントには書いてないような貴重な情報が誰にも読まれることなく眠っているのはもったいないと常々感じていたのでそれを読めるようにしたかった。

このプロジェクトは最近GitLabに移った方の[ghc/ghc](https://gitlab.haskell.org/ghc/ghc)のソースコードに埋められているNotes部分を抜粋しそれを比較的読みやすい形で並べて整理したものである。


## 現在の仕様一覧(ざっくり)

- compiler, libraries, utils以下にあるモジュールを再帰的に読んでドキュメントとして吐くようになっている
- ghc/ghcはデプロイのたびにクローンしているので、ドキュメントの参照元は比較的最近のmasterであることが期待される
- 各Noteに元ソースへのリンクあり
- (Noteのフォーマットがまともなら)箇条書き等にも対応
- 色々欠陥があるコードブロックの表示


## 中身(雰囲気)

実装は、checkoutしてきたソースコードの中身を辿ってコメントの該当箇所を抜き出してきて、reST形式てファイルに吐きreadthedocsに突っ込んでいるだけである。

ちなみにNoteの箇所を抜き出す実装は私は完全にノータッチで上に上げたお二人がやってくれたので詳しいことはよくわかりません。

ちなみにこのNoteは書かれている場所によりフォーマットがまちまちで、Noteのタイトル表からコメントの形式や箇条書きの形式、コードブロックの指定の仕方に至るまで全く統一されていないという荒れっぷりなので実装は大変だったと思う。


## 今後の課題等

- コードブロックはfalse positiveとfalse negativeだらけなので流石になんとかしたい(しかしフォーマットが統一されてなさすぎてかなり厳しい)
- 文章中の他のノートへのリンクをちゃんとリンクとして辿れるようにしたい
- masterだけでなくて特定のタグがついたghcのバージョン等をスナップショットとして見られるようにしたい

## CIについて

このプロジェクトで主に私が頑張ったところがCIだったのでCIを少しだけ解説。

CIはCircleCIを使っている。プロジェクト自体のビルドはcabalでもstackでも出来るが、Haskell公式のdocker imageがcabalとghcが入ったやつなのでそれを使っている。多分docker imageは次のいずれかを使うと良い。

- [haskell](https://hub.docker.com/_/haskell): 7.8, 7.10, 8.0, 8.2, 8.4, 8.6などがある
- [fpco/haskell](https://hub.docker.com/r/fpco/haskell/): GHC8.0.2版のみ。stackなので他のものはインストールすればよいというのは確かにそうだが…

公式のはまだ8.6.4がリリースされてないみたいなので必要であれば[これ](https://github.com/freebroccolo/docker-haskell/issues/87)を見ると良い。

また、CircleCIであれば[haskell-build](https://circleci.com/orbs/registry/orb/haskell-works/haskell-build)というorbが用意されているので、単にビルドするだけならこれが簡単で良いと思う。

### ビルドコマンド

キャッシュは、今のところは `cabal new-update` してからindex.cacheのchecksumをみて `~/.cabal` を丸ごとキャッシュしている。よくわかってないんだけどこれで大丈夫なの？

あと、以後のjobでも使うので `dist-newstyle` もworkspaceに放り込んでる。

何かの参考になれば。

```yml
  build-test-8_6_3:
    working_directory: ~/workspace
    docker:
      - image: haskell:8.6.3
    steps:
      - checkout
      - run: cabal new-update
      - restore_cache:
          keys:
            - cabal-index-{{ checksum "~/.cabal/packages/hackage.haskell.org/01-index.cache" }}-v1
      - run: make build
      - run: make test
      - save_cache:
          key: cabal-index-{{ checksum "~/.cabal/packages/hackage.haskell.org/01-index.cache" }}-v1
          paths:
            - ~/.cabal
      - persist_to_workspace:
          root: .
          paths:
            - dist-newstyle
```

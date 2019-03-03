---
title: パストレーシングについて調べてる
date: 2019-03-03T19:33:25+09:00
tags: [ "CG" ]
---

前に入門記事を書いてそこから色々調べたりしてたのでその備忘録として

## アルゴリズムについて

カメラから出たレイをたどりながら光線のシミュレーションを行う単純なアルゴリズムをレイトレーシングと言って、それを確率的な計算によってオブジェクトの数に依らない計算量で計算できるように改良したものをパストレーシングと呼ぶらしい(正確な定義はよくわからなかったがアルゴリズムの差から名前が違うみたい)。

アルゴリズムの詳細については次とかを見るとよさそう。

- [memoRANDOM](https://rayspace.xyz/CG/)
- [物理ベースレンダラ edupt解説](http://kagamin.net/hole/edupt/edupt_v103.pdf)

パストレーシングアルゴリズムの初出は"The rendering equation (J. Kajiya, 1986)"か？

bidirectional, NEE, metropolis light transport, photon mappingあたりは実装してみたいがお勉強が先かも。

## NEE (Next Event Estimation)

悩みとして、memoRANDOMさんのサイトに載ってる通りに、3点のレンダリング方程式をベースにしたNEEを実装してみたけど寄与が小さすぎて全然効果がなかった。単に実装を間違えているだけか？

また、調べているとshadow rayを蓄積したあと反射を行い、そっちで同じ光源に向けてexplicitなrayが飛んだとしたら無視するみたいなアルゴリズムでNEEを計算しているサイトも見かけたけど、それは何か違いがあるのだろうかと思った。NEEの正しいアルゴリズムがよくわからない。(というか、本当はちゃんと平均とかを計算してどういうアルゴリズムなら正しい結果が得られるかは手で確認すべきかなと思う)

## Stratified Sampling

層化サンプリングによってサンプルの座標がいい感じに均等にばらけるようにとるといいらしい。これってどれくらいの改善になるのだろうか、気になる。

- [Stratified Sampling of Spherical Triangles](https://www.graphics.cornell.edu/pubs/1995/Arv95c.pdf)

## GPU

どうせならGPU使った計算もしたい。GPUでレイトレーシングやるみたいな話は調べると色々出てくる。

疑問としてロシアンルーレットとかの実装だと分岐が入る(というかレイごとの計算回数が見積もれない)わけだけどその辺はどうするのだろうか。調べた感じだと1レイ1スレッドにするのが普通っぽかったのと、ロシアンルーレットのときにどうするかみたいな話は出てこなかったので、計算を打ち切る代わりに寄与を0にするみたいな感じで並列処理を止めないように作っているのかもしれない。

そもそもシェーダー言語とかCUDAとかにパストレーシングアルゴリズムをナイーブに突っ込んでるのとかよく見るんだけど本当にそんなんでいいの？という気持ちになったりならんかったりする。

- [Path tracing on GPU](https://is.muni.cz/th/396530/fi_b/Bachelor.pdf)

## Unity

Unity(のComputeShaderなんか)を使うとGPUを使った計算が簡単にできる。要は単にHLSL(これはWindowsだから？)とのintegrationがUnityに用意されているというだけのことだけど、Unityは普通に解説も多いしGPUを使ったレイトレーシングの入門にはいいかもしれない。

- [GPU Ray Tracing in Unity – Part 1](http://blog.three-eyed-games.com/2018/05/03/gpu-ray-tracing-in-unity-part-1/)

例えば次のような画像が割と簡単に出せる。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">なるほど <a href="https://t.co/vgvv8ohDdk">pic.twitter.com/vgvv8ohDdk</a></p>&mdash; みょん (@myuon_myon) <a href="https://twitter.com/myuon_myon/status/1102139583599239168?ref_src=twsrc%5Etfw">2019年3月3日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## WebGL

人間に見せるUIとしてWebGLにして吐くのは結構ありかもしれないと思っていた。WebGLはRustを使っても吐けるみたいだった(けど中身は普通にshader言語書いてたのでRustで書けるとは言わない気もする)。

実際にWebGLでやってる例とかもあって面白かったのでなおさら。

- [gfx-rs/gfx](https://github.com/gfx-rs/gfx)
- [WebGL+GLSLによる超高速なパストレーシング](https://qiita.com/gam0022/items/18bb3612d7bdb6f4360a)
- [http://madebyevan.com/webgl-path-tracing/](http://madebyevan.com/webgl-path-tracing/)

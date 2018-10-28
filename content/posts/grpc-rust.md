---
title: RustとNode.js間通信にgRPCを使う
date: 2018-10-28T16:03:12+09:00
tags: [ "Rust", "JavaScript" ]
toc: true
---

gRPCしたくなった。具体的にはRustで作ってるデスクトップアプリケーションで、GUIをElectronで書きたいのでNode.jsと通信が発生するのでそれに使えないかなと思って調査した。

## gRPC(protocol buffers)とは

[gRPC](https://grpc.io)はgoogleが作ったRPC(remote procedure call)のフレームワークで、簡単に言うとサーバー/クライアント間の通信が言語を問わずできるよ！みたいなやつ。
RPC自体は見た目は普通の関数呼び出しみたいな感じで書けて、裏ではHTTP/2の通信に乗ってやりとりが行われるようになっている。実際にはRPCを定義してからそれを呼び出すためにはサーバーやクライアントで言語ごとにインターフェイスの定義とかをしなければいけないが、それを自動で生成してくれるのがgRPCコンパイラという感じ。

gRPCを使うには、[protocol buffers](https://developers.google.com/protocol-buffers/docs/proto3)というプロトコル定義言語(?)を`.proto`ファイルに書いてgRPCコンパイラで言語ごとにコンパイルを行う。2018/10/28現在では公式にサポートされてる言語がC++, Java, Python, Go, Rusy, C#, Node.js, Android Java, Obj-C, PHP, Dartなどなど多岐にわたる。Rustは非公式だけどプラグインがあるので使える。

gRPC/protocol buffersの個人的なポイントをまとめてみる。

長所:

- サポートされてる言語が多い
- ツール自体はしっかりしてるのであまりその辺で変にハマることはなさそう
- streaming通信なんかもサポートされてる
- protocol buffers自体が後方互換性を命を懸けて守るという強い意志のもとに設計されてる まぁこれはそのせいで面倒なこともあるので短所でもあるけど、多くの人にとっては長所になりうるかと思う
- protoファイルからドキュメント生成するやつもある([proto-gen-doc](https://github.com/pseudomuto/protoc-gen-doc))
- protocol buffers自体は普通にプログラミング言語による型定義みたいな感じで普通に書きやすい(少なくともswaggerみたいな地獄のyaml UXとかに比べたら断然楽)

短所:

- 公式ドキュメントが死ぬほど分かりにくい(Googleだからしょうがない説もあるが)
- ツールのインストール方法などが死ぬほど分かりにくい
- ~~現状ブラウザによるネイティブサポートがない(grpc-gatewayを使うといいらしいよ)~~ **[追記]** (grpc-webというので対応されたらしい) **[/追記]**
- 生成するコードにユーザー側の自由度がほぼないし自力でプラグインを書くのは多分大変(のでユースケースによっては全く使えないと思う)

最近はマイクロサービス間通信とかで採用されてる事例が多いみたい。実際にブラウザとの通信で使ってる人はそこまで多くない印象だった。

## RustでgRPC

Rustでサーバー側の処理を書く。

まず、上にも書いたようにprotoをRustコードに変換するgRPCコンパイラのRustプラグインが必要になる。これには`protobuf-codegen`と`grpcio-compiler`を使うといいよってあった。

```bash
# インストール
$ cargo install protobuf-codegen grpcio-compiler

# コンパイル
$ protoc --rust_out=. --grpc_out=. --plugin=protoc-gen-grpc=`which grpc_rust_plugin` example.proto
```

これによって生成されたRustモジュールを読み込んで使うことになるけど、それには[grpc-rs](https://github.com/pingcap/grpc-rs)を使った([grpc-rust](https://github.com/stepancheg/grpc-rust)というのもあるけどこっちは触ってない)。

サーバー側のプログラムは[こんな感じ](https://github.com/pingcap/grpc-rs/blob/master/examples/hello_world/server.rs)で書くと良い。

コンパイルすると、protocol buffersのmessageが定義された`example.rs`と、RPC関連が定義された`example_grpc.rs`が生成される。

## Node.jsでgRPC

Node.jsでクライアント側の処理を書く。

Node.jsでは、gRPCのコンパイラがやってる処理を動的にやるライブラリとかもあるようで、その場合にはprotoファイルを直接食わせて書けるので事前にコンパイルとかが不要になる(`@grpc/proto-loader`を使うか、gRPCは不要でprotocol buffersだけなら`protobufjs`あたり)。が、まぁコード生成する方がいいと思うのでそうする。

Node.js用のgRPCコンパイラプラグインはgrpc-toolsを使う(この情報がどこにもはっきり書いてなくてマジでキレそうだった。grpcのexamplesのREADMEを見てたらこっそり書いてあってQuickStartにちゃんと書け以外の感情を失った)。

```bash
# インストール
$ npm i -g grpc-tools

# コンパイル
$ protoc --js_out=import_style=commonjs,binary:. --grpc_out=. --plugin=protoc-gen-grpc=`which grpc_tools_node_protoc_plugin` example.proto
```

コンパイルすると、protocol buffersのmessageが定義された`example_pb.js`と、RPC関連が定義された`example_grpc_pb.rs`が生成される。


## 通信

通信自体はRust側でサーバーを上げてNode.jsからクライアントを叩くだけ。シリアライズとデシリアライズはprotocol buffersが勝手にやってくれるので簡単。

## 結末

最初にも書いた通り今書いてるアプリケーションでgRPCを使う予定だった。しかし、grpcio-compilerで生成されるRustのコードはサーバー側の処理が欲しい形になってなかったので使えないことが分かったりした。

(具体的には、サーバーにコールバックをどんどん登録していく形になってて、コールバックは当然 `Sync + 'static` などを要求される。しかし今作ってるアプリケーションは動画編集ソフトで、そこでは動画ファイルストリームに関する処理はスレッドセーフではなく `Sync` になってないのでこれを用いた部分をコールバックに登録できない。どうしようもねえなこれ(肩をすくめる))

gRPCを捨ててprotocol buffersだけ使おうかとも(RPCしたい部分はZMQとか使うとよさそう)思ったけど、protocol buffers自体はserde対応しておらず、自力でserializer/deserializerを書かされそうになって闇っぽかったのでこれもナシになった。

というわけでおとなしくserdeとZMQで通信してSDKは心のこもったハンドメイドになりそう。悲しいね。

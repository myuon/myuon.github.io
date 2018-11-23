---
title: Lambda FunctionをReasonで書く
date: 2018-11-23T21:00:48+09:00
tags: [ AWS, Reason ]
---

# Reason ML、やっていこうな

世はまさに大サーバーレス時代なのでLambda Functionやっていきというお気持ち。

AWS Lambdaで現時点(2018年11月)で対応されている言語はNode.js, Python, Go, C#(dotnet), Javaの5つ。このうち後ろ2つはコールドスタートが激遅なので使い物にならない。で前3つのうちではドキュメントの多いNode.jsが安定ですが、Node.jsをランタイムに採用するとしてしかしJSは書きたくない、そういうときにReason MLはいい感じな選択肢なのでは？というのがこの記事の趣旨です。

## serverless-reason

serverless frameworkというサーバーレスアプリをやるのにとても便利なツールがあって、それのReasonで動くテンプレートを作っておいたので好きに使ってくださいという感じ。

<div class="github-card" data-github="myuon/serverless-reason" data-width="400" data-height="" data-theme="default"></div>
<script src="//cdn.jsdelivr.net/github-cards/latest/widget.js"></script>

以下このプロジェクトの中身の解説をする。

## echo.re

Lambda Functionとしてechoというものが`src/functions/echo.re`に定義されている。

```ml
/* Sorry I'm a lazy person! */
type event = {
  .
  "pathParameters": Js.Dict.t(string),
};

type context = unit;
type callback = (. Js.null(string), Js.Json.t) => Js.Promise.t(unit);

type response = {
  .
  "statusCode": int,
  "body": string,
};

let handler : (event, context, callback) => Js.Promise.t(response) = (event, _, _) => {
  Js.log("hello");

  {
    "statusCode": 200,
    "body": event##pathParameters |> Js.Dict.unsafeGet(_, "value"),
  }
  |> Js.Promise.resolve;
};
```

普通のLambda Functionを雑にラップしただけです。eventの型としてpathParametersしか乗せてないしcontextはunitで潰してしまっているので**この型定義は真似しないでください**(じゃあ乗せるなという話ではあるが)。

ここではcallbackは使わずPromiseにしているが、callbackを使いたい場合には必ずGuaranteed Uncurryingする(型定義を`(. a,b) => ..`の形にし、呼ぶときは`callback(. x,y)`の形で呼ぶ)ことを忘れないように。そうでないとうまく動かない。

callbackとかは微妙に使いにくいのでPromiseで書いて途中で例外による大域脱出をtry-catchで捉えられるようにするみたいなやり方がReasonでラムダ書くときはなんやかんや一番書きやすそうと思った。ていうかasync/awaitを早く使わせてくれ。

ちなみにaws lambdaの型定義である[ahrefs/bs-aws-lambda](https://github.com/ahrefs/bs-aws-lambda)というのもあるが、私はどうも馴染まなかった。型が強いのはいいんだけど逐一コンストラクタをかぶせたりパターンマッチするのめんどくなって普通にjsonで書いた方が分かりやすいのでは？と思ったので上でもそうしてる。


## serverless-webpack

serverless-webpackで一緒にバンドルする設定だが、BuckleScriptのランタイムはwebpackにかけないようにしてる(毎回やってると時間かかりそうだし…)。`serverless package`すると、`node_modules/bs-platform`以下のコンパイルされたjsだけzipに入るようになってる。

私はyarn使ってるのでその設定になってるけど気に入らん場合は適当に変えてください。

## その他

- bsbが`.bs.js`ではなく`.js`を吐くようにしてるのはそうでないとhandlerの設定ができないため
- `bs-json`という、Reasonのレコード型のjson用のserializer/deserializerを書くためのライブラリがあるがこれはコンパイル後のファイルがnpm packageに含まれてないので自力でビルドしないとうまくパッケージングができない。Lambdaで使うときにはbs-jsonは使わない方が無難かも
- 上のコードを実行して、ホットスタートで大体実行時間`0.5ms`、消費メモリ`45MB`だった
- ちなみにパッケージのサイズ(`bs-platform`のランタイムも含め)は1MBくらい
- Reasonで書いたラムダは実行時エラーとして`{ "errorMessage": "RequestId: ... Process exited before completing request" }`みたいなのを返してくることがある。JSの実行時エラーはこの形で出ることがあるみたいで、その場合はちゃんとログを見た方がいい

# おわりに

DynamoDBとReason/LambdaとAPI Gatewayでちょっくら簡単なアプリケーションを書いてみたんだけどデプロイでハマったり色々したのでminimalなプロジェクトテンプレートはさすがに欲しいと思って作りました。

それはそうとX-Rayが便利なのでできれば使いたいのだけれど、xray-sdkがでかすぎて入れる気にならんのどうにかならんもんか。ていうかaws-sdkはAWS側で用意してくれているんだからxrayを貼ったsdkも用意してくれてもよさそうなもんだけど。

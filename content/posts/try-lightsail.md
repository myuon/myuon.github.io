---
title: Lightsailでやっていくサービス開発
date: 2020-04-03T01:10:11+09:00
tags: ["AWS"]
---

## ジト目王国を始めた

[ジト目王国](https://jitome.ramda.io)というサービスを始めました。ガチャでみょんポイントが引けます。(はい)

ところでこのサービスは現在AWSで維持されていて、固定費としてかかるのは月$3.5程度で済んでる(厳密には通信費とかあるけどGB単位でアレしないとかからないのでまぁ今の位の規模なら無視していいと思う)ので、せっかくなのでAWSでのあれこれを解説していく。

## アプリの構成

- APIサーバー: Rust製
- DB: MySQL
- ↑の2つをdocker-composeに乗せてサービスとして運用(この構成だと1インスタンスにDBとAPIサーバーが同居しているのでAPIサーバーに負荷がかかるとDBが死ぬ危険性がある。まぁあくまで個人開発の小規模な時期にお金を頑張って節約したいという前提があるということで…)
- クライアントサイドはNowでホスティング

## Lightsail

LightsailはEC2をいい感じにパッケージングしたみたいなサービス。AWSとは思えないほど管理画面が使いやすいことと、基本的に全部のせでインスタンスだけでなく監視(CloudWatch)やロードバランサー(ALB)やDNSレコード管理(Route53)などが全部中途半端な状態でついてくるという便利なのかそうでないのかよくわからない感じのサービス。  
使い方として(実際AWSも言っているが)最初はLightsailで維持して、規模が大きくなってきたらAMIを吐いてEC2に移行するのが割とおすすめ。

## インフラ構成

### インスタンスの確保

インスタンスは適当にぽちぽちして確保する。一番安いプランだと$3.5で、512MBと1vCPU(t2.nano程度のスペック)、20GBのEBSボリュームなどがついてくる。AWSでサービス開発してるとなんやかんや色々なサービス使わせられて、覚えるのが大変な上、合計利用料金が慣れないと読みづらいというのが解消されていて割と良いと思う。このプランで、Amazon Linuxを選択する。

一つ注意としては、AMIが現在Amazon Linux 2ではなくAmazon Linuxのせいで、情報を探すときは気をつけたほうがいい。他のディストリビューションでもいいけどAmazon Linux使っておくほうが多分何かと便利。

### SSMの設定

LightsailはデフォルトだとHTTPの80番ポートとSSHの22番ポートが空いているが、まぁ22番ポートなんぞ全世界公開したくないし2020年なのでインスタンスへはSSM セッションマネージャー経由でアクセスをする。注意としてLightsailは現状(公式には)セッションマネージャーに対応しておらず、さらにAmazon Linuxだとagentが古いので自力で頑張る必要がある。

- amazon-ssm-agentをアップデートする: https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html
- 次に、SSMを利用するためアクティベーションコードの発行を行う: https://qiita.com/kooohei/items/35340bd9d36163c33f54
  - 最初にAmazonSSMManagedInstanceCoreをポリシーとしてアタッチされたロールを作成する
  - アクティベーションコードを発行する
  - インスタンスの中に入って、 `amazon-ssm-agent` コマンドを叩いてアクティベーションを行う
  - あとは22番ポートを閉じてから、SSMのセッションマネージャーからセッションを起動する

### アプリを動かす

- dockerとdocker-composeをインストール: https://qiita.com/shinespark/items/a8019b7ca99e4a30d286

インスタンスに入って適当に `docker-compose up` とかする。この辺はAWS関係ないのでまぁ省略。

### EIPの付与

- アプリが動いたら静的IPでアクセスできることを確認する
- Elastic IPをLightsailの中で作成して貼り付ける。EIPはアタッチしているインスタンスが動いてると無料だけどインスタンスが停止しているときやどのインスタンスにもアタッチされてないと課金されるので無闇に作らないようにしよう。

### SSLターミネーション

2020年なのでHTTPSに対応する必要があるわけだけど、自分で証明書の鍵の管理とかしたくないでござる〜ってことでマネージドサービス使いたいならCloudFrontを使うとできるが、ただ労力に見合ってない感じがあるのでnginxコンテナ生やすほうが早いでしょというのはそうかも…。まぁCloudFront入れておけばSSLターミネーションの他についでにキャッシュとDDoS対策も付いてくるのでお得！(ほんまか)

- まずRoute53でドメインを取得する(`example.com` など)
- ACMで証明書を発行する。例えば `example.com` をwebサイトそのもののために使って、APIサーバーでは `api.example.com` を使いたい場合はACMで `*.example.com` の証明書を発行する必要があることと、us-east-1リージョンで発行する必要があることに注意。
- Route53でAレコードを登録する。ここで使うゾーンはLightsailインスタンス専用のやつで外には公開しないものなので、 `api-lightsail.example.com` みたいな適当なやつにする
- CloudFrontでアレコレの設定を行う: https://dev.classmethod.jp/articles/how-to-install-original-domain-ssl-wordpress-with-amazon-lightsail/
  - Origin Domain Nameには `api-lightsail.example.com` を登録する
  - Alternate Domain Names (CNAMEs)に `api.example.com` を登録する
  - ACMで取得したSSL証明書を選択する
  - キャッシュの挙動は基本的にキャッシュしないでOriginへ転送するような設定にしておく。APIサーバーとして使うならキャッシュしたいことはあんまないと思われるし、キャッシュする設定だとAuthorizationなどのヘッダーが消えたりしてむしろ不便なのでキャッシュしなくていいと思われる。
- 最後に、Route53でAレコード・ALIASのエイリアス先として、上で作ったCloudFront distributionのドメインを選択する。

上手く行ってればこれでAPIサーバーにHTTPSで接続できるようになっている。ただCloudFrontはデプロイに10-20分程度かかるし、HTTPSを使うだけにしては必要な設定も複雑なのでまぁ玄人向けの解決策感は否めないですね。

ちなみにDNSレコードの設定はLightsailからなぜか可能だが、まぁこの辺の作業どうせLightsailでは完結しないのと慣れてるのでRoute53使ってる。

### スナップショットの設定

Lightsailは自動スナップショットの設定が出来る。24時間ごとにスナップショット吐けるので、とりあえず入れておくと良い。

## おわりに

ジト目王国の開発がんばる

---
title: DynamoDB LocalをTerraformから使う
date: 2019-02-11T00:22:05+09:00
tags: [ "AWS" ]
---

タイトルの通り。大体以下のPRの説明読めば分かる。

https://github.com/hashicorp/terraform/pull/2825

## Terraform側の設定

local envで環境を作ってDynamoDB Localをテスト用途で動かすという前提。以下がproject structure。

```
<project root>
  - infrastructure
    - local/
      - main.tf ここにDynamoDB Localの設定を入れる
    - modules/
      - dynamodb/table.tf ここにテーブルの設定など
```

`infrastructure/local/main.tf`では、endpointsを指定することができる。(デプロイ時にこのendpointを参照してテーブルを作ったりする)

```
provider "aws" {
  region = "ap-northeast-1"
  endpoints {
    dynamodb = "http://localhost:8000"
  }
}
```

DynamoDB Localは普通に動かせばよい。

port:8000で起動させたら、いつも通り`terraform -e dev apply`でDynamoDB Localにテーブルができる。

## スクリプト

テストで使おうと思ったら、このDynamoDB Localを立ち上げる→terraform apply→テスト実行→DynamoDB Localを落とすを何度も繰り返すことになって面倒なので、私はMakefileを書いている。

```make
install:
	mkdir -p ./infrastructure/local/.dynamodb
	cd ./infrastructure/local/.dynamodb; \
	wget https://s3-ap-northeast-1.amazonaws.com/dynamodb-local-tokyo/dynamodb_local_latest.tar.gz; \
	tar -xf ./dynamodb_local_latest.tar.gz

test:
	$(MAKE) startTest

	# ここでテスト
	export ...; \
	go test ./functions/... && $(MAKE) endTest || $(MAKE) endTest

endTest:
	kill `cat .dynamo.pid`
	rm .dynamo.pid
	rm shared-local-instance.db

startTest:
	{ java -Djava.library.path=./infrastructure/local/.dynamodb/DynamoDBLocal_lib -jar ./infrastructure/local/.dynamodb/DynamoDBLocal.jar -sharedDb & }; echo $$! > .dynamo.pid
	sleep 1

	cd infrastructure/local && terraform apply -auto-approve
	sleep 2
```

(上のproject structureで`infrastructure/local/.dynamodb`に色々入れるという前提)

色々汚いけどまぁ許してくれって感じ。

## おまけ

DynamoDB Localは実はStreamsにも対応してるんだけど、そもそもLambda ARNを設定する関係上どうせローカルでは動かないのでテスト時には切っている。

あとTerraformは柔軟性がなさすぎてつらいのでGoでTerraformをライブラリとして使ってtfファイルをコードで生成みたいなことやりたいなーとか思った。aws-cdk的なやつ。(調べてないけどすでにあったりしないのかな)

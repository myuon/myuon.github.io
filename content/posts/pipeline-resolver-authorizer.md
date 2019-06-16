---
title: Pipeline Resolverを使ったAppSync Authorizerパターン
date: 2019-06-16T14:26:31+09:00
tags: [ "AWS" ]
---

調べたけどあんまり情報がなかったので。

## AppSync Pipeline Resolver

AppSyncにはPipeline Resolverというリゾルバーがあり、これによって複数のリゾルバーを指定できる、とある。

CFnにはfunctionConfigurationを指定するといいよと書いてある。serverless-appsync-pluginだと次のように書ける。

```yaml
custom:
  appSync:
    mappingTemplates:
      - type: Query
        field: testPipelineQuery
        request: './mapping-templates/before.vtl' # the pipeline's "before" mapping template
        response: './mapping-templates/after.vtl' # the pipeline's "after" mapping template
        kind: PIPELINE
        functions:
          - authorizeFunction
          - fetchDataFunction
    functionConfigurations:
      - dataSource: graphqlLambda
        name: 'authorizeFunction'
        request: './mapping-templates/authorize-request.vtl'
        response: './mapping-templates/common-response.vtl'
      - dataSource: dataTable
        name: 'fetchDataFunction'
        request: './mapping-templates/fetchData.vtl'
        response: './mapping-templates/common-response.vtl'
```

でこれが意外とわかりにくいのだがドキュメントをよく読むと次のような意味であることがわかる。

- リゾルバーに対して指定できる処理の単位を"function"とここでは呼んでいる
- functionを複数指定すると、それぞれが順番に実行される
- functionには(通常のリゾルバー同様)リクエスト・レスポンスマッピングテンプレートを指定する
- 上記とは別に、pipelineの最初と最後にマッピングテンプレートを指定する
- DynamoDBリゾルバー、Lambdaリゾルバーも内部では1つの"functionからなる"
- Pipeline ResolverでLambdaに通してからDynamoDBに送るみたいなことをしたいなら2つのfunctionをlambda dataSource, dynamodb dataSourceを指定して作成する必要がある

で、上のような例だと次のように処理が進む

```
before mapping template
↓
authorizeFunction request mapping template
↓
authorizeFunction本体
↓
authorizeFunction response mapping template
↓
fetchDataFunction request mapping template
↓
fetchDataFunction本体
↓
fetchDataFunction response mapping template
↓
after mapping template
```

functionという概念はpipeline resolverにしか出てこないが他のリゾルバーでも内部的には使われてるとみなして良いと思う。

## Authorizer

上の例でもあるように、DyanmoDB Resolverにcustom authorizerを付けたいというようなユースケースではPipeline Resolverを使うのが良い。

設定例を以下に示す。

```yaml
(serverless.yml)
custom:
  appSync:
    mappingTemplates:
      - type: Mutation
        field: addCollection
        request: ContextRequest.vtl # before
        response: JsonResponse.vtl # after
        kind: PIPELINE
        functions:
          - authorizer
          - addCollection
      functionConfigurations:
      - dataSource: authorizer
        name: authorizer
        request: AuthorizerRequest.vtl
        response: AuthorizerResponse.vtl
      - dataSource: collection
        name: addCollection
        request: AddCollection.vtl
        response: JsonResponse.vtl
```

```
(ContextRequest.vtl; 特に何もしない)
$util.toJson($context)

(JsonResponse.vtl; 特に何もしない)
$utils.toJson($context.result)

(AuthorizerRequest.vtl; Lambda Resolverを呼ぶときと同様の設定)
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": $utils.toJson($context)
}

(AuthorizerResponse.vtl; Lambdaでエラーがあるとそこでエラーを返す、それ以外は素通し)
#if($context.error)
  $util.error($context.error.type, $context.error.message)
#end

$util.toJson($context.result)

(AddCollection.vtl; DynamoDB Resolverを呼ぶときと同様の設定、ここでは権限のチェックとか色々してる)
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": { "S": "${util.autoId()}" },
    "sort-id": { "S": "detail" }
  },

  #set ( $account = $context.prev.result )

  ## Check ownership
  #if ( $account.id != $context.arguments.owner )
    $util.unauthorized()
  #end

  #set ( $args = $util.dynamodb.toMapValues($context.arguments) )
  #set ( $args.created_at = $util.dynamodb.toNumber($util.time.nowEpochSeconds()) )
  #set ( $args.updated_at = $util.dynamodb.toNumber($util.time.nowEpochSeconds()) )

  ## Set title
  #if ( !$args.title )
    #set ( $args.title = $util.dynamodb.toString("No title") )
  #end
  "attributeValues": $util.toJson($args)
}
```

Authorizer Lambdaの中ではJWTのverificationを行ってユーザー情報を取り出し、後続のDynamoDB Resolverでは`$context.prev.result`という形でそれを受けている。これはPipeline Resolverで直前のfunctionの結果を参照する機能で、これらを組み合わせるとAPI GatewayでのLambda Authorizer相当のことがAppSyncでも出来る。

## 余談: Authorization header in Amplify

上のように自前でAuthorizerを入れたいということは(認可はCognito等に頼らず)サービス内で独自のトークンを発行してる場合が多いと思う。その場合、クライアントからAuthorizationヘッダーにトークンを載せる必要があるが、Amplifyのclientとかだとそれをするには手で設定をする必要がある。

例えばaws-appsyncを使っている場合には次のようにすればよいし、

```js
import AWSAppSyncClient, { AUTH_TYPE, createAppSyncLink, AWSAppSyncClientOptions } from 'aws-appsync';
import { ApolloLink } from 'apollo-link';
import { setContext } from "apollo-link-context";
import { createHttpLink } from "apollo-link-http";

const AppSyncConfig = {
  url: aws_config.aws_appsync_graphqlEndpoint,
  region: aws_config.aws_appsync_region,
  auth: {
    type: AUTH_TYPE.API_KEY,
    apiKey: aws_config.aws_appsync_apiKey,
  },
  disableOffline: true,
} as AWSAppSyncClientOptions;

const client = new AWSAppSyncClient(AppSyncConfig, {
  link: createAppSyncLink({
    ...AppSyncConfig,
    resultsFetcherLink: ApolloLink.from([
      setContext((request, previousContext) => ({
        headers: {
          ...previousContext.headers,
          Authorization: `Bearer ${token}`,  // ここ
        }
      })),
      createHttpLink({
        uri: AppSyncConfig.url,
      })
    ])
  } as any)
```

aws-amplifyを使っているなら次のようにすると良い。

```js
Amplify.configure(awsconfig);
Amplify.configure({
  API: {
    graphql_headers: async () => {
      return {
        'Authorization': `Bearer ${token}`  // ここ
      };
    }
  }
});
```

なおトークンの管理として、nodeなら環境変数に、ブラウザ上ならcookieまたはlocalStorageに入れるでまぁいいのかなと思う。

上の設定ではクライアント生成時にheaderの設定を書く必要があって、外から引数として渡すのは難しいので。

## 終わりに

AppSync早くLambda Authorizer正式に対応してくんないかな〜〜〜

cf: https://github.com/aws/aws-appsync-community/issues/2


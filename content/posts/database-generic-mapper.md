---
title: Genericなデータマッパーを書いた
date: 2019-09-28T17:15:06+09:00
draft: true
tags: ["haskell"]
---

まだライブラリとしては公開してませんが

## 背景

Haskell でサーバーサイドを書いてみようと思い立って色々やっていたところ、ORM 的なものが欲しい気持ちになってきた。
業界では persistent がデファクト感あるが、思ったほど細かいところに手が届かない(？)上にドキュメントが全然なくて使う気がなくなったので自分なりに解決策を考えた結果 database-generic-mapper というパッケージを作るに至った。

(実際のところ私は全然 persistent の全容を把握していない、そもそもドキュメントがないので把握のしようがない)

ていうか Generic Programming なるものを初めてやったけど普通に便利だった。TH より簡単で使いやすいのでアイデア次第で色々できそうではある(今更〜〜〜〜)。

## database-generic-mapper

database と銘打ってるが実体はただの record mapper 的な何かである。

特徴:

- Generic インスタンスなレコードと値の列を mapping してくれるやつ(DB にデータを保存することを考えると mapping するレコードは Generic インスタンスになっていると仮定しても良いだろうという感じで)
- TH なし
- 実際のデータのマッピングはライブラリ側の型クラスを使っているので自分で型を定義してインスタンスを書けば挙動はカスタマイズ可能
- 私は一応 MySQL で使ってるが特に DB 依存はない気がする(ただしマッピングされる先の型はライブラリ側で定義されてるものから選ぶ必要はある)
- 本当に誰でも思いつきそうな仕組みなので絶対すでに作られてるでしょって思って調べたけど見つからなかった…何でみんな TH するんだ…レコード定義したくないのか…

### 使い方

適当なデータ型を定義する。制約を書きたいときは幽霊型に載せる(これは attribute として後で文字列のリストとして取得可能)

mapper は `(:-)` だけは特別扱いしていて、 `a :- xs` を後で `(a,[String])` の型に mapping する(`:-`ではないときは、 `(a,[])`に mapping する)

```hs
data Sample = Sample {
  key :: VarChar 20 :- '["PRIMARY KEY"],  -- 制約書きたいときは (:-) を使う
  name :: BigInt :- '["NOT NULL"],
  single :: String
} deriving (Eq, Show, Generic)

-- レコードのフィールドは全て次の型クラスのインスタンスである必要がある
-- SQLValuesはStringやIntなどのunion
class SQLField a where
  fieldType :: a -> String
  encode :: a -> SQLValue
  decode :: SQLValue -> a
```

MySQL で使う都合上、 `VarChar (s :: Nat)` や `BigInt` を定義しているがこれらはインスタンスを導出するためのただの newtype wrapper である(実体は Text や Int64 など)

#### recordTypeOf

レコードの情報を取りたいときは `recordTypeOf` を使う(これは CREATE TABLE のクエリを作るときに使ってる)

```hs
recordTypeOf Sample{}
{-
  ==  ( "Sample"
      , M.fromList
        [ ("key"   , ("varchar(20)", ["PRIMARY KEY"]))
        , ("name"  , ("bigint", ["NOT NULL"]))
        , ("single", ("text", []))
        ]
      )
-}
```

#### mapToSQLValues

レコードを column とデータの組に mapping するときは `mapToSQLValues` を使う

```hs
mapToSQLValues (Sample (Field $ VarChar "foo") (Field $ BigInt 100) "bar")
{-
  ==  [ ("key"   , SQLVarChar "foo")
      , ("name"  , SQLBigInt 100)
      , ("single", SQLText "bar")
      ]
-}
```

#### mapFromSQLValues

逆に column の名前とデータの Map からデータを復元するときは `mapFromSQLValues` を使う

```hs
mapFromSQLValues
  Sample{}
  ( M.fromList
    [ ("key"   , SQLVarChar "foo")
    , ("name"  , SQLBigInt 100)
    , ("single", SQLText "bar")
    ]
  )
{-
  == (Sample (Field $ VarChar "foo") (Field $ BigInt 100) "bar")
-}
```

第一引数にレコードをもらってくるが、これは型を固定するためだけではなく、デフォルト値を与えるためにも使える(第二引数に key がないときは第一引数のレコードから値を拾ってくる)

```hs
mapFromSQLValues
    Sample {key = Field $ VarChar "def", name = Field $ BigInt (-1)}
    (M.fromList [("name", SQLBigInt 100), ("single", SQLText "bar")])
{-
  == (Sample (Field $ VarChar "def") (Field $ BigInt 100) "bar")
-}
```

### 注意点

1 つ懸念事項があるとすると、このパッケージでは `Sample{}` のように穴開きのデータを有効活用することを念頭に置いて作っているので(そうでないとフィールドに値を埋めないといけないからかなりめんどくさいことになる)、StrictData 拡張を入れた正格レコードだと実行時エラーで動かないみたいになってしまうと思う。

特に、上のデフォルト値をレコードから引いてくるという実装は NULL な値への対応として入れているものなので(DB 側の NULL を積極的に使うことは想定していないので、値が取れなかったときのために一応デフォルト値は欲しいでしょみたいな感じで入れてある)、レコード全部 Maybe で包むみたいなことはしたくないな〜というわがままによりこうなっているという都合はある。ここはもうちょっと考えたほうがいいかもしれない。

## サーバー側のコード例

こういう感じでやりますみたいな

```hs
-- ドメインでの定義
data Entity = Entity
  { id :: Text
  , createdAt :: Int
  , ... }

-- リポジトリの実装での定義
data EntityRecord = EntityRecord
  { id :: VarChar 26 :- '["PRIMARY KEY"]
  , createdAt :: BigInt :- '["NOT NULL"]
  , ... }

fromModel :: Entity -> EntityRecord
fromModel = ...

toModel :: EntityRecord -> Entity
toModel = ...

-- List
list :: AppM [Entity]
list = runSQL $ \conn -> liftIO $ do
  result <- SQL.query_ conn "SELECT * FROM `entity`"
  return $ map (toModel . mapFromSQLValues) result

-- Create
create :: CreateInput -> AppM ()
create input = runSQL $ \conn -> liftIO $
  SQL.execute conn "INSERT INTO `entity` VALUE (?)" (SQL.Only $ SQL.VaArgs $ mapToSQLValues $ fromModel input)
```

## コード(incomplete)

最後にコードを載せるが、適当にそれらしい箇所を切り貼りしてきただけなので適当に補って読んでください。リポジトリにもコードあるけど明日には消滅してるかもしれない。

[リポジトリ](https://github.com/provenian/api-server/blob/34810dbd39a5a38507ffc679bf3a5a91c8705b08/database-generic-mapper/src/Database/Generics/Mapper.hs)

あと実装は死ぬほど雑なのでちゃんと使いたいときはちゃんと定義等してください(雑)

```hs
class SQLField a where
  fieldType :: a -> String
  encode :: a -> SQLValue
  decode :: SQLValue -> a

newtype VarChar (length :: Nat) = VarChar { getVarChar :: T.Text }
  deriving (Eq, Show)

instance KnownNat n => SQLField (VarChar n) where
  fieldType (_ :: VarChar n) = "varchar(" ++ show (natVal (Proxy :: Proxy n)) ++ ")"
  encode = SQLVarChar . getVarChar
  decode = VarChar . (\(SQLVarChar c) -> c)

newtype BigInt = BigInt { getBigInt :: Int64 }
  deriving (Eq, Show)

instance SQLField BigInt where
  fieldType _ = "bigint"
  encode = SQLBigInt . getBigInt
  decode = BigInt . (\(SQLBigInt t) -> t)

newtype Text = Text { getText :: T.Text }
  deriving (Eq, Show)

instance SQLField Text where
  fieldType _ = "text"
  encode = SQLText . getText
  decode = Text . (\(SQLText t) -> t)

-- ...以下フィールド定義用のwrapperを定義する

data SQLValue
  = SQLBigInt Int64
  | SQLVarChar T.Text
  -- ...以下型の定義が並ぶ
  deriving (Eq, Show)

---

data (:-) a (attrs :: [Symbol]) = Field { getField :: a }
  deriving (Eq, Show)

class GMapper f where
  grecord :: f p -> (String, [(String, String, [String])])
  gfields :: f p -> [(String, String, [String])]
  gfield :: f p -> (String, String, [String])

  gmapsTo :: f p -> [(String, SQLValue)]
  gmapsFrom :: f p -> M.Map String SQLValue -> f p

class GSelector f where
  gattrs :: f p -> (String, [String])
  gmapTo :: f p -> SQLValue
  gmapFrom :: SQLValue -> f p

instance (Datatype d, GMapper t) => GMapper (D1 d t) where
  grecord (x :: D1 d t p) = (datatypeName (undefined :: M1 _i d _f _p), gfields (unM1 x))

  gmapsTo x = gmapsTo (unM1 x)
  gmapsFrom r = M1 . gmapsFrom (unM1 r)

instance GMapper t => GMapper (C1 d t) where
  gfields x = gfields $ unM1 x

  gmapsTo x = gmapsTo (unM1 x)
  gmapsFrom r = M1 . gmapsFrom (unM1 r)

instance (GMapper r1, GMapper r2) => GMapper (r1 :*: r2) where
  gfields (r1 :*: r2) = gfields r1 ++ gfields r2

  gmapsTo (r1 :*: r2) = gmapsTo r1 ++ gmapsTo r2
  gmapsFrom (r1 :*: r2) xs = gmapsFrom r1 xs :*: gmapsFrom r2 xs

instance (Selector d, GSelector t) => GMapper (S1 d t) where
  gfields r = [gfield r]
  gfield s = let (ft,attrs) = gattrs (unM1 s) in (selName s, ft, attrs)

  gmapsTo r = [(selName r, gmapTo (unM1 r))]
  gmapsFrom r mp = maybe r (M1 . gmapFrom) (mp M.!? selName r)

instance (Mapper attrs, SQLField t) => GSelector (Rec0 (t :- attrs)) where
  gattrs (x :: Rec0 (t :- attrs) p) = (fieldType (undefined :: t), attrs (Proxy :: Proxy attrs))
  gmapTo = encode . getField . unK1
  gmapFrom = K1 . Field . decode

instance {-# OVERLAPS #-} SQLField r => GSelector (Rec0 r) where
  gattrs (x :: Rec0 r p) = (fieldType (undefined :: r), [])
  gmapTo = encode . unK1
  gmapFrom = K1 . decode

class Mapper a where
  attrs :: Proxy a -> [String]

instance Mapper '[] where
  attrs Proxy = []

instance (Mapper xs, KnownSymbol x) => Mapper (x : xs) where
  attrs (Proxy :: Proxy (x:xs)) = symbolVal (Proxy :: Proxy x) : attrs (Proxy :: Proxy xs)

type RMapper a = (Generic a, GMapper (Rep a))

mapToSQLValues :: RMapper a => a -> [(String, SQLValue)]
mapToSQLValues = gmapsTo . from

mapFromSQLValues :: RMapper a => a -> M.Map String SQLValue -> a
mapFromSQLValues r = to . gmapsFrom (from r)

recordTypeOf :: RMapper a => a -> (String, M.Map String (String, [String]))
recordTypeOf =
  (\(x, y) -> (x, M.fromList $ map (\(a, b, c) -> (a, (b, c))) y))
    . grecord
    . from
```

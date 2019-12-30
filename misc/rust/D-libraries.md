# D. ライブラリ

用途を問わずよく利用されるライブラリについて紹介する。

## serde

https://serde.rs

Serialize/Deserializeを行うためのライブラリ。(デ)シリアライゼーションを提供する `serde` と、それぞれのフォーマットごとに用意された `serde_*` 系のcrateからなる。

deriveマクロを利用するためには、Cargoの `derive` featureを有効にする必要がある。


## failure

https://rust-lang-nursery.github.io/failure/

エラー処理のためのライブラリ。Rust標準でもError型はあるが、自分でエラーを定義したくなった場合にそれをサポートするためのライブラリである。

基本的な使い方として、カスタムエラー型に `Fail` と `Debug` をderiveさせればよい。Errorの表現は

https://docs.rs/failure/0.1.6/failure/struct.Error.html

を用いて、 `Result<T, failure::Error>` が基本になる。標準ライブラリのErrorから変換するときは `Error::from_boxed_compat` を使い、カスタムエラー型に戻したいときは `Error::downcast` を使う。





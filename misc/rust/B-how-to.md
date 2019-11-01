# ドキュメントの読み方

## モジュールトップ

例: https://doc.rust-lang.org/std/sync/index.html

Rustのcrateのモジュールのページには次のようなものが表示されている。

- Re-exports: モジュール階層を無視してexportされたものや外部のクレートからexportされたものの一覧
- Modules
- Structs
- Enums
- Traits
- Functions
- Constants
- Type Definitions

検索する場合は上部の検索バーから探すのが良い

### Struct

例: https://doc.rust-lang.org/std/sync/struct.Arc.html

Structのページには次のようなものが表示されている。

- Methods: 直接メソッドとして実装されたもの
- Trait Implementations: トレイト実装が与えられているもの
- Auto Trait Implementations: コンパイラによって自動的にトレイト実装が導出されるもの
- Blanket Implementations: このStructに限らず(ブランケット記法によって実装された)一般的なトレイト実装であってこのStructにも関係があるもの

特に `.hoge` によって呼び出されるメソッドはMethodsではなくTrait implementationsにあるものである場合があるので注意。

# C. The Rust Standard Library

https://doc.rust-lang.org/std/

標準ライブラリについて知っておくべきことなどをいくつか説明する。


## データの変換

次の2つのtraitは頻出である

- From: https://doc.rust-lang.org/std/convert/trait.From.html
- Into: https://doc.rust-lang.org/std/convert/trait.Into.html

これらの実装を直接書くことは少ないが、多くの実装が定義されている上に多くのコードがこれを利用しているため重要度は高い。

例として `String` に変換可能な型を取る関数を

```rust
fn foo(t: Into<String>) {
  let s: String = t.into();
  ...
}
```

のように記述できる。この関数には `&str` と `String` のいずれも渡すことができ、更に `&str` ではClone(to_string)が行われるが `String` ではそのままの値が使われるので効率の良いイディオムとして知られる。


## Optional Chaining: Option, Result

https://doc.rust-jp.rs/book/second-edition/ch09-02-recoverable-errors-with-result.html#aエラー委譲のショートカット-演算子

Rustは `?` によりOptional Chainを提供する。`?` のスコープは関数全体、または直前のtry(-catch)ブロックにまで及ぶ。`foo: Result<A, E>`とある場合に`foo?`とした場合に、

- `foo`の中身が `Ok` であればその値を取り出し、
- `foo`の中身が `Err` であれば `From<E>` を返す(単純な`E`ではないことに注意)

のような挙動を示す。


## Optionのownership

Optionのメソッドはownershipを取るものとそうでないものがあり使い分けを理解しておくべきである。

- selfを要求するもの: unwrap, map
- &mut selfを要求するもの: take, replace, as_mut

例えばunwrapはselfを要求するため当然ムーブされてしまうが、Optionの中の値を取りつつ元の変数自体は残したい場合にはtakeなどを上手く使うと良い。


## コンテナとIterator

Vecを利用する際にはイテレータとして値を処理できると便利であるので、 `v.iter()` などという書き方を良くする。Vecに限らずRustの多くのデータ型はイテレータとして処理することを前提に設計されているものも多い。

イテレータの実体となるのは次の型 `Iter<T>` である。

https://doc.rust-lang.org/std/slice/struct.Iter.html

この型は `Iterator` traitを実装しており、 `Iterator` traitは多くのイテレータの変換操作を提供している。

https://doc.rust-lang.org/std/iter/trait.Iterator.html

最後に、終端処理は `collect` メソッドにより行う。

https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect

collectメソッドは `FromIterator` traitを実装している型であればどんなものにも出来るため、これが最初の型と一致する必要はない。よって例えば `Vec<(K,V)>` を `HashMap<K,V>` に変換したければ、 `v.iter().collect()` と書くだけで良い。

`collect` は型が曖昧になりやすいメソッドであるため、コンテナの型を明示して `.collect::<Vec<_>>()` と書くようにすると扱いやすい。


## sized at compile-time: 参照, Box, Rc

可変長スライス `[T]` は可変長であるため、コンパイル時にスライスの長さは決まらない。しかしRustは大きさのわからないデータをスタックに置くことは出来ない。このような理由から可変長スライス `[T]` がそのまま使われることはほとんどなく、通常は参照 `&[T]` によって間接的にデータを扱うこととなる。

サイズが分からないものを扱う場合、参照を始めとしてBox, Rcなどを利用する方法がある。それぞれ次のような利点・欠点がある。

- 参照: 単純な場合には扱いやすいが、lifetime parameterが出現するようになると途端にコードは煩雑になる
- Box: ヒープにデータを置くだけで非常に使いやすいが、cloneすると中のデータが丸ごとコピーされるのでコストが高い。
- Rc: reference count分の実行時コストがかかるがclone自体のコストは比較的低い。

特にtrait objectはコンパイル時に長さが決まらないので `Box<dyn T>` などのようにして利用されることが非常に多い。これに適切なtrait境界を定めることで、「SyncとSendを備えたデータ型で、trait Tを実装したものをヒープに置いたもの」を `Box<dyn T + Sync + Send>` などと書くことが出来る。



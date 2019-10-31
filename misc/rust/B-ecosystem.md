# B. Rustのエコシステム

- rustup: コンパイラを始めとするRust toolchainのインストールや管理を行うためのツール
- Cargo: Rustのパッケージマネージャ
- https://crates.io: Rustのパッケージレジストリ
- https://docs.rs: crates.ioに上がっているパッケージのドキュメントを保管している場所(crates.ioのDocumentationのリンクがなくともここにドキュメントがあることもある)
- VSCodeプラグイン: https://github.com/rust-lang/rls-vscode

## ライフサイクル

Rustのツールチェインは stable/beta/nightly の3つのチャンネルがある。nightly -> beta -> stable の順で不安定な機能が取り込まれていく。  
nightlyは基本的に毎日更新されるが、かなり不安定なのでいろいろなツールが動かなくなる可能性が高い。グローバルはstableにし、使うにせよプロジェクトごとにnightlyはバージョンを固定するのがおすすめ。

nightlyを使う場合はrlsなどの周辺ツールのビルドステータスを見て固定するバージョンを決めると良い。

https://rust-lang.github.io/rustup-components-history/

## Cargoのサブコマンドを入れる

`cargo install cargo-xxxx` によってcargoのサブコマンドをインストールすることが出来る

cf: https://qiita.com/sinkuu/items/3ea25a942d80fce74a90

いくつか紹介

- cargo-expand: マクロを展開する
- cargo-clippy: linter
- cargo-edit: Cargo.tomlを編集する
- cargo-outdated: 古くなったパッケージを表示/更新する

## プロジェクトごとにRustのコンパイラのバージョンを指定する

方法は2つ

- `rust-toolchain` ファイルをプロジェクトのルートに置く( `nightly-2019-10-22` などと指定する)
- `rustup override set <version>` によってrustupで設定する

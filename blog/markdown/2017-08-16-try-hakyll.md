<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Hakyllでブログを作る</a>
<ul>
<li><a href="#sec-1-1">1.1. 概要</a></li>
<li><a href="#sec-1-2">1.2. Hakyllのsetup</a></li>
<li><a href="#sec-1-3">1.3. 文書の変換・Hakyllの設定</a></li>
</ul>
</li>
</ul>
</div>
</div>


# Hakyllでブログを作る<a id="sec-1" name="sec-1"></a>

Hakyllでこのブログを作ったのでそのあれこれを  

## 概要<a id="sec-1-1" name="sec-1-1"></a>

やりたいことは以下  

-   orgで文章をかく(大事)
-   orgから良い感じのHTMLを生成し
-   github pagesで公開

## Hakyllのsetup<a id="sec-1-2" name="sec-1-2"></a>

次を参考にした  

-   [Hakyll Tutorials](https://jaspervdj.be/hakyll/tutorials.html)
-   [Hakyll, stack, Travis CI, Github でブログを管理する](http://335g.github.io/posts/2015-08-09-hakyll_travis.html)
-   [GitHub Pages はじめました](https://matsubara0507.github.io/posts/2016-07-07-started-github-pages.html)
-   [hakyll package](https://hackage.haskell.org/package/hakyll-4.9.8.0)

`stack` でパッケージを入れて、 `hakyll-init` → `stack build` → `stack exec site watch` で動かすところまでは簡単にいけた  
2番目のリンクにあるように、 `_site` をsubmoduleに登録しておいて、これをmasterブランチにpushして公開するようにしておく  

## 文書の変換・Hakyllの設定<a id="sec-1-3" name="sec-1-3"></a>

プロジェクトの構造は次のようになっている  

    - root
      - _site    できたHTMLファイルが置かれる
      - _cache
      - css      できたCSSファイルが置かれる(圧縮済)
      - images   画像ファイルが(ry
    
      - org      ここに新しい記事を書いて放り込む
      - markdown orgから変換されたmarkdownが入るorここにmarkdownで書いた記事を入れる
      - build.py python build script
      - site.hs  Hakyllの設定ファイル

### orgの変換<a id="sec-1-3-1" name="sec-1-3-1"></a>

Hakyllは内部で文書変換にpandocを使っていて、pandocはorgに対応しているらしいので何も設定しなくても変換はできる  
(デフォルトの状態では `posts` 以下の文書ファイルが変換される)  

しかし、pandocはorgの `#OPTIONS: toc:2 \n:t` みたいなオプションを無視するようで、これがどうしても使いたかったので仕方なく一旦orgをemacsでmarkdownに変換してからHTMLに変換することにした。  
このため、Hakyllは `org/*.org` を `markdown/*.md` に、 `markdown/*.md` をHTMLに、変換するようにしている。  

具体的には次のような感じ:  

[build.py](https://github.com/myuon/myuon.github.io/blob/source/blog/build.py)  

    def org_to_markdown(file):
        dir, base_ext = os.path.split(file)
        base, ext = os.path.splitext(base_ext)
    
        new_filepath = os.path.join(dir.replace("org", "markdown"), base + ".md")
        with open(new_filepath, 'w') as outfile:
            subprocess.run(" ".join(["emacs", file, "-Q", "--batch", "-f", "org-md-export-as-markdown", '--eval="(princ (buffer-string))"']), stdout=outfile, shell=True)

[site.hs](https://github.com/myuon/myuon.github.io/blob/source/blog/site.hs)  

    match "org/*" $ do
      compile $ getResourceFilePath
        >>= \fpath -> unsafeCompiler (callCommand $ unwords ["python3", "build.py", "org_to_markdown", fpath])
        >>= makeItem

さて、pythonの方を見ると分かる通りこれはひどいという感じ。  
ただ、 `org-md-export-as-markdown` だとcode blockの言語指定が消えてしまうのでそこだけどうにかしたい。  

HTMLの方でsyntax highlightは自動判定してくれるようなものを使えばいいとはいえ、せっかくorgで指定した情報が失われるのは…という感じ。  
やはりemacsでやろうとするのがよくないのだろうか…(pandocで上手くオプションを付けることで同じことができるのならそれでもいいのだけど よくわからないので放置してる)  

### デザイン<a id="sec-1-3-2" name="sec-1-3-2"></a>

Hakyllのテーマにはあまりまともなものがなく、例えばJekyllのテーマをHakyll用に変換するのは[かなり大変そう](https://matsubara0507.github.io/posts/2016-10-24-changed-design.html)なのでやりたくなかった。  
ので、デザインは自力で何とかすることにした。  

[semantic-ui](https://semantic-ui.com/)というCSSフレームワークを使った。  
この上でテンプレートHTMLを適当に改造し適当にCSSを書くことでそれらしいデザインにした。  

まぁひとまずこれで。  


-   - -

以下はまだ出来てないこと  
今後やっていく  

-   code blockのsyntax highlight
-   SNSで共有ボタンの追加
-   記事にタグを付ける
-   markdownからHTMLに変換する時にsemantic-ui用にclassを付与する
-   orgのメタ情報をmarkdownのメタ情報に変換する？ (HTMLに正しくメタ情報が受け継がれて欲しい)
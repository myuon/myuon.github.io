---
title: newtype decoratorパターンとグラフィックスライブラリ
date: 2019-04-11T20:30:21+09:00
tags: [ "Haskell" ]
---

[minilight](https://github.com/myuon/minilight)というSDL2の上で動くグラフィックスライブラリを作っている。

前にも[似たようなこと](https://myuon.github.io/posts/refluxible-library/)をしており、フルスクラッチで作ったくせにそんなに変わらないという代物。  
(別にFluxとかを目指しているわけではないので…まぁ偶然の一致というやつだな)

比較的簡単にコンポーネントが作れるようになったので、その紹介も兼ねて。

## 例: ボタン

例として押した回数が表示されるボタンを作ってみる。

[https://github.com/myuon/minilight/blob/master/examples/button-counter.hs]

コード自体はせいぜい30行程度で書けるので結構お手軽だと思う。

- - -

以下がButton型の定義と生成関数。まあこれはいいでしょう。ちなみにminilightではライブラリ名に従って`MiniLight`モナドが基本のモナドです。

```hs
data Button = Button {
  font :: SDL.Font.Font,
  counter :: Int
}

new :: MiniLight Button
new = do
  font <- loadFont (FontDescriptor "IPAGothic" (FontStyle False False)) 22
  return $ Button {font = font, counter = 0}
```

以下がボタンコンポーネントの定義。`ComponentUnit`のインスタンスを作れば良い。viewは`figures`で、イベントハンドラーは`onSignal`で、モデルの更新は`update`で、キャッシュの設定は`useCache`でそれぞれ行う。

```hs
instance ComponentUnit Button where
  update = return

  figures comp = do
    textTexture <- liftMiniLight $ text (font comp) (Vect.V4 255 255 255 255) $
      if counter comp == 0 then "Click me!" else "You've clicked " `T.append` T.pack (show (counter comp)) `T.append` " times!"
    base <- liftMiniLight $ rectangleFilled (Vect.V4 60 60 60 255) (getFigureSize textTexture)

    return [
      base,
      textTexture
      ]

  useCache prev now = counter prev == counter now

  onSignal (RawEvent (SDL.Event _ (SDL.MouseButtonEvent (SDL.MouseButtonEventData _ SDL.Released _ _ _ _)))) comp = do
    return $ comp { counter = counter comp + 1 }
  onSignal _ comp = return comp
```

`figures`では色付きの長方形の表示とテキスト表示を行っている。ここではSDLテクスチャの生成が走るので結構重い処理だけど、中ではキャッシュされるので(counterがupdateされたときだけ作り直す)問題がない。

`useCache`は1F前の状態と今の状態をもらってきて、viewのキャッシュを使うかどうかを判定する。ここでは1F前と現在でカウンターの値が同じであればviewは変わらないのでキャッシュを利用する、そうでなければキャッシュを破棄するという設定にしている。

まぁはいという実装ですね。

## Component wrapper

このようにして作られたボタンは、コンポーネントという単位でライブラリ側で管理される。異なる種類のコンポーネントをまとめて扱うために、実際にはコンポーネントラッパーが被される。

```hs
data Component = forall c. ComponentUnit c => Component {
  component :: c,
  prev :: c,
  cache :: IORef [Figure]
}
```

ComponentはExistentialQuantificationが入っており、ここではComponentUnit型のインスタンスならば何でもComponentに出来るようにしてある。中身はコンポーネントそのものと、1F前の状態と、viewキャッシュからなる。

コンポーネントのライフサイクルは次のような感じ:

`登録 → mainloop{描画 → state反映 → update → onSignal} → 削除`

state反映というのは、現在のcomponentの値をprevに反映させることを言う。これによって、updateとonSignalによって変更される前の値と変更された値を比較して、描画時にキャッシュを使うかどうかを判定することになる。

実際にはComponentそれ自体もComponentUnitインスタンスである。

```hs
instance ComponentUnit Component where
  update (Component comp prev cache) = do
    comp' <- update comp
    return $ Component comp' prev cache

  figures (Component comp _ _) = figures comp

  draw (Component comp prev ref) = liftMiniLight $ do
    if useCache prev comp
      then renders =<< liftIO (readIORef ref)
      else do
        figs <- liftIO (readIORef ref)
        mapM_ freeFigure figs

        figs <- figures comp
        renders figs
        liftIO $ writeIORef ref figs

  onSignal ev (Component comp prev cache) = fmap (\comp' -> Component comp' prev cache) $ onSignal ev comp
```

このように、ExistentialQuantificationを付けたnewtype wrapperによって内部のinstanceからwrapper型のinstanceを導出し、さらにそこでデコレータ的な処理を行うパターンはHaskellではとても便利なのでよく使っている。

## おわりに

Componentのテクニックはminilightではそこまでアピールポイントというほどではなく、他にもviewがyamlファイルで定義できたりSDL2のラッパーとして色々頑張っていたりするんだけどまぁそのへんはある程度開発ができてきたらまた紹介しようと思います。

本当はゲームを作りたくてこれを作り始めたんだけど、ゲームエンジンから作る人間がゲームを完成されられることはないっていうアレがアレでアレしている…


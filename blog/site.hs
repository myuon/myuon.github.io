--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid (mappend)
import qualified Data.Set as S
import Text.Pandoc
import Text.Pandoc.Walk
import System.Process
import Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "semantic-ui-css/*.css" $ do
        route   idRoute
        compile compressCssCompiler

    match "semantic-ui-css/themes/**/*" $ do
        route   idRoute
        compile getResourceLBS

    match "posts/*" $ do
        route $ setExtension "html"
        let hardLineBreaks :: Inline -> Inline
            hardLineBreaks SoftBreak = LineBreak
            hardLineBreaks k = k

        let ropt = def
        let wopt = def
              { writerTableOfContents = True
              , writerSectionDivs = True
              , writerTemplate = Just "$if(toc)$\n$toc$\n$endif$\n$body$"
              , writerWrapText = WrapPreserve
              , writerHighlight = True
              }
        
        compile $ pandocCompilerWithTransform ropt wopt (walk hardLineBreaks)
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

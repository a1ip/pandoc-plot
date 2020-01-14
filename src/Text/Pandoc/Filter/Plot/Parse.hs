{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards       #-}

{-|
Module      : $header$
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : internal
Portability : portable

This module defines types and functions that help
with keeping track of figure specifications
-}
module Text.Pandoc.Filter.Plot.Parse ( 
      parseFigureSpec 
    , captionReader
) where

import           Control.Monad                   (join, when)
import           Control.Monad.Reader            (ask, liftIO)

import           Data.Default.Class              (def)
import           Data.List                       (intersperse)
import qualified Data.Map.Strict                 as Map
import           Data.Maybe                      (fromMaybe)
import           Data.Monoid                     ((<>))
import           Data.String                     (fromString)
import           Data.Text                       (Text, pack, unpack)
import qualified Data.Text.IO                    as TIO
import           Data.Version                    (showVersion)

import           Paths_pandoc_plot               (version)

import           System.FilePath                 (makeValid)

import           Text.Pandoc.Definition          (Block (..), Inline,
                                                    Pandoc (..))

import           Text.Pandoc.Class               (runPure)
import           Text.Pandoc.Extensions          (Extension (..),
                                                    extensionsFromList)
import           Text.Pandoc.Options             (ReaderOptions (..))
import           Text.Pandoc.Readers             (readMarkdown)

import           Text.Pandoc.Filter.Plot.Types

tshow :: Show a => a -> Text
tshow = pack . show

-- | Determine inclusion specifications from @Block@ attributes.
-- If an environment is detected, but the save format is incompatible,
-- an error will be thrown.
parseFigureSpec :: RendererM m => Block -> m (Maybe FigureSpec)
parseFigureSpec (CodeBlock (id', cls, attrs) content) = do
    rendererName <- tshow <$> name
    if not (rendererName `elem` cls)
        then return Nothing 
        else Just <$> figureSpec

    where
        attrs'        = Map.fromList attrs
        preamblePath  = unpack <$> Map.lookup (tshow PreambleK) attrs'
        header        = "Generated by pandoc-plot " <> ((pack . showVersion) version)

        figureSpec :: RendererM m => m FigureSpec
        figureSpec = do
            config <- ask
            extraAttrs' <- parseExtraAttrs attrs'
            c <- commentChar
            -- Note that the default preamble changes based on the RendererM
            -- which is why we use @preambleSelector@ as the default value
            includeScript <- fromMaybe
                                preambleSelector
                                ((liftIO . TIO.readFile) <$> preamblePath)
            let -- Filtered attributes that are not relevant to pandoc-plot
                -- This presumes that inclusionKeys includes ALL possible keys, for all renderers
                filteredAttrs = filter (\(k, _) -> k `notElem` (tshow <$> inclusionKeys)) attrs
                defWithSource = defaultWithSource config
                defSaveFmt = defaultSaveFormat config
                defDPI = defaultDPI config

            let caption        = Map.findWithDefault mempty (tshow CaptionK) attrs'
                withSource     = fromMaybe defWithSource $ readBool <$> Map.lookup (tshow WithSourceK) attrs'
                script         = mconcat $ intersperse "\n" [c <> header, includeScript, content]
                saveFormat     = fromMaybe defSaveFmt $ (fromString . unpack) <$> Map.lookup (tshow SaveFormatK) attrs'
                directory      = makeValid $ unpack $ Map.findWithDefault (pack $ defaultDirectory config) (tshow DirectoryK) attrs'
                dpi            = fromMaybe defDPI $ (read . unpack) <$> Map.lookup (tshow DpiK) attrs'
                extraAttrs     = Map.toList extraAttrs'
                blockAttrs     = (id', cls, filteredAttrs)
            
            -- This is the first opportunity to check save format compatibility
            saveFormatSupported <- (elem saveFormat <$> supportedSaveFormats)
            when (not saveFormatSupported) $ do
                tk <- name
                (error $ mconcat ["Save format ", show saveFormat, " not supported by ", show tk ])
            return FigureSpec{..}

parseFigureSpec _ = return Nothing

-- | Reader options for captions.
readerOptions :: ReaderOptions
readerOptions = def
    {readerExtensions =
        extensionsFromList
            [ Ext_tex_math_dollars
            , Ext_superscript
            , Ext_subscript
            , Ext_raw_tex
            ]
    }


-- | Read a figure caption in Markdown format. LaTeX math @$...$@ is supported,
-- as are Markdown subscripts and superscripts.
captionReader :: Text -> Maybe [Inline]
captionReader t = either (const Nothing) (Just . extractFromBlocks) $ runPure $ readMarkdown' t
    where
        readMarkdown' = readMarkdown readerOptions

        extractFromBlocks (Pandoc _ blocks) = mconcat $ extractInlines <$> blocks

        extractInlines (Plain inlines)          = inlines
        extractInlines (Para inlines)           = inlines
        extractInlines (LineBlock multiinlines) = join multiinlines
        extractInlines _                        = []


-- | Flexible boolean parsing
readBool :: Text -> Bool
readBool s | s `elem` ["True",  "true",  "'True'",  "'true'",  "1"] = True
           | s `elem` ["False", "false", "'False'", "'false'", "0"] = False
           | otherwise = error $ unpack $ mconcat ["Could not parse '", s, "' into a boolean. Please use 'True' or 'False'"]

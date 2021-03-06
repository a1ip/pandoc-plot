{-# LANGUAGE OverloadedStrings #-}
{-|
Module      : $header$
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : internal
Portability : portable

Prelude for renderers, containing some helpful utilities.
-}
module Text.Pandoc.Filter.Plot.Renderers.Prelude (

      module Prelude
    , module Text.Pandoc.Filter.Plot.Monad
    , Text
    , st
    , unpack
    , commandSuccess
    , existsOnPath
    , OutputSpec(..)
    , appendCapture
    , toRPath
) where

import           Data.Maybe                    (isJust)
import           Data.Text                     (Text, unpack)

import           System.Directory              (findExecutable)
import           System.FilePath               (isPathSeparator)
import           System.Exit                   (ExitCode(..))

import           Text.Shakespeare.Text         (st)

import           Text.Pandoc.Filter.Plot.Monad


-- | Check that the supplied command results in
-- an exit code of 0 (i.e. no errors)
commandSuccess :: FilePath -- Directory from which to run the command
               -> Text     -- Command to run, including the executable
               -> PlotM Bool
commandSuccess fp s = do
    (ec, _) <- runCommand fp s
    return $ ec == ExitSuccess


-- | Checks that an executable is available on path, at all.
existsOnPath :: FilePath -> IO Bool
existsOnPath fp = findExecutable fp >>= fmap isJust . return


-- | A shortcut to append capture script fragments to scripts
appendCapture :: (FigureSpec -> FilePath -> Script) 
              ->  FigureSpec -> FilePath -> Script
appendCapture f s fp = mconcat [script s, "\n", f s fp]


-- | Internal description of all information 
-- needed to output a figure.
data OutputSpec = OutputSpec 
    { oFigureSpec    :: FigureSpec    -- ^ Figure spec
    , oScriptPath    :: FilePath      -- ^ Path to the script to render
    , oFigurePath    :: FilePath      -- ^ Figure output path
    } 


-- | R paths use the '/' path separator
toRPath :: FilePath -> FilePath
toRPath = fmap (\c -> if isPathSeparator c then '/' else c)
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts  #-}
{-|
Module      : $header$
Description : Pandoc filter to create figures from code blocks using your plotting toolkit of choice
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : unstable
Portability : portable

This module defines a Pandoc filter @plotTransform@ and related functions
that can be used to walk over a Pandoc document and generate figures from
code blocks, using a multitude of plotting toolkits.

The syntax for code blocks is simple. Code blocks with the appropriate class
attribute will trigger the filter:

*   @matplotlib@ for matplotlib-based Python plots;
*   @plotly_python@ for Plotly-based Python plots;
*   @plotly_r@ for Plotly-based R plots;
*   @matlabplot@ for MATLAB plots;
*   @mathplot@ for Mathematica plots;
*   @octaveplot@ for GNU Octave plots;
*   @ggplot2@ for ggplot2-based R plots;
*   @gnuplot@ for gnuplot plots;
*   @graphviz@ for Graphviz graphs;
*   @bokeh@ for Bokeh-based Python plots;
*   @plotsjl@ for Plots.jl-based Julia plots;

For example, in Markdown:

@
    This is a paragraph.

    ```{.matlabplot}
    figure()
    plot([1,2,3,4,5], [1,2,3,4,5], '-k')
    ```
@

The code block will be reworked into a script and the output figure will be captured. Optionally, the source code
 used to generate the figure will be linked in the caption.

Here are the possible attributes what pandoc-plot understands for ALL toolkits:

    * @directory=...@ : Directory where to save the figure. This path should be specified with 
      respect to the current working directory, and not with respect to the document.
    * @source=true|false@ : Whether or not to link the source code of this figure in the caption. 
      Ideal for web pages, for example. Default is false.
    * @format=...@: Format of the generated figure. This can be an extension or an acronym, 
      e.g. @format=PNG@.
    * @caption="..."@: Specify a plot caption (or alternate text). Format 
      for captions is specified in the documentation for the @Configuration@ type.
    * @dpi=...@: Specify a value for figure resolution, or dots-per-inch. Certain toolkits ignore this.
    * @dependencies=[...]@: Specify files/directories on which a figure depends, e.g. data file. 
      Figures will be re-rendered if one of those file/directory changes. These paths should 
      be specified with respect to the current working directory, and not with respect to the document.
    * @preamble=...@: Path to a file to include before the code block. Ideal to avoid repetition over 
      many figures.
    * @file=...@: Path to a file from which to read the content of the figure. The content of the 
      code block will be ignored. This path should be specified with respect to the current working 
      directory, and not with respect to the document.

Default values for the above attributes are stored in the @Configuration@ datatype. These can be specified in a 
YAML file. 

Here is an example code block which will render a figure using gnuplot, in Markdown:

@
    ```{.gnuplot format=png caption="Sinusoidal function" source=true}
    sin(x)

    set xlabel "x"
    set ylabel "y"
    ```
@
-}
module Text.Pandoc.Filter.Plot (
    -- * Operating on whole Pandoc documents
      plotTransform
    -- * Cleaning output directories
    , cleanOutputDirs
    -- * Runtime configuration
    , configuration
    , defaultConfiguration
    , Configuration(..)
    , Verbosity(..)
    , LogSink(..)
    , SaveFormat(..)
    , Script
    -- * Determining available plotting toolkits
    , Toolkit(..)
    , availableToolkits
    , unavailableToolkits
    , toolkits
    , supportedSaveFormats
    -- * Version information
    , pandocPlotVersion
    -- * For embedding, testing and internal purposes ONLY. Might change without notice.
    , make
    , makeEither
    , PandocPlotError(..)
    ) where

import Control.Concurrent.Async.Lifted   (mapConcurrently)
import Data.Text                         (Text, unpack)
import Data.Version                      (Version)

import Paths_pandoc_plot                 (version)

import Text.Pandoc.Definition            (Pandoc(..), Block)

import Text.Pandoc.Filter.Plot.Internal

-- | Walk over an entire Pandoc document, transforming appropriate code blocks
-- into figures. This function will operate on blocks in parallel if possible.
--
-- Failing to render a figure does not stop the filter, so that you may run the filter
-- on documents without having all necessary toolkits installed. In this case, error
-- messages are printed to stderr, and blocks are left unchanged.
plotTransform :: Configuration -- ^ Configuration for default values
              -> Pandoc        -- ^ Input document
              -> IO Pandoc
plotTransform conf (Pandoc meta blocks) = 
    runPlotM conf $ mapConcurrently make blocks >>= return . Pandoc meta


-- | The version of the pandoc-plot package.
--
-- @since 0.8.0.0
pandocPlotVersion :: Version
pandocPlotVersion = version


-- | Try to process the block with `pandoc-plot`. If a failure happens (or the block)
-- was not meant to become a figure, return the block as-is.
make :: Block -> PlotM Block
make blk = either (const (return blk) ) return =<< makeEither blk


-- | Try to process the block with `pandoc-plot`, documenting the error.
makeEither :: Block -> PlotM (Either PandocPlotError Block)
makeEither block = 
    parseFigureSpec block 
        >>= maybe 
                (return $ Right block)
                (\s -> runScriptIfNecessary s >>= handleResult s)
    where
        -- Logging of errors has been taken care of in @runScriptIfNecessary@ 
        handleResult :: FigureSpec -> ScriptResult -> PlotM (Either PandocPlotError Block)
        handleResult _ (ScriptFailure msg code)       = return $ Left (ScriptRuntimeError msg code) 
        handleResult _ (ScriptChecksFailed msg)       = return $ Left (ScriptChecksFailedError msg)
        handleResult _ (ToolkitNotInstalled tk')      = return $ Left (ToolkitNotInstalledError tk') 
        handleResult spec ScriptSuccess = asks envConfig >>= \c -> Right <$> toFigure (captionFormat c) spec


data PandocPlotError
    = ScriptRuntimeError Text Int
    | ScriptChecksFailedError Text
    | ToolkitNotInstalledError Toolkit

instance Show PandocPlotError where
    show (ScriptRuntimeError _ exitcode) = "ERROR (pandoc-plot) The script failed with exit code " <> show exitcode <> "."
    show (ScriptChecksFailedError msg)   = "ERROR (pandoc-plot) A script check failed with message: " <> unpack msg <> "."
    show (ToolkitNotInstalledError tk)   = "ERROR (pandoc-plot) The " <> show tk <> " toolkit is required but not installed."
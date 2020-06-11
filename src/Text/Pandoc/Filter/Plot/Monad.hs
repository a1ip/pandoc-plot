{-# LANGUAGE OverloadedStrings #-}
{-|
Module      : $header$
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : internal
Portability : portable

This module defines the @PlotM@ monad and related capabilities.
-}

module Text.Pandoc.Filter.Plot.Monad (
      Configuration(..)
    , PlotM
    , runPlotM
    -- * Logging
    , Verbosity(..)
    , LogSink(..)
    , debug
    , err
    , warning
    , info
    -- * Lifting and other monadic operations
    , liftIO
    , ask
    , asks
    -- * Base types
    , module Text.Pandoc.Filter.Plot.Monad.Types
) where

import           Control.Monad.Reader

import           Data.Default.Class          (Default, def)
import           Data.Text                   (Text)

import           Text.Pandoc.Definition      (Format(..))

import           Prelude                     hiding (log, fst, snd)

import Text.Pandoc.Filter.Plot.Monad.Logging
import Text.Pandoc.Filter.Plot.Monad.Types

-- | pandoc-plot monad
type PlotM a = ReaderT Configuration LoggingM a


-- | Evaluate a @PlotM@ action 
runPlotM :: Configuration -> PlotM a -> IO a
runPlotM conf v = 
    let verbosity = logVerbosity conf
        sink      = logSink conf 
    in runLoggingM verbosity sink (runReaderT v conf)


debug :: Text -> PlotM ()
debug t = lift $ log Debug $ "DEBUG| " <> t


err :: Text -> PlotM ()
err t = lift $ log Error $ "ERROR| " <> t


warning :: Text -> PlotM ()
warning t = lift $ log Warning $ "WARN | " <> t


info :: Text -> PlotM ()
info t = lift $ log Info $ "INFO | " <> t


-- | The @Configuration@ type holds the default values to use
-- when running pandoc-plot. These values can be overridden in code blocks.
--
-- You can create an instance of the @Configuration@ type from file using the @configuration@ function.
--
-- You can store the path to a configuration file in metadata under the key @plot-configuration@. For example, in Markdown:
--
-- @
--     ---
--     title: My document
--     author: John Doe
--     plot-configuration: /path/to/file.yml
--     ---     
-- @
--
-- The same can be specified via the command line using Pandoc's @-M@ flag:
--
-- > pandoc --filter pandoc-plot -M plot-configuration="path/to/file.yml" ...
--
-- In this case, use @configurationPathMeta@ to extact the path from @Pandoc@ documents.
data Configuration = Configuration
    { defaultDirectory      :: !FilePath   -- ^ The default directory where figures will be saved.
    , defaultWithSource     :: !Bool       -- ^ The default behavior of whether or not to include links to source code and high-res
    , defaultDPI            :: !Int        -- ^ The default dots-per-inch value for generated figures. Renderers might ignore this.
    , defaultSaveFormat     :: !SaveFormat -- ^ The default save format of generated figures.
    , captionFormat         :: !Format     -- ^ Caption format, in the same notation as Pandoc format, e.g. "markdown+tex_math_dollars"

    , logVerbosity          :: !Verbosity  -- ^ Level of logging verbosity.
    , logSink               :: !LogSink    -- ^ Method of logging, i.e. printing to stderr or file.

    , matplotlibPreamble    :: !Script     -- ^ The default preamble script for the matplotlib toolkit.
    , plotlyPythonPreamble  :: !Script     -- ^ The default preamble script for the Plotly/Python toolkit.
    , plotlyRPreamble       :: !Script     -- ^ The default preamble script for the Plotly/R toolkit.
    , matlabPreamble        :: !Script     -- ^ The default preamble script for the MATLAB toolkit.
    , mathematicaPreamble   :: !Script     -- ^ The default preamble script for the Mathematica toolkit.
    , octavePreamble        :: !Script     -- ^ The default preamble script for the GNU Octave toolkit.
    , ggplot2Preamble       :: !Script     -- ^ The default preamble script for the GGPlot2 toolkit.
    , gnuplotPreamble       :: !Script     -- ^ The default preamble script for the gnuplot toolkit.
    , graphvizPreamble      :: !Script     -- ^ The default preamble script for the Graphviz toolkit.
    
    , matplotlibExe         :: !FilePath   -- ^ The executable to use to generate figures using the matplotlib toolkit.
    , matlabExe             :: !FilePath   -- ^ The executable to use to generate figures using the MATLAB toolkit.
    , plotlyPythonExe       :: !FilePath   -- ^ The executable to use to generate figures using the Plotly/Python toolkit.
    , plotlyRExe            :: !FilePath   -- ^ The executable to use to generate figures using the Plotly/R toolkit.
    , mathematicaExe        :: !FilePath   -- ^ The executable to use to generate figures using the Mathematica toolkit.
    , octaveExe             :: !FilePath   -- ^ The executable to use to generate figures using the GNU Octave toolkit.
    , ggplot2Exe            :: !FilePath   -- ^ The executable to use to generate figures using the GGPlot2 toolkit.
    , gnuplotExe            :: !FilePath   -- ^ The executable to use to generate figures using the gnuplot toolkit.
    , graphvizExe           :: !FilePath   -- ^ The executable to use to generate figures using the Graphviz toolkit.
    
    , matplotlibTightBBox   :: !Bool       -- ^ Whether or not to make Matplotlib figures tight by default.
    , matplotlibTransparent :: !Bool       -- ^ Whether or not to make Matplotlib figures transparent by default.
    } deriving (Eq, Show)


instance Default Configuration where
    def = Configuration
          { defaultDirectory  = "plots/"
          , defaultWithSource = False
          , defaultDPI        = 80
          , defaultSaveFormat = PNG
          , captionFormat     = Format "markdown+tex_math_dollars"

          , logVerbosity      = Warning
          , logSink           = StdErr
          
          , matplotlibPreamble  = mempty
          , plotlyPythonPreamble= mempty
          , plotlyRPreamble     = mempty
          , matlabPreamble      = mempty
          , mathematicaPreamble = mempty
          , octavePreamble      = mempty
          , ggplot2Preamble     = mempty
          , gnuplotPreamble     = mempty
          , graphvizPreamble    = mempty

          , matplotlibExe       = if isWindows then "python" else "python3"
          , matlabExe           = "matlab"
          , plotlyPythonExe     = if isWindows then "python" else "python3"
          , plotlyRExe          = "Rscript"
          , mathematicaExe      = "math"
          , octaveExe           = "octave"
          , ggplot2Exe          = "Rscript"
          , gnuplotExe          = "gnuplot"
          , graphvizExe         = "dot"
          
          , matplotlibTightBBox   = False
          , matplotlibTransparent = False
          }
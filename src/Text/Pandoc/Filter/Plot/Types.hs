{-# LANGUAGE CPP                   #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts      #-}


{-|
Module      : $header$
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : internal
Portability : portable

This module defines types in use in pandoc-plot
-}

module Text.Pandoc.Filter.Plot.Types where

import           Control.Monad.Reader            (MonadIO)
import           Control.Monad.Reader.Class      (MonadReader)

import           Data.Char              (toLower)
import           Data.Default.Class     (Default, def)
import           Data.Hashable          (Hashable(..))
import           Data.List              (intersperse)
import qualified Data.Map.Strict        as Map
import           Data.Semigroup         (Semigroup(..))
import           Data.String            (IsString(..))
import           Data.Text              (Text, pack)
import           Data.Yaml

import           GHC.Generics           (Generic)

import           Text.Pandoc.Definition (Attr)

toolkits :: [Toolkit]
toolkits = enumFromTo minBound maxBound

-- | Enumeration of supported toolkits
data Toolkit
    = Matplotlib
    | Matlab
    | PlotlyPython
    deriving (Bounded, Eq, Enum, Generic)

-- |
instance Show Toolkit where
    show Matplotlib   = "matplotlib"
    show Matlab       = "matlabplot"
    show PlotlyPython = "plotly_python"

instance IsString Toolkit where
    fromString t = if t `elem` (show <$> toolkits)
                    then error $ "unknown toolkit " <> t
                    else head $ filter (\toolkit -> (show toolkit == t)) toolkits


class (Monad m , MonadIO m , MonadReader Configuration m) 
      => RendererM m where

    -- Name of the renderer. This is the string which will activate
    -- parsing.
    name :: m Toolkit

    -- Extension for script files, e.g. ".py", or ".m".
    scriptExtension :: m String

    -- The character that precedes comments
    commentChar :: m Text

    -- The function that maps from configuration to the preamble.
    preambleSelector :: m Script

    -- | Save formats supported by this renderer.
    supportedSaveFormats :: m [SaveFormat]

    -- Checks to perform before running a script. If ANY check fails,
    -- the figure is not rendered. This is to prevent, for example,
    -- blocking operations to occur.
    scriptChecks :: m [Script -> CheckResult]
    scriptChecks = return mempty

    -- | Parse code block headers for extra attributes that are specific
    -- to this renderer. By default, no extra attributes are parsed.
    parseExtraAttrs :: Map.Map Text Text -> m (Map.Map Text Text)
    parseExtraAttrs _ = return mempty

    -- | Generate the appropriate command-line command to generate a figure.
    command :: FigureSpec 
            -> FilePath     -- ^ Location of the temporary script
            -> m Text

    -- | Script fragment required to capture a figure.
    capture :: FigureSpec 
            -> FilePath     -- ^ Final location of the figure
            -> m Script


data Configuration = Configuration
    { defaultDirectory      :: FilePath   -- ^ The default directory where figures will be saved.
    , defaultWithSource     :: Bool       -- ^ The default behavior of whether or not to include links to source code and high-res
    , defaultDPI            :: Int        -- ^ The default dots-per-inch value for generated figures. Renderers might ignore this.
    , defaultSaveFormat     :: SaveFormat -- ^ The default save format of generated figures.
    , pythonInterpreter     :: String     -- ^ The default Python interpreter to use for Python-based renderers.

    , matplotlibTightBBox   :: Bool
    , matplotlibTransparent :: Bool
    , matplotlibPreamble    :: Script

    , plotlyPreamble        :: Script

    , matlabPreamble        :: Script
    }

instance Default Configuration where
    def = Configuration 
          { defaultDirectory  = "plots/"
          , defaultWithSource = False
          , defaultDPI        = 80
          , defaultSaveFormat = PNG
#if defined(mingw32_HOST_OS)
          , pythonInterpreter = "python"
#else
          , pythonInterpreter = "python3"
#endif
          
          , matplotlibTightBBox   = False
          , matplotlibTransparent = False
          , matplotlibPreamble = mempty

          , plotlyPreamble    = mempty
          
          , matlabPreamble    = mempty
          }


type Script = Text

-- | Result of checking scripts for problems
data CheckResult
    = CheckPassed
    | CheckFailed String
    deriving (Eq)

instance Semigroup CheckResult where
    (<>) CheckPassed a                         = a
    (<>) a CheckPassed                         = a
    (<>) (CheckFailed msg1) (CheckFailed msg2) = CheckFailed (msg1 <> msg2)

instance Monoid CheckResult where
    mempty = CheckPassed

#if !(MIN_VERSION_base(4,11,0))
    mappend = (<>)
#endif

-- | Description of any possible inclusion key, both in documents
-- and in configuration files.
data InclusionKey 
    = DirectoryK
    | CaptionK
    | SaveFormatK
    | WithSourceK
    | PreambleK
    | DpiK
    | PyInterpreterK
    | MatplotlibTightBBoxK
    | MatplotlibTransparentK
    | MatplotlibPreambleK
    | PlotlyPreambleK
    | MatlabPreambleK
    deriving (Bounded, Eq, Enum)

-- | Keys that pandoc-plot will look for in code blocks. 
-- These are only exported for testing purposes.
instance Show InclusionKey where
    show DirectoryK      = "directory"
    show CaptionK        = "caption"
    show SaveFormatK     = "format"
    show WithSourceK     = "source"
    show PreambleK       = "preamble"
    show DpiK            = "dpi"
    show PyInterpreterK  = "python_interpreter"
    show MatplotlibTightBBoxK = "tight_bbox"
    show MatplotlibTransparentK = "transparent"
    show MatplotlibPreambleK = show PreambleK
    show PlotlyPreambleK = show PreambleK
    show MatlabPreambleK = show PreambleK


-- | List of all keys related to pandoc-plot that
-- can be specified in source material.
inclusionKeys :: [InclusionKey]
inclusionKeys = enumFromTo (minBound::InclusionKey) maxBound


-- | Datatype containing all parameters required to run pandoc-plot.
--
-- It is assumed that once a @FigureSpec@ has been created, no configuration
-- can overload it; hence, a @FigureSpec@ completely encodes a particular figure.
data FigureSpec = FigureSpec
    { caption    :: Text           -- ^ Figure caption.
    , withSource :: Bool           -- ^ Append link to source code in caption.
    , script     :: Script         -- ^ Source code for the figure.
    , saveFormat :: SaveFormat     -- ^ Save format of the figure.
    , directory  :: FilePath       -- ^ Directory where to save the file.
    , dpi        :: Int            -- ^ Dots-per-inch of figure.
    , extraAttrs :: [(Text, Text)] -- ^ Renderer-specific extra attributes.
    , blockAttrs :: Attr           -- ^ Attributes not related to @pandoc-plot@ will be propagated.
    } deriving Generic

instance Hashable FigureSpec -- From Generic

-- | Generated figure file format supported by pandoc-plot.
-- Note: all formats are supported by Matplotlib, but not all
-- formats are supported by Plotly
data SaveFormat
    = PNG
    | PDF
    | SVG
    | JPG
    | EPS
    | GIF
    | TIF
    | WEBP
    deriving (Bounded, Enum, Eq, Show, Generic)

instance Hashable SaveFormat -- From Generic

instance IsString SaveFormat where
    -- An error is thrown if the save format cannot be parsed. That's OK
    -- since pandoc-plot is a command-line tool and isn't expected to run
    -- long.
    fromString s
        | s `elem` ["png", "PNG", ".png"] = PNG
        | s `elem` ["pdf", "PDF", ".pdf"] = PDF
        | s `elem` ["svg", "SVG", ".svg"] = SVG
        | s `elem` ["eps", "EPS", ".eps"] = EPS
        | s `elem` ["gif", "GIF", ".gif"] = GIF
        | s `elem` ["jpg", "jpeg", "JPG", "JPEG", ".jpg", ".jpeg"] = JPG
        | s `elem` ["tif", "tiff", "TIF", "TIFF", ".tif", ".tiff"] = TIF
        | s `elem` ["webp", "WEBP", ".webp"] = WEBP
        | otherwise = error $ 
                mconcat [ s
                        , " is not one of valid save format : "
                        , mconcat $ intersperse ", " $ show <$> saveFormats
                        ]
        where
            saveFormats =  (enumFromTo minBound maxBound) :: [SaveFormat]

instance FromJSON SaveFormat where
    parseJSON (Object v) = fromString <$> v .: (pack . show $ SaveFormatK)
    parseJSON _ = error "Coult not parse save format"

-- | Save format file extension
extension :: SaveFormat -> String
extension fmt = mconcat [".", fmap toLower . show $ fmt]
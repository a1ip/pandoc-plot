{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-|
Module      : $header$
Copyright   : (c) Laurent P René de Cotret, 2020
License     : GNU GPL, version 2 or above
Maintainer  : laurent.decotret@outlook.com
Stability   : internal
Portability : portable

Rendering Plotly/R plots code blocks
-}

module Text.Pandoc.Filter.Plot.Renderers.PlotlyR (
      plotlyRSupportedSaveFormats
    , plotlyRCommand
    , plotlyRCapture
    , plotlyRAvailable
) where

import           Text.Pandoc.Filter.Plot.Renderers.Prelude


plotlyRSupportedSaveFormats :: [SaveFormat]
plotlyRSupportedSaveFormats = [PNG, PDF, SVG, JPG, EPS, HTML]


plotlyRCommand :: OutputSpec -> PlotM (FilePath, Text)
plotlyRCommand OutputSpec{..} = do
    (dir, exe) <- executable PlotlyR
    return (dir, [st|#{exe} "#{oScriptPath}"|])


plotlyRAvailable :: PlotM Bool
plotlyRAvailable = do
    (dir, exe) <- executable GGPlot2
    commandSuccess dir [st|#{exe} -e 'library("plotly")'|]


plotlyRCapture :: FigureSpec -> FilePath -> Script
plotlyRCapture = appendCapture plotlyRCaptureFragment


plotlyRCaptureFragment :: FigureSpec -> FilePath -> Script
plotlyRCaptureFragment spec@FigureSpec{..} fname = case saveFormat of
    HTML -> plotlyRCaptureHtml spec fname
    _    -> plotlyRCaptureStatic spec fname


-- Based on the following discussion:
--    https://stackoverflow.com/q/34580095
plotlyRCaptureHtml :: FigureSpec -> FilePath -> Script
plotlyRCaptureHtml _ fname = [st|
library(plotly) # just in case
library(htmlwidgets)
p <- last_plot()
htmlwidgets::saveWidget(as_widget(p), "#{fname}")
|]


-- Based on the following documentation:
--    https://plotly.com/r/static-image-export/
plotlyRCaptureStatic :: FigureSpec -> FilePath -> Script
plotlyRCaptureStatic _ fname = [st|
library(plotly) # just in case
if (!require("processx")) install.packages("processx")
pdf(NULL)
orca(last_plot(), file = "#{fname}")
|]

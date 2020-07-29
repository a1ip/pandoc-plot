

## Features Overview

### Captions

You can also specify a caption for your image. This is done using the optional `caption` parameter.

__Markdown__:

~~~markdown
```{.matlabplot caption="This is a simple figure with a **Markdown** caption"}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
```
~~~

__LaTex__:

```latex
\begin{minted}[caption=This is a simple figure with a caption]{matlabplot}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
\end{minted}
```

Caption formatting unfortunately cannot be determined automatically. To specify a caption format (e.g. "markdown", "LaTeX", etc.), see [Configuration](#configuration).

### Link to source code

In case of an output format that supports links (e.g. HTML), the embedded image generated by `pandoc-plot` can show a link to the source code which was used to generate the file. Therefore, other people can see what code was used to create your figures. 

You can turn this on via the `source=true` key:

__Markdown__:

~~~markdown
```{.mathplot source=true}
...
```
~~~

__LaTex__:

```latex
\begin{minted}[source=true]{mathplot}
...
\end{minted}
```

or via a [configuration file](#Configuration).

### Preamble scripts

If you find yourself always repeating some steps, inclusion of scripts is possible using the `preamble` parameter. For example, if you want all Matplotlib plots to have the [`ggplot`](https://matplotlib.org/tutorials/introductory/customizing.html#sphx-glr-tutorials-introductory-customizing-py) style, you can write a very short preamble `style.py` like so:

```python
import matplotlib.pyplot as plt
plt.style.use('ggplot')
```

and include it in your document as follows:

~~~markdown
```{.matplotlib preamble=style.py}
plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
~~~

Which is equivalent to writing the following markdown:

~~~markdown
```{.matplotlib}
import matplotlib.pyplot as plt
plt.style.use('ggplot')

plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
~~~

The equivalent LaTeX usage is as follows:

```latex
\begin{minted}[include=style.py]{matplotlib}

\end{minted}
```

This `preamble` parameter is perfect for longer documents with many plots. Simply define the style you want in a separate script! You can also import packages this way, or define functions you often use.

### Support for interactive plots

Starting with version 0.8.0.0, `pandoc-plot` supports the creation of interactive plots (if a toolkit supports it). All you need to do is set the save format to `html`. The resulting plot is fully self-contained, so it can be displayed offline.

### Performance

`pandoc-plot` minimizes work, only generating figures if it absolutely must, i.e. if the content has changed. `pandoc-plot` will save the hash of the source code used to generate a figure in its filename. Before generating a figure, `pandoc-plot` will check it this figure already exists based on the hash of its source! This also means that there is no way to directly name figures.

Moreover, starting with version 0.5.0.0, `pandoc-plot` takes advantage of multicore CPUs, rendering figures **in parallel**.

Therefore, you can confidently run the filter on very large documents containing hundreds of figures, like a book or a thesis.

### Compatibility with pandoc-crossref

[`pandoc-crossref`](https://github.com/lierdakil/pandoc-crossref) is a pandoc filter that makes it effortless to cross-reference objects in Markdown documents. 

You can use `pandoc-crossref` in conjunction with `pandoc-plot` for the ultimate figure-making pipeline. You can combine both in a figure like so:

~~~markdown
```{#fig:myexample .plotly_python caption="This is a caption"}
# Insert figure script here
```

As you can see in @fig:myexample, ...
~~~

If the above source is located in file `myfile.md`, you can render the figure and references by applying `pandoc-plot` **first**, and then `pandoc-crossref`. For example:

```bash
pandoc --filter pandoc-plot --filter pandoc-crossref -i myfile.md -o myfile.html
```

## Detailed usage

`pandoc-plot` is a command line executable with a few functions. You can take a look at the help using the `-h`/`--help` flag:

```{.bash include=help.txt}
```

### As a filter

The most common use for `pandoc-plot` is as a pandoc filter, in which case it should be called without arguments. For example:

```bash
pandoc --filter pandoc-plot -i input.md -o output.html
```

If `pandoc-plot` fails to render a code block into a figure, the filtering will not stop. Your code blocks will stay unchanged.

You can chain other filters with it (e.g., [`pandoc-crossref`](https://github.com/lierdakil/pandoc-crossref)) like so:

```bash
pandoc --filter pandoc-plot --filter pandoc-crossref -i input.md -o output.html
```

### Syntax

The syntax for code blocks in documents is shown below. `pandoc-plot` looks for code blocks with a specific class, depending on the toolkit you want to use. `pandoc-plot` will run the code and capture the figure output. There can only be **one** figure per code block.

The possible parameters and options are described in [further below](#parameters-and-options).

#### Markdown

````markdown
  ```{.cls param1=value1 param2=value2 ...}
  # script content
  ```
````

#### LaTeX

Note that the `minted` LaTeX package need not be installed.
````latex
\begin{minted}[param1=value1, param2=value2, ...]{cls}
...
\end{minted}
````

### Parameters and options

There are parameters that affect the figure that will be included in your document. Here are all the possible general parameters, in Markdown syntax:

````markdown
  ```{.cls 
      .language
      directory=(path) 
      caption=(text) 
      format=(PNG|PDF|SVG|JPG|EPS|GIF|TIF|WEBP|HTML) 
      source=(true|false) 
      preamble=(path) 
      dpi=(integer) 
      executable=(path) 
      caption_format=(text)
      }
  # script content
  ```

````

* `cls` must be one of the following: `matplotlib`, `matlabplot`, `plotly_python`, `plotly_r`, `mathplot`, `octaveplot`, `ggplot2`, `gnuplot`, `graphviz`, `bokeh`, `plotsjl`.

All following parameters are optional, with their default values controlled by the [configuration](#configuration)

* `language` specifies the programming language used in this block. This parameter is ignored by `pandoc-plot`, but your text editor may use it to highlight code. See [Code highlighting](#code-highlighting) below.
* `directory` is a path to the directory where the figure and source code will be saved. You cannot control the file name. This path is either absolute, or relative from the working directory where you call `pandoc-plot`.
* `caption` is the caption text. The format of the caption is specified in the `caption_format` parameter, described below.
* `format` is the desired filetype for the resulting figure. Possible values for `format` are [`PNG`, `PDF`, `SVG`, `JPG`, `EPS`, `GIF`, `TIF`, `WEBP`, `HTML`]. Not all toolkits support all formats. See `pandoc-plot toolkits` for toolkit-specific information regarding save formats. The `HTML` format is special; it can produce standalone, offline, interactive plots. As such, it only makes sense to use this format when creating HTML documents.
* `source` is a boolean toggle that determines whether the source code should be linked in the caption or not. Possible values are [`true`, `True`, `false`, `False`].
* `preamble` is a path to a script that will be included as a preamble to the content of the code block. This path is either absolute, or relative from the working directory where you call `pandoc-plot`.
* `dpi` is the pixel density of the figure in dots-per-inch. Possible values are positive integers. Not all toolkits respect this.
* `executable` is a path to the executable to use (e.g. `C:\\python3.exe`) or the name of the executable (e.g. `python3`).
* `caption_format` is the text format of the caption. Possible values are exactly the same as `pandoc`'s format specification, usually `FORMAT+EXTENSION-EXTENSION`. For example, captions in Markdown with raw LaTeX would be parsed correctly provided that `caption_format=markdown+raw_tex`. See Pandoc's guide on [Specifying formats](https://pandoc.org/MANUAL.html#specifying-formats).

#### Code highlighting

If your editor supports code highlighting in code blocks, you can also include the programming language. In Markdown:

````markdown
  ```{.language .cls (options)}
  # script content
  ```
````

or Latex:

````latex
  \begin{minted}[(options)]{language, cls}
  # script content
  \end{minted}
````

For example, for GGPlot2 figures:

````markdown
  ```{.r .ggplot2 caption=Highlighted code block}
  # script content
  ```
````

or (Latex):

````latex
  \begin{minted}[caption=Highlighted code block]{r, ggplot2}
  # script content
  \end{minted}
````

This way, you benefit from code highlighting *and* `pandoc-plot`.

### Interactive HTML figures

Interactive HTML figures are available for a few toolkits, e.g. `bokeh`. To make a figure interactive, use the output format `format=html`. This only makes sense if your output file is also HTML. 

You can take a look at the [demonstration page](https://laurentrdc.github.io/pandoc-plot/) for an example result.

Many interactive plots rely on javascript scripts stored on the internet. If you want to have a self-contained document that can be viewed offline -- or you want your document to work for the next 10 years --, you can use pandoc's `--self-contained` flag:

```bash
pandoc --self-contained --filter pandoc-plot -i mydoc.md -o webpage.html 
```

The resulting output `webpage.html` will contain everything, at the cost of size.

### Configuration

To avoid repetition, `pandoc-plot` can be configured using simple YAML
files. Here are **all** the possible parameters:

```{.yaml include=example-config.yml}
```

A file like the above sets the **default** values; you can still override them in documents directly.

The easiest way to specify configuration for `pandoc-plot` is to place a `.pandoc-plot.yml` file in the current working directory. You can also specify a configuration file in document metadata, under the `plot-configuration` key. For example, in Markdown:

```markdown
---
title: My document
author: John Doe
plot-configuration: /path/to/file.yml
---

```

or on the command line, using the pandoc `-M/--metadata` flag:

```bash
pandoc --filter pandoc-plot -M plot-configuration=/path/to/file.yml ...
```

The hierarchy of configuration files is as follows:

1. A configuration file specified in the metadata under the `plot-configuration` key;
2. Otherwise, a file in the current working directory named `.pandoc-plot.yml`;
3. Finally, the default configuration is used.

#### Executables

The `executable` parameter for all toolkits can be either the executable name (if it is present on the PATH), or the full path to the executable.

Examples:

```yaml
matplotlib:
  executable: python3
```

```yaml
matlabplot:
  executable: "C:\Program Files\Matlab\R2019b\bin\matlab.exe"
```

#### Toolkit-specific options

##### Matplotlib

* `tight_bbox` is a boolean that determines whether to use `bbox_inches="tight"` or not when saving Matplotlib figures. For example, `tight_bbox: true`. See [here](https://matplotlib.org/api/_as_gen/matplotlib.pyplot.savefig.html) for details.
* `transparent` is a boolean that determines whether to make Matplotlib figure background transparent or not. This is useful, for example, for displaying a plot on top of a colored background on a web page. High-resolution figures are not affected. For example, `transparent: true`.

#### Logging

If you are running `pandoc-plot` on a large document, you might want to turn on logging. You can do so via the configuration file as follows:

````yaml
logging:
    # Possible verbosity values: debug, error, warning, info, silent
    # debug level shows all messages
    # error level shows all but debug messages, etc.
    verbosity: info
    
    # OPTIONAL: log to file
    # Remove line below to log to stderr
    filepath: log.txt
````

By default, `pandoc-plot` logs warnings and errors to the standard error stream only.

### Other commands

#### Finding installed toolkits

You can determine which toolkits are available on your current machine using the `pandoc-plot toolkits` command. Here is the full help text:

```{.bash include=help-toolkits.txt}
```

#### Cleaning output

Figures produced by `pandoc-plot` can be placed in a few different locations. You can set a default location in the [Configuration](#configuration), but you can also re-direct specific figures in other directories if you use the `directory=...` argument in code blocks. These figures will build up over time. You can use the `clean` command to scan documents and delete the associated `pandoc-plot` output files. For example, to delete the figures generated from the `input.md` file:

```bash
pandoc-plot clean input.md
```

This sill remove all directories where a figure *could* have been placed. **WARNING**: all files will be removed.

Here is the full help text for the `clean` command:

```{.bash include=help-clean.txt}
```

#### Configuration template

Because `pandoc-plot` supports a few toolkits, there are a lot of configuration options. Don't start from scratch! The `write-example-config` command will create a file for you, which you can then modify:

```bash
pandoc-plot write-example-config
```

You will need to re-name the file to `.pandoc-ploy.yml` to be able to use it, so don't worry about overwriting your own configuration.

Here is the full help text for the `write-example-config` command:

```{.bash include=help-config.txt}

### As a Haskell library

To include the functionality of `pandoc-plot` in a Haskell package, you can use the `makePlot` function (for single blocks) or `plotTransform` function (for entire documents). [Take a look at the documentation on Hackage](https://hackage.haskell.org/package/pandoc-plot).

#### Usage with Hakyll

In case you want to use the filter with your own Hakyll setup, you can use a transform function that works on entire documents:

```haskell
import Text.Pandoc.Filter.Plot (plotTransform, defaultConfiguration)

import Hakyll

-- Unsafe compiler is required because of the interaction
-- in IO (i.e. running an external script).
makePlotPandocCompiler :: Compiler (Item String)
makePlotPandocCompiler = 
  pandocCompilerWithTransformM
    defaultHakyllReaderOptions
    defaultHakyllWriterOptions
    (unsafeCompiler . plotTransform defaultConfiguration)
```

## Warning

Do not run this filter on unknown documents. There is nothing in
`pandoc-plot` that can stop a script from performing **evil actions**.
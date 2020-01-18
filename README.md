# pandoc-plot - A Pandoc filter to generate figures directly from documents

[![Build status](https://ci.appveyor.com/api/projects/status/mmgiuk52j356e6jp?svg=true)](https://ci.appveyor.com/project/LaurentRDC/pandoc-plot) [![Build Status](https://dev.azure.com/laurentdecotret/pandoc-plot/_apis/build/status/LaurentRDC.pandoc-plot?branchName=master)](https://dev.azure.com/laurentdecotret/pandoc-plot/_build/latest?definitionId=5&branchName=master) ![GitHub](https://img.shields.io/github/license/LaurentRDC/pandoc-plot)

`pandoc-plot` turns code blocks present in your documents into embedded figures, using your plotting toolkit of choice.

* [Usage](#usage)
* [Supported toolkits](#supported-toolkits)
* [Features](#features)
    * [Captions](#captions)
    * [Link to source code](#link-to-source-code)
    * [Preamble scripts](#preamble-scripts)
    * [No wasted work](#no-wasted-work)
    * [Compatibility with pandoc-crossref](#compatibility-with-pandoc-crossref)
* [Configuration](#configuration)
    * [Toolkit-specific options](#toolkit-specific-options)
* [Installation](#installation)
* [Warning](#warning)

## Usage

This program is a [Pandoc](https://pandoc.org/) filter. It operates on the Pandoc abstract syntax tree, and can therefore be used in the middle of conversion from input format to output format.

The filter recognizes code blocks with classes that match plotting toolkits. For example, using the `matplotlib` toolkit:

~~~markdown
# My document

This is a paragraph.

```{.matplotlib}
import matplotlib.pyplot as plt

plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
~~~

Putting the above in `input.md`, we can then generate the plot and embed it in an HTML page:

```bash
pandoc --filter pandoc-plot input.md --output output.html
```

## Supported toolkits

`pandoc-plot` currently supports the following plotting toolkits (installed separately):

* `matplotlib`: plots using the [matplotlib](https://matplotlib.org/) Python library;
* `plotly_python` : plots using the [plotly](https://plot.ly/python/) Python library;
* `matlabplot`: plots using [MATLAB](https://www.mathworks.com/);
* `mathplot` : plots using [Mathematica](https://www.wolfram.com/mathematica/);
* `octaveplot`: plots using [GNU Octave](https://www.gnu.org/software/octave/);

To know which toolkits are useable on *your machine* (and which ones are not available), you can check with the `--toolkits/-t` flag:

```bash
pandoc-plot --toolkits
```

### In progress

Support for the following plotting toolkits is coming:

* [gnuplot](http://www.gnuplot.info/)
* [Plotly R](https://plot.ly/r/)
* [ggplot2](https://ggplot2.tidyverse.org/)

**Wish your plotting toolkit of choice was available? Please [raise an issue](https://github.com/LaurentRDC/pandoc-plot/issues)!**

## Features

### Captions

You can also specify a caption for your image. This is done using the optional `caption` parameter.

__Markdown__:

~~~markdown
```{.matlabplot caption="This is a simple figure"}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
```
~~~

__LaTex__:

```latex
\begin{minted}[caption=This is a simple figure]{matlabplot}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
\end{minted}
```

Caption formatting is either plain text or Markdown. LaTeX-style math is also support in captions (using dollar signs $...$).

### Link to source code

In case of an output format that supports links (e.g. HTML), the embedded image generated by `pandoc-plot` can show a link to the source code which was used to generate the file. Therefore, other people can see what code was used to create your figures. 

You can turn this off via the `source=true` key:

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

### No wasted work

`pandoc-plot` minimizes work, only generating figures if it absolutely must, i.e. if the content has changed. Therefore, you can confidently run the filter on very large documents containing dozens of figures --- like a book or a thesis --- and only the figures which have changed will be re-generated.

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

## Configuration

To avoid repetition, `pandoc-plot` can be configured using simple YAML files. `pandoc-plot` will look for a `.pandoc-plot.yml` file in the current working directory. Here are **all** the possible parameters:

```yaml
# The following parameters affect all toolkits
directory: plots/
source: false
dpi: 80
format: PNG
python_interpreter: python

# The possible parameters for the Matplotlib toolkit
matplotlib:
  preamble: matplotlib.py
  tight_bbox: false
  transparent: false
  executable: python

# The possible parameters for the MATLAB toolkit
matlabplot:
  preamble: matlab.m
  executable: matlab

# The possible parameters for the Plotly/Python toolkit
plotly_python:
  preamble: plotly-python.py
  executable: python

# The possible parameters for the Mathematica toolkit
mathplot:
  preamble: mathematica.m
  executable: math

# the possible parameters for the GNU Octave toolkit
octaveplot:
  preamble: octave.m
  executable: octave
```

A file like the above sets the **default** values; you can still override them in documents directly.

Using `pandoc-plot --write-example-config` will write the default configuration to a file which you can then customize.

### Toolkit-specific options

#### Matplotlib

* `tight_bbox` is a boolean that determines whether to use `bbox_inches="tight"` or not when saving Matplotlib figures. For example, `tight_bbox: true`. See [here](https://matplotlib.org/api/_as_gen/matplotlib.pyplot.savefig.html) for details.
* `transparent` is a boolean that determines whether to make Matplotlib figure background transparent or not. This is useful, for example, for displaying a plot on top of a colored background on a web page. High-resolution figures are not affected. For example, `transparent: true`.

## Installation

### Binaries

Windows binaries are available on [GitHub](https://github.com/LaurentRDC/pandoc-plot/releases). Place the executable in a location that is in your PATH to be able to call it.

If you can show me how to generate binaries for other platform using e.g. Azure Pipelines, let me know!

### Installers (Windows)

Windows installers are made available thanks to [Inno Setup](http://www.jrsoftware.org/isinfo.php). You can download them from the [release page](https://github.com/LaurentRDC/pandoc-plot/releases/latest).

### From Hackage/Stackage

*Coming soon*

### From source

Building from source can be done using [`stack`](https://docs.haskellstack.org/en/stable/README/) or [`cabal`](https://www.haskell.org/cabal/):

```bash
git clone https://github.com/LaurentRDC/pandoc-plot
cd pandoc-plot
stack install # Alternatively, `cabal install`
```

## Warning

Do not run this filter on unknown documents. There is nothing in `pandoc-plot` that can stop a script from performing **evil actions**.
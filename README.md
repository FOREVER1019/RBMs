# xxxx (the name of this package)




## Contents

- [Overview](#overview)
- [Repo Contents](#repo-contents)
- [System Requirements](#system-requirements)
- [Installation Guide](#installation-guide)
- [Demo](#demo)
- [Results](#results)
- [License](./LICENSE)
- [Issues](https://github.com/ebridge2/lol/issues)
- [Citation](#citation)

# Overview

xxxx.

# Repo Contents

- [xxx](./xxx): xxxxx

# System Requirements

## Hardware Requirements

The xxx package requires a high-performance computer with large RAM to support the operations defines by a user. For minimal performance, this will be a computer with about X GB of RAM. For optimal performance, we recommend a computer with the following specs:

RAM: 96+ GB  
CPU: 56+ cores, 2.6+ GHz/core

## Software Requirements

### OS Requirements

The package development version is tested on *Windows* operating systems. The developmental version of the package has been tested on the following systems:

Windows: Windows Server 2012 R2 Standard 

Before setting up the xxx package, users should have Matlab version R2017a or higher.


# Installation Guide

## Stable Release

`lolR` is available in a stable release on CRAN:

```
install.packages('lolR')
```

## Development Version

### Package dependencies

Users should install the following packages prior to installing `lolR`, from an `R` terminal:

```
install.packages(c('ggplot2', 'abind', 'irlba', 'knitr', 'rmarkdown', 'latex2exp', 'MASS', 'randomForest'))
```

which will install in about 30 seconds on a machine with the recommended specs.

The `lolR` package functions with all packages in their latest versions as they appear on `CRAN` on December 13, 2017. Users can check [CRAN snapshot](https://mran.microsoft.com/timemachine/) for details. The versions of software are, specifically:
```
abind_1.4-5
latex2exp_0.4.0
ggplot2_2.2.1
irlba_2.3.1
Matrix_1.2-3
MASS_7.3-47
randomForest_4.6-12
```

If you are having an issue that you believe to be tied to software versioning issues, please drop us an [Issue](https://github.com/neurodata/lol/issues). 

### Package Installation

From an `R` session, type:

```
require(devtools)
install_github('neurodata/lol', build_vignettes=TRUE, force=TRUE)  # install lol with the vignettes
require(lolR)
vignette("lol", package="lolR")  # view one of the basic vignettes
```

The package should take approximately 40 seconds to install with vignettes on a recommended computer. 

# Demo

## Functions

For interactive demos of the functions, please check out the vignettes built into the package. They can be accessed as follows:

```
require(lolR)
vignette('lol')
vignette('pca')
vignette('cpca')
vignette('lrcca')
vignette('mdp')
vignette('xval')
vignette('qoq')
vignette('simulations')
vignette('nearestCentroid')
```

## Extending the lolR Package

The lolR package makes many useful resources available (such as embedding and cross-validation) for simple extension. 

To extend the lolR package, check out the vignettes:

```
require(lolR)
vignette('extend_embedding')
vignette('extend_classification')
```

# Results

In this [benchmark comparison](http://docs.neurodata.io/lol/lol-paper/figures/real_data.html), we show that LOL does better than all linear embedding techniques in supervised HDLSS settings when dimensionality is high (d > 100, ntrain <= d) on 20 benchmark problems from the [UCI](https://archive.ics.uci.edu/ml/index.php) and [PMLB](https://github.com/EpistasisLab/penn-ml-benchmarks) datasets. LOL provides a good tradeoff between maintaining the class conditional difference (good misclassification rate) in a small number of dimensions (low number of embedding dimensions).

# Citation

For usage of the package and associated manuscript, please cite according to the enclosed [citation.bib](./citation.bib).

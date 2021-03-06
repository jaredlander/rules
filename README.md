# rules

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build status](https://github.com/tidymodels/rules/workflows/R-CMD-check/badge.svg)](https://github.com/tidymodels/rules)
[![Codecov test coverage](https://codecov.io/gh/tidymodels/rules/branch/master/graph/badge.svg)](https://codecov.io/gh/tidymodels/rules?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/rules)](https://cran.r-project.org/package=rules)

<!-- badges: end -->

`rules` is a "`parsnip`-adjacent" packages with model definitions for different rule-based models, including:

 * cubist models that have discrete rule sets that contain linear models with an ensemble method similar to boosting
 * classification rules where a ruleset is derived from an initial tree fit
 * _rule-fit_ models that begin with rules extracted from a tree ensemble which are then added to a regularized linear or logistic regression. 

## Installation

Th package is not yet on CRAN and can be installed via: 

``` r
# install.packages("devtools")
devtools::install_github("tidymodels/rules")
```

## Code of Conduct
  
Please note that the rules project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.

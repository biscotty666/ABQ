# Collapse for tidyverse users


[Source](https://fastverse.org/collapse/articles/collapse_for_tidyverse_users.html)

``` r
library(collapse)
```

    collapse 2.1.6, see ?`collapse-package` or ?`collapse-documentation`


    Attaching package: 'collapse'

    The following object is masked from 'package:stats':

        D

``` r
library(magrittr)
library(dplyr)
```


    Attaching package: 'dplyr'

    The following objects are masked from 'package:stats':

        filter, lag

    The following objects are masked from 'package:base':

        intersect, setdiff, setequal, union

``` r
options(paged.print = F)
```

Substitute `collapse` functions for `dplyr` ones without the prefix.

``` r
set_collapse(mask = "manip")
```

``` r
mtcars %>% 
  subset(mpg > 11) %>% 
  group_by(cyl, vs, am) %>% 
  summarise(across(c(mpg, carb, hp), mean),
            qsec_wt = weighted.mean(qsec, wt))
```

    `summarise()` has regrouped the output.
    ℹ Summaries were computed grouped by cyl, vs, and am.
    ℹ Output is grouped by cyl and vs.
    ℹ Use `summarise(.groups = "drop_last")` to silence this message.
    ℹ Use `summarise(.by = c(cyl, vs, am))` for per-operation grouping
      (`?dplyr::dplyr_by`) instead.

    # A tibble: 7 × 7
    # Groups:   cyl, vs [5]
        cyl    vs    am   mpg  carb    hp qsec_wt
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>   <dbl>
    1     4     0     1  26    2     91      16.7
    2     4     1     0  22.9  1.67  84.7    21.0
    3     4     1     1  28.4  1.43  80.6    18.8
    4     6     0     1  20.6  4.67 132.     16.3
    5     6     1     0  19.1  2.5  115.     19.2
    6     8     0     0  16.0  2.9  191      17.0
    7     8     0     1  15.4  6    300.     14.6

``` r
mtcars %>% 
  fsubset(mpg > 11) %>% 
  fgroup_by(cyl, vs, am) %>% 
  fsummarise(
    across(c(mpg, carb, hp), fmean),
    qsec_wt = fmean(qsec, wt)
  ) %>% 
  as_tibble()
```

    # A tibble: 7 × 7
        cyl    vs    am   mpg  carb    hp qsec_wt
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>   <dbl>
    1     4     0     1  26    2     91      16.7
    2     4     1     0  22.9  1.67  84.7    21.0
    3     4     1     1  28.4  1.43  80.6    18.8
    4     6     0     1  20.6  4.67 132.     16.3
    5     6     1     0  19.1  2.5  115.     19.2
    6     8     0     0  16.0  2.9  191      17.0
    7     8     0     1  15.4  6    300.     14.6

# Using fast statistical functions

``` r
fmean(mtcars$mpg)
```

    [1] 20.09063

``` r
fmean(mtcars)
```

           mpg        cyl       disp         hp       drat         wt       qsec 
     20.090625   6.187500 230.721875 146.687500   3.596563   3.217250  17.848750 
            vs         am       gear       carb 
      0.437500   0.406250   3.687500   2.812500 

Weighted mean

``` r
fmean(mtcars$mpg, w = mtcars$wt)
```

    [1] 18.54993

Group mean

``` r
fmean(mtcars$mpg, g = mtcars$cyl, w = mtcars$wt)
```

           4        6        8 
    25.93504 19.64578 14.80643 

``` r
mtcars %>% 
  fsubset(mpg > 11) %>% 
  fgroup_by(cyl, vs, am) %>% 
  fselect(mpg, carb, hp) %>% 
  fmean()
```

      cyl vs am      mpg     carb        hp
    1   4  0  1 26.00000 2.000000  91.00000
    2   4  1  0 22.90000 1.666667  84.66667
    3   4  1  1 28.37143 1.428571  80.57143
    4   6  0  1 20.56667 4.666667 131.66667
    5   6  1  0 19.12500 2.500000 115.25000
    6   8  0  0 15.98000 2.900000 191.00000
    7   8  0  1 15.40000 6.000000 299.50000

# Code efficiency

Optimized version of above

``` r
mtcars %>% 
  fsubset(mpg > 11, cyl, vs, am, mpg, carb, hp, qsec, wt) %>% 
  fgroup_by(cyl, vs, am) %>% 
  fsummarise(across(c(mpg, carb, hp), fmean),
             qsec_wt = fmean(qsec, wt))
```

      cyl vs am      mpg     carb        hp  qsec_wt
    1   4  0  1 26.00000 2.000000  91.00000 16.70000
    2   4  1  0 22.90000 1.666667  84.66667 21.04028
    3   4  1  1 28.37143 1.428571  80.57143 18.75509
    4   6  0  1 20.56667 4.666667 131.66667 16.33306
    5   6  1  0 19.12500 2.500000 115.25000 19.21275
    6   8  0  0 15.98000 2.900000 191.00000 17.01239
    7   8  0  1 15.40000 6.000000 299.50000 14.55297

Without weighted mean

``` r
mtcars %>% 
  fsubset(mpg > 11, cyl, vs, am, mpg, carb, hp) %>% 
  fgroup_by(cyl, vs, am) %>% 
  fmean()
```

      cyl vs am      mpg     carb        hp
    1   4  0  1 26.00000 2.000000  91.00000
    2   4  1  0 22.90000 1.666667  84.66667
    3   4  1  1 28.37143 1.428571  80.57143
    4   6  0  1 20.56667 4.666667 131.66667
    5   6  1  0 19.12500 2.500000 115.25000
    6   8  0  0 15.98000 2.900000 191.00000
    7   8  0  1 15.40000 6.000000 299.50000

Finally, we could set the following options to toggle unsorted grouping,
no missing value skipping, and multithreading across the three columns
for more efficient execution.

``` r
mtcars %>% 
  fsubset(mpg > 11, cyl, vs, am, mpg, carb, hp) %>% 
  fgroup_by(cyl, vs, am, sort = F) %>% 
  fmean(nthreads = 3, na.rm = F)
```

      cyl vs am      mpg     carb        hp
    1   6  0  1 20.56667 4.666667 131.66667
    2   4  1  1 28.37143 1.428571  80.57143
    3   6  1  0 19.12500 2.500000 115.25000
    4   8  0  0 15.98000 2.900000 191.00000
    5   4  1  0 22.90000 1.666667  84.66667
    6   4  0  1 26.00000 2.000000  91.00000
    7   8  0  1 15.40000 6.000000 299.50000

# Internal Grouping

Avoid `fgroup_by()` where possiblem especially with `mutate()`.

``` r
mtcars %>% 
  mutate(
    mpg_median = fmedian(mpg, list(cyl, vs, am), 
                         TRA = "fill")
  ) %>% 
  head(3)
```

                   mpg cyl disp  hp drat    wt  qsec vs am gear carb mpg_median
    Mazda RX4     21.0   6  160 110 3.90 2.620 16.46  0  1    4    4       21.0
    Mazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4       21.0
    Datsun 710    22.8   4  108  93 3.85 2.320 18.61  1  1    4    1       30.4

`fbetween` for averaging, `fwithin` for centering.

``` r
mtcars %>% 
  mutate(
    mpg_median = fbetween(mpg, list(cyl, vs, am)) 
  ) %>% 
  head(3)
```

                   mpg cyl disp  hp drat    wt  qsec vs am gear carb mpg_median
    Mazda RX4     21.0   6  160 110 3.90 2.620 16.46  0  1    4    4   20.56667
    Mazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4   20.56667
    Datsun 710    22.8   4  108  93 3.85 2.320 18.61  1  1    4    1   28.37143

Of course, if we want to apply different functions using the same
grouping, fgroup_by() is sensible, but for mutate operations it also has
the argument return.groups = FALSE, which avoids materializing the
unique grouping columns, saving some memory.

``` r
mtcars %>% 
  fgroup_by(cyl, vs, am, return.groups = F) %>% 
  fmutate(
    mpg_median = fmedian(mpg),
    mpg_mean = fmean(mpg),
    mpg_mean_same = fbetween(mpg),
    mpg_demean = fwithin(mpg),
    mpg_demean_same = fmean(mpg, TRA = "-"),
    mpg_scale = fscale(mpg),
    .keep = "used"
  ) %>% 
  fungroup() %>% 
  head(3)
```

                   mpg cyl vs am mpg_median mpg_mean mpg_mean_same mpg_demean
    Mazda RX4     21.0   6  0  1       21.0 20.56667      20.56667  0.4333333
    Mazda RX4 Wag 21.0   6  0  1       21.0 20.56667      20.56667  0.4333333
    Datsun 710    22.8   4  1  1       30.4 28.37143      28.37143 -5.5714286
                  mpg_demean_same  mpg_scale
    Mazda RX4           0.4333333  0.5773503
    Mazda RX4 Wag       0.4333333  0.5773503
    Datsun 710         -5.5714286 -1.1710339

Using `TRA = "/"` turns the column vectors into proportions.

``` r
exports <- expand.grid(c = paste0("c", 1:8), s = paste0("s", 1:8), y = 1:15) %>% 
  fmutate(v = round(abs(rnorm(length(c), mean = 5)), 2)) %>% 
  fsubset(-sample.int(length(v), 360))
head(exports); nrow(exports)
```

       c  s y    v
    1 c1 s1 1 5.94
    2 c2 s1 1 6.27
    3 c3 s1 1 5.87
    4 c7 s1 1 4.50
    5 c2 s2 1 6.06
    6 c3 s2 1 5.85

    [1] 600

It is very easy then to compute Balassa’s (1965) Revealed Comparative
Advantage (RCA) index, which is the share of a sector in country exports
divided by the share of the sector in world exports. An index above 1
indicates that a RCA of country c in sector s.

`settfm()` modifies exports and assigns it back to the global
environment

``` r
settfm(exports,
       RCA = fsum(v, list(c, y), TRA = "/") %/=% 
         fsum(fsum(v, y, TRA = "/"), list(s, y), TRA = "fill", set = TRUE))
```

``` r
pivot(exports,
      ids = "c", values = "RCA", names = "s",
      how = "wider", FUN = "mean", sort = TRUE)
```

       c       s1       s2       s3       s4       s5       s6       s7       s8
    1 c1 1.555851 1.423652 1.216637 1.510286 1.608164 2.185691 2.143396 1.400215
    2 c2 1.743997 1.553026 1.272316 1.513169 1.396050 1.504916 1.815690 1.681429
    3 c3 1.457896 1.473422 1.683250 1.349432 1.449479 1.642493 1.497444 1.939765
    4 c4 1.703284 1.949009 1.469126 1.470840 1.460665 2.082201 1.523834 1.729710
    5 c5 1.892744 1.617218 1.426551 1.547398 1.273752 1.359492 1.600417 1.633313
    6 c6 1.467185 1.277744 1.536461 1.395987 1.493548 1.591006 1.651440 1.581500
    7 c7 1.972968 1.607949 1.448348 1.887978 1.585810 1.516557 1.638759 1.722478
    8 c8 1.329834 1.381249 1.313381 1.612575 1.600482 1.672588 1.461005 1.651897

We may also wish to investigate the growth rate of RCA. This can be done
using fgrowth(). Since the panel is irregular, i.e., not every sector is
observed in every year, it is critical to also supply the time variable.

``` r
exports %>% 
  fmutate(
    RCA_growth = fgrowth(RCA, g = list(c, s), t = y)
  ) %>% 
  pivot(ids = "c", values = "RCA_growth", names = "s",
        how = "wider", FUN = fmedian, sort = TRUE)
```

       c         s1         s2          s3         s4         s5         s6
    1 c1   4.756085 -12.567490   0.5359439 -19.374451   8.000948  66.759567
    2 c2  14.748965  34.810017  66.9788024  15.971601   6.605176  -7.064089
    3 c3  45.652738   3.624638  44.3494889  18.956367 -21.281602   8.548282
    4 c4 -33.306584 -24.460026 -26.5280299 -14.679282  37.712197  -5.244132
    5 c5  -5.346409   3.706247   0.7110289  -4.662702  23.339520  -3.442846
    6 c6  14.379992   5.190963 -16.9733105   6.183175  19.946564 -24.047409
    7 c7  76.080451  -5.373853 -24.8326823 -33.312471  -3.336456  19.046070
    8 c8  24.775945  34.178157 -14.2074598   9.390538 -27.703777 -28.795046
              s7          s8
    1  -6.720760   0.1686274
    2 -25.983292 -22.6264272
    3 -14.533230  19.8406375
    4   4.346760  70.9730870
    5  57.276707 -16.6518142
    6   3.034325  13.3466404
    7  38.582468 125.5824082
    8 -19.123007  12.2579775

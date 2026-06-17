# Fast Data Manipulation


[Source](https://fastverse.org/collapse/articles/collapse_intro.html)

``` r
library(collapse)
```

    collapse 2.1.6, see ?`collapse-package` or ?`collapse-documentation`


    Attaching package: 'collapse'

    The following object is masked from 'package:stats':

        D

``` r
library(magrittr)
```

## Selecting and Replacing Columng

``` r
wlddev %>% 
  fselect(country, year, PCGDP:ODA) %>% 
  head(2)
```

          country year PCGDP LIFEEX GINI       ODA
    1 Afghanistan 1960    NA 32.446   NA 116769997
    2 Afghanistan 1961    NA 32.962   NA 232080002

``` r
wlddev %>% 
  fselect(-country, -year, -(PCGDP:ODA)) %>% 
  head(2)
```

      iso3c       date decade     region     income  OECD     POP
    1   AFG 1961-01-01   1960 South Asia Low income FALSE 8996973
    2   AFG 1962-01-01   1960 South Asia Low income FALSE 9169410

``` r
wlddev %>% 
  fselect(-c(country, year, PCGDP:ODA)) %>% 
  head(2)
```

      iso3c       date decade     region     income  OECD     POP
    1   AFG 1961-01-01   1960 South Asia Low income FALSE 8996973
    2   AFG 1962-01-01   1960 South Asia Low income FALSE 9169410

``` r
library(microbenchmark)
microbenchmark(fselect = collapse::fselect(wlddev, country, year, PCGDP:ODA),
               select = dplyr::select(wlddev, country, year, PCGDP:ODA))
```

    Unit: microseconds
        expr     min       lq       mean   median       uq        max neval cld
     fselect   4.256   5.1930    8.93118   9.8495  11.1430     23.937   100   a
      select 621.314 657.2355 2071.48617 676.9530 699.9945 134207.902   100   a

`fselect` can also replace

``` r
fselect(wlddev, PCGDP:POP) <- lapply(fselect(wlddev, PCGDP:POP), log)
```

    Warning in FUN(X[[i]], ...): NaNs produced

``` r
head(wlddev, 2)
```

          country iso3c       date year decade     region     income  OECD PCGDP
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE    NA
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE    NA
        LIFEEX GINI      ODA      POP
    1 3.479577   NA 18.57572 16.01240
    2 3.495355   NA 19.26259 16.03138

Efficient deletion

``` r
fselect(wlddev, country, year, PCGDP:POP) <- NULL
head(wlddev, 2)
```

      iso3c       date decade     region     income  OECD
    1   AFG 1961-01-01   1960 South Asia Low income FALSE
    2   AFG 1962-01-01   1960 South Asia Low income FALSE

``` r
rm(wlddev)
```

Other information returned by `fselect`.

``` r
wlddev %>% 
  fselect(PCGDP:POP, return = "names")
```

    [1] "PCGDP"  "LIFEEX" "GINI"   "ODA"    "POP"   

``` r
wlddev %>% 
  fselect(PCGDP:POP, return = "indices")
```

    [1]  9 10 11 12 13

``` r
wlddev %>% 
  fselect(PCGDP:POP, return = "named_indices")
```

     PCGDP LIFEEX   GINI    ODA    POP 
         9     10     11     12     13 

``` r
wlddev %>% 
  fselect(PCGDP:POP, return = "logical")
```

     [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE  TRUE
    [13]  TRUE

``` r
wlddev %>% 
  fselect(PCGDP:POP, return = "named_logical")
```

    country   iso3c    date    year  decade  region  income    OECD   PCGDP  LIFEEX 
      FALSE   FALSE   FALSE   FALSE   FALSE   FALSE   FALSE   FALSE    TRUE    TRUE 
       GINI     ODA     POP 
       TRUE    TRUE    TRUE 

There are no special methods for grouped tibbles.

Select variables with `get_vars`

``` r
wlddev %>% 
  get_vars(9:13) %>% 
  head(1)
```

      PCGDP LIFEEX GINI       ODA     POP
    1    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars( c("PCGDP","LIFEEX","GINI","ODA","POP")) %>% 
  head(1)
```

      PCGDP LIFEEX GINI       ODA     POP
    1    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars("[[:upper:]]", regex = T) %>% 
  head(1)
```

       OECD PCGDP LIFEEX GINI       ODA     POP
    1 FALSE    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars("PC|LI|GI|OD|PO", regex = T) %>% 
  head(1)
```

      PCGDP LIFEEX GINI       ODA     POP
    1    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars(c("PC","LI","GI","OD","PO"), regex = TRUE) %>% 
  head(1)
```

      PCGDP LIFEEX GINI       ODA     POP
    1    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars(is.numeric) %>% 
  head(1)
```

      year decade PCGDP LIFEEX GINI       ODA     POP
    1 1960   1960    NA 32.446   NA 116769997 8996973

``` r
wlddev %>% 
  get_vars(is.numeric, return = "names") %>% 
  head(1)
```

    [1] "year"

Can also replace with `get_vars`

``` r
get_vars(wlddev, 9:13) <- lapply(
  get_vars(wlddev, 9:13), log
)
```

    Warning in FUN(X[[i]], ...): NaNs produced

``` r
get_vars(wlddev, 9:13) <- NULL
head(wlddev)
```

          country iso3c       date year decade     region     income  OECD
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE
    3 Afghanistan   AFG 1963-01-01 1962   1960 South Asia Low income FALSE
    4 Afghanistan   AFG 1964-01-01 1963   1960 South Asia Low income FALSE
    5 Afghanistan   AFG 1965-01-01 1964   1960 South Asia Low income FALSE
    6 Afghanistan   AFG 1966-01-01 1965   1960 South Asia Low income FALSE

``` r
rm(wlddev)
```

collapse offers a set of functions to efficiently select and replace
data by data type: `num_vars`, `cat_vars` (for categorical = non-numeric
columns), `char_vars`, `fact_vars`, `logi_vars` and `date_vars` (for
date and date-time columns).

``` r
num_vars(wlddev) %>% head(2)
```

      year decade PCGDP LIFEEX GINI       ODA     POP
    1 1960   1960    NA 32.446   NA 116769997 8996973
    2 1961   1960    NA 32.962   NA 232080002 9169410

``` r
cat_vars(wlddev) %>% head(2)
```

          country iso3c       date     region     income  OECD
    1 Afghanistan   AFG 1961-01-01 South Asia Low income FALSE
    2 Afghanistan   AFG 1962-01-01 South Asia Low income FALSE

``` r
fact_vars(wlddev) %>% head(2)
```

      iso3c     region     income
    1   AFG South Asia Low income
    2   AFG South Asia Low income

Replacing

``` r
fact_vars(wlddev) <- fact_vars(wlddev)
```

## Subsetting

`fsubset` allows multiple comma-separated select arguments after the
subset argument, and it also preserves all attributes of subsetted
columns:

``` r
fsubset(GGDC10S, Variable == "VA" & Year > 1990,
        Country, Year, AGR:GOV) %>% head(2)
```

      Country Year      AGR      MIN      MAN       PU      CON      WRT      TRA
    1     BWA 1991 303.1157 2646.950 472.6488 160.6079 580.0876 806.7509 232.7884
    2     BWA 1992 333.4364 2690.939 537.4274 178.4532 678.7320 725.2577 285.1403
          FIRE      GOV
    1 432.6965 1073.263
    2 517.2141 1234.012

``` r
fsubset(GGDC10S, Variable == "VA" & Year > 1990,
        -(Regioncode:Variable), -(OTH:SUM)) %>% head(2)
```

      Country Year      AGR      MIN      MAN       PU      CON      WRT      TRA
    1     BWA 1991 303.1157 2646.950 472.6488 160.6079 580.0876 806.7509 232.7884
    2     BWA 1992 333.4364 2690.939 537.4274 178.4532 678.7320 725.2577 285.1403
          FIRE      GOV
    1 432.6965 1073.263
    2 517.2141 1234.012

``` r
ss(GGDC10S, 1:2, 6:16)
```

      AGR MIN MAN PU CON WRT TRA FIRE GOV OTH SUM
    1  NA  NA  NA NA  NA  NA  NA   NA  NA  NA  NA
    2  NA  NA  NA NA  NA  NA  NA   NA  NA  NA  NA

``` r
ss(GGDC10S, -(1:2), c("AGR","MIN")) %>% head(2)
```

      AGR MIN
    1  NA  NA
    2  NA  NA

``` r
microbenchmark(
  base = subset(GGDC10S, Variable == "VA" & Year > 1990, AGR:SUM),
  collapse = fsubset(GGDC10S, Variable == "VA" & Year > 1990, AGR:SUM)
)
```

    Unit: microseconds
         expr     min       lq      mean  median       uq      max neval cld
         base 141.456 147.7615 183.57329 164.464 222.5535  289.420   100  a 
     collapse  41.704  45.8145  88.56741  55.371  72.9110 2907.132   100   b

``` r
microbenchmark(GGDC10S[1:10, 1:10], ss(GGDC10S, 1:10, 1:10))
```

    Unit: microseconds
                        expr    min      lq     mean  median      uq     max neval
         GGDC10S[1:10, 1:10] 52.557 53.0710 55.56265 53.5825 54.6265 108.079   100
     ss(GGDC10S, 1:10, 1:10)  2.742  2.9755  3.53243  3.3255  3.5900  20.082   100
     cld
      a 
       b

## Reordering Rows and Columns

Replaces `arrange`. Negative variable names indicate descending sort.

``` r
roworder(GGDC10S, -Variable, Country) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode        Region Variable Year          AGR MIN         MAN
    1     ARG        LAM Latin America       VA 1950 5.887857e-07   0 3.53443e-06
    2     ARG        LAM Latin America       VA 1951 9.165327e-07   0 4.77277e-06

``` r
microbenchmark(collapse = collapse::roworder(GGDC10S, -Variable, Country),
               dplyr = dplyr::arrange(GGDC10S, desc(Variable), Country))
```

    Unit: microseconds
         expr      min        lq      mean   median       uq      max neval cld
     collapse  125.606  136.1495  219.5048  150.981  196.348 2660.809   100  a 
        dplyr 1816.735 1900.5285 2114.4860 1955.948 2031.519 7991.630   100   b

The function roworderv is a standard evaluation analogue to roworder:

``` r
roworderv(GGDC10S, c("Variable", "Country"), 
          decreasing = c(TRUE, FALSE)) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode        Region Variable Year          AGR MIN         MAN
    1     ARG        LAM Latin America       VA 1950 5.887857e-07   0 3.53443e-06
    2     ARG        LAM Latin America       VA 1951 9.165327e-07   0 4.77277e-06

Move or exchange rows with `roworderv`

``` r
GGDC10S %>% roworderv(
  neworder = which(GGDC10S$Country == "GHA")
) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode             Region Variable Year        AGR         MIN
    1     GHA        SSA Sub-saharan Africa       VA 1960 0.03576160 0.005103683
    2     GHA        SSA Sub-saharan Africa       VA 1961 0.03823049 0.005456030
             MAN
    1 0.01744687
    2 0.01865136

``` r
GGDC10S %>% roworderv(
  neworder = which(GGDC10S$Country == "BWA"), pos = "end"
) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode             Region Variable Year      AGR      MIN     MAN
    1     ETH        SSA Sub-saharan Africa       VA 1960       NA       NA      NA
    2     ETH        SSA Sub-saharan Africa       VA 1961 4495.614 11.86979 109.616

`pos = "exchange"` arranges selected rows in the order they are passed,
without affecting other rows

``` r
GGDC10S %>% roworderv(
  neworder = with(GGDC10S, c(which(Country == "GHA"),
                             which(Country == "BWA"))),
  pos = "exchange"
) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode             Region Variable Year        AGR         MIN
    1     GHA        SSA Sub-saharan Africa       VA 1960 0.03576160 0.005103683
    2     GHA        SSA Sub-saharan Africa       VA 1961 0.03823049 0.005456030
             MAN
    1 0.01744687
    2 0.01865136

## Transforming and Computing New Columns

`ftransform` always returns the entire data frame.

``` r
GGDC10S %>% 
  ftransform(AGR_perc = AGR / SUM * 100,
             Year = as.integer(Year),
             AGR = NULL) %>% 
  tail(2)
```

         Country Regioncode                       Region Variable Year      MIN
    5026     EGY       MENA Middle East and North Africa      EMP 2011 27.56394
    5027     EGY       MENA Middle East and North Africa      EMP 2012 24.78083
              MAN       PU      CON      WRT      TRA     FIRE      GOV OTH
    5026 2373.814 317.9979 2795.264 3020.236 2048.335 814.7403 5635.522  NA
    5027 2348.434 324.9332 2931.196 3109.522 2065.004 832.4770 5735.623  NA
              SUM AGR_perc
    5026 22219.39 23.33961
    5027 22532.56 22.90281

``` r
GGDC10S %>% 
  ftransform(MIN_mean = fmean(MIN),
             Intercept = 1) %>% 
  tail(2)
```

         Country Regioncode                       Region Variable Year      AGR
    5026     EGY       MENA Middle East and North Africa      EMP 2011 5185.919
    5027     EGY       MENA Middle East and North Africa      EMP 2012 5160.590
              MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5026 27.56394 2373.814 317.9979 2795.264 3020.236 2048.335 814.7403 5635.522
    5027 24.78083 2348.434 324.9332 2931.196 3109.522 2065.004 832.4770 5735.623
         OTH      SUM MIN_mean Intercept
    5026  NA 22219.39  1867909         1
    5027  NA 22532.56  1867909         1

The modification `ftransformv` exists to transform specific columns
using a function:

``` r
GGDC10S %>% 
  ftransformv(6:16, log) %>% 
  tail(2)
```

    Warning in FUN(X[[i]], ...): NaNs produced

         Country Regioncode                       Region Variable Year      AGR
    5026     EGY       MENA Middle East and North Africa      EMP 2011 8.553702
    5027     EGY       MENA Middle East and North Africa      EMP 2012 8.548806
              MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5026 3.316508 7.772253 5.762045 7.935682 8.013090 7.624782 6.702869 8.636845
    5027 3.210070 7.761504 5.783620 7.983166 8.042224 7.632888 6.724406 8.654452
         OTH      SUM
    5026  NA 10.00872
    5027  NA 10.02272

``` r
GGDC10S %>% 
  ftransformv(6:16, `*`, 100 / SUM) %>% 
  tail(2)
```

         Country Regioncode                       Region Variable Year      AGR
    5026     EGY       MENA Middle East and North Africa      EMP 2011 23.33961
    5027     EGY       MENA Middle East and North Africa      EMP 2012 22.90281
               MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5026 0.1240535 10.68352 1.431173 12.58029 13.59279 9.218680 3.666798 25.36308
    5027 0.1099779 10.42240 1.442061 13.00871 13.80013 9.164534 3.694551 25.45482
         OTH SUM
    5026  NA 100
    5027  NA 100

``` r
GGDC10S %>% 
  ftransformv(is.numeric, log) %>% 
  tail(2)
```

    Warning in FUN(X[[i]], ...): NaNs produced

         Country Regioncode                       Region Variable     Year      AGR
    5026     EGY       MENA Middle East and North Africa      EMP 7.606387 8.553702
    5027     EGY       MENA Middle East and North Africa      EMP 7.606885 8.548806
              MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5026 3.316508 7.772253 5.762045 7.935682 8.013090 7.624782 6.702869 8.636845
    5027 3.210070 7.761504 5.783620 7.983166 8.042224 7.632888 6.724406 8.654452
         OTH      SUM
    5026  NA 10.00872
    5027  NA 10.02272

``` r
GGDC10S %>%
  ftransform(num_vars(.) %>%
    lapply(log) %>%
    replace_Inf()) %>%
  tail(2)
```

    Warning in FUN(X[[i]], ...): NaNs produced

         Country Regioncode                       Region Variable     Year      AGR
    5026     EGY       MENA Middle East and North Africa      EMP 7.606387 8.553702
    5027     EGY       MENA Middle East and North Africa      EMP 7.606885 8.548806
              MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5026 3.316508 7.772253 5.762045 7.935682 8.013090 7.624782 6.702869 8.636845
    5027 3.210070 7.761504 5.783620 7.983166 8.042224 7.632888 6.724406 8.654452
         OTH      SUM
    5026  NA 10.00872
    5027  NA 10.02272

The function settransform(v) can be used to change the input data frame
by reference:

``` r
settransform(GGDC10S, FIRE_MAN = FIRE / MAN,
                      Regioncode = NULL, Region = NULL)
tail(GGDC10S, 2)
```

         Country Variable Year      AGR      MIN      MAN       PU      CON
    5026     EGY      EMP 2011 5185.919 27.56394 2373.814 317.9979 2795.264
    5027     EGY      EMP 2012 5160.590 24.78083 2348.434 324.9332 2931.196
              WRT      TRA     FIRE      GOV OTH      SUM  FIRE_MAN
    5026 3020.236 2048.335 814.7403 5635.522  NA 22219.39 0.3432200
    5027 3109.522 2065.004 832.4770 5735.623  NA 22532.56 0.3544817

``` r
rm(GGDC10S)
settransformv(GGDC10S, 6:16, `*`, 100 / SUM)
tail(GGDC10S)
```

         Country Regioncode                       Region Variable Year      AGR
    5022     EGY       MENA Middle East and North Africa      EMP 2007 25.45611
    5023     EGY       MENA Middle East and North Africa      EMP 2008 24.83443
    5024     EGY       MENA Middle East and North Africa      EMP 2009 23.86862
    5025     EGY       MENA Middle East and North Africa      EMP 2010 23.64013
    5026     EGY       MENA Middle East and North Africa      EMP 2011 23.33961
    5027     EGY       MENA Middle East and North Africa      EMP 2012 22.90281
               MIN      MAN       PU      CON      WRT      TRA     FIRE      GOV
    5022 0.1634626 12.13530 1.373922 10.49275 13.17196 8.358284 3.507606 25.34061
    5023 0.1519862 11.88280 1.377725 11.29401 13.37793 8.586313 3.560963 24.93383
    5024 0.1397829 11.62389 1.377065 12.17718 13.77724 8.681730 3.588320 24.76618
    5025 0.1316829 11.06068 1.395426 12.41130 13.51989 9.047614 3.638977 25.15430
    5026 0.1240535 10.68352 1.431173 12.58029 13.59279 9.218680 3.666798 25.36308
    5027 0.1099779 10.42240 1.442061 13.00871 13.80013 9.164534 3.694551 25.45482
         OTH SUM
    5022  NA 100
    5023  NA 100
    5024  NA 100
    5025  NA 100
    5026  NA 100
    5027  NA 100

`fcompute` can be used to compute new columns, returning the computed
columns in a new data frame.

``` r
fcompute(GGDC10S, AGR_perc = AGR / SUM * 100, FIRE_MAN = FIRE / MAN) %>% 
  tail(2)
```

         AGR_perc  FIRE_MAN
    5026 23.33961 0.3432200
    5027 22.90281 0.3544817

## Adding and Binding Columns

`add_vars`

``` r
rm(wlddev)
add_vars(wlddev) <- 
  get_vars(wlddev, 9:13) %>% 
  lapply(log10) %>% 
  add_stub("log10.")
```

    Warning in lapply(., log10): NaNs produced

``` r
head(wlddev, 2)
```

          country iso3c       date year decade     region     income  OECD PCGDP
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE    NA
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE    NA
      LIFEEX GINI       ODA     POP log10.PCGDP log10.LIFEEX log10.GINI log10.ODA
    1 32.446   NA 116769997 8996973          NA     1.511161         NA  8.067331
    2 32.962   NA 232080002 9169410          NA     1.518014         NA  8.365638
      log10.POP
    1  6.954096
    2  6.962341

Replace at other positions

``` r
rm(wlddev)
add_vars(wlddev, "front") <- 
  get_vars(wlddev, 9:13) %>% 
  lapply(log10) %>% 
  add_stub("log10.")
```

    Warning in lapply(., log10): NaNs produced

``` r
head(wlddev, 2)
```

      log10.PCGDP log10.LIFEEX log10.GINI log10.ODA log10.POP     country iso3c
    1          NA     1.511161         NA  8.067331  6.954096 Afghanistan   AFG
    2          NA     1.518014         NA  8.365638  6.962341 Afghanistan   AFG
            date year decade     region     income  OECD PCGDP LIFEEX GINI
    1 1961-01-01 1960   1960 South Asia Low income FALSE    NA 32.446   NA
    2 1962-01-01 1961   1960 South Asia Low income FALSE    NA 32.962   NA
            ODA     POP
    1 116769997 8996973
    2 232080002 9169410

``` r
rm(wlddev)

add_vars(wlddev, c(10L, 12L, 14L, 16L, 18L)) <- 
  get_vars(wlddev, 9:13) %>%
  lapply(log10) %>%
  add_stub("log10.")
```

    Warning in lapply(., log10): NaNs produced

``` r
head(wlddev, 2)
```

          country iso3c       date year decade     region     income  OECD PCGDP
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE    NA
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE    NA
      log10.PCGDP LIFEEX log10.LIFEEX GINI log10.GINI       ODA log10.ODA     POP
    1          NA 32.446     1.511161   NA         NA 116769997  8.067331 8996973
    2          NA 32.962     1.518014   NA         NA 232080002  8.365638 9169410
      log10.POP
    1  6.954096
    2  6.962341

Using `add_vars` without replacement.

``` r
rm(wlddev)
add_vars(
  wlddev, 
  get_vars(wlddev, 9:13) %>% lapply(log) %>% add_stub("log."),
  get_vars(wlddev, 9:13) %>% lapply(log10) %>% add_stub("log10.")
) %>% head(2)
```

    Warning in FUN(X[[i]], ...): NaNs produced

    Warning in lapply(., log10): NaNs produced

          country iso3c       date year decade     region     income  OECD PCGDP
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE    NA
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE    NA
      LIFEEX GINI       ODA     POP log.PCGDP log.LIFEEX log.GINI  log.ODA  log.POP
    1 32.446   NA 116769997 8996973        NA   3.479577       NA 18.57572 16.01240
    2 32.962   NA 232080002 9169410        NA   3.495355       NA 19.26259 16.03138
      log10.PCGDP log10.LIFEEX log10.GINI log10.ODA log10.POP
    1          NA     1.511161         NA  8.067331  6.954096
    2          NA     1.518014         NA  8.365638  6.962341

``` r
add_vars(wlddev,
  get_vars(wlddev, 9:13) %>% lapply(log) %>% add_stub("log."),
  get_vars(wlddev, 9:13) %>% lapply(log10) %>% add_stub("log10."),
  pos = c(10L, 13L, 16L, 19L, 22L, 11L, 14L, 17L, 20L, 23L)
) %>% head(2)
```

    Warning in FUN(X[[i]], ...): NaNs produced

    Warning in lapply(., log10): NaNs produced

          country iso3c       date year decade     region     income  OECD PCGDP
    1 Afghanistan   AFG 1961-01-01 1960   1960 South Asia Low income FALSE    NA
    2 Afghanistan   AFG 1962-01-01 1961   1960 South Asia Low income FALSE    NA
      log.PCGDP log10.PCGDP LIFEEX log.LIFEEX log10.LIFEEX GINI log.GINI log10.GINI
    1        NA          NA 32.446   3.479577     1.511161   NA       NA         NA
    2        NA          NA 32.962   3.495355     1.518014   NA       NA         NA
            ODA  log.ODA log10.ODA     POP  log.POP log10.POP
    1 116769997 18.57572  8.067331 8996973 16.01240  6.954096
    2 232080002 19.26259  8.365638 9169410 16.03138  6.962341

``` r
identical(cbind(wlddev, wlddev), add_vars(wlddev, wlddev))
```

    [1] TRUE

``` r
microbenchmark(cbind(wlddev, wlddev), add_vars(wlddev, wlddev))
```

    Unit: microseconds
                         expr    min      lq     mean  median      uq    max neval
        cbind(wlddev, wlddev) 19.846 20.4055 22.02976 20.7535 21.2600 81.567   100
     add_vars(wlddev, wlddev)  4.752  5.0530  5.79536  5.4610  5.8345 23.823   100
     cld
      a 
       b

## Renaming Columns

``` r
GGDC10S %>% 
  frename(AGR = Agriculture, MIN = Mining) %>% 
  head(2)
```

      Country Regioncode             Region Variable Year Agriculture Mining MAN PU
    1     BWA        SSA Sub-saharan Africa       VA 1960          NA     NA  NA NA
    2     BWA        SSA Sub-saharan Africa       VA 1961          NA     NA  NA NA
      CON WRT TRA FIRE GOV OTH SUM
    1  NA  NA  NA   NA  NA  NA  NA
    2  NA  NA  NA   NA  NA  NA  NA

``` r
frename(GGDC10S, tolower) %>% head(2)
```

      country regioncode             region variable year agr min man pu con wrt
    1     BWA        SSA Sub-saharan Africa       VA 1960  NA  NA  NA NA  NA  NA
    2     BWA        SSA Sub-saharan Africa       VA 1961  NA  NA  NA NA  NA  NA
      tra fire gov oth sum
    1  NA   NA  NA  NA  NA
    2  NA   NA  NA  NA  NA

``` r
frename(GGDC10S, tolower, cols = .c(AGR, MIN)) %>% head(2)
```

      Country Regioncode             Region Variable Year agr min MAN PU CON WRT
    1     BWA        SSA Sub-saharan Africa       VA 1960  NA  NA  NA NA  NA  NA
    2     BWA        SSA Sub-saharan Africa       VA 1961  NA  NA  NA NA  NA  NA
      TRA FIRE GOV OTH SUM
    1  NA   NA  NA  NA  NA
    2  NA   NA  NA  NA  NA

Rename by reference

``` r
setrename(GGDC10S, AGR = Agriculture, MIN = Mining)
head(GGDC10S, 2)
```

      Country Regioncode             Region Variable Year Agriculture Mining MAN PU
    1     BWA        SSA Sub-saharan Africa       VA 1960          NA     NA  NA NA
    2     BWA        SSA Sub-saharan Africa       VA 1961          NA     NA  NA NA
      CON WRT TRA FIRE GOV OTH SUM
    1  NA  NA  NA   NA  NA  NA  NA
    2  NA  NA  NA   NA  NA  NA  NA

``` r
rm(GGDC10S)
```

## Shortcuts

Only recommended for personal scripts

- `fselect` -\> `slt`
- `fsubset` -\> `sbt`
- `ftransform(v)` -\> `tfm(v)`
- `settransform(v)` -\> `settfm(v)`
- `get_vars -> gv`
- `num_vars -> nv`
- `add_vars` -\> `av`.

## Missing Values/Rows

``` r
microbenchmark(
  na_omit(wlddev, na.attr = TRUE), 
  na.omit(wlddev))
```

    Unit: microseconds
                                expr     min      lq     mean  median       uq
     na_omit(wlddev, na.attr = TRUE) 134.076 139.501 177.4406 144.782 161.2885
                     na.omit(wlddev) 624.750 649.072 881.0346 668.485 756.2560
          max neval cld
     2439.207   100  a 
     3685.360   100   b

Act on certain columns only

``` r
na_omit(wlddev, cols = .c(PCGDP, LIFEEX)) %>% 
  head(2)
```

          country iso3c       date year decade     region     income  OECD    PCGDP
    1 Afghanistan   AFG 2003-01-01 2002   2000 South Asia Low income FALSE 330.3036
    2 Afghanistan   AFG 2004-01-01 2003   2000 South Asia Low income FALSE 343.0809
      LIFEEX GINI        ODA      POP
    1 56.784   NA 1790479980 22600770
    2 57.271   NA 1972890015 23680871

``` r
na_omit(wlddev, cols = is.numeric) %>% head(2)
```

      country iso3c       date year decade                region
    1 Albania   ALB 1997-01-01 1996   1990 Europe & Central Asia
    2 Albania   ALB 2003-01-01 2002   2000 Europe & Central Asia
                   income  OECD    PCGDP LIFEEX GINI       ODA     POP
    1 Upper middle income FALSE 1869.866 72.495 27.0 294089996 3168033
    2 Upper middle income FALSE 2572.721 74.579 31.7 453309998 3051010

For atomic vectors the function `na_rm` also exists which is 2x faster
than `x[!is.na(x)]`. Both `na_omit` and `na_rm` return their argument if
no missing cases were found.

The existence of missing cases can be checked using `missing_cases`,
which is also considerably faster than `complete.cases` for data frames.

There is also a function `na_insert` to randomly insert missing values
into vectors, matrices and data frames. The default is
`na_insert(X, prop = 0.1)` so that 10% of values are randomly set to
missing.

Finally, a function `allNA` provides the much needed opposite of anyNA
for atomic vectors.

## Unique Values / Rows

``` r
funique(GGDC10S$Variable, sort = T)
```

    [1] "EMP" "VA" 
    attr(,"label")
    [1] "Variable"
    attr(,"format.stata")
    [1] "%9s"

If all values/rows are unique, the original data is returned

``` r
identical(funique(GGDC10S), GGDC10S)
```

    [1] TRUE

Remove duplicate rows

``` r
funique(GGDC10S, cols = .c(Country, Variable)) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode             Region Variable Year AGR MIN MAN
    1     BWA        SSA Sub-saharan Africa       VA 1960  NA  NA  NA
    2     BWA        SSA Sub-saharan Africa      EMP 1960  NA  NA  NA

``` r
funique(GGDC10S, cols = c("Country", "Variable")) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode             Region Variable Year AGR MIN MAN
    1     BWA        SSA Sub-saharan Africa       VA 1960  NA  NA  NA
    2     BWA        SSA Sub-saharan Africa      EMP 1960  NA  NA  NA

``` r
funique(GGDC10S, cols = .c(Country, Variable), sort = T) %>% 
  ss(1:2, 1:8)
```

      Country Regioncode        Region Variable Year          AGR      MIN
    1     ARG        LAM Latin America      EMP 1950 1.799565e+03 32.71936
    2     ARG        LAM Latin America       VA 1950 5.887857e-07  0.00000
               MAN
    1 1.603249e+03
    2 3.534430e-06

## Recoding and Replacing

- `recode_num`
- `recode_char`
- `replace_NA`
- `replace_Inf`
- `replace_outliers`

``` r
microbenchmark(replace_NA(GGDC10S, 0))
```

    Unit: microseconds
                       expr    min     lq     mean median       uq      max neval
     replace_NA(GGDC10S, 0) 93.722 99.238 163.2147 106.02 226.3955 2472.767   100

``` r
add_vars(GGDC10S, 6:16*2-5) <- 
  fselect(GGDC10S, AGR:SUM) %>% 
  lapply(log) %>% 
  replace_Inf() %>% 
  add_stub("log.")
```

    Warning in FUN(X[[i]], ...): NaNs produced

``` r
head(GGDC10S, 2)
```

      Country Regioncode             Region Variable Year AGR log.AGR MIN log.MIN
    1     BWA        SSA Sub-saharan Africa       VA 1960  NA      NA  NA      NA
    2     BWA        SSA Sub-saharan Africa       VA 1961  NA      NA  NA      NA
      MAN log.MAN PU log.PU CON log.CON WRT log.WRT TRA log.TRA FIRE log.FIRE GOV
    1  NA      NA NA     NA  NA      NA  NA      NA  NA      NA   NA       NA  NA
    2  NA      NA NA     NA  NA      NA  NA      NA  NA      NA   NA       NA  NA
      log.GOV OTH log.OTH SUM log.SUM
    1      NA  NA      NA  NA      NA
    2      NA  NA      NA  NA      NA

``` r
rm(GGDC10S)
```

``` r
recode_char(month.name,
            ber = "C", "^J" = "A", default = "B",
            regex = TRUE)
```

     [1] "A" "B" "B" "B" "B" "A" "A" "B" "C" "C" "C" "C"

`replace_outliers` replaces values falling outside a 1- or 2-sided
numeric threshold or outside a certain number of column- standard
deviations with a value (default is NA).

Replace all values below 2 and above 100 with NA

``` r
replace_outliers(mtcars, c(2, 100)) %>% 
  head(3)
```

                   mpg cyl disp hp drat    wt  qsec vs am gear carb
    Mazda RX4     21.0   6   NA NA 3.90 2.620 16.46 NA NA    4    4
    Mazda RX4 Wag 21.0   6   NA NA 3.90 2.875 17.02 NA NA    4    4
    Datsun 710    22.8   4   NA 93 3.85 2.320 18.61 NA NA    4   NA

Replace only values smaller than 2

``` r
replace_outliers(mtcars, 2, single.limit = "min") %>% 
  head(3)
```

                   mpg cyl disp  hp drat    wt  qsec vs am gear carb
    Mazda RX4     21.0   6  160 110 3.90 2.620 16.46 NA NA    4    4
    Mazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02 NA NA    4    4
    Datsun 710    22.8   4  108  93 3.85 2.320 18.61 NA NA    4   NA

Replace only values larger than 100

``` r
replace_outliers(mtcars, 100, single.limit = "max") %>% 
  head(3)
```

                   mpg cyl disp hp drat    wt  qsec vs am gear carb
    Mazda RX4     21.0   6   NA NA 3.90 2.620 16.46  0  1    4    4
    Mazda RX4 Wag 21.0   6   NA NA 3.90 2.875 17.02  0  1    4    4
    Datsun 710    22.8   4   NA 93 3.85 2.320 18.61  1  1    4    1

Replace values above or below 3 column-standard-deviations with NA

``` r
replace_outliers(mtcars, 3) %>% tail(3)
```

                   mpg cyl disp  hp drat   wt qsec vs am gear carb
    Ferrari Dino  19.7   6  145 175 3.62 2.77 15.5  0  1    5    6
    Maserati Bora 15.0   8  301 335 3.54 3.57 14.6  0  1    5   NA
    Volvo 142E    21.4   4  121 109 4.11 2.78 18.6  1  1    4    2

# Collapse Advanced Data Aggregation


[Source](https://fastverse.org/collapse/articles/collapse_intro.html)

``` r
library(collapse)
library(magrittr)
library(microbenchmark)
options(paged.print = FALSE)
```

`collap`

``` r
weights <- abs(rnorm(fnrow(mtcars)))
collap(mtcars,
       mpg + disp ~ cyl + vs + am,
       list(fmean, fsd, fmin, fmax),
       w = weights, keep.col.order = F)
```

    Warning in unused_arg_action(match.call(), ...): Unused argument (w = w) passed
    to fmin.data.frame

    Warning in unused_arg_action(match.call(), ...): Unused argument (w = w) passed
    to fmax.data.frame

      cyl vs am   weights fmean.mpg fmean.disp   fsd.mpg fsd.disp fmin.mpg
    1   4  0  1 0.9535433  26.00000  120.30000 0.0000000  0.00000     26.0
    2   4  1  0 0.6406224  22.68508  137.04235        NA       NA     21.5
    3   4  1  1 5.8707312  27.54623   93.88374 5.0568534 20.23326     21.4
    4   6  0  1 1.8912799  20.51623  154.41799 0.9153714 10.56198     19.7
    5   6  1  0 3.0580192  19.69101  203.54859 1.7181109 52.77776     17.8
    6   8  0  0 8.3754314  15.18665  365.09143 2.2826361 60.21489     10.4
    7   8  0  1 0.6307238  15.24643  316.40193        NA       NA     15.0
      fmin.disp fmax.mpg fmax.disp
    1     120.3     26.0     120.3
    2     120.1     24.4     146.7
    3      71.1     33.9     121.0
    4     145.0     21.0     160.0
    5     167.6     21.4     258.0
    6     275.8     19.2     472.0
    7     301.0     15.8     351.0

Suppose we would like to aggregate `wlddev` data by country and decade,
but keep all that categorical information.

``` r
collap(wlddev, ~ iso3c + decade) %>% head()
```

      country iso3c       date   year decade                    region      income
    1   Aruba   ABW 1961-01-01 1964.5   1960 Latin America & Caribbean High income
    2   Aruba   ABW 1971-01-01 1974.5   1970 Latin America & Caribbean High income
    3   Aruba   ABW 1981-01-01 1984.5   1980 Latin America & Caribbean High income
    4   Aruba   ABW 1991-01-01 1994.5   1990 Latin America & Caribbean High income
    5   Aruba   ABW 2001-01-01 2004.5   2000 Latin America & Caribbean High income
    6   Aruba   ABW 2011-01-01 2014.5   2010 Latin America & Caribbean High income
       OECD    PCGDP  LIFEEX GINI      ODA      POP
    1 FALSE       NA 67.2592   NA       NA  56984.3
    2 FALSE       NA 70.6372   NA       NA  60080.6
    3 FALSE 20267.30 73.0153   NA 49745999  61665.9
    4 FALSE 26611.44 73.6069   NA 29971000  76946.7
    5 FALSE 26664.99 74.2660   NA 23292000  97939.7
    6 FALSE 24926.17 75.6546   NA       NA 103994.6

`collap` syntax.

``` r
collap(X, by, 
       FUN = fmean, catFUN = fmode, 
       cols = NULL, 
       w = NULL, wFUN = fsum,
       custom = NULL, 
       keep.by = TRUE, keep.w = TRUE, keep.col.order = TRUE,
       sort.row = TRUE, 
       parallel = FALSE, mc.cores = 1L,
       return = c("wide","list","long","long_dupl"), 
       give.names = "auto") # , ...
```

Suppose we only want to aggregate 4 series in this dataset.

``` r
collap(wlddev,
       PCGDP + LIFEEX + GINI + ODA ~ iso3c + decade) %>% 
  head()
```

      iso3c decade    PCGDP  LIFEEX GINI      ODA
    1   ABW   1960       NA 67.2592   NA       NA
    2   ABW   1970       NA 70.6372   NA       NA
    3   ABW   1980 20267.30 73.0153   NA 49745999
    4   ABW   1990 26611.44 73.6069   NA 29971000
    5   ABW   2000 26664.99 74.2660   NA 23292000
    6   ABW   2010 24926.17 75.6546   NA       NA

``` r
collap(wlddev, 
       ~ iso3c + decade, cols = 9:12) %>% 
  head()
```

      iso3c decade    PCGDP  LIFEEX GINI      ODA
    1   ABW   1960       NA 67.2592   NA       NA
    2   ABW   1970       NA 70.6372   NA       NA
    3   ABW   1980 20267.30 73.0153   NA 49745999
    4   ABW   1990 26611.44 73.6069   NA 29971000
    5   ABW   2000 26664.99 74.2660   NA 23292000
    6   ABW   2010 24926.17 75.6546   NA       NA

Using multiple functions

``` r
collap(wlddev,
       ~ iso3c + decade,
       list(fmean, fmedian, fsd),
       cols = 9:12) %>% 
  head()
```

      iso3c decade fmean.PCGDP fmedian.PCGDP fsd.PCGDP fmean.LIFEEX fmedian.LIFEEX
    1   ABW   1960          NA            NA        NA      67.2592        67.2740
    2   ABW   1970          NA            NA        NA      70.6372        70.6760
    3   ABW   1980    20267.30      20280.81 4037.2695      73.0153        73.1260
    4   ABW   1990    26611.44      26684.19  592.7919      73.6069        73.6100
    5   ABW   2000    26664.99      26992.71 1164.6741      74.2660        74.2215
    6   ABW   2010    24926.17      24599.50 1159.7344      75.6546        75.6540
      fsd.LIFEEX fmean.GINI fmedian.GINI fsd.GINI fmean.ODA fmedian.ODA  fsd.ODA
    1 1.03046880         NA           NA       NA        NA          NA       NA
    2 0.96813702         NA           NA       NA        NA          NA       NA
    3 0.38203753         NA           NA       NA  49745999    39259998 23573651
    4 0.08549392         NA           NA       NA  29971000    35155001 17270808
    5 0.37614448         NA           NA       NA  23292000    16219999 42969712
    6 0.42974339         NA           NA       NA        NA          NA       NA

Return long-format data

``` r
collap(wlddev,
       ~ iso3c + decade,
       list(fmean, fmedian, fsd),
       cols = 9:12,
       return = "long") %>% 
  head()
```

      Function iso3c decade    PCGDP  LIFEEX GINI      ODA
    1    fmean   ABW   1960       NA 67.2592   NA       NA
    2    fmean   ABW   1970       NA 70.6372   NA       NA
    3    fmean   ABW   1980 20267.30 73.0153   NA 49745999
    4    fmean   ABW   1990 26611.44 73.6069   NA 29971000
    5    fmean   ABW   2000 26664.99 74.2660   NA 23292000
    6    fmean   ABW   2010 24926.17 75.6546   NA       NA

The `custom` argument allows the user to circumvent the broad
distinction into numeric and categorical data (and the associated `FUN`
and `catFUN` arguments) and specify exactly which columns to aggregate
using which functions.

``` r
collap(wlddev,
       ~ iso3c + decade,
       custom = list(
         fmean = 9:10, fmedian = 11:12,
         ffirst = c("country", "region", "income"),
         flast = c("year", "date"),
         fmode = "OECD"
       )) %>% 
  head()
```

      country iso3c       date year decade                    region      income
    1   Aruba   ABW 1970-01-01 1969   1960 Latin America & Caribbean High income
    2   Aruba   ABW 1980-01-01 1979   1970 Latin America & Caribbean High income
    3   Aruba   ABW 1990-01-01 1989   1980 Latin America & Caribbean High income
    4   Aruba   ABW 2000-01-01 1999   1990 Latin America & Caribbean High income
    5   Aruba   ABW 2010-01-01 2009   2000 Latin America & Caribbean High income
    6   Aruba   ABW 2020-01-01 2019   2010 Latin America & Caribbean High income
       OECD    PCGDP  LIFEEX GINI      ODA
    1 FALSE       NA 67.2592   NA       NA
    2 FALSE       NA 70.6372   NA       NA
    3 FALSE 20267.30 73.0153   NA 39259998
    4 FALSE 26611.44 73.6069   NA 35155001
    5 FALSE 26664.99 74.2660   NA 16219999
    6 FALSE 24926.17 75.6546   NA       NA

It is also possible to perform weighted aggregations and append
functions with \_uw to yield an unweighted computation.

``` r
collap(wlddev,
       ~ region + year,
       w = ~ POP,
       custom = list(
         fmean = 9:10, fmedian_uw = 11:12,
         ffirst_uw = c("country", "region", "income"),
         flast_uw = c("year", "date"),
         fmode = "OECD"
       ),
       keep.w = FALSE) %>% 
  head()
```

             country       date year year              region              region
    1 American Samoa 1961-01-01 1960 1960 East Asia & Pacific East Asia & Pacific
    2 American Samoa 1962-01-01 1961 1961 East Asia & Pacific East Asia & Pacific
    3 American Samoa 1963-01-01 1962 1962 East Asia & Pacific East Asia & Pacific
    4 American Samoa 1964-01-01 1963 1963 East Asia & Pacific East Asia & Pacific
    5 American Samoa 1965-01-01 1964 1964 East Asia & Pacific East Asia & Pacific
    6 American Samoa 1966-01-01 1965 1965 East Asia & Pacific East Asia & Pacific
                   income  OECD    PCGDP   LIFEEX GINI       ODA
    1 Upper middle income FALSE 1313.760 48.20996   NA  37295000
    2 Upper middle income FALSE 1395.228 48.73451   NA  26630001
    3 Upper middle income FALSE 1463.441 49.39960   NA 100040001
    4 Upper middle income FALSE 1540.621 50.37529   NA  40389999
    5 Upper middle income FALSE 1665.385 51.57330   NA  70059998
    6 Upper middle income FALSE 1733.757 52.94426   NA  91545002

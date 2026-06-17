# Collapse Data Object Conversions


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
library(microbenchmark)
```

`collapse` provides a set of functions to speed these conversions

- `qDF` - convert to data.frame
- `qDT` - convert to data.table
- `qTBL` - convert to tibble
- `qM` - converts vectors, higher-dim arrays, data frames, and suitable
  lists to matrix
- `qF` - convert vector to factor
- `mrtl` - row-wise convert a matrix into list, data.frame or data.table
- `mctl` - column-wise convert a matrix into list, data.frame or
  data.table

``` r
str(EuStockMarkets)
```

     Time-Series [1:1860, 1:4] from 1991 to 1999: 1629 1614 1607 1621 1618 ...
     - attr(*, "dimnames")=List of 2
      ..$ : NULL
      ..$ : chr [1:4] "DAX" "SMI" "CAC" "FTSE"

``` r
microbenchmark(
  qDT(wlddev),
  qDT(EuStockMarkets),
  data.table::as.data.table(wlddev),
  as.data.frame(EuStockMarkets)
)
```

    Unit: microseconds
                                  expr     min       lq      mean   median       uq
                           qDT(wlddev)   4.598   5.3175   6.99197   5.8485   7.7170
                   qDT(EuStockMarkets)   9.057  10.6565  19.91619  14.3740  23.3460
     data.table::as.data.table(wlddev) 108.021 115.4695 618.86024 166.6970 351.5195
         as.data.frame(EuStockMarkets)  81.001  94.3870 121.31982 110.6760 137.7885
           max neval cld
        20.370   100   a
       242.345   100   a
     34495.091   100   a
       466.876   100   a

By default these functions drop all unnecessary attributes from matrices
or lists / data frames in the conversion, but this can be changed using
the keep.attr = TRUE argument.

`row.names.col` saves names/row names in a column.

``` r
head(qDT(mtcars, "car"))
```

                     car   mpg   cyl  disp    hp  drat    wt  qsec    vs    am
                  <char> <num> <num> <num> <num> <num> <num> <num> <num> <num>
    1:         Mazda RX4  21.0     6   160   110  3.90 2.620 16.46     0     1
    2:     Mazda RX4 Wag  21.0     6   160   110  3.90 2.875 17.02     0     1
    3:        Datsun 710  22.8     4   108    93  3.85 2.320 18.61     1     1
    4:    Hornet 4 Drive  21.4     6   258   110  3.08 3.215 19.44     1     0
    5: Hornet Sportabout  18.7     8   360   175  3.15 3.440 17.02     0     0
    6:           Valiant  18.1     6   225   105  2.76 3.460 20.22     1     0
        gear  carb
       <num> <num>
    1:     4     4
    2:     4     4
    3:     4     1
    4:     3     1
    5:     3     2
    6:     3     1

``` r
(N_distinct <- fndistinct(GGDC10S))
```

       Country Regioncode     Region   Variable       Year        AGR        MIN 
            43          6          6          2         67       4353       4224 
           MAN         PU        CON        WRT        TRA       FIRE        GOV 
          4353       4237       4339       4344       4334       4349       3470 
           OTH        SUM 
          4238       4364 

Convert to data frame, preserving names

``` r
head(qDF(N_distinct, "variable"))
```

        variable N_distinct
    1    Country         43
    2 Regioncode          6
    3     Region          6
    4   Variable          2
    5       Year         67
    6        AGR       4353

This converts the matrix to a list of 1860 row-vectors of length 4.

``` r
microbenchmark(mrtl(EuStockMarkets))
```

    Unit: microseconds
                     expr     min      lq     mean median       uq     max neval
     mrtl(EuStockMarkets) 134.107 138.164 145.9075 141.11 143.7275 302.299   100

``` r
mrtl(EuStockMarkets) %>% head()
```

    [[1]]
    [1] 1628.75 1678.10 1772.80 2443.60

    [[2]]
    [1] 1613.63 1688.50 1750.50 2460.20

    [[3]]
    [1] 1606.51 1678.60 1718.00 2448.20

    [[4]]
    [1] 1621.04 1684.10 1708.10 2470.40

    [[5]]
    [1] 1618.16 1686.60 1723.10 2484.70

    [[6]]
    [1] 1610.61 1671.60 1714.30 2466.80

``` r
microbenchmark(rowSums(qM(mtcars)), 
               rowSums(mtcars),
               kit::psum(mtcars))
```

    Unit: microseconds
                    expr    min      lq     mean  median      uq      max neval cld
     rowSums(qM(mtcars))  8.459  9.3045 12.77335  9.7830 10.5500  223.680   100   a
         rowSums(mtcars) 45.149 47.4465 52.48091 52.2510 54.0470   91.158   100   a
       kit::psum(mtcars)  1.150  1.3940 60.79812  1.5595  1.7415 5917.109   100   a

Factor From Character

``` r
str(wlddev$country)
```

     chr [1:13176] "Afghanistan" "Afghanistan" "Afghanistan" "Afghanistan" ...
     - attr(*, "label")= chr "Country Name"

``` r
fndistinct(wlddev$country)
```

    [1] 216

``` r
microbenchmark(
  qF(wlddev$country),
  as.factor(wlddev$country)
)
```

    Unit: microseconds
                          expr     min       lq      mean   median       uq
            qF(wlddev$country)  85.177  89.3970  98.14828  93.6905 100.5280
     as.factor(wlddev$country) 237.437 282.5845 325.44023 300.4750 324.2805
          max neval cld
      350.815   100  a 
     2855.076   100   b

Factor from numeric

``` r
fndistinct(wlddev$PCGDP)
```

    [1] 9470

``` r
microbenchmark(
  qF(wlddev$PCGDP),
  as.factor(wlddev$PCGDP)
)
```

    Unit: microseconds
                        expr       min         lq       mean     median         uq
            qF(wlddev$PCGDP)   524.907   570.4885   616.7583   586.9485   607.7885
     as.factor(wlddev$PCGDP) 13095.541 13564.7005 13786.4306 13642.2010 13726.1990
           max neval cld
      3118.401   100  a 
     16452.615   100   b

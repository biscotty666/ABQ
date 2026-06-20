# Efficient Coding with Collapse


[Source](https://fastverse.org/collapse/articles/developing_with_collapse.html)

``` r
library(collapse)
library(magrittr)
library(microbenchmark)
options(paged.print = FALSE)
```

# Be Minimalistic in Computations

A key for very efficient code is to use the minimal required
operations/objects to get the job done.

Eg, if a grouping vector `g` is used only once, use internal grouping
instead.

``` r
fmean(mtcars$mpg, mtcars$cyl)
```

           4        6        8 
    26.66364 19.74286 15.10000 

``` r
fmean(mtcars$mpg, mtcars$cyl, TRA = "fill")
```

     [1] 19.74286 19.74286 26.66364 19.74286 15.10000 19.74286 15.10000 26.66364
     [9] 26.66364 19.74286 19.74286 15.10000 15.10000 15.10000 15.10000 15.10000
    [17] 15.10000 26.66364 26.66364 26.66364 26.66364 15.10000 15.10000 15.10000
    [25] 15.10000 26.66364 26.66364 26.66364 15.10000 19.74286 15.10000 26.66364

For aggregation, use unsorted grouping, eg.

`fsum(x, qF(g, sort = FALSE))` or
`fsum(x, qG(g, sort = FALSE), use.g.names = FALSE)` if group names
aren’t needed. `na.exclude = FALSE` should be used with `qF()` and
`qG()`.

If `g` is a plain vector of the first-appearance order should be
preserved, use `group(g)` instead of
`qG(g, sort = FALSE, na.exclude = FALSE)`. Set `use.g.names = FALSE` and
`na.rm = FALSE` when possible.

``` r
x <- rnorm(1e7) # 10 million random obs
g <- sample.int(1e6, 1e7, TRUE) # 1 Million random groups
oldopts <- set_collapse(na.rm = FALSE)
microbenchmark(
  internal = fsum(x, g),
  internal_expand = fsum(x, g, TRA = "fill"),
  qF1 = fsum(x, qF(g, sort = FALSE)),
  qF2 = fsum(x, qF(g, sort = FALSE, na.exclude = FALSE)),
  qG1 = fsum(x, qG(g, sort = FALSE), use = FALSE),
  qG2 = fsum(x, qG(g, sort = FALSE, na.exclude = FALSE), use = FALSE),
  group = fsum(x, group(g), use = FALSE), # Same as above basically
  GRP1 = fsum(x, GRP(g)), 
  GRP2 = fsum(x, GRP(g, sort = FALSE)), 
  GRP3 = fsum(x, GRP(g, sort = FALSE, return.groups = FALSE), use = FALSE)
)
```

    Unit: milliseconds
                expr      min       lq     mean   median       uq      max neval
            internal 252.5567 268.3194 275.9666 273.1149 278.6138 327.8448   100
     internal_expand 221.2034 232.6619 240.5698 237.6850 243.9592 297.1555   100
                 qF1 215.5034 224.7344 231.1038 228.9465 234.8712 289.4238   100
                 qF2 208.8619 212.6853 219.2239 216.0958 220.3175 271.0369   100
                 qG1 201.5905 216.3092 223.2799 220.3101 227.5807 285.4409   100
                 qG2 182.3801 192.2435 198.0198 194.9051 201.6197 242.1236   100
               group 185.9109 191.1733 197.3334 194.2156 200.1651 255.4992   100
                GRP1 257.3980 270.6520 278.9773 275.9478 283.6507 328.8341   100
                GRP2 222.4485 230.8127 238.7077 235.6359 242.7458 290.4961   100
                GRP3 199.4399 208.7145 214.1275 211.8774 215.9920 273.7072   100
        cld
     a     
      b    
       c   
        de 
        d  
          f
          f
     a     
      b    
         e 

Factors and ‘qG’ objects are efficient inputs to all
statistical/transformation functions except for - `fmedian()`, `fnth()`,
`fmode()`, `fndistinct()` - split-apply-combine operations using
`BY()`/`gsplit()`

For these, great a `GRP` object. Set `sort = FALSE` and
`return.groups = FALSE` if not needed.

``` r
f <- qF(g); f2 <- qF(g, na.exclude = F)
gg <- group(g) # Same as qG(g, sort = FALSE, na.exclude = FALSE)
grp <- GRP(g)
microbenchmark(
  factor = fsum(x, f),
  factor_nona = fsum(x, f2),
  qG_nona = fsum(x, gg),
  qG_nona_nonam = fsum(x, gg, use = FALSE),
  GRP = fsum(x, grp),
  GRP_nonam = fsum(x, grp, use = FALSE)
)
```

    Unit: milliseconds
              expr      min       lq     mean   median       uq       max neval cld
            factor 25.17722 27.76313 29.05794 29.10724 30.07568  32.91493   100 a  
       factor_nona 21.35778 23.15536 25.04051 24.49783 26.25833  41.97280   100 ab 
           qG_nona 21.74766 24.70078 40.29200 33.03158 37.35035 126.34572   100   c
     qG_nona_nonam 19.96116 21.92119 23.33077 22.81042 24.86479  38.32688   100  b 
               GRP 20.94141 23.61620 25.20861 25.04081 25.94340  43.17080   100 ab 
         GRP_nonam 20.75716 24.11406 25.39448 25.32505 26.56817  30.88301   100 ab 

`qF()`/`qG()` are a bit smarter than `group()` when it comes to handling
input factors/‘qG’ objects because `group()` hashes every vector:

``` r
microbenchmark(
  factor_factor = qF(f),
  # This checks NA's and adds 'na.included' class -> full deep copy
  factor_factor2 = qF(f, na.exclude = FALSE), 
  # NA checking costs.. incurred in fsum() and friends
  check_na = collapse:::is.nmfactor(f), 
  check_na2 = collapse:::is.nmfactor(f2),
  factor_qG = qF(gg),
  qG_factor = qG(f),
  qG_qG = qG(gg),
  group_factor = group(f),
  group_qG = group(gg)
)
```

    Unit: nanoseconds
               expr      min         lq        mean     median         uq      max
      factor_factor     1665     7624.0    11479.84    11359.5    17102.5    21422
     factor_factor2 16236190 17001341.5 19537383.27 17267922.0 17741931.5 41276980
           check_na  3893498  4028482.5  4105729.68  4092437.5  4151495.0  4654683
          check_na2      498     3938.0     5597.44     5335.0     8263.5    11629
          factor_qG     3562    15719.0    21728.06    23697.0    31107.5    49656
          qG_factor     2604     6162.5    16538.87    16526.0    23620.5   136081
              qG_qG     2031     3637.0    10999.10    11337.5    17004.0    26291
       group_factor 30601820 31761006.5 34552554.18 32240569.5 33284816.5 57768072
           group_qG 29227121 30032996.5 32407889.01 30604019.5 31115008.0 55130697
     neval   cld
       100 a    
       100  b   
       100   c  
       100 a    
       100 a    
       100 a    
       100 a    
       100    d 
       100     e

Only in rare cases are grouped/indexed data frames created with
fgroup_by()/findex_by() needed in package code. Likewise, functions like
fsummarise()/fmutate() are essentially wrappers.

``` r
mtcars %>% 
  fgroup_by(cyl, vs, am) %>% 
  fsummarise(mpg = fsum(mpg),
             across(c(carb, hp, qsec), fmean))
```

      cyl vs am   mpg     carb        hp     qsec
    1   4  0  1  26.0 2.000000  91.00000 16.70000
    2   4  1  0  68.7 1.666667  84.66667 20.97000
    3   4  1  1 198.6 1.428571  80.57143 18.70000
    4   6  0  1  61.7 4.666667 131.66667 16.32667
    5   6  1  0  76.5 2.500000 115.25000 19.21500
    6   8  0  0 180.6 3.083333 194.16667 17.14250
    7   8  0  1  30.8 6.000000 299.50000 14.55000

is the same as

``` r
g <- GRP(mtcars, c("cyl", "vs", "am"))

add_vars(g$groups,
         get_vars(mtcars, "mpg") %>% 
           fsum(g, use = FALSE),
         get_vars(mtcars, c("carb", "hp", "qsec")) %>% 
           fmean(g, use = FALSE))
```

      cyl vs am   mpg     carb        hp     qsec
    1   4  0  1  26.0 2.000000  91.00000 16.70000
    2   4  1  0  68.7 1.666667  84.66667 20.97000
    3   4  1  1 198.6 1.428571  80.57143 18.70000
    4   6  0  1  61.7 4.666667 131.66667 16.32667
    5   6  1  0  76.5 2.500000 115.25000 19.21500
    6   8  0  0 180.6 3.083333 194.16667 17.14250
    7   8  0  1  30.8 6.000000 299.50000 14.55000

``` r
microbenchmark(
  fgroup = mtcars %>%
    fgroup_by(cyl, vs, am) %>%
    fsummarise(
      mpg = fsum(mpg),
      across(c(carb, hp, qsec), fmean)
    ),
  addvar = add_vars(
    g$groups,
    get_vars(mtcars, "mpg") %>%
      fsum(g, use = FALSE),
    get_vars(mtcars, c("carb", "hp", "qsec")) %>%
      fmean(g, use = FALSE)
  )
)
```

    Unit: microseconds
       expr    min      lq     mean  median      uq     max neval cld
     fgroup 76.271 79.4035 84.36616 81.1195 84.3605 245.117   100  a 
     addvar 27.095 28.5455 30.99731 30.3585 31.7800  61.868   100   b

# Memory

`x[x == 0] <- NA` creates a logical vector of 1 million elements.
`setv(x, 0, NA)` is the efficient equivalent.

``` r
x <- abs(round(rnorm(1e6)))
y <- abs(round(rnorm(1e6)))
microbenchmark(
  lvec = x[x == 0] <- NA,
  coll = setv(y, 0, NA)
)
```

    Unit: milliseconds
     expr      min       lq     mean   median       uq       max neval cld
     lvec 5.115598 7.883423 8.484082 8.748967 8.951635 10.420504   100  a 
     coll 3.624822 3.772980 3.859174 3.850804 3.920139  4.382493   100   b

``` r
x1 <- abs(round(rnorm(1e6)))
x2 <- abs(round(rnorm(1e6)))
y <- rnorm(1e6)
microbenchmark(
  lvec = x1[is.na(x1)] <- y[is.na(x1)],
  coll = setv(x2, NA, y)
)
```

    Unit: microseconds
     expr      min        lq      mean    median       uq      max neval cld
     lvec 2503.824 3709.0475 4925.1346 5422.5630 5601.546 7315.317   100  a 
     coll  378.269  504.2515  524.0066  525.9705  557.720  756.064   100   b

Logical vectors are inefficient compared to indices.

``` r
xNA <- na_insert(x, prop = 0.4)
xmiss <- is.na(xNA)
ind <- which(xmiss)
microbenchmark(x[xmiss], x[ind])
```

    Unit: milliseconds
         expr      min       lq     mean   median       uq      max neval cld
     x[xmiss] 3.637865 3.943257 4.725287 4.141688 6.037301 6.287750   100  a 
       x[ind] 1.156111 1.247508 1.611913 1.307578 2.213867 2.905631   100   b

With `collapse`, they can be created directly using `whichNA(xNA)` in
this case, or `whichv(x, 0)` for `which(x == 0)` or any other number.
Also here there exist an `invert = TRUE` argument covering the `!=`
case. For convenience, infix operators `x %==% 0` and `x %!=% 0` wrap
`whichv(x, 0)` and `whichv(x, 0, invert = TRUE)`, respectively.

Use %iin% instead of %in%.

``` r
microbenchmark(
  `%in%` = fsubset(wlddev, iso3c %in% c("USA", "DEU", "ITA", "GBR")),
  `%iin%` = fsubset(wlddev, iso3c %iin% c("USA", "DEU", "ITA", "GBR"))
)
```

    Unit: microseconds
      expr     min       lq      mean   median      uq      max neval cld
      %in% 138.378 142.6975 155.98300 146.2815 160.265  202.131   100   a
     %iin%  20.328  21.3990  71.21426  22.1015  24.208 4722.264   100   a

`anyNA()`, `allNA()`, `anyv()` and `allv()` are faster than, eg,
`any(x == 0)` `na_rm(x)` is faster than `x[!is.na(x)]`.

With `ss()`, index checks can be avoided using `check = FALSE`.

``` r
ind <- wlddev$iso3c %!iin% c("USA", "DEU", "ITA", "GBR")
microbenchmark::microbenchmark(
  withcheck = ss(wlddev, ind),
  nocheck = ss(wlddev, ind, check = FALSE)
)
```

    Unit: microseconds
          expr     min       lq     mean   median      uq     max neval cld
     withcheck 101.606 269.5335 269.6351 289.9035 293.506 488.354   100   a
       nocheck  99.283 256.1305 250.7785 277.1575 285.514 466.074   100   a

Inefficiencies can come from copies produced in statistical operations.

``` r
x <- rnorm(100); y <- rnorm(100); z <- rnorm(100)
```

This produces 2 copies

``` r
res <- x + y + z
```

Instead, from `kit`, use `psum(x, y, z)` or

``` r
res <- x + y
res %+=% z
```

For operations between vectors and rows, use `rowwise` argument.

``` r
m <- qM(mtcars)
setop(m, "*", seq_col(m), rowwise = T)
head(m / qM(mtcars))
```

                      mpg cyl disp hp drat wt qsec  vs  am gear carb
    Mazda RX4           1   2    3  4    5  6    7 NaN   9   10   11
    Mazda RX4 Wag       1   2    3  4    5  6    7 NaN   9   10   11
    Datsun 710          1   2    3  4    5  6    7   8   9   10   11
    Hornet 4 Drive      1   2    3  4    5  6    7   8 NaN   10   11
    Hornet Sportabout   1   2    3  4    5  6    7 NaN NaN   10   11
    Valiant             1   2    3  4    5  6    7   8 NaN   10   11

Some functions like `na_locf()`/`na_focb()` also have set = TRUE
arguments to perform operations by reference. There is also `setTRA()`
for (grouped) transformations by reference, wrapping
`TRA(..., set = TRUE)`.

Replace Sepal.Length with group median.

``` r
fmedian(iris$Sepal.Length, iris$Species,
        TRA = "fill", set = TRUE)
head(iris)
```

      Sepal.Length Sepal.Width Petal.Length Petal.Width Species
    1            5         3.5          1.4         0.2  setosa
    2            5         3.0          1.4         0.2  setosa
    3            5         3.2          1.3         0.2  setosa
    4            5         3.1          1.5         0.2  setosa
    5            5         3.6          1.4         0.2  setosa
    6            5         3.9          1.7         0.4  setosa

``` r
data(iris)
```

This is the same as

``` r
setTRA(iris$Sepal.Length, 
       fmedian(iris$Sepal.Length, iris$Species), 
       "fill", iris$Species)
head(iris)
```

      Sepal.Length Sepal.Width Petal.Length Petal.Width Species
    1            5         3.5          1.4         0.2  setosa
    2            5         3.0          1.4         0.2  setosa
    3            5         3.2          1.3         0.2  setosa
    4            5         3.1          1.5         0.2  setosa
    5            5         3.6          1.4         0.2  setosa
    6            5         3.9          1.7         0.4  setosa

``` r
data(iris)
```

``` r
head(iris)
```

      Sepal.Length Sepal.Width Petal.Length Petal.Width Species
    1          5.1         3.5          1.4         0.2  setosa
    2          4.9         3.0          1.4         0.2  setosa
    3          4.7         3.2          1.3         0.2  setosa
    4          4.6         3.1          1.5         0.2  setosa
    5          5.0         3.6          1.4         0.2  setosa
    6          5.4         3.9          1.7         0.4  setosa

`set` can be invoked anywhere. The following turns columns of the matrix
into proportions.

``` r
fsum(m, TRA = "/", set = TRUE)
fsum(m)
```

     mpg  cyl disp   hp drat   wt qsec   vs   am gear carb 
       1    1    1    1    1    1    1    1    1    1    1 

Example of an efficient function for univariate linear regression.

``` r
greg <- function(y, x, g) {
  g <- group(g)
  dmx <- fmean(x, g, TRA = "-", na.rm = FALSE)
  (fsum(y, g, dmx, use = FALSE, na.rm = FALSE) %/=%
      fsum(dmx, g, dmx, use = FALSE, na.rm = FALSE))
}

y <- rnorm(1e7)
x <- rnorm(1e7)
g <- sample.int(1e6, 1e7, TRUE)
microbenchmark(greg(y, x, g), group(g))
```

    Unit: milliseconds
              expr      min       lq     mean   median       uq      max neval cld
     greg(y, x, g) 320.2875 334.1972 351.5702 342.7051 351.1864 446.6771   100  a 
          group(g) 157.7400 164.6486 168.3598 166.4321 169.8010 213.5410   100   b

The expression computed by `greg()` amounts to
`sum(y * (x - mean(x)))/sum((x - mean(x))^2)` for each group, which is
equivalent to `cov(x, y)/var(x)`, but very efficient, requiring exactly
one full copy of x to create a group-demeaned vector, `dmx`, and then
using the w (weights) argument to `fsum()` to sum the products
(`y * dmx` and `dmx * dmx`) on the fly, including a division by
reference avoiding an additional copy.

# Prefer primitive R objects and functions

Vectors, matrices and lists are good, data frames and complex objects
are bad.

``` r
l <- unclass(mtcars)
nam <- names(mtcars)
microbenchmark(
  names(mtcars),
  attr(mtcars, "names"),
  names(l),
  names(mtcars) <- nam, 
  attr(mtcars, "names") <- nam, 
  names(l) <- nam,
  mtcars[["mpg"]],
  .subset2(mtcars, "mpg"), 
  l[["mpg"]],
  mtcars[3:8], 
  .subset(mtcars, 3:8), 
  l[3:8],
  ncol(mtcars), 
  length(mtcars), 
  length(unclass(mtcars)), 
  length(l),
  nrow(mtcars), 
  length(.subset2(mtcars, 1L)), 
  length(l[[1L]])
)
```

    Unit: nanoseconds
                             expr  min     lq    mean median     uq   max neval
                    names(mtcars)  287  350.0  370.17  364.5  384.5   704   100
            attr(mtcars, "names")  128  164.0  195.29  180.0  196.5  1282   100
                         names(l)   66   84.0   99.38   94.0  108.0   227   100
             names(mtcars) <- nam  685  748.5  889.69  890.0  983.0  2855   100
     attr(mtcars, "names") <- nam  486  558.0  825.67  708.5  787.0 14616   100
                  names(l) <- nam  376  432.5  492.08  457.0  493.0  3174   100
                  mtcars[["mpg"]] 2937 3062.0 3207.20 3163.5 3241.5  7168   100
          .subset2(mtcars, "mpg")  107  130.5  173.58  144.0  160.5  2820   100
                       l[["mpg"]]  115  139.5  163.26  150.0  176.0   576   100
                      mtcars[3:8] 7426 7657.0 8152.70 7776.5 7927.0 32747   100
             .subset(mtcars, 3:8)  373  441.0  478.31  462.0  487.5  1616   100
                           l[3:8]  391  465.5  509.18  496.5  527.0  1002   100
                     ncol(mtcars) 1612 1721.5 1840.87 1810.0 1899.5  3214   100
                   length(mtcars)  309  343.5  385.69  381.5  413.0   620   100
          length(unclass(mtcars))  216  267.5  296.72  287.0  312.0   638   100
                        length(l)   56   77.0   93.73   91.0  105.0   233   100
                     nrow(mtcars) 1643 1717.5 1860.03 1772.5 1849.0  8297   100
     length(.subset2(mtcars, 1L))  124  153.5  182.19  170.0  191.0   547   100
                  length(l[[1L]])  133  172.0  223.85  188.0  210.5  3271   100
         cld
     ab     
     ab     
     a      
       c    
       cd   
      b d   
         e  
     ab     
     ab     
          f 
      b d   
      b d   
           g
     ab     
     ab     
     a      
           g
     ab     
     ab     

``` r
microbenchmark(
  nrow(mtcars),
  length(unclass(mtcars)[[1L]])
)
```

    Unit: nanoseconds
                              expr  min   lq    mean median     uq   max neval cld
                      nrow(mtcars) 1639 1652 1888.44 1684.0 1806.0 14063   100  a 
     length(unclass(mtcars)[[1L]])  308  325  386.70  354.5  372.5  3421   100   b

By means of further illustration, let’s recreate the pwnobs() function
in collapse which counts pairwise missing values. The list method is
written in R. A basic implementation is

``` r
pwnobs_list <- function(X) {
  dg <- fnobs(X)
  n <- ncol(X)
  nr <- nrow(X)
  N.mat <- diag(dg)
  for (i in 1:(n - 1L)) {
    miss <- is.na(X[[i]])
    for (j in (i + 1L):n) N.mat[i, j] <- N.mat[j, i] <- 
        nr - sum(miss | is.na(X[[j]]))
  }
  rownames(N.mat) <- names(dg)
  colnames(N.mat) <- names(dg)
  N.mat
}
mtcNA <- na_insert(mtcars, prop = 0.2)
pwnobs_list(mtcNA)
```

         mpg cyl disp hp drat wt qsec vs am gear carb
    mpg   26  22   21 21   20 21   22 22 20   20   21
    cyl   22  26   20 21   21 20   21 21 21   21   21
    disp  21  20   26 20   21 22   22 20 20   20   22
    hp    21  21   20 26   21 20   24 21 22   21   22
    drat  20  21   21 21   26 20   21 21 20   21   21
    wt    21  20   22 20   20 26   20 21 22   21   22
    qsec  22  21   22 24   21 20   26 20 21   20   22
    vs    22  21   20 21   21 21   20 26 21   22   23
    am    20  21   20 22   20 22   21 21 26   22   21
    gear  20  21   20 21   21 21   20 22 22   26   21
    carb  21  21   22 22   21 22   22 23 21   21   26

Optimized version.

``` r
pwnobs_list_opt <- function(X) {
  dg <- fnobs.data.frame(X)
  class(X) <- NULL
  n <- length(X)
  nr <- length(X[[1L]])
  N.mat <- diag(dg)
  for (i in 1:(n - 1L)) {
    miss <- is.na(X[[i]])
    for (j in (i + 1L):n) N.mat[i, j] <- N.mat[j, i] <- 
        nr - sum(miss | is.na(X[[j]]))
  }
  dimnames(N.mat) <- list(names(dg), names(dg))
  N.mat
}

identical(pwnobs_list(mtcNA), pwnobs_list_opt(mtcNA))
```

    [1] TRUE

``` r
microbenchmark(
  pwnobs_list(mtcNA), pwnobs_list_opt(mtcNA)
)
```

    Unit: microseconds
                       expr     min       lq      mean   median       uq     max
         pwnobs_list(mtcNA) 224.711 247.5140 251.62894 253.4700 257.5325 283.386
     pwnobs_list_opt(mtcNA)  32.810  35.9325  38.27427  38.1875  39.5355  58.783
     neval cld
       100  a 
       100   b

Avoid `as.data.frame` and related.

``` r
attr(l, "row.names") <- .set_row_names(length(l[[1L]]))
class(l) <- "data.frame"
head(l, 2)
```

      mpg cyl disp  hp drat    wt  qsec vs am gear carb
    1  21   6  160 110  3.9 2.620 16.46  0  1    4    4
    2  21   6  160 110  3.9 2.875 17.02  0  1    4    4

``` r
library(data.table)
library(tibble)
microbenchmark(qDT(mtcars), as.data.table(mtcars),
                               qTBL(mtcars), as_tibble(mtcars))
```

    Unit: microseconds
                      expr    min      lq     mean  median      uq      max neval
               qDT(mtcars)  4.449  5.0915  8.50465  5.9855  6.8300  237.178   100
     as.data.table(mtcars) 54.123 60.0530 71.39025 64.3235 69.7895  598.411   100
              qTBL(mtcars)  3.570  3.9180  5.23612  4.6375  5.4100   41.423   100
         as_tibble(mtcars) 71.370 75.9705 96.36464 80.8910 94.7660 1172.164   100
     cld
     a  
      b 
     a  
       c

``` r
l <- unclass(mtcars)
microbenchmark(qDF(l), as.data.frame(l), 
               as.data.table(l), as_tibble(l))
```

    Unit: microseconds
                 expr     min       lq      mean   median       uq     max neval
               qDF(l)   2.322   3.4240   5.71947   4.1825   4.7135 172.419   100
     as.data.frame(l) 311.705 338.5530 355.19209 351.9615 367.6565 447.632   100
     as.data.table(l) 114.374 126.7665 142.89157 137.5845 144.0845 824.109   100
         as_tibble(l)  87.804 100.1320 114.36959 113.2890 120.5660 340.256   100
      cld
     a   
      b  
       c 
        d

Another efficient workflow for general data frame-like objects is to
save the attributes `ax <- attributes(data)`, manipulate it as a list
`attributes(data) <- NULL`, modify `ax$names` and `ax$row.names` as
needed and then use `setattrib(data, ax)` before returning.

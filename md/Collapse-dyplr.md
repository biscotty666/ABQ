# Collapse and dyplr


[Source](https://fastverse.org/collapse/articles/collapse_intro.html)

``` r
library(collapse)
library(magrittr)
library(dplyr)
library(microbenchmark)
options(paged.print = FALSE)
```

# Fast Aggregations

- `fsum`
- `fprod`
- `fmean`
- `fmedian`
- `fmode`
- `fvar`
- `fsd`
- `fmin`
- `fmax`
- `fnth`
- `ffirst`
- `flast`
- `fnobs` - Number of Observations
- `fndistinct` - Number of distinct values

The grouped tibble method has the following arguments:

    #| eval: false
    FUN.grouped_df(x, [w = NULL,] TRA = NULL, [na.rm = TRUE,]
                   use.g.names = FALSE, keep.group_vars = TRUE, 
                   [keep.w = TRUE,] ...)

## Simple Aggregations

Efficient conversion to `tibble`

``` r
GGDC10S <- qTBL(GGDC10S)
```

Column-wise computations

Number of Observations

``` r
GGDC10S %>% fnobs
```

       Country Regioncode     Region   Variable       Year        AGR        MIN 
          5027       5027       5027       5027       5027       4364       4355 
           MAN         PU        CON        WRT        TRA       FIRE        GOV 
          4355       4354       4355       4355       4355       4355       3482 
           OTH        SUM 
          4248       4364 

Number of distinct values

``` r
GGDC10S %>% fndistinct
```

       Country Regioncode     Region   Variable       Year        AGR        MIN 
            43          6          6          2         67       4353       4224 
           MAN         PU        CON        WRT        TRA       FIRE        GOV 
          4353       4237       4339       4344       4334       4349       3470 
           OTH        SUM 
          4238       4364 

``` r
GGDC10S %>% select_at(6:16) %>% fmedian
```

           AGR        MIN        MAN         PU        CON        WRT        TRA 
     4394.5194   173.2234  3718.0981   167.9500  1473.4470  3773.6430  1174.8000 
          FIRE        GOV        OTH        SUM 
      960.1251  3928.5127  1433.1722 23186.1936 

``` r
GGDC10S %>% fmode
```

               Country         Regioncode             Region           Variable 
                 "USA"              "ASI"             "Asia"              "EMP" 
                  Year                AGR                MIN                MAN 
                "2010" "171.315882316326"                "0" "4645.12507642586" 
                    PU                CON                WRT                TRA 
                   "0" "1.34623115930777" "21.8380052682527" "8.97743416914571" 
                  FIRE                GOV                OTH                SUM 
    "40.0701608636442"                "0" "3626.84423577048" "37.4822945751317" 

Keep data structure intact

``` r
GGDC10S %>% fmode(drop = FALSE)
```

    # A tibble: 1 × 16
      Country Regioncode Region Variable  Year   AGR   MIN   MAN    PU   CON   WRT
    * <chr>   <chr>      <chr>  <chr>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1 USA     ASI        Asia   EMP       2010  171.     0 4645.     0  1.35  21.8
    # ℹ 5 more variables: TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>

Moving on to grouped statistics, we can compute the average value added
and employment by sector and country using:

``` r
GGDC10S %>% 
  group_by(Variable, Country) %>%
  select_at(6:16) %>% fmean
```

    # A tibble: 85 × 13
       Variable Country     AGR     MIN     MAN      PU     CON    WRT    TRA   FIRE
       <chr>    <chr>     <dbl>   <dbl>   <dbl>   <dbl>   <dbl>  <dbl>  <dbl>  <dbl>
     1 EMP      ARG       1420.   52.1   1932.   102.     742.  1.98e3 6.49e2  628. 
     2 EMP      BOL        964.   56.0    235.     5.35   123.  2.82e2 1.15e2   44.6
     3 EMP      BRA      17191.  206.    6991.   365.    3525.  8.51e3 2.05e3 4414. 
     4 EMP      BWA        188.   10.5     18.1    3.09    25.3 3.63e1 8.36e0   15.3
     5 EMP      CHL        702.  101.     625.    29.4    296.  6.95e2 2.58e2  272. 
     6 EMP      CHN     287744. 7050.   67144.  1606.   20852.  2.89e4 1.39e4 4929. 
     7 EMP      COL       3091.  145.    1175.    33.9    524.  2.07e3 4.70e2  649. 
     8 EMP      CRI        231.    1.70   136.    14.3     57.6 1.57e2 4.24e1   54.9
     9 EMP      DEW       2490.  407.    8473.   226.    2093.  4.44e3 1.48e3 1689. 
    10 EMP      DNK        236.    8.03   507.    13.8    171.  4.55e2 1.61e2  181. 
    # ℹ 75 more rows
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

It is important to not use `dplyr`’s `summarize` together with these
functions since that would eliminate their speed gain. These functions
are fast because they are executed only once and carry out the grouped
computations in C++, whereas summarize will apply the function to each
group in the grouped tibble.

The method GRP.grouped_df takes a dplyr grouping object from a grouped
tibble and efficiently converts it to a collapse grouping object:

``` r
GGDC10S %>% 
  group_by(Variable, Country) %>% 
  GRP %>% str
```

    Class 'GRP'  hidden list of 9
     $ N.groups    : int 85
     $ group.id    : int [1:5027] 46 46 46 46 46 46 46 46 46 46 ...
     $ group.sizes : int [1:85] 62 61 62 52 63 62 61 62 61 64 ...
     $ groups      :List of 2
      ..$ Variable: chr [1:85] "EMP" "EMP" "EMP" "EMP" ...
      .. ..- attr(*, "label")= chr "Variable"
      .. ..- attr(*, "format.stata")= chr "%9s"
      ..$ Country : chr [1:85] "ARG" "BOL" "BRA" "BWA" ...
      .. ..- attr(*, "label")= chr "Country"
      .. ..- attr(*, "format.stata")= chr "%9s"
     $ group.vars  : chr [1:2] "Variable" "Country"
     $ ordered     : Named logi [1:2] TRUE FALSE
      ..- attr(*, "names")= chr [1:2] "ordered" "sorted"
     $ order       : NULL
     $ group.starts: NULL
     $ call        : language GRP.grouped_df(X = .)

## Using `collapse` Verbs

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fmedian
```

    # A tibble: 85 × 13
       Variable Country     AGR     MIN     MAN      PU     CON    WRT    TRA   FIRE
       <chr>    <chr>     <dbl>   <dbl>   <dbl>   <dbl>   <dbl>  <dbl>  <dbl>  <dbl>
     1 EMP      ARG       1325.   47.4   1988.   105.     782.  1.85e3 5.80e2  464. 
     2 EMP      BOL        943.   53.5    167.     4.46    66.0 1.32e2 9.70e1   15.3
     3 EMP      BRA      17481.  225.    7208.   376.    4055.  6.45e3 1.58e3 4355. 
     4 EMP      BWA        175.   12.2     13.1    3.71    19.0 2.11e1 6.75e0   10.4
     5 EMP      CHL        690.   93.9    607.    25.8    230.  4.84e2 2.05e2  106. 
     6 EMP      CHN     293915  8150.   61761.  1139.   10578.  1.70e4 9.56e3 4328. 
     7 EMP      COL       3006.   84.0   1033.    37.1    419.  1.55e3 3.91e2  655. 
     8 EMP      CRI        216.    1.49   114.     7.92    55.0 8.98e1 2.55e1   19.6
     9 EMP      DEW       2178   320.    8459.   247     2095.  4.45e3 1.53e3 1656  
    10 EMP      DNK        187.    3.75   508.    13.6    165.  4.61e2 1.61e2  169. 
    # ℹ 75 more rows
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

``` r
microbenchmark(
  collapse = GGDC10S %>% fgroup_by(Variable, Country) %>%
    get_vars(6:16) %>% fmedian(),
  hybrid = GGDC10S %>% group_by(Variable, Country) %>%
    select_at(6:16) %>%
    fmedian(),
  dplyr = GGDC10S %>% group_by(Variable, Country) %>%
    select_at(6:16) %>%
    summarise_all(median, na.rm = TRUE)
)
```

    Unit: microseconds
         expr       min         lq       mean     median         uq       max neval
     collapse   264.849   307.8685   335.5599   327.7675   375.6765   440.570   100
       hybrid  4359.134  4579.8845  4876.6702  4696.7565  4815.9475  8169.797   100
        dplyr 25835.663 26833.3900 28907.8694 28980.7365 30537.1205 35929.246   100
     cld
     a  
      b 
       c

``` r
class(group_by(GGDC10S, Variable, Country))
```

    [1] "grouped_df" "tbl_df"     "tbl"        "data.frame"

``` r
class(fgroup_by(GGDC10S, Variable, Country))
```

    [1] "GRP_df"     "tbl_df"     "tbl"        "grouped_df" "data.frame"

``` r
fgroup_by(GGDC10S, Variable, Country)
```

    # A tibble: 5,027 × 16
       Country Regioncode Region     Variable  Year   AGR   MIN    MAN     PU    CON
       <chr>   <chr>      <chr>      <chr>    <dbl> <dbl> <dbl>  <dbl>  <dbl>  <dbl>
     1 BWA     SSA        Sub-sahar… VA        1960  NA   NA    NA     NA     NA    
     2 BWA     SSA        Sub-sahar… VA        1961  NA   NA    NA     NA     NA    
     3 BWA     SSA        Sub-sahar… VA        1962  NA   NA    NA     NA     NA    
     4 BWA     SSA        Sub-sahar… VA        1963  NA   NA    NA     NA     NA    
     5 BWA     SSA        Sub-sahar… VA        1964  16.3  3.49  0.737  0.104  0.660
     6 BWA     SSA        Sub-sahar… VA        1965  15.7  2.50  1.02   0.135  1.35 
     7 BWA     SSA        Sub-sahar… VA        1966  17.7  1.97  0.804  0.203  1.35 
     8 BWA     SSA        Sub-sahar… VA        1967  19.1  2.30  0.938  0.203  0.897
     9 BWA     SSA        Sub-sahar… VA        1968  21.1  1.84  0.750  0.203  1.22 
    10 BWA     SSA        Sub-sahar… VA        1969  21.9  5.24  2.14   0.578  3.47 
    # ℹ 5,017 more rows
    # ℹ 6 more variables: WRT <dbl>, TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>,
    #   SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

Note further that fselect and get_vars are not full drop-in replacements
for select because they do not have a grouped_df method:

``` r
GGDC10S %>% group_by(Variable, Country) %>% select_at(6:16) %>% tail(3)
```

    # A tibble: 3 × 13
    # Groups:   Variable, Country [1]
      Variable Country   AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH
      <chr>    <chr>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1 EMP      EGY     5206.  29.0 2436.  307. 2733. 2977. 1992.  801. 5539.    NA
    2 EMP      EGY     5186.  27.6 2374.  318. 2795. 3020. 2048.  815. 5636.    NA
    3 EMP      EGY     5161.  24.8 2348.  325. 2931. 3110. 2065.  832. 5736.    NA
    # ℹ 1 more variable: SUM <dbl>

``` r
GGDC10S %>% group_by(Variable, Country) %>% get_vars(6:16) %>% tail(3)
```

    # A tibble: 3 × 11
        AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH    SUM
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
    1 5206.  29.0 2436.  307. 2733. 2977. 1992.  801. 5539.    NA 22020.
    2 5186.  27.6 2374.  318. 2795. 3020. 2048.  815. 5636.    NA 22219.
    3 5161.  24.8 2348.  325. 2931. 3110. 2065.  832. 5736.    NA 22533.

Since by default keep.group_vars = TRUE in the Fast Statistical
Functions, the end result is nevertheless the same:

``` r
GGDC10S %>% group_by(Variable, Country) %>% 
  select_at(6:16) %>% fmean %>% tail(3)
```

    # A tibble: 3 × 13
      Variable Country      AGR      MIN     MAN      PU    CON    WRT    TRA   FIRE
      <chr>    <chr>      <dbl>    <dbl>   <dbl>   <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
    1 VA       VEN        6860.   35478.  19553.   1064. 1.17e4 1.93e4 8.03e3 5.60e3
    2 VA       ZAF       16419.   42928.  87572.  13826. 1.64e4 6.83e4 4.53e4 6.64e4
    3 VA       ZMB     1268849. 1006099. 899510. 219164. 8.66e5 2.10e6 7.05e5 9.10e5
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

``` r
GGDC10S %>% group_by(Variable, Country) %>% 
  get_vars(6:16) %>% fmean %>% tail(3)
```

    # A tibble: 3 × 13
      Variable Country      AGR      MIN     MAN      PU    CON    WRT    TRA   FIRE
      <chr>    <chr>      <dbl>    <dbl>   <dbl>   <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
    1 VA       VEN        6860.   35478.  19553.   1064. 1.17e4 1.93e4 8.03e3 5.60e3
    2 VA       ZAF       16419.   42928.  87572.  13826. 1.64e4 6.83e4 4.53e4 6.64e4
    3 VA       ZMB     1268849. 1006099. 899510. 219164. 8.66e5 2.10e6 7.05e5 9.10e5
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

`fgroup_vars` can be used to efficiently obtain the grouping columns or
grouping variables from a grouped tibble.

`fgroup_by` fully supports grouped tibbles created with `group_by` or
`fgroup_by`:

``` r
GGDC10S %>% group_by(Variable, Country) %>% 
  fgroup_vars %>% 
  head(3)
```

    # A tibble: 3 × 2
      Variable Country
      <chr>    <chr>  
    1 VA       BWA    
    2 VA       BWA    
    3 VA       BWA    

``` r
GGDC10S %>% fgroup_by(Variable, Country) %>% 
  fgroup_vars %>% 
  head(3)
```

    # A tibble: 3 × 2
      Variable Country
      <chr>    <chr>  
    1 VA       BWA    
    2 VA       BWA    
    3 VA       BWA    

``` r
GGDC10S %>% group_by(Variable, Country) %>% 
  fgroup_vars("unique") %>% 
  head(3)
```

    # A tibble: 3 × 2
      Variable Country
      <chr>    <chr>  
    1 EMP      ARG    
    2 EMP      BOL    
    3 EMP      BRA    

`fsubset` is a faster alternative to `dplyr::filter` which also provides
an option to flexibly subset columns after the select argument:

Two equivalent calls, the first is substantially faster

``` r
microbenchmark(
  filter = GGDC10S %>% 
    filter(Variable == "VA" & Year > 1990) %>%
    select(Country, Year, AGR:GOV) %>% head(3),
  fsubset = GGDC10S %>% 
    fsubset(Variable == "VA" & Year > 1990, 
            Country, Year, AGR:GOV) %>% head(3)
)
```

    Unit: microseconds
        expr      min       lq      mean   median        uq      max neval cld
      filter 1394.994 1468.499 1591.5757 1492.610 1537.9855 4693.304   100  a 
     fsubset  100.400  114.175  138.0077  131.064  138.6405  358.018   100   b

## Multifunction Aggregations

For such operations it is often necessary to use curly braces `{` to
prevent first argument injection so that `%>% cbind(FUN1(.), FUN2(.))`
does not evaluate as `%>% cbind(., FUN1(.), FUN2(.))`

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>%  {
    cbind(fmedian(.),
          add_stub(fmean(., keep.group_vars = F), "mean_"))
  } %>% head(3)
```

      Variable Country        AGR       MIN       MAN         PU        CON
    1      EMP     ARG  1324.5255  47.35255 1987.5912 104.738825  782.40283
    2      EMP     BOL   943.1612  53.53538  167.1502   4.457895   65.97904
    3      EMP     BRA 17480.9810 225.43693 7207.7915 375.851832 4054.66103
           WRT        TRA       FIRE      GOV       OTH       SUM   mean_AGR
    1 1854.612  579.93982  464.39920 1738.836  866.1119  9743.223  1419.8013
    2  132.225   96.96828   15.34259       NA  384.0678  1842.055   964.2103
    3 6454.523 1580.81120 4354.86210 4449.942 4478.6927 51881.110 17191.3529
       mean_MIN  mean_MAN    mean_PU  mean_CON  mean_WRT  mean_TRA  mean_FIRE
    1  52.08903 1931.7602 101.720936  742.4044 1982.1775  648.5119  627.79291
    2  56.03295  235.0332   5.346433  122.7827  281.5164  115.4728   44.56442
    3 206.02389 6991.3710 364.573404 3524.7384 8509.4612 2054.3731 4413.54448
      mean_GOV  mean_OTH  mean_SUM
    1 2043.471  992.4475 10542.177
    2       NA  395.5650  2220.524
    3 5307.280 5710.2665 54272.985

\# Regular expression matching column names

``` r
GGDC10S %>%
  fgroup_by(Variable, Country) %>%
  {
    add_vars(
      get_vars(., "Reg", regex = TRUE) %>% # Gets both Region and Regioncode
        ffirst(),
      num_vars(.) %>%
        fmean(keep.group_vars = FALSE) %>%
        add_stub("mean_"),
      fselect(., PU:TRA) %>%
        fmedian(keep.group_vars = FALSE) %>%
        add_stub("median_"),
      fselect(., PU:CON) %>%
        fmin(keep.group_vars = FALSE) %>%
        add_stub("min_")
    )
  } %>%
  head(3)
```

    # A tibble: 3 × 22
      Variable Country Regioncode Region        mean_Year mean_AGR mean_MIN mean_MAN
      <chr>    <chr>   <chr>      <chr>             <dbl>    <dbl>    <dbl>    <dbl>
    1 EMP      ARG     LAM        Latin America     1980.    1420.     52.1    1932.
    2 EMP      BOL     LAM        Latin America     1980      964.     56.0     235.
    3 EMP      BRA     LAM        Latin America     1980.   17191.    206.     6991.
    # ℹ 14 more variables: mean_PU <dbl>, mean_CON <dbl>, mean_WRT <dbl>,
    #   mean_TRA <dbl>, mean_FIRE <dbl>, mean_GOV <dbl>, mean_OTH <dbl>,
    #   mean_SUM <dbl>, median_PU <dbl>, median_CON <dbl>, median_WRT <dbl>,
    #   median_TRA <dbl>, min_PU <dbl>, min_CON <dbl>

Specify position of new columns

``` r
names(GGDC10S)
```

     [1] "Country"    "Regioncode" "Region"     "Variable"   "Year"      
     [6] "AGR"        "MIN"        "MAN"        "PU"         "CON"       
    [11] "WRT"        "TRA"        "FIRE"       "GOV"        "OTH"       
    [16] "SUM"       

``` r
GGDC10S %>%
  fsubset(Variable == "VA", Country, AGR, SUM) %>% 
  fgroup_by(Country) %>% {
   add_vars(fgroup_vars(.,"unique"),
            fmean(., keep.group_vars = FALSE) %>% add_stub("mean_"),
            fsd(., keep.group_vars = FALSE) %>% add_stub("sd_"), 
            pos = c(2,4,3,5))
  } %>% head(3)
```

    # A tibble: 3 × 5
      Country mean_AGR sd_AGR mean_SUM  sd_SUM
      <chr>      <dbl>  <dbl>    <dbl>   <dbl>
    1 ARG       14951. 33061.  152534. 301316.
    2 BOL        3300.  4456.   22619.  33173.
    3 BRA       76870. 59442. 1200563. 976963.

``` r
GGDC10S %>%
  fsubset(Variable == "VA", Country, AGR, SUM) %>% 
  fgroup_by(Country) %>% {
   add_vars(fgroup_vars(.,"unique"),
            fmean(., keep.group_vars = FALSE) %>% add_stub("mean_"),
            fsd(., keep.group_vars = FALSE) %>% add_stub("sd_"))
  } %>% head(3)
```

    # A tibble: 3 × 5
      Country mean_AGR mean_SUM sd_AGR  sd_SUM
      <chr>      <dbl>    <dbl>  <dbl>   <dbl>
    1 ARG       14951.  152534. 33061. 301316.
    2 BOL        3300.   22619.  4456.  33173.
    3 BRA       76870. 1200563. 59442. 976963.

A much more compact solution to multi-function and multi-type
aggregation is offered by the function collapg, which by default uses
`fmean` for numeric and `fmode` for categorical columns.

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  collapg %>% 
  head(3)
```

    # A tibble: 3 × 16
      Variable Country Regioncode Region  Year    AGR   MIN   MAN     PU   CON   WRT
      <chr>    <chr>   <chr>      <chr>  <dbl>  <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl>
    1 EMP      ARG     LAM        Latin… 1980.  1420.  52.1 1932. 102.    742. 1982.
    2 EMP      BOL     LAM        Latin… 1980    964.  56.0  235.   5.35  123.  282.
    3 EMP      BRA     LAM        Latin… 1980. 17191. 206.  6991. 365.   3525. 8509.
    # ℹ 5 more variables: TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>

Changing the default

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  collapg(fmedian, flast) %>% head(3)
```

    # A tibble: 3 × 16
      Variable Country Regioncode Region       Year    AGR   MIN   MAN     PU    CON
      <chr>    <chr>   <chr>      <chr>       <dbl>  <dbl> <dbl> <dbl>  <dbl>  <dbl>
    1 EMP      ARG     LAM        Latin Amer… 1980.  1325.  47.4 1988. 105.    782. 
    2 EMP      BOL     LAM        Latin Amer… 1980    943.  53.5  167.   4.46   66.0
    3 EMP      BRA     LAM        Latin Amer… 1980. 17481. 225.  7208. 376.   4055. 
    # ℹ 6 more variables: WRT <dbl>, TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>,
    #   SUM <dbl>

One can apply multiple functions to both numeric and/or categorical
data:

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  collapg(list(fmean, fmedian), list(ffirst, fmode, flast)) %>% 
  head(3)
```

    # A tibble: 3 × 32
      Variable Country ffirst.Regioncode fmode.Regioncode flast.Regioncode
      <chr>    <chr>   <chr>             <chr>            <chr>           
    1 EMP      ARG     LAM               LAM              LAM             
    2 EMP      BOL     LAM               LAM              LAM             
    3 EMP      BRA     LAM               LAM              LAM             
    # ℹ 27 more variables: ffirst.Region <chr>, fmode.Region <chr>,
    #   flast.Region <chr>, fmean.Year <dbl>, fmedian.Year <dbl>, fmean.AGR <dbl>,
    #   fmedian.AGR <dbl>, fmean.MIN <dbl>, fmedian.MIN <dbl>, fmean.MAN <dbl>,
    #   fmedian.MAN <dbl>, fmean.PU <dbl>, fmedian.PU <dbl>, fmean.CON <dbl>,
    #   fmedian.CON <dbl>, fmean.WRT <dbl>, fmedian.WRT <dbl>, fmean.TRA <dbl>,
    #   fmedian.TRA <dbl>, fmean.FIRE <dbl>, fmedian.FIRE <dbl>, fmean.GOV <dbl>,
    #   fmedian.GOV <dbl>, fmean.OTH <dbl>, fmedian.OTH <dbl>, fmean.SUM <dbl>, …

Applying multiple functions to only numeric (or only categorical) data
allows return in a long format:

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>%
  collapg(list(fmean, fmedian), 
          cols = is.numeric, return = "long") %>% 
  head(3)
```

    # A tibble: 3 × 15
      Function Variable Country  Year    AGR   MIN   MAN     PU   CON   WRT   TRA
      <fct>    <chr>    <chr>   <dbl>  <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl>
    1 fmean    EMP      ARG     1980.  1420.  52.1 1932. 102.    742. 1982.  649.
    2 fmean    EMP      BOL     1980    964.  56.0  235.   5.35  123.  282.  115.
    3 fmean    EMP      BRA     1980. 17191. 206.  6991. 365.   3525. 8509. 2054.
    # ℹ 4 more variables: FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>

Apply aggregator functions to select columns

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  collapg(
    custom = list(fmean = 6:8,
                  fmedian = 10:12)
  ) %>% head(3)
```

    # A tibble: 3 × 8
      Variable Country    AGR   MIN   MAN    CON   WRT    TRA
      <chr>    <chr>    <dbl> <dbl> <dbl>  <dbl> <dbl>  <dbl>
    1 EMP      ARG      1420.  52.1 1932.  782.  1855.  580. 
    2 EMP      BOL       964.  56.0  235.   66.0  132.   97.0
    3 EMP      BRA     17191. 206.  6991. 4055.  6455. 1581. 

## Weighted Aggregations

``` r
GGDC10S %>%
  fgroup_by(Variable, Country) %>%
  fselect(AGR:SUM) %>% 
  fsd(SUM) %>% head(3)
```

    # A tibble: 3 × 13
      Variable Country  sum.SUM    AGR   MIN   MAN    PU   CON   WRT    TRA   FIRE
      <chr>    <chr>      <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>  <dbl>
    1 EMP      ARG      653615.  225.   22.2  176. 20.5   285.  856.  195.   493. 
    2 EMP      BOL      135452.   99.7  17.1  168.  4.87  123.  324.   98.1   69.8
    3 EMP      BRA     3364925. 1587.   73.8 2952. 93.8  1861. 6285. 1306.  3003. 
    # ℹ 2 more variables: GOV <dbl>, OTH <dbl>

``` r
GGDC10S %>%
  fgroup_by(Variable, Country) %>%
  fselect(AGR:SUM) %>% 
  fmode(SUM) %>% head(3)
```

    # A tibble: 3 × 13
      Variable Country  sum.SUM    AGR   MIN    MAN    PU   CON    WRT   TRA   FIRE
      <chr>    <chr>      <dbl>  <dbl> <dbl>  <dbl> <dbl> <dbl>  <dbl> <dbl>  <dbl>
    1 EMP      ARG      653615.  1162. 127.   2164. 152.  1415.  3768. 1060.  1748.
    2 EMP      BOL      135452.   819.  37.6   604.  10.8  433.   893.  333.   321.
    3 EMP      BRA     3364925. 16451. 313.  11841. 388.  8154. 21860. 5169. 12011.
    # ℹ 2 more variables: GOV <dbl>, OTH <dbl>

Weighted aggregations may also be performed with collapg. By default
fsum is used to compute a sum of the weights, but it is also possible
here to aggregate the weights with other functions:

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  collapg(w = SUM, wFUN = list(fsum, fmax)) %>%  head(3)
```

    # A tibble: 3 × 17
      Variable Country fsum.SUM fmax.SUM Regioncode Region   Year    AGR   MIN   MAN
      <chr>    <chr>      <dbl>    <dbl> <chr>      <chr>   <dbl>  <dbl> <dbl> <dbl>
    1 EMP      ARG      653615.   17929. LAM        Latin … 1985.  1361.  56.5 1935.
    2 EMP      BOL      135452.    4508. LAM        Latin … 1987.   977.  57.9  296.
    3 EMP      BRA     3364925.  102572. LAM        Latin … 1989. 17746. 238.  8466.
    # ℹ 7 more variables: PU <dbl>, CON <dbl>, WRT <dbl>, TRA <dbl>, FIRE <dbl>,
    #   GOV <dbl>, OTH <dbl>

# Fast Transformations

`ftransform` instead of `mutate`.

``` r
GGDC10S %>% 
  fsubset(Variable == "VA", Country, Year, AGR, SUM) %>% 
  ftransform(
    AGR_perc = AGR / SUM * 100,
    AGR_mean = fmean(AGR),
    AGR = NULL, SUM = NULL # Deleting columns AGR and SUM
  ) %>% head
```

    # A tibble: 6 × 4
      Country  Year AGR_perc AGR_mean
      <chr>   <dbl>    <dbl>    <dbl>
    1 BWA      1960     NA   5137561.
    2 BWA      1961     NA   5137561.
    3 BWA      1962     NA   5137561.
    4 BWA      1963     NA   5137561.
    5 BWA      1964     43.5 5137561.
    6 BWA      1965     40.0 5137561.

``` r
microbenchmark(
  ftransform = GGDC10S %>%
    fsubset(Variable == "VA", Country, Year, AGR, SUM) %>%
    ftransform(
      AGR_perc = AGR / SUM * 100,
      AGR_mean = fmean(AGR),
      AGR = NULL, SUM = NULL # Deleting columns AGR and SUM
    ) %>% head(),
  mutate = GGDC10S %>%
    filter(Variable == "VA") %>%
    select(Country, Year, AGR, SUM) %>%
    mutate(
      AGR_perc = AGR / SUM * 100,
      AGR_mean = mean(AGR)
    ) %>%
    select(-AGR, -SUM) %>%
    head()
)
```

    Unit: microseconds
           expr      min        lq      mean   median        uq        max neval
     ftransform  105.921  127.3245  148.8302  152.775  165.5945    227.631   100
         mutate 3272.010 3410.2775 4538.4688 3466.577 3558.0455 100227.859   100
     cld
      a 
       b

The modification brought by `ftransformv` enables transformations of
groups of columns like `dplyr::mutate_at` and `dplyr::mutate_if`:

This replaces variables mpg, carb and wt by their log (.c turns
expressions into character vectors)

``` r
mtcars %>% 
  ftransformv(.c(mpg, carb, wt), log) %>% 
  head
```

                           mpg cyl disp  hp drat        wt  qsec vs am gear
    Mazda RX4         3.044522   6  160 110 3.90 0.9631743 16.46  0  1    4
    Mazda RX4 Wag     3.044522   6  160 110 3.90 1.0560527 17.02  0  1    4
    Datsun 710        3.126761   4  108  93 3.85 0.8415672 18.61  1  1    4
    Hornet 4 Drive    3.063391   6  258 110 3.08 1.1678274 19.44  1  0    3
    Hornet Sportabout 2.928524   8  360 175 3.15 1.2354715 17.02  0  0    3
    Valiant           2.895912   6  225 105 2.76 1.2412686 20.22  1  0    3
                           carb
    Mazda RX4         1.3862944
    Mazda RX4 Wag     1.3862944
    Datsun 710        0.0000000
    Hornet 4 Drive    0.0000000
    Hornet Sportabout 0.6931472
    Valiant           0.0000000

Logging numeric variables

``` r
iris %>% ftransformv(is.numeric, log) %>% head
```

      Sepal.Length Sepal.Width Petal.Length Petal.Width Species
    1     1.629241    1.252763    0.3364722  -1.6094379  setosa
    2     1.589235    1.098612    0.3364722  -1.6094379  setosa
    3     1.547563    1.163151    0.2623643  -1.6094379  setosa
    4     1.526056    1.131402    0.4054651  -1.6094379  setosa
    5     1.609438    1.280934    0.3364722  -1.6094379  setosa
    6     1.686399    1.360977    0.5306283  -0.9162907  setosa

Can pass a list of transformed variables instead of using
`column = value`.

``` r
mtcars %>% 
  ftransform(
    fselect(., mpg, cyl, vs:gear) %>% 
      lapply(log) %>% replace_Inf
  ) %>% 
  head
```

                           mpg      cyl disp  hp drat    wt  qsec vs am     gear
    Mazda RX4         3.044522 1.791759  160 110 3.90 2.620 16.46 NA  0 1.386294
    Mazda RX4 Wag     3.044522 1.791759  160 110 3.90 2.875 17.02 NA  0 1.386294
    Datsun 710        3.126761 1.386294  108  93 3.85 2.320 18.61  0  0 1.386294
    Hornet 4 Drive    3.063391 1.791759  258 110 3.08 3.215 19.44  0 NA 1.098612
    Hornet Sportabout 2.928524 2.079442  360 175 3.15 3.440 17.02 NA NA 1.098612
    Valiant           2.895912 1.791759  225 105 2.76 3.460 20.22  0 NA 1.098612
                      carb
    Mazda RX4            4
    Mazda RX4 Wag        4
    Datsun 710           1
    Hornet 4 Drive       1
    Hornet Sportabout    2
    Valiant              1

If only the computed columns need to be returned, `fcompute` provides an
efficient alternative:

``` r
GGDC10S %>% 
  fsubset(Variable == "VA", Country, Year, AGR, SUM) %>%
  fcompute(AGR_perc = AGR / SUM * 100,
           AGR_mean = fmean(AGR)) %>% head
```

    # A tibble: 6 × 2
      AGR_perc AGR_mean
         <dbl>    <dbl>
    1     NA   5137561.
    2     NA   5137561.
    3     NA   5137561.
    4     NA   5137561.
    5     43.5 5137561.
    6     40.0 5137561.

## Replacing and sweeping out statistics

- “replace_fill” : replace and overwrite missing values (same as mutate)
- “replace” : replace but preserve missing values
- “-” : subtract (center)
- “-+” : subtract group-statistics but add average of group statistics
- “/” : divide (scale)
- “%” : compute percentages (divide and multiply by 100)
- “+” : add
- “\*” : multiply
- “%%” : modulus
- “-%%” : subtract modulus

This subtracts the median value from all data points i.e. centers on the
median

``` r
GGDC10S %>% 
  num_vars %>% 
  fmedian(TRA = "-") %>% head()
```

    # A tibble: 6 × 12
       Year    AGR   MIN    MAN    PU    CON    WRT    TRA  FIRE    GOV    OTH
      <dbl>  <dbl> <dbl>  <dbl> <dbl>  <dbl>  <dbl>  <dbl> <dbl>  <dbl>  <dbl>
    1   -22    NA    NA     NA    NA     NA     NA     NA    NA     NA     NA 
    2   -21    NA    NA     NA    NA     NA     NA     NA    NA     NA     NA 
    3   -20    NA    NA     NA    NA     NA     NA     NA    NA     NA     NA 
    4   -19    NA    NA     NA    NA     NA     NA     NA    NA     NA     NA 
    5   -18 -4378. -170. -3717. -168. -1473. -3767. -1173. -959. -3924. -1431.
    6   -17 -4379. -171. -3717. -168. -1472. -3767. -1173. -959. -3923. -1430.
    # ℹ 1 more variable: SUM <dbl>

This replaces all data points with the mode

``` r
GGDC10S %>% 
  char_vars %>% 
  fmode(TRA = "replace") %>% head
```

    # A tibble: 6 × 4
      Country Regioncode Region Variable
      <chr>   <chr>      <chr>  <chr>   
    1 USA     ASI        Asia   EMP     
    2 USA     ASI        Asia   EMP     
    3 USA     ASI        Asia   EMP     
    4 USA     ASI        Asia   EMP     
    5 USA     ASI        Asia   EMP     
    6 USA     ASI        Asia   EMP     

For grouped transformations:

Replacing data with the 2nd quartile (25%)

``` r
GGDC10S %>% 
  fselect(Variable, Country, AGR:SUM) %>% 
  fgroup_by(Variable, Country) %>% 
  fnth(0.25, TRA = "replace_fill") %>% head(3)
```

    # A tibble: 3 × 13
      Variable Country   AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH
      <chr>    <chr>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1 VA       BWA      63.5  33.1  27.3  7.36  26.8  31.1  13.2  12.0  33.6  11.5
    2 VA       BWA      63.5  33.1  27.3  7.36  26.8  31.1  13.2  12.0  33.6  11.5
    3 VA       BWA      63.5  33.1  27.3  7.36  26.8  31.1  13.2  12.0  33.6  11.5
    # ℹ 1 more variable: SUM <dbl>

Scaling sectoral data by Variable and Country

``` r
GGDC10S %>% 
  fselect(Variable, Country, AGR:SUM) %>% 
  fgroup_by(Variable, Country) %>% 
  fsd(TRA = "/") %>% head
```

    # A tibble: 6 × 13
      Variable Country     AGR      MIN      MAN       PU      CON      WRT      TRA
      <chr>    <chr>     <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
    1 VA       BWA     NA      NA       NA       NA       NA       NA       NA      
    2 VA       BWA     NA      NA       NA       NA       NA       NA       NA      
    3 VA       BWA     NA      NA       NA       NA       NA       NA       NA      
    4 VA       BWA     NA      NA       NA       NA       NA       NA       NA      
    5 VA       BWA      0.0270  5.56e-4  5.23e-4  3.88e-4  5.11e-4  0.00194  0.00154
    6 VA       BWA      0.0260  3.97e-4  7.23e-4  5.03e-4  1.04e-3  0.00220  0.00180
    # ℹ 4 more variables: FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>

Grouped mutations without creating a grouped tibble

AGR_gmed = TRUE if AGR is greater than it’s median value, grouped by
Variable and Country. Note: This calls fmedian.default

``` r
settransform(GGDC10S,
             AGR_gmed = AGR > fmedian(AGR, list(Variable, Country),
                                      TRA = "replace")
)
tail(GGDC10S, 3)
```

    # A tibble: 3 × 17
      Country Regioncode Region   Variable  Year   AGR   MIN   MAN    PU   CON   WRT
      <chr>   <chr>      <chr>    <chr>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1 EGY     MENA       Middle … EMP       2010 5206.  29.0 2436.  307. 2733. 2977.
    2 EGY     MENA       Middle … EMP       2011 5186.  27.6 2374.  318. 2795. 3020.
    3 EGY     MENA       Middle … EMP       2012 5161.  24.8 2348.  325. 2931. 3110.
    # ℹ 6 more variables: TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>,
    #   AGR_gmed <lgl>

Dividing (scaling) the sectoral data (columns 6 through 16) by their
grouped standard deviation

``` r
settransformv(
  GGDC10S,
  6:16,
  fsd,
  list(Variable, Country),
  TRA = "/",
  apply = FALSE
)
tail(GGDC10S)
```

    # A tibble: 6 × 17
      Country Regioncode Region   Variable  Year   AGR   MIN   MAN    PU   CON   WRT
      <chr>   <chr>      <chr>    <chr>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1 EGY     MENA       Middle … EMP       2007  8.44  2.64  4.42  3.26  2.85  3.41
    2 EGY     MENA       Middle … EMP       2008  8.44  2.51  4.43  3.36  3.15  3.55
    3 EGY     MENA       Middle … EMP       2009  8.43  2.40  4.51  3.49  3.53  3.80
    4 EGY     MENA       Middle … EMP       2010  8.41  2.28  4.32  3.56  3.62  3.75
    5 EGY     MENA       Middle … EMP       2011  8.38  2.17  4.21  3.68  3.70  3.81
    6 EGY     MENA       Middle … EMP       2012  8.34  1.95  4.17  3.76  3.88  3.92
    # ℹ 6 more variables: TRA <dbl>, FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>,
    #   AGR_gmed <lgl>

``` r
rm(GGDC10S)
```

Adding weights to grouped transformations

``` r
GGDC10S %>% 
  fselect(Variable, Country, AGR:SUM) %>% 
  fgroup_by(Variable, Country) %>% 
  fmean(SUM, "-") %>% 
  head
```

      Variable Country      SUM       AGR       MIN       MAN        PU       CON
    1       VA     BWA       NA        NA        NA        NA        NA        NA
    2       VA     BWA       NA        NA        NA        NA        NA        NA
    3       VA     BWA       NA        NA        NA        NA        NA        NA
    4       VA     BWA       NA        NA        NA        NA        NA        NA
    5       VA     BWA 37.48229 -1301.113 -13317.10 -2964.701 -528.5427 -2745.996
    6       VA     BWA 39.34710 -1301.688 -13318.09 -2964.419 -528.5120 -2745.310
            WRT       TRA      FIRE       GOV       OTH
    1        NA        NA        NA        NA        NA
    2        NA        NA        NA        NA        NA
    3        NA        NA        NA        NA        NA
    4        NA        NA        NA        NA        NA
    5 -6540.405 -2156.528 -4430.977 -7551.069 -2613.149
    6 -6539.584 -2156.248 -4430.850 -7550.196 -2612.812

Sequentially scale then subtract median.

``` r
GGDC10S %>% 
  fselect(Variable, Country, AGR:SUM) %>% 
  fgroup_by(Variable, Country) %>% 
  fsd(TRA = "/") %>% 
  fmedian(TRA = "-") %>% 
  head(10)
```

       Variable Country        AGR        MIN        MAN         PU        CON
    1        VA     BWA         NA         NA         NA         NA         NA
    2        VA     BWA         NA         NA         NA         NA         NA
    3        VA     BWA         NA         NA         NA         NA         NA
    4        VA     BWA         NA         NA         NA         NA         NA
    5        VA     BWA -0.1819651 -0.2347562 -0.1833832 -0.2452089 -0.1175826
    6        VA     BWA -0.1829165 -0.2349150 -0.1831831 -0.2450946 -0.1170517
    7        VA     BWA -0.1796815 -0.2349986 -0.1833354 -0.2448433 -0.1170517
    8        VA     BWA -0.1772553 -0.2349464 -0.1832402 -0.2448433 -0.1173989
    9        VA     BWA -0.1740204 -0.2350195 -0.1833735 -0.2448433 -0.1171509
    10       VA     BWA -0.1727576 -0.2344778 -0.1823866 -0.2434467 -0.1154056
               WRT         TRA        FIRE        GOV         OTH        SUM
    1           NA          NA          NA         NA          NA         NA
    2           NA          NA          NA         NA          NA         NA
    3           NA          NA          NA         NA          NA         NA
    4           NA          NA          NA         NA          NA         NA
    5  -0.08196890 -0.07244500 -0.06606111 -0.1077699 -0.08482976 -0.1457267
    6  -0.08171379 -0.07218467 -0.06600143 -0.1075279 -0.08456911 -0.1456371
    7  -0.08133903 -0.07198441 -0.06594932 -0.1073423 -0.08432541 -0.1454546
    8  -0.08257039 -0.07238492 -0.06586586 -0.1071566 -0.08408171 -0.1455387
    9  -0.08230270 -0.07171741 -0.06610142 -0.1077136 -0.08481281 -0.1455509
    10 -0.08212168 -0.07146161 -0.06600788 -0.1075567 -0.08460681 -0.1450669

Of course it is also possible to combine multiple functions as in the
aggregation section, or to add variables to existing data:

This adds a groupwise observation count next to each column

``` r
add_vars(GGDC10S, seq(7, 27, 2)) <- GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  fselect(AGR:SUM) %>% 
  fnobs("replace_fill") %>% 
  add_stub("N_")
head(GGDC10S)
```

      Country Regioncode             Region Variable Year      AGR N_AGR      MIN
    1     BWA        SSA Sub-saharan Africa       VA 1960       NA    47       NA
    2     BWA        SSA Sub-saharan Africa       VA 1961       NA    47       NA
    3     BWA        SSA Sub-saharan Africa       VA 1962       NA    47       NA
    4     BWA        SSA Sub-saharan Africa       VA 1963       NA    47       NA
    5     BWA        SSA Sub-saharan Africa       VA 1964 16.30154    47 3.494075
    6     BWA        SSA Sub-saharan Africa       VA 1965 15.72700    47 2.495768
      N_MIN       MAN N_MAN        PU N_PU       CON N_CON      WRT N_WRT      TRA
    1    47        NA    47        NA   47        NA    47       NA    47       NA
    2    47        NA    47        NA   47        NA    47       NA    47       NA
    3    47        NA    47        NA   47        NA    47       NA    47       NA
    4    47        NA    47        NA   47        NA    47       NA    47       NA
    5    47 0.7365696    47 0.1043936   47 0.6600454    47 6.243732    47 1.658928
    6    47 1.0181992    47 0.1350976   47 1.3462312    47 7.064825    47 1.939007
      N_TRA     FIRE N_FIRE      GOV N_GOV      OTH N_OTH      SUM N_SUM
    1    47       NA     47       NA    47       NA    47       NA    47
    2    47       NA     47       NA    47       NA    47       NA    47
    3    47       NA     47       NA    47       NA    47       NA    47
    4    47       NA     47       NA    47       NA    47       NA    47
    5    47 1.119194     47 4.822485    47 2.341328    47 37.48229    47
    6    47 1.246789     47 5.695848    47 2.678338    47 39.34710    47

``` r
rm(GGDC10S)
```

## The `TRA` function

Fundamentally, `TRA` is a generalization of `base::sweep` for
column-wise grouped operations. Direct calls to `TRA` enable more
control over inputs and outputs.

The two operations below are equivalent, although the first is slightly
more efficient as it only requires one method dispatch and one check of
the inputs:

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fprod(TRA = "/") %>% 
  head
```

                AGR           MIN           MAN           PU           CON
    1            NA            NA            NA           NA            NA
    2            NA            NA            NA           NA            NA
    3            NA            NA            NA           NA            NA
    4            NA            NA            NA           NA            NA
    5 1.285134e-105 2.806662e-127 1.400237e-101 4.441472e-74 4.192031e-102
    6 1.239840e-105 2.004758e-127 1.935622e-101 5.747788e-74 8.550083e-102
                WRT          TRA         FIRE           GOV          OTH
    1            NA           NA           NA            NA           NA
    2            NA           NA           NA            NA           NA
    3            NA           NA           NA            NA           NA
    4            NA           NA           NA            NA           NA
    5 3.968680e-113 6.913397e-92 1.011237e-97 2.508767e-117 2.358324e-94
    6 4.490588e-113 8.080594e-92 1.126525e-97 2.963110e-117 2.697780e-94
                SUM
    1            NA
    2            NA
    3            NA
    4            NA
    5 7.157273e-156
    6 7.513359e-156

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  TRA(fprod(., keep.group_vars = FALSE), "/") %>% 
  head
```

                AGR           MIN           MAN           PU           CON
    1            NA            NA            NA           NA            NA
    2            NA            NA            NA           NA            NA
    3            NA            NA            NA           NA            NA
    4            NA            NA            NA           NA            NA
    5 1.285134e-105 2.806662e-127 1.400237e-101 4.441472e-74 4.192031e-102
    6 1.239840e-105 2.004758e-127 1.935622e-101 5.747788e-74 8.550083e-102
                WRT          TRA         FIRE           GOV          OTH
    1            NA           NA           NA            NA           NA
    2            NA           NA           NA            NA           NA
    3            NA           NA           NA            NA           NA
    4            NA           NA           NA            NA           NA
    5 3.968680e-113 6.913397e-92 1.011237e-97 2.508767e-117 2.358324e-94
    6 4.490588e-113 8.080594e-92 1.126525e-97 2.963110e-117 2.697780e-94
                SUM
    1            NA
    2            NA
    3            NA
    4            NA
    5 7.157273e-156
    6 7.513359e-156

This only demeans Agriculture (AGR) and Mining (MIN)

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  TRA(fselect(., AGR, MIN) %>% 
        fmean(keep.group_vars = FALSE), "-") %>% 
  head
```

      Country Regioncode             Region Variable Year       AGR       MIN
    1     BWA        SSA Sub-saharan Africa       VA 1960        NA        NA
    2     BWA        SSA Sub-saharan Africa       VA 1961        NA        NA
    3     BWA        SSA Sub-saharan Africa       VA 1962        NA        NA
    4     BWA        SSA Sub-saharan Africa       VA 1963        NA        NA
    5     BWA        SSA Sub-saharan Africa       VA 1964 -445.8739 -4505.178
    6     BWA        SSA Sub-saharan Africa       VA 1965 -446.4485 -4506.176
            MAN        PU       CON      WRT      TRA     FIRE      GOV      OTH
    1        NA        NA        NA       NA       NA       NA       NA       NA
    2        NA        NA        NA       NA       NA       NA       NA       NA
    3        NA        NA        NA       NA       NA       NA       NA       NA
    4        NA        NA        NA       NA       NA       NA       NA       NA
    5 0.7365696 0.1043936 0.6600454 6.243732 1.658928 1.119194 4.822485 2.341328
    6 1.0181992 0.1350976 1.3462312 7.064825 1.939007 1.246789 5.695848 2.678338
           SUM
    1       NA
    2       NA
    3       NA
    4       NA
    5 37.48229
    6 39.34710

`TRA` is best used in computations where grouped statistics are computed
using some other function.

Same as above, with one line of code using fmean.data.frame and
ftransform…

``` r
GGDC10S %>% 
  ftransform(fmean(list(AGR = AGR, MIN = MIN),
                   list(Variable, Country),
                   TRA = "-")) %>% 
  head
```

      Country Regioncode             Region Variable Year       AGR       MIN
    1     BWA        SSA Sub-saharan Africa       VA 1960        NA        NA
    2     BWA        SSA Sub-saharan Africa       VA 1961        NA        NA
    3     BWA        SSA Sub-saharan Africa       VA 1962        NA        NA
    4     BWA        SSA Sub-saharan Africa       VA 1963        NA        NA
    5     BWA        SSA Sub-saharan Africa       VA 1964 -445.8739 -4505.178
    6     BWA        SSA Sub-saharan Africa       VA 1965 -446.4485 -4506.176
            MAN        PU       CON      WRT      TRA     FIRE      GOV      OTH
    1        NA        NA        NA       NA       NA       NA       NA       NA
    2        NA        NA        NA       NA       NA       NA       NA       NA
    3        NA        NA        NA       NA       NA       NA       NA       NA
    4        NA        NA        NA       NA       NA       NA       NA       NA
    5 0.7365696 0.1043936 0.6600454 6.243732 1.658928 1.119194 4.822485 2.341328
    6 1.0181992 0.1350976 1.3462312 7.064825 1.939007 1.246789 5.695848 2.678338
           SUM
    1       NA
    2       NA
    3       NA
    4       NA
    5 37.48229
    6 39.34710

Another potential use of TRA is to do computations in two- or more
steps, for example if both aggregated and transformed data are needed,
or if computations are more complex and involve other manipulations
in-between the aggregating and sweeping part.

Get grouped tibble and then aggregate data

``` r
gGGDC <- GGDC10S %>% 
  fgroup_by(Variable, Country)
gsumGGDC <- gGGDC %>% 
  fselect(AGR:SUM) %>% 
  fsum
head(gsumGGDC)
```

      Variable Country         AGR         MIN          MAN         PU         CON
    1      EMP     ARG    88027.68   3229.5198  119769.1324  6306.6981   46029.075
    2      EMP     BOL    58816.83   3418.0097   14337.0257   326.1324    7489.743
    3      EMP     BRA  1065863.88  12773.4814  433464.9997 22603.5510  218533.779
    4      EMP     BWA     8838.70    492.5429     848.6251   145.3822    1191.031
    5      EMP     CHL    44220.40   6389.2975   39368.8912  1849.5898   18648.143
    6      EMP     CHN 17264654.30 422971.5973 4028618.0405 96363.8673 1251099.985
              WRT         TRA        FIRE         GOV         OTH         SUM
    1  122895.005  40207.7408  38923.1607  126695.219   61531.747   653614.98
    2   17172.499   7043.8434   2718.4295          NA   24129.467   135451.98
    3  527586.597 127371.1352 273639.7578  329051.366  354036.523  3364925.07
    4    1707.497    393.0242    720.8023    2871.927    1297.498    18507.03
    5   43763.661  16269.1752  17163.6169          NA   63216.697   250889.47
    6 1734486.397 835716.4429 295755.7846 1360154.889 1859407.116 29149228.42

Get transformed (scaled) data

``` r
head(TRA(gGGDC, gsumGGDC, "/"))
```

      Country Regioncode             Region Variable Year          AGR          MIN
    1     BWA        SSA Sub-saharan Africa       VA 1960           NA           NA
    2     BWA        SSA Sub-saharan Africa       VA 1961           NA           NA
    3     BWA        SSA Sub-saharan Africa       VA 1962           NA           NA
    4     BWA        SSA Sub-saharan Africa       VA 1963           NA           NA
    5     BWA        SSA Sub-saharan Africa       VA 1964 0.0007504538 1.648868e-05
    6     BWA        SSA Sub-saharan Africa       VA 1965 0.0007240042 1.177763e-05
               MAN           PU          CON          WRT          TRA         FIRE
    1           NA           NA           NA           NA           NA           NA
    2           NA           NA           NA           NA           NA           NA
    3           NA           NA           NA           NA           NA           NA
    4           NA           NA           NA           NA           NA           NA
    5 1.664388e-05 1.026152e-05 1.568468e-05 6.819850e-05 5.555551e-05 1.752624e-05
    6 2.300772e-05 1.327961e-05 3.199054e-05 7.716707e-05 6.493501e-05 1.952434e-05
               GOV          OTH          SUM
    1           NA           NA           NA
    2           NA           NA           NA
    3           NA           NA           NA
    4           NA           NA           NA
    5 4.324528e-05 6.445077e-05 5.651279e-05
    6 5.107711e-05 7.372777e-05 5.932439e-05

## Faster Centering, Averaging and Standardizing

The functions `fbetween` and `fwithin` are slightly more memory
efficient implementations of `fmean` invoked with different `TRA`
options

``` r
rm(GGDC10S)
```

    Warning in rm(GGDC10S): object 'GGDC10S' not found

``` r
GGDC10S <- qTBL(GGDC10S)
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fbetween %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH    SUM
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
    1 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.
    2 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.

Same as.

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fmean(TRA = "replace") %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH    SUM
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
    1 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.
    2 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fbetween(fill = TRUE) %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH    SUM
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
    1 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.
    2 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.

Same as

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fmean(TRA = "replace_fill") %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH    SUM
      <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
    1 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.
    2 4444.  34.9 1614.  131.  997. 1307.  799.  320. 2958.    NA 12605.

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fwithin %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR    MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH   SUM
      <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1  742.  -7.35  760.  187. 1798. 1713. 1249.  495. 2678.    NA 9614.
    2  717. -10.1   734.  194. 1934. 1803. 1266.  512. 2778.    NA 9928.

Same as

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  get_vars(6:16) %>% 
  fmean(TRA = "-") %>% 
  tail(2)
```

    # A tibble: 2 × 11
        AGR    MIN   MAN    PU   CON   WRT   TRA  FIRE   GOV   OTH   SUM
      <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
    1  742.  -7.35  760.  187. 1798. 1713. 1249.  495. 2678.    NA 9614.
    2  717. -10.1   734.  194. 1934. 1803. 1266.  512. 2778.    NA 9928.

Apart from higher speed, fwithin has a mean argument to assign an
arbitrary mean to centered data, the default being mean = 0. A very
common choice for such an added mean is just the overall mean of the
data, which can be added in by invoking mean = “overall.mean”:

``` r
GGDC10S %>%
  fgroup_by(Variable, Country) %>%
  fselect(Country, Variable, AGR:SUM) %>%
  fwithin(mean = "overall.mean") %>%
  tail(3)
```

    # A tibble: 3 × 13
      Country Variable      AGR      MIN      MAN     PU    CON    WRT    TRA   FIRE
      <chr>   <chr>       <dbl>    <dbl>    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
    1 EGY     EMP      2527458. 1867903. 5539313. 3.36e5 1.80e6 3.39e6 1.47e6 1.66e6
    2 EGY     EMP      2527439. 1867902. 5539251. 3.36e5 1.80e6 3.39e6 1.47e6 1.66e6
    3 EGY     EMP      2527413. 1867899. 5539226. 3.36e5 1.80e6 3.39e6 1.47e6 1.66e6
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

Use the `SUM` column as weights, for each variable and each group,
subtract weighted mean, then add overall weighted column mean back to
centered columns. `SUM` is kept as-is.

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  fselect(Country, Variable, AGR:SUM) %>% 
  fwithin(SUM, mean = "overall.mean") %>% 
  tail(3)
```

    # A tibble: 3 × 13
      Country Variable    SUM        AGR      MIN    MAN     PU    CON    WRT    TRA
      <chr>   <chr>     <dbl>      <dbl>    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
    1 EGY     EMP      22020. 429066006.   3.70e8 7.38e8 2.73e7 2.83e8 4.33e8 1.97e8
    2 EGY     EMP      22219. 429065986.   3.70e8 7.38e8 2.73e7 2.83e8 4.33e8 1.97e8
    3 EGY     EMP      22533. 429065961.   3.70e8 7.38e8 2.73e7 2.83e8 4.33e8 1.97e8
    # ℹ 3 more variables: FIRE <dbl>, GOV <dbl>, OTH <dbl>

The `theta` parameter allows partial- or quasi-demeaning operations,
e.g. fwithin(gdata, theta = theta) is equal to gdata - theta \*
fbetween(gdata). This is particularly useful to prepare data for
variance components (also known as ‘random-effects’) estimation.

`fscale` can be used to avoid sequential calls such as
`... %>% fsd(TRA = "/") %>% fmean(TRA = "-")`

``` r
GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  fselect(Country, Variable, AGR:SUM) %>% 
  fscale
```

    # A tibble: 5,027 × 13
       Country Variable    AGR    MIN    MAN     PU    CON    WRT    TRA   FIRE
     * <chr>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
     1 BWA     VA       NA     NA     NA     NA     NA     NA     NA     NA    
     2 BWA     VA       NA     NA     NA     NA     NA     NA     NA     NA    
     3 BWA     VA       NA     NA     NA     NA     NA     NA     NA     NA    
     4 BWA     VA       NA     NA     NA     NA     NA     NA     NA     NA    
     5 BWA     VA       -0.738 -0.717 -0.668 -0.805 -0.692 -0.603 -0.589 -0.635
     6 BWA     VA       -0.739 -0.717 -0.668 -0.805 -0.692 -0.603 -0.589 -0.635
     7 BWA     VA       -0.736 -0.717 -0.668 -0.805 -0.692 -0.603 -0.589 -0.635
     8 BWA     VA       -0.734 -0.717 -0.668 -0.805 -0.692 -0.604 -0.589 -0.635
     9 BWA     VA       -0.730 -0.717 -0.668 -0.805 -0.692 -0.604 -0.588 -0.635
    10 BWA     VA       -0.729 -0.716 -0.667 -0.803 -0.690 -0.603 -0.588 -0.635
    # ℹ 5,017 more rows
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

The `mean` and `sd` arguments allow scaling to an arbitrary mean and
standard deviation. `mean = FALSE` scales but preserves the means.

``` r
gGGDC <- GGDC10S %>% 
  fgroup_by(Variable, Country) %>% 
  fselect(Country, Variable, AGR:SUM)
head(fmean(gGGDC))
```

    # A tibble: 6 × 13
      Variable Country     AGR    MIN     MAN      PU     CON     WRT     TRA   FIRE
      <chr>    <chr>     <dbl>  <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>  <dbl>
    1 EMP      ARG       1420.   52.1  1932.   102.     742.   1982.   6.49e2  628. 
    2 EMP      BOL        964.   56.0   235.     5.35   123.    282.   1.15e2   44.6
    3 EMP      BRA      17191.  206.   6991.   365.    3525.   8509.   2.05e3 4414. 
    4 EMP      BWA        188.   10.5    18.1    3.09    25.3    36.3  8.36e0   15.3
    5 EMP      CHL        702.  101.    625.    29.4    296.    695.   2.58e2  272. 
    6 EMP      CHN     287744. 7050.  67144.  1606.   20852.  28908.   1.39e4 4929. 
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

Mean preserving scaling:

``` r
gGGDC %>% 
  fscale(mean = FALSE) %>% 
  fmean %>% 
  head
```

    # A tibble: 6 × 13
      Variable Country     AGR    MIN     MAN      PU     CON     WRT     TRA   FIRE
      <chr>    <chr>     <dbl>  <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>  <dbl>
    1 EMP      ARG       1420.   52.1  1932.   102.     742.   1982.   6.49e2  628. 
    2 EMP      BOL        964.   56.0   235.     5.35   123.    282.   1.15e2   44.6
    3 EMP      BRA      17191.  206.   6991.   365.    3525.   8509.   2.05e3 4414. 
    4 EMP      BWA        188.   10.5    18.1    3.09    25.3    36.3  8.36e0   15.3
    5 EMP      CHL        702.  101.    625.    29.4    296.    695.   2.58e2  272. 
    6 EMP      CHN     287744. 7050.  67144.  1606.   20852.  28908.   1.39e4 4929. 
    # ℹ 3 more variables: GOV <dbl>, OTH <dbl>, SUM <dbl>

``` r
gGGDC %>% 
  fscale(mean = FALSE) %>% 
  fsd %>% 
  head
```

    # A tibble: 6 × 13
      Variable Country   AGR   MIN   MAN    PU   CON   WRT   TRA  FIRE    GOV   OTH
      <chr>    <chr>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
    1 EMP      ARG     1.00  1.00  1.000 1.000 1.000 1.000 1.000 1.000  1.000 1.000
    2 EMP      BOL     1.00  1.000 1.00  1.00  1.000 1.00  1.00  1.00  NA     1.00 
    3 EMP      BRA     1.00  1.00  1.00  1.000 1.00  1.000 1.000 1.000  1.00  1.000
    4 EMP      BWA     1.000 1.000 1.00  1     1     1.000 1.00  1.000  1.00  1.000
    5 EMP      CHL     1.00  1     1.000 1.00  1.00  1.00  1.000 1.00  NA     1.00 
    6 EMP      CHN     1.00  1.00  1.00  1.000 1.000 1.00  1.00  1.00   1.000 1.000
    # ℹ 1 more variable: SUM <dbl>

One can also set `mean = "overall.mean"`, which group-centers columns on
the overall mean as illustrated with `fwithin` or `sd = "within.sd"`,
which group-scales data such that every group has a standard deviation
equal to the within-standard deviation of the data:

``` r
gGGDC <- GGDC10S %>%
  fsubset(Variable == "VA", Country, AGR:SUM) %>% 
      fgroup_by(Country)
```

This calculates the within- standard deviation for all columns

``` r
fwithin(gGGDC) %>% 
  ungroup %>% 
  num_vars %>% 
  fsd
```

          AGR       MIN       MAN        PU       CON       WRT       TRA      FIRE 
     45046972  40122220  75608708   3062688  30811572  44125207  20676901  16030868 
          GOV       OTH       SUM 
     20358973  18780869 306429102 

This scales all groups to take on the within- standard deviation while
preserving group means

``` r
fscale(gGGDC, mean = FALSE, sd = "within.sd") %>% 
  fsd
```

    # A tibble: 43 × 12
       Country       AGR       MIN    MAN     PU    CON    WRT    TRA   FIRE     GOV
       <chr>       <dbl>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>   <dbl>
     1 ARG     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
     2 BOL     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7 NA     
     3 BRA     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
     4 BWA     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
     5 CHL     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7 NA     
     6 CHN     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
     7 COL     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7 NA     
     8 CRI     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
     9 DEW     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
    10 DNK     45046972. 40122220. 7.56e7 3.06e6 3.08e7 4.41e7 2.07e7 1.60e7  2.04e7
    # ℹ 33 more rows
    # ℹ 2 more variables: OTH <dbl>, SUM <dbl>

## Lags/Leads, Differences, Growth Rates

- `flag`
- `fdiff`
- `fgrowth`

The following code computes 1 fully-identified panel-lag and 1 fully
identified panel-lead of each variable in the data.

``` r
GGDC10S %>% 
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  flag(-1:1, Year)
```

    # A tibble: 5,027 × 36
       Country Variable  Year F1.AGR   AGR L1.AGR F1.MIN   MIN L1.MIN F1.MAN    MAN
     * <chr>   <chr>    <dbl>  <dbl> <dbl>  <dbl>  <dbl> <dbl>  <dbl>  <dbl>  <dbl>
     1 BWA     VA        1960   NA    NA     NA    NA    NA     NA    NA     NA    
     2 BWA     VA        1961   NA    NA     NA    NA    NA     NA    NA     NA    
     3 BWA     VA        1962   NA    NA     NA    NA    NA     NA    NA     NA    
     4 BWA     VA        1963   16.3  NA     NA     3.49 NA     NA     0.737 NA    
     5 BWA     VA        1964   15.7  16.3   NA     2.50  3.49  NA     1.02   0.737
     6 BWA     VA        1965   17.7  15.7   16.3   1.97  2.50   3.49  0.804  1.02 
     7 BWA     VA        1966   19.1  17.7   15.7   2.30  1.97   2.50  0.938  0.804
     8 BWA     VA        1967   21.1  19.1   17.7   1.84  2.30   1.97  0.750  0.938
     9 BWA     VA        1968   21.9  21.1   19.1   5.24  1.84   2.30  2.14   0.750
    10 BWA     VA        1969   23.1  21.9   21.1  10.2   5.24   1.84  4.15   2.14 
    # ℹ 5,017 more rows
    # ℹ 25 more variables: L1.MAN <dbl>, F1.PU <dbl>, PU <dbl>, L1.PU <dbl>,
    #   F1.CON <dbl>, CON <dbl>, L1.CON <dbl>, F1.WRT <dbl>, WRT <dbl>,
    #   L1.WRT <dbl>, F1.TRA <dbl>, TRA <dbl>, L1.TRA <dbl>, F1.FIRE <dbl>,
    #   FIRE <dbl>, L1.FIRE <dbl>, F1.GOV <dbl>, GOV <dbl>, L1.GOV <dbl>,
    #   F1.OTH <dbl>, OTH <dbl>, L1.OTH <dbl>, F1.SUM <dbl>, SUM <dbl>,
    #   L1.SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

It is also possible to omit the time-variable if one is certain that the
data is sorted:

``` r
GGDC10S %>%
  fselect(Variable, Country,AGR:SUM) %>%
  fgroup_by(Variable, Country) %>% 
  flag
```

    # A tibble: 5,027 × 13
       Variable Country   AGR   MIN    MAN     PU    CON   WRT   TRA  FIRE   GOV
     * <chr>    <chr>   <dbl> <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
     1 VA       BWA      NA   NA    NA     NA     NA     NA    NA    NA    NA   
     2 VA       BWA      NA   NA    NA     NA     NA     NA    NA    NA    NA   
     3 VA       BWA      NA   NA    NA     NA     NA     NA    NA    NA    NA   
     4 VA       BWA      NA   NA    NA     NA     NA     NA    NA    NA    NA   
     5 VA       BWA      NA   NA    NA     NA     NA     NA    NA    NA    NA   
     6 VA       BWA      16.3  3.49  0.737  0.104  0.660  6.24  1.66  1.12  4.82
     7 VA       BWA      15.7  2.50  1.02   0.135  1.35   7.06  1.94  1.25  5.70
     8 VA       BWA      17.7  1.97  0.804  0.203  1.35   8.27  2.15  1.36  6.37
     9 VA       BWA      19.1  2.30  0.938  0.203  0.897  4.31  1.72  1.54  7.04
    10 VA       BWA      21.1  1.84  0.750  0.203  1.22   5.17  2.44  1.03  5.03
    # ℹ 5,017 more rows
    # ℹ 2 more variables: OTH <dbl>, SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

`fdiff` computes sequences of lagged-leaded and iterated differences as
well as quasi-differences and log-differences on time series and panel
data. The code below computes the 1 and 10 year first and second
differences of each variable in the data:

``` r
GGDC10S %>% 
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  fdiff(c(1, 10), 1:2, Year)
```

    # A tibble: 5,027 × 47
       Country Variable  Year D1.AGR D2.AGR L10D1.AGR L10D2.AGR D1.MIN D2.MIN
     * <chr>   <chr>    <dbl>  <dbl>  <dbl>     <dbl>     <dbl>  <dbl>  <dbl>
     1 BWA     VA        1960 NA     NA            NA        NA NA     NA    
     2 BWA     VA        1961 NA     NA            NA        NA NA     NA    
     3 BWA     VA        1962 NA     NA            NA        NA NA     NA    
     4 BWA     VA        1963 NA     NA            NA        NA NA     NA    
     5 BWA     VA        1964 NA     NA            NA        NA NA     NA    
     6 BWA     VA        1965 -0.575 NA            NA        NA -0.998 NA    
     7 BWA     VA        1966  1.95   2.53         NA        NA -0.525  0.473
     8 BWA     VA        1967  1.47  -0.488        NA        NA  0.328  0.854
     9 BWA     VA        1968  1.95   0.488        NA        NA -0.460 -0.788
    10 BWA     VA        1969  0.763 -1.19         NA        NA  3.41   3.87 
    # ℹ 5,017 more rows
    # ℹ 38 more variables: L10D1.MIN <dbl>, L10D2.MIN <dbl>, D1.MAN <dbl>,
    #   D2.MAN <dbl>, L10D1.MAN <dbl>, L10D2.MAN <dbl>, D1.PU <dbl>, D2.PU <dbl>,
    #   L10D1.PU <dbl>, L10D2.PU <dbl>, D1.CON <dbl>, D2.CON <dbl>,
    #   L10D1.CON <dbl>, L10D2.CON <dbl>, D1.WRT <dbl>, D2.WRT <dbl>,
    #   L10D1.WRT <dbl>, L10D2.WRT <dbl>, D1.TRA <dbl>, D2.TRA <dbl>,
    #   L10D1.TRA <dbl>, L10D2.TRA <dbl>, D1.FIRE <dbl>, D2.FIRE <dbl>, …

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

Log-differences of the form $\log(x_t)−\log(x_{t−s})$ are also easily
computed.

``` r
GGDC10S %>% 
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  fdiff(c(1, 10), 1, Year, log = TRUE)
```

    Warning in FUN(X[[i]], ...): NaNs produced

    # A tibble: 5,027 × 25
       Country Variable  Year Dlog1.AGR L10Dlog1.AGR Dlog1.MIN L10Dlog1.MIN
     * <chr>   <chr>    <dbl>     <dbl>        <dbl>     <dbl>        <dbl>
     1 BWA     VA        1960   NA                NA    NA               NA
     2 BWA     VA        1961   NA                NA    NA               NA
     3 BWA     VA        1962   NA                NA    NA               NA
     4 BWA     VA        1963   NA                NA    NA               NA
     5 BWA     VA        1964   NA                NA    NA               NA
     6 BWA     VA        1965   -0.0359           NA    -0.336           NA
     7 BWA     VA        1966    0.117            NA    -0.236           NA
     8 BWA     VA        1967    0.0796           NA     0.154           NA
     9 BWA     VA        1968    0.0972           NA    -0.223           NA
    10 BWA     VA        1969    0.0355           NA     1.05            NA
    # ℹ 5,017 more rows
    # ℹ 18 more variables: Dlog1.MAN <dbl>, L10Dlog1.MAN <dbl>, Dlog1.PU <dbl>,
    #   L10Dlog1.PU <dbl>, Dlog1.CON <dbl>, L10Dlog1.CON <dbl>, Dlog1.WRT <dbl>,
    #   L10Dlog1.WRT <dbl>, Dlog1.TRA <dbl>, L10Dlog1.TRA <dbl>, Dlog1.FIRE <dbl>,
    #   L10Dlog1.FIRE <dbl>, Dlog1.GOV <dbl>, L10Dlog1.GOV <dbl>, Dlog1.OTH <dbl>,
    #   L10Dlog1.OTH <dbl>, Dlog1.SUM <dbl>, L10Dlog1.SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

Finally, it is also possible to compute quasi-differences and
quasi-log-differences of the form $x_t−\rho x_{t−s}$ or
$\log(x_t)−\rho \log(x_{t−s})$.

``` r
GGDC10S %>%
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  fdiff(t = Year, rho = 0.95)
```

    # A tibble: 5,027 × 14
       Country Variable  Year    AGR    MIN    MAN      PU     CON    WRT    TRA
     * <chr>   <chr>    <dbl>  <dbl>  <dbl>  <dbl>   <dbl>   <dbl>  <dbl>  <dbl>
     1 BWA     VA        1960 NA     NA     NA     NA      NA      NA     NA    
     2 BWA     VA        1961 NA     NA     NA     NA      NA      NA     NA    
     3 BWA     VA        1962 NA     NA     NA     NA      NA      NA     NA    
     4 BWA     VA        1963 NA     NA     NA     NA      NA      NA     NA    
     5 BWA     VA        1964 NA     NA     NA     NA      NA      NA     NA    
     6 BWA     VA        1965  0.241 -0.824  0.318  0.0359  0.719   1.13   0.363
     7 BWA     VA        1966  2.74  -0.401 -0.163  0.0743  0.0673  1.56   0.312
     8 BWA     VA        1967  2.35   0.427  0.174  0.0101 -0.381  -3.55  -0.323
     9 BWA     VA        1968  2.91  -0.345 -0.141  0.0101  0.365   1.08   0.804
    10 BWA     VA        1969  1.82   3.50   1.43   0.385   2.32    0.841  0.397
    # ℹ 5,017 more rows
    # ℹ 4 more variables: FIRE <dbl>, GOV <dbl>, OTH <dbl>, SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

Finally, `fgrowth` computes growth rates in the same way. By default
exact growth rates are computed in percentage terms using
$(x_t−x_{t−s})/x_{t−s} \times 100$ (the default argument is
`scale = 100`). The user can also request growth rates obtained by
log-differencing using $\log(x_t/x_{t−s})×100$.

``` r
GGDC10S %>% 
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  fgrowth(c(1, 10), 1, Year)
```

    # A tibble: 5,027 × 25
       Country Variable  Year G1.AGR L10G1.AGR G1.MIN L10G1.MIN G1.MAN L10G1.MAN
     * <chr>   <chr>    <dbl>  <dbl>     <dbl>  <dbl>     <dbl>  <dbl>     <dbl>
     1 BWA     VA        1960  NA           NA   NA          NA   NA          NA
     2 BWA     VA        1961  NA           NA   NA          NA   NA          NA
     3 BWA     VA        1962  NA           NA   NA          NA   NA          NA
     4 BWA     VA        1963  NA           NA   NA          NA   NA          NA
     5 BWA     VA        1964  NA           NA   NA          NA   NA          NA
     6 BWA     VA        1965  -3.52        NA  -28.6        NA   38.2        NA
     7 BWA     VA        1966  12.4         NA  -21.1        NA  -21.1        NA
     8 BWA     VA        1967   8.29        NA   16.7        NA   16.7        NA
     9 BWA     VA        1968  10.2         NA  -20          NA  -20          NA
    10 BWA     VA        1969   3.61        NA  185.         NA  185.         NA
    # ℹ 5,017 more rows
    # ℹ 16 more variables: G1.PU <dbl>, L10G1.PU <dbl>, G1.CON <dbl>,
    #   L10G1.CON <dbl>, G1.WRT <dbl>, L10G1.WRT <dbl>, G1.TRA <dbl>,
    #   L10G1.TRA <dbl>, G1.FIRE <dbl>, L10G1.FIRE <dbl>, G1.GOV <dbl>,
    #   L10G1.GOV <dbl>, G1.OTH <dbl>, L10G1.OTH <dbl>, G1.SUM <dbl>,
    #   L10G1.SUM <dbl>

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

This computes the 1 and 10-year growth rates, for the current period and
lagged by one period

``` r
GGDC10S %>% 
  fselect(-Region, -Regioncode) %>% 
  fgroup_by(Variable, Country) %>% 
  fgrowth(c(1, 10), 1, Year) %>% 
  flag(0:1, Year)
```

    # A tibble: 5,027 × 47
       Country Variable  Year G1.AGR L1.G1.AGR L10G1.AGR L1.L10G1.AGR G1.MIN
     * <chr>   <chr>    <dbl>  <dbl>     <dbl>     <dbl>        <dbl>  <dbl>
     1 BWA     VA        1960  NA        NA           NA           NA   NA  
     2 BWA     VA        1961  NA        NA           NA           NA   NA  
     3 BWA     VA        1962  NA        NA           NA           NA   NA  
     4 BWA     VA        1963  NA        NA           NA           NA   NA  
     5 BWA     VA        1964  NA        NA           NA           NA   NA  
     6 BWA     VA        1965  -3.52     NA           NA           NA  -28.6
     7 BWA     VA        1966  12.4      -3.52        NA           NA  -21.1
     8 BWA     VA        1967   8.29     12.4         NA           NA   16.7
     9 BWA     VA        1968  10.2       8.29        NA           NA  -20  
    10 BWA     VA        1969   3.61     10.2         NA           NA  185. 
    # ℹ 5,017 more rows
    # ℹ 39 more variables: L1.G1.MIN <dbl>, L10G1.MIN <dbl>, L1.L10G1.MIN <dbl>,
    #   G1.MAN <dbl>, L1.G1.MAN <dbl>, L10G1.MAN <dbl>, L1.L10G1.MAN <dbl>,
    #   G1.PU <dbl>, L1.G1.PU <dbl>, L10G1.PU <dbl>, L1.L10G1.PU <dbl>,
    #   G1.CON <dbl>, L1.G1.CON <dbl>, L10G1.CON <dbl>, L1.L10G1.CON <dbl>,
    #   G1.WRT <dbl>, L1.G1.WRT <dbl>, L10G1.WRT <dbl>, L1.L10G1.WRT <dbl>,
    #   G1.TRA <dbl>, L1.G1.TRA <dbl>, L10G1.TRA <dbl>, L1.L10G1.TRA <dbl>, …

    Grouped by:  Variable, Country  [85 | 59 (7.7) 4-65] 

# Benchmarking

## Data

``` r
rm(GGDC10S)
GRP(GGDC10S, ~ Variable + Country)
```

    collapse grouping object of length 5027 with 85 ordered groups

    Call: GRP.default(X = GGDC10S, by = ~Variable + Country), X is unsorted

    Distribution of group sizes: 
       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
       4.00   53.00   62.00   59.14   63.00   65.00 

    Groups with sizes: 
    EMP.ARG EMP.BOL EMP.BRA EMP.BWA EMP.CHL EMP.CHN 
         62      61      62      52      63      62 
      ---
    VA.TWN VA.TZA VA.USA VA.VEN VA.ZAF VA.ZMB 
        63     52     65     63     52     52 

``` r
data <- replicate(200, GGDC10S, simplify = FALSE)
uniquify <- function(x, i) ftransform(x, 
                                      lapply(unclass(x)[c(1,4)], paste0, i))
data <- unlist2d(Map(uniquify, data,
                     as.list(1:200)),
                 idcols = FALSE)
fdim(data)
```

    [1] 1005400      16

``` r
GRP(data, ~ Variable + Country)
```

    collapse grouping object of length 1005400 with 17000 ordered groups

    Call: GRP.default(X = data, by = ~Variable + Country), X is unsorted

    Distribution of group sizes: 
       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
       4.00   53.00   62.00   59.14   63.00   65.00 

    Groups with sizes: 
    EMP1.ARG1 EMP1.BOL1 EMP1.BRA1 EMP1.BWA1 EMP1.CHL1 EMP1.CHN1 
           62        61        62        52        63        62 
      ---
    VA99.TWN99 VA99.TZA99 VA99.USA99 VA99.VEN99 VA99.ZAF99 VA99.ZMB99 
            63         52         65         63         52         52 

``` r
gc()
```

               used  (Mb) gc trigger  (Mb) max used  (Mb)
    Ncells  2079759 111.1    3164780 169.1  3164780 169.1
    Vcells 20988598 160.2   28394414 216.7 23129056 176.5

## Selecting, Subsetting, Ordering and Grouping

``` r
microbenchmark(dplyr = select(GGDC10S, Country, Variable, AGR:SUM),
               collapse = fselect(GGDC10S, Country, Variable, AGR:SUM))
```

    Unit: microseconds
         expr     min      lq      mean  median      uq      max neval cld
        dplyr 642.437 670.880 696.66217 686.904 717.080 1045.385   100  a 
     collapse   4.222   5.144   8.15071   7.129  11.129   19.163   100   b

``` r
microbenchmark(dplyr = select(data, Country, Variable, AGR:SUM),
               collapse = fselect(data, Country, Variable, AGR:SUM))
```

    Unit: microseconds
         expr     min       lq      mean   median       uq      max neval cld
        dplyr 645.268 668.8025 692.17200 680.7665 698.3400 1085.684   100  a 
     collapse   4.208   5.4515   8.58433   8.9190  11.0865   27.588   100   b

``` r
microbenchmark(dplyr = filter(GGDC10S, Variable == "VA"),
               collapse = fsubset(GGDC10S, Variable == "VA"))
```

    Unit: microseconds
         expr     min       lq      mean   median       uq     max neval cld
        dplyr 540.285 580.8885 639.46423 650.7910 674.3330 896.196   100  a 
     collapse  50.380  57.6770  92.69361 107.2415 120.4095 164.400   100   b

``` r
microbenchmark(dplyr = filter(data, Variable == "VA"),
               collapse = fsubset(data, Variable == "VA"))
```

    Unit: milliseconds
         expr      min       lq     mean   median       uq       max neval cld
        dplyr 5.235396 5.400365 6.262462 5.538993 6.671922 13.840272   100  a 
     collapse 2.534294 2.655807 3.116559 2.708786 3.391967  5.921456   100   b

``` r
microbenchmark(dplyr = arrange(GGDC10S, desc(Country), Variable, Year),
               collapse = roworder(GGDC10S, -Country, Variable, Year))
```

    Unit: microseconds
         expr      min       lq      mean    median        uq      max neval cld
        dplyr 2833.331 3015.159 3193.8667 3078.0640 3195.8155 6565.475   100  a 
     collapse  254.799  269.191  291.1893  282.9005  297.7915  434.800   100   b

``` r
microbenchmark(dplyr = arrange(data, desc(Country), Variable, Year),
               collapse = roworder(data, -Country, Variable, Year), times = 2)
```

    Unit: milliseconds
         expr     min      lq     mean   median       uq      max neval cld
        dplyr 264.821 264.821 271.9431 271.9431 279.0651 279.0651     2  a 
     collapse 191.062 191.062 191.4572 191.4572 191.8525 191.8525     2   b

``` r
microbenchmark(dplyr = group_by(GGDC10S, Country, Variable),
               collapse = fgroup_by(GGDC10S, Country, Variable))
```

    Unit: microseconds
         expr      min        lq      mean    median        uq      max neval cld
        dplyr 1446.735 1516.5175 1583.1669 1550.6920 1577.8475 4206.099   100  a 
     collapse  184.609  199.3925  212.3663  211.8235  222.8135  388.269   100   b

``` r
microbenchmark(dplyr = group_by(data, Country, Variable),
               collapse = fgroup_by(data, Country, Variable), times = 10)
```

    Unit: milliseconds
         expr       min        lq      mean    median        uq      max neval cld
        dplyr 101.08177 102.52067 106.62963 108.14731 109.33148 111.5676    10  a 
     collapse  38.29142  38.57819  39.20874  38.97186  39.77021  40.6200    10   b

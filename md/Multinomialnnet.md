# Multinomial Regression nnet


[Source](https://stats.oarc.ucla.edu/r/dae/multinomial-logistic-regression/)

``` r
library(foreign)
library(nnet)
library(ggplot2)
library(reshape2)
library(data.table)
```

# Sample data

``` r
ml <- read.dta("https://stats.idre.ucla.edu/stat/data/hsbdemo.dta")
```

The data set contains variables on 200 students. The outcome variable is
prog, program type. The predictor variables are social economic status,
ses, a three-level categorical variable and writing score, write, a
continuous variable.

``` r
with(ml, table(ses, prog))
```

            prog
    ses      general academic vocation
      low         16       19       12
      middle      20       44       31
      high         9       42        7

``` r
with(ml, 
     do.call(rbind,
             tapply(write, prog,
                    function(x) c(M = mean(x), SD = sd(x)))))
```

                    M       SD
    general  51.33333 9.397775
    academic 56.25714 7.943343
    vocation 46.76000 9.318754

``` r
library(tidyverse)
ml %>% 
  group_by(prog) %>% 
  summarise(
    M = mean(write),
    SD = sd(write)
  )
```

    # A tibble: 3 × 3
      prog         M    SD
      <fct>    <dbl> <dbl>
    1 general   51.3  9.40
    2 academic  56.3  7.94
    3 vocation  46.8  9.32

``` r
ml_dt <- as.data.table(ml)

ml_dt[, .(
  M = mean(write),
  SD = sd(write)
),
keyby = .(prog)
]
```

    Key: <prog>
           prog        M       SD
         <fctr>    <num>    <num>
    1:  general 51.33333 9.397775
    2: academic 56.25714 7.943343
    3: vocation 46.76000 9.318754

# Multinomial logistic regression

First, we need to choose the level of our outcome that we wish to use as
our baseline and specify this in the relevel function. Then, we run our
model using multinom. The multinom package does not include p-value
calculation for the regression coefficients, so we calculate p-values
using Wald tests (here z-tests).

``` r
ml <- ml_dt
ml$prog2 <- relevel(ml$prog, ref = "academic")
(test <- multinom(prog2 ~ ses + write,
                 data = ml))
```

    # weights:  15 (8 variable)
    initial  value 219.722458 
    iter  10 value 179.982880
    final  value 179.981726 
    converged

    Call:
    multinom(formula = prog2 ~ ses + write, data = ml)

    Coefficients:
             (Intercept)  sesmiddle    seshigh      write
    general     2.852198 -0.5332810 -1.1628226 -0.0579287
    vocation    5.218260  0.2913859 -0.9826649 -0.1136037

    Residual Deviance: 359.9635 
    AIC: 375.9635 

The final negative log-likelihood is 179.981726. The Residual Deviance
is twice this amount

``` r
summary(test)
```

    Call:
    multinom(formula = prog2 ~ ses + write, data = ml)

    Coefficients:
             (Intercept)  sesmiddle    seshigh      write
    general     2.852198 -0.5332810 -1.1628226 -0.0579287
    vocation    5.218260  0.2913859 -0.9826649 -0.1136037

    Std. Errors:
             (Intercept) sesmiddle   seshigh      write
    general     1.166441 0.4437323 0.5142196 0.02141097
    vocation    1.163552 0.4763739 0.5955665 0.02221996

    Residual Deviance: 359.9635 
    AIC: 375.9635 

``` r
(z <- 
  summary(test)$coefficients/
  summary(test)$standard.errors)
```

             (Intercept)  sesmiddle   seshigh     write
    general     2.445214 -1.2018081 -2.261334 -2.705562
    vocation    4.484769  0.6116747 -1.649967 -5.112689

2-tailed z test

``` r
(p <- (1 - pnorm(abs(z), 0, 1)) * 2)
```

              (Intercept) sesmiddle    seshigh        write
    general  0.0144766100 0.2294379 0.02373856 6.818902e-03
    vocation 0.0000072993 0.5407530 0.09894976 3.176045e-07

The two model equations are:

$$ln\left(\frac{P(prog=general)}{P(prog=academic)}\right) = b_{10} + b_{11}(ses=2) + b_{12}(ses=3) + b_{13}write$$

$$ln\left(\frac{P(prog=vocation)}{P(prog=academic)}\right) = b_{20} + b_{21}(ses=2) + b_{22}(ses=3) + b_{23}write$$

- $b_{13}$ A one-unit increase in the variable `write` is associated
  with the decrease in the log odds of being in general program
  vs. academic program in the amount of .058 .
- $b_{23}$ A one-unit increase in the variable `write` is associated
  with the decrease in the log odds of being in vocation program
  vs. academic program. in the amount of .1136 .
- $b_{12}$ The log odds of being in general program vs. in academic
  program will decrease by 1.163 if moving from `ses="low"` to
  `ses="high"`.
- $b_{11}$ The log odds of being in general program vs. in academic
  program will decrease by 0.533 if moving from `ses="low"` to
  `ses="middle"`, although this coefficient is not significant.
- $b_{22}$ The log odds of being in vocation program vs. in academic
  program will decrease by 0.983 if moving from `ses="low"` to
  `ses="high"`.
- $b_{21}$ The log odds of being in vocation program vs. in academic
  program will increase by 0.291 if moving from `ses="low"` to
  `ses="middle"`, although this coefficient is not significant.

The relative risk, sometimes called odds, is the ratio of the
probability of choosing one outcome category over the probability of
choosing the baseline category. It is the exponentiated linear equation.
The exponentiated regression coefficients are relative risk ratios for a
unit change in the predictor variable.

``` r
exp(coef(test))
```

             (Intercept) sesmiddle   seshigh     write
    general     17.32582 0.5866769 0.3126026 0.9437172
    vocation   184.61262 1.3382809 0.3743123 0.8926116

- The relative risk ratio for a one-unit increase in the variable write
  is .9437 for being in general program vs. academic program.
- The relative risk ratio switching from ses = 1 to 3 is .3126 for being
  in general program vs. academic program.

Calculate predicted probabilities for each outcome level. First,
generate the predicted probabilities for the observations in the
dataset.

``` r
head(pp <- fitted(test))
```

       academic   general  vocation
    1 0.1482764 0.3382454 0.5134781
    2 0.1202017 0.1806283 0.6991700
    3 0.4186747 0.2368082 0.3445171
    4 0.1726885 0.3508384 0.4764731
    5 0.1001231 0.1689374 0.7309395
    6 0.3533566 0.2377976 0.4088458

To look at one variable, while holding the other constant. First, hold
`write` at its mean and examine the levels of `ses`.

``` r
d_ses <- data.table(
  ses = c("low", "middle", "high"),
  write = mean(ml$write)
)
predict(test, newdata = d_ses, "probs")
```

       academic   general  vocation
    1 0.4396845 0.3581917 0.2021238
    2 0.4777488 0.2283353 0.2939159
    3 0.7009007 0.1784939 0.1206054

Consider the averaged predicted probabilities for different values of
`write` within each `ses` level.

``` r
d_write <- data.table(
  ses = rep(c("low", "middle", "high"),
            each = 41),
  write = rep(c(30:70), 3)
)
pp_write <- cbind(
  d_write,
  predict(test, newdata = d_write,
          type = "probs", se = T)
)

by(pp_write[, 3:5], pp_write$ses, colMeans)
```

    pp_write$ses: high
     academic   general  vocation 
    0.6164315 0.1808037 0.2027648 
    ------------------------------------------------------------ 
    pp_write$ses: low
     academic   general  vocation 
    0.3972977 0.3278174 0.2748849 
    ------------------------------------------------------------ 
    pp_write$ses: middle
     academic   general  vocation 
    0.4256198 0.2010864 0.3732938 

``` r
pp_write[, .(mean(academic),
             mean(general),
             mean(vocation)),
         keyby = ses]
```

    Key: <ses>
          ses        V1        V2        V3
       <char>     <num>     <num>     <num>
    1:   high 0.6164315 0.1808037 0.2027648
    2:    low 0.3972977 0.3278174 0.2748849
    3: middle 0.4256198 0.2010864 0.3732938

Plot the predicted probabilities against writing score by `ses` level.

``` r
head(lpp <- melt(
  pp_write,
  id.vars = c("ses", "write"),
  value.name = "probability"
))
```

          ses write variable probability
       <char> <int>   <fctr>       <num>
    1:    low    30 academic  0.09843588
    2:    low    31 academic  0.10716868
    3:    low    32 academic  0.11650390
    4:    low    33 academic  0.12645834
    5:    low    34 academic  0.13704576
    6:    low    35 academic  0.14827643

``` r
lpp %>% 
  ggplot(
    aes(x = write, y = probability, colour = ses)
  ) +
  geom_line() +
  facet_grid(variable ~ .,
             scales = "free")
```

![](Multinomialnnet_files/figure-commonmark/multinom-nnet-1.png)

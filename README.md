estatusbar
================
Petar Mimica

Register Task Progress, Display Statusbar, Estimate Time of Completion
======================================================================

Introduction
------------

This is an R port of a Fortran module that was used in the [astrophysical codes SPEV and MRGENESIS](https://arxiv.org/pdf/1603.05832.pdf). You can register the task completion fraction as it progresses and display a progress/status bar. The package uses several algorithms to estimate the time of completion.

The best way to install this package directly from my GitHub page:

``` r
devtools::install_github("petarmimica/estatusbar")
```

Basic usage
-----------

The idea is that you start performing some task, and then periodically add entries about the fraction of that task that has been completed. `estatusbar` will automatically add time stamps.

First, an `estatusbar` object is created:

``` r
est <- estatusbar$new()
```

To add an entry after 15 percent of the task has been completed you can use:

``` r
est$add(0.15)
```

`estatusbar` also allows you to display the current status and also to estimate when the task will be complete.

``` r
est$display()
```

    ## 
                                                                                    
    |=====>                                  | (15%) ETA: 2017-10-25 12:51:48

The `display` routine is configurable. The width can be adjusted:

``` r
est$display(width=20)
```

    ## 
                                                              
    |==>                 | (15%) ETA: 2017-10-25 12:51:48

Also, a custom text string can be provided:

``` r
est$display(text = "Working...")
```

    ## 
                                                                                                
    |=====>                                  | Working... (15%) ETA: 2017-10-25 12:51:48

The percentage can be hidden, as well as the ETA:

``` r
est$display(perc = FALSE)
```

    ## 
                                                                             
    |=====>                                  | ETA: 2017-10-25 12:51:48

``` r
est$display(eta = FALSE)
```

    ## 
                                                        
    |=====>                                  | (15%)

Examples
========

Example 1
---------

In the first example, the status bar is registered, and then 20 entries are added. Before each add the system sleeps for a random time interval (between 0 and 2 seconds). Afterward an entry is registered and the display is updated.

``` r
est <- estatusbar$new()
for (i in 1:20) {
   Sys.sleep(2 * runif(1))
   est$add(i / 20)
   est$display()
}
```

    ## 
                                                                                    
    |=>                                      | (05%) ETA: 2017-10-25 12:51:49
                                                                                    
    |===>                                    | (10%) ETA: 2017-10-25 12:53:02
                                                                                    
    |=====>                                  | (15%) ETA: 2017-10-25 12:54:27
                                                                                    
    |=======>                                | (20%) ETA: 2017-10-25 12:52:24
                                                                                    
    |=========>                              | (25%) ETA: 2017-10-25 12:52:22
                                                                                    
    |===========>                            | (30%) ETA: 2017-10-25 12:52:15
                                                                                    
    |=============>                          | (35%) ETA: 2017-10-25 12:52:13
                                                                                    
    |===============>                        | (40%) ETA: 2017-10-25 12:52:14
                                                                                    
    |=================>                      | (45%) ETA: 2017-10-25 12:52:15
                                                                                    
    |===================>                    | (50%) ETA: 2017-10-25 12:52:14
                                                                                    
    |=====================>                  | (55%) ETA: 2017-10-25 12:52:14
                                                                                    
    |=======================>                | (60%) ETA: 2017-10-25 12:52:14
                                                                                    
    |=========================>              | (65%) ETA: 2017-10-25 12:52:13
                                                                                    
    |===========================>            | (70%) ETA: 2017-10-25 12:52:13
                                                                                    
    |=============================>          | (75%) ETA: 2017-10-25 12:52:12
                                                                                    
    |===============================>        | (80%) ETA: 2017-10-25 12:52:11
                                                                                    
    |=================================>      | (85%) ETA: 2017-10-25 12:52:10
                                                                                    
    |===================================>    | (90%) ETA: 2017-10-25 12:52:09
                                                                                    
    |=====================================>  | (95%) ETA: 2017-10-25 12:52:09
                                                                                     
    |=======================================>| (100%) ETA: 2017-10-25 12:52:09

``` r
Sys.time()
```

    ## [1] "2017-10-25 12:52:09 CEST"

If this were run in terminal, the statusbar would be animated. As can be seen, the time estimate varies considerable at the early times, but after 55% of the task has been completed it is quite close to the final value, shown by calling `Sys.time()`.

Example 2
---------

In this example the user supplied text is used instead of the percentage display to show progress.

``` r
est <- estatusbar$new()
for (i in 1:10) {
   Sys.sleep(5 * runif(1))
   est$add(i / 10)
   my.text <- paste0(formatC(i, width=2, flag="0"), "/", "10", collapse="")
   est$display(text=my.text, perc=FALSE)
}
```

    ## 
                                                                                    
    |===>                                    | 01/10 ETA: 2017-10-25 12:52:09
                                                                                    
    |=======>                                | 02/10 ETA: 2017-10-25 12:54:16
                                                                                    
    |===========>                            | 03/10 ETA: 2017-10-25 12:52:46
                                                                                    
    |===============>                        | 04/10 ETA: 2017-10-25 12:52:37
                                                                                    
    |===================>                    | 05/10 ETA: 2017-10-25 12:52:34
                                                                                    
    |=======================>                | 06/10 ETA: 2017-10-25 12:52:34
                                                                                    
    |===========================>            | 07/10 ETA: 2017-10-25 12:52:32
                                                                                    
    |===============================>        | 08/10 ETA: 2017-10-25 12:52:31
                                                                                    
    |===================================>    | 09/10 ETA: 2017-10-25 12:52:31
                                                                                    
    |=======================================>| 10/10 ETA: 2017-10-25 12:52:33

``` r
Sys.time()
```

    ## [1] "2017-10-25 12:52:33 CEST"

Estimators
==========

Currently only two algorithms are implemented.

First-last
----------

The first algorithm takes the last known entry and uses its time *T* and its fraction *f* to estimate the total duration (*T*(1)), assuming the following model:
*T*(*f*)=*T*(1)\**f*<sup>*α*</sup>
 It is easy to compute *T*(1) (or any *T*) from the preceding equation. In the current implementation *α* takes values 1 and 2/

Linear fit
----------

The second algorithm performs a linear fit on the last *n* points and uses that model to predict the total duration or any other desired value:
*T*(*f*)=*A* + *B* \* *f*
 Currently *n* is either equal to 5 or to the total number of points so far.

This means that currently we are using 4 estimators for the total time.

Voting
------

When a new entry is added, the prediction of each estimator for that entry's time is recored. This information is then used when estimating the total time. Assuming that so far *n* entries have been recorded, for each estimator *j* we define its weight as:
$$ w\_j = 1 / \\sum\_{i=1}^n (T\_i - P\_j(f\_i) )^2 $$
 where *P*<sub>*j*</sub>(*f*<sub>*i*</sub>) is the model prediction of the estimator *j* for the fracton *f*<sub>*i*</sub>. The final prediction is computed as:
$$ T\_{pred} = (\\sum\_{j=1}^{N\_{est}} w\_j P\_j(1)) / \\sum\_{j=1}^{N\_{est}} w\_j $$
 where *P*<sub>*j*</sub>(1) is the current prediction for the total time of the estimator *j*. *N*<sub>*e**s**t*</sub> is the total number of estimators.

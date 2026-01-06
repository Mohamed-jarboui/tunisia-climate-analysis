options(timeout = 300, repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c("tidyverse","lubridate","scales","patchwork","here","knitr","gt")
pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]

install.packages(pkgs, dependencies = TRUE)

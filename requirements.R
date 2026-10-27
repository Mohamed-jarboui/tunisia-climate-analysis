# Install the R packages used by the analysis and the report
pkgs <- c("tidyverse", "lubridate", "here", "patchwork", "scales", "knitr", "rmarkdown", "stringi")
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

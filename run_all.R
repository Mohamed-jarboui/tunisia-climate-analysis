# ==============================================================================
# Tunisia Climate Analysis - run the whole pipeline
# ==============================================================================
# Usage (from the project root):
#   Rscript run_all.R        then        quarto render
# ==============================================================================

steps <- c(
  "scripts/01_data_loading.R",
  "scripts/02_data_cleaning.R",
  "scripts/03_eda.R",
  "scripts/04_visualizations.R"
)

raw_files <- file.path("data", "raw", c("bizerte.csv", "sousse.csv", "kef.csv"))
missing <- raw_files[!file.exists(raw_files)]
if (length(missing) > 0) stop("Missing data files: ", paste(missing, collapse = ", "))

start <- Sys.time()
for (step in steps) {
  cat("\n==> ", step, "\n", sep = "")
  source(step, local = new.env(), echo = FALSE)
}

cat(sprintf("\nPipeline finished in %.1f s.\n", as.numeric(difftime(Sys.time(), start, units = "secs"))))
cat("Figures: output/figures/   Tables: output/tables/\n")
cat("Build the website with: quarto render\n")

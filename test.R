# ==============================================================================
# Tunisia Climate Capstone - MASTER EXECUTION SCRIPT
# ==============================================================================
# Purpose: Run the entire analysis pipeline with one command
# Usage: Rscript run_all.R  OR  source("run_all.R") in RStudio
# ==============================================================================

cat("
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║           TUNISIA CLIMATE CAPSTONE PROJECT - MASTER SCRIPT                   ║
║                                                                              ║
║                Running Complete Analysis Pipeline...                         ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
\n")

# ==============================================================================
# STEP 0: CHECK PREREQUISITES
# ==============================================================================
cat("\n📋 Step 0: Checking prerequisites...\n")
cat("=" , rep("=", 70), "\n", sep = "")

# Check required packages
required_packages <- c("tidyverse", "lubridate", "here", "gt", "patchwork", 
                       "scales", "viridis")

missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("❌ Missing packages detected:", paste(missing_packages, collapse = ", "), "\n")
  cat("\n📦 Installing missing packages...\n")
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
  cat("✅ Packages installed!\n")
} else {
  cat("✅ All required packages are installed!\n")
}

# Check for data files
if (!file.exists(here::here("data", "raw", "bizerte.csv")) ||
    !file.exists(here::here("data", "raw", "sousse.csv")) ||
    !file.exists(here::here("data", "raw", "kef.csv"))) {
  cat("\n❌ ERROR: Data files not found in data/raw/\n")
  cat("   Please ensure you have:\n")
  cat("   - data/raw/bizerte.csv\n")
  cat("   - data/raw/sousse.csv\n")
  cat("   - data/raw/kef.csv\n")
  stop("Data files missing. Execution stopped.")
}

cat("✅ Data files found!\n")

# Create output directories if they don't exist
dir.create(here::here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# STEP 1: DATA LOADING
# ==============================================================================
cat("\n📥 Step 1: Loading data...\n")
cat("=" , rep("=", 70), "\n", sep = "")

start_time <- Sys.time()

tryCatch({
  source(here::here("scripts", "01_data_loading.R"))
  cat("✅ Data loading completed successfully!\n")
}, error = function(e) {
  cat("❌ ERROR in data loading:\n")
  print(e)
  stop("Data loading failed. Execution stopped.")
})

# ==============================================================================
# STEP 2: DATA CLEANING
# ==============================================================================
cat("\n🧹 Step 2: Cleaning data...\n")
cat("=" , rep("=", 70), "\n", sep = "")

tryCatch({
  source(here::here("scripts", "02_data_cleaning.R"))
  cat("✅ Data cleaning completed successfully!\n")
}, error = function(e) {
  cat("❌ ERROR in data cleaning:\n")
  print(e)
  stop("Data cleaning failed. Execution stopped.")
})

# ==============================================================================
# STEP 3: EXPLORATORY DATA ANALYSIS
# ==============================================================================
cat("\n📊 Step 3: Performing exploratory data analysis...\n")
cat("=" , rep("=", 70), "\n", sep = "")

tryCatch({
  source(here::here("scripts", "03_eda.R"))
  cat("✅ EDA completed successfully!\n")
}, error = function(e) {
  cat("❌ ERROR in EDA:\n")
  print(e)
  stop("EDA failed. Execution stopped.")
})

# ==============================================================================
# STEP 4: VISUALIZATIONS
# ==============================================================================
cat("\n🎨 Step 4: Creating visualizations...\n")
cat("=" , rep("=", 70), "\n", sep = "")

tryCatch({
  source(here::here("scripts", "04_visualizations.R"))
  cat("✅ Visualizations created successfully!\n")
}, error = function(e) {
  cat("❌ ERROR in visualization:\n")
  print(e)
  stop("Visualization failed. Execution stopped.")
})

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================
end_time <- Sys.time()
execution_time <- round(difftime(end_time, start_time, units = "secs"), 2)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                                                                              ║\n")
cat("║                        ✅ ANALYSIS COMPLETE! ✅                              ║\n")
cat("║                                                                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n")

cat("\n📈 Execution Summary:\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat(sprintf("   Total execution time: %s seconds\n", execution_time))
cat(sprintf("   Completed at: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

cat("\n📁 Generated Files:\n")
cat("=" , rep("=", 70), "\n", sep = "")

# Count generated files
processed_files <- list.files(here::here("data", "processed"), pattern = "\\.rds$")
figure_files <- list.files(here::here("output", "figures"), pattern = "\\.png$")
table_files <- list.files(here::here("output", "tables"), pattern = "\\.csv$")

cat(sprintf("   Processed data files: %d (in data/processed/)\n", length(processed_files)))
cat(sprintf("   Visualization files: %d (in output/figures/)\n", length(figure_files)))
cat(sprintf("   Table files: %d (in output/tables/)\n", length(table_files)))

cat("\n📊 Visualizations Created:\n")
for (fig in figure_files) {
  cat(sprintf("   ✓ %s\n", fig))
}

cat("\n🎯 Next Steps:\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("   1. Review the generated figures in output/figures/\n")
cat("   2. Check the processed data in data/processed/\n")
cat("   3. Render the Quarto website:\n")
cat("      Command: quarto render\n")
cat("   4. Preview the website:\n")
cat("      Command: quarto preview\n")
cat("   5. Deploy to Vercel (after pushing to GitHub)\n")

cat("\n💡 Tips:\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("   • All data is now ready for the Quarto report\n")
cat("   • Visualizations will be embedded automatically\n")
cat("   • You can re-run individual scripts if needed\n")
cat("   • Check the SETUP_GUIDE.md for deployment instructions\n")

cat("\n🎓 Good luck with your presentation!\n\n")

# Optional: Open output folder
if (interactive()) {
  response <- readline(prompt = "Open output folder? (y/n): ")
  if (tolower(response) == "y") {
    system(paste("xdg-open", here::here("output", "figures")))
  }
}
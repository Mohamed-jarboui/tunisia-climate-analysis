# ==============================================================================
# Tunisia Climate Capstone - Data Loading Script
# ==============================================================================
# Purpose: Load raw CSV data from three Tunisian cities
# Author: Your Name
# Date: January 2026
# ==============================================================================

# Load required libraries
library(tidyverse)
library(lubridate)
library(here)

# Set project root
here::i_am("scripts/01_data_loading.R")

# Function to load and label city data
load_city_data <- function(filepath, city_name) {
  cat(sprintf("📥 Loading data for %s...\n", city_name))
  
  data <- read_csv(filepath, 
                   show_col_types = FALSE,
                   locale = locale(encoding = "UTF-8"))
  
  # Add city identifier
  data$city <- city_name
  
  cat(sprintf("   ✓ Loaded %d rows\n", nrow(data)))
  return(data)
}

# Load data from all three cities
bizerte_data <- load_city_data(
  here("data", "raw", "bizerte.csv"),
  "Bizerte"
)

sousse_data <- load_city_data(
  here("data", "raw", "sousse.csv"),
  "Sousse"
)

kef_data <- load_city_data(
  here("data", "raw", "kef.csv"),
  "Kef"
)

# Combine all datasets
combined_data <- bind_rows(bizerte_data, sousse_data, kef_data)

cat("\n📊 Combined Dataset Summary:\n")
cat(sprintf("   Total rows: %d\n", nrow(combined_data)))
cat(sprintf("   Date range: %s to %s\n", 
            min(combined_data$Date), 
            max(combined_data$Date)))
cat(sprintf("   Cities: %s\n", paste(unique(combined_data$city), collapse = ", ")))
cat(sprintf("   Variables: %s\n", paste(unique(combined_data$nom_fr), collapse = ", ")))

# Display data structure
cat("\n🔍 Data Structure:\n")
glimpse(combined_data)

# Display first few rows
cat("\n📋 Sample Data:\n")
print(head(combined_data, 10))

# Save the combined raw data
saveRDS(combined_data, here("data", "processed", "01_raw_combined.rds"))
cat("\n💾 Saved combined data to: data/processed/01_raw_combined.rds\n")

cat("\n✅ Data loading complete!\n")
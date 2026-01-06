# ==============================================================================
# Tunisia Climate Capstone - Data Cleaning Script
# ==============================================================================
# Purpose: Clean and transform data for analysis
# Author: Your Name
# Date: January 2026
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)

# Load combined raw data
cat("📂 Loading raw data...\n")
raw_data <- readRDS(here("data", "processed", "01_raw_combined.rds"))

# ==============================================================================
# STEP 1: Parse dates and extract time components
# ==============================================================================
cat("\n🕐 Step 1: Parsing dates...\n")

cleaned_data <- raw_data %>%
  mutate(
    # Parse datetime
    datetime = ymd_hms(Date, quiet = TRUE),
    
    # Extract components
    date = as_date(datetime),
    year = year(datetime),
    month = month(datetime, label = TRUE, abbr = FALSE),
    day = day(datetime),
    hour = hour(datetime),
    
    # Create time period categories
    time_period = case_when(
      hour >= 6 & hour < 12 ~ "Morning",
      hour >= 12 & hour < 18 ~ "Afternoon",
      hour >= 18 & hour < 24 ~ "Evening",
      TRUE ~ "Night"
    ),
    
    # Season (Northern Hemisphere)
    season = case_when(
      month(datetime) %in% c(12, 1, 2) ~ "Winter",
      month(datetime) %in% c(3, 4, 5) ~ "Spring",
      month(datetime) %in% c(6, 7, 8) ~ "Summer",
      month(datetime) %in% c(9, 10, 11) ~ "Autumn"
    )
  )

cat(sprintf("   ✓ Parsed %d datetime records\n", nrow(cleaned_data)))

# ==============================================================================
# STEP 2: Standardize variable names and convert to wide format
# ==============================================================================
cat("\n📊 Step 2: Transforming to wide format...\n")

# Create English variable names mapping
variable_mapping <- tibble(
  nom_fr = c("Température", "Humidité relative", "Vitesse du vent", 
             "Direction du vent", "Point de Rosée", "Rayonnement solaire"),
  variable_en = c("temperature", "humidity", "wind_speed", 
                  "wind_direction", "dew_point", "solar_radiation")
)

# Transform to wide format  ✅ FIX APPLIED HERE
wide_data <- cleaned_data %>%
  left_join(variable_mapping, by = "nom_fr") %>%
  select(datetime, date, year, month, day, hour, time_period, season, 
         city, variable_en, valeur) %>%
  pivot_wider(
    names_from = variable_en,
    values_from = valeur,
    values_fn = mean,
    values_fill = NA
  )

cat(sprintf("   ✓ Transformed to %d rows with %d columns\n", 
            nrow(wide_data), ncol(wide_data)))

# ==============================================================================
# STEP 3: Handle missing values
# ==============================================================================
cat("\n🔍 Step 3: Checking for missing values...\n")

# Count missing values
missing_summary <- wide_data %>%
  summarise(across(temperature:solar_radiation, 
                   ~sum(is.na(.)), 
                   .names = "missing_{.col}"))

print(missing_summary)

# Calculate percentage of missing data
missing_pct <- wide_data %>%
  summarise(across(temperature:solar_radiation, 
                   ~round(sum(is.na(.)) / n() * 100, 2),
                   .names = "pct_missing_{.col}"))

print(missing_pct)

# Remove rows with all NA values in measurements
wide_data <- wide_data %>%
  filter(!if_all(temperature:solar_radiation, is.na))

cat(sprintf("   ✓ Removed rows with all missing measurements\n"))
cat(sprintf("   ✓ Final dataset: %d rows\n", nrow(wide_data)))

# ==============================================================================
# STEP 4: Data validation and quality checks
# ==============================================================================
cat("\n✅ Step 4: Validating data quality...\n")

# Check for unrealistic values
quality_checks <- wide_data %>%
  summarise(
    temp_outliers = sum(temperature < -20 | temperature > 60, na.rm = TRUE),
    humidity_outliers = sum(humidity < 0 | humidity > 100, na.rm = TRUE),
    wind_outliers = sum(wind_speed < 0 | wind_speed > 50, na.rm = TRUE),
    solar_outliers = sum(solar_radiation < 0 | solar_radiation > 1500, na.rm = TRUE)
  )

cat("\n   Potential outliers detected:\n")
print(quality_checks)

# Remove impossible values (optional - be careful!)
# Keeping outliers for now, but flagging them
wide_data <- wide_data %>%
  mutate(
    quality_flag = case_when(
      temperature < -20 | temperature > 60 ~ "temperature_outlier",
      humidity < 0 | humidity > 100 ~ "humidity_outlier",
      wind_speed < 0 | wind_speed > 50 ~ "wind_outlier",
      solar_radiation < 0 | solar_radiation > 1500 ~ "solar_outlier",
      TRUE ~ "ok"
    )
  )

# ==============================================================================
# STEP 5: Create summary statistics by city
# ==============================================================================
cat("\n📈 Step 5: Creating summary statistics...\n")

city_summary <- wide_data %>%
  group_by(city) %>%
  summarise(
    n_observations = n(),
    avg_temperature = round(mean(temperature, na.rm = TRUE), 2),
    avg_humidity = round(mean(humidity, na.rm = TRUE), 2),
    avg_wind_speed = round(mean(wind_speed, na.rm = TRUE), 2),
    avg_solar_radiation = round(mean(solar_radiation, na.rm = TRUE), 2),
    date_range = paste(min(date), "to", max(date))
  )

print(city_summary)

# ==============================================================================
# STEP 6: Save cleaned data
# ==============================================================================
cat("\n💾 Saving cleaned data...\n")

saveRDS(wide_data, here("data", "processed", "02_cleaned_data.rds"))
write_csv(wide_data, here("data", "processed", "02_cleaned_data.csv"))
saveRDS(city_summary, here("data", "processed", "02_city_summary.rds"))

cat("\n✅ Data cleaning complete!\n")
cat(sprintf("   📁 Cleaned data saved to: data/processed/02_cleaned_data.rds\n"))
cat(sprintf("   📁 CSV export saved to: data/processed/02_cleaned_data.csv\n"))

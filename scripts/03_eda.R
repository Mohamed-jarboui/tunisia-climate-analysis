# ==============================================================================
# Tunisia Climate Capstone - Exploratory Data Analysis (EDA)
# ==============================================================================
# Purpose: Comprehensive statistical analysis and KPI calculations
# Author: Your Name
# Date: January 2026
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)
library(gt)

# Load cleaned data
cat("📂 Loading cleaned data...\n")
climate_data <- readRDS(here("data", "processed", "02_cleaned_data.rds"))

# ==============================================================================
# 1. OVERALL STATISTICAL SUMMARY
# ==============================================================================
cat("\n📊 1. Overall Statistical Summary\n")
cat("=" , rep("=", 60), "\n", sep = "")

overall_stats <- climate_data %>%
  summarise(
    across(
      c(temperature, humidity, wind_speed, dew_point, solar_radiation),
      list(
        min = ~min(., na.rm = TRUE),
        q25 = ~quantile(., 0.25, na.rm = TRUE),
        median = ~median(., na.rm = TRUE),
        mean = ~mean(., na.rm = TRUE),
        q75 = ~quantile(., 0.75, na.rm = TRUE),
        max = ~max(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE),
        missing = ~sum(is.na(.))
      ),
      .names = "{.col}_{.fn}"
    )
  )

print(glimpse(overall_stats))

# ==============================================================================
# 2. CITY-WISE COMPARISON
# ==============================================================================
cat("\n🏙️ 2. City-wise Climate Comparison\n")
cat("=" , rep("=", 60), "\n", sep = "")

city_stats <- climate_data %>%
  group_by(city) %>%
  summarise(
    n_obs = n(),
    
    # Temperature
    avg_temp = round(mean(temperature, na.rm = TRUE), 2),
    min_temp = round(min(temperature, na.rm = TRUE), 2),
    max_temp = round(max(temperature, na.rm = TRUE), 2),
    temp_range = round(max_temp - min_temp, 2),
    
    # Humidity
    avg_humidity = round(mean(humidity, na.rm = TRUE), 2),
    min_humidity = round(min(humidity, na.rm = TRUE), 2),
    max_humidity = round(max(humidity, na.rm = TRUE), 2),
    
    # Wind
    avg_wind = round(mean(wind_speed, na.rm = TRUE), 2),
    max_wind = round(max(wind_speed, na.rm = TRUE), 2),
    
    # Solar Radiation
    avg_solar = round(mean(solar_radiation, na.rm = TRUE), 2),
    max_solar = round(max(solar_radiation, na.rm = TRUE), 2),
    
    .groups = "drop"
  ) %>%
  arrange(desc(avg_temp))

print(city_stats)

# ==============================================================================
# 3. SEASONAL PATTERNS
# ==============================================================================
cat("\n🍂 3. Seasonal Climate Patterns\n")
cat("=" , rep("=", 60), "\n", sep = "")

seasonal_stats <- climate_data %>%
  group_by(season, city) %>%
  summarise(
    avg_temp = round(mean(temperature, na.rm = TRUE), 2),
    avg_humidity = round(mean(humidity, na.rm = TRUE), 2),
    avg_wind = round(mean(wind_speed, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  arrange(city, match(season, c("Winter", "Spring", "Summer", "Autumn")))

print(seasonal_stats)

# ==============================================================================
# 4. MONTHLY TRENDS
# ==============================================================================
cat("\n📅 4. Monthly Climate Trends\n")
cat("=" , rep("=", 60), "\n", sep = "")

monthly_trends <- climate_data %>%
  group_by(city, month) %>%
  summarise(
    avg_temp = round(mean(temperature, na.rm = TRUE), 2),
    avg_humidity = round(mean(humidity, na.rm = TRUE), 2),
    avg_solar = round(mean(solar_radiation, na.rm = TRUE), 2),
    n_obs = n(),
    .groups = "drop"
  )

# Show sample
print(head(monthly_trends, 15))

# ==============================================================================
# 5. DAILY PATTERNS (DIURNAL CYCLE)
# ==============================================================================
cat("\n☀️ 5. Daily Patterns (Diurnal Cycle)\n")
cat("=" , rep("=", 60), "\n", sep = "")

hourly_patterns <- climate_data %>%
  group_by(city, hour) %>%
  summarise(
    avg_temp = round(mean(temperature, na.rm = TRUE), 2),
    avg_humidity = round(mean(humidity, na.rm = TRUE), 2),
    avg_solar = round(mean(solar_radiation, na.rm = TRUE), 2),
    .groups = "drop"
  )

# Show morning, noon, and evening patterns
print(hourly_patterns %>% filter(hour %in% c(6, 12, 18)))

# ==============================================================================
# 6. KEY PERFORMANCE INDICATORS (KPIs)
# ==============================================================================
cat("\n🎯 6. Key Performance Indicators (KPIs)\n")
cat("=" , rep("=", 60), "\n", sep = "")

kpis <- climate_data %>%
  group_by(city) %>%
  summarise(
    # Temperature KPIs
    heat_days = sum(temperature > 35, na.rm = TRUE),
    cold_days = sum(temperature < 5, na.rm = TRUE),
    comfortable_days = sum(temperature >= 18 & temperature <= 26, na.rm = TRUE),
    
    # Humidity KPIs
    high_humidity_hours = sum(humidity > 80, na.rm = TRUE),
    low_humidity_hours = sum(humidity < 30, na.rm = TRUE),
    
    # Wind KPIs
    windy_hours = sum(wind_speed > 10, na.rm = TRUE),
    calm_hours = sum(wind_speed < 2, na.rm = TRUE),
    
    # Solar KPIs
    sunny_hours = sum(solar_radiation > 800, na.rm = TRUE),
    
    # Comfort index (simple calculation)
    avg_comfort_index = round(mean(
      case_when(
        temperature >= 18 & temperature <= 26 & humidity >= 30 & humidity <= 70 ~ 1,
        TRUE ~ 0
      ), na.rm = TRUE
    ) * 100, 2),
    
    .groups = "drop"
  )

print(kpis)

# ==============================================================================
# 7. CORRELATION ANALYSIS
# ==============================================================================
cat("\n🔗 7. Correlation Analysis\n")
cat("=" , rep("=", 60), "\n", sep = "")

# Calculate correlations by city
correlations <- climate_data %>%
  group_by(city) %>%
  summarise(
    temp_humidity_cor = round(cor(temperature, humidity, use = "complete.obs"), 3),
    temp_solar_cor = round(cor(temperature, solar_radiation, use = "complete.obs"), 3),
    humidity_solar_cor = round(cor(humidity, solar_radiation, use = "complete.obs"), 3),
    temp_wind_cor = round(cor(temperature, wind_speed, use = "complete.obs"), 3),
    .groups = "drop"
  )

print(correlations)

# ==============================================================================
# 8. EXTREME EVENTS
# ==============================================================================
cat("\n⚠️ 8. Extreme Weather Events\n")
cat("=" , rep("=", 60), "\n", sep = "")

extreme_events <- climate_data %>%
  group_by(city) %>%
  summarise(
    hottest_temp = max(temperature, na.rm = TRUE),
    hottest_date = date[which.max(temperature)],
    coldest_temp = min(temperature, na.rm = TRUE),
    coldest_date = date[which.min(temperature)],
    strongest_wind = max(wind_speed, na.rm = TRUE),
    strongest_wind_date = date[which.max(wind_speed)],
    highest_solar = max(solar_radiation, na.rm = TRUE),
    .groups = "drop"
  )

print(extreme_events)

# ==============================================================================
# 9. TEMPERATURE VARIABILITY
# ==============================================================================
cat("\n📊 9. Temperature Variability Analysis\n")
cat("=" , rep("=", 60), "\n", sep = "")

temp_variability <- climate_data %>%
  group_by(city, date) %>%
  summarise(
    daily_temp_range = max(temperature, na.rm = TRUE) - min(temperature, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(city) %>%
  summarise(
    avg_daily_range = round(mean(daily_temp_range, na.rm = TRUE), 2),
    max_daily_range = round(max(daily_temp_range, na.rm = TRUE), 2),
    sd_daily_range = round(sd(daily_temp_range, na.rm = TRUE), 2),
    .groups = "drop"
  )

print(temp_variability)

# ==============================================================================
# 10. SAVE ALL RESULTS
# ==============================================================================
cat("\n💾 Saving EDA results...\n")

# Create a list of all results
eda_results <- list(
  overall_stats = overall_stats,
  city_stats = city_stats,
  seasonal_stats = seasonal_stats,
  monthly_trends = monthly_trends,
  hourly_patterns = hourly_patterns,
  kpis = kpis,
  correlations = correlations,
  extreme_events = extreme_events,
  temp_variability = temp_variability
)

# Save as RDS
saveRDS(eda_results, here("data", "processed", "03_eda_results.rds"))

# Save individual CSV files for reporting
write_csv(city_stats, here("output", "tables", "city_statistics.csv"))
write_csv(seasonal_stats, here("output", "tables", "seasonal_patterns.csv"))
write_csv(kpis, here("output", "tables", "kpis.csv"))
write_csv(extreme_events, here("output", "tables", "extreme_events.csv"))

cat("\n✅ EDA complete! Results saved to:\n")
cat("   📁 data/processed/03_eda_results.rds\n")
cat("   📁 output/tables/*.csv\n")
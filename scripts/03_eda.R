# ==============================================================================
# Tunisia Climate Analysis - Exploratory Data Analysis
# ==============================================================================
# Purpose: City comparison, daily cycles, correlations and extremes
# Author: Mohamed Jarboui
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)

cat("Loading cleaned data...\n")
climate_data <- readRDS(here("data", "processed", "02_cleaned_data.rds"))

# ------------------------------------------------------------------------------
# Common period: the stations cover different date ranges (Sousse runs longer),
# so cities are compared only over the days that all stations recorded.
# ------------------------------------------------------------------------------
period <- climate_data %>%
  group_by(city) %>%
  summarise(start = min(datetime), end = max(datetime), .groups = "drop")
common_start <- max(period$start)
common_end <- min(period$end)
common <- climate_data %>% filter(datetime >= common_start, datetime <= common_end)

cat(sprintf("Common period: %s to %s (%d station-hours)\n",
            common_start, common_end, nrow(common)))

# ------------------------------------------------------------------------------
# 1. City comparison over the common period
# ------------------------------------------------------------------------------
city_stats <- common %>%
  group_by(city) %>%
  summarise(
    hours = n(),
    avg_temp = mean(temperature, na.rm = TRUE),
    min_temp = min(temperature, na.rm = TRUE),
    max_temp = max(temperature, na.rm = TRUE),
    avg_humidity = mean(humidity, na.rm = TRUE),
    avg_wind = mean(wind_speed, na.rm = TRUE),
    max_wind = max(wind_speed, na.rm = TRUE),
    avg_dew_point = mean(dew_point, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.double), ~round(., 1))) %>%
  arrange(desc(avg_temp))
print(city_stats)

# ------------------------------------------------------------------------------
# 2. Daily temperature range (max - min within a day)
# ------------------------------------------------------------------------------
daily <- common %>%
  group_by(city, date) %>%
  summarise(
    hours = n(),
    t_min = min(temperature, na.rm = TRUE),
    t_max = max(temperature, na.rm = TRUE),
    t_mean = mean(temperature, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(hours >= 18)   # only days with enough hourly readings

temp_variability <- daily %>%
  mutate(range = t_max - t_min) %>%
  group_by(city) %>%
  summarise(
    full_days = n(),
    avg_daily_range = round(mean(range), 1),
    max_daily_range = round(max(range), 1),
    .groups = "drop"
  )
print(temp_variability)

# ------------------------------------------------------------------------------
# 3. Average daily cycle (all available data per city)
# ------------------------------------------------------------------------------
hourly_patterns <- climate_data %>%
  group_by(city, hour) %>%
  summarise(
    avg_temp = mean(temperature, na.rm = TRUE),
    avg_humidity = mean(humidity, na.rm = TRUE),
    avg_solar = mean(solar_radiation, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  filter(n >= 5)   # Bizerte logs every 2 hours; drop hour slots with only a few stray readings

peak_hours <- hourly_patterns %>%
  group_by(city) %>%
  summarise(
    warmest_hour = hour[which.max(avg_temp)],
    coldest_hour = hour[which.min(avg_temp)],
    .groups = "drop"
  )
print(peak_hours)

# ------------------------------------------------------------------------------
# 4. Hour counts over the common period
# ------------------------------------------------------------------------------
hour_counts <- common %>%
  group_by(city) %>%
  summarise(
    hours = n(),
    hours_below_5c = sum(temperature < 5, na.rm = TRUE),
    hours_above_80pct_humidity = sum(humidity > 80, na.rm = TRUE),
    calm_hours = sum(wind_speed < 2, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct_humid = round(hours_above_80pct_humidity / hours * 100, 1),
    pct_calm = round(calm_hours / hours * 100, 1)
  )
print(hour_counts)

# ------------------------------------------------------------------------------
# 5. Correlations (all available data per city)
# ------------------------------------------------------------------------------
safe_cor <- function(x, y) {
  ok <- complete.cases(x, y)
  if (sum(ok) < 10) return(NA_real_)
  round(cor(x[ok], y[ok]), 2)
}

correlations <- climate_data %>%
  group_by(city) %>%
  summarise(
    temp_humidity = safe_cor(temperature, humidity),
    temp_solar = safe_cor(temperature, solar_radiation),
    temp_wind = safe_cor(temperature, wind_speed),
    .groups = "drop"
  )
print(correlations)

# ------------------------------------------------------------------------------
# 6. Extremes (all available data per city)
# ------------------------------------------------------------------------------
extreme_events <- climate_data %>%
  group_by(city) %>%
  summarise(
    hottest_temp = max(temperature, na.rm = TRUE),
    hottest_time = datetime[which.max(temperature)],
    coldest_temp = min(temperature, na.rm = TRUE),
    coldest_time = datetime[which.min(temperature)],
    strongest_wind = max(wind_speed, na.rm = TRUE),
    strongest_wind_time = datetime[which.max(wind_speed)],
    .groups = "drop"
  )
print(extreme_events)

# ------------------------------------------------------------------------------
# 7. Save
# ------------------------------------------------------------------------------
eda_results <- list(
  common_start = common_start,
  common_end = common_end,
  period = period,
  city_stats = city_stats,
  daily = daily,
  temp_variability = temp_variability,
  hourly_patterns = hourly_patterns,
  peak_hours = peak_hours,
  hour_counts = hour_counts,
  correlations = correlations,
  extreme_events = extreme_events
)
saveRDS(eda_results, here("data", "processed", "03_eda_results.rds"))

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)
write_csv(city_stats, here("output", "tables", "city_statistics.csv"))
write_csv(temp_variability, here("output", "tables", "daily_temperature_range.csv"))
write_csv(hour_counts, here("output", "tables", "hour_counts.csv"))
write_csv(correlations, here("output", "tables", "correlations.csv"))
write_csv(extreme_events, here("output", "tables", "extreme_events.csv"))

cat("\nEDA complete.\n")

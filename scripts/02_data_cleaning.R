# ==============================================================================
# Tunisia Climate Analysis - Data Cleaning
# ==============================================================================
# Purpose: Parse timestamps, reshape to one row per station-hour, run quality
#          checks and remove readings from faulty sensors
# Author: Mohamed Jarboui
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)

cat("Loading raw data...\n")
raw_data <- readRDS(here("data", "processed", "01_raw_combined.rds"))

# ------------------------------------------------------------------------------
# 1. Parse timestamps and add time features
# ------------------------------------------------------------------------------
# Readings are logged on the hour, sometimes with a few seconds of delay
# (e.g. 07:00:02), so timestamps are rounded to the hour.
# read_csv already parses Date as a datetime; converting it back to text would
# drop the time at midnight ("2025-12-07") and lose those readings.
parsed <- raw_data %>%
  mutate(
    datetime = round_date(as_datetime(Date), "hour"),
    date = as_date(datetime),
    hour = hour(datetime),
    time_period = case_when(
      hour >= 6 & hour < 12 ~ "Morning",
      hour >= 12 & hour < 18 ~ "Afternoon",
      hour >= 18 ~ "Evening",
      TRUE ~ "Night"
    )
  )

n_unparsed <- sum(is.na(parsed$datetime))
cat(sprintf("  Parsed %d readings (%d unparseable timestamps dropped)\n",
            nrow(parsed), n_unparsed))
parsed <- filter(parsed, !is.na(datetime))

# ------------------------------------------------------------------------------
# 2. Long to wide: one row per city and hour
# ------------------------------------------------------------------------------
# Variable names are matched without accents so the join works in any locale
strip_accents <- function(x) stringi::stri_trans_general(x, "Latin-ASCII")

variable_mapping <- tibble(
  key = c("Temperature", "Humidite relative", "Vitesse du vent",
          "Direction du vent", "Point de Rosee", "Rayonnement solaire",
          "Pression atmospherique"),
  variable = c("temperature", "humidity", "wind_speed",
               "wind_direction", "dew_point", "solar_radiation", "pressure")
)

wide_data <- parsed %>%
  mutate(key = strip_accents(nom_fr)) %>%
  inner_join(variable_mapping, by = "key") %>%   # drops evapotranspiration (not used)
  select(city, datetime, date, hour, time_period, variable, valeur) %>%
  pivot_wider(names_from = variable, values_from = valeur, values_fn = mean) %>%
  arrange(city, datetime)

cat(sprintf("  Reshaped to %d station-hours\n", nrow(wide_data)))

# ------------------------------------------------------------------------------
# 3. Range checks: physically impossible values become NA
# ------------------------------------------------------------------------------
range_checks <- wide_data %>%
  summarise(
    temperature = sum(temperature < -20 | temperature > 60, na.rm = TRUE),
    humidity = sum(humidity < 0 | humidity > 100, na.rm = TRUE),
    wind_speed = sum(wind_speed < 0 | wind_speed > 60, na.rm = TRUE),
    solar_radiation = sum(solar_radiation < 0 | solar_radiation > 1400, na.rm = TRUE)
  )
cat("  Out-of-range values:\n"); print(range_checks)

wide_data <- wide_data %>%
  mutate(
    temperature = if_else(between(temperature, -20, 60), temperature, NA_real_),
    humidity = if_else(between(humidity, 0, 100), humidity, NA_real_),
    wind_speed = if_else(between(wind_speed, 0, 60), wind_speed, NA_real_),
    solar_radiation = if_else(between(solar_radiation, 0, 1400), solar_radiation, NA_real_)
  )

# ------------------------------------------------------------------------------
# 4. Sensor fault detection: solar radiation must be ~0 at night
# ------------------------------------------------------------------------------
# A working pyranometer reads close to 0 W/m² between 20:00 and 05:00.
# If the median night reading of a station is above 50 W/m², its solar sensor
# is considered faulty and all its solar readings are removed.
solar_check <- wide_data %>%
  filter(hour >= 20 | hour <= 5) %>%
  group_by(city) %>%
  summarise(
    night_hours = sum(!is.na(solar_radiation)),
    median_night_solar = median(solar_radiation, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(solar_sensor_ok = is.na(median_night_solar) | median_night_solar <= 50)

cat("  Solar sensor check (night-time readings):\n"); print(solar_check)

faulty_solar <- solar_check %>% filter(!solar_sensor_ok) %>% pull(city)
wide_data <- wide_data %>%
  mutate(solar_radiation = if_else(city %in% faulty_solar, NA_real_, solar_radiation))

if (length(faulty_solar) > 0) {
  cat(sprintf("  Solar readings removed for: %s\n", paste(faulty_solar, collapse = ", ")))
}

# ------------------------------------------------------------------------------
# 5. Coverage summary and save
# ------------------------------------------------------------------------------
coverage <- wide_data %>%
  group_by(city) %>%
  summarise(
    first_reading = min(datetime),
    last_reading = max(datetime),
    days_covered = as.numeric(difftime(max(date), min(date), units = "days")) + 1,
    station_hours = n(),
    temperature_missing = sum(is.na(temperature)),
    humidity_missing = sum(is.na(humidity)),
    wind_missing = sum(is.na(wind_speed)),
    solar_missing = sum(is.na(solar_radiation)),
    .groups = "drop"
  ) %>%
  left_join(select(solar_check, city, median_night_solar, solar_sensor_ok), by = "city")

print(coverage)

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)
saveRDS(wide_data, here("data", "processed", "02_cleaned_data.rds"))
write_csv(wide_data, here("data", "processed", "02_cleaned_data.csv"))
write_csv(coverage, here("output", "tables", "data_quality.csv"))

cat("\nData cleaning complete.\n")

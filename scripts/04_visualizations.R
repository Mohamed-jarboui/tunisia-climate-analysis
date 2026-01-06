# ==============================================================================
# Tunisia Climate Capstone - Visualization Script
# ==============================================================================
# Purpose: Create professional visualizations for the capstone report
# Author: Your Name
# Date: January 2026
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)
library(patchwork)
library(scales)
library(viridis)

# Load cleaned data and EDA results
cat("📂 Loading data...\n")
climate_data <- readRDS(here("data", "processed", "02_cleaned_data.rds"))
eda_results <- readRDS(here("data", "processed", "03_eda_results.rds"))

# Set custom theme
theme_capstone <- function() {
  theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
      axis.title = element_text(size = 10, face = "bold"),
      legend.position = "bottom",
      legend.title = element_text(size = 9, face = "bold"),
      panel.grid.minor = element_blank()
    )
}

# Color palette for cities
city_colors <- c("Bizerte" = "#E41A1C", "Sousse" = "#377EB8", "Kef" = "#4DAF4A")

# ==============================================================================
# 1. TEMPERATURE COMPARISON ACROSS CITIES
# ==============================================================================
cat("\n📈 Creating Plot 1: Temperature Comparison...\n")

p1 <- ggplot(climate_data, aes(x = city, y = temperature, fill = city)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.alpha = 0.3) +
  scale_fill_manual(values = city_colors) +
  labs(
    title = "Temperature Distribution by City",
    subtitle = "Violin and box plots showing temperature variability",
    x = "City",
    y = "Temperature (°C)"
  ) +
  theme_capstone() +
  theme(legend.position = "none")

ggsave(here("output", "figures", "01_temperature_comparison.png"), 
       p1, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 2. TEMPERATURE TRENDS OVER TIME
# ==============================================================================
cat("📈 Creating Plot 2: Temperature Trends...\n")

daily_temps <- climate_data %>%
  group_by(city, date) %>%
  summarise(
    avg_temp = mean(temperature, na.rm = TRUE),
    .groups = "drop"
  )

p2 <- ggplot(daily_temps, aes(x = date, y = avg_temp, color = city)) +
  geom_line(alpha = 0.7, linewidth = 0.8) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.2, linewidth = 1.2) +
  scale_color_manual(values = city_colors) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
  labs(
    title = "Daily Average Temperature Trends",
    subtitle = "Smoothed trend lines with confidence intervals",
    x = "Date",
    y = "Average Temperature (°C)",
    color = "City"
  ) +
  theme_capstone() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(here("output", "figures", "02_temperature_trends.png"), 
       p2, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 3. SEASONAL TEMPERATURE PATTERNS
# ==============================================================================
cat("📈 Creating Plot 3: Seasonal Patterns...\n")

seasonal_data <- eda_results$seasonal_stats

p3 <- ggplot(seasonal_data, aes(x = season, y = avg_temp, fill = city)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = city_colors) +
  labs(
    title = "Average Temperature by Season and City",
    subtitle = "Comparing seasonal temperature patterns",
    x = "Season",
    y = "Average Temperature (°C)",
    fill = "City"
  ) +
  theme_capstone()

ggsave(here("output", "figures", "03_seasonal_temperature.png"), 
       p3, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 4. HUMIDITY COMPARISON
# ==============================================================================
cat("📈 Creating Plot 4: Humidity Analysis...\n")

p4 <- ggplot(climate_data, aes(x = humidity, fill = city)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = city_colors) +
  labs(
    title = "Humidity Distribution by City",
    subtitle = "Density plots showing humidity patterns",
    x = "Relative Humidity (%)",
    y = "Density",
    fill = "City"
  ) +
  theme_capstone()

ggsave(here("output", "figures", "04_humidity_distribution.png"), 
       p4, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 5. DIURNAL TEMPERATURE CYCLE
# ==============================================================================
cat("📈 Creating Plot 5: Daily Temperature Cycle...\n")

hourly_data <- eda_results$hourly_patterns

p5 <- ggplot(hourly_data, aes(x = hour, y = avg_temp, color = city, group = city)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = city_colors) +
  scale_x_continuous(breaks = seq(0, 23, 3)) +
  labs(
    title = "24-Hour Temperature Cycle",
    subtitle = "Average temperature by hour of day",
    x = "Hour of Day",
    y = "Average Temperature (°C)",
    color = "City"
  ) +
  theme_capstone()

ggsave(here("output", "figures", "05_diurnal_cycle.png"), 
       p5, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 6. TEMPERATURE VS HUMIDITY SCATTER
# ==============================================================================
cat("📈 Creating Plot 6: Temperature-Humidity Relationship...\n")

sample_data <- climate_data %>%
  sample_n(min(5000, nrow(climate_data)))

p6 <- ggplot(sample_data, aes(x = temperature, y = humidity, color = city)) +
  geom_point(alpha = 0.3, size = 1) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.2) +
  scale_color_manual(values = city_colors) +
  labs(
    title = "Temperature vs Humidity Relationship",
    subtitle = "Scatter plot with linear regression lines",
    x = "Temperature (°C)",
    y = "Relative Humidity (%)",
    color = "City"
  ) +
  theme_capstone()

ggsave(here("output", "figures", "06_temp_humidity_scatter.png"), 
       p6, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 7. WIND SPEED ANALYSIS
# ==============================================================================
cat("📈 Creating Plot 7: Wind Speed Analysis...\n")

p7 <- ggplot(climate_data, aes(x = city, y = wind_speed, fill = city)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  scale_fill_manual(values = city_colors) +
  labs(
    title = "Wind Speed Distribution by City",
    subtitle = "Box plots showing wind speed variability",
    x = "City",
    y = "Wind Speed (m/s)"
  ) +
  theme_capstone() +
  theme(legend.position = "none")

ggsave(here("output", "figures", "07_wind_speed.png"), 
       p7, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 8. SOLAR RADIATION PATTERNS
# ==============================================================================
cat("📈 Creating Plot 8: Solar Radiation...\n")

solar_hourly <- climate_data %>%
  group_by(city, hour) %>%
  summarise(
    avg_solar = mean(solar_radiation, na.rm = TRUE),
    .groups = "drop"
  )

p8 <- ggplot(solar_hourly, aes(x = hour, y = avg_solar, fill = city)) +
  geom_area(alpha = 0.6, position = "identity") +
  scale_fill_manual(values = city_colors) +
  scale_x_continuous(breaks = seq(0, 23, 3)) +
  labs(
    title = "Solar Radiation Throughout the Day",
    subtitle = "Average solar radiation by hour",
    x = "Hour of Day",
    y = "Solar Radiation (W/m²)",
    fill = "City"
  ) +
  theme_capstone()

ggsave(here("output", "figures", "08_solar_radiation.png"), 
       p8, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 9. MONTHLY HEATMAP
# ==============================================================================
cat("📈 Creating Plot 9: Monthly Heatmap...\n")

monthly_data <- climate_data %>%
  group_by(city, month) %>%
  summarise(
    avg_temp = mean(temperature, na.rm = TRUE),
    .groups = "drop"
  )

p9 <- ggplot(monthly_data, aes(x = month, y = city, fill = avg_temp)) +
  geom_tile(color = "white", linewidth = 1) +
  scale_fill_viridis_c(option = "plasma") +
  labs(
    title = "Monthly Average Temperature Heatmap",
    subtitle = "Temperature patterns across months and cities",
    x = "Month",
    y = "City",
    fill = "Avg Temp (°C)"
  ) +
  theme_capstone() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(here("output", "figures", "09_monthly_heatmap.png"), 
       p9, width = 10, height = 5, dpi = 300)

# ==============================================================================
# 10. KPI DASHBOARD (COMPOSITE)
# ==============================================================================
cat("📈 Creating Plot 10: KPI Dashboard...\n")

kpi_data <- eda_results$kpis %>%
  select(city, heat_days, comfortable_days, high_humidity_hours, windy_hours) %>%
  pivot_longer(-city, names_to = "kpi", values_to = "value")

p10 <- ggplot(kpi_data, aes(x = city, y = value, fill = kpi)) +
  geom_col(position = "dodge", alpha = 0.8) +
  facet_wrap(~kpi, scales = "free_y", ncol = 2) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Key Performance Indicators by City",
    subtitle = "Comparison of climate comfort metrics",
    x = "City",
    y = "Count",
    fill = "KPI"
  ) +
  theme_capstone() +
  theme(legend.position = "none")

ggsave(here("output", "figures", "10_kpi_dashboard.png"), 
       p10, width = 10, height = 8, dpi = 300)

# ==============================================================================
# 11. COMPREHENSIVE DASHBOARD (4-PANEL)
# ==============================================================================
cat("📈 Creating Plot 11: Comprehensive Dashboard...\n")

dashboard <- (p1 | p4) / (p5 | p7) +
  plot_annotation(
    title = "Tunisia Climate Analysis Dashboard",
    subtitle = "Comprehensive overview of weather patterns across three cities",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5)
    )
  )

ggsave(here("output", "figures", "11_comprehensive_dashboard.png"), 
       dashboard, width = 14, height = 10, dpi = 300)

# ==============================================================================
# SUMMARY
# ==============================================================================
cat("\n✅ All visualizations created successfully!\n")
cat("\n📁 Saved to: output/figures/\n")
cat("\n📊 Generated plots:\n")
cat("   01. Temperature comparison\n")
cat("   02. Temperature trends\n")
cat("   03. Seasonal patterns\n")
cat("   04. Humidity distribution\n")
cat("   05. Diurnal cycle\n")
cat("   06. Temperature-Humidity scatter\n")
cat("   07. Wind speed analysis\n")
cat("   08. Solar radiation\n")
cat("   09. Monthly heatmap\n")
cat("   10. KPI dashboard\n")
cat("   11. Comprehensive dashboard\n")
# ==============================================================================
# Tunisia Climate Analysis - Visualizations
# ==============================================================================
# Purpose: Figures for the report and README
# Author: Mohamed Jarboui
# ==============================================================================

library(tidyverse)
library(lubridate)
library(here)
library(patchwork)
library(scales)

climate_data <- readRDS(here("data", "processed", "02_cleaned_data.rds"))
eda <- readRDS(here("data", "processed", "03_eda_results.rds"))
common <- climate_data %>% filter(datetime >= eda$common_start, datetime <= eda$common_end)

fig_dir <- here("output", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
unlink(list.files(fig_dir, pattern = "\\.png$", full.names = TRUE))

city_colors <- c("Bizerte" = "#2a78d6", "Sousse" = "#eb6834", "Kef" = "#1baf7a")
common_label <- sprintf("%s to %s, hours recorded by all three stations",
                        format(eda$common_start, "%d %b"), format(eda$common_end, "%d %b %Y"))

theme_report <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray35", size = 10),
      plot.caption = element_text(color = "gray45", size = 8, hjust = 0),
      axis.title = element_text(color = "gray25", size = 10),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank()
    )
}

save_fig <- function(plot, name, width = 9, height = 5.5) {
  ggsave(file.path(fig_dir, name), plot, width = width, height = height, dpi = 200, bg = "white")
  cat("  saved", name, "\n")
}

# 1. Temperature by city ---------------------------------------------------------
p1 <- ggplot(common, aes(x = reorder(city, temperature, median), y = temperature, fill = city)) +
  geom_boxplot(width = 0.5, alpha = 0.85, outlier.alpha = 0.4, color = "gray25") +
  scale_fill_manual(values = city_colors, guide = "none") +
  labs(title = "Kef is about 4-5 \u00b0C colder than the coastal cities",
       subtitle = common_label, x = NULL, y = "Temperature (\u00b0C)") +
  theme_report()
save_fig(p1, "01_temperature_by_city.png", 8, 5.5)

# 2. Daily temperature: mean with min-max band ------------------------------------
daily_all <- climate_data %>%
  group_by(city, date) %>%
  summarise(n = n(), t_min = min(temperature, na.rm = TRUE), t_max = max(temperature, na.rm = TRUE),
            t_mean = mean(temperature, na.rm = TRUE), .groups = "drop") %>%
  group_by(city) %>%
  filter(n >= 0.5 * median(n)) %>%   # drop partial days (e.g. a station outage)
  ungroup()

p2 <- ggplot(daily_all, aes(x = date)) +
  geom_ribbon(aes(ymin = t_min, ymax = t_max, fill = city), alpha = 0.25) +
  geom_line(aes(y = t_mean, color = city), linewidth = 0.9) +
  geom_point(aes(y = t_mean, color = city), size = 1.6) +
  facet_wrap(~city, ncol = 1) +
  scale_color_manual(values = city_colors, guide = "none") +
  scale_fill_manual(values = city_colors, guide = "none") +
  scale_x_date(date_breaks = "1 week", date_labels = "%d %b") +
  labs(title = "Daily temperature",
       subtitle = "Line: daily mean. Band: daily minimum to maximum. Partial days are left out. Sousse recorded until 6 January.",
       x = NULL, y = "Temperature (\u00b0C)") +
  theme_report() +
  theme(strip.text = element_text(face = "bold", hjust = 0))
save_fig(p2, "02_daily_temperature.png", 9, 7)

# 3. Average daily cycle -----------------------------------------------------------
hourly <- eda$hourly_patterns
labels_end <- hourly %>% group_by(city) %>% filter(hour == max(hour))

p3 <- ggplot(hourly, aes(x = hour, y = avg_temp, color = city)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_text(data = labels_end, aes(label = city), hjust = -0.2, size = 3.5, show.legend = FALSE) +
  scale_color_manual(values = city_colors) +
  scale_x_continuous(breaks = seq(0, 21, 3), labels = function(h) sprintf("%02d:00", h),
                     expand = expansion(mult = c(0.02, 0.12))) +
  labs(title = "Average daily temperature cycle",
       subtitle = "Warmest around 14:00-15:00, coldest just before sunrise",
       x = "Hour of day", y = "Average temperature (\u00b0C)") +
  theme_report()
save_fig(p3, "03_daily_cycle.png")

# 4. Humidity by city --------------------------------------------------------------
p4 <- ggplot(common, aes(x = reorder(city, humidity, median), y = humidity, fill = city)) +
  geom_boxplot(width = 0.5, alpha = 0.85, outlier.alpha = 0.4, color = "gray25") +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray50") +
  annotate("text", x = 0.55, y = 82, label = "80%", hjust = 0, size = 3, color = "gray40") +
  scale_fill_manual(values = city_colors, guide = "none") +
  scale_y_continuous(limits = c(25, 100)) +
  labs(title = "Bizerte is the most humid station",
       subtitle = common_label, x = NULL, y = "Relative humidity (%)") +
  theme_report()
save_fig(p4, "04_humidity_by_city.png", 8, 5.5)

# 5. Temperature vs humidity --------------------------------------------------------
cor_labels <- eda$correlations %>% mutate(label = sprintf("r = %.2f", temp_humidity))

p5 <- ggplot(climate_data, aes(x = temperature, y = humidity, color = city)) +
  geom_point(alpha = 0.35, size = 1.2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linewidth = 1, color = "gray20") +
  geom_text(data = cor_labels, aes(x = Inf, y = Inf, label = label), inherit.aes = FALSE,
            hjust = 1.1, vjust = 1.5, size = 3.5, color = "gray20") +
  facet_wrap(~city) +
  coord_cartesian(ylim = c(25, 100)) +
  scale_color_manual(values = city_colors, guide = "none") +
  labs(title = "Humidity falls as temperature rises",
       subtitle = "Each point is one hour; line: linear fit; r: Pearson correlation",
       x = "Temperature (\u00b0C)", y = "Relative humidity (%)") +
  theme_report() +
  theme(strip.text = element_text(face = "bold"))
save_fig(p5, "05_temp_vs_humidity.png", 10, 4.8)

# 6. Wind speed ---------------------------------------------------------------------
p6 <- ggplot(common, aes(x = reorder(city, wind_speed, median), y = wind_speed, fill = city)) +
  geom_boxplot(width = 0.5, alpha = 0.85, outlier.alpha = 0.4, color = "gray25") +
  scale_fill_manual(values = city_colors, guide = "none") +
  labs(title = "Wind speed by city", subtitle = common_label, x = NULL, y = "Wind speed (m/s)") +
  theme_report()
save_fig(p6, "06_wind_speed.png", 8, 5.5)

# 7. Solar radiation daily cycle (stations with a working sensor) -------------------
solar <- hourly %>% filter(!is.na(avg_solar))

p7 <- ggplot(solar, aes(x = hour, y = avg_solar, color = city)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = city_colors) +
  scale_x_continuous(breaks = seq(0, 21, 3), labels = function(h) sprintf("%02d:00", h)) +
  labs(title = "Average solar radiation by hour",
       subtitle = "Kef is excluded: its sensor reported ~950 W/m\u00b2 day and night (sensor fault)",
       x = "Hour of day", y = "Solar radiation (W/m\u00b2)") +
  theme_report()
save_fig(p7, "07_solar_daily_cycle.png")

# 8. Overview panel ------------------------------------------------------------------
overview <- (p1 + labs(subtitle = NULL) | p4 + labs(subtitle = NULL)) /
  (p3 + labs(subtitle = NULL) | p6 + labs(subtitle = NULL)) +
  plot_annotation(
    title = "Tunisia climate stations: Bizerte, Sousse and Kef",
    subtitle = paste("Hourly sensor data,", common_label),
    theme = theme(plot.title = element_text(face = "bold", size = 16),
                  plot.subtitle = element_text(color = "gray35"))
  )
save_fig(overview, "08_overview.png", 14, 10)

cat("\nAll figures saved to output/figures/\n")

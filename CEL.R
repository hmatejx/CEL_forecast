library(openxlsx)
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)
library(scales)
library(prophet)


# load data
cel <- as_tibble(read.xlsx("CEL.xlsx", sheet = 1))
cel$DATE <- as.Date(as.POSIXct(cel$DATE * (24*60*60),
                               origin = "1899-12-30", 
                               tz = "GMT"))


# convert to long format
cel %>% mutate(CEL_per_USER := OUTSIDE / USERS,
               CEL_per_ACTIVE := OUTSIDE / ACTIVE,
               Price := 0.25*(Open + High + Low + Close)) %>%
  pivot_longer(-c(DATE)) -> cel


# plot the CEL outside per user
# outside = circulating supply - under celsius management - in app
cel %>% filter(name %in% c("CEL_per_ACTIVE", "CEL_per_USER")) %>%
  ggplot(aes(x = DATE, y = value, col = name)) + 
  geom_line(size = 1.5) + 
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x))) +
  annotation_logticks(sides = "l") +
  ylab("CEL per user")


# Prophet models
# prepare data frames
cel %>%
  filter(name == "USERS") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>%
  mutate(y := log(y)) -> df1
cel %>%
  filter(name == "ACTIVE") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>%
  mutate(y := log(y)) -> df2
cel %>%
  filter(name == "OUTSIDE") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>% 
  mutate(y := log(y)) -> df3
cel %>%
  filter(name == "Price") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>% 
  mutate(y := log(y)) -> df4
cel %>%
  filter(name == "CEL_per_ACTIVE") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>% 
  mutate(y := log(y)) -> df5
cel %>%
  filter(name == "CEL_per_USER") %>%
  select(-name) %>% 
  rename(ds := DATE, y := value) %>% 
  mutate(y := log(y)) -> df6
# fit models & forecast
horizon = as.numeric(as.Date("2021-12-31") - max(cel$DATE))
CL <- 0.9
m1 <- prophet(df1)
future1 <- make_future_dataframe(m1, periods = horizon)
forecast1 <- predict(m1, future1, interval.width = CL)
forecast1[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast1[, c("yhat", "yhat_lower", "yhat_upper")])
m1$history$y <- exp(m1$history$y)
m2 <- prophet(df2)
future2 <- make_future_dataframe(m2, periods = horizon)
forecast2 <- predict(m2, future2, interval.width = CL)
forecast2[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast2[, c("yhat", "yhat_lower", "yhat_upper")])
m2$history$y <- exp(m2$history$y)
m3 <- prophet(df3)
future3 <- make_future_dataframe(m3, periods = horizon)
forecast3 <- predict(m3, future3, interval.width = CL)
forecast3[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast3[, c("yhat", "yhat_lower", "yhat_upper")])
m3$history$y <- exp(m3$history$y)
m4 <- prophet(df4)
future4 <- make_future_dataframe(m4, periods = horizon)
forecast4 <- predict(m4, future4, interval.width = CL)
forecast4[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast4[, c("yhat", "yhat_lower", "yhat_upper")])
m4$history$y <- exp(m4$history$y)
m5 <- prophet(df5)
future5 <- make_future_dataframe(m5, periods = horizon)
forecast5 <- predict(m5, future5, interval.width = CL)
forecast5[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast5[, c("yhat", "yhat_lower", "yhat_upper")])
m5$history$y <- exp(m5$history$y)
m6 <- prophet(df6)
future6 <- make_future_dataframe(m6, periods = horizon)
forecast6 <- predict(m6, future6, interval.width = CL)
forecast6[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast6[, c("yhat", "yhat_lower", "yhat_upper")])
m6$history$y <- exp(m6$history$y)

# plot the forecast of users
p1 <- plot(m1, forecast1) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x)),
                limits = c(1e3, 1e7)) +
  xlab("Date") + 
  ylab("Predicted number of TOTAL USERS") +
  geom_text(x = max(forecast1$ds) - 0.05*diff(range(forecast1$ds)), 
            y = log10(forecast1$yhat[nrow(forecast1)]), 
            label = paste0("M: ", round(forecast1$yhat[nrow(forecast1)], -4)),
            check_overlap = T, size = 4, hjust = 1, fontface = "bold") +
  geom_text(x = max(forecast1$ds) - 0.05*diff(range(forecast1$ds)), 
            y = log10(forecast1$yhat_lower[nrow(forecast1)]), 
            label = paste0("L: ", round(forecast1$yhat_lower[nrow(forecast1)], -4)),
            check_overlap = T, size = 4, hjust = 1) +
  geom_text(x = max(forecast1$ds) - 0.05*diff(range(forecast1$ds)), 
            y = log10(forecast1$yhat_upper[nrow(forecast1)]), 
            label = paste0("U: ", round(forecast1$yhat_upper[nrow(forecast1)], -4)),
            check_overlap = T, size = 4, hjust = 1) +
  annotation_logticks(sides = "l") +
  theme_gray(base_size = 14)

# plot the forecast of active users
p2 <- plot(m2, forecast2) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x)),
                limits = c(1e3, 1e7)) +
  xlab("Date") + 
  ylab("Predicted number of ACTIVE USERS") +
  geom_text(x = max(forecast2$ds) - 0.05*diff(range(forecast2$ds)), 
            y = log10(forecast2$yhat[nrow(forecast2)]), 
            label = paste0("M: ", round(forecast2$yhat[nrow(forecast2)], -4)),
            check_overlap = T, size = 4, hjust = 1, fontface = "bold") +
  geom_text(x = max(forecast2$ds) - 0.05*diff(range(forecast2$ds)), 
            y = log10(forecast2$yhat_lower[nrow(forecast2)]), 
            label = paste0("L: ", round(forecast2$yhat_lower[nrow(forecast2)], -4)),
            check_overlap = T, size = 4, hjust = 1) +
  geom_text(x = max(forecast2$ds) - 0.05*diff(range(forecast2$ds)), 
            y = log10(forecast2$yhat_upper[nrow(forecast2)]), 
            label = paste0("U: ", round(forecast2$yhat_upper[nrow(forecast2)], -4)),
            check_overlap = T, size = 4, hjust = 1) +
  annotation_logticks(sides = "l") +
  theme_gray(base_size = 14)

# plot the forecast of CEL outside
p3 <- plot(m3, forecast3) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 3),
                labels = trans_format("log10", scales::math_format(10^.x))) +
  xlab("Date") +
  ylab("Predicted amount of CEL outside") +
  annotation_logticks(sides = "l") +
  theme_gray(base_size = 14)

# plot the forecast of CEL price
p4 <- plot(m4, forecast4) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x))) + 
  xlab("Date") +
  ylab("Predicted CEL Price (USD)") +
  annotation_logticks(sides = "l") +
  geom_text(x = max(forecast4$ds) - 0.05*diff(range(forecast4$ds)), 
            y = log10(forecast4$yhat[nrow(forecast4)]), 
            label = paste0("M: ", round(forecast4$yhat[nrow(forecast4)], 1)),
            check_overlap = T, size = 4, hjust = 1, fontface = "bold") +
  geom_text(x = max(forecast4$ds) - 0.05*diff(range(forecast4$ds)), 
            y = log10(forecast4$yhat_lower[nrow(forecast4)]), 
            label = paste0("L: ", round(forecast4$yhat_lower[nrow(forecast4)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  geom_text(x = max(forecast4$ds) - 0.05*diff(range(forecast4$ds)), 
            y = log10(forecast4$yhat_upper[nrow(forecast4)]), 
            label = paste0("U: ", round(forecast4$yhat_upper[nrow(forecast4)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  theme_gray(base_size = 14)

# plot the forecast of CEL price
p5 <- plot(m5, forecast5) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x))) + 
  xlab("Date") +
  ylab("Predicted amount of CEL_per_ACTIVE") +
  annotation_logticks(sides = "l") +
  geom_text(x = max(forecast5$ds) - 0.05*diff(range(forecast5$ds)), 
            y = log10(forecast5$yhat[nrow(forecast5)]), 
            label = paste0("M: ", round(forecast5$yhat[nrow(forecast5)], 1)),
            check_overlap = T, size = 4, hjust = 1, fontface = "bold") +
  geom_text(x = max(forecast5$ds) - 0.05*diff(range(forecast5$ds)), 
            y = log10(forecast5$yhat_lower[nrow(forecast5)]), 
            label = paste0("L: ", round(forecast5$yhat_lower[nrow(forecast5)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  geom_text(x = max(forecast5$ds) - 0.05*diff(range(forecast5$ds)), 
            y = log10(forecast5$yhat_upper[nrow(forecast5)]), 
            label = paste0("U: ", round(forecast5$yhat_upper[nrow(forecast5)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  theme_gray(base_size = 14)

# plot the forecast of CEL price
p6 <- plot(m6, forecast6) +
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x))) + 
  xlab("Date") +
  ylab("Predicted amount of CEL_per_USER") +
  geom_text(x = max(forecast6$ds) - 0.05*diff(range(forecast6$ds)), 
            y = log10(forecast6$yhat[nrow(forecast6)]), 
            label = paste0("M: ", round(forecast6$yhat[nrow(forecast6)], 1)),
            check_overlap = T, size = 4, hjust = 1, fontface = "bold") +
  geom_text(x = max(forecast6$ds) - 0.05*diff(range(forecast6$ds)), 
            y = log10(forecast6$yhat_lower[nrow(forecast6)]), 
            label = paste0("L: ", round(forecast6$yhat_lower[nrow(forecast6)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  geom_text(x = max(forecast6$ds) - 0.05*diff(range(forecast6$ds)), 
            y = log10(forecast6$yhat_upper[nrow(forecast6)]), 
            label = paste0("U: ", round(forecast6$yhat_upper[nrow(forecast6)], 1)),
            check_overlap = T, size = 4, hjust = 1) +
  annotation_logticks(sides = "l") +
  theme_gray(base_size = 14)

# plot the forecast of CEL_per_USER
cel %>% 
  filter(name %in% c("Price", "CEL_per_USER", "USERS")) %>% 
  pivot_wider() %>% filter(USERS > 50000) %>%
  ggplot(aes(x = CEL_per_USER, y = Price)) + 
  geom_point() +  scale_x_log10() + scale_y_log10() +
  annotation_logticks(sides = "bl") +
  geom_smooth(method = "loess") +
  theme_gray(base_size = 14) -> p7

# plot everything on one page
grid.arrange(p1, p2, p7, p5, p6, p4, nrow = 2)

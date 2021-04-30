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
# fit models & forecast
m1 <- prophet(df1)
future1 <- make_future_dataframe(m1, periods = 250)
forecast1 <- predict(m1, future1)
forecast1[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast1[, c("yhat", "yhat_lower", "yhat_upper")])
m1$history$y <- exp(m1$history$y)
m2 <- prophet(df2)
future2 <- make_future_dataframe(m2, periods = 250)
forecast2 <- predict(m2, future2)
forecast2[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast2[, c("yhat", "yhat_lower", "yhat_upper")])
m2$history$y <- exp(m2$history$y)
m3 <- prophet(df3)
future3 <- make_future_dataframe(m3, periods = 250)
forecast3 <- predict(m3, future3)
forecast3[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast3[, c("yhat", "yhat_lower", "yhat_upper")])
m3$history$y <- exp(m3$history$y)
m4 <- prophet(df4)
future4 <- make_future_dataframe(m4, periods = 250)
forecast4 <- predict(m4, future4)
forecast4[, c("yhat", "yhat_lower", "yhat_upper")] <- 
  exp(forecast4[, c("yhat", "yhat_lower", "yhat_upper")])
m4$history$y <- exp(m4$history$y)

# plot the forcast of users
p1 <- plot(m1, forecast1) + 
  scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x)),
                limits = c(1e3, 1e7)) +
  xlab("Date") + 
  ylab("Predicted number of TOTAL USERS") +
  theme_gray(base_size = 14)
p2 <- plot(m2, forecast2) +
    scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x, n = 4),
                labels = trans_format("log10", scales::math_format(10^.x)),
                limits = c(1e3, 1e7)) +
  xlab("Date") + 
  ylab("Predicted number of ACTIVE USERS") +
  theme_gray(base_size = 14)
grid.arrange(p1, p2, nrow = 1)

# plot the forecast of CEL outside
p3 <- plot(m3, forecast3) +
  xlab("Date") +
  ylab("Predicted amount of CEL outside") +
  theme_gray(base_size = 14)
print(p3)

# plot the forecast of CEL price
p4 <- plot(m4, forecast4)   +
  scale_y_log10() + 
  xlab("Date") +
  ylab("Predicted amount of CEL outside") +
  annotation_logticks(sides = "l") +
  theme_gray(base_size = 14)
print(p4)

# plot the correlation of CEL price and CEL_per_USER
cel %>% 
  filter(name %in% c("Price", "CEL_per_USER", "USERS")) %>% 
  pivot_wider() %>% filter(USERS > 50000) %>%
  ggplot(aes(x = CEL_per_USER, y = Price)) + 
  geom_point() +  scale_x_log10() + scale_y_log10() +
  annotation_logticks(sides = "bl") +
  theme_gray(base_size = 14)

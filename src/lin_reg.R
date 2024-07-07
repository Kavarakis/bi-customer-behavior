
# Load necessary libraries
library(data.table)
library(ggplot2)
library(lubridate)

# Simple Linear Regression: Analyze the relationship between total sales and time
# Calculate daily sales

data <- fread("./src/data/full_data.csv")

daily_sales <- data[event_type == 'purchase', .(total_sales = sum(price, na.rm = TRUE)), by = .(date = as.Date(event_time))]

# Fit simple linear regression model
simple_lm <- lm(total_sales ~ date, data = daily_sales)

# Plot the regression results
p1 <- ggplot(daily_sales, aes(x = date, y = total_sales)) +
  geom_point(color = "blue") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(title = "Simple Linear Regression: Total Sales Over Time", x = "Date", y = "Total Sales") +
  theme_minimal()
ggsave("lin-reg.png", plot = p1)

# Multiple Linear Regression: Explore the relationship between sales revenue and multiple independent variables
# Create a dataset for regression analysis
# Aggregate data by user_session to calculate total sales and other variables
session_data <- data[event_type == 'purchase', .(
  total_sales = sum(price, na.rm = TRUE),
  avg_price = mean(price, na.rm = TRUE),
  session_duration = mean(session_duration, na.rm = TRUE),
  time_of_day = unique(time_of_day),
  user_segment = unique(user_segment)
), by = user_session]

# Ensure categorical variables are factors
session_data[, time_of_day := as.factor(time_of_day)]
session_data$user_segment <- NULL
multiple_lm <- lm(total_sales ~ avg_price + session_duration + time_of_day, data = session_data)
summary(multiple_lm)
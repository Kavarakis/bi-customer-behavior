# Load necessary libraries
library(data.table)
library(ggplot2)
library(lubridate)
library(fitdistrplus)

data <- fread("./src/data/full_data.csv")

# 1. Conversion Funnel: Funnel chart showing the number of users at each stage (view, add to cart, purchase)
# Aggregate data to get the number of users at each stage
funnel_data <- data[, .N, by = event_type]
funnel_data <- funnel_data[event_type %in% c('view', 'cart', 'purchase')]
funnel_data <- funnel_data[order(-N)]

# Plot the conversion funnel
p1 <- ggplot(funnel_data, aes(x = reorder(event_type, N), y = N)) +
  geom_bar(stat = 'identity', fill = 'blue', color = 'black') +
  coord_flip() +
  labs(title = 'Conversion Funnel', x = 'Stage', y = 'Number of Users') +
  theme_minimal()
ggsave("conversion_funnel.png", plot = p1)

# Remove outliers for session durations
sum(data$session_duration > 180)
session_durations <- data[data$session_duration <= 180]$session_duration

# 2. Plot histogram
p2 <- hist(session_durations, breaks = 50, probability = TRUE, 
           main = "Distribution of Session Durations",
           xlab = "Session Duration (mins)",
           col = "blue", border = "black")
# Save the histogram
ggsave("session_duration_distribution.png")

# 3. Customer Segmentation: Scatter plot showing different customer segments based on their behavior metrics
# Aggregate data by customer segments to count the number of users in each segment
customer_segments <- data[, .N, by = .(user_segment)]

# Plot the customer segments
p3 <- ggplot(customer_segments, aes(x = user_segment, y = N, color = user_segment)) +
  geom_point(size = 5) +
  geom_text(aes(label = N), vjust = -1, color = "black") +
  labs(title = 'Customer Segments', x = 'Segment', y = 'Number of Users') +
  theme_minimal()
ggsave("customer_segments.png", plot = p3)

# KPI 1: Conversion Rate
total_visitors <- data[, .N, by = user_session][, .N]
purchases <- data[event_type == 'purchase', .N, by = user_session][, .N]
conversion_rate <- purchases / total_visitors * 100

# Plot Conversion Rate
conversion_rate_data <- data.table(KPI = "Conversion Rate", Value = conversion_rate)
p4 <- ggplot(conversion_rate_data, aes(x = KPI, y = Value)) +
  geom_bar(stat = "identity", fill = "blue") +
  labs(title = "Conversion Rate", y = "Percentage") +
  theme_minimal()
ggsave("conversion_rate.png", plot = p4)

# KPI 2: Average Session Duration
avg_session_duration <- data[, mean(session_duration, na.rm = TRUE)]

# Plot Average Session Duration
avg_session_duration_data <- data.table(KPI = "Average Session Duration", Value = avg_session_duration)
p5 <- ggplot(avg_session_duration_data, aes(x = KPI, y = Value)) +
  geom_bar(stat = "identity", fill = "blue") +
  labs(title = "Average Session Duration (mins)", y = "Minutes") +
  theme_minimal()
ggsave("average_session_duration.png", plot = p5)

# KPI 3: Bounce Rate
single_page_sessions <- data[, .N, by = user_session][N == 1, .N]
bounce_rate <- single_page_sessions / total_visitors * 100

# Plot Bounce Rate
bounce_rate_data <- data.table(KPI = "Bounce Rate", Value = bounce_rate)
p6 <- ggplot(bounce_rate_data, aes(x = KPI, y = Value)) +
  geom_bar(stat = "identity", fill = "blue") +
  labs(title = "Bounce Rate", y = "Percentage") +
  theme_minimal()
ggsave("bounce_rate.png", plot = p6)

# KPI 4: Cart Abandonment Rate
add_to_cart_sessions <- data[event_type == 'cart', .N, by = user_session][, .N]
cart_abandonment_rate <- (add_to_cart_sessions - purchases) / add_to_cart_sessions * 100

# Plot Cart Abandonment Rate
cart_abandonment_rate_data <- data.table(KPI = "Cart Abandonment Rate", Value = cart_abandonment_rate)
p7 <- ggplot(cart_abandonment_rate_data, aes(x = KPI, y = Value)) +
  geom_bar(stat = "identity", fill = "blue") +
  labs(title = "Cart Abandonment Rate", y = "Percentage") +
  theme_minimal()
ggsave("cart_abandonment_rate.png", plot = p7)

# KPI 5: Revenue per Visitor
total_revenue <- data[event_type == 'purchase', sum(price, na.rm = TRUE)]
revenue_per_visitor <- total_revenue / total_visitors

# Plot Revenue per Visitor
revenue_per_visitor_data <- data.table(KPI = "Revenue per Visitor", Value = revenue_per_visitor)
p8 <- ggplot(revenue_per_visitor_data, aes(x = KPI, y = Value)) +
  geom_bar(stat = "identity", fill = "blue") +
  labs(title = "Revenue per Visitor", y = "Revenue") +
  theme_minimal()
ggsave("revenue_per_visitor.png", plot = p8)

# KPI 6: Product Views and Purchases
product_performance <- data[event_type %in% c('view', 'purchase'), .(
  views = sum(event_type == 'view'),
  purchases = sum(event_type == 'purchase')
), by = product_id]
# Replace NA values with 0 (if any)
product_performance[is.na(product_performance)] <- 0
product_performance[, total_interactions := views + purchases]

# Select the top 10 most performant products based on total interactions
top_products <- product_performance[order(-total_interactions)][1:10]

# Melt the data for plotting
top_products_melted <- melt(top_products, id.vars = "product_id", variable.name = "type", value.name = "count")
# Plot Product Views and Purchases
p9 <- ggplot(top_products_melted, aes(x = reorder(product_id, -count), y = count, fill = type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Top 10 Most Performant Products by Views and Purchases", x = "Product ID", y = "Count") +
  theme_minimal() +
  coord_flip()
ggsave("top_products_views_purchases.png", plot = p9)

# Lineplot of Session Duration by Hour of Day
data[, hour := hour(event_time)]
session_duration_by_hour <- data[, .(avg_duration = mean(session_duration, na.rm = TRUE)), by = hour]
# Plot the data using line plot
p10 <- ggplot(session_duration_by_hour, aes(x = hour, y = avg_duration)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 2) +
  geom_text(aes(label = round(avg_duration, 2)), vjust = -1, color = "black") +
  scale_x_continuous(breaks = 0:23) +
  labs(title = "Average Session Duration by Hour of Day", x = "Hour of Day", y = "Average Session Duration (mins)") +
  theme_minimal()
ggsave("session_duration_by_hour.png", plot = p10)



# Extract day of the week and hour from 'event_time'
data[, `:=`(day_of_week = wday(event_time, label = TRUE), hour = hour(event_time))]

# Aggregate data to count events by day of the week and hour
activity_by_day_hour <- data[, .N, by = .(day_of_week, hour)]

# Plot the heatmap
p11 <- ggplot(activity_by_day_hour, aes(x = hour, y = day_of_week, fill = N)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(
    title = "User Activity Heatmap by Day and Hour",
    x = "Hour of Day",
    y = "Day of Week",
    fill = "Number of Events"
  ) +
  theme_minimal()

# Save the plot
ggsave("user_activity_heatmap.png", plot = p11)

# Print the plot
print(p11)


# Load necessary libraries
library(dplyr)
library(readr)
library(lubridate)

# Load the dataset
data <- read_csv("./data/2019-Oct.csv")

# Display the first few rows of the dataset
head(data)

# 1. Handle missing values
# Check for missing values
sapply(data, function(x) sum(is.na(x)))

# Drop rows with missing values in critical columns
# like 'session_id' and 'event_type'
data <- data %>% drop_na(session_id, event_type)

# 2. Data type conversion
# Convert 'event_time' to Date-Time format if it's not already
data$event_time <- as_datetime(data$event_time)

# 3. Removing duplicates
# Remove duplicate rows if any
data <- data %>% distinct()

# 4. Filtering data
# Remove irrelevant data, such as bot traffic,
# which may have session durations of zero or other invalid criteria
# This step will depend on specific criteria relevant to your dataset,
# such as unusual session durations or counts
# Example filter, adjust according to your data
data <- data %>% filter(event_type != "bot_traffic")

# 5. Feature engineering
# Create a new feature: session duration
data <- data %>%
    group_by(session_id) %>%
    mutate(session_duration = as.numeric(difftime(max(event_time), min(event_time), units = "mins"))) %>%
    ungroup()

# Create a new feature: categorize time of day (morning, afternoon, evening, night)
data <- data %>%
    mutate(time_of_day = case_when(
        hour(event_time) >= 5 & hour(event_time) < 12 ~ "Morning",
        hour(event_time) >= 12 & hour(event_time) < 17 ~ "Afternoon",
        hour(event_time) >= 17 & hour(event_time) < 21 ~ "Evening",
        TRUE ~ "Night"
    ))

# Create a new feature: user segments based on behavior
data <- data %>%
    group_by(session_id) %>%
    mutate(user_segment = case_when(
        any(event_type == "purchase") ~ "Purchaser",
        any(event_type == "add_to_cart") & !any(event_type == "purchase") ~ "Cart Abandoner",
        TRUE ~ "Browser"
    )) %>%
    ungroup()

# Display the first few rows of the cleaned and prepared dataset
head(data)

# Save the cleaned dataset for further analysis
write_csv(data, "cleaned_ecommerce_data.csv")

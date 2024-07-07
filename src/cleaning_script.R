# Load necessary libraries
library(data.table)
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(fasttime)  # Faster date-time conversion
file_name <- "2019-Nov"
data <- read_csv(paste0("./src/data/",file_name,'.csv'))

# 1. Handle missing values
# Check for missing values
sapply(data, function(x) sum(is.na(x)))

# Drop rows with missing values in critical columns like 'session_id' and 'event_type'
data <- data %>% drop_na(category_code, brand, user_session)
# Save data.frame to csv and continue with data.table
fwrite(data,paste0('./src/data/', file_name, '-drop-na.csv'))
rm(data)
data <- fread(paste0('./src/data/', file_name, '-drop-na.csv'))
# Display the first few rows of the dataset
head(data)


# 2. Data type conversion
# Convert 'event_time' to Date-Time format if it's not already
data[, event_time := fastPOSIXct(event_time)]
# 3. Removing duplicates
# Remove duplicate rows if any
data <- unique(data)

# 4. Filtering data
# Remove irrelevant data, such as bot traffic,
# which may have session durations of zero or other invalid criteria
# This step will depend on specific criteria relevant to your dataset,
# such as unusual session durations or counts
# Example filter, adjust according to your data
data <- data %>% filter(event_type != "bot_traffic")

# 5. Feature engineering
# Step 1: Calculate the min and max event times for each session
session_times <- data[, .(min_time = min(event_time), max_time = max(event_time)), by = user_session]
# Step 2: Join the results back to the original data.table
data <- merge(data, session_times, by = "user_session")

# Step 3: Calculate session duration
data[, session_duration := as.numeric(difftime(max_time, min_time, units = "mins"))]

# Remove the temporary columns
data[, c("min_time", "max_time") := NULL]


# Create a new feature: categorize time of day (morning, afternoon, evening, night)
# Vectorized time of day categorization
data[, hour := hour(event_time)]
data[hour >= 5 & hour < 12, time_of_day := 'Morning']
data[hour >= 12 & hour < 17, time_of_day := 'Afternoon']
data[hour >= 17 & hour < 21, time_of_day := 'Evening']
data[is.na(time_of_day), time_of_day := 'Night']
data[, hour := NULL]  # Clean up temporary 'hour' column

# Create a new feature: user segments based on behavior

# Step 1: Calculate the user segment for each session
user_segments <- data[, .(
  has_purchase = any(event_type == 'purchase'),
  has_add_to_cart = any(event_type == 'cart')
), by = user_session]

# Step 2: Assign segments based on precomputed flags
user_segments[, user_segment := fifelse(
  has_purchase, 'Purchased',
  fifelse(has_add_to_cart, 'Cart Abandoned', 'Browse')
)]

# Step 3: Merge the segments back to the main data.table
data <- merge(data, user_segments[, .(user_session, user_segment)], by = 'user_session', all.x = TRUE)



data %>% group_by(user_segment) %>% summarise(count=n())
data %>% group_by(time_of_day) %>% summarise(count=n())

# Display the first few rows of the cleaned and prepared dataset
head(data)


# Save the cleaned dataset for further analysis
fwrite(data, paste0("./src/data/", file_name ,"_cleaned_data.csv"))

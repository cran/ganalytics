library(ganalytics)

# Assumes app creds can be found in environment variables (default prefix) or in a JSON file (default filename)
# Selects default view of first property in first account returned by the Management API.
myQuery <- GaQuery()

GaView(myQuery) <- ga_view_selector()
GetGaData(myQuery)

readline("Press enter to continue.")
# Example 1 - Setting the date range

# Set the date range to last 180 days.
DateRange(myQuery) <- c(Sys.Date() - 180L, Sys.Date() - 1L)

myData <- GetGaData(myQuery)
summary(myData)

# Adjust the start date to 60 days ago:
StartDate(myQuery) <- Sys.Date() - 60L
# Adjust the end date to 30 days ago:
EndDate(myQuery) <- Sys.Date() - 30L

myData <- GetGaData(myQuery)
summary(myData)

readline("Press enter to continue.")
# Example 2 - Choosing what metrics to report

# Report number of page views instead
Metrics(myQuery) <- "pageviews"

myData <- GetGaData(myQuery)
summary(myData)

# Report both pageviews and sessions
Metrics(myQuery) <- c("pageviews", "sessions")
# These variations are also acceptable
Metrics(myQuery) <- c("ga:pageviews", "ga.sessions")

myData <- GetGaData(myQuery)
summary(myData)

readline("Press enter to continue.")
# Example 3 - Selecting what dimensions to split your metrics by

# Similar to metrics, but for dimensions
Dimensions(myQuery) <- c("year", "week", "dayOfWeek", "hour")

# Lets set a wider date range
DateRange(myQuery) <- c(Sys.Date() - 180L, Sys.Date() - 1L)

myData <- GetGaData(myQuery)
head(myData)
tail(myData)

readline("Press enter to continue.")
# Example 4 - Sort by

# Sort by descending number of pageviews
SortBy(myQuery) <- "-pageviews"

myData <- GetGaData(myQuery)
head(myData)
tail(myData)

readline("Press enter to continue.")
# Example 5 - Row filters

# Filter for Sunday sessions only
sundayExpr <- Expr(~dayofweek == "0")
TableFilter(myQuery) <- sundayExpr

myData <- GetGaData(myQuery)
head(myData)

# Remove the filter
TableFilter(myQuery) <- NULL

myData <- GetGaData(myQuery)
head(myData)

readline("Press enter to continue.")
# Example 6 - Combining filters with AND

# Expression to define Sunday sessions
sundayExpr <- Expr(~dayofweek == "0")
# Expression to define organic search sessions
organicExpr <- Expr(~medium == "organic")
# Expression to define organic search sessions made on a Sunday
sundayOrganic <- sundayExpr & organicExpr
TableFilter(myQuery) <- sundayOrganic

myData <- GetGaData(myQuery)
head(myData)

# Let's concatenate medium to the dimensions for our query
Dimensions(myQuery) <- c(Dimensions(myQuery), "medium")

myData <- GetGaData(myQuery)
head(myData)

readline("Press enter to continue.")
# Example 7 - Combining filters with OR

# In a similar way to AND
loyalExpr <- !Expr(~sessionCount %matches% "^[0-3]$") # Made more than 3 sessions
recentExpr <- Expr(~daysSinceLastSession %matches% "^[0-6]$") # Visited sometime within the past 7 days.
loyalOrRecent <- loyalExpr | recentExpr
TableFilter(myQuery) <- loyalOrRecent

myData <- GetGaData(myQuery)
summary(myData)

readline("Press enter to continue.")
# Example 8 - Filters that combine ORs with ANDs

loyalExpr <- !Expr(~sessionCount %matches% "^[0-3]$") # Made more than 3 sessions
recentExpr <- Expr(~daysSinceLastSession %matches% "^[0-6]$") # Visited sometime within the past 7 days.
loyalOrRecent <- loyalExpr | recentExpr
sundayExpr <- Expr(~dayOfWeek == "0")
loyalOrRecent_Sunday <- loyalOrRecent & sundayExpr
TableFilter(myQuery) <- loyalOrRecent_Sunday

myData <- GetGaData(myQuery)
summary(myData)

# Perform the same query but change which dimensions to view
Dimensions(myQuery) <- c("sessionCount", "daysSinceLastSession", "dayOfWeek")

myData <- GetGaData(myQuery)
summary(myData)

readline("Press enter to continue.")
# Example 9 - Sorting 'numeric' dimensions (continuing from example 8)

# Continuing from example 8...

# Change filter to loyal session AND recent sessions AND visited on Sunday
loyalAndRecent_Sunday <- loyalExpr & recentExpr & sundayExpr
TableFilter(myQuery) <- loyalAndRecent_Sunday

# Sort by descending visit count and ascending days since last visit.
SortBy(myQuery) <- c("-sessionCount", "+daysSinceLastSession")
myData <- GetGaData(myQuery)
head(myData)

# Notice that Google Analytics' Core Reporting API doesn't recognise 'numerical' dimensions as
# ordered factors when sorting. We can use R to sort instead, using a dplyr::arrange function.
library(dplyr)
myData <- myData %>% arrange(desc(sessionCount), daysSinceLastSession)
head(myData)
tail(myData)

readline("Press enter to continue.")
# Example 10 - Session segmentation

# Visit segmentation is expressed similarly to row filters and supports AND and OR combinations.
# Define a segment for sessions where a "thank-you", "thankyou" or "success" page was viewed.
thankyouExpr <- Expr(~pagePath %matches% "thank\\-?you|success")
Segments(myQuery) <- list(thankyou = thankyouExpr)

# Reset the filter
TableFilter(myQuery) <- NULL

# Split by traffic source and medium
Dimensions(myQuery) <- c("source", "medium")

# Sort by descending number of sessions
SortBy(myQuery) <- "-sessions"

myData <- GetGaData(myQuery)
head(myData)

readline("Press enter to continue.")
# Example 11 - Using automatic pagination to get more than 10,000 rows of data per query

# Sessions by date and hour for the past two years.
# First let's clear any filters or segments defined previously
TableFilter(myQuery) <- NULL
Segments(myQuery) <- NULL
# Define our date range
DateRange(myQuery) <- c(Sys.Date() - 730L, Sys.Date() - 1L)
# Define our metrics and dimensions
Metrics(myQuery) <- "sessions"
Dimensions(myQuery) <- c("date", "dayOfWeek", "hour")
# Let's allow a maximum of 17544 rows (default is 10000)
MaxResults(myQuery) <- 17545

myData <- GetGaData(myQuery)
nrow(myData)

# Sessions by day of week
sessions_by_dayOfWeek <- myData %>%
  group_by(dayOfWeek) %>%
  summarise(sessions = sum(sessions)) %>%
  ungroup()
with(sessions_by_dayOfWeek, barplot(sessions, names.arg = dayOfWeek))

# Sessions by hour of day
sessions_by_hour <- myData %>%
  group_by(hour) %>%
  summarise(sessions = sum(sessions)) %>%
  ungroup()
with(sessions_by_hour, barplot(sessions, names.arg = hour))

readline("Press enter to continue.")
# Example 12 - Using ggplot2

library(ggplot2)

# Sessions by date and hour for the past two years
# First let's clear any filters or segments defined previously
TableFilter(myQuery) <- NULL
Segments(myQuery) <- NULL
# Define our date range
DateRange(myQuery) <- c(Sys.Date() - 730L, Sys.Date() - 1L)
# Define our metrics and dimensions
Metrics(myQuery) <- "sessions"
Dimensions(myQuery) <- c("date", "dayOfWeek", "hour", "deviceCategory")
# Let's allow a maximum of 40000 rows (default is 10000)
MaxResults(myQuery) <- 40000

myData <- GetGaData(myQuery)

# Sessions by hour of day and day of week
avg_sessions_by_hour_wday_mobile <- myData %>%
  group_by(hour, dayOfWeek, deviceCategory) %>%
  summarise(sessions = mean(sessions)) %>%
  ungroup()

# Relabel the days of week
levels(avg_sessions_by_hour_wday_mobile$dayOfWeek) <- c(
  "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
)

# Plot the summary data
qplot(
  x = hour,
  y = sessions,
  data = avg_sessions_by_hour_wday_mobile,
  facets = ~dayOfWeek,
  fill = deviceCategory,
  geom = "col"
)

readline("Press enter to continue.")
# Real-time reporting API

my_creds <- GoogleApiCreds(userName = "johanndeboer@gmail.com", appCreds = "~/client_secret.json")

rt_query <- RtQuery(view = "ga:987654321", creds = my_creds)
Dimensions(rt_query) <- "rt:minutesAgo"
Metrics(rt_query) <- "rt:pageviews"
GetGaData(rt_query)

# In the above example, set userName to yours that you use to access Google
# Analytics (this is optional, but ensures you are authenticating under the
# correct Google account), and set the appCreds to the path of where you have
# saved your Google APIs Project OAuth application credentials JSON file (which
# you can download from the Google APIs Console). Also set view to the ID of the
# Google Analytics view of which you wish to get real-time reporting data for.

readline("Press enter to continue.")
# Querying more than 10 metrics

Dimensions(myQuery) <- c("date", "dayofweekname")
TableFilter(myQuery) <- NULL
Segments(myQuery) <- NULL
DateRange(myQuery) <- c(Sys.Date() - 7L, Sys.Date() - 1L)

Metrics(myQuery) <- c(
  "pageviews", "entrances", "bounces", "exits", "timeonpage",
  "totalEvents", "transactionRevenue", "goalCompletionsAll", "transactions", "uniqueEvents",
  "uniquePageviews"
)

GetGaData(myQuery)


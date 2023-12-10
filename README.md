# reintroduceR

**reintroduceR** is an R package designed to support conservationists in planning and adapting wildlife reintroductions based on results extracted from movement ecology data and other post-monitoring data sets.

## Installation

You can install the package from GitHub using the `devtools` package:

```R
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install reintroduceR from GitHub
devtools::install_github("your_username/reintroduceR")
Replace "your_username" with your GitHub username.

Functions
disp_dist
The disp_dist function uses wildlife tracking data with multiple animal IDs to extract dispersal distances, calculating the release location distance from the centroid of the remaining points.

Example Usage:

R
Copy code
library(reintroduceR)

# Assuming you have a dataframe 'dat' with tracking data
result <- disp_dist(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", crs = st_crs("EPSG:32648"))
days_to_settle_mcp
The days_to_settle_mcp function identifies the average amount of days a series of tracked animals takes on average to settle into their new environment after translocation/reintroduction. It utilizes convex hull updates and logistic growth modeling to simulate settlement.

Example Usage:

R
Copy code
library(reintroduceR)

# Assuming you have a dataframe 'dat' with tracking data
result <- days_to_settle_mcp(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", DateTime = datetime, crs = st_crs("EPSG:32648"))
print(result[[1]])  # MCP data
print(result[[2]])  # Summary of logistic growth model
print(result[[3]])  # Plot of logistic growth model
Maintainer
Maintainer: Russell J. Gray
Maintainer Email: rjgrayecology@gmail.com

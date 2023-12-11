![alt text](https://i.ibb.co/4FJ8KgC/reintroduce-R-long.png)

# reintroduceR

**reintroduceR** is an R package designed to support conservationists in planning and adapting wildlife reintroductions based on results extracted from movement ecology data and other post-monitoring data sets. Note that all functions assume a series of data with unique animal IDs identifying multiple reintroduced animals of the same species. The functions are not meant for the analysis for multiple species at once, since the associated metrics may vary from species to species.

## Installation

You can install the package from GitHub using the `devtools` package:

```{r}
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install reintroduceR from GitHub
devtools::install_github("RJGrayEcology/reintroduceR")
```
# Functions
## disp_dist
The **disp_dist** function uses wildlife tracking data with multiple animal IDs to extract dispersal distances, calculating the release location distance from the centroid of the remaining points.
```{r}
Example Usage:

R
```{r}
library(reintroduceR)

# Assuming you have a dataframe 'dat' with tracking data, which includes X and Y coordinates in UTM projection, a column with animal IDs, and a date/time column in standard format (using asPosixCT or anytime functions, for exaple)

result <- disp_dist(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", DateTime=datetime, crs = "EPSG:32648")
```
## days_to_settle_mcp

The **days_to_settle_mcp** function identifies the average amount of days a series of tracked animals takes on average to settle into their new environment after translocation/reintroduction. It utilizes convex hull updates and logistic growth modeling to simulate settlement.

Example Usage:

```{r}
library(reintroduceR)

# Assuming you have a dataframe 'dat' with tracking data, which includes X and Y coordinates in UTM projection, a column with animal IDs, and a date/time column in standard format (using asPosixCT or anytime functions, for exaple)

result <- days_to_settle_mcp(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", DateTime = datetime, crs = "EPSG:32648")
print(result[[1]])  # MCP data
print(result[[2]])  # Summary of logistic growth model
print(result[[3]])  # Plot of logistic growth model
```

# Maintainer
**Maintainer:** Russell J. Gray <br>
**Maintainer Email:** rjgrayecology@gmail.com

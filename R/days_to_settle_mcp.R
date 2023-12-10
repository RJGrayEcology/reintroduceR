#' Calculate Days to Settle Using Minimum Convex Polygon (MCP)
#'
#' The \code{days_to_settle_mcp} function identifies the average number of days it takes for a series of tracked animals to settle into their new environment after translocation or reintroduction. The settling date is determined by updating a convex hull iteratively for each animal ID until the animal only moves within the occupied space, and no longer outside of it, indicating the animal is no-longer going on long-distance exploratory jaunts. A logistic growth model is then fitted using the number of days and updated geometry to simulate a logistic growth curve. Settlement is considered to be achieved when the curve reaches 95% of the plateau.
#'
#' @param x A data frame containing tracking data.
#' @param coords A character vector specifying the columns representing the coordinates (e.g., c("UTM_X", "UTM_Y")).
#' @param ID A character string specifying the column containing unique animal IDs.
#' @param DateTime The column containing datetime information. This must be in standardized format class "POSIXct" "POSIXt"
#' @param crs An object specifying the coordinate reference system (e.g., st_crs("EPSG:32648")). Note all coordinates should be projected in UTM format for metric measurement, not WGS84 latlong.
#'
#' @return A list containing three elements:
#'   \itemize{
#'     \item \code{mcp_all}: A data frame with columns \code{ID}, \code{DateTime}, \code{mcp_area}, and \code{Days} representing the tracked animals, datetime, cumulative MCP area, and number of days, respectively.
#'     \item \code{summary_nls_res}: A summary of the logistic growth model fit using \code{nls} with details on the coefficients.
#'     \item \code{nls_plot}: A \code{ggplot} object visualizing the logistic growth model prediction with vertical and horizontal lines indicating the estimated plateau.
#'   }
#'
#' @examples
#' \dontrun{
#' # Example usage
#' dat <- read.csv("tracking_data.csv")
#' result <- days_to_settle_mcp(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", DateTime = datetime, crs = st_crs("EPSG:32648"))
#'
#' print(result[[1]])  # sf data frame of the updated convex hull area and days for each animal ID
#' print(result[[2]])  # summary of the nls model
#' print(result[[3]])  # ggplot object showing the logistic growth curve results
#' }
#'
#' @seealso
#' \code{\link{st_as_sf}}, \code{\link{st_crs}}, \code{\link{st_distance}}, \code{\link{st_combine}}, \code{\link{st_convex_hull}}, \code{\link{ggplot}}, \code{\link{nls}}
#'
#' @export


days_to_settle_mcp <- function(x, coords, ID, DateTime, crs) {
  # Convert dataframe to sf object
  dat <- st_as_sf(x, coords = coords, crs = crs)

  # Remove IDs with fewer than 4 records
  id_counts <- table(dat$ID)
  invalid_ids <- names(id_counts[id_counts < 4])
  dat <- dat[!(dat$ID %in% invalid_ids), ]

  # Check if there are remaining IDs
  if (nrow(dat) == 0) {
    print("No valid IDs with at least 4 records.")
    return(NULL)
  }

  # Initialize progress bar
  pb <- progress_bar$new(
    format = "[:bar] :percent Elapsed: :elapsed",
    total = length(unique(dat$ID))
  )

  # Initialize variables
  cumulative_areas <- data.frame(ID = integer(), Cumulative_Area = numeric())

  # Initialize variable to store cumulative areas
  cumulative_areas <- data.frame(ID = integer(), DateTime = character(), Cumulative_Area = numeric())

  # store mcp_all
  mcp_all <- NULL

  # turn off the messages of summarize() function
  options(dplyr.summarise.inform = FALSE)

  # Iterate through points for each ID to calculate cumulative area
  for (id in unique(dat$ID)) {
    pb$tick()  # Increment progress bar

    id_data <- subset(dat, ID == id) %>% arrange({{DateTime}})

    # Check for and remove invalid geometries
    id_data <- id_data[st_is_valid(id_data$geometry), ]

    cumulative_area <- numeric()

    for (i in 2:nrow(id_data)) {
      # Select points up to the current iteration
      current_dat <- id_data[1:i, ]

      # Check if all geometries are valid
      if (all(st_is_valid(current_dat$geometry))) {
        # Calculate MCP (Minimum Convex Polygon)
        mcp <- current_dat %>%
          group_by({{ID}}) %>%
          summarise(geometry = st_combine(geometry),
                    DateTime = max({{DateTime}}),
                    ID = id) %>%
          st_convex_hull()

        mcp_all <- rbind(mcp_all, mcp)

      }
    }
  }

  # Extract area and calculate cumulative sum
  mcp_all <- mcp_all %>%
    mutate(mcp_area = as.numeric(st_area(geometry)) / 1e6)%>%
    arrange(ID, DateTime) %>%
    group_by(ID) %>%
    arrange(ID, DateTime)%>%
    mutate(Days = as.numeric(difftime(DateTime, first(DateTime), units = "days")))


  # make logistic growth model
  nls_res = nls(mcp_area ~ SSlogis(Days, Asym, xmid, scal), data=mcp_all)

  # Add vertical and horizontal lines for the estimated plateau
  plateau_percentage <- 0.95  # Adjust as needed

  # Estimate plateau value
  plateau_value <- coef(nls_res)["Asym"] * plateau_percentage

  # Create a new data frame for prediction
  new_data <- data.frame(Days = seq(min(mcp_all$Days), max(mcp_all$Days), length.out = 100))

  # Generate predicted values
  predicted_data <- data.frame(
    Days = new_data$Days,
    Predicted_mcp_area = predict(nls_res, newdata = new_data)
  )

  # Find the day corresponding to the plateau value
  plateau_day <- predicted_data$Days[which.min(abs(predicted_data$Predicted_mcp_area - plateau_value))]

  # Determine suitable x and y coordinates for the bottom right of the plot
  max_x <- max(predicted_data$Days)
  min_y <- min(predicted_data$Predicted_mcp_area)

  # Plot the predicted curve
  nls_plot <- ggplot() +
    geom_line(data=predicted_data, aes(x = Days, y = Predicted_mcp_area),
              color = "red", linetype = "dashed", size=1) +
    geom_hline(yintercept = plateau_value, linetype = "dotted", color = "grey40", size=0.8) +
    geom_vline(xintercept = predicted_data$Days[which.min(abs(predicted_data$Predicted_mcp_area - plateau_value))], linetype = "dotted", color = "grey40", size=0.8) +
    geom_text(aes(x = max_x, y = min_y,
                  label = paste(round(plateau_day), "Days until settled", "\n",
                                "Area occupied = ", round(plateau_value, 2), "km²")),
              vjust = 0, hjust = 1, color = "black") +
    labs(title = "Logistic Growth Model Prediction", subtitle = "(Settlement = 95% before asymptote)",
         x = "Days", y = expression("Predicted area occupied (km"^{2}~")")) +
    theme_bw(base_size = 15)


  pb$terminate()  # Close progress bar

  # Return the dataframe
  return(list(mcp_all, summary(nls_res), nls_plot))
}

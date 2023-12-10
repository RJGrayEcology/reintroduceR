#' Calculate Dispersal Distances
#'
#' The \code{disp_dist} function calculates dispersal distances for wildlife tracking data. You can combine the output via ID with any existing species metadata - e.g. sex, mass, age class, etc. - to identify trends and variations in dispersal distances. This can help in planning, for example, for:
#' -species with territorial males/females and how far - by averaging the output for each sex - they should be released away from one another.
#' -to identify dispersal trends in habituated vs. non-habituated animals to inform captive enrichment strategy changes
#' -to identify dispersal trends between the same species relocated in various sites/ecosystems to see if there are differences that may indicate preference - reduced dispersal could indicate highly abundant resources and lack of need for long-distance exploration.
#'
#' @param x A data frame containing tracking data.
#' @param coords A character vector specifying the columns representing the coordinates (e.g., c("UTM_X", "UTM_Y")).
#' @param ID A character string specifying the column containing unique animal IDs.
#' @param DateTime The column containing datetime information. This must be in standardized format class "POSIXct" "POSIXt"
#' @param crs An object specifying the coordinate reference system (e.g., st_crs("EPSG:32648")). Note all coordinates should be projected in UTM format for metric measurement, not WGS84 latlong.
#'
#' @return A data frame with columns \code{ID} and \code{disp_dist} representing animal IDs and dispersal distances, respectively.
#'
#' @examples
#' \dontrun{
#' # Example usage
#' dat <- read.csv("tracking_data.csv")
#' meta <- read.csv("meta_data.csv")
#'
#' disp_distances <- disp_dist(dat, coords = c("UTM_X", "UTM_Y"), ID = "ID", DateTime = datetime, crs = st_crs("EPSG:32648"))
#'
#' meta <- left_join(meta, disp_distances, by="ID") #note: this uses dplyr function left_join
#' }
#'
#' @seealso
#' \code{\link{st_distance}}, \code{\link{st_as_sf}}, \code{\link{st_crs}}
#'
#' @export

disp_dist <- function(x, coords, ID, DateTime, crs) {
  # Convert dataframe to sf object
  dat <- st_as_sf(x, coords = coords, crs = crs)

  # Get the release location
  # First get the minimum coordinates (release location)
  rel.sf <-  dat%>%
    group_by({{ID}})%>%
    filter({{DateTime}} == min({{DateTime}}))

  # then get the centroid of the rest of the coordinate data excluding the release location
  cent.sf <-  dat%>%
    group_by({{ID}})%>%
    filter({{DateTime}} != min({{DateTime}}))%>%
    group_by({{ID}})%>%
    summarise(UTM_X = mean(st_coordinates(.)[, 1]),
              UTM_Y = mean(st_coordinates(.)[, 2]))%>%
    st_as_sf()

  # Calculate distances
  dists <- st_distance(rel.sf, cent.sf, by_element = TRUE, na.rm=TRUE)

  # Create a data frame with ID and disp_dist columns
  result_df <- data.frame(ID = rel.sf$ID, disp_dist = dists)

  return(result_df)
}

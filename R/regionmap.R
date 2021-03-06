#' Get a map of the region specified
#'
#' @export
#' @template regionid
#' @return map of the region
#' @note there's a number of warnings that print, all related to \pkg{ggplot2},
#' they are most likely okay, and don't indicate a problem
#' @examples \dontrun{
#' regionmap("eez")
#' regionmap(region = "eez", id = 76)
#'
#' # a different region type
#' regionmap(region = "lme", id = 23)
#' }
regionmap <- function(region, id) {
  # draw all regions
  url <- paste(getapibaseurl(), region, "?geojson=true", sep = "/")
  tfile <- tempfile()
  on.exit(unlink(tfile))
  res <- httr::GET(url, httr::write_disk(tfile))
  dat <- sf::read_sf(readLines(tfile, warn = FALSE, encoding = "UTF-8"))

  if (!missing(id)) { # draw specified region
    url <- paste(getapibaseurl(), region, paste(id, "?geojson=true", sep = ""),
                 sep = "/")
    tfile2 <- tempfile()
    on.exit(unlink(tfile2))
    res <- httr::GET(url, httr::write_disk(tfile2))
    rsp <- sf::read_sf(readLines(tfile2, warn = FALSE, encoding = "UTF-8"))

    # get bounds for map zoom
    bounds <- sf::st_bbox(rsp)
    dim <- round(max(diff(bounds[c(1,3)]), diff(bounds[c(2,4)])))
    center <- c(mean(bounds[c(1,3)]), mean(bounds[c(2,4)]))
    xlim <- c(center[1] - dim, center[1] + dim)
    ylim <- c(center[2] - dim, center[2] + dim)
  }

  # draw the map
  map <- ggplot(dat) +
    geom_sf(colour = "#394D66", fill = "#536D8E", size = 0.25)

  if (!missing(id)) {
    map <- map +
      geom_sf(data = rsp, colour = "#449FD5", fill = "#CAD9EC", size = 0.25)
  }

  if (identical(region, "eez") && !missing(id)) { # use ifa for eez
    url <- paste(getapibaseurl(), region, id, "ifa", "?geojson=true", sep = "/")
    tfile3 <- tempfile()
    on.exit(unlink(tfile3))
    res <- httr::GET(url, httr::write_disk(tfile3))
    ifa <- sf::read_sf(readLines(tfile3, warn = FALSE, encoding = "UTF-8"))
    map <- map +
      geom_sf(data = ifa, colour = "#E96063", fill = "#E38F95", size = 0.25)
  }

  map <- map +
    borders("world", colour = "#333333", fill = "#EDE49A", size = 0.25) +
    theme_map()

  if (!missing(id)) {
    map <- map + coord_sf(xlim = xlim, ylim = ylim)
  } else {
    map <- map + coord_sf()
  }

  return(map)
}

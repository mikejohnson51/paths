#' @title Compare simular paths
#' @description Given a set of GPS points with defined paths, compares those with the same end nodes and compute the areal differnce between a direct line and the path choosen.
#' @param gps sf sf pbect from gpx \code{gpx_to_point} with a path added from \code{add_paths}.
#' @param same_paths a table pof same paths produced with \code{find_same_paths}
#' @param truth  set on known locations for each point in route
#' @return a sf object with area, path lengths, and path times
#' @export
#' @importFrom sf st_distance st_buffer st_coordinates st_linestring st_sfc st_sf st_set_crs st_crs st_difference st_intersection st_polygon st_zm st_union
#' @importFrom dplyr filter
#' @importFrom units set_units
#'


compare_paths = function(gps, same_paths, truth){

  all = list()
  truth = st_transform(truth, st_crs(gps))

  empty <- st_as_sfc("POINT(EMPTY)")

  rate = gps %>% mutate(
    elapsed_time = lead(time) - time,
    distance_to_next = as.numeric(sf::st_distance(
      geometry,
      lead(geometry, default = empty),
      by_element = TRUE)),
      rate = distance_to_next/as.numeric(elapsed_time))

  rem = which(rate$rate > 2)
  rem = c(rem-1,  rem, rem+1)
  rem2 = which((rate$distance_to_next > 25))
  rem3 = unique(c(rem,rem2))
  g = gps[-rem3,]

  for(p in 1:nrow(same_paths)){

    tmp = same_paths[p, ]

    l1 = g[g$path == tmp$Path1,]
    l2 = g[g$path == tmp$Path2,]

    trueStart = truth[truth$location == tmp$start,]
    trueEnd   = truth[truth$location == tmp$end,]

    l1 = l1[sort(c(which.min(st_distance(trueStart, l1)):which.min(st_distance(trueEnd, l1)))),]
    l2 = l2[sort(c(which.min(st_distance(trueStart, l2)):which.min(st_distance(trueEnd, l2)))),]

    l1$geometry[which.min(st_distance(trueStart, l1))] = trueStart$geometry
    l2$geometry[which.min(st_distance(trueStart, l2))] = trueStart$geometry

    l1$geometry[which.min(st_distance(trueEnd, l1))] = trueEnd$geometry
    l2$geometry[which.min(st_distance(trueEnd, l2))] = trueEnd$geometry

    make_lines = function(coords, gps){
        st_linestring(coords) %>%
        st_sfc() %>% st_sf() %>%
        st_set_crs(st_crs(gps))
    }

    int = st_coordinates(rbind(trueStart, trueEnd)) %>% make_lines(gps)

    line1 = l1  %>% st_coordinates() %>% make_lines(gps)

    line2 = l2  %>% st_coordinates() %>% make_lines(gps)


    ppp = rbind(st_cast(line1,"POLYGON"), st_cast(line2,"POLYGON")) %>% lwgeom::st_make_valid()

    u = ppp %>% st_intersection()  %>% filter(n.overlaps == 1) %>%
        st_set_crs(st_crs(gps)) %>%
        st_union() %>%
        st_sf() %>%
        st_zm()

    u = st_cast(u, 'POLYGON') %>% mutate(a = st_area(.), feild = 1) #%>% filter(as.numeric(a) > 20)

    u =  u %>%
      group_by(feild) %>%
      summarise() %>%
      st_cast()

    if(st_geometry_type(u) == "GEOMETRYCOLLECTION") {
      u = u %>%
      st_collection_extract("POLYGON") %>%
      st_union() %>%
      st_sf() %>%
      st_zm()
    }

    u$start = tmp$start
    u$end = tmp$end
    u$area = sum(units::set_units(st_area(u), "m^2"))
    u$straight_length = units::set_units(st_length(int), "m")
    u$path1_length = units::set_units(st_length(line1), "m")
    u$path2_length = units::set_units(st_length(line2), "m")
    u$path1_time = abs(l1$time[1] - l1$time[nrow(l1)])
    u$path2_time = abs(l2$time[1] - l2$time[nrow(l2)])

    all[[p]] = u
  }

  do.call(rbind, all)
}

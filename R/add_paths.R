#' @title Build Paths
#' @description Add a new attribute to a GPX file processed with
#'
#' @param gps a gps file processed form GPX with \code{gpx_to_points}
#' @param truth a set on known locations for each point in route
#' @param route a vector of destinations
#'
#' @return gps object with added path ID
#' @importFrom sf st_distance st_transform st_crs

add_paths = function(gps, truth, route){

  u = unique(route)
  breaks = list()
  counts = list()
  truth = st_transform(truth, st_crs(gps))

  for(i in 1:length(u)){
    t = sum(route == u[i])
    d = st_distance(gps, truth[truth$location == u[i],])
    index = order(d, decreasing = F)

    fin.index = NA

    fin.index[1] = index[1]

    index = index[abs(fin.index[1] - index) > 5]

    for(j in 2:t){
      fin.index[j] = index[1]
      index = index[abs(fin.index[j] - index) > 5]
    }

    breaks[[u[i]]] = sort(fin.index)
  }

  break_index = route

  for(i in 1:length(u)){

    log = which(route == u[i])

    for(j in 1:length(log)){

      break_index[log[j]] = breaks[[u[i]]][j]
    }
  }

  break_index = as.numeric(break_index)
  break_index = cbind(break_index[-length(break_index)], break_index[-1])
  break_index[2:nrow(break_index),1] = break_index[2:nrow(break_index),1] + 1

  gps$path = 0

  for(i in 1:nrow(break_index)){
    gps$path[break_index[i,1]:break_index[i,2]] = i
  }

  gps

}

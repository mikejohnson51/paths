#' @title Find same paths within a vector of destinations
#' @param route a vector of destinations
#' @return a data.frame containing the path start and end nodes and order in route.
#' @export
#' @importFrom stats setNames

find_same_paths = function(route){

  x = cbind(route[-length(route)], route[-1]) %>% data.frame(stringsAsFactors = F)

  tmp = do.call(paste0,x)

  yyy = lapply(1:nrow(x), function(y){
    A <- x[y, ]
    A[order(A)]
  })

  dd = data.frame(matrix(unlist(yyy), ncol = 2, byrow = T), stringsAsFactors = F)

  ind = duplicated(dd)

  all = dd[ind,]
  match = list()
  for(i in 1:nrow(all)){
    match[[i]] = which(dd[,1] == all[i,1] & dd[,2] == all[i,2])
  }

  df = setNames(do.call(rbind, match) %>% data.frame(stringsAsFactors = F),
                c("Path1", "Path2"))

  df$start = x[df$Path1,1]
  df$end   = x[df$Path1,2]

  df
}

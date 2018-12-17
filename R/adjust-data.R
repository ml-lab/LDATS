library(dplyr)

ldats_rod <- read.csv('inst/extdata/rodents.csv', stringsAsFactors = F)

ldats_rod_adj <- ldats_rod[,4:25]

adj <- function(rodents_row) {
  
  if(rodents_row[1] == 392) {
    return(rodents_row)
  } else {
    rodents_row_adj <- c(392, (floor(392 * 
                               (rodents_row[2:length(rodents_row)] 
                                / rodents_row[1]))))
    return(rodents_row_adj)
  }
  
}

ldats_rod_adj <- apply(ldats_rod_adj, MARGIN = 1, 
                       FUN = adj)
ldats_rod_adj <- t(ldats_rod_adj)

colnames(ldats_rod_adj) <- colnames(ldats_rod)[4:25]
ldats_rod_adj <- cbind(ldats_rod[1:3], ldats_rod_adj)

write.csv(ldats_rod_adj, 'inst/extdata/rodents-adj.csv', row.names = F)

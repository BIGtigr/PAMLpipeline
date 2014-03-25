#!/bin/R

library(ape)
library(R.utils)

#Read command line arguments
args <- commandArgs(trailingOnly = TRUE)

infile <- args[2]

tmp <- read.table(infile)

names <- tmp[2:nrow(tmp),1]
names <- as.vector(names)
Taxa <- unlist(lapply(names, function(x) substr(x, nchar(x)-3, nchar(x))))

TaxNames <- c("Dmel", "Dana", "Dere", "Dgri", "Dmoj", "Dper", "Dpse", "Dsec", "Dsim", "Dvir", "Dwil", "Dyak")

NodeList <- c()
for (i in Taxa){
    ind.2 <- which(TaxNames == i)
    NodeList<- c(NodeList, ind.2)
}

tmptree <- read.tree("treefile.txt")
pruned.tree<-drop.tip(tmptree,tmptree$tip.label[-match(NodeList, tmptree$tip.label)])
#make name that matches infile name
outfile <- paste(infile, ".tre", sep='')
write.tree(pruned.tree, file =outfile)

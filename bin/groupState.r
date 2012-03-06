#samples <- read.csv("s.csv")
samples <- read.csv("public/csv_pnc/ss09pnc.csv")

# this groups everything out, but it includes rows that are empty in the PINCP section. If all the PINCP sections are zero, then I want
# to filter them out.
groups <- with(samples, ftable(
  SEX, 
  ANC, 
  cut(AGEP,breaks=c(0,18,25,30,35,40,50,60,Inf)),
  cut(SCHL,breaks=c(1,12,Inf),labels=c('HS','College')),
  cut(PINCP,breaks=c(seq(0,10,by=2)*10000,Inf))
))
data <- as.data.frame(groups)
data <- subset(data,Freq > 0) # exclude anything that doesn't actually have any values
write.csv(data,file="out.csv",row.names=FALSE)

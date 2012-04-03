#samples <- read.csv("s.csv")
samples <- read.csv("public/csv_pnc/ss09pnc.csv")

# this groups everything out, but it includes rows that are empty in the PINCP section. If all the PINCP sections are zero, then I want
# to filter them out.
# ANC, You need at least ANC1P too...ANC by itself doesn't work.
groups <- with(samples, ftable(
  SEX, 
  cut(AGEP,breaks=c(0,18,25,30,35,40,50,60,Inf)),
  cut(SCHL,breaks=c(1,12,17,Inf),labels=c('HS','College','Graduate')),
  cut(PINCP,breaks=c(seq(0,20,by=2)*10000,Inf))
))

# so I do this, to filter out the non-events:
data <- as.data.frame(groups)
data <- subset(data,Freq > 0)
colnames(data) <- c('Sex','Age','School','Income','IncomeCount')

write.csv(data,file="out.csv",row.names=FALSE)

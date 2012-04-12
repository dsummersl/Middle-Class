#samples <- read.csv("csv_hnc/ss10hnc.csv")
samples <- read.csv("csv_pnc/ss10pnc.csv")

# group by:
# PUMA = public use micro area
# AGEP = age
# SCHL = schooling
# PINCP = total person's income

# TODO additional fields I like:
# FINC = family income
# VEH = # of vehicles
# VAL = property value (see docs - not straight forward)
# ACR = size of the property you live on.
# BDS or RMS = number of bedrooms or # of rooms
# HFL = heating method (gas, wood, etc)
# PLM = do you ahve complete plumbing (toilet, shower, hot/cold)
# TEN = owned, mortgaged, etc...
# FES or HHT or WKEXREL = family type (married, not married - different employment status's)
# HHL = household language
# HINCP = household income..
# MV = how long you've lived where you live
# FPARC = presence of kids...
# FINC = family income

schoolGroups <- c('NA','None','Preschool','<=6th','<=8th','9th','10th','11th','12th','Highschool Grad','<1yr college','1+yr college','associates','bachelors','masters','professional','doctorate')
groups <- with(samples, ftable(
  PUMA, 
  SEX,
  cut(AGEP,breaks=c(0,18,25,30,35,40,50,60,Inf)),
  #cut(SCHL,breaks=c(NA,seq(1,16)),labels=schoolGroups),
  SCHL,
  cut(PINCP,breaks=c(seq(0,20,by=2)*10000,Inf))
))

# so I do this, to filter out the non-events:
data <- as.data.frame(groups)
data <- subset(data,Freq > 0)

colnames(data) <- c('PUMA','Sex','Age','School','Income','IncomeCount')

# replace all the string funkiness with ints
data$Age <- factor(data$Age,labels=c(17,24,30,34,39,49,59,100))
data$Income <- factor(data$Income,labels=c(seq(2,20,by=2)*10,10000))

write.csv(data,file="out.csv",row.names=FALSE)

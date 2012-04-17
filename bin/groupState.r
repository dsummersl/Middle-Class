#samples <- read.csv("csv_hnc/ss10hnc.csv")
#samples <- read.csv('/Volumes/My\ Book/data/ss10ptxsplit1.csv')
samples <- read.csv(commandArgs(TRUE))

# group by:
# PUMA = public use micro area
# AGEP = age
# SCHL = schooling
# PINCP = total person's income
# ST = State

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
# http://www.sigmafield.org/2009/09/23/r-function-of-the-day-cut
groups <- with(samples, ftable(
  ST,
  PUMA, 
  SEX,
  cut(AGEP,breaks=c(0,18,25,30,35,40,50,60,Inf)),
  #cut(SCHL,breaks=c(NA,seq(1,16)),labels=schoolGroups),
  SCHL,
  cut(PINCP,breaks=c(seq(1,20)*5000,Inf))
))

# so I do this, to filter out the non-events:
data <- as.data.frame(groups)
data <- subset(data,Freq > 0)

colnames(data) <- c('State','PUMA','Sex','Age','School','Income','IncomeCount')

data$Age <- factor(data$Age,labels=c(17,24,30,34,39,49,59,100))
# change the levels so that they match the incomes that actually exist
# TODO wrong wrong wrong...need to fix this for texas and for iowa
#c("(0,2e+04]","(2e+04,4e+04]","(4e+04,6e+04]","(6e+04,8e+04]","(8e+04,1e+05]","(1e+05,1.2e+05]","(1.2e+05,1.4e+05]","(1.4e+05,1.6e+05]","(1.6e+05,1.8e+05]","(1.8e+05,2e+05]","(2e+05,Inf]")
data$Income <- factor(data$Income,labels=c(seq(1,19)*5,100000))

write.csv(data,file="out.csv",row.names=FALSE)

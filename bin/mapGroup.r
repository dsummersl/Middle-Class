# take in the group data from bin/groupState.r and map it up:
samples <- read.csv("out.csv")
quartz()
plot(samples$Sex,samples$Ancestry)
# factor lets me label the genders up...
plot(factor(samples$Sex,labels=c("Male","Female")),factor(samples$Age,labels=c("<18","19-25","26-30","31-35","36-40","41-50","51-60",">61")))
pairs(samples)

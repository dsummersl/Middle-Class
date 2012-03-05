#samples <- read.csv("s.csv")
samples <- read.csv("public/csv_pnc/ss09pnc.csv")
subsamples <- samples[c("SEX","AGEP","ANC","SCHL","PINCP")]
# sum up the remaining income:
#grouped <- aggregate(subsamples,list(sex=subsamples[,"SEX"],age=subsamples[,"AGEP"],ancestry=subsamples[,"ANC"],schooling=subsamples[,"SCHL"]),sum)
# just count the number that match the pattern:
grouped <- aggregate(subsamples,list(sex=subsamples[,"SEX"],age=subsamples[,"AGEP"],ancestry=subsamples[,"ANC"],schooling=subsamples[,"SCHL"],less10=subsamples[,"PINCP"] < 10000,greater10=subsamples[,"PINCP"] >= 10000),length)
#summary(grouped)
grouped

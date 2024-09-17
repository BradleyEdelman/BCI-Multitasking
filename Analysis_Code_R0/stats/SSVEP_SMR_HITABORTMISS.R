rm(list = ls())


library(readr)
library(lsr)
library(dunn.test)
tmp.txt <- read.table("M:/_bci_Multitasking/SSVEP_SMRResult.txt", header=TRUE)
myData = data.frame(tmp.txt)

# SSVEP_SMRResult.txt
# ET_DwellTime_SMRResult.txt
# ITR_2.txt


myData <- within(myData,{
  subjid <- factor(subjid)
  cond <- factor(cond)
  pair <- factor(pair)
})

myData <- myData[order(myData$subjid), ]
head(myData)

vars=colnames(myData)
vars=vars[4:length(vars)]


Hit<-array(1,length(vars))
Abort<-array(1,length(vars))
Miss<-array(1,length(vars))
Hit2<-array(1,length(vars))
Miss2<-array(1,length(vars))
Abort2<-array(1,length(vars))
etaHit<-array(1,length(vars))
etaAbort<-array(1,length(vars))
etaMiss<-array(1,length(vars))
shapTot<-array(1,length(vars))
shapHit<-array(1,length(vars))
shapAbort<-array(1,length(vars))
shapMiss<-array(1,length(vars))


for (i in 1:length(vars)){
  
  myData$tmp <- as.numeric(unlist(myData[vars[i]]))
  myData.mean <- aggregate(myData$tmp,
                           by = list(myData$subjid, myData$cond, myData$pair), FUN = 'mean')
  #head(myData.mean)
  
  colnames(myData.mean) <- c("subjid","cond","pair","tmp")
  
  myData.mean <- myData.mean[order(myData.mean$subjid), ]
  head(myData.mean)
  
  # 2 way ANOVA - time, treatment main effects
  var.aov <- aov(tmp ~ cond + Error(subjid), data=myData)
  print(summary(var.aov))
  
  # Test normality of residuals
  tmp <- proj(var.aov)
  var.resid <- tmp[[3]][, "Residuals"]
  var.shap <- shapiro.test(var.resid)
  shapTot[i]=var.shap$p.value
  hist(var.resid)
  
  var.aov <- with(aov(tmp ~ pair),data=myData.mean)
  #print(TukeyHSD(var.aov))
  
  # Tukey HSD post Hoc
  tmp<-TukeyHSD(var.aov)
  tmp2<-data.frame(tmp$pair)
  tmp3<-tmp2["p.adj"]
  Hit[i]=tmp3$p.adj[1]
  Abort[i]=tmp3$p.adj[10]
  Miss[i]=tmp3$p.adj[15]
  print(tmp3)
  
  #kruskal.test(tmp~cond,data=myData.mean)
  #pairwise.wilcox.test(myData.mean$tmp,myData.mean$pair,p.adj="bonferroni", exact=F, paired=T)
  #dunn.test(as.numeric(myData.mean$pair),as.numeric(myData.mean$tmp),method="bonferroni")
  
}


# shapTot
# shapDT
# shapCP
# shapCPS
# etaCP
# etaDT
# etaCPS

# dev.off()


rm(list = ls())

tmp.txt <- read.table("M:/_bci_Multitasking/Accuracy.txt", header=TRUE)
myData = data.frame(tmp.txt)

# Accuracy.txt
# SSVEP_Amp.txt
# Congruency.txt
# ET_DwellTime.txt
# ITR_1.txt
# Rsq.txt


myData <- within(myData,{
  subjid <- factor(subjid)
  cond <- factor(cond)
})

myData <- myData[order(myData$subjid), ]
head(myData)

vars = colnames(myData)
vars = vars[3:length(vars)]

ACC = array(1,length(vars))
shap = array(1,length(vars))
eta = array(1,length(vars))

for (i in 1:length(vars)){
  
  
  myData$tmp <- as.numeric(unlist(myData[vars[i]]))
  myData.mean <- aggregate(myData$tmp,
                           by = list(myData$subjid, myData$cond), FUN = 'mean')
  # head(myData.mean)
  
  colnames(myData.mean) <- c("subjid","cond","var")
  
  myData.mean <- myData.mean[order(myData.mean$subjid), ]
  head(myData.mean)
  
  # 2 way ANOVA - condition main effect only
  var.aov <- with(myData.mean,aov(var ~ cond + Error(subjid)))
  print(summary(var.aov))
  ACC[i] = as.numeric(unlist(summary(var.aov)[2])[9])
  
  # Test normality of residuals
  tmp <- proj(var.aov)
  var.resid = tmp[[3]][, "Residuals"]
  var.shap = shapiro.test(var.resid)
  shap[i] = var.shap$p.value
  hist(var.resid)
  
  library(lsr)
  var.aov <- with(myData.mean,aov(var ~ cond))
  eta[i] = etaSquared(var.aov)[1]
  
}

which(ACC<.05)
p.adjust(ACC[1:2],method = "bonferroni",n=2)

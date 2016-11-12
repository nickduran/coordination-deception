library(multcomp) 
library(reshape2) 
library(plyr) 
library(ggplot2) 
library(psych) 
library(xlsx)
library(MuMIn) 
library(lme4) 
library(data.table)

library(scales) 
require(grid)
library(gridExtra) 
library(cowplot) 

#######################
##// MOVEMENT ANALYSIS
#######################

##// STEP 1 INITIAL DATA PREP

a = read.table("~synchronyMovementRapp.csv",sep=",",header=TRUE)  #<<<<<<<<<<<<<

##// clean-up, name columns
colnames_add = names(a[69:76])
colnames(a) = c('dyad','order','ConvoVeracity','ConvoArgument','bodypartA','bodypartB',seq(-5000, 5000, length.out=61),'analysis',colnames_add)
a = a[,c(68,1:6,69,70:76,7:67)]

##// generate clean file (saved as synchronyRapport1.xlsx in GitHub)
# write.xlsx(a, "synchronyDEMO.xlsx", append=TRUE, sheetName="Movement1")   #<<<<<<<<<<<<<

##// select analysis that corresponds to windowed lagged cross correlation analysis
newa = a[a$analysis == '3',] # {1='xcorr',2='xcorrV',3='wincross',4='wincrossV'};

##// select analysis that corresponds to region of head movements
BODYPART = '1' # {1 = head, 2 = mid, 3 = legs}
newa = newa[newa$bodypartA == BODYPART & newa$bodypartB == BODYPART,] 

##// select lagged regions of interest
##// region around 0 lag
newa1 = newa[,c(45:47,1:15)] # region around 0 ms -.1333-0-.1333
newa1$region = "lag0"
##// negative values, NAIVE FOLLOWS
newa2 = newa[,c(40:44, 1:15)] # outside of 0 lag 
newa2$region = "Nfoll1000"
newa3 = newa[,c(16:39, 1:15)] # outside of 1000lag
newa3$region = "Nfoll5000"
##// positive values, DA FOLLOWS
newa4 = newa[,c(48:52,1:15)] # outside of 0lag  
newa4$region = "DAfoll1000"
newa5 = newa[,c(53:76,1:15)] # outside of 1000lag
newa5$region = "DAfoll5000"

##// additional data prep to "melt" data 
newa1m = melt(newa1,id=c("dyad","ConvoVeracity","ConvoArgument","order","analysis",'sex','bodypartA','bodypartB','topic','Q1_mean','Q2_mean','Q3_mean','Q1_abs','Q2_abs','Q3_abs','region'))
test1 = describeBy(newa1m$value,list(newa1m$ConvoVeracity,newa1m$ConvoArgument),mat=TRUE)
newa2m = melt(newa2,id=c("dyad","ConvoVeracity","ConvoArgument","order","analysis",'sex','bodypartA','bodypartB','topic','Q1_mean','Q2_mean','Q3_mean','Q1_abs','Q2_abs','Q3_abs','region'))
newa3m = melt(newa3,id=c("dyad","ConvoVeracity","ConvoArgument","order","analysis",'sex','bodypartA','bodypartB','topic','Q1_mean','Q2_mean','Q3_mean','Q1_abs','Q2_abs','Q3_abs','region'))
newa4m = melt(newa4,id=c("dyad","ConvoVeracity","ConvoArgument","order","analysis",'sex','bodypartA','bodypartB','topic','Q1_mean','Q2_mean','Q3_mean','Q1_abs','Q2_abs','Q3_abs','region'))
newa5m = melt(newa5,id=c("dyad","ConvoVeracity","ConvoArgument","order","analysis",'sex','bodypartA','bodypartB','topic','Q1_mean','Q2_mean','Q3_mean','Q1_abs','Q2_abs','Q3_abs','region'))

syncBind = rbind(newa1m,newa2m,newa3m,newa4m,newa5m)

##// generate clean file (saved as synchronyRapport2.xlsx in GitHub)
# write.xlsx(syncBind, "synchronyRapport2.xlsx", append=TRUE, sheetName="Movement2")  #<<<<<<<<<<<<<

##// STEP 2 SET UP CODING FOR STATISTICAL ANALYSIS (DEVIATION/EFFECT CODING)
 
syncBind$region = factor(syncBind$region) 
newa = syncBind  
newa$dyad = as.factor(newa$dyad)
newa$order = as.factor(newa$order)  
newa$topic = as.factor(newa$topic)
 
newa$ConvoVeracity = factor(newa$ConvoVeracity, levels = c(1, 0), labels=c("Deception", "Truth")) 
contrasts(newa$ConvoVeracity) = contr.sum(2)/2 #// set up deviation/effect coding 

newa$ConvoArgument = factor(newa$ConvoArgument, levels = c(1, 2), labels=c("Disagree", "Agree")) 
contrasts(newa$ConvoArgument) = contr.sum(2)/2 #// set up deviation/effect coding 

contrasts(newa$order) = contr.sum(2)/2 

##// planned comparison between mixed and female
mat = matrix(c(1/3, 1/3, 1/3, 1, 0, -1, 1, -1, 1), ncol = 3)
mymat = solve(t(mat))
my.contrasts<-mymat[,2:3]
contrasts(newa$sex) = my.contrasts

##// STEP 3: RUN STATS 

##// function generates model summary table 
modelout = function(model,DVname,MODname){
    coefs = data.frame(summary(model)$coef)
    coefs$p = 2*(1-pnorm(abs(coefs$t.value)))    
    gg = coefs
    gg$r2m = r.squaredGLMM(model)[1]
    gg$r2c = r.squaredGLMM(model)[2]
    gg$dvname = c(DVname)
    gg$modelname = c(MODname)
    is.num = sapply(gg, is.numeric)
    gg[is.num] = lapply(gg[is.num], round, 3)
    gg = rbind(gg,"*****")
    return(gg)
}

dfList = list(df1=subset(newa, region=="lag0"), df2=subset(newa, region=="Nfoll1000"), df3=subset(newa, region=="Nfoll5000"), df4=subset(newa, region=="DAfoll1000"), df5=subset(newa, region=="DAfoll5000"))
dfnames = c("region around 0ms","NAIVE FOLLOWS - 1000ms","NAIVE FOLLOWS - 5000ms","DA FOLLOWS - 1000ms","DA FOLLOWS - 5000ms")

bigDF1 = c()

for (j in c(1:2,4)) { ##// loop through all movement subsets (dfList above)
                
    lmeA = lmer(value ~ order + sex + ConvoArgument*ConvoVeracity + 
    (1+ConvoVeracity|dyad) + (1+ConvoArgument+ConvoVeracity|topic), 
    dfList[[j]], REML=F)   
            
    mod1 = modelout(lmeA,dfnames[j],"completeINTER")
        
    bigDF1 = rbind(bigDF1, mod1)
    
}

# write.xlsx(bigDF1, "ANALYSIS_FINAL.xlsx", append=TRUE, sheetName="Head")  

###// follow-up on argument vs. deception interaction 

bigDF2 = c()

for (j in c(1:2,4)) { ##// loop through all movement subsets dfList that had a significant interaction
        
    ##// WITHIN
    inter = subset(dfList[[j]], ConvoArgument == "Disagree") ##//     
    newf1 = lmer(value ~ order + sex + ConvoVeracity + 
    (1+ConvoVeracity|dyad) + (1+ConvoVeracity|topic), 
    inter, REML=F)     
    
    inter = subset(dfList[[j]], ConvoArgument == "Agree") ##//     
    newf2 = lmer(value ~ order + sex + ConvoVeracity + 
    (1+ConvoVeracity|dyad) + (1+ConvoVeracity|topic), 
    inter, REML=F) 
    
    ##// BETWEEN
    inter = subset(dfList[[j]], ConvoVeracity == "Deception") ##// 
    newf3 = lmer(value ~ order + sex + ConvoArgument +
    (1+ConvoArgument|topic), 
    inter, REML=F) 
    
    inter = subset(dfList[[j]], ConvoVeracity == "Truth") ##// 
    newf4 = lmer(value ~ order + sex + ConvoArgument + 
    (1+ConvoArgument|topic),  
    inter, REML=F) 
    
    mod1 = modelout(newf1,dfnames[j],"JustDisagree")
    mod2 = modelout(newf2,dfnames[j],"JustAgree")
    mod3 = modelout(newf3,dfnames[j],"JustDeception")
    mod4 = modelout(newf4,dfnames[j],"JustTruth")
        
    l1 = list(mod1,mod2,mod3,mod4)
    d1 = do.call(rbind, unname(l1)) ##// preserves row names
    
    bigDF2 = rbind(bigDF2, d1)

}

# write.xlsx(bigDF3, "ANALYSIS_FINAL.xlsx", append=TRUE, sheetName="Interactions") 

#######################
##// SPEECH ANALYSIS
#######################

##// STEP 1 INITIAL DATA PREP

speRate = read.table("~/synchronySpeechRapp.csv",sep=",",header=TRUE) #<<<<<<<<<<<<< 

speRate$dyad = as.factor(speRate$Pair)
speRate$order = as.factor(speRate$Task)  
speRate$topic = as.factor(speRate$Topic)

##// STEP 2 SET UP CODING FOR STATISTICAL ANALYSIS (DEVIATION/EFFECT CODING)

speRate$ConvoVeracity = factor(speRate$Deception, levels = c(1, 0), labels=c("Deception", "Truth")) 
contrasts(speRate$ConvoVeracity) = contr.sum(2)/2 

speRate$ConvoArgument = factor(speRate$Conflict, levels = c(0, 1), labels=c("Disagree", "Agree")) 
contrasts(speRate$ConvoArgument) = contr.sum(2)/2 

contrasts(speRate$order) = contr.sum(2)/2

##// planned comparison between mixed and female
mat = matrix(c(1/3, 1/3, 1/3, 1, 0, -1, 1, -1, 1), ncol = 3)
mymat = solve(t(mat))
my.contrasts<-mymat[,2:3]
contrasts(speRate$sex) = my.contrasts

center_scale <- function(x) {
    scale(x, scale = FALSE)
}

speRat2 = speRate[,c(53:56,45:46,10:14,18:19,22:26,30:31,47:52)]

##// STEP 3: RUN STATS 

modelout = function(model,DVname,MODname){
    coefs = data.frame(summary(model)$coef)
    coefs$p = 2*(1-pnorm(abs(coefs$t.value)))    
    gg = coefs
    gg$r2m = r.squaredGLMM(model)[1]
    gg$r2c = r.squaredGLMM(model)[2]
    gg$dvname = c(DVname)
    gg$modelname = c(MODname)
    is.num = sapply(gg, is.numeric)
    gg[is.num] = lapply(gg[is.num], round, 3)  
    gg = rbind(gg,"*****")
    return(gg)
}

bigDF1 = c()

for (i in c(7,15,9,17,13,11)) { ##// loop through all speech rate CRQA values 
            
	lmeA =  lmer(speRat2[,i] ~ order + sex + ConvoArgument*ConvoVeracity + 
	(1+ConvoVeracity|dyad) + (1+ConvoArgument+ConvoVeracity|topic), 
	speRat2, REML=F)  
        
    mod1 = modelout(lmeA,names(mtd4[i]),"MAIN EFFECTS")
    
    bigDF1 = rbind(bigDF1,mod1)
}

# write.xlsx(bigDF1, "ANALYSIS_FINAL.xlsx", append=TRUE, sheetName="SPEECH")                      











































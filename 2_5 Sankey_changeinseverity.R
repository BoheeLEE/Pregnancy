library (haven)
library(ggplot2)
library(tidyverse)
library(ggforce)
install.packages("ggalluvial")
library(ggalluvial)
install.packages("ggsankey")
library(ggsankey)

setwd("~/Documents/DS220/share/BOHEE/Pregnancy")


###############################################################################
## Change in classes: Option 1

data <- read_dta("sankey_inhalers.dta")

data$therapy_pre1<- as.factor(data$therapy_pre1)
data$therapy_pre1<-factor(data$therapy_pre1, levels=c("0", "1", "2", "3"))
data$therapy_pre1 <- recode(data$therapy_pre1, 
                           "1" = "Reliever only", 
                           "2" = "Infrequent ICS", 
                           "3" = "Regular ICS", 
                           "0"="No")

data$therapy_pre<- as.factor(data$therapy_pre)
data$therapy_pre<-factor(data$therapy_pre, levels=c("0", "1", "2", "3"))
data$therapy_pre <- recode(data$therapy_pre, 
                            "1" = "Reliever only", 
                            "2" = "Infrequent ICS", 
                            "3" = "Regular ICS", 
                            "0"="No")


data$therapy_dur<- as.factor(data$therapy_dur)
data$therapy_dur<-factor(data$therapy_dur, levels=c("0", "1", "2", "3"))
data$therapy_dur <- recode(data$therapy_dur, 
                            "1" = "Reliever only", 
                            "2" = "Infrequent ICS", 
                            "3" = "Regular ICS", 
                            "0"="No")

data$therapy_post<- as.factor(data$therapy_post)
data$therapy_post<-factor(data$therapy_post, levels=c("0", "1", "2", "3"))
data$therapy_post <- recode(data$therapy_post, 
                             "1" = "Reliever only", 
                             "2" = "Infrequent ICS", 
                             "3" = "Regular ICS", 
                             "0"="No")

data$therapy_post2<- as.factor(data$therapy_post2)
data$therapy_post2<-factor(data$therapy_post2, levels=c("0", "1", "2", "3"))
data$therapy_post2 <- recode(data$therapy_post2, 
                              "1" = "Reliever only", 
                              "2" = "Infrequent ICS", 
                              "3" = "Regular ICS", 
                              "0"="No")



# Step1
df <- data %>% 
  make_long(#therapy_pre1, 
            therapy_pre, therapy_dur, therapy_post, therapy_post2)

df$node <-factor(df$node, levels=c("No", "Regular ICS", "Infrequent ICS", "Reliever only"))
df$next_node <-factor(df$next_node, levels=c("No", "Regular ICS", "Infrequent ICS", "Reliever only"))

# Chart 1
x_label=c(#"-7 to -12 months", 
          "-6 months","Pregnancy", "+6 months", "+7 to 12 months")

p1 <-ggplot(df, aes(x=x
                    , next_x = next_x
                    , node = node
                    , next_node = next_node
                    , fill = factor(node)
                    , label= node))

p1<-p1+geom_sankey(flow.alpha=0.5
                   , node.color= "black"
                   , show.legend = TRUE)+
  geom_sankey_label(size=5, color="black", fill="white")+
  theme_bw()+
  theme(legend.position="none")+
  theme(text = element_text(colour = "black", size=15),
        axis.text.x=element_text(size=15, colour="black"),
        axis.text.y=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y=element_blank())+
  scale_x_discrete(labels=x_label)

p1

###############################################################################

data <- read_dta("sankey_inhalers2.dta")

data$therapy_pre1<- as.factor(data$therapy_pre1)
data$therapy_pre1<-factor(data$therapy_pre1, levels=c("0", "1", "2", "3"))
data$therapy_pre1 <- recode(data$therapy_pre1, 
                            "1" = "Reliever only", 
                            "2" = "Infrequent ICS", 
                            "3" = "Regular ICS", 
                            "0"="No")

data$therapy_pre<- as.factor(data$therapy_pre)
data$therapy_pre<-factor(data$therapy_pre, levels=c("0", "1", "2", "3"))
data$therapy_pre <- recode(data$therapy_pre, 
                           "1" = "Reliever only", 
                           "2" = "Infrequent ICS", 
                           "3" = "Regular ICS", 
                           "0"="No")


data$therapy_dur<- as.factor(data$therapy_dur)
data$therapy_dur<-factor(data$therapy_dur, levels=c("0", "1", "2", "3"))
data$therapy_dur <- recode(data$therapy_dur, 
                           "1" = "Reliever only", 
                           "2" = "Infrequent ICS", 
                           "3" = "Regular ICS", 
                           "0"="No")

data$therapy_post<- as.factor(data$therapy_post)
data$therapy_post<-factor(data$therapy_post, levels=c("0", "1", "2", "3"))
data$therapy_post <- recode(data$therapy_post, 
                            "1" = "Reliever only", 
                            "2" = "Infrequent ICS", 
                            "3" = "Regular ICS", 
                            "0"="No")

data$therapy_post2<- as.factor(data$therapy_post2)
data$therapy_post2<-factor(data$therapy_post2, levels=c("0", "1", "2", "3"))
data$therapy_post2 <- recode(data$therapy_post2, 
                             "1" = "Reliever only", 
                             "2" = "Infrequent ICS", 
                             "3" = "Regular ICS", 
                             "0"="No")



# Step1
df <- data %>% 
  make_long(#therapy_pre1, 
            therapy_pre, therapy_dur, therapy_post, therapy_post2)

df$node <-factor(df$node, levels=c("No", "Regular ICS", "Infrequent ICS", "Reliever only"))
df$next_node <-factor(df$next_node, levels=c("No", "Regular ICS", "Infrequent ICS", "Reliever only"))

# Chart 1
x_label=c(#"-7 to -12 months", 
          "-6 months","Pregnancy", "+6 months", "+7 to 12 months")

p1 <-ggplot(df, aes(x=x
                    , next_x = next_x
                    , node = node
                    , next_node = next_node
                    , fill = factor(node)
                    , label= node))

p1<-p1+geom_sankey(flow.alpha=0.5
                   , node.color= "black"
                   , show.legend = TRUE)+
  geom_sankey_label(size=5, color="black", fill="white")+
  theme_bw()+
  theme(legend.position="none")+
  theme(text = element_text(colour = "black", size=15),
        axis.text.x=element_text(size=15, colour="black"),
        axis.text.y=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y=element_blank())+
  scale_x_discrete(labels=x_label)

p1












p2 <- p2+ scale_fill_manual(values=c(
  "Low" = "skyblue", 
  "Infrequent ICS" = "#E68613", 
  "Regular ICS" = "#00A9FF", 
  "Infrequent ICS + add-on"= "#8494FF", 
  "Regular ICS + add-on" ="#C77CFF", 
  "No"="grey",
  "Reliever only " = "#CD9600", 
  "Infrequent ICS " = "#E68613", 
  "Regular ICS " = "#00A9FF", 
  "Infrequent ICS + add-on "= "#8494FF", 
  "Regular ICS + add-on " ="#C77CFF", 
  "No"="grey",
  " Reliever only " = "#CD9600", 
  " Infrequent ICS " = "#E68613", 
  " Regular ICS " = "#00A9FF", 
  " Infrequent ICS + add-on "= "#8494FF", 
  " Regular ICS + add-on " ="#C77CFF", 
  " No "="grey"
))

p2 





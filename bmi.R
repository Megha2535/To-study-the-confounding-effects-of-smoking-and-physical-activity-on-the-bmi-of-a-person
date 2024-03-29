rm(list=ls())
library(NHANES)
library(dplyr)
glimpse(NHANESraw)
#------------------------------------task 2
library(ggplot2)
NHANESraw<-NHANESraw%>%
  mutate(WTMEC4YR=WTMEC2YR/2)
NHANESraw%>%summarize(sum(WTMEC4YR))
ggplot(NHANESraw,aes(y=WTMEC4YR,x=Race1))+geom_boxplot()
#------------------------------------task 3
library(survey)
# Specify the survey design
nhanes_design <- svydesign(
  data = NHANESraw,
  strata = ~SDMVSTRA,
  id = ~SDMVPSU,
  nest = TRUE,
  weights = ~WTMEC4YR)
#nested=true because id is nested in strata variable
# Print a summary of this design
summary(nhanes_design)
#-----------------------------------task 4
# Select adults of Age >= 20 with subset
nhanes_adult <- subset(nhanes_design,Age>=20 )

# Print a summary of this subset
# .... YOUR CODE FOR TASK 4 ....
summary(nhanes_adult)
# Compare the number of observations in the full data to the adult data
nrow(nhanes_design)
nrow(nhanes_adult)
#-----------------------------------task 5
# Calculate the mean BMI in NHANESraw
bmi_mean_raw <- NHANESraw %>% 
  filter(Age >= 20) %>%
  summarize(mean(BMI, na.rm = TRUE))
bmi_mean_raw

# Calculate the survey-weighted mean BMI of US adults
bmi_mean <- svymean(~BMI, design = nhanes_adult, na.rm = TRUE)
bmi_mean

# Draw a weighted histogram of BMI in the US population
NHANESraw %>% 
  filter(Age>=20) %>%
  ggplot(mapping = aes(x = BMI, weight = WTMEC4YR)) + 
  geom_histogram()+
  geom_vline(xintercept = coef(bmi_mean), color="red")
#-----------------------------------task 6
library(broom)
# Make a boxplot of BMI stratified by physically active status
library(quantreg)
NHANESraw %>% 
  filter(Age>=20) %>%
  ggplot(mapping=aes(x=PhysActive,y=BMI,weight=WTMEC4YR))+geom_boxplot()
# .... YOUR CODE FOR TASK 6 ....

# Conduct a t-test comparing mean BMI between physically active status
survey_ttest <- svyttest(BMI~PhysActive, design =nhanes_adult)
tidy(survey_ttest)
#----------------------------------task 7
# Estimate the proportion who are physically active by current smoking status
phys_by_smoke <- svyby(~PhysActive, by = ~SmokeNow, 
                       FUN = svymean, 
                       design = nhanes_adult, 
                       keep.names = FALSE)

# Print the table
phys_by_smoke

# Plot the proportions
ggplot(data = phys_by_smoke, 
       aes(x = SmokeNow, y = PhysActiveYes, fill = SmokeNow)) +
  geom_col()+
  ylab("Proportion Physically Active")
#-----------------------------------task 8
# Estimate mean BMI by current smoking status
BMI_by_smoke <- svyby(~BMI, by = ~SmokeNow, 
                      FUN = svymean,
                      design = nhanes_adult,
                      na.rm = TRUE)
BMI_by_smoke

# Plot the distribution of BMI by current smoking status
NHANESraw %>% 
  filter(Age>=20, !is.na(SmokeNow)) %>%
  ggplot(mapping=aes(y=BMI,x=SmokeNow,weight=WTMEC4YR))+geom_boxplot()
#----------------------------------task 9
# Plot the distribution of BMI by smoking and physical activity status
NHANESraw %>% 
  filter(Age>=20) %>% 
  ggplot(mapping=aes(x=SmokeNow,y=BMI, weight = WTMEC4YR,color=PhysActive))+geom_boxplot()
#----------------------------------task 10
# Fit a multiple regression model
mod1 <- svyglm(BMI~PhysActive*SmokeNow, design = nhanes_adult)

# Tidy the model results
tidy_mod1 <- tidy(mod1)
tidy_mod1

# Calculate expected mean difference in BMI for activity within non-smokers
diff_non_smoke <- tidy_mod1 %>% 
  filter(term == "PhysActiveYes") %>% 
  select(estimate)
diff_non_smoke

# Calculate expected mean difference in BMI for activity within smokers
diff_smoke <- tidy_mod1 %>% 
  filter(term %in% c("PhysActiveYes","PhysActiveYes:SmokeNowYes")) %>% 
  summarize(estimate = sum(estimate))
diff_smoke
#--------------------------------------------task 11
# Adjust mod1 for other possible confounders
mod2 <- svyglm(BMI ~ PhysActive*SmokeNow + Race1+ Alcohol12PlusYr + Gender, 
               design = nhanes_adult)

# Tidy the output
tidy(mod2)

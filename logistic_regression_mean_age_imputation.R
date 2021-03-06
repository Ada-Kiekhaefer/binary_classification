#Kaggle competition Titanic
#Goal: predict which passengers survived the tragedy
#Data: train.csv, test.csv

library(readr)
library(dplyr)
library(broom)
library(tidyverse)
library(rsample)
library(Metrics)
library(ranger)
library(caTools)
library(na.tools)
library(tidyimpute)

#training data set
train_all_column <- read_csv("train.csv")
train <- train_all_column %>% select(Survived, Sex, Age, Pclass, Embarked) %>%
  impute_at( .na=na.mean, .vars = 'Age') %>% #impute missing age with mean values
  drop_na() %>%
  mutate(Survived=factor(Survived), Sex=factor(Sex), Pclass=factor(Pclass), Embarked=factor(Embarked))

#Split training and testing data
set.seed(42)
data_split <- initial_split(train, prop = 0.75)
training_data <- training(data_split)
testing_data <- testing(data_split)
threshold <- 0.53

#Read in the new dataset for prediction 
newdata_all_column <- read_csv("test.csv") %>%
  impute_at( .na=na.mean, .vars = 'Age') %>% #impute missing age with mean values
  mutate(Sex=factor(Sex), Pclass=factor(Pclass), Embarked=factor(Embarked))

# Logistic regression with gender only ------------------------------------
model_gender <- glm(Survived ~Sex,family=binomial(link='logit'),data=training_data)
test_predicted_gender <- predict(model_gender, testing_data, type = "response") > threshold
test_actual <- testing_data$Survived ==1
confusion_matrix_gender <- table(test_actual, test_predicted_gender)
model_performance_gender <- tibble(accuracy = accuracy(test_actual, test_predicted_gender),
                                   precision = precision(test_actual, test_predicted_gender),
                                   recall = recall(test_actual, test_predicted_gender))

#creat ROC curve
p_gender <- predict(model_gender, testing_data, type = "response")
auc_gender <- colAUC(p_gender, testing_data[["Survived"]], plotROC = TRUE)

#Predicting survival for newdata
results_gender <- predict(model_gender, newdata = newdata_all_column, type = "response") > threshold
results_gender <- as.integer(results_gender)
titanic_prediction_gender <- select(newdata_all_column, PassengerId) %>%
  mutate(Survived = results_gender)

write_csv(titanic_prediction_gender, "titanic_prediction_gender.csv", col_names = TRUE)

# Logistic regression with Sex, Age, Pclass, Embarked -------------------------------
model <- glm(Survived ~.,family=binomial(link='logit'), data=training_data)
test_predicted <- predict(model, testing_data, type = "response") > threshold
test_actual <- testing_data$Survived ==1
confusion_matrix <- table(test_actual, test_predicted)
model_performance <- tibble(accuracy = accuracy(test_actual, test_predicted),
                                   precision = precision(test_actual, test_predicted),
                                   recall = recall(test_actual, test_predicted))

#creat ROC curve
p <- predict(model, testing_data, type = "response")
auc_3age <- colAUC(p, testing_data[["Survived"]], plotROC = TRUE)

#Predicting survival for newdata data
results <- predict(model, newdata = newdata_all_column, type = "response") > threshold
results <- as.integer(results)
titanic_prediction <- select(newdata_all_column, PassengerId) %>%
  mutate(Survived = results)

write_csv(titanic_prediction, "titanic_prediction.csv", col_names = TRUE)





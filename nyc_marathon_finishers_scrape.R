# Web crawler for 2018 NYC Marathon Finisher Data =============================
# This file uses Docker and RSelenium package for navigating the site
# setting up the docker container : 
# reference http://rpubs.com/johndharrison/RSelenium-Docker
# reference https://stackoverflow.com/questions/45395849/cant-execute-rsdriver-connection-refused
# reference https://ropensci.org/tutorials/rselenium_tutorial/ 
#
# OPEN Docker Toolbox
# in Docker Toolbox call command to create the docker container
# $ docker pull selenium/standalone-chrome
# $ docker run -d -p 4445:4444 selenium/standalone-chrome
# $ docker ps
# $ docker-machine ip

# Load libraries for file =====================================================
library(tidyverse)
library(XML)
library(stringr)
library(readxl)
library(rvest)
library(beepr)

# Set up docker container =====================================================
# in terminal 
# pull the latest image docker pull selenium/node-chrome if not pulled before
shell('docker run -d -p 4445:4444 selenium/standalone-chrome')
shell('docker ps')

# Load up RSelenium ===========================================================
library(RSelenium)

# if RSelenium is not on the current computer then download it from the archives
# make sure to download the dependency files as well 
# dependencies for RSelenium are'XML', 'wdman', 'binman'
# order matters 1) XML 2) yaml 3) binman 4) wdman 5)RSelenium
# https://cran.r-project.org/src/contrib/Archive/RSelenium/
# https://cran.r-project.org/src/contrib/Archive/RSelenium/RSelenium_1.7.1.tar.gz

# Here what we are creating an object in R that contains the information
# about the selenium browser was created in a docker container. 

remDr <- RSelenium::remoteDriver(remoteServerAddr = "localhost",
                                 port = 4445L,
                                 browserName = "chrome") 

# columns to be extracted =====================================================
result <- vector("list", 0) 

# column names
list_cols <- c("runner", "age_gender", "official_time", "pace_per_mile", 
               "place_overall", "place_gender", "place_age_group", "place_age_graded", 
               "time_age_graded", "percentile_age_graded", "gun_time", 
               "gun_place", "splits_5k", "splits_10k", "splits_15K", "splits_20K", 
               "splits_half", "splits_25k", "splits_30k", "splits_35k", 
               "splits_40k")

# Open browser
remDr$open()

for(i in 1:80000){
  print(i)
  
  #Entering our URL gets the browser to navigate to the page
  url = paste0("https://results.nyrr.org/event/M2018/result/", i)
  remDr$navigate(url)
  remDr$setTimeout(type = "page load", milliseconds = 10000)
  
  #This will take a screenshot and display it in the RStudio viewer
  remDr$screenshot(display = TRUE) 
  
  # Collecting the data
  runner_profile_element <- try(remDr$findElement(using = 'xpath', 
                                              value = "/html/body/div[2]/div[2]/div[2]/div/div/div[3]/div[1]"))
  remDr$setImplicitWaitTimeout(milliseconds = 1000)
  
  if(class(runner_profile_element) == "try-error"){
    ms <- as.factor("missing")
    runner_profile <- c( rep(NA, times=42, each=1))
    result[[i]] <- as.tibble(data.frame(t(sapply(runner_profile,c))))
  }
  else{
    runner_profile <- str_split(runner_profile_element$getElementText(), "\n")
    result[[i]] <- as.tibble(data.frame(t(sapply(runner_profile,c))))
  }
  
  }

keep_result <-  vector("list", 0)
discard_result <- vector("list", 0)

for(i in 1:length(result)){
  if(length(result[[i]]) == 42){
    keep_result[[i]] <- result[[i]]
  }
  else{
    discard_result[[i]] <- result[[i]]
  }
  print(i)
  print(length(result[[i]]))
}

finishers <- bind_rows(keep_result) %>%
  select(c(1,2,4,6,8,10,12,14,16,18,20,22,26,28,30,32,34,36,38,40,42))
colnames(finishers) <- list_cols
finishers
write.table(finishers, file = paste0("nyc2018marathonfinishers.csv"), sep = ",", append = FALSE)

beep(sound = 8)

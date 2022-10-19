#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(shiny)
library(shinydashboard)
library(paws)
library(data.table)
library(Hmisc)
library(ggplot2)
library(janitor)
library(forecast)
library(zoo)
library(lubridate)
library(smooth)
# Define UI for application that draws a histogram
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = 'Goodreads Data'),
  dashboardSidebar( sidebarMenu(
    menuItem("Home", tabName = "home"),
    menuItem('About', tabName = 'about')
  )),

    # Application title
  dashboardBody(
    tabItems(
      tabItem(tabName = "home",
              fluidRow(box(plotOutput("real_plot"), width = 12)),
              fluidRow(box(plotOutput("fore_plot"),  width = 12))
      ),
      tabItem(tabName = "about",
              fluidRow(box(a("Data from this website",href="https://sites.google.com/eng.ucsd.edu/ucsdbookgraph/home"),width = 12))
      )
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  
  Sys.setenv(
    AWS_ACCESS_KEY_ID = "AKIASZCQN6XXZWFR4G6Q",
    AWS_SECRET_ACCESS_KEY = "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",
    AWS_REGION = "us-east-2")
  
  ###connecting to s3
  connect<- paws::s3()
  bucketlist<-  connect$list_buckets()
  
  
  ##getting yearly publication data for Penguin random house
  pr_yr<- connect$get_object(Bucket = 'pupulin-goodreads', Key = "pr_yr.csv/pr_yr.csv")
  ##converting raw data to string
  raw_pr_yr<- rawToChar(pr_yr$Body)
  ##converting string to data table
  pr_yr_df <- read.table(text = raw_pr_yr, sep =",", header = TRUE, stringsAsFactors = FALSE)
  colnames(pr_yr_df)<- c("Year","Publications")
  pr_yr_df$Year <- as.integer(pr_yr_df$Year)
  
  
  ##getting yearly publication data for Simon and Schuster
  ss_yr<- connect$get_object(Bucket = 'pupulin-goodreads', Key = "ss_yr.csv/ss_yr.csv")
  ##converting raw data to string
  raw_ss_yr<- rawToChar(pr_yr$Body)
  ##converting string to data table
  ss_yr_df <- read.table(text = raw_ss_yr, sep =",", header = TRUE, stringsAsFactors = FALSE)
  colnames(ss_yr_df)<- c("Year","Publications")
  ss_yr_df$Year <- as.integer(ss_yr_df$Year)
  
  
  ##getting average yearly ratings for PRH
  pr_avg_yr<- connect$get_object(Bucket = 'pupulin-goodreads', Key = "avg_pr_by_yr.csv/avg_pr_yr.csv")
  ##converting raw data to string
  raw_avg_pr_yr<- rawToChar(pr_avg_yr$Body)
  ##converting string to data table
  pr_avg_yr_df <- read.table(text = raw_avg_pr_yr, sep =",", header = TRUE, stringsAsFactors = FALSE)
  colnames(pr_avg_yr_df)<- c("Year","Average Rating")
  pr_avg_yr_df$Year <- as.integer(pr_avg_yr_df$Year)
  pr_avg_yr_df$`Average Rating`<- as.double(pr_avg_yr_df$`Average Rating`)
  
  ##getting average yearly ratings for SS
  ss_avg_yr<- connect$get_object(Bucket = 'pupulin-goodreads', Key = "avg_ss_by_yr.csv/avg_ss_yr.csv")
  ##converting raw data to string
  raw_avg_ss_yr<- rawToChar(ss_avg_yr$Body)
  ##converting string to data table
  ss_avg_yr_df <- read.table(text = raw_avg_ss_yr, sep =",", header = TRUE, stringsAsFactors = FALSE)
  colnames(ss_avg_yr_df)<- c("Year","Average Rating")
  ss_avg_yr_df$Year <- as.integer(ss_avg_yr_df$Year)
  ss_avg_yr_df$`Average Rating`<- as.double(ss_avg_yr_df$`Average Rating`)
  
  ##combine average data
  both_avg<-merge(ss_avg_yr_df,pr_avg_yr_df, by="Year")
  colnames(both_avg)<-c("Year","Simon and Schuster", "Penguin Random House")
  both_avg[75,1]<- 2019
  
  ##melt average data
  d <- reshape2::melt(both_avg, id.vars="Year")
  colnames(d)<- c("Year","Publisher","value")
  
  d$Year<- as.Date(ISOdate(year = d$Year, 
                           month = rep("1",length(d$Year)), 
                           day = rep("1",length(d$Year))))
  
  

  S<- ts(both_avg$`Simon and Schuster`,frequency = 1, start = both_avg$Year[1] , end = both_avg$Year[length(both_avg$Year)])
  PRH<- ts(both_avg$`Penguin Random House`,frequency = 1, start = both_avg$Year[1] , end = both_avg$Year[length(both_avg$Year)])
  
  Scast <- sma(S, order=4, h=5,silent=TRUE)
  PRHcast <-sma(PRH, order=4, h=5,silent=TRUE)
  
  
  tvals<-seq(both_avg$Year[length(both_avg$Year)] + 1,both_avg$Year[length(both_avg$Year)] + 5, by=1)
  
  fcast<- data.frame(tvals,Scast$forecast,PRHcast$forecast)
  colnames(fcast)<-c("Date","Simon and Schuster", "Penguin Random House")
  a <- reshape2::melt(fcast, id.vars="Date")
  colnames(a)<-c("Date","Publisher", "value")

  
  
    output$real_plot <- renderPlot({
      
      p<-ggplot(d, aes(Year,value, col=Publisher))+
        geom_line()+
        xlab("Date")+
        ylab("Average rating")+
        ggtitle("Average ratings by year for PRH and S&S")+
        geom_smooth(method = "lm", se = FALSE, linetype = "dashed") 
      
      p
    })
    
    
    output$fore_plot <- renderPlot({
      
      
      c<- ggplot(a, aes(Date,value, col=Publisher))+
        geom_point()+
        xlab("Date")+
        ylab("Average rating")+
        ggtitle("Forecast (SMA) of average ratings on Goodreads")+
        geom_line()
      
      c
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

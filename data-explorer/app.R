#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(tidyverse)
library(DT)
library(arrow)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  tags$head(
    # Note the wrapping of the string in HTML()
    tags$style(HTML("
        .single-select {
          padding-top: 0px;
          float: left;
          margin-right: 0px;
          width: 100% !important;
        }
        
        .dataTables_filter>label {
          visibility: hidden;
        }
        
        input[type='search'] {
          visibility: visible;
        }
        
        .dataTables_filter {
          display: none;
        }
        
        .dataTables_length {
          display: none;
        }
        
        .note {
          background-color: white;
          border-radius: 20px;
          box-shadow: 0 2px 4px lightgrey;
          padding: 10px;
        }
        
        .dataTable {
          font-size: 1.2rem;
        }
        
        h3 {
          margin-top: 0px;
          font-family: Times New Roman;
        }
        
        .well {
          padding: 0px;
          margin-bottom: 20px;
          background-color: transparent;
          border: none;
          box-shadow: none;
        }
        
        .filter-control {
          margin-top: 0px;
        }
        
        h2 {
          font-family: Times;
          font-size: 2em;
          margin-top: 0px;
          margin-bottom: 5px;
        }
        
        .project-branding {
          background-color: #ffdd00;
          margin-top: 10px;
          margin-bottom: 10px;
          width: fit-content;
          padding-left: 5px;
          padding-right: 5px;
          padding-top: 3px;
          padding-bottom: 3px;
          font-weight: bold;
        }
        
        .project-branding>a {
          color: black !important;
        }
        
        .dt-buttons {
          margin-top: 10px;
          float: right !important;
        }
        
        .dt-button {
          background: white !important;
        }
        
        .blurb {
          margin-bottom: 5px;
          padding-bottom: 5px;
        }
        
        @media screen and (max-width:840px) {
          .single-select {
            width: 100% !important;
          }
          
          .charts-panel {
            height: 700px;
          }
        } 
        
                      "))
    ),
  
    fluidRow(
      column(2,
              # Application title
              div(
                a("Data Liberation Project") %>% tagAppendAttributes(href='https://www.data-liberation-project.org/'),
              ) %>% tagAppendAttributes(class='project-branding'),
              titlePanel("Inmate Complaints"),
              p("Exploratory analysis interface.") %>% tagAppendAttributes(class='blurb'),
               div(
                    uiOutput('State'),
                    uiOutput('Subject_Primary'),
                    uiOutput('Subject_Secondary'),
                    uiOutput('Facility_Occurred'),
                    uiOutput('Case_Status'),
                    dateRangeInput(
                      'filed_range',
                      'Filed Between',
                      start = '2020-01-01'
                    ),
                    uiOutput('Columns')
                 ) %>% tagAppendAttributes(class="filter-control")
                ),
      column(10,
             DT::dataTableOutput("cases")
      ),
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
    dataInput <- reactive({
      file_year_ranges <- list.files('dashboard-data/filings') %>% 
        str_split_i('_',2) %>% 
        lapply(str_split,'-') %>% 
        lapply(function(vec) {return(vec[[1]][1]:vec[[1]][2])})
      
      user_year_range <- year(input$filed_range[1]):year(input$filed_range[2])
      
      target_files <- user_year_range %>%
        lapply(
          function(user_year) {
            file_year_ranges %>% 
              lapply(function(vec,year) {if (year %in% vec) {return(TRUE)} else {return(FALSE)}},user_year) %>% 
              unlist() %>% 
              which()
          }
        ) %>%
        unlist() %>%
        unique()
      
      df <- list.files('dashboard-data/filings') %>%
        .[target_files] %>%
        paste('dashboard-data/filings/',.,sep='') %>%
        lapply(read_csv) %>%
        do.call(rbind,.)
      
      
      df <- df %>%
        left_join(read_csv('dashboard-data/facilities/facility-locations.csv'),
                  by=c('Facility_Occurred' = 'Facility_Name')) %>%
        mutate(State = lapply(State,
                              function(x) {
                                  if (x %in% state.abb) {
                                    state.name[which(state.abb == x)]
                                  } else {
                                    return(NA)
                                  }
                                }
                              ))
      
      df
    })
    
    dataFiltered <- reactive({
      table_df <- dataInput()
      
      if (length(input$Case_Status) > 0) {
        table_df <- table_df %>%
          filter(Case_Status %in% input$Case_Status)
      }
      
      if (length(input$Subject_Primary) > 0) {
        table_df <- table_df %>%
          filter(Subject_Primary %in% input$Subject_Primary)
      }
      
      if (length(input$Subject_Secondary) > 0) {
        table_df <- table_df %>%
          filter(Subject_Secondary %in% input$Subject_Secondary)
      }
      
      if (length(input$Facility_Occurred) > 0) {
        table_df <- table_df %>%
          filter(Facility_Occurred %in% input$Facility_Occurred)
      }
      
      if (length(input$Status_Reasons) > 0) {
        table_df <- lapply(input$Status_Reasons,function(reason) {
          table_df %>%
            filter(grepl(reason,Status_Reasons))
        }) %>%
          do.call(rbind,.) %>%
          unique()
      }
      
      if (length(input$City) > 0) {
        table_df <- table_df %>%
          filter(City %in% input$City)
      }
      
      if (length(input$State) > 0) {
        table_df <- table_df %>%
          filter(State %in% input$State)
      }
      
      table_df <- table_df %>%
        filter(Received_Date >= input$filed_range[1]) %>%
        filter(Received_Date <= input$filed_range[2])
      
      table_df
    })

    output$cases <- DT::renderDataTable({
      table_df <- dataFiltered() %>%
        mutate(Lat = round(Lat,2),
               Long = round(Long,2)) %>%
        .[,which(colnames(.) %in% gsub(' ','_',input$Columns))]
      colnames(table_df) <- colnames(table_df) %>% gsub('_',' ',.)
      table_df
    },
    rownames=FALSE,
    extensions='Buttons',
    options = list(pageLength = 15,
                   dom = 'Bfrtip',
                   buttons = c('copy', 'csv', 'excel', 'pdf', 'print')))
    
    output$Columns <- renderUI({
      selectizeInput("Columns", 
                  "Show Columns", 
                  colnames(dataInput()) %>% gsub('_',' ',.),
                  selected=c('Case Number','Case Status','Subject Primary','Facility Occurred','Received Date','State'),
                  multiple=TRUE,
                  options = list(maxItems = 8)
      )
    })
    
    output$Case_Status <- renderUI({
      selectInput("Case_Status", 
                  "Case Status", 
                  c(dataInput() %>% pull('Case_Status') %>% unique()),
                  multiple=TRUE
      )
    })
    
    output$Subject_Primary <- renderUI({
      selectInput("Subject_Primary", 
                  "Subject_Primary" %>% gsub('_',' ',.), 
                  c(dataInput() %>% pull('Subject_Primary') %>% unique()),
                  multiple=TRUE
      )
    })
    
    output$Subject_Secondary <- renderUI({
      selectInput("Subject_Secondary", 
                  "Subject_Secondary" %>% gsub('_',' ',.), 
                  c(dataInput() %>% pull('Subject_Secondary') %>% unique()),
                  multiple=TRUE
      )
    })
    
    output$Facility_Occurred <- renderUI({
      selectInput("Facility_Occurred", 
                  "Facility_Occurred" %>% gsub('_',' ',.), 
                  c(dataInput() %>% pull('Facility_Occurred') %>% unique()),
                  multiple=TRUE
      )
    })
    
    output$Status_Reasons <- renderUI({
      selectInput("Status_Reasons", 
                  "Status_Reasons" %>% gsub('_',' ',.), 
                  dataInput() %>% 
                    pull(Status_Reasons) %>%
                    str_split(',') %>%
                    unlist() %>%
                    str_squish() %>%
                    unique(),
                  multiple=TRUE
      )
    })
    
    output$City <- renderUI({
      selectInput("City", 
                  "City" %>% gsub('_',' ',.), 
                  c(dataInput() %>% pull('City') %>% unique()),
                  multiple=TRUE
      )
    })
    
    output$State <- renderUI({
      selectInput("State", 
                  "State", 
                  c(dataInput() %>% pull('State') %>% unique()),
                  multiple=TRUE
      )
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

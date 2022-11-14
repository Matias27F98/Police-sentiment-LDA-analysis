# Police topic modeling (LDA analysis)



<!-- ABOUT THE PROJECT -->
## About The Project


Latent Dirichlet allocation (LDA) is a particularly popular method for fitting a topic model. It treats each document as a mixture of topics, and each topic as a mixture of words. By modeling the topics discussed in a large matrix of police-related tweets, we can begin to understand how public perceptions of the police are influenced by different events and circumstances. This is part of Dr. Ta-Johnson's research on police-citizen interactions. She is the author and owner of this script. For more info, visit https://www.vivianpta.com




### Prerequisites

Required packages (install first if not downloaded)

  ```sh
library(topicmodels)
library(doParallel)
library(ggplot2)
library(scales)
library(slam)
library(tictoc)

  ```

You will also need the Meaning Extraction Helper (MEH) here: https://www.ryanboyd.io/software/meh/download/
 
 Once downloaded, open MEH and select the following parameters (if I don't mention something, leave it on the default selection):
 
   1) Input File Settings: upload "tweets.csv"; "id" is the column to be used as row identifier; "cleaned_tweets" is the column containing text
   2) Output Generation: select folder where you want the output to be saved
   3) Text Segmentation: select "no segmentation"
   4) Conversion List: use default selections
   5) Stop List: use default selections
   6) Token Handling Options: use default selections
   7) Choose Output Types: adjust number in "Prune Frequency List after X Docs" to whatever;
   8)  de-select Binary Document by Term Matrix" and "Verbose Document by Term Matrix"; select "Raw Count Document by Term Matrix"
   9) N-gram Settings: Insert number in "Ignore Documents with a Word Count less than"
      A (min) = 1; B (max) = 1; select "Retain the X most Frequent N-grams (by raw frequency)
  10)Input your selected threshold parameter (X) here: I've used 500 in the past, but may need to adjust
  11) Once you finish selecting the parameters, click "Start!" under Begin Analysis

 

### Import the MEH_DTM_RawCount file into R from output folder
 
 Make it a dataframe named "DF_DTMatrix"


   ```sh
   RawCounttable <- read.csv('pathname')

DF_DTMatrix <- as.data.frame(RawCounttable)

   ```
   
   ### Determine how many topics you want to extract and how big they should
 
 Replace w/ the number of topics you want to extract 
   ```sh
   NumberOfTopics <- 6
   ```
Indicate the number of "most likely" terms that you want to show for any given topic.
I've used 20 previously but change this to whatever you want
   ```sh
  MaximumTermsPerTopic <- 20
   ```

 ### Save your results
   ```sh
dir.create("Results", showWarnings = FALSE)
   ```

### Clean your text some more

  Strip away the extra info from our document term matrix (Segment, WC, RawTokenCount)
   ```sh
DF_DTMatrix <- DF_DTMatrix[, !names(DF_DTMatrix) %in% c('Segment', 'WC', 'RawTokenCount')]
   ```

 Only include rows that don't sum to 0 (i.e., has at least one of our target words)
   ```sh
rowTotals <- apply(DF_DTMatrix[2:length(DF_DTMatrix)] , 1, sum)
DF_DTMatrix <- DF_DTMatrix[rowTotals > 0,]
remove(rowTotals)

   ```
   
 Sets aside our filenames
   ```sh
Filenames <- DF_DTMatrix$Filename
DF_DTMatrix <- DF_DTMatrix[, !names(DF_DTMatrix) %in% c("Filename")]

   ```
### Run LDA model

I typically use "Gibbs" and alpha = 0.1
   ```sh
lda.model <- LDA(DF_DTMatrix, k=NumberOfTopics, method="Gibbs", control = list(alpha = 0.1))

   ```

 Dump our term results to a .csv file in the "Results" folder
   ```sh
DataToPrint <- terms(lda.model, MaximumTermsPerTopic)
write.csv(DataToPrint, paste("Results/", Sys.Date(), "_-_LDA_Topic_Terms.csv", sep=""), na="", row.names=FALSE)

   ```
   
  This prints the most likely topic for each document to a file in the "Results" folder
   ```sh
DataToPrint <- data.frame(Filenames)
DataToPrint$Topics <- topics(lda.model)
write.csv(DataToPrint, paste("Results/", Sys.Date(), "_-_LDA_Document_Categorization.csv", sep=""), na="", row.names=FALSE)


   ```
   
   
### Rank topic terms for each topic and save 
   ```sh
tmResult <- posterior(lda.model)
attributes(tmResult)
beta <- tmResult$terms   
dim(beta)
topictermsranked <- apply(lda::top.topic.words(beta, 20, by.score = T), 2, paste, collapse = " ")
write.csv(topictermsranked, paste("Results/", Sys.Date(), "_-_Topic_Terms_Ranked.csv", sep=""), na="", row.names=FALSE)

   ```


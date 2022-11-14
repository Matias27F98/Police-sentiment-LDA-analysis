options(java.parameters = "-Xmx8g")

# Upload the following packages (install first if not already downloaded)
library(topicmodels)
library(doParallel)
library(ggplot2)
library(scales)
library(slam)
library(tictoc)



#First, download the Meaning Extraction Helper (MEH) here: https://www.ryanboyd.io/software/meh/download/
# Once downloaded, open MEH and select the following parameters (if I don't mention something, leave it on the default selection):
  # Input File Settings: upload "tweets.csv"; "id" is the column to be used as row identifier; "cleaned_tweets" is the column containing text
  # Output Generation: select folder where you want the output to be saved
  # Text Segmentation: select "no segmentation"
  # Conversion List: use default selections
  # Stop List: use default selections
  # Token Handling Options: use default selections
  # Choose Output Types: adjust number in "Prune Frequency List after X Docs" to whatever;
# de-select Binary Document by Term Matrix" and "Verbose Document by Term Matrix"; select "Raw Count Document by Term Matrix"
# N-gram Settings: Insert number in "Ignore Documents with a Word Count less than"
# A (min) = 1; B (max) = 1; select "Retain the X most Frequent N-grams (by raw frequency)
# Input your selected threshold parameter (X) here: I've used 500 in the past, but may need to adjust
# Once you finish selecting the parameters, click "Start!" under Begin Analysis

# Import the MEH_DTM_RawCount file into R from output folder
# Make it a dataframe named "DF_DTMatrix"
DF_DTMatrix <- as.data.frame(X2022_11_08_MEH_DTM_RawCount)

# If you know the number of topics you want to extract:

# Replace w/ the number of topics you want to extract 
NumberOfTopics <- 6

# Indicate the number of "most likely" terms that you want to show for any given topic.
# I've used 20 previously but change this to whatever you want
MaximumTermsPerTopic <- 20

# Create a folder named "Results" in current working directory for our results
dir.create("Results", showWarnings = FALSE)

# Strip away the extra info from our document term matrix (Segment, WC, RawTokenCount)
DF_DTMatrix <- DF_DTMatrix[, !names(DF_DTMatrix) %in% c('Segment', 'WC', 'RawTokenCount')]

# Only include rows that don't sum to 0 (i.e., has at least one of our target words)
rowTotals <- apply(DF_DTMatrix[2:length(DF_DTMatrix)] , 1, sum)
DF_DTMatrix <- DF_DTMatrix[rowTotals > 0,]
remove(rowTotals)

# Sets aside our filenames
Filenames <- DF_DTMatrix$Filename
DF_DTMatrix <- DF_DTMatrix[, !names(DF_DTMatrix) %in% c("Filename")]

# Run LDA model; I typically use "Gibbs" and alpha = 0.1
lda.model <- LDA(DF_DTMatrix, k=NumberOfTopics, method="Gibbs", control = list(alpha = 0.1))

# Dump our term results to a .csv file in the "Results" folder
DataToPrint <- terms(lda.model, MaximumTermsPerTopic)
write.csv(DataToPrint, paste("Results/", Sys.Date(), "_-_LDA_Topic_Terms.csv", sep=""), na="", row.names=FALSE)

# This prints the most likely topic for each document to a file in the "Results" folder
DataToPrint <- data.frame(Filenames)
DataToPrint$Topics <- topics(lda.model)
write.csv(DataToPrint, paste("Results/", Sys.Date(), "_-_LDA_Document_Categorization.csv", sep=""), na="", row.names=FALSE)


# Rank topic terms for each topic; saves to a file in "Results" folder
tmResult <- posterior(lda.model)
attributes(tmResult)
beta <- tmResult$terms   
dim(beta)
topictermsranked <- apply(lda::top.topic.words(beta, 20, by.score = T), 2, paste, collapse = " ")
write.csv(topictermsranked, paste("Results/", Sys.Date(), "_-_Topic_Terms_Ranked.csv", sep=""), na="", row.names=FALSE)



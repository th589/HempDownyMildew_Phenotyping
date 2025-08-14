# HempDownyMildew_Phenotyping
Code for neural network, the Blackbird high throughput phenotyping system, and statistical analysis 

This repository contains code and data associated with Evaluation of downy mildew resistance in the USDA Hemp Germplasm Repository using high-throughput and traditional phenotyping methods by Herrmann et al. (in preparation). 

Code is seperated into two folders, Matlab and R. Here is the order in which the code/files were used:

(In the Matlab folder)
1. user_training_GUI_7.m
     - This was used to train the convolutional neural network to detect signs of _Pseudoperonospora cannabina__ (downy mildew) on hemp tissue.
     - The network was trained first with the images in the folder "Neural Network Training Set 1" and underwent another round of training with "Neural Network Training Set 2". Both of these groups are in the parent folder: "Neural Network Training Images"
     - The final neural network is named "HempDMNet3.mat"

2. Analyzer_05.m
     - This code was used to analyze the images that were taken by the Blackbird machiene
     - In line 280, it is specified that the neural network HempDMNet3.mat is loaded. This can be changed to a neural network of your choosing.
     - Run the script, then seelct open and choose the directory of the experiment, then start analysis
     - After analysis, a score file (.score) will be saved in the experiment file 
  
3. ThresholderApp_00.m
    - this code is used for quality control. Run the script, then select open and select the .score file generated in the step above.
    - Click export results, then in the menu that opens select "threshold" and enter lower and upper thresholds for category assignments or select average.
    - select a directory to save the result file and define a file name. The app will generate an excel file with results from your given threshold with a sheet for each tray and a column for each date.
  
  (In R folder) 
4. Data Analysis - 8dpi.Rmd
      - This code goes through the full data analysis using the dataset "Full_dataset.csv". 
      - This data set includes severity ratings generated from the Blackbird neural network, collected from visual ratings of leaf discs, and visual ratings of detached leaves. 
      - For convience, "Full_dataset.csv" is contained in the R folder.  
   



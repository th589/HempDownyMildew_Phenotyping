# HempDownyMildew_Phenotyping

This repository contains code and data associated with Evaluation of downy mildew resistance in the USDA Hemp Germplasm Repository using high-throughput and traditional phenotyping methods by Herrmann et al. (in preparation). 

Code is seperated into two folders, Matlab and R. Here is the order in which the code/files were used:

1. user_training_GUI_7.m (Matlab folder)
     - This was used to train the convolutional neural network to detect signs of _Pseudoperonospora cannabina__ (downy mildew) on hemp tissue.
     - The network was trained with one group of images, and then with a secondary set of images. These images can be found here: https://cornell.box.com/s/h170ksoypl9l1ajwihmd46ju26zwucn5<img width="468" height="14" alt="image" src="https://github.com/user-attachments/assets/5e1e46a3-08e2-49f5-be09-53e2a8780395" />
     - The final neural network is named "HempDMNet3.mat"

2. Analyzer_05.m (Matlab folder)
     - This code was used to analyze the images that were taken by the Blackbird machiene
     - In line 280, it is specified that the neural network HempDMNet3.mat is loaded. This can be changed to a neural network of your choosing.
     - Run the script, then select open and choose the directory of the experiment, then start analysis
     - After analysis, a score file (.score) will be saved in the experiment file 
  
3. ThresholderApp_00.m (Matlab folder)
    - this code is used for quality control. Run the script, then select open and select the .score file generated in the step above.
    - Click export results, then in the menu that opens select "threshold" and enter lower and upper thresholds for category assignments or select average.
    - select a directory to save the result file and define a file name. The app will generate an excel file with results from your given threshold with a sheet for each tray and a column for each date.
  
4. Quick Look up application (In R folder)
      - This custom R Shiny application, written by A.J. Ackerman, allowed Blackbird output images to be visually inspected with ease allowing rapid look up and examination of leaf disc images. 
           - quick_lookup_macos_V9.1-app.R
           - quick_lookup_win_V9.1-app.R

5. Data Analysis (In R folder) 
      - This code goes through the full data analysis using the dataset "Full_dataset.csv". 
           - This data set includes severity ratings generated from the Blackbird neural network, collected from visual ratings of leaf discs, and visual ratings of detached leaves. 
           - For convience, "Full_dataset.csv" is contained in the R folder as well as the data folder.
      - The code is broken into the following R markdown files:
           - 01_Data_Preprocessing.Rmd
           - 02_Blackbird_Analysis.Rmd
           - 03_Leaf_disc_Analysis.Rmd
           - 04_Detacehd_Leaf_Analysis.Rmd
           - 05_Rating_Method_Comparison.Rmd

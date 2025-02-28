using Pumas, CairoMakie, DataFrames, DataFramesMeta, Logging

@info """
Exercise 1: Additional Diagnostic Plots
----------------------------------
Using docs.pumas.ai, explore and implement:
1. Individual plots:
   - Create subject_fits() with different options
   - Customize the layout and appearance
   - Add confidence intervals
   - Compare observed vs predicted for each subject

2. Covariate effect plots:
   - Create plots showing EBEs vs covariate relationships
"""

# Your code here


@info """
Exercise 2: Residual Analysis
-------------------------
Implement additional residual diagnostics:
1. Create different types of residual plots:
   - CWRES vs time
   - CWRES vs predictions
   - IWRES vs time
   - IWRES vs predictions
   
2. Add features to residual plots:
   - Smoothing lines (LOESS)
   - Reference lines at y=0
   - Confidence bands
   - Identify outliers
"""

# Your code here


@info """
Exercise 3: Population-Level Diagnostics
------------------------------------
Create population-level diagnostic plots:
1. Parameter distribution plots:
   - Histograms of random effects
   - QQ plots for random effects
   - Box plots by covariate groups
   
2. Correlation plots:
   - Random effects correlation matrix
   - Parameter-covariate correlations
   - Residual correlations
"""

# Your code here

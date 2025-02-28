using DataFrames, DataFramesMeta, PharmaDatasets, Logging

@info """
Exercise 1: Data Wrangling for PO SAD Data
----------------------------------------
Using the po_sad_1 dataset:
1. Create a working copy of the data
2. Add the following derived columns:
   - Weight-normalized dose (mg/kg)
   - Time since first dose for each subject
   - Log-transformed concentrations
3. Handle any duplicate time points by adding a small increment
"""

# Your code here


@info """
Exercise 2: Data Wrangling for IV Data
-----------------------------------
Using the iv_sd_1 dataset:
1. Create columns for dosing events:
   - CMT (use 1 for central compartment)
   - EVID (0 for observations, 1 for doses)
2. Calculate subject-specific metrics:
   - Total dose received
   - Number of observations
   - Time of last observation
3. Create a summary DataFrame with these metrics
"""

# Your code here


@info """
Exercise 3: Data Wrangling for Categorical Data
-------------------------------------------
Using the nausea dataset:
1. Create binary indicator columns for:
   - Treatment (convert to 0/1)
   - Adverse events (if present in data)
2. Calculate the proportion of events by:
   - Treatment group
   - Time point
3. Create a wide format dataset where each row represents one subject
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Advanced Data Manipulation
---------------------------------------
Create a function that:
1. Takes any of the three datasets
2. Identifies the type of data (PK or categorical)
3. Applies appropriate transformations:
   - For PK: normalizes concentrations and times
   - For categorical: creates dummy variables
"""

# Your code here 
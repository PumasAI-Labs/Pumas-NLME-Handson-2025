using Pumas, PharmaDatasets, DataFrames, Logging

@info """
Exercise 1: Creating Pumas Population from PO SAD Data
-------------------------------------------------
Using the processed po_sad_1 dataset:
1. Identify the required columns for a Pumas Population:
   - Subject identifiers
   - Time points
   - Dosing information
   - Observations
   - Covariates
2. Create a Pumas Population object using read_pumas
3. Examine the resulting population object
"""

# Your code here


@info """
Exercise 2: Creating Pumas Population from IV Data
---------------------------------------------
Using the processed iv_sd_1 dataset:
1. Create a Pumas Population object that includes:
   - Weight-normalized clearance (CLnorm = CL/WT)
   - Weight-normalized volume (Vnorm = V/WT)
2. Add a categorical covariate for high/low weight
   (high if weight > median weight)
3. Verify the population object contains all required information
"""

# Your code here


@info """
Exercise 3: Creating Pumas Population from Categorical Data
----------------------------------------------------
Using the processed nausea dataset:
1. Create a Pumas Population object that includes:
   - Binary treatment indicator
   - Time-varying response
   - Subject characteristics
2. Handle any missing data appropriately
3. Verify the data structure is suitable for modeling
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Advanced Population Creation
----------------------------------------
Create a function that:
1. Takes any of the three processed datasets
2. Automatically determines appropriate column mappings
3. Applies necessary transformations for Pumas compatibility
4. Creates a validated Pumas Population object
5. Returns a report of the population characteristics
"""

# Your code here 
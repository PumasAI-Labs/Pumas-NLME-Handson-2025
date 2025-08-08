using CSV, DataFrames, PharmaDatasets

@info """
Exercise 1: Reading and Exploring PK Data
---------------------------------------
Using the PharmaDatasets package:
1. Load the 'po_sad_1' dataset using dataset("po_sad_1")
2. Display basic information about the dataset:
   - Number of rows and columns
   - Column names and types
   - First 5 rows
3. Calculate summary statistics for numerical columns
4. Check for missing values in each column
"""

# Your code here


@info """
Exercise 2: Reading and Exploring IV Data
--------------------------------------
Using the PharmaDatasets package:
1. Load the 'iv_sd_1' dataset
2. Create a function that takes a DataFrame and returns:
   - Count of unique subjects
   - Range of doses used
   - Time range of observations
3. Apply this function to both po_sad_1 and iv_sd_1 datasets
"""

# Your code here


@info """
Exercise 3: Reading and Exploring Categorical Data
----------------------------------------------
Using the PharmaDatasets package:
1. Load the 'nausea' dataset
2. Identify all categorical columns
3. For each categorical column:
   - Count the number of unique values
   - Display the frequency of each value
4. Create a summary table showing the distribution of observations across categories
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Data Quality Assessment
------------------------------------
Create a function that performs a comprehensive data quality check:
1. Identifies outliers in continuous variables (e.g., concentrations, times)
2. Checks for logical consistency (e.g., time should increase within subjects)
3. Verifies units and ranges are reasonable
4. Produces a summary report of potential data issues

Apply this function to all three datasets.
"""

# Your code here 
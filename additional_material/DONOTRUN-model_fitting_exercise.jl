using Pumas, PharmaDatasets, DataFrames, Logging

@info """
Exercise 1: Initial Parameter Exploration
-------------------------------------
Using the warfarin PKPD model:
1. Examine the current initial parameter estimates
2. Try different sets of initial values:
   - Increase/decrease clearance by 50%
   - Double/halve the volume of distribution
   - Modify random effect variances
3. Compare the model fits with different starting values
4. Document which changes lead to better/worse fits
"""

# Your code here


@info """
Exercise 2: Optimization Settings
-----------------------------
Explore different optimization settings from docs.pumas.ai:
1. Try different optimization algorithms:
   - FOCE vs FO
2. Modify convergence criteria:
   - Change relative tolerance
   - Change absolute tolerance
   - Adjust maximum iterations
3. Compare computation time and results
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Two-Compartment Model Fitting
------------------------------------------
Using the two-compartment model from the previous exercise:
1. Prepare the po_sad_1 dataset for fitting:
   - Check data structure
   - Add necessary columns
   - Create appropriate Pumas population
2. Fit the model to the data:
   - Choose suitable initial estimates
   - Select appropriate optimization settings
   - Implement step-wise fitting if needed
3. Compare results with the one-compartment model:
   - Look at objective function values
   - Compare parameter precision
   - Assess model diagnostics
"""

# Your code here 
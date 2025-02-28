using Pumas, PharmaDatasets, DataFrames, Logging

@info """
Exercise 1: SIR Analysis Setup
--------------------------
Using the fitted model from previous exercises:
1. Prepare for SIR analysis:
   - Fix the random effect variances for ω_ka and ω_v2
   - Keep other parameters free for estimation
   - Set appropriate number of samples (e.g., 1000)

2. Document your choices:
   - Why did you choose these specific omegas to fix?
   - What values did you fix them to?
   - How did you determine the number of samples?
"""

# Your code here


@info """
Exercise 2: Running SIR Analysis
----------------------------
Perform the SIR analysis:
1. Execute SIR with the prepared settings:
   - Use the inferred results from model fitting
   - Apply the fixed parameter constraints
   - Run the analysis with chosen samples

2. Monitor the process:
   - Note any warnings or issues
"""

# Your code here

# Bonus Challenge
@info """
Bonus Challenge: Advanced SIR Analysis
---------------------------------
Extend your analysis:
1. Compare results with bootstrap analysis

"""

# Your code here 
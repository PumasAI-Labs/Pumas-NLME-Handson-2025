using Pumas

@info """
Exercise 1: Initial Parameter Exploration
-------------------------------------
Using the warfarin PK model:
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
Exercise 2: Evaluate Alternative Model Structures
-------------------------------------
Using the warfarin PK model:
1. Add a second compartment for drug distribution
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
2. Replace lag time by transit compartments for the absorption
"""

# Your code here


@info """
Exercise 3: Evaluate Alternative Model Structures
-------------------------------------
Using the warfarin PK model:
1. Use Gamma distribution for the absorption
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Your code here


@info """
Exercise 4: Evaluate correlation between ηCL and ηV1
-------------------------------------
Using the warfarin PK model:
1. Add correlation between ηCL and ηV1
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Your code here


@info """
Exercise 5: Evaluate sex effect on CL
-------------------------------------
Using the warfarin PK model:
1. Add sex effect on CL
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Your code here


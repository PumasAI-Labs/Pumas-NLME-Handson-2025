# =============================================================================
# Population PK Modeling in Pumas - Hands-on
# =============================================================================

# Import the previous code that returns the fitted Pumas model
include(joinpath("..","01-TeachingMaterial","06-population_pk","03-pk_model_fitting.jl"))  # This gives us the fitted base model, warfarin_pkmodel_fit

# -----------------------------------------------------------------------------
# 1. Exercise 1: Initial Parameter Exploration
# -----------------------------------------------------------------------------

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

# Initial parameters from the base model
# your code here

# New fit with new initial values
# your code here

# Model comparison
#compare_estimates(;model1, model2))
# your code here


# -----------------------------------------------------------------------------
# 2. Exercise 2: Evaluate Alternative Model Structure
# -----------------------------------------------------------------------------

@info """
Exercise 2: Evaluate Alternative Model Structure
-------------------------------------
Using the warfarin PK model:
1. Add a second compartment for drug distribution
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model definition with 2 compartments
warfarin_pkmodel_2cmt = @model begin

   # your code here

end

# Fit the model
# your code here

# Parameter uncertainty, Diagnostic plots and VPC
# your code here

# Model comparison
# your code here


# -----------------------------------------------------------------------------
# 3. Exercise 3: Evaluate correlation between ηCL and ηV1
# -----------------------------------------------------------------------------

@info """
Exercise 3: Evaluate correlation between ηCL and ηV1
-------------------------------------
Using the warfarin PK model:
1. Add correlation between ηCL and ηV1
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""


# your code here


# -----------------------------------------------------------------------------
# 4. Exercise 4: Evaluate covariate effect
# -----------------------------------------------------------------------------

@info """
Exercise 4: Evaluate sex effect on CL
-------------------------------------
Using the warfarin PK model:
1. Add sex effect on CL
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Your code here


# =============================================================================
# Population PK-PD Simulation in Pumas - Hands-on
# =============================================================================

# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__, "..","TeachingMaterial","population_pkpd","03-pkpd_model_fitting.jl")) # to get warfarin_model and warfarin_model_fit    

# -----------------------------------------------------------------------------
# 1. PACKAGES 
# -----------------------------------------------------------------------------
using Pumas, CairoMakie, Random, PumasUtilities

# -----------------------------------------------------------------------------
# 2. SETTING SEED FOR RANDOM NUMBER GENERATION
# -----------------------------------------------------------------------------
# To ensure reproducible results, a seed should be set for random number
# generation
Random.seed!(123456)

# -----------------------------------------------------------------------------
# 3. EXERCISE 1: Simulate a single dose
# -----------------------------------------------------------------------------

@info """
Exercise 1: Simulate a single dose
-------------------------------------
Using the warfarin PK-PD model:
1. Simulate various dose levels (e.g., 50 and 150) at time 0 (assume flat doses)
2. Explore the effect on PK and PCA
"""

# Create DosagRegimen objects for single dose levels of 50 and 150 at time 0
# your code here

# Create a population of 100 subjects for each new dosing regimen:
# your code here

# Simulate:
# your code here

# Plot:
# your code here


# -----------------------------------------------------------------------------
# 4. EXERCISE 2: Simulate multiple doses
# -----------------------------------------------------------------------------

@info """
Exercise 2: Simulate multiple doses
-------------------------------------
Using the warfarin PK-PD model:
1. Simulate daily doses of 50 and 150 (assume flat doses)
2. Explore the effect on PK and PCA
"""

# Create DosagRegimen objects for daily doses of 50 and 150 for a week:
#  your code here

# Create a population for each new dosing regimen:
#  your code here

# Simulate:
#  your code here

# Plot:
#  your code here


# -----------------------------------------------------------------------------
# 5. EXERCISE 3: Simulate loading and maintenance dose
# -----------------------------------------------------------------------------

@info """
Exercise 1: Simulate loading and maintenance dose
-------------------------------------
Using the warfarin PK-PD model:
1. Simulate a loading dose of 400 followed by daily doses of 150 for a week:
2. Explore the effect on PK and PCA
"""

# Create a DosagRegimen object for a loading dose of 400 followed by daily doses of 150 for a week:
#  your code here

# Create a population with the new dosing regimen:
#  your code here

# Simulate:
#  your code here

# Plot:
#  your code here

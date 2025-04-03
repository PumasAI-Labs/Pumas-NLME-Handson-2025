# =============================================================================
# Population PK-PD Simulation in Pumas - Hands-on Solutions
# =============================================================================

# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__, "..","01-TeachingMaterial","03-pkpd_model_fitting.jl") )     

# -----------------------------------------------------------------------------
# 1. PACKAGES 
# -----------------------------------------------------------------------------
using Pumas, CairoMakie, DataFrames, Random, PumasUtilities, Logging, Random

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
1. Simulate various dose levels at time 0
2. Explore the effect on PK and PCA
"""

# Simulate one dose of 50
dose_50 = DosageRegimen(50; time = 0)
# Create a population with the new dosing regimen:
pop_dose_50 = Population(map(i -> Subject(id = i, events = dose_50, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
new_sim = simobs(
    warfarin_model, 
    pop_dose_50, 
    coef(warfarin_model), 
    obstimes = 0.0:0.5:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, new_sim; observations = [:conc])
sim_plot(warfarin_model, new_sim; observations = [:pca])


# -----------------------------------------------------------------------------
# 4. EXERCISE 2: Simulate multiple doses
# -----------------------------------------------------------------------------

@info """
Exercise 2: Simulate multiple doses
-------------------------------------
Using the warfarin PK-PD model:
1. Simulate a daily dose of 100 
2. Explore the effect on PK and PCA
"""

# Simulate daily doses of 100 for a week:
dose_100qd = DosageRegimen(100; time = 0, ii = 24 , addl = 6)
dose_100qd
# Create a population with the new dosing regimen:
pop_dose_100qd = Population(map(i -> Subject(id = i, events = dose_100qd, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
new_sim = simobs(
    warfarin_model, 
    pop_100qd, 
    coef(fpm), 
    obstimes = 0.0:0.5:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, new_sim; observations = [:conc])
sim_plot(warfarin_model, new_sim; observations = [:pca])

# -----------------------------------------------------------------------------
# 5. EXERCISE 3: Simulate loading and maintenance dose
# -----------------------------------------------------------------------------

@info """
Exercise 1: Simulate loading and maintenance dose
-------------------------------------
Using the warfarin PK-PD model:
1. Simulate a loading dose of 300 followed by daily doses of 300 for a week:
2. Explore the effect on PK and PCA
"""

# Simulate a loading dose of 300 followed by daily doses of 300 for a week:
loading_dose = DosageRegimen(300; time = 0)
mnt_dose = DosageRegimen(100; time = 24, ii = 24 , addl = 5)
new_ev = DosageRegimen(loading_dose,mnt_dose)
new_ev

# Create a population with the new dosing regimen:
pop_new = Population(map(i -> Subject(id = i, events = new_ev, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
new_sim = simobs(
    warfarin_model, 
    new_pop, 
    coef(fpm), 
    obstimes = 0.0:0.5:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, new_sim; observations = [:conc])
sim_plot(warfarin_model, new_sim; observations = [:pca])





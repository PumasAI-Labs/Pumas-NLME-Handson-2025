# =============================================================================
# Population PK-PD Simulation in Pumas - Hands-on Solutions
# =============================================================================

# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__, "..","TeachingMaterial","population_pkpd","03-pkpd_model_fitting.jl")) # to get warfarin_model and warfarin_model_fit    

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
1. Simulate various dose levels (e.g., 50 and 150) at time 0 (assume flat doses)
2. Explore the effect on PK and PCA
"""

# Create DosagRegimen object for single dose levels of 50 and 150 at time 0
dose_50 = DosageRegimen(50; time = 0)
dose_150 = DosageRegimen(150; time = 0)
# Create a population of 100 subjects for each new dosing regimen:
pop_dose_50 = Population(map(i -> Subject(id = i, events = dose_50, covariates = (; FSZV=1, FSZCL=1)), 1:100))
pop_dose_150 = Population(map(i -> Subject(id = i, events = dose_150, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
sim_50 = simobs(
    warfarin_model, 
    pop_dose_50, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:1:150.0,  # Fine time grid
)

sim_150 = simobs(
    warfarin_model, 
    pop_dose_150, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:1:150.0,  # Fine time grid
)

# Plot:
sim_plot(fig[1, 1], warfarin_model, sim_50; observations = [:conc])
sim_plot(fig[1, 2], warfarin_model, sim_150; observations = [:conc])

sim_plot(warfarin_model, sim_50; observations = [:pca])
sim_plot(warfarin_model, sim_150; observations = [:pca])


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
dose_50qd = DosageRegimen(50; time = 0, ii = 24 , addl = 6)
dose_150qd = DosageRegimen(150; time = 0, ii = 24 , addl = 6)
# Create a population for each new dosing regimen:
pop_50qd = Population(map(i -> Subject(id = i, events = dose_50qd, covariates = (; FSZV=1, FSZCL=1)), 1:100))
pop_150qd = Population(map(i -> Subject(id = i, events = dose_150qd, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
sim_50qd = simobs(
    warfarin_model, 
    pop_50qd, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:1:150.0,  # Fine time grid
)

sim_150qd = simobs(
    warfarin_model, 
    pop_150qd, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:1:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, sim_50qd; observations = [:conc])
sim_plot(warfarin_model, sim_150qd; observations = [:conc])

sim_plot(warfarin_model, sim_50qd; observations = [:pca])
sim_plot(warfarin_model, sim_150qd; observations = [:pca])


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

# Simulate a loading dose of 400 followed by daily doses of 150 for a week:
loading_dose = DosageRegimen(400; time = 0)
mnt_dose = DosageRegimen(150; time = 24, ii = 24 , addl = 5)
new_ev = DosageRegimen(loading_dose,mnt_dose)
new_ev

# Create a population with the new dosing regimen:
pop_new = Population(map(i -> Subject(id = i, events = new_ev, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
new_sim = simobs(
    warfarin_model, 
    pop_new, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:1:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, new_sim; observations = [:conc])
sim_plot(warfarin_model, new_sim; observations = [:pca])

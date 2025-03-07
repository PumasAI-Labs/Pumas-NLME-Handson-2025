# Purpose: Solutions for Hands-on based on the Warfarin PK/PD Model
# ==============================================================

using Pumas, CairoMakie, DataFrames, Random, PumasUtilities, Logging

include(joinpath(@__DIR__, "..","01-TeachingMaterial","04-pkpd_model_fitting.jl") )     
include(joinpath(@__DIR__, "..","01-TeachingMaterial","06-pkpd_model_uncertainty_quantification.jl") )     


# Exercise: Simulate various dosing regimens 
# --------------------------------------

### Exercise: Simulate one dose of 100
new_dose = DosageRegimen(50; time = 0)
# Create a population with the new dosing regimen:
new_pop = Population(map(i -> Subject(id = i, events = new_dose, covariates = (; FSZV=1, FSZCL=1)), 1:100))
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


### Simulate daily doses of 300 for a week:
new_dose = DosageRegimen(300; time = 0, ii = 24 , addl = 6)
new_dose
# Create a population with the new dosing regimen:
new_pop = Population(map(i -> Subject(id = i, events = new_dose, covariates = (; FSZV=1, FSZCL=1)), 1:100))
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


### Simulate a loading dose of 300 followed by daily doses of 300 for a week:
loading_dose = DosageRegimen(300; time = 0)
mnt_dose = DosageRegimen(100; time = 24, ii = 24 , addl = 5)
new_ev = DosageRegimen(loading_dose,mnt_dose)
new_ev

# Create a population with the new dosing regimen:
new_pop = Population(map(i -> Subject(id = i, events = new_ev, covariates = (; FSZV=1, FSZCL=1)), 1:100))
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





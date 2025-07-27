# =============================================================================
# Population PK Modeling in Pumas - Part 7: Simulations
# =============================================================================

# The simobs function is used to simulate from Pumas models

# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__, "..", "population_pk", "03-pk_model_fitting.jl"))

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR SIMULATIONS
# -----------------------------------------------------------------------------
using Pumas
using Random

# -----------------------------------------------------------------------------
# 2. SETTING SEED FOR RANDOM NUMBER GENERATION
# -----------------------------------------------------------------------------
# To ensure reproducible results, a seed should be set for random number
# generation
Random.seed!(123456)

# -----------------------------------------------------------------------------
# 3. SIMULATING FROM FINAL PARAMETER ESTIMATES AND INDIVIDUAL PARAMETERS
# -----------------------------------------------------------------------------
# In this example:
# 1. Fixes population parameters to the final estimates from the fit
# 2. Uses final empirical Bayes estimates for individual parameters
# 3. Does not apply random unexplained variability to predictions
# 4. Use the same population (dosing information and covariates) from the 
# observed population
# 5. Performs 1 simulation

# Resulting "conc" variable is the equivalent to the individual-predicted from
# using the inspect function

warfarin_pkmodel_pred = simobs(
    warfarin_pkmodel,           # The model we defined
    pop_pk,                     # The data
    coef(warfarin_pkmodel_fit), # Final parameters estimates from the fit
    empirical_bayes(warfarin_pkmodel_fit), # Empirical Bayes estimates from the fit
    simulate_error = false,      # Do not apply random unexplained variability
)

# Plot individual predicted and observed concentrations
sim_plot(
    warfarin_pkmodel_pred;
    separate = true,
    paginate = true
)[1]

# Using predict to get preds and ipreds
preds = predict(warfarin_pkmodel_fit)
# same as
#   preds = predict(warfarin_pkmodel, pop_pk, coef(warfarin_pkmodel_fit))
vscodedisplay(DataFrame(preds))
subject_fits(preds; separate = true, paginate = true)[1]

# -----------------------------------------------------------------------------
# 4. SIMULATING FROM FINAL PARAMETER ESTIMATES AND RESAMPLING RANDOM EFFECTS (IIV)
# -----------------------------------------------------------------------------
# In this example:
# 1. Fixes population parameters to the final estimates from the fit
# 2. Samples new individual parameters from final estimates for IIV
# 3. Does not apply random unexplained variability to predictions
# 4. Use the same population (dosing information and covariates) from the 
# observed population
# 5. Performs 1 simulation

# Resulting "conc" variable is the equivalent to the individual-predicted for
# a NEW individual given the same dosing regimen and covariates as a 
# reference individual in the observed population

# We might not want to simulate based on the empirical Bayes estimates but
# instead to randomly sample individual parameters. This can be done with the 
# sample_randeffs function
warfarin_pkmodel_etas = sample_randeffs(
    warfarin_pkmodel,                  # the model
    pop_pk,                            # the population
    coef(warfarin_pkmodel_fit),        # the parameters
)

# We can pass these values to simobs instead of the EBEs
# Again, only 1 simulation of the population is being performed
warfarin_pkmodel_sim = simobs(
    warfarin_pkmodel,                   # The model we defined
    pop_pk,                             # The data
    coef(warfarin_pkmodel_fit),         # final parameters from the fit
    warfarin_pkmodel_etas,              # Randomly sampled individual parameters
    simulate_error = false,             # Do not apply random unexplained variability
)

# Plot individual predicted and observed concentrations
sim_plot(
    warfarin_pkmodel_sim;
    separate = true,
    paginate = true
)[1]

# As expected, we can see the the predictions no longer align with the observations
# given that the random effects for IIV are now drawn randomly.

# -----------------------------------------------------------------------------
# 5. SIMULATING FROM FINAL PARAMETER ESTIMATES AND RESAMPLING RANDOM EFFECTS
# (IIV AND RUV)
# -----------------------------------------------------------------------------
# In this example:
# 1. Fixes population parameters to the final estimates from the fit
# 2. Samples new individual parameters from final estimates for IIV
# 3. Applies random unexplained variability to predictions
# 4. Use the same population (dosing information and covariates) from the 
# observed population
# 5. Performs 1 simulation

# Alternatively, we might want to completely disable randomness in the simulation, i.e.
# to get the individual predictions. This an be done with by setting 
# simulate_error to false
warfarin_pkmodel_simerr = simobs(
    warfarin_pkmodel,                  # The model we defined
    pop_pk,                            # The data
    coef(warfarin_pkmodel_fit),        # final parameters from the fit
    warfarin_pkmodel_etas,             # Randomly sampled individual parameters
    simulate_error = true,             # Apply random unexplained variability
)

# Plot individual predicted and observed concentrations
sim_plot(
    warfarin_pkmodel_simerr;
    separate = true,
    paginate = true,
)[1]

# As expected, we can see the the predictions no longer align with the observations
# given that the random effects for IIV and RUV are now drawn randomly.

# -----------------------------------------------------------------------------
# 6. SIMULATING AT DIFFERENT TIME-POINTS
# -----------------------------------------------------------------------------
# In this example:
# 1. Fixes population parameters to the final estimates from the fit
# 2. Samples new individual parameters from final estimates for IIV
# 3. Does not apply random unexplained variability to predictions
# 4. Use the same population (dosing information and covariates) from the 
# observed population
# 5. Performs 1 simulation
# 6. Samples at new time-points specified in obstimes

# The granularity of the predicted concentrations is by default based on the input
# data. It is possible to pass a custom time vector to get more granular predictions
warfarin_pkmodel_smooth = simobs(
    warfarin_pkmodel,                # The model we defined
    pop_pk,                          # The data
    coef(warfarin_pkmodel_fit),      # final parameters from the fit
    warfarin_pkmodel_etas;           # extract the EBEs
    simulate_error = false,          # Disable random draws in the error model
    obstimes = 0.0:0.1:150.0,        # Custom time points for simulation
)

# Plot individual predicted and observed concentrations
sim_plot(
    warfarin_pkmodel_smooth;
    separate = true,
    paginate = true,
)[1]

# -----------------------------------------------------------------------------
# 7. SIMULATING REPLICATES
# -----------------------------------------------------------------------------
# In this example:
# 1. Fixes population parameters to the final estimates from the fit
# 2. Samples new individual parameters from final estimates for IIV
# 3. Applies random unexplained variability to predictions
# 4. Use the same population (dosing information and covariates) from the 
# observed population
# 5. Performs 200 simulations

# If you wanted to perform a manual simulation for vpc - then need to perform
# the simulation x number of times
# For each simulation (rep) in 1:200:
# 1. Perform the simulation (resampling IIV and RUV)
# 2. Convert to a DataFrame
# 3. Add a new column storing the replicate number (rep)
# 4. Perform a row-wise bind all of the results
warfarin_pkmodel_vpcsim = mapreduce(vcat, 1:200) do rep
    @chain warfarin_pkmodel begin
        simobs(
            _,
            pop_pk,
            coef(warfarin_pkmodel_fit),
            simulate_error = true,
        )
        DataFrame
        @rtransform :sim = rep
    end
end

## Plotting replicates separately for each subject
df = @rsubset warfarin_pkmodel_vpcsim parse(Int, :id) ≤ 9 # Select the first 9 subject
data(df) *
mapping(:time, :conc, layout = :id) *
visual(Lines, color = (:black, 0.025)) |> draw

## Plotting confidence intervals for each subject
# First compute the CI bounds by:
#   1. drop rows which have missing values of conc
#   2. grouping by :id and :time
#   3. combining the grouped DataFrames by using median and quantile to get the CIs
df = @chain warfarin_pkmodel_vpcsim begin
    # Select the first 9 subject
    @rsubset parse(Int, :id) ≤ 9
    # Drop rows which have missing values of conc 
    dropmissing(_, :conc)
    # Combine the grouped DataFrames by using median and quantile to get the CIs
    @by [:id, :time] begin
        :median = median(:conc)
        :lb = quantile(:conc, 0.1)
        :ub = quantile(:conc, 0.9)
    end
end
data(df) *
mapping(:time, :median, lower = :lb, upper = :ub, layout = :id) *
visual(LinesFill, label = "80% CI") |> draw

## Plotting multiple CIs
df = @chain warfarin_pkmodel_vpcsim begin
    # Select the first 9 subject
    @rsubset parse(Int, :id) ≤ 9
    # Drop rows which have missing values of conc 
    dropmissing(_, :conc)
    # Combine the grouped DataFrames by using median and quantile to get the CIs
    @by [:id, :time] begin
        :median = median(:conc)
        :lb50 = quantile(:conc, 0.25)
        :ub50 = quantile(:conc, 0.75)
        :lb95 = quantile(:conc, 0.025)
        :ub95 = quantile(:conc, 0.975)
    end
end
data(df) * (
    mapping(:time, :median, lower = :lb95, upper = :ub95, layout = :id) *
    visual(LinesFill, color = :darkblue, fillalpha = 0.15, linewidth = 0, label = "95% CI") +
    mapping(:time, :median, lower = :lb50, upper = :ub50, layout = :id) *
    visual(LinesFill, color = :darkblue, fillalpha = 0.25, label = "IQR")
) |> draw

# -----------------------------------------------------------------------------
# 6. SIMULATING ALTERNATIVE DOSING REGIMENS
# -----------------------------------------------------------------------------
# In Pumas, a dosing regimen can be defined with the DosageRegimen constructor
new_dr_v = [
    DosageRegimen(
        1.5*sub.covariates(0.0).WEIGHT, # Dose 1.5mg/kg
        route = NCA.EV                     # Set route for NCA postprocessing
    ) for sub in pop_pk
]

# We can create a new subject from the old one by passing it to the Subject constructor
# and then overwrite the events

Subject(pop_pk[1]; events = new_dr_v[1])

# ...or for all subjects
new_pop_pk = [Subject(sub; events = dr) for (sub, dr) in zip(pop_pk, new_dr_v)]

# We can now simulate based on the new population
new_sim_so = simobs(
    warfarin_pkmodel,           # The model we defined
    new_pop_pk,                 # The data
    coef(warfarin_pkmodel_fit), # final parameters from the fit
    warfarin_pkmodel_etas       # Use the sampled values that we already have
)

# -----------------------------------------------------------------------------
# 7. NON-COMPARTMENTAL ANALYSIS (NCA) CALCULATIONS
# -----------------------------------------------------------------------------
# What is the type of the simulated object
typeof(new_sim_so)

# We can convert the SimulatedObservations to a Subject, i.e. "data" by using the Subject constructor
new_sim_1_s = Subject(new_sim_so[1])

# We can analyze such simulated data by converting it to an NCASubject
# There might be multiple endpoint so we need to specify observations
sim_nca_1_s = NCASubject(new_sim_1_s; observations = :conc)

# Compuate the NCA based AUC
nca_1_1_half_mgkg = NCA.auc(sim_nca_1_s)

# We can now simulate the first subject with a higher dose
new_sub_2mgpk_1_s = Subject(
    new_pop_pk[1];
    events = DosageRegimen(
        2.0*new_pop_pk[1].covariates(0.0).WEIGHT,
        route = NCA.EV
    )
)

new_sim_2mgkg_1_so = simobs(
    warfarin_pkmodel,    # The model we defined
    new_sub_2mgpk_1_s,     # The data
    coef(warfarin_pkmodel_fit),           # final parameters from the fit
    warfarin_pkmodel_etas[1]
)

# What is the new AUC
nca_1_2mgkg = NCA.auc(NCASubject(
    Subject(new_sim_2mgkg_1_so),
    observations = :conc
))

# As expected, the exposure increases proportionally to the dose
nca_1_2mgkg / nca_1_1_half_mgkg
2/1.5

# Exercises
# - Simulate with alternative regimens

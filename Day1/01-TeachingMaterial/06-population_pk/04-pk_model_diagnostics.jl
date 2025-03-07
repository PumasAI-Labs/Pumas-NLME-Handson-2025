# =============================================================================
# Population PK Modeling in Pumas - Part 4: Goodness-of-Fit Diagnostics
# =============================================================================

# Model diagnostics are crucial for validating our fitted model. They help us:
# 1. Assess model assumptions
# 2. Identify potential model misspecification
# 3. Evaluate predictive performance
# 4. Detect systematic bias
# 5. Examine individual subject fits
#
# We'll explore several key diagnostic tools:
# - Visual Predictive Check (VPC): Compares simulated vs observed data
# - Goodness-of-fit plots: Basic model performance checks
# - Residual analysis: Identifies systematic errors
# - Individual fits: Examines model performance for specific subjects

# Import the previous code that returns the fitted Pumas model
include("03-pk_model_fitting.jl")  # This gives us the fitted model, warfarin_pkmodel_fit

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR GOODNESS-OF-FIT DIAGNOSTICS
# -----------------------------------------------------------------------------
using Pumas
using CairoMakie
using DataFrames, DataFramesMeta
using CategoricalArrays
using Logging

# -----------------------------------------------------------------------------
# 2. STANDARD GOODNESS-OF-FIT DIAGNOSTICS
# -----------------------------------------------------------------------------
# Obtain individual- and population-predictions from the model fit
warfarin_pkmodel_pred = inspect(warfarin_pkmodel_fit)
warfarin_pkmodel_preddf = DataFrame(warfarin_pkmodel_pred)

# Add descriptive values for SEX for stratification
@transform! warfarin_pkmodel_preddf @astable begin
    # Make SEX an ordered categorical variable
    :SEX = categorical(:SEX; ordered = true)
    # Assign new labels for each of the categories
    :SEX = recode(:SEX, 0 => "Female", 1 => "Male", missing => "Missing")
end
# Obtain the levels of the Categorical variable
levels(warfarin_pkmodel_preddf.SEX)

# Goodness-of-fit diagnostics
fig_gof_conc = goodness_of_fit(warfarin_pkmodel_pred,
    observations = [:conc],
    markercolor = :grey,
    markersize = 6,
    include_legend = true,
    figurelegend = (
        position = :b,
        framevisible = false,
        orientation = :vertical, 
        tellheight = true,
        tellwidth = false,
        nbanks = 4
    ),
    figure = (size = (800, 600),)
)
# Save plot
save(joinpath(@__DIR__, "gof_concentration.png"), fig_gof_conc)

# -----------------------------------------------------------------------------
# 3. INDIVIDUAL CONCENTRATION TIME-COURSES
# -----------------------------------------------------------------------------
# Plot individual observed time-courses with individual- and population-
# predictions
fig_id_conc = subject_fits(warfarin_pkmodel_pred,
    separate = true,
    ids = unique(warfarin_pkmodel_preddf.id),
    observations = [:conc],
    include_legend = true,
    figurelegend = (
        position = :b,
        framevisible = false,
        orientation = :vertical, 
        tellheight = true,
        tellwidth = false,
        nbanks = 4
    ),
    facet = (combinelabels = true,),
    paginate = true # this will generate a vector of plots
                    # to avoid that each plot gets too small
)
# We can render all plots in one go by calling display on the vector
display.(fig_id_conc)

# -----------------------------------------------------------------------------
# 4. VISUAL PREDICTIVE CHECK
# -----------------------------------------------------------------------------
# VPC is a powerful diagnostic that:
# - Simulates many datasets from the model
# - Compares observed data with simulation-based confidence intervals
# - Helps assess model's predictive performance

# Perform simulation for VPC (1000 replicates of index dataset)
vpc_res_conc = vpc(
    warfarin_pkmodel_fit;
    observations = [:conc],
    ensemblealg = EnsembleThreads(),
    samples = 1000,
    quantiles = (0.05, 0.5, 0.95),
)

# Generate figure for VPC
fig_vpc = vpc_plot(
    vpc_res_conc,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time After Dose (hr)",
        ylabel = "Warfarin Concentration (mg/L)",
    ),
    include_legend = true,
    figurelegend = (
        position = :b,
        framevisible = false,
        orientation = :vertical, 
        tellheight = true,
        tellwidth = false,
        nbanks = 3
    ),
    figure = (size = (800, 600),)
)
# Save plot
save(joinpath(@__DIR__, "vpc_concentration.png"), fig_vpc)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Prediction plots reveal systematic bias
# 2. Residual plots help identify specific types of model misspecification
# 3. Individual fits show how well the model describes each subject
# 4. VPCs show overall predictive performance

# Next Steps:
# 1. Examine uncertainty in parameter estimates (Day 2/01-pk_model_uncertainty.jl)
# =============================================================================
# Population PK Modeling in Pumas - Part 4: Goodness-of-Fit Diagnostics (1)
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
using CairoMakie,  AlgebraOfGraphics
using DataFrames, DataFramesMeta
using CategoricalArrays
using Logging

# -----------------------------------------------------------------------------
# 2. STANDARD GOODNESS-OF-FIT DIAGNOSTICS
# -----------------------------------------------------------------------------
# Obtain individual- and population-predictions from the model fit
warfarin_pkmodel_pred = inspect(warfarin_pkmodel_fit)
warfarin_pkmodel_preddf = DataFrame(warfarin_pkmodel_pred)

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


# Each subpanel of the plot is constructed from separate functions 
# of which can also be used to generate the subpanels separately
observations_vs_predictions(warfarin_pkmodel_pred)
observations_vs_ipredictions(warfarin_pkmodel_pred)
wresiduals_vs_time(warfarin_pkmodel_pred)
iwresiduals_vs_ipredictions(warfarin_pkmodel_pred)


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
# 2. NORMALIZED PREDICTION DISTRIBUTION ERRORS (NPDE)
# -----------------------------------------------------------------------------
# Obtain individual- and population-predictions from the model fit
warfarin_pkmodel_pred = inspect(warfarin_pkmodel_fit, nsim = 1000)
warfarin_pkmodel_preddf = DataFrame(warfarin_pkmodel_pred)

# Generating goodness-of-fit diagnostics when NPDEs are available will now
# plot them
goodness_of_fit(warfarin_pkmodel_pred)

# Custom plots can be generated using the DataFrame output of inspect and
# using AlgebraOfGraphics.jl/CairoMakie.jl packages
p_npde_scatter = data(warfarin_pkmodel_preddf)*
    mapping(:time,:conc_npde)*
    visual(Scatter)
draw(p_npde_scatter)

# A linear regression line can be added
p_npde_linear = data(dropmissing(warfarin_pkmodel_preddf,:conc))*
    mapping(:time,:conc_npde)*
    AlgebraOfGraphics.linear()*
    visual(;label = "Linear Regression")
draw(p_npde_scatter + p_npde_linear)

# And a LOESS smooth line can be added
p_npde_loess = data(dropmissing(warfarin_pkmodel_preddf,:conc))*
    mapping(:time,:conc_npde)*
    AlgebraOfGraphics.smooth()*
    visual(;color = :red,label = "LOESS")
draw(p_npde_scatter + p_npde_linear + p_npde_loess)

# Adjust figure options
draw(p_npde_scatter + p_npde_linear + p_npde_loess;
    axis = (;
        xlabel = "Time After Dose (hours)",
        ylabel = "NPDE",
        xticks = LinearTicks(7),
        yticks = [-6,-2,0,2,6],
    ),
    legend = (;
        position = :bottom,
        framevisible = false
    )
)


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
# 3. ADDITIONAL VPC OPTIONS
# -----------------------------------------------------------------------------
# More on VPCs
# Pumas uses local quantile regression instead of binning. The approach is inspired by
# https://ascpt.onlinelibrary.wiley.com/doi/full/10.1002/psp4.12319

# Redo default vpc
vpc_res_conc = vpc(warfarin_pkmodel_fit)

# Generate figure for VPC
vpc_plot(
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

# Adjust the bandwidth for local quantile regression
# The neightborhood of the local regression is controlled by the bandwidth parameter
vpc_res_conc_bw10 = vpc(
    warfarin_pkmodel_fit;
    bandwidth = 10.0,
)

vpc_plot(
    vpc_res_conc_bw10,
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

# An alternative way to account for subject heterogeneity is to
# stratify the plot based on discrete covariates.
vpc_res_conc_by_sex = vpc(
    warfarin_pkmodel_fit;
    stratify_by = [:SEX]
)

vpc_plot(
    vpc_res_conc_by_sex,
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


# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Prediction plots reveal systematic bias
# 2. Residual plots help identify specific types of model misspecification
# 3. Individual fits show how well the model describes each subject
# 4. VPCs show overall predictive performance

# Next Steps:
# 1. Examine uncertainty in parameter estimates (Day 2/01-pk_model_uncertainty.jl)
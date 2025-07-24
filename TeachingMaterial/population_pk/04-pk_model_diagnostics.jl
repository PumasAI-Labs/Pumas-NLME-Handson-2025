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
vscodedisplay(warfarin_pkmodel_preddf)

# Goodness-of-fit diagnostics
fig_gof_conc = goodness_of_fit(warfarin_pkmodel_pred,
    observations = [:conc],
    markercolor = :grey,
    markersize = 6,
    legend = (
        position = :bottom,
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
# 3. NORMALIZED PREDICTION DISTRIBUTION ERRORS (NPDE)
# -----------------------------------------------------------------------------
# Obtain individual- and population-predictions from the model fit
# nsim: number of simulations to be performed to obtain simulation-based residual diagnostics
warfarin_pkmodel_pred = inspect(warfarin_pkmodel_fit, nsim = 100) # Specifying 100 simulations for demonstrate purposes only
warfarin_pkmodel_preddf = DataFrame(warfarin_pkmodel_pred)
vscodedisplay(warfarin_pkmodel_preddf)

# Generating goodness-of-fit diagnostics when NPDEs are available will now
# plot them
goodness_of_fit(warfarin_pkmodel_pred)

# subpanel for NPDEs 
npde_vs_time(warfarin_pkmodel_pred)
npde_vs_predictions(warfarin_pkmodel_pred)


# -----------------------------------------------------------------------------
# 4. INDIVIDUAL CONCENTRATION TIME-COURSES
# -----------------------------------------------------------------------------
# Plot individual observed time-courses with individual- and population-
# predictions
fig_id_conc = subject_fits(warfarin_pkmodel_pred,
    separate = true,
    observations = [:conc],
    legend = (
        position = :bottom,
        framevisible = false,
        orientation = :vertical, 
        tellheight = true,
        tellwidth = false,
        nbanks = 4
    ),
    paginate = true # this will generate a vector of plots
                    # to avoid that each plot gets too small
)
# We can render all plots in one go by calling display on the vector
foreach(display, fig_id_conc)


# -----------------------------------------------------------------------------
# 5. EMPIRICAL BAYES ESTIMATES DISTRIBUTIONS
# -----------------------------------------------------------------------------
# Plot histograms of each of the EBEs from the model output
fig_ebe_hist = empirical_bayes_dist(
    warfarin_pkmodel_pred,  
)

# Plot EBEs versus covariates
empirical_bayes_vs_covariates(
    warfarin_pkmodel_pred,  
)


# -----------------------------------------------------------------------------
# 6. RESIDUAL DISTRIBUTIONS
# -----------------------------------------------------------------------------
# Plot histograms of weighted residuals from the model output
wresiduals_dist(
    warfarin_pkmodel_pred, 
)

# Plot histograms of NPDEs from the model output
npde_dist(
    warfarin_pkmodel_pred, 
)


# -----------------------------------------------------------------------------
# 7. CUSTOM PLOTS
# -----------------------------------------------------------------------------
# Custom plots can be generated using the DataFrame output of inspect and
# using AlgebraOfGraphics.jl/CairoMakie.jl packages
p_npde_scatter = data(warfarin_pkmodel_preddf)*
    mapping(:time,:conc_npde)*  # to define the aesthetic mapping of variables to the plot axes
    visual(Scatter)  # to specify the type of plot
draw(p_npde_scatter)  # to render and display the plot

# A linear regression line can be added
p_npde_linear = data(dropmissing(warfarin_pkmodel_preddf,:conc))*
    mapping(:time,:conc_npde)*
    AlgebraOfGraphics.linear()*  # to add a linear regression trend line to the plot
    visual(;label = "Linear Regression")  # to ensure that the regression line has an appropriate legend entry
draw(p_npde_scatter + p_npde_linear)  # to combine both plots

# And a LOESS smooth line can be added
p_npde_loess = data(dropmissing(warfarin_pkmodel_preddf,:conc))*
    mapping(:time,:conc_npde)*
    AlgebraOfGraphics.smooth()*  #  to add a LOESS smooth line to the plot
    visual(;color = :red, label = "LOESS")
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
# 8. VISUAL PREDICTIVE CHECK
# -----------------------------------------------------------------------------
# VPC is a powerful diagnostic that:
# - Simulates many datasets from the model
# - Compares observed data with simulation-based confidence intervals
# - Helps assess model's predictive performance

# Pumas uses local quantile regression instead of binning. The approach is inspired by
# https://ascpt.onlinelibrary.wiley.com/doi/full/10.1002/psp4.12319

# Perform simulation for VPC (1000 replicates of index dataset)
vpc_res_conc = vpc(
    warfarin_pkmodel_fit;
    observations = [:conc],
    ensemblealg = EnsembleThreads(), # to specify the parallelization method to be used
    samples = 1000,
    quantiles = (0.05, 0.5, 0.95),  # to specify the quantiles for which the VPC will compute PI
)

# Generate figure for VPC
fig_vpc = vpc_plot(
    vpc_res_conc,
    simquantile_medians = true,  # to include the medians of the simulated quantiles
    observations = true,  # to include the observed data
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
# 9. ADDITIONAL VPC OPTIONS
# -----------------------------------------------------------------------------
# An alternative way to account for subject heterogeneity is to
# stratify the plot based on discrete covariates.
vpc_res_conc_by_sex = vpc(
    warfarin_pkmodel_fit;
    observations = [:conc],
    ensemblealg = EnsembleThreads(), 
    samples = 1000,
    quantiles = (0.05, 0.5, 0.95),  
    stratify_by = [:SEX]  # to stratify by sex
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


# Prediction-corrected Visual Predictive Check (pcVPC):
pcvpc_res_conc = vpc(
    warfarin_pkmodel_fit;
    observations = [:conc],
    ensemblealg = EnsembleThreads(), 
    samples = 1000,
    quantiles = (0.05, 0.5, 0.95),  
    prediction_correction = true    # to enable prediction correction
)

vpc_plot(
    pcvpc_res_conc,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time After Dose (hr)",
        ylabel = "Prediction-corrected Concentration (mg/L)",
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
    observations = [:conc],
    ensemblealg = EnsembleThreads(), 
    samples = 1000,
    quantiles = (0.05, 0.5, 0.95),  
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



# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Prediction plots reveal systematic bias
# 2. Residual plots help identify specific types of model misspecification
# 3. Individual fits show how well the model describes each subject
# 4. VPCs show overall predictive performance
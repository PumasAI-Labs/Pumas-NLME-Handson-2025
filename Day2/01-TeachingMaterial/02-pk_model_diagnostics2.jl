# =============================================================================
# Population PK Modeling in Pumas - Part 6: Goodness-of-Fit Diagonstics (2)
# =============================================================================

# The inspect function can be used to obtain other residual error types for
# model evaluation, such as normalized prediction distribution errors.

# While the goodness_of_fit function is a quick way to plot the diagnostics,
# it can sometimes be useful to plot the quantities based on the DataFrame
# output from inspect. This gives you completely control over the plotting.

# Import the previous code that returns the fitted Pumas model
include(joinpath("..", "..", "Day1", "01-TeachingMaterial", "06-population_pk",
    "03-pk_model_fitting.jl")) 

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR GOODNESS-OF-FIT DIAGNOSTICS
# -----------------------------------------------------------------------------
using Pumas
using CairoMakie, AlgebraOfGraphics
using DataFrames, DataFramesMeta

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
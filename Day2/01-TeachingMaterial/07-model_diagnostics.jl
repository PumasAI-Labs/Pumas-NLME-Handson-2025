# Script: 07-model_diagnostics.jl
# Purpose: Perform and interpret model diagnostics for the warfarin PK/PD model
# ==============================================================

using Pumas, CairoMakie, DataFrames, DataFramesMeta, Logging
include("06-model_fitting.jl")  # This gives us the fitted model 'fpm'

# Introduction to Model Diagnostics
# ------------------------------
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

@info "Starting Model Diagnostic Analysis"
@info "================================"

# Step 1: Visual Predictive Check (VPC)
# ----------------------------------
# VPC is a powerful diagnostic that:
# - Simulates many datasets from the model
# - Compares observed data with simulation-based confidence intervals
# - Helps assess model's predictive performance
@info "Performing Visual Predictive Checks..."

# VPC for concentration
@info "Generating VPC for concentration..."
@info "This shows how well the model predicts drug concentrations over time"
vpc_res_conc = vpc(fpm; observations = [:conc], ensemblealg = EnsembleThreads())

fig_conc = vpc_plot(vpc_res_conc,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (h)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)
save("vpc_concentration.png", fig_conc)
@info "Concentration VPC saved" path="vpc_concentration.png" details="Blue band: 95% CI for median, Pink bands: 95% CI for 5th/95th percentiles, Points: Observed data"

# VPC for PCA
@info "Generating VPC for PCA (Prothrombin Complex Activity)..."
@info "This shows how well the model predicts the pharmacodynamic response"
vpc_res_pca = vpc(fpm; 
                    observations = [:pca], 
                    ensemblealg = EnsembleThreads())

fig_pca = vpc_plot(vpc_res_pca,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (h)",
        ylabel = "PCA",
        title = "VPC - PCA"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)

save("vpc_pca.png", fig_pca)
@info "PCA VPC saved" path="vpc_pca.png"

# Step 2: Basic Goodness-of-Fit Plots
# --------------------------------
@info "Generating Basic Goodness-of-Fit Plots..."
@info "These plots help identify systematic model misspecification"

# Get inspection data for plotting
insp = inspect(fpm)
insp_df = DataFrame(insp)

# Add categorical sex for potential stratification
@transform! insp_df begin
    :SEXC = recode(:SEX, 0 => "female", 1 => "male")
end

@info "Basic goodness-of-fit plots for concentration"

goodness_of_fit(insp,
                observations = [:conc],
                markercolor = :grey,
                markersize = 6,
                include_legend = true,
                figurelegend = (position = :t, 
                                orientation = :vertical, 
                                tellheight = true, tellwidth = false, nbanks = 4),
                figure = (size = (800, 600),))

@info "Basic goodness-of-fit plots for PCA"

goodness_of_fit(insp,
                observations = [:pca],
                markercolor = :grey,
                markersize = 6,
                include_legend = true,
                figurelegend = (position = :t, 
                                orientation = :vertical, 
                                tellheight = true, tellwidth = false, nbanks = 4),
                figure = (size = (800, 600),))

# Create prediction plots
@info "Generating observations vs predictions plots..."
# Population predictions
@info "Plotting population predictions..."
@info "These show how well the typical model parameters predict the data"
observations_vs_predictions(insp,
    observations = [:conc],
    markercolor = :grey,
    markersize = 6,
    axis = (
        xlabel = "Population Predictions",
        ylabel = "Observations",
        title = "Observations vs Population Predictions for Warfarin Concentration"
    ),
    figure = (size = (800, 600),)
)

observations_vs_predictions(insp,
    observations = [:pca],
    markercolor = :grey,
    markersize = 6,
    axis = (
        xlabel = "Population Predictions",
        ylabel = "Observations",
        title = "Observations vs Population Predictions for PCA"
    ),
    figure = (size = (800, 600),)
)


# Individual predictions
@info "Plotting individual predictions..."
@info "These show predictions after accounting for individual random effects"
observations_vs_ipredictions(insp,
    observations = [:conc],
    markercolor = :grey,
    markersize = 6,
    axis = (
        xlabel = "Individual Predictions",
        ylabel = "Observations",
        title = "Observations vs Individual Predictions for Warfarin Concentration"
    ),
    figure = (size = (800, 600),)
)

observations_vs_ipredictions(insp,
    observations = [:pca],
    markercolor = :grey,
    markersize = 6,
    axis = (
        xlabel = "Individual Predictions",
        ylabel = "Observations",
        title = "Observations vs Individual Predictions for PCA"
    ),
    figure = (size = (800, 600),)
)
# save("predictions.png", filetosave)
# @info "Prediction plots saved" path="predictions.png" details="Points should cluster around the line of identity, Individual predictions should show less scatter"

# Step 3: Residual Analysis
# ----------------------
@info "Performing Residual Analysis..."
@info "Residuals help identify systematic model misspecification"

# Residuals vs time
@info "Analyzing residuals vs time..."
@info "This helps identify time-dependent bias"
wresiduals_vs_time(insp,
    observations = [:conc],
    axis = (
        xlabel = "Time",
        ylabel = "WRES",
        title = "Weighted Residuals vs Time for Warfarin Concentration"
    ),
    figure = (size = (800, 600),))

wresiduals_vs_time(insp,
    observations = [:pca],
    axis = (
        xlabel = "Time",
        ylabel = "WRES",
        title = "Weighted Residuals vs Time for PCA"
    ),
    figure = (size = (800, 600),))

# Residuals vs predictions
@info "Analyzing residuals vs predictions..."
@info "This helps identify magnitude-dependent bias"
wresiduals_vs_predictions(insp,
    observations = [:conc],
    axis = (
        xlabel = "Predictions",
        ylabel = "WRES",
        title = "Weighted Residuals vs Predictions for Warfarin Concentration"
    ),
    figure = (size = (800, 600),))

wresiduals_vs_predictions(insp,
    observations = [:pca],
    axis = (
        xlabel = "Predictions",
        ylabel = "WRES",
        title = "Weighted Residuals vs Predictions for PCA"
    ),
    figure = (size = (800, 600),))

# Step 4: Individual Subject Fits
# ---------------------------
@info "Generating Individual Subject Fits..."
@info "These show how well the model describes individual subjects"
subject_fits(insp,
    separate = true,
    ids = unique(insp_df.id)[1:16],
    observations = [:conc],
    facet = (combinelabels = true,)
)

subject_fits(insp,
    separate = true,
    ids = unique(insp_df.id)[1:16],
    observations = [:pca],
    facet = (combinelabels = true,)
)
@info "Individual fits saved" path="individual_fits.png" details="Blue lines: Model predictions, Points: Observed data"

# Educational Note:
# ---------------
@info "Key Takeaways from Diagnostics:"
@info "1. VPCs show overall predictive performance"
@info "2. Prediction plots reveal systematic bias"
@info "3. Residual plots help identify specific types of model misspecification"
@info "4. Individual fits show how well the model describes each subject"

# Next Steps:
# ----------
@info "Next Steps:"
@info "1. Examine uncertainty in parameter estimates (08-uncertainty_quantification.jl)"
@info "2. Use the model for simulations (09-simulation.jl)"
@info "3. Consider model refinements if diagnostics reveal issues"

# Execute if this script is run directly
if abspath(PROGRAM_FILE) == @__FILE__
    @info "Script completed successfully!"
    @info "Review the generated diagnostic plots:" files=[
        "vpc_concentration.png",
        "vpc_pca.png",
        "predictions.png",
        "residuals.png",
        "individual_fits.png"
    ]
end
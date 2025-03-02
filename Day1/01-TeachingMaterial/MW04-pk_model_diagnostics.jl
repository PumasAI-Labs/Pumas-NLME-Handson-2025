# Script: MW04-pk_model_diagnostics_v1.jl
# Purpose: Perform and interpret model diagnostics for the warfarin PK model
# ==============================================================

using Pumas, CairoMakie, DataFrames, DataFramesMeta, CategoricalArrays, Logging
include("MW03-pk_model_fitting.jl")  # This gives us the fitted model 'fpm'

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
# More details to be given on Day 2
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

fig_gof_conc = goodness_of_fit(insp,
                observations = [:conc],
                markercolor = :grey,
                markersize = 6,
                include_legend = true,
                figurelegend = (position = :t, 
                                orientation = :vertical, 
                                tellheight = true, tellwidth = false, nbanks = 4),
                figure = (size = (800, 600),))

save("gof_concentration.png", fig_gof_conc)

# Step 4: Individual Subject Fits
# ---------------------------
@info "Generating Individual Subject Fits..."
@info "These show how well the model describes individual subjects"
sf_v = subject_fits(insp,
    separate = true,
    ids = unique(insp_df.id),
    observations = [:conc],
    facet = (combinelabels = true,),
    paginate = true # this will generate a vector of plots
                    # to avoid that each plot gets too small
)
# We can render all plots in one go by calling display on the vector
display.(sf_v)

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
        "predictions.png",
        "individual_fits.png"
    ]
end
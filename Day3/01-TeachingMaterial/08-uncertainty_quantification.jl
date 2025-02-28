# Script: 08-uncertainty_quantification.jl
# Purpose: Quantify uncertainty in parameter estimates for the warfarin PK/PD model
# ==============================================================

using Pumas, CairoMakie, DataFrames, Logging
include("06-model_fitting.jl")  # This gives us the fitted model 'fpm'

# Introduction to Parameter Uncertainty
# --------------------------------
# Understanding uncertainty in parameter estimates is crucial because:
# 1. No model fit is perfect - we need to quantify our confidence
# 2. Parameter uncertainty affects predictions and simulations
# 3. Some parameters may be more precisely estimated than others
# 4. Uncertainty helps inform experimental design and data collection
#
# We'll explore two main approaches:
# 1. Asymptotic Confidence Intervals
# 2. Bootstrap Method (non-parametric resampling)

@info "Asymptotic Confidence Intervals"
@info "===================================="
try
    asymp_inf = infer(fpm)
    @info "Asymptotic inference successful!"
    @info "Standard Errors from Asymptotic Inference:"
    coeftable(asymp_inf)
catch e
    @info "Asymptotic inference failed."
    @info "This often occurs with complex models or when parameters are highly correlated."
    @info "We'll proceed with bootstrap analysis instead."
end

# Step 2: Bootstrap Analysis
# ----------------------
# Bootstrap analysis:
# - Resamples the data with replacement
# - Refits the model to each sample
# - Provides empirical parameter distributions
# - Is more robust but computationally intensive

@info "Performing Bootstrap Analysis..."
@info "This will take some time as we need to refit the model multiple times"
@info "We'll use 10 bootstrap samples for this demonstration"
@info "(In practice, you might want 100 or more samples)"

# Perform bootstrap with progress updates
bts_inf = infer(fpm, Bootstrap(samples = 10))

@info "Bootstrap Analysis Complete!"
@info "Parameter Standard Errors from Bootstrap:"
coeftable(bts_inf)

# Step 3: Handling Parameter Correlation
# ---------------------------------
@info "Assessing Parameter Correlation..."
@info "Some parameters may be highly correlated, affecting their estimation"

# Fix potentially problematic parameters
@info "Refitting model with fixed variance parameters..."
@info "This can help when variance parameters are poorly identified"

fpm_inf = fit(
    fpm.model,
    pop,
    coef(fpm),
    FOCE();
    init_randeffs = empirical_bayes(fpm),
    constantcoef = (:pk_Ω, :pd_Ω),  # Fix variance parameters
    optim_options = (; iterations = 0)
)

# Try inference again with fixed parameters
@info "Recalculating standard errors with fixed parameters:"
inf_fixed = infer(fpm_inf)
coeftable(inf_fixed)

# Educational Note:
# ---------------
@info "Key Takeaways from Uncertainty Analysis:"
@info "1. Parameter uncertainty can be estimated through multiple methods"
@info "2. Bootstrap is more robust but computationally intensive"
@info "3. Some parameters may be estimated more precisely than others"
@info "4. Fixing poorly identified parameters can improve estimation"
@info "5. Understanding uncertainty is crucial for model-based decision making"

# Next Steps:
# ----------
@info "Next Steps:"
@info "1. Use uncertainty estimates in simulations (09-simulation.jl)"
@info "2. Consider ways to reduce uncertainty:"
@info "   - Collect more data"
@info "   - Modify sampling times"
@info "   - Simplify the model if appropriate"

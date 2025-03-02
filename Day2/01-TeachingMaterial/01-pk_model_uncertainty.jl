# Script: 01-pk_model_uncertainty.jl
# Purpose: Provide uncertainty estimates for the points estimates of the model
# ==============================================================

using Pumas, CairoMakie, DataFrames, DataFramesMeta, CategoricalArrays, Logging
include(joinpath("..", "..", "Day1", "01-TeachingMaterial", "03-pk_model_fitting.jl"))  # This gives us the fitted model 'fpm'

# Introduction to Parameter Uncertainty
# --------------------------------
# Understanding uncertainty in parameter estimates is crucial because:
# 1. Some parameters might be poorly determined in the model for the data available
# 2. Parameter uncertainty affects predictions and simulations
# 3. Some parameters may be more precisely estimated than others
# 4. Uncertainty helps inform experimental design and data collection
#
# We'll explore a variety of approaches:
# 1. Asymptotic confidence intervals
#   a Sandwich estimator (default)
#   b Inverse Hessian (the classical maximum likelihood estimator)
# 2. Bootstrap Method (non-parametric resampling)
# 3. Sampling importance resampling (SIR)

@info "Asymptotic confidence intervals"
@info "Sandwich estimator (default)"
@info "===================================="
asymp_inf_a = infer(fpm)

@info "Sandwich estimator (default)"
asymp_inf_b = infer(fpm; sandwich_estimator = false)

# Step 2: Bootstrap Analysis
# ----------------------
# Bootstrap analysis:
# - Resamples the data with replacement
# - Refits the model to each sample
# - Is more robust but computationally intensive

@info "Performing Bootstrap Analysis..."
@info "This will take some time as we need to refit the model multiple times"

# Perform bootstrap with progress updates
bts_inf = infer(fpm, Bootstrap(samples = 100))

@info "Bootstrap Analysis Complete!"
@info "Parameter Standard Errors from Bootstrap:"
coeftable(bts_inf)

# Step 3: Sampling importance resampling
sir_inf = infer(fpm, SIR(samples = 1000, resamples = 200))

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
@info "1. Use uncertainty estimates in simulations (simulation.jl)"
@info "2. Consider ways to reduce uncertainty:"
@info "   - Collect more data"
@info "   - Modify sampling times"
@info "   - Simplify the model if appropriate"

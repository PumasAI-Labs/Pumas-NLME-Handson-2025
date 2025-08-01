# =============================================================================
# Population PK Modeling in Pumas - Part 3: Fitting a Pumas Model
# =============================================================================

# Population modeling estimates both:
# 1. Population parameters (fixed effects) - typical values in the population
# 2. Random effects - variability of the individual deviations from typical
# values AND variability of the deviations between predicted and observed
# outcomes
#
# The fitting process involves:
# - Maximum likelihood estimation
# - Empirical Bayes estimation
# - Model diagnostics and validation
#
# Key concepts:
# - FOCE (First-Order Conditional Estimation): A method that:
#   * Linearizes the model around individual random effects
#   * Provides good balance of accuracy and computational speed
# - Likelihood: Measure of how well the model fits the data
# - AIC/BIC: Model comparison criteria that penalize complexity

# Import the previous code that create the Pumas population and Pumas model
include("01-read_pumas_data.jl")  # This gives us the pop_pk object
include("02-pk_model.jl")  # This gives us the warfarin_pkmodel

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR FITTING PUMAS MODELS
# -----------------------------------------------------------------------------
using Pumas, Serialization, Logging, PumasUtilities

# -----------------------------------------------------------------------------
# 2. INITIAL PARAMETER ESTIMATES
# -----------------------------------------------------------------------------
# Before fitting, we need starting values for all parameters:
warfarin_pkmodel_initial_params = (
    θCL = 0.134,
    θVC = 8.11,
    θtabs = 0.523,
    θlag = 0.1,
    pk_Ω = Diagonal([0.09, 0.09]),
    tabs_ω = 0.09,
    σ_prop = 0.00752,
    σ_add = 0.0661,
)

# -----------------------------------------------------------------------------
# 3. ESTIMATING PARAMETERS
# -----------------------------------------------------------------------------
# Fit the model using FOCE method
# This step:
# - Optimizes population parameters
# - Estimates individual random effects
# - Computes the likelihood
warfarin_pkmodel_fit = fit(
    warfarin_pkmodel,                 # The model we defined
    pop_pk,                           # The population data
    warfarin_pkmodel_initial_params,  # Starting values
    FOCE(),                           # Estimation method
) 

# Convergence trace: 
# Plot the log-likelihood and gradient norm over each iteration
convergence_trace(warfarin_pkmodel_fit)

# Obtain parameter uncertainty
warfarin_pkmodel_varcov = infer(warfarin_pkmodel_fit)

# -----------------------------------------------------------------------------
# 3. EXAMINE MODEL RESULTS
# -----------------------------------------------------------------------------
# Look at the estimated parameters and their uncertainty
coeftable(warfarin_pkmodel_varcov)
coefficients_table(warfarin_pkmodel_fit,warfarin_pkmodel_varcov)  # Contains metadata

# -----------------------------------------------------------------------------
# 4. MODEL REFINEMENT
# -----------------------------------------------------------------------------
# Refit using:
# - Previous parameter estimates as new starting values
# - Resets the inverse Hessian approximation of BFGS
# This sometimes improves the fit and stability
warfarin_pkmodel_fit = fit(
    warfarin_pkmodel,
    pop_pk,
    coef(warfarin_pkmodel_fit),  # Use previous parameter estimates
    FOCE(),
)

# Example: fixing a parameter:
# Fix IIV on tabs to 0.5
warfarin_pkmodel_fit_fix = fit(
    warfarin_pkmodel,
    pop_pk,
    merge(warfarin_pkmodel_initial_params, (; tabs_ω = 0.5)), # Replace initial value for tabs_ω by 0.5 
    FOCE(),
    constantcoef = (:tabs_ω,),  # Fix the tabs_ω parameter
)

# -----------------------------------------------------------------------------
# 5. NUMERICAL DIAGNOSTICS
# -----------------------------------------------------------------------------
# Various statistics help us assess model fit:
# - log_likelihood: Higher is better
# - AIC: Lower is better, penalizes model complexity 
#       (calculated based on -2LL)
# - BIC: Lower is better, penalizes complexity more strongly than AIC
#       (calculated based on -2LL)
# - Condition_Number: Lower is better, assessment of parameter collinearity
#       (calculated based on correlation matrix of parameter estimates)
# - ηshrinkage: Lower is better
# - ϵshrinkage: Lower is better
@info "Model Fit Metrics:" metrics = (
    log_likelihood = loglikelihood(warfarin_pkmodel_fit),
    AIC = aic(warfarin_pkmodel_fit),
    BIC = bic(warfarin_pkmodel_fit),
    Condition_Number = cond(warfarin_pkmodel_varcov),
    ηshrinkage = ηshrinkage(warfarin_pkmodel_fit),
    ϵshrinkage = ϵshrinkage(warfarin_pkmodel_fit)
)

# Obtain a table of the numerical diagnostics for the model
metrics = metrics_table(warfarin_pkmodel_fit)

# -----------------------------------------------------------------------------
# 6. OBTAINING EMPIRICAL BAYES ESTIMATES
# -----------------------------------------------------------------------------
# Empirical Bayes Estimates (EBEs) show individual deviations from population
# typical values
ebes = empirical_bayes(warfarin_pkmodel_fit)

# Random effects for first subject (deviations from population mean)
display(ebes[1])

# -----------------------------------------------------------------------------
# 7. OBTAINING INDIVIDUAL -LOGLIKELIHOODS
# -----------------------------------------------------------------------------
# Identify subjects that strongly influence the model fit
# Large influence might indicate:
# - Outliers
# - Model misspecification for certain subjects
# - Data quality issues
nlls = findinfluential(warfarin_pkmodel_fit)

# Identify the top 5 most influential subjects (ID and influence metric):
nlls[1:5]

# -----------------------------------------------------------------------------
# 8. SAVING RESULTS
# -----------------------------------------------------------------------------
# Save the fitted model for later use
# This allows us to:
# - Continue analysis later
# - Share results with colleagues
# - Use the model for simulations
filename = joinpath(@__DIR__,"warfarin_pk_fpm.jls")
serialize(filename, warfarin_pkmodel_fit)
@info "Model Saved" path = filename

# -----------------------------------------------------------------------------
# 9. LOADING PREVIOUSLY SAVED RESULTS
# -----------------------------------------------------------------------------
# Load the saved model and check it matches original
loaded_pkmodel_fit = deserialize(filename)
@info "Model Verification" models = (
    original_ll = loglikelihood(warfarin_pkmodel_fit),
    loaded_ll = loglikelihood(loaded_pkmodel_fit),
)

# -----------------------------------------------------------------------------
# 10. COMPARING NONMEM RESULTS
# -----------------------------------------------------------------------------
# Calculate NONMEM-style objective function values
# This is useful for:
# - Comparing with NONMEM results
# - Historical compatibility
# - Literature comparisons
OFV_WITH_CONSTANT = -2 * loglikelihood(warfarin_pkmodel_fit)
OFV_WITHOUT_CONSTANT = OFV_WITH_CONSTANT - nobs(pop_pk) * log(2π)
@info "NONMEM-Style Objective Function Values:" values = (
    with_constant = OFV_WITH_CONSTANT,
    without_constant = OFV_WITHOUT_CONSTANT,
)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Always examine initial estimates before fitting
# 2. Use multiple fit statistics to assess model performance
# 3. Look at both population and individual-level results
# 4. Save your results for reproducibility
# 5. Consider influential subjects for model refinement

# Next Steps:
# 1. Detailed diagnostics (goodness-of-fit plots)
# 2. Visual predictive checks
# 3. Parameter uncertainty analysis
# 4. Clinical trial simulations
# =============================================================================
# Population PK-PD Modeling in Pumas - Part 3: Fitting a Pumas Model
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
include("01-read_pumas_pkpd_data.jl")  # This gives us the pop_pkpd object
include("02-pkpd_model.jl")  # This gives us the warfarin_model

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR FITTING PUMAS MODELS
# -----------------------------------------------------------------------------
using Pumas, Serialization, Logging, PumasUtilities

# -----------------------------------------------------------------------------
# 2. INITIAL PARAMETER ESTIMATES
# -----------------------------------------------------------------------------
# Before fitting, we need starting values for all parameters
# These come from the model's @param block initialization
# Returns a NamedTuple
initial_params = init_params(warfarin_model)

# -----------------------------------------------------------------------------
# 3. ESTIMATING PARAMETERS
# -----------------------------------------------------------------------------
# Fit the model using FOCE method
# This step:
# - Optimizes population parameters
# - Estimates individual random effects
# - Computes the likelihood
warfarin_model_fit = fit(
    warfarin_model,              # The model we defined
    pop_pkpd,                        # The population data
    initial_params,                # Starting values
    FOCE(),                        # Estimation method
) 

# Convergence trace: 
# Plot the log-likelihood and gradient norm over each iteration
convergence_trace(warfarin_model_fit)

# Obtain parameter uncertainty
warfarin_model_varcov = infer(warfarin_model_fit)

# -----------------------------------------------------------------------------
# 3. EXAMINE MODEL RESULTS
# -----------------------------------------------------------------------------
# Look at the estimated parameters and their uncertainty
coeftable(warfarin_model_varcov)
vscodedisplay(coefficients_table(warfarin_model_fit,warfarin_model_varcov))  # Contains metadata


# -----------------------------------------------------------------------------
# 4. NUMERICAL DIAGNOSTICS
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
    log_likelihood = loglikelihood(warfarin_model_fit),
    AIC = aic(warfarin_model_fit),
    BIC = bic(warfarin_model_fit),
    Condition_Number = cond(warfarin_model_varcov),
    ηshrinkage = ηshrinkage(warfarin_model_fit),
    ϵshrinkage = ϵshrinkage(warfarin_model_fit)
)

# Obtain a table of the numerical diagnostics for the model
metrics = metrics_table(warfarin_model_fit)

# -----------------------------------------------------------------------------
# 5. OBTAINING EMPIRICAL BAYES ESTIMATES
# -----------------------------------------------------------------------------
# Empirical Bayes Estimates (EBEs) show individual deviations from population
# typical values
ebes = empirical_bayes(warfarin_model_fit)

# Random effects for first subject (deviations from population mean)
display(ebes[1])

# -----------------------------------------------------------------------------
# 6. OBTAINING INDIVIDUAL -LOGLIKELIHOODS
# -----------------------------------------------------------------------------
# Identify subjects that strongly influence the model fit
# Large influence might indicate:
# - Outliers
# - Model misspecification for certain subjects
# - Data quality issues
nlls = findinfluential(warfarin_model_fit)

# Identify the top 5 most influential subjects (ID and influence metric):
nlls[1:5]

# -----------------------------------------------------------------------------
# 7. SAVING RESULTS
# -----------------------------------------------------------------------------
# Save the fitted model for later use
# This allows us to:
# - Continue analysis later
# - Share results with colleagues
# - Use the model for simulations
filename = joinpath(@__DIR__,"warfarin_fpm.jls")
serialize(filename, warfarin_model_fit)
@info "Model Saved" path = filename

# -----------------------------------------------------------------------------
# 8. LOADING PREVIOUSLY SAVED RESULTS
# -----------------------------------------------------------------------------
# Load the saved model and check it matches original
loaded_model_fit = deserialize(filename)
@info "Model Verification" models = (
    original_ll = loglikelihood(warfarin_model_fit),
    loaded_ll = loglikelihood(loaded_model_fit),
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
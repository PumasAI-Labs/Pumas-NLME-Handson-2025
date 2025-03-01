# Script: MW03-pk_model_fitting_v1.jl
# Purpose: Fit the warfarin PK/PD model to data and examine results
# ==============================================================

using Pumas, Serialization, Logging, PumasUtilities
include("MW01-read_pumas_data.jl")  # This gives us the 'pop' object
include("MW02-pk_model.jl")       # This gives us the 'warfarin_pkmodel'

# Introduction to Population PK/PD Model Fitting
# ------------------------------------------
# Population modeling estimates both:
# 1. Population parameters (fixed effects) - typical values in the population
# 2. Random effects - individual deviations from typical values
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

@info "Starting Population PK Model Fitting Process"
@info "============================================"

# Step 1: Initial Parameter Values
# ----------------------------
# Before fitting, we need starting values for all parameters
# These come from the model's @param block initialization
@info "Getting initial parameter values..."
initial_params = init_params(warfarin_pkmodel)


# Step 2: First Model Fit
# --------------------
# Fit the model using FOCE method
# This step:
# - Optimizes population parameters
# - Estimates individual random effects
# - Computes the likelihood
@info "Performing initial model fit..."
@info "This may take a few minutes..."
fpm = fit(
    warfarin_pkmodel,  # The model we defined
    pop_pk,            # The population data
    initial_params, # Starting values
    FOCE()         # Estimation method
)

# Step 3: Examine Initial Results
# ---------------------------
# Look at the estimated parameters and their uncertainty
@info "Initial Fit Results:"
@info "------------------"
@info "Fitted population parameters:"
coeftable(fpm)

# Step 4: Model Refinement
# ---------------------
# Refit using:
# - Previous parameter estimates as new starting values
# - Individual random effects estimates (empirical Bayes estimates)
# This often improves the fit and stability
@info "Refining the model fit..."
@info "Using previous estimates as new starting points..."
@info "resets the inverse Hessian approximation of BFGS"
fpm = fit(
    warfarin_pkmodel,
    pop_pk,
    coef(fpm),     # Use previous parameter estimates
    FOCE();
    init_randeffs = empirical_bayes(fpm)  # Use previous random effects
)

# Step 5: Evaluate Model Fit
# -----------------------
# Various statistics help us assess model fit:
# - Log-likelihood: Higher is better
# - AIC: Lower is better, penalizes model complexity
# - BIC: Lower is better, penalizes complexity more strongly than AIC
@info "Model Fit Statistics:"
@info "-------------------"
@info "Model fit metrics:" metrics=(
    loglikelihood = loglikelihood(fpm),
    AIC = aic(fpm),
    BIC = bic(fpm)
)

@info "Model fit metrics" 
metrics = metrics_table(fpm)

# Step 6: Individual-Level Analysis
# -----------------------------
# Examine how well the model describes individual subjects
# Empirical Bayes Estimates (EBEs) show individual deviations from population
@info "Examining Individual-Level Predictions:"
@info "-------------------------------------"
ebes = empirical_bayes(fpm)
@info "Random effects for first subject (deviations from population mean):"
display(ebes[1])

# Step 7: Model Diagnostics
# ----------------------
# Identify subjects that strongly influence the model fit
# Large influence might indicate:
# - Outliers
# - Model misspecification for certain subjects
# - Data quality issues
@info "Identifying Influential Subjects:"
@info "-------------------------------"
nlls = findinfluential(fpm)
@info "Top 5 most influential subjects (ID and influence metric):"
nlls[1:5]

# Step 8: Save Results
# -----------------
# Save the fitted model for later use
# This allows us to:
# - Continue analysis later
# - Share results with colleagues
# - Use the model for simulations
@info "Saving the fitted model..."
filename = "warfarin_pk_fpm.jls"
serialize(filename, fpm)
@info "Model saved" path=filename

# Step 9: Verify Saved Results
# -------------------------
# Load the saved model and check it matches original
@info "Verifying saved results..."
loaded_fpm = deserialize(filename)
@info "Model verification" original_ll=loglikelihood(fpm) loaded_ll=loglikelihood(loaded_fpm)

# Step 10: NONMEM Compatibility
# -------------------------
# Calculate NONMEM-style objective function values
# This is useful for:
# - Comparing with NONMEM results
# - Historical compatibility
# - Literature comparisons
@info "NONMEM-style Objective Function Values:"
@info "-------------------------------------"
OFV_WITH_CONSTANT = -2 * loglikelihood(fpm)
OFV_WITHOUT_CONSTANT = OFV_WITH_CONSTANT - nobs(pop) * log(2π)
@info "NONMEM objective function values:" with_constant=OFV_WITH_CONSTANT without_constant=OFV_WITHOUT_CONSTANT

# Educational Note:
# ---------------
@info "Key Takeaways from Model Fitting:"
@info "1. Always examine initial estimates before fitting"
@info "2. Use multiple fit statistics to assess model performance"
@info "3. Look at both population and individual-level results"
@info "4. Save your results for reproducibility"
@info "5. Consider influential subjects for model refinement"

# Next Steps:
# ----------
@info "Next Steps:"
@info "1. Detailed diagnostics (goodness-of-fit plots)"
@info "2. Visual predictive checks"
@info "3. Parameter uncertainty analysis"
@info "4. Clinical trial simulations"
# =============================================================================
# Population PK Modeling in Pumas - Part 5: Parameter Uncertainty
# =============================================================================

# Understanding uncertainty in parameter estimates is crucial because:
# 1. Some parameters might be poorly determined in the model for the data available
# 2. Parameter uncertainty affects predictions and simulations
# 3. Some parameters may be more precisely estimated than others
# 4. Uncertainty helps inform experimental design and data collection
#
# We'll explore a variety of approaches:
# 1. Asymptotic confidence intervals
# - Sandwich estimator (default)
# - Inverse Hessian (the classical maximum likelihood estimator)
# 2. Bootstrap Method (non-parametric resampling)
# 3. Sampling importance resampling (SIR) 
# - https://link.springer.com/article/10.1007/s10928-016-9487-8

# Import the previous code that returns the fitted Pumas model
include("03-pk_model_fitting.jl")  # This gives us the fitted model, warfarin_pkmodel_fit

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR PARAMETER UNCERTAINTY
# -----------------------------------------------------------------------------
using Pumas
import Logging
Logging.disable_logging(Logging.Warn)

# -----------------------------------------------------------------------------
# 2. ASYMPTOTIC CONFIDENCE INTERVALS
# -----------------------------------------------------------------------------
# Obtain variance-covariance matrix of parameter uncertainty using the
# Sandwich estimator (default)
warfarin_pkmodel_varcov_sandwich = infer(warfarin_pkmodel_fit)

# Obtain variance-covariance matrix of parameter uncertainty using the 
# inverse Hessian matrix (i.e., MATRIX = R in NONMEM)
warfarin_pkmodel_varcov_hessian = infer(warfarin_pkmodel_fit; sandwich_estimator = false)

# -----------------------------------------------------------------------------
# 3. BOOTSTRAP
# -----------------------------------------------------------------------------
# Bootstrap analysis:
# - Resamples the data with replacement
# - Refits the model to each sample
# - Is more robust but computationally intensive

# Perform bootstrap with progress updates
# Keeping sample size small for purposes of demonstration
warfarin_pkmodel_bootstrap = infer(warfarin_pkmodel_fit, Bootstrap(samples = 100))

# Obtain raw results from bootstrap
warfarin_pkmodel_bootstrap_results = DataFrame(warfarin_pkmodel_bootstrap.vcov)

# Return a DataFrame of parameter estimates and precision from bootstrap
# Provide 95% confidence intervals
coeftable(warfarin_pkmodel_bootstrap; level = 0.95)

# -----------------------------------------------------------------------------
# 3. SAMPLING IMPORTANCE RESAMPLING (SIR)
# -----------------------------------------------------------------------------
# Sampling Importance Resampling:
# - SIR accepts the number of samples from the proposal (samples) and the
# number of resamples (resamples)
# - It is suggested that samples is at least 5 times larger than resamples to have
# sufficient samples to resample from
# - SIR draws its first samples from a truncated multivariate normal distribution
# from the variance-covariance matrix obtained from infer
# Perform SIR
warfarin_pkmodel_sir = infer(warfarin_pkmodel_fit, SIR(samples = 1000, resamples = 200))

# Obtain raw results from SIR
warfarin_pkmodel_sir_results = DataFrame(warfarin_pkmodel_sir.vcov)

# Return a DataFrame of parameter estimates and precision from SIR
# Provide 95% confidence intervals
coeftable(warfarin_pkmodel_sir; level = 0.95)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Parameter uncertainty can be estimated through multiple methods
# 2. Bootstrap is more robust but computationally intensive
# 3. Some parameters may be estimated more precisely than others
# 4. Fixing poorly identified parameters can improve estimation
# 5. Understanding uncertainty is crucial for model-based decision making

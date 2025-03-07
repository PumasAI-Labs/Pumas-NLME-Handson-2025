# =============================================================================
# Population PK-PD Modeling in Pumas - Part 3: Model Documentation
# =============================================================================
# LaTeX equations are uself for:
# 1. Scientific documentation
# 2. Publications and presentations
# 3. Clear communication of model structure
# 4. Validation of model implementation
#
# We'll generate equations for:
# - Model dynamics
# - Parameters and their domains
# - Derived variables
# - Random effects

# Import the previous code that create the Pumas population and Pumas model
include("02-pkpd_model.jl")  # This gives us the warfarin_model

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR MODEL DOCUMENTATION
# -----------------------------------------------------------------------------
using Pumas, Latexify, CairoMakie, Logging

# -----------------------------------------------------------------------------
# 2. LATEXIFY
# -----------------------------------------------------------------------------
# Generate LaTeX for the differential equations
# These describe how the system changes over time
dynamics_latex = latexify(warfarin_model, :dynamics)
render(dynamics_latex)

# Generate LaTeX for model parameters
# This includes:
# - Population parameters
# - Variance parameters
# - Error model parameters
params_latex = latexify(warfarin_model, :param)
render(params_latex)

# Generate LaTeX for derived variables
# These are quantities calculated from state variables
derived_latex = latexify(warfarin_model, :derived)
render(derived_latex)

# Generate LaTeX for random effects
# These describe individual variability
random_latex = latexify(warfarin_model, :random)
render(random_latex)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. LaTeX equations provide precise mathematical representation
# 2. Documentation is crucial for model validation
# 3. Clear equations help communicate model structure


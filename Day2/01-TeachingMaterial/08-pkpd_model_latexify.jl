# Script: 08-pkpd_model_latexify.jl
# Purpose: Generate LaTeX equations from the warfarin PK/PD model
# ==============================================================

using Pumas, Latexify, CairoMakie, Logging
include("03-pkpd_model.jl")  # This gives us the 'warfarin_model'

# Introduction to Model Documentation
# ------------------------------
# LaTeX equations are essential for:
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

@info "Starting LaTeX Equation Generation"
@info "==============================="

# Step 1: Model Dynamics
# ------------------
# Generate LaTeX for the differential equations
# These describe how the system changes over time
@info "Generating LaTeX for model dynamics..."
dynamics_latex = latexify(warfarin_model, :dynamics)
@info "Model dynamics in LaTeX format:"
render(dynamics_latex)

# Step 2: Model Parameters
# -------------------
# Generate LaTeX for model parameters
# This includes:
# - Population parameters
# - Variance parameters
# - Error model parameters
@info "Generating LaTeX for model parameters..."
params_latex = latexify(warfarin_model, :param)
@info "Model parameters in LaTeX format:"
render(params_latex)

# Step 3: Derived Variables
# --------------------
# Generate LaTeX for derived variables
# These are quantities calculated from state variables
@info "Generating LaTeX for derived variables..."
derived_latex = latexify(warfarin_model, :derived)
@info "Derived variables in LaTeX format:"
render(derived_latex)

# Step 4: Random Effects
# -----------------
# Generate LaTeX for random effects
# These describe individual variability
@info "Generating LaTeX for random effects..."
random_latex = latexify(warfarin_model, :random)
@info "Random effects in LaTeX format:"
render(random_latex)

# Educational Note:
# ---------------
@info "Key Takeaways from LaTeX Documentation:"
@info "1. LaTeX equations provide precise mathematical representation"
@info "2. Documentation is crucial for model validation"
@info "3. Clear equations help communicate model structure"


# =============================================================================
# Population PK Modeling in Pumas - Part 2: Defining Pumas Model
# =============================================================================

# The following code will demonstrate how to define a population pharmacokinetic
# model in Pumas using the warfarin dataset as an example.

# The example model is:
# - 1-compartment model
# - First-order absorption with lag time
# - Linear elimination
# - Allometric scaling on clearance and central volume of distribution
# - Inter-individual variability on clearance, central volume of distribution
# and the absorption half-life
# - Combined additive and proportional residual error model

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR DEFINING A PUMAS MODEL
# -----------------------------------------------------------------------------
using Pumas

# -----------------------------------------------------------------------------
# 2. MODEL DEFINITION
# -----------------------------------------------------------------------------
warfarin_pkmodel = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL   ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC   ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag  ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω     ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω   ∈ RealDomain(lower = 0.0, init = 0.09)
        
        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop   ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0, init = 0.0661)
    end

    # The @random block defines the distribution of individual random effects
    @random begin
        pk_η ~ MvNormal(pk_Ω) # Sample from multivariate normal distribution
        tabs_η ~ Normal(0.0, sqrt(tabs_ω)) # Sample from normal distribution
    end

    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual PK Parameters
        CL = θCL * FSZCL * exp(pk_η[1])
        Vc = θVC * FSZV * exp(pk_η[2])
        tabs = θtabs * exp(tabs_η)
        Ka = log(2) / tabs # Convert half-life to first-order rate constant
    end

    # Define dosing-related parameters (bioavailability [bioav], absorption rate [rate],
    # absorption duration [duration], absorption lag [lags])
    @dosecontrol begin
        lags = (Depot = θlag,) 
    end

    # Define derived variables used in dynamics and observations
    @vars begin
        # Concentration in central compartment
        cp := Central / Vc
    end

    # Define the differential equations for the model
    # Options available for using analytical solutions instead
    @dynamics begin
        Depot'    = -Ka * Depot              # Rate of change in depot compartment
        Central'  =  Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))  # Combined error model
    end
end

# Note: This model will be used in subsequent scripts for fitting and simulation
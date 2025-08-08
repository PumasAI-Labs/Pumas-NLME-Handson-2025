# =============================================================================
# Population PK-PD Modeling in Pumas - Part 2: Defining Pumas Model
# =============================================================================

# The following code will demonstrate how to define a population pharmacokinetic
# model in Pumas using the warfarin dataset as an example.

# The example model is:
# Pharmacokinetics:
# - 1-compartment model
# - First-order absorption with lag time
# - Linear elimination
# - Allometric scaling on clearance and central volume of distribution
# - Inter-individual variability on clearance, central volume of distribution
# and the absorption half-life
# - Combined additive and proportional residual error model

# Pharmacodynamics:
# - Indirect response model
# - Inhibition of response production
# - Emax relationship for effect of drug concentrations
# - No inter-individual variability
# - Proportional residual error model

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR DEFINING A PUMAS MODEL
# -----------------------------------------------------------------------------
using Pumas

# -----------------------------------------------------------------------------
# 2. MODEL DEFINITION
# -----------------------------------------------------------------------------
warfarin_model = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL   ∈ RealDomain(lower = 0.0)
        "Central Volume of Distribution (L/70 kg)"
        θVC   ∈ RealDomain(lower = 0.0)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0)
        "Absorption Lag Time (hr)"
        θlag  ∈ RealDomain(lower = 0.0)

        # Population PD Parameters
        "Baseline Prothrombin Complex Activity"
        θBASE ∈ RealDomain()
        "Maximum drug effect"
        θEMAX ∈ RealDomain(lower = 0.0, upper = 1.0)
        "Half-maximal concentration (mg/L)"
        θEC50 ∈ RealDomain(lower = 0.0)
        "Half-life of turnover (hr)"
        θTHALF ∈ RealDomain(lower = 0.0)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω     ∈ PDiagDomain(2)
        "Variance for IIV in Absorption Half-Life"
        tabs_ω   ∈ RealDomain(lower = 0.0)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop   ∈ RealDomain(lower = 0.0)
        "Additive Error for Concentrations (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0)
        "Proportional Residual Error for PCA"
        σ_proppd ∈ RealDomain(lower = 0.0)
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

        # Individual PD parameters
        BASE = θBASE
        EMAX = θEMAX
        EC50 = θEC50
        KON = log(2) / θTHALF # Convert half-life to first-order rate constant
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

    # Define the initial conditions for differential equations
    @init begin
        Depot = 0.0
        Central = 0.0
        PCA = BASE
    end

    # Define the differential equations for the model
    # Options available for using analytical solutions instead
    @dynamics begin
        Depot'    = -Ka * Depot              # Rate of change in depot compartment
        Central'  =  Ka * Depot - CL * cp    # Rate of change in central compartment
        PCA' = KON * BASE * (1 - EMAX * cp / (EC50 + cp)) - KON * PCA
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)) # Combined error model
        "Prothrombin Complex Activity"
        pca ~ @. Normal(PCA, sqrt((σ_proppd * PCA)^2)) # Proportional error model
    end
end

# Note: This model will be used in subsequent scripts for fitting and simulation
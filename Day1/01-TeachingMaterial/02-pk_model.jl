using Pumas

# Introduction to the Warfarin PK Model
# --------------------------------------
# This model describes:
# 1. PK (Pharmacokinetics): How the body processes warfarin
#    - One-compartment model
#    - First-order absorption with lag time
#    - First-order elimination

@info "Defining Warfarin PK Model..."

# Model Definition
# --------------
warfarin_pkmodel = @model begin
    ##### Parameter Block #####
    # The @param block defines all model parameters and their properties
    @param begin
        
        # PK Parameters
        # ------------
        "Clearance (L/h/70kg)"
        pop_CL   ∈ RealDomain(lower = 0.0, init = 0.134)  # Population clearance
        "Central Volume (L/70kg)"
        pop_V    ∈ RealDomain(lower = 0.0, init = 8.11)   # Population volume
        "Absorption time (h)"
        pop_tabs ∈ RealDomain(lower = 0.0, init = 0.523)  # Absorption time
        "Lag time (h)"
        pop_lag  ∈ RealDomain(lower = 0.0, init = 0.1)    # Lag time

        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "PK variability matrix (CL, V, Tabs)"
        pk_Ω     ∈ PDiagDomain([0.01, 0.01, 0.01])       # PK variability
        "Lag time variability"
        lag_ω    ∈ RealDomain(lower = 0.0, init = 0.1)    # Lag time variability
        
        # Residual Error Parameters
        # -----------------------
        "Proportional residual error for concentration"
        σ_prop   ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive residual error for concentration (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0, init = 0.0661)
    end

    ##### Random Effects Block #####
    # The @random block defines the distribution of individual random effects
    @random begin
        # PK random effects - multivariate normal distribution
        pk_η ~ MvNormal(pk_Ω)      # For CL, V, and Tabs
        lag_η ~ Normal(0.0, lag_ω) # For lag time
    end

    ##### Covariates Block #####
    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL

    ##### Pre-computation Block #####
    # Calculate individual parameters using population parameters, random effects, and covariates
    @pre begin
        # Individual PK Parameters
        # ----------------------
        CL = FSZCL * pop_CL * exp(pk_η[1])    # Individual clearance
        Vc = FSZV * pop_V * exp(pk_η[2])      # Individual volume
        tabs = pop_tabs * exp(pk_η[3])         # Individual absorption time
        Ka = log(2) / tabs                     # Absorption rate constant
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = pop_lag * exp(lag_η),) # Individual lag time
    end

    ##### Variables Block #####
    # Define derived variables used in dynamics and observations
    @vars begin
        cp := Central / Vc           # Concentration in central compartment
        ratein := Ka * Depot         # Absorption rate from depot
    end

    ##### Dynamics Block #####
    # Define the differential equations for the model
    @dynamics begin
        Depot'    = -ratein              # Change in depot compartment
        Central'  =  ratein - CL * cp    # Change in central compartment
    end

    ##### Observation Block #####
    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))  # Combined error model
    end
end

# Print model description and structure
@info "Model Structure Summary" sections=[
    "1. Compartments:",
    "   - Depot (absorption)",
    "   - Central (distribution)",
    "",
    "2. Parameters defined: $(length(Pumas.init_params(warfarin_pkmodel)))",
    "",
    "3. Random effects defined:",
    "   - PK: CL, V, Tabs",
    "",
    "4. Error models:",
    "   - Concentration: Combined (proportional + additive)",
]

# Note: This model will be used in subsequent scripts for fitting and simulation
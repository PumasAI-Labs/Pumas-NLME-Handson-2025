using Pumas

# Introduction to the Warfarin PK/PD Model
# --------------------------------------
# This model describes:
# 1. PK (Pharmacokinetics): How the body processes warfarin
#    - One-compartment model
#    - First-order absorption with lag time
#    - First-order elimination
#
# 2. PD (Pharmacodynamics): How warfarin affects PCA
#    - Indirect response model
#    - Inhibition of response production
#    - Turnover-based mechanism

@info "Defining Warfarin PK/PD Model..."

# Model Definition
# --------------
warfarin_model = @model begin
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
        
        # PD Parameters
        # ------------
        "Baseline PCA"
        pop_e0   ∈ RealDomain(lower = 0.0, init = 100.0)  # Baseline effect
        "Maximum inhibition"
        pop_emax ∈ RealDomain(init = -1.0)                # Maximum effect
        "Concentration at half-maximal effect"
        pop_c50  ∈ RealDomain(lower = 0.0, init = 1.0)    # EC50
        "Turnover time (h)"
        pop_tover ∈ RealDomain(lower = 0.0, init = 14.0)  # Turnover time
        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "PK variability matrix (CL, V, Tabs)"
        pk_Ω     ∈ PDiagDomain([0.01, 0.01, 0.01])       # PK variability
        "Lag time variability"
        lag_ω    ∈ RealDomain(lower = 0.0, init = 0.1)    # Lag time variability
        "PD variability matrix (E0, Emax, EC50, Turnover)"
        pd_Ω     ∈ PDiagDomain([0.01, 0.01, 0.01, 0.01]) # PD variability
        
        # Residual Error Parameters
        # -----------------------
        "Proportional residual error for concentration"
        σ_prop   ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive residual error for concentration (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0, init = 0.0661)
        "Additive error for PCA"
        σ_fx     ∈ RealDomain(lower = 0.0, init = 0.01)
    end

    ##### Random Effects Block #####
    # The @random block defines the distribution of individual random effects
    @random begin
        # PK random effects - multivariate normal distribution
        pk_η ~ MvNormal(pk_Ω)      # For CL, V, and Tabs
        lag_η ~ Normal(0.0, lag_ω) # For lag time
        # PD random effects - multivariate normal distribution
        pd_η ~ MvNormal(pd_Ω)      # For E0, Emax, EC50, and Turnover
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
        
        # Individual PD Parameters
        # ----------------------
        e0 = pop_e0 * exp(pd_η[1])            # Individual baseline
        emax = pop_emax * exp(pd_η[2])        # Individual maximum effect
        c50 = pop_c50 * exp(pd_η[3])          # Individual EC50
        tover = pop_tover * exp(pd_η[4])      # Individual turnover time
        kout = log(2) / tover                 # Elimination rate constant
        rin = e0 * kout                       # Zero-order production rate
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = pop_lag * exp(lag_η),) # Individual lag time
    end

    ##### Initial Conditions Block #####
    # Define the initial state of the system
    @init begin
        Turnover = e0  # Start at baseline PCA
    end

    ##### Variables Block #####
    # Define derived variables used in dynamics and observations
    @vars begin
        cp := Central / Vc           # Concentration in central compartment
        ratein := Ka * Depot         # Absorption rate from depot
        pd := 1 + emax * cp / (c50 + cp) # PD effect (inhibitory Emax model)
    end

    ##### Dynamics Block #####
    # Define the differential equations for the model
    @dynamics begin
        Depot'    = -ratein              # Change in depot compartment
        Central'  =  ratein - CL * cp    # Change in central compartment
        Turnover' =  rin * pd - kout * Turnover # Change in PCA
    end

    ##### Observation Block #####
    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))  # Combined error model
        "PCA"
        pca  ~ @. Normal(Turnover, σ_fx)  # Additive error model
    end
end

# Print model description and structure
@info "Model Structure Summary" sections=[
    "1. Compartments:",
    "   - Depot (absorption)",
    "   - Central (distribution)",
    "   - PCA (pharmacodynamic effect)",
    "",
    "2. Parameters defined: $(length(Pumas.init_params(warfarin_model)))",
    "",
    "3. Random effects defined:",
    "   - PK: CL, V, Tabs",
    "   - PD: E0, Emax, EC50, Turnover",
    "",
    "4. Error models:",
    "   - Concentration: Combined (proportional + additive)",
    "   - PCA: Additive"
]

# Note: This model will be used in subsequent scripts for fitting and simulation
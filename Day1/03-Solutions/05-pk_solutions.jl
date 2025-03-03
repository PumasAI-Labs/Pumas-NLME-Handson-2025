# Purpose: Solutions for Hands-on based on the Warfarin PK Model
# ==============================================================

using Pumas

# Exercise 1: Initial Parameter Exploration
# --------------------------------------

@info """
Exercise 1: Initial Parameter Exploration
-------------------------------------
Using the warfarin PK model:
1. Examine the current initial parameter estimates
2. Try different sets of initial values:
   - Increase/decrease clearance by 50%
   - Double/halve the volume of distribution
   - Modify random effect variances
3. Compare the model fits with different starting values
4. Document which changes lead to better/worse fits
"""

include(joinpath(@__DIR__, "..","01-TeachingMaterial","01-read_pumas_data.jl"))  # This gives us the 'pop' object
include(joinpath(@__DIR__, "..","01-TeachingMaterial","02-pk_model.jl") )      # This gives us the 'warfarin_pkmodel'
include(joinpath(@__DIR__, "..","01-TeachingMaterial","03-pk_model_fitting.jl") )      # This gives us the 'warfarin_pkmodel'

# First version of the model:
initial_params = init_params(warfarin_pkmodel)
coefficients_table(fpm) # Table of parameter estimates with metadata 

# Re-run with new initial values:
fit_newinit = fit(
    warfarin_pkmodel,              # The model we defined
    pop_pk,                        # The population data
    (;                             # Starting values
        initial_params...,
        lag_ω = 0.0, 
        pop_CL = 0.201, 
        #pop_V = 12.04,
        #pk_Ω =  Diagonal([0.1, 0.1, 0.1]),
    ),
    FOCE(),                        # Estimation method
    constantcoef = (:lag_ω,)      # Variability on lags doesn't work
)

coefficients_table(fit_newinit) # Table of parameter estimates with metadata 


# Exercise 2: Evaluate Alternative Model Structures
# --------------------------------------

@info """
Exercise 2: Evaluate Alternative Model Structures
-------------------------------------
Using the warfarin PK model:
1. Add a second compartment for drug distribution
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
2. Replace lag time by transit compartments for the absorption
"""

# Model Definition
# --------------
warfarin_pkmodel_2cmt = @model begin
    ##### Parameter Block #####
    # The @param block defines all model parameters and their properties
    @param begin
        
        # PK Parameters
        # ------------
        "Clearance (L/h/70kg)"
        pop_CL   ∈ RealDomain(lower = 0.0, init = 0.134)  # Population clearance
        "Central Volume (L/70kg)"
        pop_V    ∈ RealDomain(lower = 0.0, init = 8.11)   # Population volume
        "Intercompartmental Clearance (L/h/70kg)"
        pop_Q ∈ RealDomain(lower = 0.0, init = 0.1)  
        "Peripheral Volume (L/70kg)"
        pop_V2 ∈ RealDomain(lower = 0.0, init = 10)
        "Absorption time (h)"
        pop_tabs ∈ RealDomain(lower = 0.0, init = 0.523)  # Absorption time
        "Lag time (h)"
        pop_lag  ∈ RealDomain(lower = 0.0, init = 0.1)    # Lag time

        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "PK variability matrix (CL, V, Tabs)"
        pk_Ω     ∈ PDiagDomain([0.01, 0.01, 0.01])       # PK variability
        
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
        Q = FSZCL * pop_Q 
        V2 = FSZV * pop_V2 
        tabs = pop_tabs * exp(pk_η[3])         # Individual absorption time
        Ka = log(2) / tabs                     # Absorption rate constant
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = pop_lag,) # Individual lag time
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
        Central'  =  ratein - CL * cp - Q/Vc * Central + (Q/V2) * Peripheral
        Peripheral' = (Q/Vc) * Central - (Q/V2) * Peripheral
    end

    ##### Observation Block #####
    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))  # Combined error model
    end
end

# Fit
# --------------
fit_2cmt = fit(
    warfarin_pkmodel_2cmt,              # The model we defined
    pop_pk,                        # The population data
    init_params(warfarin_pkmodel_2cmt),
    FOCE()                       # Estimation method
)

coefficients_table(fit_2cmt) # Table of parameter estimates with metadata 

# AIC and VPC
# --------------
aic(fpm)
aic(fit_2cmt)

vpc_2cmt = vpc(fit_2cmt; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_2cmt,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (h)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)


# Exercise 3: Evaluate Alternative Model Structures
# --------------------------------------

@info """
Exercise 3: Evaluate Alternative Model Structures
-------------------------------------
Using the warfarin PK model:
1. Use Gamma distribution for the absorption
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_gamma = @model begin
    ##### Parameter Block #####
    # The @param block defines all model parameters and their properties
    @param begin
        
        # PK Parameters
        # ------------
        "Clearance (L/h/70kg)"
        pop_CL   ∈ RealDomain(lower = 0.0, init = 0.134)  # Population clearance
        "Central Volume (L/70kg)"
        pop_V    ∈ RealDomain(lower = 0.0, init = 8.11)   # Population volume
        "Mean absorption time (h)"
        pop_mat ∈ RealDomain(lower = 0, init = 1)
        "Number of transit compartments"
        pop_n ∈ RealDomain(lower = 0, init = 2)

        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "PK variability matrix (CL, V)"
        pk_Ω     ∈ PDiagDomain([0.01, 0.01])       # PK variability
        
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
        MAT = pop_mat
        N = pop_n
        ρ = @delay(Gamma(N, MAT / N), Central) # Gamma distribution
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        bioav = (; Central = 0.0)
    end

    ##### Variables Block #####
    # Define derived variables used in dynamics and observations
    @vars begin
        cp := Central / Vc           # Concentration in central compartment
    end

    ##### Dynamics Block #####
    # Define the differential equations for the model
    @dynamics begin
        Central'  =  ρ - CL * cp    # Change in central compartment
    end

    ##### Observation Block #####
    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))  # Combined error model
    end
end


# Fit
# --------------
fit_gamma = fit(
    warfarin_pkmodel_gamma,              # The model we defined
    pop_pk,                        # The population data
    init_params(warfarin_pkmodel_gamma),
    FOCE()                       # Estimation method
)

coefficients_table(fit_gamma) # Table of parameter estimates with metadata 

# AIC and VPC
# --------------
aic(fpm)
aic(fit_gamma)

vpc_gamma = vpc(fit_gamma; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_gamma,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (h)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)



# Exercise 4: Evaluate correlation between ηCL and ηV1
# --------------------------------------

@info """
Exercise 4: Evaluate correlation between ηCL and ηV1
-------------------------------------
Using the warfarin PK model:
1. Add correlation between ηCL and ηV1
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_corr = @model begin
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
        "PK variability matrix (CL, V)"
        clv_Ω    ∈ PSDDomain([0.02 0.01; 0.01 0.02])     
        "PK variability Tabs"
        tabs_Ω     ∈ PDiagDomain([0.01])      
        
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
        clv_η ~ MvNormal(clv_Ω)      # For CL, V
        tabs_η ~ MvNormal(tabs_Ω)      # For CL, V
    end

    ##### Covariates Block #####
    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL

    ##### Pre-computation Block #####
    # Calculate individual parameters using population parameters, random effects, and covariates
    @pre begin
        # Individual PK Parameters
        # ----------------------
        CL = FSZCL * pop_CL * exp(clv_η[1])    # Individual clearance
        Vc = FSZV * pop_V * exp(clv_η[2])      # Individual volume
        tabs = pop_tabs * exp(tabs_η[1])         # Individual absorption time
        Ka = log(2) / tabs                     # Absorption rate constant
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = pop_lag ,) # Individual lag time
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


# Fit
# --------------
fpm_corr = fit(
    warfarin_pkmodel_corr,              # The model we defined
    pop_pk,                        # The population data
    init_params(warfarin_pkmodel_corr),
    FOCE()                       # Estimation method
)

coef(fpm_corr) 

# AIC and VPC
# --------------
aic(fpm)
aic(fpm_corr)

vpc_corr= vpc(fpm_corr; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_corr,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (h)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)



# Exercise 5: Evaluate sex effect on CL
# --------------------------------------

@info """
Exercise 5: Evaluate sex effect on CL
-------------------------------------
Using the warfarin PK model:
1. Add sex effect on CL
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_sex = @model begin
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
        "Sex effect on CL"
        SEXonCL  ∈ RealDomain(init = 0.5)   
        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "PK variability matrix (CL, V, Tabs)"
        pk_Ω     ∈ PDiagDomain([0.01, 0.01, 0.01])       # PK variability
        
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
    end

    ##### Covariates Block #####
    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL SEX

    ##### Pre-computation Block #####
    # Calculate individual parameters using population parameters, random effects, and covariates
    @pre begin
        # Individual PK Parameters
        # ----------------------
        CL = FSZCL * pop_CL * exp(SEXonCL * SEX) * exp(pk_η[1])    # Individual clearance
        Vc = FSZV * pop_V * exp(pk_η[2])      # Individual volume
        tabs = pop_tabs * exp(pk_η[3])         # Individual absorption time
        Ka = log(2) / tabs                     # Absorption rate constant
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = pop_lag ,) # Individual lag time
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


# Fit
# --------------
fpm_sex = fit(
    warfarin_pkmodel_sex,              # The model we defined
    pop_pk,                        # The population data
    init_params(warfarin_pkmodel_sex),
    FOCE()                       # Estimation method
)

coefficients_table(fpm_sex) 

# AIC 
# --------------
aic(fpm)
aic(fpm_sex)

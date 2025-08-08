# =============================================================================
# Population PK Modeling in Pumas - Hands-on Solution
# =============================================================================

# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__,"..","TeachingMaterial","population_pk","03-pk_model_fitting.jl"))  # This gives us the fitted base model, warfarin_pkmodel_fit

# -----------------------------------------------------------------------------
# 1. Exercise 1: Initial Parameter Exploration
# -----------------------------------------------------------------------------

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

# New fit with new initial values:
fit_newinit = fit(
    warfarin_pkmodel,              # The model we defined
    pop_pk,                        # The population data
    (;                             # Starting values
        warfarin_pkmodel_initial_params...,
        θCL = 0.201, 
        #θVC = 16,
        #pk_Ω =  Diagonal([0.3, 0.3]),
    ),
    FOCE(),                        # Estimation method
)

coefficients_table(fit_newinit) # Table of parameter estimates with metadata 
vscodedisplay(compare_estimates(;warfarin_pkmodel_fit, fit_newinit))


# -----------------------------------------------------------------------------
# 2. Exercise 2: Evaluate Alternative Model Structure
# -----------------------------------------------------------------------------

@info """
Exercise 2: Evaluate Alternative Model Structures
-------------------------------------
Using the warfarin PK model:
1. Add a second compartment for drug distribution
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_2cmt = @model begin
    ##### Parameter Block #####
    # The @param block defines all model parameters and their properties
    @param begin
        
        # PK Parameters
        # ------------
        "Clearance (L/h/70 kg)"
        θCL   ∈ RealDomain(lower = 0.0)
        "Central Volume of Distribution (L/70 kg)"
        θVC   ∈ RealDomain(lower = 0.0)
        "Intercompartmental Clearance (L/h/70kg)"
        θQ ∈ RealDomain(lower = 0.0)  
        "Peripheral Volume (L/70kg)"
        θV2 ∈ RealDomain(lower = 0.0)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0)
        "Absorption Lag Time (hr)"
        θlag  ∈ RealDomain(lower = 0.0)
        
        # Inter-individual Variability (IIV)
        # --------------------------------
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω     ∈ PDiagDomain(2)
        "Variance for IIV in Absorption Half-Life"
        tabs_ω   ∈ RealDomain(lower = 0.0)
        
        # Residual Error Parameters
        # -----------------------
        "Proportional Error for Concentrations"
        σ_prop   ∈ RealDomain(lower = 0.0)
        "Additive Error for Concentrations (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0)
    end

    ##### Random Effects Block #####
    # The @random block defines the distribution of individual random effects
    @random begin
        pk_η ~ MvNormal(pk_Ω) # Sample from multivariate normal distribution
        tabs_η ~ Normal(0.0, sqrt(tabs_ω)) # Sample from normal distribution
    end

    ##### Covariates Block #####
    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL

    ##### Pre-computation Block #####
    # Calculate individual parameters using population parameters, random effects, and covariates
    @pre begin
        # Individual PK Parameters
        # ----------------------
        CL = θCL * FSZCL * exp(pk_η[1])
        Vc = θVC * FSZV * exp(pk_η[2])
        Q = θQ * FSZCL  
        V2 = θV2 * FSZV 
        tabs = θtabs * exp(tabs_η)
        Ka = log(2) / tabs # Convert half-life to first-order rate constant
    end

    ##### Dosing Control Block #####
    # Define dosing-related parameters
    @dosecontrol begin
        lags = (Depot = θlag,) 
    end

    ##### Variables Block #####
    # Define derived variables used in dynamics and observations
    @vars begin
        # Concentration in central compartment
        cp := Central / Vc
    end

    ##### Dynamics Block #####
    # Define the differential equations for the model
    @dynamics begin
        Depot'    = -Ka * Depot             # Rate of change in depot compartment
        Central'  =  Ka * Depot - CL/Vc * Central - Q/Vc * Central + (Q/V2) * Peripheral # Rate of change in central compartment
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
warfarin_pkmodel_2cmt_initial_params = merge(
    warfarin_pkmodel_initial_params,
    (; θQ = 0.1, θV2 = 10),
)

fit_2cmt = fit(
    warfarin_pkmodel_2cmt,              # The model we defined
    pop_pk,                        # The population data
    warfarin_pkmodel_2cmt_initial_params,
    FOCE()                       # Estimation method
)

coefficients_table(fit_2cmt) # Table of parameter estimates with metadata 

# Parameter uncertainty
# --------------
inf_2cmt = infer(fit_2cmt)

# Diagnostic plots and VPC
# --------------
pred_2cmt = inspect(fit_2cmt)
goodness_of_fit(pred_2cmt)

vpc_2cmt = vpc(fit_2cmt; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_2cmt,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (hr)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)

# Model comparison
# --------------
vscodedisplay(compare_estimates(; warfarin_pkmodel_fit, fit_2cmt)) # Comparison parameter estimates
lrtest(warfarin_pkmodel_fit, fit_2cmt) # likelihood ratio test to compare the two nested models

# Metrics comparison:
comp_metrics = @chain metrics_table(warfarin_pkmodel_fit) begin
    leftjoin(metrics_table(fit_2cmt); on = :Metric, makeunique = true)
    rename!(:Value => :pk1cmp, :Value_1 => :pk2cmp)
end
vscodedisplay(comp_metrics)


# -----------------------------------------------------------------------------
# 3. Exercise 3: Evaluate correlation between ηCL and ηV1
# -----------------------------------------------------------------------------

@info """
Exercise 3: Evaluate correlation between ηCL and ηV1
-------------------------------------
Using the warfarin PK model:
1. Add correlation between ηCL and ηV1
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_corr = @model begin
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

        # Inter-Individual Variability
        "PK variability matrix (CL, V)"
        pk_Ω    ∈ PSDDomain(2)
        "Variance for IIV in Absorption Half-Life"
        tabs_ω   ∈ RealDomain(lower = 0.0)
        
        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop   ∈ RealDomain(lower = 0.0)
        "Additive Error for Concentrations (mg/L)"
        σ_add    ∈ RealDomain(lower = 0.0)
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

# Fit
# --------------
warfarin_pkmodel_corr_initial_params = merge(
    warfarin_pkmodel_initial_params,
    (; pk_Ω = [0.02 0.01; 0.01 0.02]),
)

fit_corr = fit(
    warfarin_pkmodel_corr,              # The model we defined
    pop_pk,                        # The population data
    warfarin_pkmodel_corr_initial_params,
    FOCE()                       # Estimation method
)

coefficients_table(fit_corr) # Table of parameter estimates with metadata 

# Parameter uncertainty
# --------------
inf_corr = infer(fit_corr)

# Diagnostic plots and VPC
# --------------
pred_corr = inspect(fit_corr)
goodness_of_fit(pred_corr)

vpc_corr = vpc(fit_corr; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_corr,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (hr)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)

# Model comparison
# --------------
vscodedisplay(compare_estimates(; warfarin_pkmodel_fit, fit_corr)) # Comparison parameter estimates
lrtest(warfarin_pkmodel_fit, fit_corr) # likelihood ratio test to compare the two nested models

# Metrics comparison:
comp_metrics = @chain metrics_table(warfarin_pkmodel_fit) begin
    leftjoin(metrics_table(fit_corr); on = :Metric, makeunique = true)
    rename!(:Value => :pk1cmp, :Value_1 => :pkcorr)
end
vscodedisplay(comp_metrics)



# -----------------------------------------------------------------------------
# 4. Exercise 4: Evaluate covariate effect
# -----------------------------------------------------------------------------

@info """
Exercise 4: Evaluate sex effect on CL
-------------------------------------
Using the warfarin PK model:
1. Add sex effect on CL
2. Compare the model fits with the initial model
3. Document which changes lead to better/worse fits
"""

# Model Definition
# --------------
warfarin_pkmodel_sex = @model begin
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

        "Sex effect on CL"
        SEXonCL  ∈ RealDomain()  

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
    end

    # The @random block defines the distribution of individual random effects
    @random begin
        pk_η ~ MvNormal(pk_Ω) # Sample from multivariate normal distribution
        tabs_η ~ Normal(0.0, sqrt(tabs_ω)) # Sample from normal distribution
    end

    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL SEX

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual PK Parameters
        CL = θCL * FSZCL * exp(SEXonCL * SEX) * exp(pk_η[1])
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


# Fit
# --------------
warfarin_pkmodel_sex_initial_params = merge(
    warfarin_pkmodel_initial_params,
    (; SEXonCL = 0.5),
)

fit_sex = fit(
    warfarin_pkmodel_sex,              # The model we defined
    pop_pk,                        # The population data
    warfarin_pkmodel_sex_initial_params,
    FOCE()                       # Estimation method
)

coefficients_table(fit_sex) 

# Parameter uncertainty
# --------------
inf_sex = infer(fit_sex)

# Diagnostic plots and VPC
# --------------
pred_sex = inspect(fit_sex)
goodness_of_fit(pred_sex)

vpc_sex = vpc(fit_sex; observations = [:conc], ensemblealg = EnsembleThreads())
vpc_plot(vpc_sex,
    simquantile_medians = true,
    observations = true,
    axis = (
        xlabel = "Time (hr)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "VPC - Warfarin Concentration"
    ),
    figurelegend = (position = :t, 
                    orientation = :vertical, 
                    tellheight = true, tellwidth = false, nbanks = 3),
    figure = (size = (800, 600),)
)

# Model comparison
# --------------
vscodedisplay(compare_estimates(; warfarin_pkmodel_fit, fit_sex)) # Comparison parameter estimates
lrtest(warfarin_pkmodel_fit, fit_sex) # likelihood ratio test to compare the two nested models

# Metrics comparison:
comp_metrics = @chain metrics_table(warfarin_pkmodel_fit) begin
    leftjoin(metrics_table(fit_sex); on = :Metric, makeunique = true)
    rename!(:Value => :pk1cmp, :Value_1 => :sexoncl)
end
vscodedisplay(comp_metrics)
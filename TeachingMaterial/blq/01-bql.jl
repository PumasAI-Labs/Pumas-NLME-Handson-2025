# =============================================================================
# Handling BLQ data in Pumas
# =============================================================================

# Import warfarin PK data and model definition
include(joinpath(@__DIR__, "..", "data_read_wrangle", "03-data_wrangling.jl"))
include(joinpath(@__DIR__, "..", "population_pk", "02-pk_model.jl"))

# ------------------------------------------------------------------------------
# 1. PREPARING THE DATA
# ------------------------------------------------------------------------------

lloq = 1.0
df = @rtransform df_wide begin
    :BLQ = :EVID == 0 && :conc !== missing && :conc < lloq
end

vscodedisplay(df)

sum(df.BLQ)  # Count of BLQ data points

# -------------------------------------------------------------------------------
# 2. Utility for creating PK population
# -------------------------------------------------------------------------------

function create_pk_population(df::DataFrame)
    return read_pumas(
        df;
        # Subject identification
        id = :ID,           # Column containing subject IDs

        # Time information
        time = :TIME,       # Column containing time points

        # Dosing information
        amt = :AMOUNT,      # Dosing amounts
        cmt = :CMT,         # Compartment numbers
        evid = :EVID,       # Event type identifiers

        # Subject characteristics (covariates)
        covariates = [
            :SEX,           # Gender (0 = female, 1 = male)
            :WEIGHT,        # Body weight in kg
            :FSZV,          # Volume scaling factor
            :FSZCL,         # Clearance scaling factor
        ],

        # Measured responses (observations)
        observations = [
            :conc,          # Drug concentration
        ],
    )
end


### -----------------------------------------------------------------------------
# M1: Discard BLQ data
# -------------------------------------------------------------------------------

# `missing` concentrations are ignored in the likelihood calculations
df_m1 = @rtransform df :conc = :BLQ ? missing : :conc

# Alternative: Remove BLQ data points
df_m1_alt = @rsubset df !:BLQ

warfarin_pkmodel_fit_m1 = fit(
    warfarin_pkmodel, # Use the unmodified warfarin model
    create_pk_population(df_m1),
    init_params(warfarin_pkmodel),
    FOCE(),
)

# -------------------------------------------------------------------------------
# M2: Discard BLQ data and model non-BLQ data with truncated distribution
# -------------------------------------------------------------------------------

# `missing` concentrations are ignored in the likelihood calculations
df_m2 = @rtransform df :conc = :BLQ ? missing : :conc

# Take into account that BLQ data is discarded by changing the model distribution of `conc`
# to a truncated distribution
warfarin_pkmodel_m2 = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω ∈ RealDomain(lower = 0.0, init = 0.09)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add ∈ RealDomain(lower = 0.0, init = 0.0661)
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
        Depot' = -Ka * Depot              # Rate of change in depot compartment
        Central' = Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. truncated(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = lloq)  # Combined error model
        # conc ~ @. truncated_latent(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = lloq)  # Combined error model
    end
end

# Fit the model
warfarin_pkmodel_fit_m2 = fit(
    warfarin_pkmodel_m2,
    create_pk_population(df_m2),
    init_params(warfarin_pkmodel),
    LaplaceI(), # Have to use Laplace!
)

#----------------------------------------------------------------------------------
# `truncated` vs `truncated_latent`: Same likelihood, different sampling
#----------------------------------------------------------------------------------
halfnormal_truncated = truncated(Normal(0, 1); lower = lloq)
halfnormal_truncated_latent = truncated_latent(Normal(0, 1); lower = lloq)

# Same likelihood
pdf_truncated = pdf.(halfnormal_truncated, -1:0.01:5)
pdf_truncated_latent = pdf.(halfnormal_truncated_latent, -1:0.01:5)
data(
    (;
        x = repeat(-1:0.01:5, 2),
        pdf = vcat(pdf_truncated, pdf_truncated_latent),
        distribution = vcat(fill("truncated", length(pdf_truncated)), fill("truncated_latent", length(pdf_truncated_latent))),
    )
) *
    mapping(
    :x,
    :pdf,
    group = :distribution,
    color = :distribution,
    linestyle = :distribution
) * visual(Lines) |> draw(; axis = (; title = "Likelihood comparison"))

# Untruncated vs truncated sampling
xs_truncated = rand(halfnormal_truncated, 10_000)
xs_truncated_latent = rand(halfnormal_truncated_latent, 10_000)
data(
    (;
        x = vcat(xs_truncated, xs_truncated_latent),
        dist = vcat(fill("truncated", length(xs_truncated)), fill("truncated_latent", length(xs_truncated_latent))),
    )
) *
    mapping(
    :x,
    group = :dist,
    color = :dist,
) * AlgebraOfGraphics.density(; datalimits = extrema) |> draw(; axis = (; title = "Sampling comparison"))

# -------------------------------------------------------------------------------
# M3: Model BLQ data with censored distribution
# -------------------------------------------------------------------------------

# Censored data
df_m3 = @rtransform df :conc = :BLQ ? lloq : :conc

# Model of BLQ data with censored distribution
# to a truncated distribution
warfarin_pkmodel_m3 = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω ∈ RealDomain(lower = 0.0, init = 0.09)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add ∈ RealDomain(lower = 0.0, init = 0.0661)
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
        Depot' = -Ka * Depot              # Rate of change in depot compartment
        Central' = Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. censored_latent(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = lloq)  # Combined error model
        # conc ~ @. censored(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = lloq)  # Combined error model
    end
end

# Fit the model
warfarin_pkmodel_fit_m3 = fit(
    warfarin_pkmodel_m3,
    create_pk_population(df_m3),
    init_params(warfarin_pkmodel),
    LaplaceI(), # Have to use Laplace!
)

#----------------------------------------------------------------------------------
# `censored` vs `censored_latent`: Same likelihood, different sampling
#----------------------------------------------------------------------------------
halfnormal_censored = censored(Normal(0, 1); lower = lloq)
halfnormal_censored_latent = censored_latent(Normal(0, 1); lower = lloq)

# Same likelihood
pdf_censored = pdf.(halfnormal_censored, -1:0.01:5)
pdf_censored_latent = pdf.(halfnormal_censored_latent, -1:0.01:5)
data(
    (;
        x = repeat(-1:0.01:5, 2),
        pdf = vcat(pdf_censored, pdf_censored_latent),
        distribution = vcat(fill("censored", length(pdf_censored)), fill("censored_latent", length(pdf_censored_latent))),
    )
) *
    mapping(
    :x,
    :pdf,
    group = :distribution,
    color = :distribution,
    linestyle = :distribution
) * visual(Lines) |> draw(; axis = (; title = "Likelihood comparison"))

# Uncensored vs censored sampling
xs_censored = rand(halfnormal_censored, 10_000)
xs_censored_latent = rand(halfnormal_censored_latent, 10_000)
data(
    (;
        x = vcat(xs_censored, xs_censored_latent),
        dist = vcat(fill("truncated", length(xs_censored)), fill("truncated_latent", length(xs_censored_latent))),
    )
) *
    mapping(
    :x,
    group = :dist,
    color = :dist,
) * AlgebraOfGraphics.density(; datalimits = extrema) |> draw(; axis = (; title = "Sampling comparison"))

# -----------------------------------------------------------------------------
# M4: M3 with a truncated distribution
# -----------------------------------------------------------------------------

# Censored data
df_m4 = @rtransform df :conc = :BLQ ? lloq : :conc

# Model of BLQ data with censored distribution
# Takes into account that concentrations are always non-negative
warfarin_pkmodel_m4 = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω ∈ RealDomain(lower = 0.0, init = 0.09)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add ∈ RealDomain(lower = 0.0, init = 0.0661)
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
        Depot' = -Ka * Depot              # Rate of change in depot compartment
        Central' = Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. censored_latent(
            truncated(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = 0.0);
            lower = lloq,
        )
        #=
        conc ~ @. censored(
            truncated(Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2)); lower = 0.0);
            lower = lloq,
        )
        =#
    end
end

# Fit the model
warfarin_pkmodel_fit_m4 = fit(
    warfarin_pkmodel_m4,
    create_pk_population(df_m4),
    init_params(warfarin_pkmodel),
    LaplaceI(), # Have to use Laplace!
)

#----------------------------------------------------------------------------------
# M5: Impute BLQ data with LLOQ/2
#----------------------------------------------------------------------------------

# Impute BLQ data with LLOQ/2
df_m5 = @rtransform df :conc = :BLQ ? lloq / 2 : :conc

# Fit the model
warfarin_pkmodel_fit_m5 = fit(
    warfarin_pkmodel, # Use the unmodified warfarin model
    create_pk_population(df_m5),
    init_params(warfarin_pkmodel),
    FOCE(),
)

#----------------------------------------------------------------------------------
# M6: Impute consecutive BLQ data (set first to LLOQ/2, discard others)
#----------------------------------------------------------------------------------

# Impute first of consecutive BLQ data with LLOQ/2, discard following ones
df_m6 = @chain df begin
    @groupby :ID :EVID
    @transform! :conc = ifelse.(:EVID .== 0 .&& :BLQ, ifelse.(:BLQ .!= vcat(false, :BLQ[begin:(end - 1)]), lloq / 2, missing), :conc)
end

# Fit the model
warfarin_pkmodel_fit_m6 = fit(
    warfarin_pkmodel, # Use the unmodified warfarin model
    create_pk_population(df_m6),
    init_params(warfarin_pkmodel),
    FOCE(),
)

#----------------------------------------------------------------------------------
# M6+: Impute consecutive BLQ data (set first to LLOQ/2, discard others) and
#      increase additive error for BLQ data
#----------------------------------------------------------------------------------

# Impute first of consecutive BLQ data with LLOQ/2, discard following ones
df_m6p = @chain df begin
    @groupby :ID :EVID
    @transform! :conc = ifelse.(:EVID .== 0 .&& :BLQ, ifelse.(:BLQ .!= vcat(false, :BLQ[begin:(end - 1)]), lloq / 2, missing), :conc)
end

# Include BLQ as covariate
pop_m6p = read_pumas(
    df_m7p;
    # Subject identification
    id = :ID,           # Column containing subject IDs

    # Time information
    time = :TIME,       # Column containing time points

    # Dosing information
    amt = :AMOUNT,      # Dosing amounts
    cmt = :CMT,         # Compartment numbers
    evid = :EVID,       # Event type identifiers

    # Subject characteristics (covariates)
    covariates = [
        :SEX,           # Gender (0 = female, 1 = male)
        :WEIGHT,        # Body weight in kg
        :FSZV,          # Volume scaling factor
        :FSZCL,         # Clearance scaling factor
        :BLQ,           # BLQ indicator (boolean)
    ],

    # Measured responses (observations)
    observations = [
        :conc,          # Drug concentration
    ],
)

warfarin_pkmodel_m6p = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω ∈ RealDomain(lower = 0.0, init = 0.09)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add ∈ RealDomain(lower = 0.0, init = 0.0661)
    end

    # The @random block defines the distribution of individual random effects
    @random begin
        pk_η ~ MvNormal(pk_Ω) # Sample from multivariate normal distribution
        tabs_η ~ Normal(0.0, sqrt(tabs_ω)) # Sample from normal distribution
    end

    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL BLQ

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual PK Parameters
        CL = θCL * FSZCL * exp(pk_η[1])
        Vc = θVC * FSZV * exp(pk_η[2])
        tabs = θtabs * exp(tabs_η)
        Ka = log(2) / tabs # Convert half-life to first-order rate constant

        # Increase RUV for BLQ data
        σ_add_blq = BLQ ? σ_add + lloq / 2 : σ_add
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
        Depot' = -Ka * Depot              # Rate of change in depot compartment
        Central' = Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add_blq^2))  # Combined error model
    end
end

# Fit the model
warfarin_pkmodel_fit_m6p = fit(
    warfarin_pkmodel_m6p,
    pop_m6p,
    init_params(warfarin_pkmodel),
    FOCE(),
)

#----------------------------------------------------------------------------------
# M7: Impute BLQ data with 0
#----------------------------------------------------------------------------------

# Impute BLQ data with zero
df_m7 = @rtransform df :conc = :BLQ ? 0.0 : :conc

# Fit the model
warfarin_pkmodel_fit_m7 = fit(
    warfarin_pkmodel, # Use the unmodified warfarin model
    create_pk_population(df_m7),
    init_params(warfarin_pkmodel),
    FOCE(),
)

#----------------------------------------------------------------------------------
# M7+: Impute BLQ data with 0 and increase additive error for BLQ data
#----------------------------------------------------------------------------------

# Impute BLQ data with zero
df_m7p = @rtransform df :conc = :BLQ ? 0.0 : :conc

# Include BLQ as covariate
pop_m7p = read_pumas(
    df_m7p;
    # Subject identification
    id = :ID,           # Column containing subject IDs

    # Time information
    time = :TIME,       # Column containing time points

    # Dosing information
    amt = :AMOUNT,      # Dosing amounts
    cmt = :CMT,         # Compartment numbers
    evid = :EVID,       # Event type identifiers

    # Subject characteristics (covariates)
    covariates = [
        :SEX,           # Gender (0 = female, 1 = male)
        :WEIGHT,        # Body weight in kg
        :FSZV,          # Volume scaling factor
        :FSZCL,         # Clearance scaling factor
        :BLQ,           # BLQ indicator (boolean)
    ],

    # Measured responses (observations)
    observations = [
        :conc,          # Drug concentration
    ],
)

warfarin_pkmodel_m7p = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population PK Parameters
        "Clearance (L/h/70 kg)"
        θCL ∈ RealDomain(lower = 0.0, init = 0.134)
        "Central Volume of Distribution (L/70 kg)"
        θVC ∈ RealDomain(lower = 0.0, init = 8.11)
        "Absorption Half-Life (hr)"
        θtabs ∈ RealDomain(lower = 0.0, init = 0.523)
        "Absorption Lag Time (hr)"
        θlag ∈ RealDomain(lower = 0.0, init = 0.1)

        # Inter-Individual Variability
        "Variance-Covariance for IIV in PK Parameters"
        pk_Ω ∈ PDiagDomain([0.09, 0.09])
        "Variance for IIV in Absorption Half-Life"
        tabs_ω ∈ RealDomain(lower = 0.0, init = 0.09)

        # Random Unexplained Variability
        "Proportional Error for Concentrations"
        σ_prop ∈ RealDomain(lower = 0.0, init = 0.00752)
        "Additive Error for Concentrations (mg/L)"
        σ_add ∈ RealDomain(lower = 0.0, init = 0.0661)
    end

    # The @random block defines the distribution of individual random effects
    @random begin
        pk_η ~ MvNormal(pk_Ω) # Sample from multivariate normal distribution
        tabs_η ~ Normal(0.0, sqrt(tabs_ω)) # Sample from normal distribution
    end

    # Declare which covariates from the data will be used in the model
    @covariates FSZV FSZCL BLQ

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual PK Parameters
        CL = θCL * FSZCL * exp(pk_η[1])
        Vc = θVC * FSZV * exp(pk_η[2])
        tabs = θtabs * exp(tabs_η)
        Ka = log(2) / tabs # Convert half-life to first-order rate constant

        # Increase RUV for BLQ data
        σ_add_blq = BLQ ? σ_add + lloq : σ_add
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
        Depot' = -Ka * Depot              # Rate of change in depot compartment
        Central' = Ka * Depot - CL * cp    # Rate of change in central compartment
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Warfarin Concentration (mg/L)"
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add_blq^2))  # Combined error model
    end
end

# Fit the model
warfarin_pkmodel_fit_m7p = fit(
    warfarin_pkmodel_m7p,
    pop_m7p,
    init_params(warfarin_pkmodel),
    FOCE(),
)

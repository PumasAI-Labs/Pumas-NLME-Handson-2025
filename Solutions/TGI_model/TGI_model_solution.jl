# =============================================================================
# TGI Model from Claret et al., 2009 - Exercise
# =============================================================================
# https://pubmed.ncbi.nlm.nih.gov/19636014/
# ==============================================================

using Pumas, CairoMakie, DataFrames, Random, PumasUtilities

# Reproduce the model for FU Phase III

# Model set up
#------------
tgi_model = @model begin
    # The @param block defines all model parameters and their properties
    @param begin
        # Population Parameters
        "Tumor Growth Rate (week-1)"
        θKL   ∈ RealDomain()
        "Cell Kill Rate (g-1 x week-1)"
        θKD   ∈ RealDomain()
        "Resistance Appearance (week-1)"
        θλ ∈ RealDomain()

        # Inter-Individual Variability
        "Variance-Covariance for IIV"
        Ω     ∈ PDiagDomain(3)
        
        # Random Unexplained Variability
        "Additive Error for Concentrations (mm)"
        σ_add    ∈ RealDomain()
    end

    # The @random block defines the distribution of individual random effects
    @random begin
        η ~ MvNormal(Ω) # Sample from multivariate normal distribution
    end

    # Declare which covariates from the data will be used in the model
    # Exposure to be used as covariate in this example
    @covariates Exposure

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual Parameters
        KL = θKL * exp(η[1])
        KD = θKD * exp(η[2])
        λ = θλ * exp(η[3]) 

        # Define exposure (need to be redefined here to be used in @dynamics)
        Exp = Exposure
    end

    # Define the initial conditions for differential equations
    @init begin
        TS = 100  # Assume a baseline tumor size of 100 mm
    end

    # Define derived variables used in dynamics and observations
    @vars begin
        # Drug-constant cell kill rate that decreases exponentially with time (according to λ)
        KDt := KD * exp(-λ*t)
    end

    # Define the differential equation for the model
    @dynamics begin
        TS' = KL * TS - KDt * Exp * TS 
    end

    # Define how the model predictions relate to observed data
    @derived begin
        "Tumor size (mm)"
        yTS ~ @. Normal(TS, σ_add)
    end
end


# Parameter values
#------------
param = (
    θKL = 0.015, # week-1
    θKD = 0.058,  # g-1 x week-1
    θλ = 0.042,  # week-1
    Ω = Diagonal([0.556, 0.540, 0.450]), 
    σ_add = 14.9, # sd 
  )


# Simulations
#------------

# Define simulation times as weekly until 40 weeks
time_weekly =  collect(0.0:1.0:39.0) # Weeks from 0 to 39 weeks

# Define simulated exposure
# Daily dose was used as a metric for exposure
# FU 425 mg/m2 daily on days 1 to 5 every 4 weeks for 40 weeks
# Assuming 1.8 m2 BSA value -> 765 mg (to be converted in g)
# Use weekly doses for simulations
Exposure_values = repeat(vcat(765*5*0.001, fill(0, 3)), 10)  

#Example with dose 0
#Exposure_values = repeat(vcat(0, fill(0, 3)), 10)  

# Create a subject with the exposure as covariates and define covariates_time
subject = Subject(
    id = "1",
    covariates_time = time_weekly,
    covariates = (Exposure = Exposure_values,)
)

# Simulate:
simdata = simobs(
    tgi_model,
    subject,
    param;
    obstimes = time_weekly,
    simulate_error = false,
  )

# Plot:
sim_plot(simdata, 
        observations = [:yTS], 
        axis = (
        xlabel = "Time (weeks))",
        ylabel = "Tumor size (mm)",
        xticks = 0:4:40
    )
    )


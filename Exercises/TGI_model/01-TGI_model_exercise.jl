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

        # Inter-Individual Variability

        
        # Random Unexplained Variability

    end

    # The @random block defines the distribution of individual random effects
    @random begin

    end

    # Declare which covariates from the data will be used in the model
    # Exposure to be used as covariate in this example
    @covariates 

    # Calculate individual parameters using population parameters, random effects,
    # and covariates
    @pre begin
        # Individual Parameters



        # Define exposure (need to be redefined here to be used in @dynamics)
        Exp = Exposure
    end

    # Define the initial conditions for differential equations
    @init begin
         # Assume a baseline tumor size of 100 mm
    end

    # Define derived variables used in dynamics and observations
    @vars begin

    end

    # Define the differential equation for the model
    @dynamics begin

    end

    # Define how the model predictions relate to observed data
    @derived begin

    end
end


# Parameter values
#------------
param = (

  )


# Simulations
#------------

# Define simulation times as weekly until 40 weeks
time_weekly =  

# Define simulated exposure
# Daily dose was used as a metric for exposure
# FU 425 mg/m2 daily on days 1 to 5 every 4 weeks for 40 weeks
# Assuming 1.8 m2 BSA value -> 765 mg (to be converted in g)
# Use weekly doses for simulations
Exposure_values = 

# Create a subject with the exposure as covariates and define covariates_time


# Simulate:


# Plot:


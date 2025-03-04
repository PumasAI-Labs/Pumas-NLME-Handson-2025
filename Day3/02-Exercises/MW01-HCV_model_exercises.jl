# Purpose: HCV Model from Nyberg et al., 2014
# https://pmc.ncbi.nlm.nih.gov/articles/PMC4294071/
# ==============================================================

using Pumas, CairoMakie, DataFrames, Random, PumasUtilities, Logging


# Model set up
#------------
model_hcv = @model begin
    # The "@param" block specifies the parameters
    @param begin
      # fixed effects 
      logθKa ∈ RealDomain()

      # random effects variance parameters, must be posisitive
      ω²Ka ∈ RealDomain(lower = 0.0)

      # variance parameter in error models
      σ²PK ∈ RealDomain(lower = 0.0)

    end

    # The @random block allows us to specify variances for, and covariances
    # between, the random effects
    @random begin
        ηKa ~ Normal(0.0, sqrt(ω²Ka))

    end

    @pre begin
      # constants
      p = 
      d = 
      e = 
      s = 

      # Individual PK parameters
      logKa = logθKa + ηKa

    end

    @init begin
     # Initial state of the system
        T = 
        I = 
        W =
    end

    # The dynamics block is used to describe the evolution of our variables.
    @dynamics begin
        X' = 
        A' = 
        T' = 
        I' = 
        W' =
    end

    # The derived block is used to model the dependent variables. 
    @derived begin
        yPK ~ @. Normal()

    end
  end


# Parameter values:
#------------

prm = (
    logθKa = log(0.80),

  )


# Simulations
#------------

# Dosing regimen: 180 μg administered as a 24 h infusion once a week for 4 weeks
dr = 

# Create a population:
pop = 

# Simulate and plot:

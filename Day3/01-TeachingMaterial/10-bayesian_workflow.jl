using Pumas, CairoMakie, DataFrames, Random, PumasUtilities
include(joinpath("..", "..", "Day1", "01-TeachingMaterial", "01-read_pumas_data.jl"))
include(joinpath("..", "..", "Day1", "02-TeachingMaterial", "04-pkpd_model_fitting.jl"))

@info """
Bayesian Workflow for Warfarin PK/PD Model
=========================================
This script implements a Bayesian approach to parameter estimation for the warfarin model.
Key advantages of Bayesian analysis:
1. Provides full posterior distributions of parameters
2. Naturally incorporates parameter uncertainty
3. Allows incorporation of prior knowledge
4. Provides uncertainty quantification for predictions
"""

@info """
Prior Distributions
==================
We use informative priors based on literature and previous analyses:
- LogNormal priors for positive parameters (CL, V, etc.)
- Normal priors for parameters that can be negative (Emax)
- Constrained priors for variance parameters
"""

bayes_model = @model begin
    @param begin
        # PK parameters
        pop_CL   ~ LogNormal(log(0.134), 1.0) # L/h/70kg
        pop_V    ~ LogNormal(log(8.11), 1.0)  # L/70kg
        pop_tabs ~ LogNormal(log(0.523), 1.0) # h
        # PD parameters
        pop_e0   ~ LogNormal(log(100.0), 1.0)
        pop_emax ~ Normal(-1.0, 1.0)
        pop_c50  ~ LogNormal(log(1.0), 1.0)
        pop_tover ~ LogNormal(log(14.0), 1.0)
        # Inter-individual variability
        pk_Ω     ~ Constrained(MvNormal([0.01, 0.01, 0.01], 1.0), lower = 0.0) # unitless
        pd_Ω     ~ Constrained(MvNormal([0.01, 0.01, 0.01, 0.01], 1.0), lower = 0.0) # unitless
        # Residual variability
        σ_prop   ~ Constrained(Normal(0.00752, 0.1), lower = 0.0) # unitless
        σ_add    ~ Constrained(Normal(0.0661, 1.0), lower = 0.0) # mg/L
        σ_fx     ~ Constrained(Normal(0.01, 1.0), lower = 0.0) # unitless
    end

    @random begin
        # mean = 0, covariance = pk_Ω
        pk_η ~ MvNormal(Diagonal(pk_Ω))
        # mean = 0, covariance = pd_Ω
        pd_η ~ MvNormal(Diagonal(pd_Ω))
    end

    @covariates FSZV FSZCL

    @pre begin
        # PK
        CL = FSZCL * pop_CL * exp(pk_η[1])
        Vc = FSZV * pop_V * exp(pk_η[2])
        tabs = pop_tabs * exp(pk_η[3])
        Ka = log(2) / tabs
        # PD
        e0 = pop_e0 * exp(pd_η[1])
        emax = pop_emax * exp(pd_η[2])
        c50 = pop_c50 * exp(pd_η[3])
        tover = pop_tover * exp(pd_η[4])
        kout = log(2) / tover
        rin = e0 * kout
    end

    @init begin
        Turnover = e0
    end

    @vars begin
        cp := Central / Vc
        ratein := Ka * Depot
        pd := 1 + emax * cp / (c50 + cp)
    end

    @dynamics begin
        Depot'    = -ratein
        Central'  =  ratein - CL * cp
        Turnover' =  rin * pd - kout * Turnover
    end

    @derived begin
        conc ~ @. Normal(cp, sqrt((σ_prop * cp)^2 + σ_add^2))
        pca  ~ @. Normal(Turnover, σ_fx)
    end
end

@info """
MCMC Configuration
=================
Using the No-U-Turn Sampler (NUTS):
- Multiple chains for convergence assessment
- Adaptation period for tuning the sampler
- Burn-in period to discard initial samples
- Stiff ODE solver (Rodas5P) for numerical stability
"""

@info "Starting Bayesian model fitting..." 
@info "This may take some time depending on the number of samples and chains"

bayes_fpm = fit(
    bayes_model,
    pop,
    init_params(bayes_model),
    BayesMCMC(
        nsamples = 200,  # Number of posterior samples per chain
        nadapts = 100,   # Number of adaptation steps
        nchains = 4,     # Number of parallel chains
        alg = GeneralizedNUTS(max_depth = 3),  # NUTS algorithm with max tree depth
        diffeq_options = (; alg = Rodas5P()),  # Stiff ODE solver
    ),
)

@info """
Post-Processing MCMC Results
===========================
1. Inspect trace plots
2. Discard burn-in samples
3. Calculate posterior means
4. Compare with maximum likelihood estimates
5. Visualize posterior distributions
"""

# Inspect the traces of the chains
trace_plot(
    bayes_fpm,
    linkyaxes = :none,
)

# Printing all parameters parameters can be a bit busy
trace_plot(
    Chains(bayes_fpm),
    linkyaxes = :none,
    parameters = [:pop_CL, :pop_V, :pop_c50, :pop_e0, :pop_emax, :pop_tabs, :pop_tover]
)

# Remove burn-in period and get final samples
bayes_fpm_samples = Pumas.discard(bayes_fpm, burnin = 100)

# Compare posterior means with maximum likelihood estimates
@info "Comparing estimates:"
post_mean = mean(bayes_fpm_samples)
mle = coef(fpm)

# Calculate relative differences
rel_diff = Dict(
    param => (post_mean[param] - mle[param]) / mle[param] 
    for param in keys(mle) if contains(string(param), "pop") && !contains(string(param), "lag")
)

bayes_fpm_chns_df = DataFrame(Chains(bayes_fpm_samples))
combine(
    bayes_fpm_chns_df,
    Not(:iteration, :chain) .=> mean .=> Not(:iteration, :chain)
)

# Create posterior density plot for turnover time
@info "Creating posterior density plot for turnover time..."
fig = density_plot(bayes_fpm_samples, parameters = [:pop_tover])
save("turnover_posterior.png", fig)
@info "Posterior plot saved" path="turnover_posterior.png"

@info """
Key Takeaways from Bayesian Analysis
==================================
1. Posterior distributions provide full uncertainty quantification
2. Multiple chains help ensure convergence
3. Comparison with MLE gives insight into parameter identifiability
4. Posterior predictive checks can validate the model
5. Results can inform future study designs
""" 
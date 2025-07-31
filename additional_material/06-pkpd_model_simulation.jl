# =============================================================================
# Population PK-PD Modeling in Pumas - Part 6: Simulations
# =============================================================================

# Introduction to Model Simulation
# ----------------------------
# Simulation is a powerful tool in pharmacometrics that allows us to:
# 1. Predict outcomes for new dosing regimens
# 2. Account for parameter uncertainty
# 3. Design clinical trials
# 4. Evaluate "what-if" scenarios
# 5. Support decision-making in drug development
#
# We'll explore several simulation approaches:
# - Basic simulation with fixed parameters
# - Simulation with random effects
# - Simulation incorporating parameter uncertainty
# - Clinical trial simulation


# Import the previous code that returns the fitted Pumas model
include(joinpath(@__DIR__, "..", "TeachingMaterial", "population_pkpd", "03-pkpd_model_fitting.jl")) # This gives us the fitted model, warfarin_model_fit and the uncertainty

# -----------------------------------------------------------------------------
# 1. PACKAGES 
# -----------------------------------------------------------------------------
using Pumas, CairoMakie, DataFrames, Random, PumasUtilities, Logging, Random

# -----------------------------------------------------------------------------
# 2. SETTING SEED FOR RANDOM NUMBER GENERATION
# -----------------------------------------------------------------------------
# To ensure reproducible results, a seed should be set for random number
# generation
Random.seed!(123456)

# -----------------------------------------------------------------------------
# 3. BASIC POPULATION SIMULATION
# -----------------------------------------------------------------------------
# First, we'll simulate from the model using:
# - Fixed population parameters from our fit
# - Random effects sampled from their estimated distributions

# Simulate a single realization
sim1 = simobs(warfarin_model, pop_pkpd, coef(warfarin_model_fit))

sim_plot(
    warfarin_model,
    sim1,
    observations = [:conc]
)

sim_plot(
    warfarin_model,
    sim1,
    observations = [:pca]
)

# Simulate multiple populations
sims_multi = [simobs(warfarin_model, pop_pkpd, coef(warfarin_model_fit)) for _ in 1:100]

combined_sims = vcat(sims_multi...)  # Combine all simulations into a single Simulated Population

sim_plot(
    warfarin_model,
    combined_sims,
    observations = [:conc]
)

sim_plot(
    warfarin_model,
    combined_sims,
    observations = [:pca]
)


# -----------------------------------------------------------------------------
# 4. FINE-RESOLUTION TIME COURSE
# -----------------------------------------------------------------------------

# Simulate with smaller time steps to see smooth profiles
fine_sims = simobs(
    warfarin_model, 
    pop_pkpd, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:0.5:150.0,  # Fine time grid
    simulate_error = false # ignore the residual variability
)

# Create and save concentration plot
fig_conc = Figure(resolution = (800, 600))
ax_conc = Axis(
    fig_conc[1, 1],
    xlabel = "Time (h)",
    ylabel = "Warfarin Concentration (mg/L)",
    title = "Simulated Concentration Profiles"
)
sim_plot!(ax_conc, fine_sims, observations = [:conc])  # ! indicates that this function modifies its first argument
fig_conc
save("simulation_concentration.png", fig_conc)

# Create and save PCA plot
fig_pca = Figure(resolution = (800, 600))
ax_pca = Axis(
    fig_pca[1, 1],
    xlabel = "Time (h)",
    ylabel = "PCA",
    title = "Simulated PCA Profiles"
)
sim_plot!(ax_pca, fine_sims, observations = [:pca])
fig_pca
save("simulation_pca.png", fig_pca)


# -----------------------------------------------------------------------------
# 5. SIMULATION WITH PARAMETER UNCERTAINTY
# -----------------------------------------------------------------------------

# Use bootstrap results to incorporate parameter uncertainty
# Set random seed for reproducibility
rng = Pumas.default_rng()
Random.seed!(rng, 123)

# Simulate using bootstrap results
sims_uncertain = simobs(warfarin_model_varcov, pop_pkpd, samples = 1000, simulate_error = false)

# Create VPC from uncertainty simulations
vpc_uncertain_conc = vpc(sims_uncertain; observations = [:conc], ensemblealg = EnsembleThreads())
fig_vpc_conc = vpc_plot(
    vpc_uncertain_conc;
    axis = (xlabel = "Time (h)", 
            ylabel = "Warfarin Concentration (mg/L)", 
            title = "VPC with Parameter Uncertainty"),
    figure = (size = (800, 600),),
    simquantile_medians = true,
    observations = true,
    figurelegend = (position = :t, 
                    orientation = :horizontal, 
                    framevisible = false,
                    nbanks = 3),
)
save("vpc_with_uncertainty.png", fig_vpc_conc)

vpc_uncertain_pca = vpc(sims_uncertain; observations = [:pca], ensemblealg = EnsembleThreads())
fig_vpc_pca = vpc_plot(
    vpc_uncertain_pca;
    axis = (xlabel = "Time (h)", 
            ylabel = "PCA", 
            title = "VPC with Parameter Uncertainty"),
    figure = (size = (800, 600),),
    simquantile_medians = true,
    observations = true,
    figurelegend = (position = :t, 
                    orientation = :horizontal, 
                    framevisible = false,
                    nbanks = 3),
)
save("vpc_with_uncertainty_pca.png", fig_vpc_pca)

# -----------------------------------------------------------------------------
# 6. CLINICAL TRIAL SIMULATION
# -----------------------------------------------------------------------------

# Simulate outcomes for different dosing scenarios
# Simulate a dose of 300 at time 0 in the population:
dose_300 = DosageRegimen(300; time = 0)
# Create a population with the new dosing regimen:
pop_300 = Population(map(i -> Subject(id = i, events = dose_300, covariates = (; FSZV=1, FSZCL=1)), 1:100))
# Simulate:
sims_300 = simobs(
    warfarin_model, 
    pop_300, 
    coef(warfarin_model_fit), 
    obstimes = 0.0:0.5:150.0,  # Fine time grid
)
# Plot:
sim_plot(warfarin_model, sims_300; observations = [:conc])
sim_plot(warfarin_model, sims_300; observations = [:pca])



# Educational Note:
# ---------------
@info "Key Takeaways from Simulation Analysis:"
@info "1. Simulations help predict outcomes and understand variability"
@info "2. Parameter uncertainty affects prediction confidence"
@info "3. Different dosing scenarios can be evaluated"
@info "4. Visual predictive checks validate simulation results"
@info "5. Clinical trial simulation supports decision-making"

# Next Steps:
# ----------
@info "Potential Next Steps:"
@info "1. Evaluate additional dosing regimens"
@info "2. Simulate specific patient populations"
@info "3. Perform power calculations for future studies"
@info "4. Optimize sampling times for future trials"

# Execute if this script is run directly
if abspath(PROGRAM_FILE) == @__FILE__
    @info "Script completed successfully!"
    @info "Review the generated visualizations:" files=[
        "simulation_concentration.png",
        "simulation_pca.png",
        "vpc_with_uncertainty.png",
        "dose_comparison.png"
    ]
end 

# Functions to generate simulations
function basic_simulation(fpm)
    @info "Basic Model Simulation"
    @info "====================="
    
    # Sample random effects from their priors
    @info "Simulating with random effects from priors..."
    sims1 = simobs(fpm)
    
    # Plot the simulations
    fig = Figure(resolution = (1200, 600))
    
    # Concentration plot
    ax1 = Axis(
        fig[1, 1],
        xlabel = "Time (h)",
        ylabel = "Concentration (mg/L)",
        title = "Simulated Concentration"
    )
    sim_plot!(ax1, sims1, observations = [:conc])
    
    # PCA plot
    ax2 = Axis(
        fig[1, 2],
        xlabel = "Time (h)",
        ylabel = "PCA",
        title = "Simulated PCA"
    )
    sim_plot!(ax2, sims1, observations = [:pca])
    
    save("basic_simulation.png", fig)
end

function multiple_population_simulation(fpm; n_pop=100)
    @info "Multiple Population Simulation"
    @info "============================="
    
    # Simulate multiple populations
    @info "Simulating populations..." n_populations=n_pop
    sims = [simobs(fpm) for _ in 1:n_pop]
    
    # Plot all simulations
    fig = Figure(resolution = (1200, 600))
    
    # Concentration plot
    ax1 = Axis(
        fig[1, 1],
        xlabel = "Time (h)",
        ylabel = "Concentration (mg/L)",
        title = "Multiple Population Simulations - Concentration"
    )
    for sim in sims
        sim_plot!(ax1, sim, observations = [:conc], color = (:blue, 0.1))
    end
    
    # PCA plot
    ax2 = Axis(
        fig[1, 2],
        xlabel = "Time (h)",
        ylabel = "PCA",
        title = "Multiple Population Simulations - PCA"
    )
    for sim in sims
        sim_plot!(ax2, sim, observations = [:pca], color = (:red, 0.1))
    end
    
    save("multiple_simulations.png", fig)
    
    return sims
end

function fine_grid_simulation(fpm)
    @info "Fine Time Grid Simulation"
    @info "========================"
    
    # Simulate with fine time grid
    @info "Simulating with fine time grid..."
    fine_sims = simobs(fpm, obstimes = 0.0:0.5:150.0)
    
    # Plot the fine grid simulations
    fig = Figure(resolution = (1200, 600))
    
    # Concentration plot
    ax1 = Axis(
        fig[1, 1],
        xlabel = "Time (h)",
        ylabel = "Concentration (mg/L)",
        title = "Fine Grid Simulation - Concentration"
    )
    sim_plot!(ax1, fine_sims, observations = [:conc])
    
    # PCA plot
    ax2 = Axis(
        fig[1, 2],
        xlabel = "Time (h)",
        ylabel = "PCA",
        title = "Fine Grid Simulation - PCA"
    )
    sim_plot!(ax2, fine_sims, observations = [:pca])
    
    save("fine_grid_simulation.png", fig)
end

function post_process_simulations(sims)
    @info "Post-processing Simulations"
    @info "=========================="
    
    # Calculate PK/PD parameters from simulations
    @info "Calculating AUC and Cmax..."
    nca_params = postprocess(reduce(vcat, sims)) do gen, obs
        pk_auc = NCA.auc(gen.conc, gen.time)
        pk_cmax = NCA.cmax(gen.conc, gen.time)
        pd_auc = NCA.auc(gen.pca, gen.time)
        pd_cmax = NCA.cmax(gen.pca, gen.time)
        (; pk_auc, pk_cmax, pd_auc, pd_cmax)
    end
    
    # Calculate probability of being in therapeutic range
    prob = mean(nca_params) do p
        !ismissing(p.pk_auc) && 500.0 < p.pk_auc < 1000.0 && p.pk_cmax <= 15
    end
    @info "Therapeutic success probability" probability=prob
    
    # Plot distributions
    fig = Figure(resolution = (1200, 800))
    
    # AUC distributions
    ax1 = Axis(
        fig[1, 1],
        xlabel = "AUC",
        ylabel = "Count",
        title = "PK AUC Distribution"
    )
    hist!(ax1, filter(!ismissing, getproperty.(nca_params, :pk_auc)))
    
    ax2 = Axis(
        fig[1, 2],
        xlabel = "AUC",
        ylabel = "Count",
        title = "PD AUC Distribution"
    )
    hist!(ax2, filter(!ismissing, getproperty.(nca_params, :pd_auc)))
    
    # Cmax distributions
    ax3 = Axis(
        fig[2, 1],
        xlabel = "Cmax",
        ylabel = "Count",
        title = "PK Cmax Distribution"
    )
    hist!(ax3, filter(!ismissing, getproperty.(nca_params, :pk_cmax)))
    
    ax4 = Axis(
        fig[2, 2],
        xlabel = "Cmax",
        ylabel = "Count",
        title = "PD Cmax Distribution"
    )
    hist!(ax4, filter(!ismissing, getproperty.(nca_params, :pd_cmax)))
    
    save("derived_parameters.png", fig)
end
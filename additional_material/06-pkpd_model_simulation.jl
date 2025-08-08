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
using Pumas, CairoMakie, Random, PumasUtilities

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

combined_sims = reduce(vcat, sims_multi)  # Combine all simulations into a single Simulated Population

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
fig_conc = sim_plot(
    fine_sims;
    observations = [:conc],
    figure = (; size = (800, 600)),
    axis = (;
        xlabel = "Time (h)",
        ylabel = "Warfarin Concentration (mg/L)",
        title = "Simulated Concentration Profiles",
    ),
)
save("simulation_concentration.png", fig_conc)

# Create and save PCA plot
fig_pca = sim_plot(
    fine_sims;
    observations = [:pca],
    figure = (; size = (800, 600)),
    axis = (;
        xlabel = "Time (h)",
        ylabel = "PCA",
        title = "Simulated PCA Profiles",
    ),
)
save("simulation_pca.png", fig_pca)


# -----------------------------------------------------------------------------
# 5. SIMULATION WITH PARAMETER UNCERTAINTY
# -----------------------------------------------------------------------------

# Use bootstrap results to incorporate parameter uncertainty
# Set random seed for reproducibility
Random.seed!(123)

# Simulate using bootstrap results
sims_uncertain = simobs(warfarin_model_varcov, pop_pkpd, samples = 1000, simulate_error = false)

# Create VPC from uncertainty simulations
vpc_uncertain_conc = vpc(sims_uncertain; observations = [:conc])
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

vpc_uncertain_pca = vpc(sims_uncertain; observations = [:pca])
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
    sims1 = simobs(fpm.model, fpm.data, coef(fpm))
    
    # Plot the simulations
    fig = Figure(size = (1200, 600))
    
    # Concentration plot
    sim_plot(
        fig[1, 1],
        sims1;
        observations = [:conc],
        axis = (;
            xlabel = "Time (h)",
            ylabel = "Concentration (mg/L)",
            title = "Simulated Concentration",
        ),
    )
    
    # PCA plot
    sim_plot(
        fig[1, 2],
        sims1;
        observations = [:pca],
        axis = (;
            xlabel = "Time (h)",
            ylabel = "PCA",
            title = "Simulated PCA",
        ),
    )
    
    save("basic_simulation.png", fig)
end

function multiple_population_simulation(fpm; n_pop=100)
    @info "Multiple Population Simulation"
    @info "============================="
    
    # Simulate multiple populations
    @info "Simulating populations..." n_populations=n_pop
    sims = [simobs(fpm.model, fpm.data, coef(fpm)) for _ in 1:n_pop]
    
    # Plot all simulations
    allsims = reduce(vcat, sims)  # Combine all simulations
    fig = Figure(size = (1200, 600))
    
    # Concentration plot
    sim_plot(
        fig[1, 1],
        allsims;
        observations = [:conc],
        color = (:blue, 0.1),
        axis = (;
            xlabel = "Time (h)",
            ylabel = "Concentration (mg/L)",
            title = "Multiple Population Simulations - Concentration",
        ),
    )
    
    # PCA plot
    sim_plot(
        fig[1, 2],
        allsims;
        observations = [:pca],
        color = (:red, 0.1),
        axis = (;
            xlabel = "Time (h)",
            ylabel = "PCA",
            title = "Multiple Population Simulations - PCA",
        ),
    )
    
    save("multiple_simulations.png", fig)
    
    return sims
end

function fine_grid_simulation(fpm)
    @info "Fine Time Grid Simulation"
    @info "========================"
    
    # Simulate with fine time grid
    @info "Simulating with fine time grid..."
    fine_sims = simobs(fpm.model, fpm.data, coef(fpm); obstimes = 0.0:0.5:150.0)
    
    # Plot the fine grid simulations
    fig = Figure(size = (1200, 600))
    
    # Concentration plot
    sim_plot(
        fig[1, 1],
        fine_sims;
        observations = [:conc],
        axis = (;
            xlabel = "Time (h)",
            ylabel = "Concentration (mg/L)",
            title = "Fine Grid Simulation - Concentration",
        ),
    )
    
    # PCA plot
    sim_plot(
        fig[1, 2],
        fine_sims;
        observations = [:pca],
        axis = (;
            xlabel = "Time (h)",
            ylabel = "PCA",
            title = "Fine Grid Simulation - PCA",
        ),
    )
    
    save("fine_grid_simulation.png", fig)

    return fig
end

function post_process_simulations(sims)
    @info "Post-processing Simulations"
    @info "=========================="
    
    # Calculate PK/PD parameters from simulations
    @info "Calculating AUC and Cmax..."
    nca_params = postprocess(reduce(vcat, sims)) do gen, obs
        PK_AUC = NCA.auc(gen.conc, gen.t)
        PK_Cmax = NCA.cmax(gen.conc, gen.t)
        PD_AUC = NCA.auc(gen.pca, gen.t)
        PD_Cmax = NCA.cmax(gen.pca, gen.t)
        (; PK_AUC, PK_Cmax, PD_AUC, PD_Cmax)
    end
    
    # Calculate probability of being in therapeutic range
    prob = mean(nca_params) do p
        !ismissing(p.PK_AUC) && 500.0 < p.PK_AUC < 1000.0 && p.PK_Cmax <= 15
    end
    @info "Therapeutic success probability" probability=prob

    # Convert to DataFrame for easier handling
    nca_params_df = @chain DataFrame(nca_params) begin
        # Convert to long format
        stack
        # Drop missing values
        dropmissing(_, :value)
        # Split variable into observation and NCA type
        @rtransform @astable begin
            obs_nca = split(:variable, "_"; limit = 2)
            :obs = obs_nca[1]
            :nca = obs_nca[2]
        end
    end

    # Plot distributions
    specs = data(nca_params_df) * 
        mapping(:value, row = :nca, col = :obs => sorter(["PK", "PD"])) *
        histogram(bins=15, datalimits=extrema)
    fig = draw(specs; figure = (; size = (1200, 800)), facet = (; linkxaxes = :none))
    
    save("derived_parameters.png", fig)

    return fig
end

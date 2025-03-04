# Script: XX-pk_model_simulation.jl
# Purpose: Perform simulation and exposure metrics calculations
# ==============================================================
using Pumas
include(joinpath("..", "..", "Day1", "01-TeachingMaterial", "03-pk_model_fitting.jl"))

# The simobs function
# Possible to simulate based on a fitted model
fpm_so = simobs(fpm)

fpm_so_pv = sim_plot(
    fpm_so;
    separate = true,
    paginate = true
)
fpm_so_pv[1] # Render the first plot page

# What is being simluated here? Potentially three layers of randomness:
# 1. Population parameter estimates, due to estimation uncertainty
# 2. Random effects samling
# 3. Error model sampling

# When fitting a FittedPumasModel (without priors on the parameters) then
# only the error model triggers sampling. The population parameters are
# fixed at the point estimates and the random effects are fixed at the
# empirical bayes esimates

# More granular control of the simulation can be achived by calling the
# simobs method below. The first version is equivalent to calling the
# method above
mdl_ebe_so = simobs(
    warfarin_pkmodel,    # The model we defined
    pop_pk,              # The data
    coef(fpm),           # final parameters from the fit
    empirical_bayes(fpm) # extract the EBEs
)

mdl_ebe_so_pv = sim_plot(
    mdl_ebe_so;
    separate = true,
    paginate = true
)
mdl_ebe_so_pv[1] # Render the first plot page

# We might not want to simulate based on the empirical bayes estimated but
# instead to draw the random effects randomly. This can be done with the 
# sample_randeffs function

rfx_ntv = sample_randeffs(
    warfarin_pkmodel, # the model
    coef(fpm),        # the parameters
    pop_pk            # the population
)

# We can pass these values to simobs instead of the EBEs
mdl_rand_rfx_so = simobs(
    warfarin_pkmodel,    # The model we defined
    pop_pk,              # The data
    coef(fpm),           # final parameters from the fit
    rfx_ntv              # extract the EBEs
)

mdl_rand_rfx_so_pv = sim_plot(
    mdl_rand_rfx_so;
    separate = true,
    paginate = true
)
mdl_rand_rfx_so_pv[1]

# As expected, te can see the the predictions no longer align with the observations
# given that the random effects are now drawn randomly.

# Alternatively, we might want to completely disable randomness in the simulation, i.e.
# to get the individual predictions. This an be done with
mdl_no_rand_so = simobs(
    warfarin_pkmodel,      # The model we defined
    pop_pk,                # The data
    coef(fpm),             # final parameters from the fit
    empirical_bayes(fpm),  # extract the EBEs
    simulate_error = false # Disable random draws in the error model
)

mdl_no_rand_so_pv = sim_plot(
    mdl_no_rand_so;
    separate = true,
    paginate = true,
    # observations = 
)
mdl_no_rand_so_pv[1]

# The granularity of the predicted concentrations is by default based on the input
# data. It is possible to pass a custom time vector to get more granular predictions
mdl_no_rand_smooth_so = simobs(
    warfarin_pkmodel,        # The model we defined
    pop_pk,                  # The data
    coef(fpm),               # final parameters from the fit
    empirical_bayes(fpm),    # extract the EBEs
    simulate_error = false,  # Disable random draws in the error model
    obstimes = 0.0:0.1:150.0 # Custom time points for simulation
)

mdl_no_rand_smooth_so_pv = sim_plot(
    mdl_no_rand_smooth_so;
    separate = true,
    paginate = true,
    # observations = 
)
mdl_no_rand_smooth_so_pv[1]

# Alternative dosing regimens

# in Pumas, a dosing regimen can be defined with the DosageRegimen constructor
new_dr_v = [
    DosageRegimen(
        1.5*sub.covariates(0.0).WEIGHT, # Dose 1.5mg/kg
        route = NCA.EV                     # Set route for NCA postprocessing
    ) for sub in pop_pk
]

# We can create a new subject from the old one by passing it to the Subject constructor
# and then overwrite the events

Subject(pop_pk[1]; events = new_dr_v[1])

# ...or for all subjects
new_pop_pk = [Subject(sub; events = dr) for (sub, dr) in zip(pop_pk, new_dr_v)]

# We can now simulate based on the new population
new_sim_so = simobs(
    warfarin_pkmodel,    # The model we defined
    new_pop_pk,          # The data
    coef(fpm),           # final parameters from the fit
    rfx_ntv              # Use the sampled values that we already have
)

# NCA calculations

# What is the type of the simulated object
typeof(new_sim_so)

# We can convert the SimulatedObservations to a Subject, i.e. "data" by using the Subject constructor
new_sim_1_s = Subject(new_sim_so[1])

# We can analyze such simulated data by converting it to an NCASubject
# There might be multiple endpoint so we need to specify observations
sim_nca_1_s = NCASubject(new_sim_1_s; observations = :conc)

# Compuate the NCA based AUC
nca_1_1_half_mgkg = NCA.auc(sim_nca_1_s)

# We can now simulate the first subject with a higher dose
new_sub_2mgpk_1_s = Subject(
    new_pop_pk[1];
    events = DosageRegimen(
        2.0*new_pop_pk[1].covariates(0.0).WEIGHT,
        route = NCA.EV
    )
)

new_sim_2mgkg_1_so = simobs(
    warfarin_pkmodel,    # The model we defined
    new_sub_2mgpk_1_s,     # The data
    coef(fpm),           # final parameters from the fit
    rfx_ntv[1]
)

# What is the new AUC
nca_1_2mgkg = NCA.auc(NCASubject(
    Subject(new_sim_2mgkg_1_so),
    observations = :conc
))

# As expected, the exposure increases proportionally to the dose
nca_1_2mgkg / nca_1_1_half_mgkg
2/1.5

# Exercises
# - Simulate with alternative regimens

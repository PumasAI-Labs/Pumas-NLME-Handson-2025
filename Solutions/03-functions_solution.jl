using Test

# Exercise 1: Basic Function Definition
function calculate_clearance(volume::Float64, elimination_rate::Float64)
    return volume * elimination_rate
end

function calculate_half_life(elimination_rate::Float64)
    return log(2) / elimination_rate
end

function calculate_auc(dose::Float64, clearance::Float64)
    return dose / clearance
end

# Test Exercise 1
@test calculate_clearance(50.0, 0.1) == 5.0
@test calculate_half_life(0.1) ≈ 6.93 atol=0.01
@test calculate_auc(100.0, 5.0) == 20.0

# Exercise 2: Multiple Dispatch
function calculate_dose(weight::Real, dose_per_kg::Real)
    return weight * dose_per_kg
end
function calculate_dose(weights::Vector{<:Real}, dose_per_kg::Real)
    return calculate_dose.(weights, dose_per_kg)
end

function calculate_dose_alt(weights::Union{Real, Vector{<:Real}}, dose_per_kg::Real)
    return weights * dose_per_kg
end

# Test Exercise 2
@test length(methods(calculate_dose)) == 2 # two methods for both cases
@test calculate_dose(70.0, 2.0) == 140.0  # single subject
@test calculate_dose([65.3, 92.1], 2.0) == [130.6, 184.2]  # multiple subjects

@test length(methods(calculate_dose_alt)) == 1 # single method handles both cases
@test calculate_dose_alt(70.0, 2.0) == 140.0  # single subject
@test calculate_dose_alt([65.3, 92.1], 2.0) == [130.6, 184.2]  # multiple subjects

# Exercise 3: Anonymous Functions
C0 = 100.0
k = 0.1
concentration_at_t = t -> C0 * exp(-k * t)
time_points = [0, 1, 2, 4, 8]
concentrations = map(concentration_at_t, time_points)

# Test Exercise 3
@test length(concentrations) == length(time_points)
@test concentrations[1] ≈ 100.0
@test all(concentrations[i] > concentrations[i+1] for i in 1:length(concentrations)-1)

# Bonus Challenge
function simulate_pk(dosing_function::Function, time_points::Vector{Float64}, pk_params::Dict{String,Float64})
    # Single dose simulation
    function single_dose(t)
        C0 = pk_params["dose"] / pk_params["volume"]
        k = pk_params["clearance"] / pk_params["volume"]
        return dosing_function(C0, k, t)
    end
    
    # Multiple dose simulation (superposition)
    function multiple_dose(t)
        tau = pk_params["dosing_interval"]
        doses = floor(Int, t/tau)
        return sum(single_dose(t - i*tau) for i in 0:doses)
    end
    
    if haskey(pk_params, "dosing_interval")
        return map(multiple_dose, time_points)
    else
        return map(single_dose, time_points)
    end
end

# Test Bonus Challenge
pk_params_single = Dict{String,Float64}(
    "dose" => 100.0,
    "volume" => 50.0,
    "clearance" => 5.0
)

pk_params_multiple = Dict{String,Float64}(
    "dose" => 100.0,
    "volume" => 50.0,
    "clearance" => 5.0,
    "dosing_interval" => 12.0
)

simple_pk = (C0, k, t) -> C0 * exp(-k * t)
test_times = [0.0, 6.0, 12.0, 24.0]

single_dose_results = simulate_pk(simple_pk, test_times, pk_params_single)
multiple_dose_results = simulate_pk(simple_pk, test_times, pk_params_multiple)

@test length(single_dose_results) == length(test_times)
@test length(multiple_dose_results) == length(test_times)
@test all(multiple_dose_results .>= single_dose_results) 
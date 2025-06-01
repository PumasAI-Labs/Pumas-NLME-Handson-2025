using Test
using Statistics

# Exercise 1: Map and Filter
weights = [62.5, 75.0, 58.2, 91.4, 68.7, 83.2, 55.8, 77.3]
height = 170.0  # cm

# Calculate BSA using map
bsa_calc = w -> 0.007184 * w^0.425 * height^0.725
bsa_values = map(bsa_calc, weights)

# Filter patients with BSA > 1.8
high_bsa_patients = filter(bsa -> bsa > 1.8, bsa_values)

# Test Exercise 1
@test length(bsa_values) == length(weights)
@test all(bsa_values .> 0)
@test all(high_bsa_patients .> 1.8)

# Exercise 2: Reduce and Fold
times = [0, 0.5, 1, 2, 4, 8, 12]
concs = [100.0, 85.2, 72.5, 52.4, 27.5, 7.6, 2.1]

# Calculate AUC using reduce
function trapz_step(acc, i)
    if i == 1
        return 0.0
    end
    return acc + (concs[i] + concs[i-1]) * (times[i] - times[i-1]) / 2
end

auc = reduce(trapz_step, 1:length(times))

# Calculate cumulative concentrations using foldr
cum_concs = foldr((x, acc) -> [x + acc[1]; acc], concs, init=[0.0])
pop!(cum_concs)  # Remove the initial 0.0

# Test Exercise 2
@test auc > 0
@test length(cum_concs) == length(concs)
@test cum_concs[1] ≈ sum(concs)

# Exercise 3: Broadcasting
volumes = [45.2, 52.8, 48.7, 55.3, 50.1]      # L
clearances = [4.5, 5.2, 4.8, 5.5, 5.0]        # L/hr
doses = [100.0, 150.0, 125.0, 175.0, 150.0]   # mg

# Broadcasting calculations
initial_concs = doses ./ volumes
elimination_rates = clearances ./ volumes

# Function for concentration over time
calc_conc(C0, k, t) = C0 * exp(-k * t)
t_points = [0.0, 1.0, 2.0, 4.0, 8.0]

# Broadcasting over time points for each patient
concentrations = [calc_conc.(ic, er, t_points) for (ic, er) in zip(initial_concs, elimination_rates)]

# Test Exercise 3
@test size(concentrations) == (length(volumes),)
@test length(concentrations[1]) == length(t_points)
@test all(conc[1] ≈ ic for (conc, ic) in zip(concentrations, initial_concs))

# Bonus Challenge
# Helper functions for the pipeline
remove_lloq(data) = filter(x -> x[2] > 0.1, data)
log_transform(data) = [(t, log(c)) for (t, c) in data]

function calc_elimination_rate(data)
    # Take last 3 points
    terminal_data = data[end-2:end]
    times = [x[1] for x in terminal_data]
    log_concs = [x[2] for x in terminal_data]
    
    # Simple linear regression
    t_mean = mean(times)
    c_mean = mean(log_concs)
    slope = sum((times .- t_mean) .* (log_concs .- c_mean)) / 
           sum((times .- t_mean).^2)
    
    return -slope  # Negative slope is the elimination rate
end

# Example data
raw_data = collect(zip(times, concs))

# Pipeline implementation
process_pk_data = remove_lloq ∘ log_transform
k_el = raw_data |> process_pk_data |> calc_elimination_rate

# Test Bonus Challenge
@test k_el > 0
@test typeof(k_el) == Float64 
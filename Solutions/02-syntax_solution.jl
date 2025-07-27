using Test

# Exercise 1: Conditional Statements
conc = 15.5
is_therapeutic = 10 <= conc <= 20

# Classification
function classify_exposure(conc)
    if conc < 10
        return "Low"
    elseif conc <= 20
        return "Therapeutic"
    else
        return "High"
    end
end

exposure_class = classify_exposure(conc)

# Test Exercise 1
@test is_therapeutic == true
@test exposure_class == "Therapeutic"
@test classify_exposure(8.0) == "Low"
@test classify_exposure(25.0) == "High"

# Exercise 2: Loops
time_points = 0:24
C0 = 100.0
k = 0.1

concentrations = Float64[]
for t in time_points
    Ct = C0 * exp(-k * t)
    push!(concentrations, Ct)
end

# Test Exercise 2
@test length(concentrations) == 25  # 0 to 24 hours = 25 points
@test concentrations[1] ≈ 100.0     # At t=0
@test concentrations[end] < C0      # Should decrease over time

# Exercise 3: Array Comprehension
doses = [100 + 50*(i-1) for i in 1:5]
Vd = 48.2
peak_concentrations = [dose/Vd for dose in doses]

# Test Exercise 3
@test length(doses) == 5
@test doses == [100, 150, 200, 250, 300]
@test all(peak_concentrations .== doses./Vd)

# Bonus Challenge
weights = [60, 70, 80, 90]
dose_levels = [1, 2, 3]
dosing_recommendations = Dict()

for weight in weights
    dosing_recommendations[weight] = Dict()
    for level in dose_levels
        dose = weight * level
        dosing_recommendations[weight][level] = dose
        if dose > 200
            @warn "Dose of $(dose)mg exceeds 200mg for $(weight)kg at $(level)mg/kg"
        end
    end
end

# Test Bonus Challenge
@test haskey(dosing_recommendations, 60)
@test dosing_recommendations[60][1] == 60
@test dosing_recommendations[90][3] == 270
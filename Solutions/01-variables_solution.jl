using Test

# Exercise 1: Variable Declaration and Types
dose = 100                    # mg
volume_of_distribution = 48.2 # L
half_life = 12.5              # hours
is_fasted = true              # boolean
patient_id = "SUBJ-001"       # string

# Test Exercise 1
@test typeof(dose) == Int64
@test typeof(volume_of_distribution) == Float64
@test typeof(half_life) == Float64
@test typeof(is_fasted) == Bool
@test typeof(patient_id) == String

# Exercise 2: Basic Calculations
k = log(2)/half_life
C0 = dose/volume_of_distribution

# Test Exercise 2
@test k ≈ 0.0554 atol=0.001
@test C0 ≈ 2.0747 atol=0.001

# Exercise 3: String Manipulation
patient_info = "Patient $patient_id received $dose mg"
patient_ids = ["SUBJ-001", "SUBJ-002", "SUBJ-003"]

# Test Exercise 3
@test patient_info == "Patient SUBJ-001 received 100 mg"
@test length(patient_ids) == 3
@test all(id -> occursin("SUBJ-00", id), patient_ids)

# Bonus Challenge
dose_in_grams = dose/1000.0  # Convert mg to g

# Create dictionary of patient parameters
patient_params = Dict(
    "dose" => dose,
    "volume" => volume_of_distribution,
    "half_life" => half_life
)

# Add clearance to dictionary
patient_params["clearance"] = volume_of_distribution * k

# Test Bonus Challenge
@test dose_in_grams == 0.1
@test haskey(patient_params, "clearance")
@test patient_params["clearance"] ≈ 2.67 atol=0.01

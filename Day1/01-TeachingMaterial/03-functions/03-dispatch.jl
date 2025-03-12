# =============================================================================
# Julia Multiple Dispatch Tutorial
# =============================================================================
#
# Multiple dispatch is one of Julia's most powerful and distinctive features.
# It allows functions to have different implementations based on the types
# of ALL their arguments, not just the first one (unlike traditional OOP).
# This enables both elegant code organization and high performance.

include("02-advanced.jl")

# -----------------------------------------------------------------------------
# 1. TYPE-CONSTRAINED FUNCTIONS (REVIEW)
# -----------------------------------------------------------------------------
# Let's start by reviewing how to constrain argument types

"""
    AUC(times::Vector, observations::Vector)

Calculate the Area Under the Curve (AUC) using the trapezoidal rule for a single
subject's time series data.

# Arguments
- `times::Vector`: Vector of time points
- `observations::Vector`: Vector of corresponding measurements

# Returns
- `Float64`: The calculated area under the curve

# Example
```julia
times = [0, 1, 2, 4]
observations = [0, 1, 0.5, 0.25]
AUC(times, observations)  # Returns area under the curve
```
"""
function AUC(times::Vector, observations::Vector)
    auc = 0
    for i = 1:length(times)-1
        # Trapezoidal rule: area = (base * height)/2
        auc += (observations[i] + observations[i+1]) * (times[i+1] - times[i]) / 2
    end
    return auc
end

# This will fail - arguments must be Vectors
# AUC(1, 10)  

# This works - arguments match the type constraints
AUC(times, observations)

# -----------------------------------------------------------------------------
# 2. THE NEED FOR MULTIPLE IMPLEMENTATIONS
# -----------------------------------------------------------------------------
# Real-world data often comes in different formats
# Here's population data stored in a dictionary

# Sample population data with multiple subjects
population = Dict(
    "SUBJ-1" => [0.01, 112, 224, 220, 143, 109, 57],  # Subject 1's measurements
    "SUBJ-2" => [0.01, 78, 168, 148, 119, 97, 48],    # Subject 2's measurements
    "SUBJ-3" => [0.01, 54, 100, 91, 73, 56, 32]       # Subject 3's measurements
)

# Our original AUC function won't work with dictionary input
# AUC(times, population)  # This would raise a type error

# -----------------------------------------------------------------------------
# 3. APPROACH 1: SEPARATE FUNCTIONS (NOT IDEAL)
# -----------------------------------------------------------------------------
# One solution is to create a separate function for dictionary input

"""
    AUC_pop(times::Vector, population::Dict)

Calculate AUC for multiple subjects stored in a dictionary.

# Arguments
- `times::Vector`: Common time points for all subjects
- `population::Dict`: Dictionary mapping subject IDs to their observations

# Returns
- `Dict`: Dictionary mapping subject IDs to their AUC values
"""
function AUC_pop(times::Vector, population::Dict)
    auc_values = Dict()  # Store results for each subject
    
    for subject in population
        auc = 0
        observations = subject.second  # Get subject's measurements
        
        # Calculate AUC using trapezoidal rule
        for i = 1:length(times)-1
            auc += (observations[i] + observations[i+1]) * (times[i+1] - times[i]) / 2
        end
        
        subject_id = subject.first
        auc_values[subject_id] = auc  # Store result for this subject
    end
    
    return auc_values
end

# This works but requires users to remember two different function names
result_pop = AUC_pop(times, population)

# -----------------------------------------------------------------------------
# 4. APPROACH 2: MULTIPLE DISPATCH (JULIA'S WAY)
# -----------------------------------------------------------------------------
# Better solution: Use the same function name with different type signatures

"""
    AUC(times::Vector, population::Dict)

Calculate AUC for multiple subjects stored in a dictionary.
This method is automatically selected when the second argument is a Dict.

# Arguments
- `times::Vector`: Common time points for all subjects
- `population::Dict`: Dictionary mapping subject IDs to their observations

# Returns
- `Dict`: Dictionary mapping subject IDs to their AUC values

# Note
This is an example of multiple dispatch - the same function name handles
different input types appropriately.
"""
function AUC(times::Vector, population::Dict)
    auc_values = Dict()
    
    for subject in population
        auc = 0
        observations = subject.second
        
        for i = 1:length(times)-1
            auc += (observations[i] + observations[i+1]) * (times[i+1] - times[i]) / 2
        end
        
        subject_id = subject.first
        auc_values[subject_id] = auc
    end
    
    return auc_values
end

# Now we can use the same function name for both cases
dict_result = AUC(times, population)   # Uses Dict method
vector_result = AUC(times, observations)  # Uses Vector method

# The function AUC is now a generic function with two methods
# Julia automatically selects the right method based on argument types
AUC  # Shows it's a generic function

# -----------------------------------------------------------------------------
# 5. EXPLORING MULTIPLE DISPATCH
# -----------------------------------------------------------------------------
# Julia provides tools to inspect method definitions

# List all methods for our function
methods(AUC)    # Shows both Vector and Dict methods we defined

# Example of a built-in function with many methods
methods(string)    # Julia's string function has many methods
                  # This is how Julia achieves its expressiveness

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use multiple dispatch instead of if/else type checking
# 2. Keep methods focused on specific type combinations
# 3. Ensure consistent return types when possible
# 4. Use meaningful type constraints
# 5. Document each method separately
# 6. Use methods() to explore existing implementations

# Try in the REPL:
# - ?AUC to see documentation
# - methods(AUC) to see all methods
# - @which AUC(times, population) to see which method is called
# - methodswith(Vector) to see methods that accept Vector arguments


function add_2_numbers(a, b)
    return a + b
end

add_2_numbers(1, 2.0)

function add_two_numbers(a::Int, b::Int)
    return a + b
end

function add_two_numbers(a::Float64, b::Float64)
    return a + b
end


function add_two_numbers(a::Int64, b::Float64)
    return a + b
end

add_two_numbers(1, 2.0)
# =============================================================================
# Julia Functional Programming Tutorial - Part 1: Applying Functions
# =============================================================================
#
# Functional programming is a programming paradigm that treats computation as the
# evaluation of mathematical functions. Julia provides rich support for functional
# programming concepts while maintaining high performance.

# -----------------------------------------------------------------------------
# 1. BASIC FUNCTION FOR DEMONSTRATION
# -----------------------------------------------------------------------------

"""
    terminal_slope(observations; time=[0, 1, 2, 4, 8, 12, 24])

Calculate the terminal slope of a time series using the last and third-to-last points.

# Arguments
- `observations`: Vector of observations
- `time`: Optional vector of time points (default: standard PK timepoints)

# Returns
- `Float64`: Terminal slope (dy/dx)
"""
function terminal_slope(observations; time = [0, 1, 2, 4, 8, 12, 24])
    dy = observations[end] - observations[end-2]    # Change in y
    dx = time[end] - time[end-2]                   # Change in x
    return dy / dx
end

# -----------------------------------------------------------------------------
# 2. SAMPLE DATA FOR DEMONSTRATION
# -----------------------------------------------------------------------------
# Dictionary containing multiple subjects' time series data
population = Dict(
    "SUBJ-1" => [0.01, 112, 224, 220, 143, 109, 57],    # Subject 1 data
    "SUBJ-2" => [0.01, 78, 168, 148, 119, 97, 48],      # Subject 2 data
    "SUBJ-3" => [0.01, 54, 100, 91, 73, 56, 32],        # Subject 3 data
)

# -----------------------------------------------------------------------------
# 3. ARRAY COMPREHENSION APPROACH
# -----------------------------------------------------------------------------
# Extract observations and apply function to each subject
obs = collect(values(population))    # Convert dictionary values to array
# Calculate slopes using array comprehension
[terminal_slope(observations) for observations in obs]

# -----------------------------------------------------------------------------
# 4. VECTORIZATION APPROACH
# -----------------------------------------------------------------------------
# Julia provides elegant syntax for vectorizing functions

# Direct application (incorrect)
terminal_slope(obs)    # Treats entire array as single input - wrong!

# Broadcast operation with dot syntax
terminal_slope.(obs)    # Applies function to each element - correct!
log.(obs[1])           # Works with any Julia function

# Vectorizing multiple operations
# Method 1: Chain dot operations
abs(terminal_slope.(obs))     # Error: abs needs to be vectorized too
abs.(terminal_slope.(obs))    # Correct: both functions vectorized

# Method 2: Use @. macro for automatic vectorization
@. abs(terminal_slope(obs))   # Same as above but more concise
                             # @. vectorizes every function call in expression

# -----------------------------------------------------------------------------
# 5. MAP FUNCTION APPROACH
# -----------------------------------------------------------------------------
# map applies a function to each element of a collection

# Basic mapping
map(terminal_slope, obs)    # Apply terminal_slope to each element
map(log, obs[1])           # Apply log to each element of first subject's data

# Map with anonymous functions
# Calculate log of all observations for each subject
map(x -> log.(x), obs)    

# Complex transformation with anonymous function and ternary operator
map(i -> abs(terminal_slope(i)) < 5 ? "Less than 5" : "Greater than 5", obs)

# -----------------------------------------------------------------------------
# 6. FOREACH FOR SIDE EFFECTS
# -----------------------------------------------------------------------------
# foreach is like map but for when you don't need the results

# Apply function without collecting results
foreach(terminal_slope, obs)    # Calculate but don't store results
typeof(foreach(terminal_slope, obs))    # Returns Nothing

# Useful for printing or other side effects
foreach(println, keys(population))    # Print all subject IDs

# Custom function with string interpolation
get_id_number(subject_id) = println("$(subject_id) has ID number $(last(subject_id))")
foreach(get_id_number, keys(population))

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use array comprehension for simple transformations
# 2. Use broadcast (.) for vectorizing operations
# 3. Use @. macro when vectorizing multiple operations
# 4. Use map for complex transformations
# 5. Use foreach for side effects (printing, logging, etc.)
# 6. Consider performance implications of each approach

# Try in the REPL:
# - Compare timing of different approaches with @time
# - Experiment with more complex function compositions
# - Try broadcasting with multiple arguments using .+, .*, etc.

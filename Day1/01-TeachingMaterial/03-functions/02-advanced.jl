# =============================================================================
# Julia Functions Tutorial - Advanced Concepts
# =============================================================================
#
# This tutorial covers advanced function concepts in Julia including:
# - Documentation (docstrings)
# - Type annotations
# - Default arguments
# - Keyword arguments
# - Anonymous functions

include("01-syntax.jl")

# -----------------------------------------------------------------------------
# 1. FUNCTION DOCUMENTATION (DOCSTRINGS)
# -----------------------------------------------------------------------------
# Julia supports markdown-formatted documentation for functions

"""
    terminal_slope(times, observations)

Calculate the terminal slope of a time series using the last and third-to-last points.

# Arguments
- `times`: Vector of time points
- `observations`: Vector of corresponding observations

# Returns
- Slope calculated as Δy/Δt between the specified points
"""
function terminal_slope(times, observations)
    dy = observations[end] - observations[end-2]    # Change in y
    dt = times[end] - times[end-2]                 # Change in t
    return dy / dt
end

terminal_slope(times, observations)    # Function works as before
# Try ?terminal_slope in the REPL to see the documentation!

# -----------------------------------------------------------------------------
# 2. TYPE ANNOTATIONS
# -----------------------------------------------------------------------------
# Julia allows specifying types for arguments and return values

"""
    AUC(times::Vector, observations::Vector)

Calculate the Area Under the Curve (AUC) using the trapezoidal rule.

See also: [Trapezoidal rule](https://en.wikipedia.org/wiki/Trapezoidal_rule)

# Arguments
- `times::Vector`: Time points
- `observations::Vector`: Corresponding observations

# Returns
- Numerical approximation of the area under the curve
"""
function AUC(times::Vector, observations::Vector)
    auc = 0
    for i = 1:length(times)-1
        # Trapezoidal rule: area = (base * height)/2
        auc += (observations[i] + observations[i+1]) * (times[i+1] - times[i]) / 2
    end
    return auc
end

AUC(times, observations)    # Works with vectors
# AUC(1, 10)               # Would fail - arguments must be vectors
typeof(AUC(times, observations))    # Returns Float64 by default

# Adding return type annotation
function AUC(times::Vector, observations::Vector)::Float64
    auc = 0
    for i = 1:length(times)-1
        auc += (observations[i] + observations[i+1]) * (times[i+1] - times[i]) / 2
    end
    return auc
end

AUC(times, observations)
typeof(AUC(times, observations))    # Explicitly Float64

# -----------------------------------------------------------------------------
# 3. DEFAULT ARGUMENTS
# -----------------------------------------------------------------------------
# Functions can have default values for arguments

function terminal_slope(observations, times = [0, 1, 2, 4, 8, 12, 24])
    dy = observations[end] - observations[end-2]
    dt = times[end] - times[end-2]
    return dy / dt
end

terminal_slope(observations)                # Uses default times
terminal_slope(observations, times / 24)    # Override default with custom times

# -----------------------------------------------------------------------------
# 4. KEYWORD ARGUMENTS
# -----------------------------------------------------------------------------
# Named arguments that are specified by keyword rather than position

function terminal_slope(times, observations; npoints = 2)
    # npoints determines how far back to go for slope calculation
    dy = observations[end] - observations[end-npoints]
    dt = times[end] - times[end-npoints]
    return dy / dt
end

# terminal_slope(times, observations, 1)      # Error: can't pass keyword arg by position
terminal_slope(times, observations; npoints = 1)    # Correct: use keyword syntax
terminal_slope(times, observations, npoints = 1)    # Also works, but ; is clearer

# -----------------------------------------------------------------------------
# 5. ANONYMOUS FUNCTIONS
# -----------------------------------------------------------------------------
# Functions that don't need a name, useful for short operations

"""
    apply(func, vector)

Apply a function to each element of a vector.

# Arguments
- `func`: Function to apply (can be named or anonymous)
- `vector`: Input vector

# Returns
- New vector with function applied to each element
"""
function apply(func, vector)
    return [func(element) for element in vector]    # Array comprehension
end

# Named function approach
days(hours) = hours / 24
apply(days, times)

minutes(hours) = hours * 60
apply(minutes, times)

# Anonymous function approach (more concise)
apply(i -> i / 24, times)    # Convert to days: i is the input, i/24 is the operation
apply(i -> i * 60, times)    # Convert to minutes

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Always document functions with docstrings
# 2. Use type annotations when types are known
# 3. Consider default values for common arguments
# 4. Use keyword arguments for optional parameters
# 5. Use anonymous functions for simple operations
# 6. Test functions with various inputs

# Try these examples in the REPL!
# Experiment with different combinations of these features

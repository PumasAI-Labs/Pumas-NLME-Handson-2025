# =============================================================================
# Julia Functional Programming Tutorial - Part 2: Reduction Operations
# =============================================================================
#
# Reduction is a fundamental functional programming concept where we combine
# elements of a collection into a single value using a binary operation.
# Julia provides several powerful reduction functions and patterns.

# -----------------------------------------------------------------------------
# 1. BASIC REDUCTION OPERATIONS
# -----------------------------------------------------------------------------

# Create a range of numbers for demonstration
x = 1:10    # Range from 1 to 10

# Basic reduce operations
# reduce(op, collection) applies op successively to elements
reduce(+, x)    # Sum: ((((1 + 2) + 3) + 4) + ...) = 55
reduce(*, x)    # Product: ((((1 * 2) * 3) * 4) * ...) = 3628800

# Built-in reduction functions
# Julia provides optimized functions for common reductions
sum(x)     # Optimized sum function
prod(x)    # Optimized product function

# -----------------------------------------------------------------------------
# 2. CUSTOM REDUCTION: AREA UNDER THE CURVE
# -----------------------------------------------------------------------------

# Sample pharmacokinetic data
times = [0, 1, 2, 4, 8, 12, 24]           # Time points (hours)
obs = [0.01, 112, 224, 220, 143, 109, 57] # Concentrations (ng/mL)

"""
    AUC(accumulated, i)

Calculate incremental area under the curve using the trapezoidal rule.
This function is designed to be used with reduce().

For more information on the trapezoidal rule, see:
https://en.wikipedia.org/wiki/Trapezoidal_rule

# Arguments
- `accumulated`: Sum of areas calculated so far
- `i`: Current index for calculation

# Returns
- Sum of accumulated area plus current trapezoid area

# Note
This function assumes access to global `times` and `obs` arrays
"""
function AUC(accumulated, i)
    # Calculate area of current trapezoid
    trapz_area = (obs[i] + obs[i+1]) * (times[i+1] - times[i]) / 2
    
    # Add to accumulated area
    return accumulated + trapz_area
end

# Calculate total AUC using reduce
# We need to:
# 1. Provide initial value (init = 0)
# 2. Iterate over indices 1 to length-1 (each trapezoid needs two points)
reduce(AUC, 1:length(obs)-1; init = 0)

# -----------------------------------------------------------------------------
# 3. COMBINING MAP AND REDUCE
# -----------------------------------------------------------------------------

using Statistics    # For statistical functions

# Example: Calculate sample variance manually
# Variance is mean of squared deviations from the mean

# Method 1: Separate map and reduce
# 1. Map: Calculate squared deviations from mean
# 2. Reduce: Sum the squared deviations
# 3. Divide by (n-1) for sample variance
reduce(+, map(i -> (i - mean(x))^2, x)) / (length(x) - 1)

# Built-in sum function
sum(map(i -> (i - mean(x))^2, x)) / (length(x) - 1)

# Built-in variance function for comparison
var(x)    # Same result as our manual calculation

# -----------------------------------------------------------------------------
# 4. MAPREDUCE: EFFICIENT COMBINATION
# -----------------------------------------------------------------------------

# mapreduce combines mapping and reduction in a single, more efficient operation
# Syntax: mapreduce(mapping_function, reduction_operation, collection)

# Calculate variance using mapreduce
mapreduce(i -> (i - mean(x))^2, +, x) / (length(x) - 1)

# Bult-in sum function
sum(i -> (i - mean(x))^2, x) / (length(x) - 1)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use built-in reduction functions (sum, prod, etc.) when available
# 2. Provide init value when the reduction might start with empty collection
# 3. Use mapreduce instead of separate map and reduce for better performance
# 4. Consider numerical stability in reduction operations
# 5. reduce assumes associativity of the operation - alternatives: (map)foldl and (map)foldr
# 6. Use broadcasting with reduce for more complex operations

# Try in the REPL:
# - Experiment with different reduction operations (min, max, etc.)
# - Compare performance of reduce vs. mapreduce with @time
# - Try reducing with custom types and operations
# - Explore parallel reductions with threads

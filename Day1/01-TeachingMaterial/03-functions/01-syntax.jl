# =============================================================================
# Julia Functions Tutorial - Basic Syntax
# =============================================================================
#
# Functions are fundamental building blocks in Julia programming.
# They allow you to encapsulate reusable code and create abstractions.
# Julia's functions are first-class objects and can be passed as arguments.

# -----------------------------------------------------------------------------
# 1. BASIC FUNCTION DEFINITION
# -----------------------------------------------------------------------------

# Long-form function definition
function geo_mean(values)    # function keyword, name, and arguments
    prod(values)^(1 / length(values))    # Calculate geometric mean
end    # 'end' keyword is required in long-form syntax

# Testing our function
geo_mean(1:10)              # Works with ranges
geo_mean(rand(10))          # Works with random numbers

# Using external packages for built-in functions
using StatsBase             # Import statistical functions
geomean(1:10)               # Built-in geometric mean from StatsBase

# Using well-tested functinos from packages is often preferable
geo_mean(fill(1e9, 100))
geomean(fill(1e9, 100))

# -----------------------------------------------------------------------------
# 2. FUNCTIONS WITH MULTIPLE ARGUMENTS
# -----------------------------------------------------------------------------

function terminal_slope(times, observations)    # Multiple arguments separated by commas
    # Calculate slope using last two points
    dy = observations[end] - observations[end-2]    # Change in y
    dt = times[end] - times[end-2]                 # Change in t
    
    return dy / dt    # Explicit return statement
end

# Test data for our function
observations = [0.01, 112, 224, 220, 143, 109, 57]    # y values
times = [0, 1, 2, 4, 8, 12, 24]                       # x values

terminal_slope(times, observations)    # Calculate slope

# Functions without arguments
pwd()    # Built-in function that returns present working directory

# -----------------------------------------------------------------------------
# 3. COMPACT FUNCTION SYNTAX
# -----------------------------------------------------------------------------

# Single-line function definition (equivalent to long-form)
geo_mean(values) = prod(values)^(1 / length(values))    # name(args) = expression

# Testing compact form
geo_mean(1:10)
geo_mean(rand(10))

# Multi-line compact form
terminal_slope(times, observations) =
    (observations[end] - observations[end-2]) / (times[end] - times[end-2])

terminal_slope(times, observations)

# -----------------------------------------------------------------------------
# 4. MULTIPLE RETURN VALUES
# -----------------------------------------------------------------------------

using Statistics    # For statistical functions

function summary_statistics(values)
    # Calculate various statistics
    min = minimum(values)
    max = maximum(values)
    q1 = quantile(values, 0.25)    # First quartile
    q2 = quantile(values, 0.50)    # Median
    q3 = quantile(values, 0.75)    # Third quartile
    
    return min, max, q1, q2, q3    # Return multiple values as tuple
end

# Method 1: Store result as tuple
summary = summary_statistics(1:10)    # Returns a tuple of values

# Access tuple elements by indexing
min = summary[1]    # First element
q2 = summary[4]     # Fourth element

# Method 2: Tuple unpacking (more elegant)
min, max, q1, q2, q3 = summary_statistics(1:10)    # Unpack values directly
min    # Access individual values
q2     # Access median

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use clear, descriptive function names
# 2. Keep functions focused on a single task
# 3. Use explicit return statements for clarity
# 4. Consider using named tuples for multiple returns
# 5. Document function behavior with comments
# 6. Use type annotations when performance is critical

# Try these examples in the REPL!
# Type ?function in the REPL for more information about functions

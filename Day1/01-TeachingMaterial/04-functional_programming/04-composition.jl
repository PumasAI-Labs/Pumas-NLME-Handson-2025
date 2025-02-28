# =============================================================================
# Julia Functional Programming Tutorial - Part 4: Function Composition
# =============================================================================
#
# Function composition is a powerful functional programming technique where we
# combine multiple functions to create a new function. Julia provides elegant
# syntax for both function composition and chaining.

# -----------------------------------------------------------------------------
# 1. BASIC FUNCTION COMPOSITION
# -----------------------------------------------------------------------------

# Traditional nested function calls
# Reading from inside out: abs(-2) → sqrt(result) → exp(result)
exp(sqrt(abs(-2)))    # Result: e^√2

# Function composition using ∘ operator (\circ<TAB>)
# Reading from right to left: abs → sqrt → exp
my_operation = (exp ∘ sqrt ∘ abs)    # Creates a new function
my_operation(-2)                     # Same result as above

# Inline composition without intermediate variable
(exp ∘ sqrt ∘ abs)(-2)    # More concise when function is used once

# -----------------------------------------------------------------------------
# 2. COMPLEX COMPOSITION EXAMPLE: GEOMETRIC MEAN
# -----------------------------------------------------------------------------

# Sample data
x = 1:10    # Range from 1 to 10

# Traditional nested approach to calculate geometric mean
# geometric_mean = exp(mean(log(x)))
exp(sum(log.(x)) / length(x))    # Note the broadcast operator (.) for log

# Function composition approach
# Steps:
# 1. Take logarithm of all elements (log.(x))
# 2. Calculate mean (sum/length)
# 3. Take exponential
geometric_mean = (exp ∘                           # Step 3: exp of result
                 (i -> sum(i) / length(i)) ∘      # Step 2: mean
                 (i -> log.(i)))                  # Step 1: log of each element
                 
# Note: Anonymous functions need parentheses in composition

# Verify our result
geometric_mean(x)    # Calculate geometric mean

# Compare with built-in function
using StatsBase
geomean(x)    # Same result as our composed function

# -----------------------------------------------------------------------------
# 3. FUNCTION CHAINING (PIPING)
# -----------------------------------------------------------------------------
# Alternative to composition using |> operator
# Reading left to right (more natural for some)

# Basic example (same as our first composition)
-2 |> abs |> sqrt |> exp    # Each result is passed to next function

# Geometric mean using pipes
# Method 1: Using anonymous functions
x |> (i -> log.(i)) |> (i -> sum(i) / length(i)) |> exp

# Method 2: Using broadcast pipe operator (.|>)
x .|> log |> (i -> sum(i) / length(i)) |> exp    # Vectorize first operation

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use composition (∘) when:
#    - Creating reusable function combinations
#    - Reading right-to-left feels natural
#    - Working with point-free style programming

# 2. Use piping (|>) when:
#    - Reading left-to-right feels natural
#    - Doing one-off operations
#    - Making code more readable

# 3. Remember:
#    - Wrap anonymous functions in parentheses
#    - Use broadcasting (.|>) when needed
#    - Consider readability vs. conciseness

# Try in the REPL:
# - Create more complex function compositions
# - Compare timing of composed vs. nested functions
# - Experiment with different broadcasting patterns
# - Try composing with custom types and methods

# Examples to try:
# numbers = [1, -2, 3, -4, 5]
# numbers .|> abs .|> sqrt |> sum    # Chain with broadcasting
# ["a", "b", "c"] .|> uppercase |> join    # Transform and combine
# 1:10 |> x->filter(iseven, x) |> sum    # Filter and reduce

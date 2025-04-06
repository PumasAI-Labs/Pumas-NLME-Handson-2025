# =============================================================================
# Julia Functional Programming Tutorial - Part 3: Filtering
# =============================================================================
#
# Filtering is a fundamental operation in data processing where we select elements
# from a collection based on a predicate (a function that returns true or false).
# Julia provides powerful and efficient filtering capabilities.

# -----------------------------------------------------------------------------
# 1. BASIC FILTERING
# -----------------------------------------------------------------------------

# Create sample data
x = 1:10    # Range from 1 to 10

# filter(predicate, collection) returns elements where predicate is true
filter(iseven, x)     # Get even numbers: [2, 4, 6, 8, 10]
                      # iseven(n) returns true if n is even

# Multiple ways to get odd numbers
filter(!iseven, x)    # Negate iseven with ! operator: [1, 3, 5, 7, 9]
filter(isodd, x)      # Direct use of isodd: [1, 3, 5, 7, 9]
                      # isodd(n) returns true if n is odd

# -----------------------------------------------------------------------------
# 2. HANDLING MISSING VALUES
# -----------------------------------------------------------------------------

# Sample data with missing values (common in real-world datasets)
obs = [missing, 0.067, 110, 220, 220, missing, 110, 58, missing, 76]

# Filtering missing values requires special handling
# filter(i -> i != missing, obs)    # WRONG: comparison with missing is always missing

# Correct way: use ismissing function
filter(!ismissing, obs)   # Remove all missing values
                          # ismissing(x) returns true if x is missing

# Also correct
skipmissing(obs) # iterator, does not allocate memory
collect(skipmissing(obs)) # now a vector
sum(skipmissing(obs)) # computes the sum without allocating a new Vector

# -----------------------------------------------------------------------------
# 3. COUNTING WITH PREDICATES
# -----------------------------------------------------------------------------

# count(predicate, collection) counts elements where predicate is true
count(iseven, x)       # Count even numbers in 1:10 (returns 5)
count(ismissing, obs)  # Count missing values in obs

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use built-in predicates (iseven, isodd, ismissing) when available
# 2. Remember that missing values need special handling
# 3. Consider using filter with broadcasting for complex conditions
# 4. Use count instead of length(filter()) for better performance
# 5. Chain filters for multiple conditions
# 6. Consider comprehensions for simple filtering cases

# Try in the REPL:
# - Create custom predicates for filtering
# - Combine filter with map or reduce
# - Compare performance of filter vs. comprehensions
# - Experiment with filtering on more complex data structures

# Examples to try:
# filter(x -> x > 0 && iseven(x), -5:5)    # Multiple conditions
# filter(x -> !ismissing(x) && x > 100, obs)    # Filter missing and threshold
# count(x -> x > 5, x)    # Count with custom predicate

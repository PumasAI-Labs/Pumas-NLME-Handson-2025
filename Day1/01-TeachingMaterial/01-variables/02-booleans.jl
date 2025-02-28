# =============================================================================
# Julia Boolean Types Tutorial
# =============================================================================
#
# Boolean values are fundamental to programming logic and control flow.
# In Julia, booleans are represented by the values true and false.
# The Bool type is a primitive type that takes only these two values.

# Import previous numeric examples for demonstration
include("01-numeric.jl")

# -----------------------------------------------------------------------------
# 1. COMPARISON OPERATORS
# -----------------------------------------------------------------------------
# Comparison operators always return a boolean value

# Basic numeric comparisons
1 < 2              # Less than
x < y              # Variables can be compared
y ≤ 6              # Less than or equal to (\leq<TAB> or <=)
y ≥ 6              # Greater than or equal to (\geq<TAB> or >=)

# Equality comparisons
one == one_float   # Equality test (note: == for comparison, = for assignment)
1.00000001 ≈ 1    # Approximately equal (\approx<TAB>)
                  # Useful for floating-point comparisons

# -----------------------------------------------------------------------------
# 2. LOGICAL OPERATORS
# -----------------------------------------------------------------------------
# Julia provides standard logical operators for boolean algebra

# Negation (NOT)
!(1 < 2)          # Negates a boolean expression
!true             # Direct negation of a boolean value

# Logical OR (||)
(1 < 2) || (2 < 1)    # Returns true if EITHER expression is true
                      # Short-circuits: stops at first true value

# Logical AND (&&)
(1 < 2) && (2 < 1)    # Returns true if BOTH expressions are true
                      # Short-circuits: stops at first false value

# -----------------------------------------------------------------------------
# 3. BOOLEAN ARITHMETIC
# -----------------------------------------------------------------------------
# Booleans can be used in arithmetic operations
# In this context: true = 1, false = 0

true + true       # Evaluates to 2
one + true        # Mixing numbers and booleans
(x > 6) * x       # Conditional multiplication: 0 or x

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use short-circuit evaluation for efficiency
# 2. Be careful with floating-point equality (use ≈ when appropriate)
# 3. Boolean arithmetic can be useful for vectorized operations
# 4. Use parentheses to make complex boolean expressions clear

# Try experimenting with these concepts in the REPL!
# Type ?Bool in the REPL for more information about boolean types

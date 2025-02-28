# =============================================================================
# Julia Syntax Tutorial - Part 3: Assignments and Scoping
# =============================================================================
#
# This tutorial covers how to assign values to variables in Julia, including
# compound expressions, variable scoping rules, constants, and naming conventions.
# Understanding these concepts is crucial for writing clean and maintainable code.

# -----------------------------------------------------------------------------
# 1. COMPOUND EXPRESSIONS
# -----------------------------------------------------------------------------
# Compound expressions allow multiple operations to be combined into a single
# expression, with the last value being returned.

# Method 1: begin...end block (Multiple lines)
# This is the most readable approach for complex assignments
x = begin
    a = 3              # First operation
    b = 2              # Second operation
    a + b              # Last value is returned
end

println("Result of multi-line begin block: $x")

# Method 2: begin...end block (Single line)
# More concise but less readable
x = begin a = 3; b = 2; a + b end    # Semicolons separate expressions

# Method 3: Parentheses with semicolons
# Most concise, but use sparingly for readability
x = (a = 3; b = 2; a + b)

# -----------------------------------------------------------------------------
# 2. VARIABLE SCOPING
# -----------------------------------------------------------------------------
# Julia has well-defined scoping rules that determine where variables are accessible

# Global Scope
# Variables defined in the global scope are accessible everywhere
c = 2    # Global variable

# Using global variables in loops
println("\nAccessing global variable in loops:")
for i = 1:5
    println("Printing $c for the $(i)th time")    # Global c is accessible
end

# Modifying global variables
println("\nModifying global variables:")
j = 1    # Global variable
while j <= 5
    # 'global' keyword required to modify global variables in local scope
    global j += 1    # Equivalent to: global j = j + 1
    println("j is now $j")
end

# Local Scope
# Variables defined in a local scope are only accessible within that scope
println("\nDemonstrating local scope:")
for i = 1:3
    local d = 3    # Local variable, only exists inside this loop
    println("$c + $d = $(c + d)")    # Can access both global c and local d
end

# This would cause an error - d doesn't exist outside the loop
# println(d)    # Uncommenting this line would raise an UndefVarError

# -----------------------------------------------------------------------------
# 3. CONSTANTS
# -----------------------------------------------------------------------------
# Constants are variables whose values should not change
# They help prevent accidental modifications and can improve performance

const MY_PI = 3.14    # Convention: constants are usually UPPERCASE
# MY_PI = 3          # This would error - can't change type of constant
# MY_PI = 3.1416     # This would warn - changing value of constant

# -----------------------------------------------------------------------------
# 4. NAMING CONVENTIONS
# -----------------------------------------------------------------------------
# Julia has strong conventions for naming variables, types, and modules

# Variables: lowercase with underscores
good_variable_name = "follows convention"
badVariableName = "doesn't follow convention"    # Avoid camelCase for variables

# Long names: use underscores for clarity
my_long_variable_name = 1    # Good
myLongVariableName = 1      # Not idiomatic Julia

# Types and Modules: start with capital letter, use CamelCase
# Examples of built-in types:
#   Int64       # 64-bit integer type
#   String      # String type
#   DataFrame   # Data frame type (from DataFrames.jl)

# Functions: lowercase with underscores
#   push!       # Built-in function to add elements to collections
#   read_csv    # Common naming pattern for file operations

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Scoping:
#    - Minimize use of global variables
#    - Use local variables when possible
#    - Always use 'global' keyword when modifying global variables
#
# 2. Constants:
#    - Use for values that shouldn't change
#    - Define at the module level
#    - Use UPPERCASE names
#
# 3. Naming:
#    - Be consistent with Julia conventions
#    - Use descriptive names
#    - Avoid single-letter names except for simple loops
#
# 4. Compound Expressions:
#    - Use multi-line begin blocks for complex logic
#    - Use semicolon syntax for simple, related operations
#    - Prioritize readability over conciseness

# Try in the REPL:
# - Experiment with different scoping rules
# - Try modifying constants
# - Practice using compound expressions
# - Test variable naming conventions

# Examples to try:
# # Scope experiment
# x = 1
# let
#     local x = 2
#     println("Inside let: $x")    # Prints 2
# end
# println("Outside let: $x")       # Prints 1
#
# # Compound expression with function
# result = begin
#     function double(x)
#         2x
#     end
#     double(21)
# end

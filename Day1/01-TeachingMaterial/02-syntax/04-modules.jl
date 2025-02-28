# =============================================================================
# Julia Syntax Tutorial - Part 4: Modules and Package Management
# =============================================================================
#
# Modules are a fundamental way to organize and reuse code in Julia. They allow
# you to namespace your code and use functionality from other packages without
# naming conflicts. This tutorial covers how to use modules effectively.

# -----------------------------------------------------------------------------
# 1. IMPORTING MODULES
# -----------------------------------------------------------------------------
# There are several ways to import and use modules in Julia

# Method 1: using keyword
# This brings all exported names into the current namespace
using Statistics    # Built-in module for statistical functions
mean([10, 13, 10]) # We can directly use 'mean' function

# Multiple modules can be imported in a single line
using Pumas, Statistics    # Separate module names with commas

# Method 2: Selective importing
# Import only specific functions (recommended for clarity)
using Statistics: mean, std    # Only import mean and std functions
# mean([1, 2, 3])            # Works
# var([1, 2, 3])            # Would error - var wasn't imported

# Method 3: import keyword
# More explicit, requires module name prefix
import LinearAlgebra    # Import the module

# This won't work - import requires module prefix
# norm([1, 1])    # Would raise UndefVarError

# This works - explicitly showing where norm comes from
LinearAlgebra.norm([1, 1])    # Using module prefix

# Later, if you want direct access, you can use 'using'
using LinearAlgebra
norm([1, 1])    # Now it works without prefix!

# -----------------------------------------------------------------------------
# 2. MODULE NAMESPACING
# -----------------------------------------------------------------------------
# Modules help avoid naming conflicts between different packages

# Example of potential naming conflict
using Statistics    # has mean()
# using MyStats    # hypothetical module that also has mean()

# Resolution options:
# 1. Use module prefix
Statistics.mean([1, 2, 3])    # Explicitly use Statistics version
# MyStats.mean([1, 2, 3])    # Explicitly use MyStats version

# 2. Selective import
using Statistics: mean as stats_mean    # Rename on import
# using MyStats: mean as my_mean       # Different name for MyStats version

# -----------------------------------------------------------------------------
# 3. STANDARD LIBRARY MODULES
# -----------------------------------------------------------------------------
# Julia comes with several built-in modules:
#   - Base: Always available, no need to import
#   - Core: Fundamental types and functions
#   - Statistics: Basic statistical functions
#   - LinearAlgebra: Matrix operations
#   - Dates: Date and time functionality
#   - Random: Random number generation
#   - Printf: Formatted printing
#   - Test: Unit testing functionality

# -----------------------------------------------------------------------------
# 4. CREATING CUSTOM MODULES
# -----------------------------------------------------------------------------
# Basic module structure:
#
# module MyModule
#     export my_function    # Make function available to users
#     
#     function my_function()
#         @info "Hello from MyModule!"    # Changed from println
#     end
# end

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Importing:
#    - Use 'using' when you want direct access to names
#    - Use 'import' when you want to be explicit about source
#    - Prefer selective imports for clarity
#
# 2. Naming:
#    - Module names use CamelCase
#    - Avoid naming conflicts with selective imports
#    - Use module prefix when in doubt
#
# 3. Organization:
#    - Keep related functionality in modules
#    - Export only the public interface
#    - Use submodules for complex packages
#
# 4. Performance:
#    - Avoid using too many modules in local scope
#    - Import only what you need
#    - Consider precompilation for large modules

# Try in the REPL:
# - Import different combinations of modules
# - Experiment with naming conflicts
# - Create a simple custom module
# - Try different import styles

# Examples to try:
# # Custom module
# module MyMath
#     export double, triple
#     
#     double(x) = 2x
#     triple(x) = 3x
# end
#
# # Different import styles
# using MyMath: double
# import MyMath: triple
# MyMath.triple(3)    # Using module prefix
# double(3)           # Direct use

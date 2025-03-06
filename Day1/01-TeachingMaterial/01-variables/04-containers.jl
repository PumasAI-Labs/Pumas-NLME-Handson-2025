# =============================================================================
# Julia Containers Tutorial
# =============================================================================
#
# Julia provides several container types for organizing and storing data.
# The main container types are Arrays (Vectors and Matrices), Tuples, and Dictionaries.

include("03-strings.jl")

# -----------------------------------------------------------------------------
# 1. VECTORS (1-DIMENSIONAL ARRAYS)
# -----------------------------------------------------------------------------
# Vectors are ordered collections of elements

# Creating vectors with different types
numeric = [1, 2, 3, 6.5]           # Vector of numbers (promotes to Float64)
string_vector = ["A", "B", "C", "D"]  # Vector of strings
mixed = [1, "one", 2, "two"]       # Vector of Any type (avoid if possible for performance)

# -----------------------------------------------------------------------------
# 2. MATRICES (2-DIMENSIONAL ARRAYS)
# -----------------------------------------------------------------------------
# Julia has native support for matrices with efficient implementations

# Multi-line syntax (using spaces for columns, line breaks for rows)
A = [
    1 2 3                          # Spaces separate columns
    4 5 6                          # Line breaks separate rows
    7 8 9
    ]

# Single line syntax (using semicolons)
A2 = [1 2 3; 4 5 6; 7 8 9]        # Semicolons separate rows
A == A2                           # Both methods create identical matrices

# Creating matrix from vector
# Note: Julia is column-major (stores columns contiguously)
reshape([1, 2, 3, 4, 5, 6, 7, 8, 9], (3, 3))  # Different from A due to column-major order

# -----------------------------------------------------------------------------
# 3. TUPLES
# -----------------------------------------------------------------------------
# Tuples and NamedTuples are fixed-length containers that can hold any values
# of different types
# They cannot be modified (i.e., they are immutable)

# Tuple
a_tuple = (1,79,176,"Female",true)

# NamedTuple
a_named_tuple = (id = 1,wt = 79, ht = 176, sex = "Female", ispatient = true)

# -----------------------------------------------------------------------------
# 4. INDEXING AND SLICING
# -----------------------------------------------------------------------------
# Julia uses 1-based indexing (first element is at index 1)

# Vector indexing
numeric[1]                         # First element (Julia starts at 1)
string_vector[begin]               # Also first element using keyword

# Matrix indexing
A[1, 2]                           # Element at row 1, column 2
A[begin, 3]                       # First row, third column

# Slicing operations
numeric[1:3]                      # Get first three elements
A[1:2, 2:3]                       # Get submatrix (rows 1-2, columns 2-3)

# Using begin and end keywords
numeric[begin+1:end-1]            # All elements except first and last
A[begin:end, begin:2]             # All rows, first two columns

# Index NamedTuple by name with Symbol
a_named_tuple[:wt]                # Access the wt value

# -----------------------------------------------------------------------------
# 5. DICTIONARIES
# -----------------------------------------------------------------------------
# Dictionaries are collections of key-value pairs

# Method 1: Creating with Tuples
height = Dict([("Alice", 165),     # Each tuple is (key, value)
              ("Bob", 178),
              ("Charlie", 172)])

# Method 2: Creating with Pair syntax (preferred)
height = Dict("Alice" => 165,      # => operator creates pairs
             "Bob" => 178,
             "Charlie" => 172)

# Accessing dictionary values
height["Bob"]                      # Get value by key
height["Alice"]                    # Returns 165

# Modifying dictionary
height["Bob"] = 175                # Modify existing value
height["Peter"] = 173              # Add new key-value pair
height                             # View updated dictionary

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use type-homogeneous arrays for better performance
# 2. Prefer column-major operations for matrices
# 3. Use begin and end for more readable indexing
# 4. Use the Symbol (:value) syntax for NamedTuples
# 5. Use the pairs (=>) syntax for dictionaries (more readable)
# 6. Consider using get() for safe dictionary access

# Try these examples in the REPL!
# Type ?Array, ?Tuple, or ?Dict in the REPL for more information

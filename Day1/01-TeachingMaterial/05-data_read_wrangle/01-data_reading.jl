# =============================================================================
# Data Wrangling and Visualization - Part 1: Reading Data
# =============================================================================

# Understanding your data is the first crucial step in PK/PD modeling.
# This script demonstrates:
# 1. Reading structured clinical trial data
# 2. Initial data exploration and validation
# 3. Understanding data structure and quality
# 4. Identifying potential data issues

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR READING DATA
# -----------------------------------------------------------------------------
using CSV, DataFrames, Logging

# -----------------------------------------------------------------------------
# 2. READING DATA
# -----------------------------------------------------------------------------

# The warfarin dataset contains:
# - Time measurements
# - Drug concentrations
# - Prothrombin Complex Activity (PCA) measurements
# - Patient characteristics (weight, sex)
# - Dosing information

@info "Reading warfarin data from CSV file..."
@info "Note: Using missingstring='.' to handle NONMEM-style missing values"

df = CSV.read(
    joinpath(@__DIR__, "..", "..", "..", "data", "warfarin.csv"),
    DataFrame;
    missingstring=["."]
)

# -----------------------------------------------------------------------------
# 3. INITIAL DATA EXPLORATION
# -----------------------------------------------------------------------------
@info "Basic Dataset Information:" nrow(df) ncol(df)

@info "First 5 rows of data for initial inspection:"
first(df, 5)

# Basic data summary
@info "Calculating summary statistics..."
summary_stats = describe(df)
@info "Summary statistics computed" details="Review the display below:"
display(summary_stats)

# Checking for missing values
@info "Analyzing missing values..."
missing_counts = Dict(
    col => sum(ismissing.(df[:, col])) 
    for col in names(df) 
    if sum(ismissing.(df[:, col])) > 0
)
@info "Missing value counts:" counts=missing_counts

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Always check data structure and types after reading
# 2. Understand how missing values are represented
# 3. Look for potential data quality issues
# 4. Verify that the data matches the expected format
# 5. Document any assumptions or special handling

# Next Steps:
# 1. Data visualization (02-data_visualization.jl)
# 2. Data wrangling (03-data_wrangling.jl)"
# 3. Creating a Pumas population object

# Script: 01-data_reading.jl
# Purpose: Read and explore warfarin PK/PD data from CSV file
# ========================================================

using CSV, DataFrames, Logging

# Introduction to Data Reading and Exploration
# ---------------------------------------
# Understanding your data is the first crucial step in PK/PD modeling.
# This script demonstrates:
# 1. Reading structured clinical trial data
# 2. Initial data exploration and validation
# 3. Understanding data structure and quality
# 4. Identifying potential data issues
#
# The warfarin dataset contains:
# - Time measurements
# - Drug concentrations
# - Prothrombin Complex Activity (PCA) measurements
# - Patient characteristics (weight, sex)
# - Dosing information

@info "Starting Data Reading and Exploration Process"
@info "=========================================="

# Step 1: Read the CSV file
# ------------------------
@info "Reading warfarin data from CSV file..."
@info "Note: Using missingstring='.' to handle NONMEM-style missing values"

df = CSV.read(joinpath(@__DIR__, "..", "..", "..", "data", "warfarin.csv"), DataFrame; missingstring=["."])

# Step 2: Initial Data Exploration
# ------------------------------
@info "Basic Dataset Information:" metrics=(
    rows = nrow(df),
    columns = ncol(df)
)

@info "First 5 rows of data for initial inspection:"
display(first(df, 5))

# Step 3: Understanding Column Names and Types
# -----------------------------------------
@info "Dataset Structure Analysis"
@info "Column names in the dataset:" columns=names(df)

col_types = Dict(name => eltype(col) for (name, col) in zip(names(df), eachcol(df)))
@info "Column types:" col_types

# Step 4: Basic Data Summary
# ------------------------
@info "Calculating summary statistics..."
summary_stats = describe(df)
@info "Summary statistics computed" details="Review the display below:"
display(summary_stats)

# Step 5: Check for Missing Values
# ------------------------------
@info "Analyzing missing values..."
missing_counts = Dict(
    col => sum(ismissing.(df[:, col])) 
    for col in names(df) 
    if sum(ismissing.(df[:, col])) > 0
)
@info "Missing value counts:" counts=missing_counts

# Educational Note:
# ---------------
@info "Key Takeaways from Data Reading:"
@info "1. Always check data structure and types after reading"
@info "2. Understand how missing values are represented"
@info "3. Look for potential data quality issues"
@info "4. Verify that the data matches the expected format"
@info "5. Document any assumptions or special handling"

# Next Steps:
# ----------
@info "Next Steps:"
@info "1. Data wrangling (02-data_wrangling.jl)"
@info "2. Creating a Pumas population object"
@info "3. Initial data visualizations"

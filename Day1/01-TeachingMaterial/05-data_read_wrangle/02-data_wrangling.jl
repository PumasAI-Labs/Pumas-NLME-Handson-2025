# Script: 02-data_wrangling.jl
# Purpose: Process and prepare warfarin data for PK/PD modeling
# ===========================================================

using DataFrames, DataFramesMeta
include("01-data_reading.jl")  # This gives us the 'df' DataFrame

@info "Starting data wrangling process..."

# Step 1: Create a Working Copy
# ---------------------------
# Always work with a copy to preserve original data
df_processed = copy(df)
@info "Created working copy of data"

# Step 2: Fix Duplicate Time Points
# -------------------------------
# Some subjects have duplicate time points for DVID = 1
# We add a tiny increment to make these times unique
# This is necessary because Pumas requires unique time points
@info "Adjusting duplicate time points..."
@. df_processed[[133, 135, 137, 139], :TIME] += 1e-6
@info "Time points adjusted for rows: 133, 135, 137, 139"

# Step 3: Add Derived Columns
# -------------------------
@info "Creating derived columns..."

# Use @rtransform! macro for row-wise transformations
# This is more efficient than applying operations to individual columns
@rtransform! df_processed begin
    # Size-based scaling factors for PK parameters
    :FSZV = :WEIGHT / 70  # Volume scaling (linear with body weight)
    :FSZCL = (:WEIGHT / 70)^0.75  # Clearance scaling (allometric)
    
    # Create observation type identifier
    :DVNAME = "DV$(:DVID)"  # DV1 = concentration, DV2 = PCA
    
    # Set up dosing indicators
    :CMT = ismissing(:AMOUNT) ? missing : 1  # Compartment number
    :EVID = ismissing(:AMOUNT) ? 0 : 1       # Event type (0=obs, 1=dose)
end

@info "Created columns:" "FSZV: Volume scaling factor" "FSZCL: Clearance scaling factor" "DVNAME: Observation type" "CMT: Compartment number" "EVID: Event identifier"

# Step 4: Remove Problematic Data
# ----------------------------
# Remove subjects with '#' in their ID (typically test or invalid data)
@info "Removing problematic subject IDs..."
n_before = nrow(df_processed)
@rsubset! df_processed begin
    :ID != "#"
end
n_removed = n_before - nrow(df_processed)
@info "Removed rows with invalid subject IDs" n_removed

# Step 5: Reshape Data from Long to Wide Format
# -----------------------------------------
# Convert from long format (multiple rows per time point)
# to wide format (one row per time point)
@info "Reshaping data from long to wide format..."
df_wide = unstack(
    df_processed,
    Not([:DVID, :DVNAME, :DV]),  # Columns to keep as is
    :DVNAME,                      # Column containing observation types
    :DV                          # Values to spread into new columns
)

# Step 6: Rename Columns for Clarity
# -------------------------------
@info "Renaming columns to meaningful names..."
rename!(df_wide, :DV1 => :conc, :DV2 => :pca)
@info "Columns renamed" DV1="conc (concentration)" DV2="pca (Prothrombin Complex Activity)"

# Display final data structure
@info "Final data structure:" rows=nrow(df_wide) columns=ncol(df_wide) column_names=names(df_wide)

# Note: This processed DataFrame (df_wide) will be used in the next script
# to create a Pumas Population object 
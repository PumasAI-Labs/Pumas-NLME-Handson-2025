# Script: 02-data_wrangling.jl
# Purpose: Process and prepare warfarin data for PK/PD modeling
# ===========================================================

using DataFrames, DataFramesMeta
include("01-data_reading.jl")  # This gives us the 'df' DataFrame

@info "Starting data wrangling process..."

# Step 1: Create a Working Copy
# ---------------------------
# In Julia, it is to mutate DataFrames in-place. Hence, it is often useful
# to work with a copy of the original data
df_processed = copy(df)
@info "Created working copy of data"

# Step 2: Fix Duplicate Time Points
# -------------------------------
# Some subjects have duplicate time points for DVID = 1
# For this dataset, the triple (ID, TIME, DVID) should define
# a row uniquely, but
nrow(df)
nrow(unique(df, ["ID", "TIME", "DVID"]))

# We can identify the problematic rows by grouping on the index variables
@chain df begin
    @groupby :ID :TIME :DVID
    @transform :tmp = length(:ID)
    @rsubset :tmp > 1
end

# It is important to understand the reason for the duplicate values.
# Sometimes the duplication is caused by recording errors, sometimes
# it is a data processing error, e.g. when joining tables, or it can
# be genuine records, e.g. when samples have been analyzed in multiple
# labs. The next step depends on which of the causes are behind the
# duplications.
#
# In this case, we will assume that both values are informative and
# we will therefore just adjust the time stamp a bit for the second
# observation.
df_processed = @chain df begin
    @groupby :ID :TIME :DVID
    @transform :tmp = 1:length(:ID)
    @rtransform :TIME = :tmp == 1 ? :TIME : :TIME + 1e-6
    @select Not(:tmp)
end

# We can now confirm that all rows are unique defined by the index triple
nrow(df) == nrow(unique(df_processed, ["ID", "TIME", "DVID"]))

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
    !contains(:ID, "#")
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
    :DVNAME,                     # Column containing observation types
    :DV                          # Values to spread into new columns
)

# Step 6: Rename Columns for Clarity
# -------------------------------
@info "Renaming columns to meaningful names..."
rename!(df_wide, :DV1 => :conc, :DV2 => :pca)
@info "Columns renamed" DV1="conc (concentration)" DV2="pca (Prothrombin Complex Activity)"

# Display final data structure
@info "Final data structure:" nrow(df_wide) ncol(df_wide) names(df_wide)

# Note: This processed DataFrame (df_wide) will be used in the next script
# to create a Pumas Population object 
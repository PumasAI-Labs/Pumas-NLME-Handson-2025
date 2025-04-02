# =============================================================================
# Population PK Modeling in Pumas - Part 1: Converting to Pumas Population Object
# =============================================================================

# A Pumas Population object requires specific data elements:
# - Subject identifiers (id)
# - Time points (time)
# - Dosing information (amt, cmt, evid)
# - Covariates (subject characteristics)
# - Observations (measured responses)

@info"""
Required data elements for Pumas Population:
1. Subject IDs: Using :ID column
2. Time points: Using :TIME column
3. Dosing: Using :AMOUNT, :CMT, :EVID columns
4. Covariates: Using :SEX, :WEIGHT, :FSZV, :FSZCL
5. Observations: Using :conc
"""

# Import the previous data wrangling example for demonstration
# This gives us the df_wide DataFrame
include(joinpath("..","05-data_read_wrangle","03-data_wrangling.jl"))

# Display the dataset:
vscodedisplay(df_wide)

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR CREATING PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
using Pumas

# -----------------------------------------------------------------------------
# 2. CONVERTING A DATAFRAME TO A PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
pop_pk = read_pumas(
    df_wide;
    # Subject identification
    id = :ID,           # Column containing subject IDs
    
    # Time information
    time = :TIME,       # Column containing time points
    
    # Dosing information
    amt = :AMOUNT,      # Dosing amounts
    cmt = :CMT,         # Compartment numbers
    evid = :EVID,       # Event type identifiers
    
    # Subject characteristics (covariates)
    covariates = [
        :SEX,           # Gender (0 = female, 1 = male)
        :WEIGHT,        # Body weight in kg
        :FSZV,          # Volume scaling factor
        :FSZCL,         # Clearance scaling factor
    ],
    
    # Measured responses (observations)
    observations = [
        :conc,          # Drug concentration
    ],
)

# -----------------------------------------------------------------------------
# 3. EXAMINING A PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
# Determine number of subjects in populations
length(pop_pk)

# View the population object as a DataFrame
df_pop_pk = DataFrame(pop_pk)
vscodedisplay(df_pop_pk)

# -----------------------------------------------------------------------------
# 4. EXAMINING A INDIVIDUAL DATA FROM PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
# Examine data for the first individual
pop_pk[1]

# -----------------------------------------------------------------------------
# 5. DATA VERIFICATION
# -----------------------------------------------------------------------------
# Number of individuals in the original dataset
original_subjects = length(unique(df_wide.ID))

# Number of individuals in the Pumas population object
pumas_subjects = length(pop_pk)

# Note: This Population object (pop_pk) will be used in subsequent scripts
# for model fitting and simulation 
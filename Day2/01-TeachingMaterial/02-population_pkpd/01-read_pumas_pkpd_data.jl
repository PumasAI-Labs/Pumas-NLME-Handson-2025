# =============================================================================
# Population PK-PD Modeling in Pumas - Part 1: Converting to Pumas Population Object
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
5. Observations: Using :conc, :pca
"""

# Import the previous data wrangling example for demonstration
# This gives us the df_wide DataFrame
include(joinpath("..", "..", "..", "Day1", "01-TeachingMaterial",
    "05-data_read_wrangle", "03-data_wrangling.jl"))

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR CREATING PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
using Pumas

# -----------------------------------------------------------------------------
# 2. CONVERTING A DATAFRAME TO A PUMAS POPULATION OBJECT
# -----------------------------------------------------------------------------
pop_pkpd = read_pumas(
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
        :pca,           # Prothrombin Complex Activity
    ],
)

# Note: This Population object (pop_pkpd) will be used in subsequent scripts
# for model fitting and simulation 
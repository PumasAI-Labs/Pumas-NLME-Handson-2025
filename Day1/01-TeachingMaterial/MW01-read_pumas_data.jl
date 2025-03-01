# Script: MW01-read_pumas_data.jl
# Purpose: Convert processed DataFrame into a Pumas Population object
# ================================================================

using Pumas
include("05-data_read_wrangle/02-data_wrangling.jl")  # This gives us the 'df_wide' DataFrame

@info "Creating Pumas Population from processed data..."

# Step 1: Understanding Pumas Population Requirements
# -----------------------------------------------
# A Pumas Population object requires specific data elements:
# - Subject identifiers (id)
# - Time points (time)
# - Dosing information (amt, cmt, evid)
# - Covariates (subject characteristics)
# - Observations (measured responses)

@info "Required data elements for Pumas Population:" elements=[
    "1. Subject IDs: Using :ID column",
    "2. Time points: Using :TIME column",
    "3. Dosing: Using :AMOUNT, :CMT, :EVID columns",
    "4. Covariates: Using :SEX, :WEIGHT, :FSZV, :FSZCL",
    "5. Observations: Using :conc, :pca"
]

# Step 2: Create the Pumas Population
# --------------------------------
@info "Creating Pumas Population object..."
pop = read_pumas(
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
        :SEX,           # Gender (0=female, 1=male)
        :WEIGHT,        # Body weight in kg
        :FSZV,          # Volume scaling factor
        :FSZCL,         # Clearance scaling factor
    ],
    
    # Measured responses (observations)
    observations = [
        :conc,          # Drug concentration
        :pca,           # Prothrombin complex activity
    ],
)

# Step 3: Examine the Population Object
# ----------------------------------
@info "Pumas Population Summary:" n_subjects=length(pop)

@info "View the population object as a DataFrame"
df_pop = DataFrame(pop)
vscodedisplay(df_pop)

# Step 4: Examine Individual Subject Data
# ------------------------------------
@info "Example: Data for first subject"
@info "First subject details" subject_data=pop[1]

# Step 5: Basic Data Verification
# ----------------------------
@info "Verifying data consistency:" original_subjects=length(unique(df_wide.ID)) pumas_subjects=length(pop)

# Note: This Population object (pop) will be used in subsequent scripts
# for model fitting and simulation 


# The next modeling exercise will begin with the popPK model only -> Create a population based on concentrations only
# ----------------------------
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
        :SEX,           # Gender (0=female, 1=male)
        :WEIGHT,        # Body weight in kg
        :FSZV,          # Volume scaling factor
        :FSZCL,         # Clearance scaling factor
    ],
    
    # Measured responses (observations)
    observations = [
        :conc          # Drug concentration
    ],
)
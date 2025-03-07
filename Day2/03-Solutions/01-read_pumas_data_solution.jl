using Pumas, PharmaDatasets, DataFrames, Logging, Statistics

# Exercise 1: Creating Pumas Population from PO SAD Data
po_sad = dataset("po_sad_1")

# Create Pumas Population
pop_po = read_pumas(
    po_sad;
    id = :ID,
    time = :TIME,
    amt = :AMT,
    covariates = [:WT, :SEX],
    observations = [:DV],
    cmt = 1,
    evid = :EVID
)

# Examine population
@info "PO SAD Population Summary:"
@info "Number of subjects: $(length(pop_po))"
@info "First subject data:"
display(DataFrame(pop_po[1]))

# Exercise 2: Creating Pumas Population from IV Data
iv_sd = dataset("iv_sd_1")

# Add normalized parameters and weight category
iv_processed = transform(iv_sd,
    [:CL, :WT] => ByRow((cl, wt) -> cl/wt) => :CLnorm,
    [:V, :WT] => ByRow((v, wt) -> v/wt) => :Vnorm,
    :WT => ByRow(wt -> wt > median(iv_sd.WT) ? 1 : 0) => :WT_CAT
)

# Create Pumas Population
pop_iv = read_pumas(
    iv_processed;
    id = :ID,
    time = :TIME,
    amt = :AMT,
    covariates = [:WT, :WT_CAT, :CLnorm, :Vnorm],
    observations = [:DV],
    cmt = 1,
    evid = :EVID
)

# Verify population
@info "IV SD Population Summary:"
@info "Covariates included: $(names(DataFrame(pop_iv)))"
@info "Sample subject data:"
display(DataFrame(pop_iv[1]))

# Exercise 3: Creating Pumas Population from Categorical Data
nausea_data = dataset("nausea")

# Process categorical data
nausea_processed = transform(nausea_data,
    :TRT => ByRow(x -> x == "active" ? 1 : 0) => :TRT_BIN
)

# Create Pumas Population
pop_nausea = read_pumas(
    nausea_processed;
    id = :ID,
    time = :TIME,
    observations = [:NAUSEA],
    covariates = [:TRT_BIN, :AGE],
    event_data = false
)

# Verify population
@info "Nausea Population Summary:"
@info "Number of subjects: $(length(pop_nausea))"
@info "Observations per subject: $(mean(length.(pop_nausea)))"

# Bonus Challenge: Advanced Population Creation
function create_pumas_population(df::DataFrame)
    # Determine dataset type and required columns
    is_pk = all(col -> col ∈ names(df), [:TIME, :DV, :AMT])
    
    # Basic required columns
    required_cols = Dict(
        :id => :ID,
        :time => :TIME
    )
    
    # Dataset-specific settings
    if is_pk
        # PK data settings
        required_cols[:amt] = :AMT
        required_cols[:observations] = [:DV]
        required_cols[:cmt] = 1
        required_cols[:evid] = :EVID
        
        # Identify potential covariates
        covariate_cols = filter(x -> x ∉ values(required_cols), 
                              names(df))
    else
        # Non-PK data settings
        required_cols[:observations] = [:NAUSEA]
        required_cols[:event_data] = false
        
        # Process categorical covariates
        for col in names(df)
            if eltype(df[!, col]) <: Union{String, CategoricalValue}
                df[!, "$(col)_BIN"] = df[!, col] .== unique(df[!, col])[1]
            end
        end
        
        covariate_cols = filter(x -> x ∉ values(required_cols) && 
                                   endswith(x, "_BIN"),
                              names(df))
    end
    
    # Create population
    pop = read_pumas(
        df;
        id = required_cols[:id],
        time = required_cols[:time],
        amt = get(required_cols, :amt, nothing),
        observations = required_cols[:observations],
        covariates = covariate_cols,
        cmt = get(required_cols, :cmt, nothing),
        evid = get(required_cols, :evid, nothing),
        event_data = get(required_cols, :event_data, true)
    )
    
    # Generate report
    report = Dict(
        "n_subjects" => length(pop),
        "n_observations" => sum(length.(pop)),
        "covariates" => covariate_cols,
        "observations" => required_cols[:observations],
        "is_pk_data" => is_pk
    )
    
    return pop, report
end

# Test the function
for (name, data) in [("PO SAD", po_sad), 
                     ("IV SD", iv_sd), 
                     ("Nausea", nausea_data)]
    pop, report = create_pumas_population(data)
    @info "Population Report for $name:" report
end 
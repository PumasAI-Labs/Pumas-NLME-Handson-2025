using DataFrames, DataFramesMeta, PharmaDatasets, Logging

# Exercise 1: Data Wrangling for PO SAD Data
po_sad = dataset("po_sad_1")
po_processed = copy(po_sad)

# Add derived columns
@rtransform! po_processed begin
    # Weight-normalized dose
    :dose_nrm = ismissing(:amt) ? missing : :amt / :wt
    
    # Log-transformed concentrations
    :ldv = ismissing(:dv)
end

# Calculate time since first dose
po_processed = @chain po_processed begin
    @groupby :id
    @transform begin
        :time_after_first_dose = :time .- minimum(:time[:evid .== 1])
    end
end

# Handle duplicate time points
duplicates = combine(groupby(po_processed, [:id, :time]), nrow => :count)
duplicates = duplicates[duplicates.count .> 1, :]

if !isempty(duplicates)
    for row in eachrow(duplicates)
        idx = findall(x -> x.id == row.id && x.time == row.time, po_processed)
        po_processed[idx[2:end], :time] .+= 1e-6 .* (1:length(idx[2:end]))
    end
end

# Exercise 2: Data Wrangling for IV Data
iv_sd = dataset("iv_sd_1")
iv_processed = copy(iv_sd)

# Add cmt and evid columns
@rtransform! iv_processed begin
    :cmt = ismissing(:amt) ? missing : 1
    :evid = ismissing(:amt) ? 0 : 1
end

# Calculate subject-specific metrics
subject_metrics = combine(groupby(iv_processed, :id)) do df
    (
        total_dose = sum(skipmissing(df.amt)),
        n_obs = count(.!ismissing.(df.conc)),
        last_obs = maximum(df.time[.!ismissing.(df.conc)])
    )
end

@info "Subject Metrics:"
display(subject_metrics)


# Bonus Challenge: Advanced Data Manipulation
function process_dataset(df::DataFrame)
    # Identify dataset type
    is_pk = all(col -> col ∈ names(df), [:TIME, :DV, :AMT])
    
    processed = copy(df)
    
    if is_pk
        # PK data processing
        @rtransform! processed begin
            # Normalize concentrations by dose if available
            :DV_NORM = if !ismissing(:DV) && !ismissing(:AMT)
                :DV / :AMT
            else
                missing
            end
            
            # Time since first dose
            :TAD = :TIME - minimum(:TIME[.!ismissing.(:AMT)])
        end
        
        # Wide format: pivot DV by time
        wide = unstack(
            processed,
            :id,
            :TIME,
            :DV,
            renamecols = x -> "conc_$(x)"
        )
    else
        # Categorical data processing
        # Create dummy variables for string columns
        for col in names(processed)
            if eltype(processed[!, col]) <: Union{String, CategoricalValue}
                dummies = DataFrame(
                    indicator(processed[!, col]),
                    :auto
                )
                processed = hcat(processed, dummies)
            end
        end
        
        # Wide format: one row per subject
        wide = processed |> 
            x -> groupby(x, :id) |>
            x -> combine(x, names(x) .=> first, renamecols=false)
    end
    
    return (long=processed, wide=wide)
end

# Test the function on all datasets
po_results = process_dataset(po_sad)
iv_results = process_dataset(iv_sd)
nausea_results = process_dataset(nausea_data)

@info "Results of data processing:"
@info "PO SAD:" long_shape=size(po_results.long) wide_shape=size(po_results.wide)
@info "IV SD:" long_shape=size(iv_results.long) wide_shape=size(iv_results.wide)
@info "Nausea:" long_shape=size(nausea_results.long) wide_shape=size(nausea_results.wide) 
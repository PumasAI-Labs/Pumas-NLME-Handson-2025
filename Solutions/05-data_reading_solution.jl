using CSV, DataFrames, PharmaDatasets, Statistics

# Exercise 1: Reading and Exploring PK Data
po_sad = dataset("po_sad_1")

# Basic information
@info "Dataset Information:" metrics=(
    rows = nrow(po_sad),
    columns = ncol(po_sad),
    column_names = names(po_sad)
)

# Column types
col_types = Dict(name => string(type) for (name, type) in zip(names(po_sad), eltype.(eachcol(po_sad))))
@info "Column types:" types=col_types

# First 5 rows
@info "First 5 rows:"
display(first(po_sad, 5))

# Summary statistics
@info "Summary statistics:"
display(describe(po_sad))

# Missing values
missing_counts = Dict(
    col => sum(ismissing.(po_sad[:, col])) 
    for col in names(po_sad)
    if sum(ismissing.(po_sad[:, col])) > 0
)
@info "Missing value counts:" counts=missing_counts

# Exercise 2: Reading and Exploring IV Data
iv_sd = dataset("iv_sd_1")

function analyze_pk_data(df::DataFrame)
    n_subjects = length(unique(df.id))
    dose_range = extrema(filter(!ismissing, df.amt))
    time_range = extrema(df.time)
    
    return Dict(
        "subjects" => n_subjects,
        "dose_range" => dose_range,
        "time_range" => time_range
    )
end

po_analysis = analyze_pk_data(po_sad)
iv_analysis = analyze_pk_data(iv_sd)

@info "PO SAD Analysis:" po_analysis
@info "IV SD Analysis:" iv_analysis

# Exercise 3: Reading and Exploring Categorical Data
nausea_data = dataset("nausea")

# Identify categorical columns
cat_cols = names(nausea_data)[eltype.(eachcol(nausea_data)) .<: Union{String, CategoricalValue}]

# Analyze each categorical column
for col in cat_cols
    values = nausea_data[:, col]
    freq = countmap(values)
    @info "Analysis of $col:" unique_values=length(freq) frequencies=freq
end

# Create summary table
cat_summary = DataFrame(
    Column = cat_cols,
    Unique_Values = [length(unique(nausea_data[:, col])) for col in cat_cols],
    Most_Common = [mode(nausea_data[:, col]) for col in cat_cols],
    Missing_Count = [sum(ismissing.(nausea_data[:, col])) for col in cat_cols]
)

@info "Categorical Summary Table:"
display(cat_summary)

# Bonus Challenge: Data Quality Assessment
function check_data_quality(df::DataFrame, name::String)
    issues = Dict()
    
    # Check continuous variables for outliers
    for col in names(df)
        if eltype(df[:, col]) <: Number
            values = filter(!ismissing, df[:, col])
            if !isempty(values)
                q1, q3 = quantile(values, [0.25, 0.75])
                iqr = q3 - q1
                outliers = values[(values .< q1 - 1.5*iqr) .| (values .> q3 + 1.5*iqr)]
                if !isempty(outliers)
                    issues["$(col)_outliers"] = length(outliers)
                end
            end
        end
    end
    
    # Check time consistency within subjects
    if all(col -> col ∈ names(df), [:ID, :TIME])
        for sub in unique(df.ID)
            sub_data = df[df.ID .== sub, :]
            if any(diff(sub_data.TIME) .< 0)
                issues["time_inconsistency_subject_$sub"] = true
            end
        end
    end
    
    # Check reasonable ranges
    if :DV ∈ names(df)
        dv_range = extrema(filter(!ismissing, df.DV))
        if dv_range[1] < 0 || dv_range[2] > 1000
            issues["unusual_DV_range"] = dv_range
        end
    end
    
    @info "Data Quality Report for $name:" issues
    return issues
end

# Apply quality check to all datasets
po_quality = check_data_quality(po_sad, "PO SAD")
iv_quality = check_data_quality(iv_sd, "IV SD")
nausea_quality = check_data_quality(nausea_data, "Nausea") 
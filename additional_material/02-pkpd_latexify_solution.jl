using Pumas, Latexify, CairoMakie, Logging

# Exercise 1: Two-Compartment Oral Absorption Model
two_cmt_model = @model begin
    @param begin
        # Population PK parameters
        "Typical value of clearance (L/h)"
        tvcl ∈ RealDomain(lower=0.0, init=5.0)
        "Typical value of central volume (L)"
        tvv1 ∈ RealDomain(lower=0.0, init=50.0)
        "Typical value of intercompartmental clearance (L/h)"
        tvq ∈ RealDomain(lower=0.0, init=2.0)
        "Typical value of peripheral volume (L)"
        tvv2 ∈ RealDomain(lower=0.0, init=100.0)
        "Typical value of absorption rate constant (1/h)"
        tvka ∈ RealDomain(lower=0.0, init=1.0)
        
        # Random effects
        "Variance-covariance matrix for CL and V1"
        Ω_clv1 ∈ PDiagDomain(2; init=[0.04, 0.04])
        "Variance for Q"
        ω_q ∈ RealDomain(lower=0.0, init=0.04)
        "Variance for V2"
        ω_v2 ∈ RealDomain(lower=0.0, init=0.04)
        "Variance for Ka"
        ω_ka ∈ RealDomain(lower=0.0, init=0.04)
        
        # Error parameters
        "Proportional error"
        σ_prop ∈ RealDomain(lower=0.0, init=0.1)
        "Additive error"
        σ_add ∈ RealDomain(lower=0.0, init=0.1)
    end
    
    @random begin
        # Random effects with correlation
        η_clv1 ~ MvNormal(Ω_clv1)
        η_q ~ Normal(0.0, √ω_q)
        η_v2 ~ Normal(0.0, √ω_v2)
        η_ka ~ Normal(0.0, √ω_ka)
    end
    
    @covariates begin
        WT
        SEX
    end
    
    @pre begin
        # Individual parameters with covariate effects
        CL = tvcl * (WT/70.0)^0.75 * (SEX == 1 ? 1.1 : 1.0) * exp(η_clv1[1])
        V1 = tvv1 * (WT/70.0) * exp(η_clv1[2])
        Q = tvq * (WT/70.0)^0.75 * exp(η_q)
        V2 = tvv2 * (WT/70.0) * exp(η_v2)
        Ka = tvka * exp(η_ka)
    end
    
    @dynamics begin
        Depot' = -Ka * Depot
        Central' = Ka * Depot - (CL/V1) * Central - (Q/V1) * Central + (Q/V2) * Peripheral
        Peripheral' = (Q/V1) * Central - (Q/V2) * Peripheral
    end
    
    @derived begin
        cp := Central / V1
        dv ~ @. Normal(cp, sqrt(σ_prop^2 * cp^2 + σ_add^2))
    end
end

# Exercise 2: Model Visualization with Latexify
# Generate LaTeX equations for different model components
dynamics_eq = latexify(two_cmt_model, :dynamics)
param_eq = latexify(two_cmt_model, :param)
random_eq = latexify(two_cmt_model, :random)
derived_eq = latexify(two_cmt_model, :derived)

@info "Model Equations in LaTeX format:"
render(dynamics_eq)
render(param_eq)
render(random_eq)
render(derived_eq)

# Bonus Challenge: Transit Compartment Extension
transit_model = @model begin
    @param begin
        # Original parameters
        tvcl ∈ RealDomain(lower=0.0, init=5.0)
        tvv1 ∈ RealDomain(lower=0.0, init=50.0)
        tvq ∈ RealDomain(lower=0.0, init=2.0)
        tvv2 ∈ RealDomain(lower=0.0, init=100.0)
        
        # Transit compartment parameters
        "Mean absorption time"
        tvmat ∈ RealDomain(lower=0.0, init=1.0)
        "Number of transit compartments"
        n_transit ∈ RealDomain(lower=1.0, init=3.0)
        
        # Random effects and error parameters
        Ω ∈ PDiagDomain([0.04, 0.04, 0.04, 0.04, 0.04])
        σ_prop ∈ RealDomain(lower=0.0, init=0.1)
    end
    
    @random begin
        η ~ MvNormal(Ω)
    end
    
    @covariates begin
        WT
        SEX
    end
    
    @pre begin
        CL = tvcl * (WT/70.0)^0.75 * exp(η[1])
        V1 = tvv1 * (WT/70.0) * exp(η[2])
        Q = tvq * (WT/70.0)^0.75 * exp(η[3])
        V2 = tvv2 * (WT/70.0) * exp(η[4])
        MAT = tvmat * exp(η[5])
        ktr = (n_transit + 1)/MAT
    end
    
    @dynamics begin
        Transit1' = -ktr * Transit1
        Transit2' = ktr * (Transit1 - Transit2)
        Transit3' = ktr * (Transit2 - Transit3)
        Central' = ktr * Transit3 - (CL/V1) * Central - (Q/V1) * Central + (Q/V2) * Peripheral
        Peripheral' = (Q/V1) * Central - (Q/V2) * Peripheral
    end
    
    @derived begin
        cp := Central / V1
        dv ~ @. Normal(cp, σ_prop * cp)
    end
end

# Visualize transit model
transit_dynamics = latexify(transit_model, :dynamics)
@info "Transit Compartment Model Equations:"
render(transit_dynamics) 

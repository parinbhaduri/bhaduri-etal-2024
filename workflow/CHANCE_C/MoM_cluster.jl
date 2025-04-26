#File for running Method of Morris for CHANCE-C on Cluster 
using Pkg
Pkg.activate("."); 
Pkg.instantiate()

using Distributed, SlurmClusterManager

addprocs(SlurmManager())
@everywhere println("hello from $(myid()):$(gethostname())")

# instantiate and precompile environment
@everywhere begin
  using Pkg;Pkg.activate("."); 
  Pkg.instantiate(); Pkg.precompile()
end

@everywhere begin
    using CSV, DataFrames
    using GlobalSensitivity
    using Statistics
    using Agents
    using CHANCE_C
    using LinearAlgebra
    using StatsBase
    using Random
    using DataStructures
    using Distributions
    using FileIO
end

@everywhere include(joinpath(@__DIR__, "src/damage_functions.jl"))

##Input Data
@everywhere begin
    data_location = "baltimore-data/model_inputs"
    balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
    balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))
    balt_ddf = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "ddfs", "ens_agg_bg.csv")))
end

## Create wrapper of Simulator function to avoid specifying input data and hyperparameters every time
@everywhere begin 
    @everywhere BaltSim(;slr_scen::String, no_of_years::Int64, perc_growth::Float64, house_choice_mode::String, flood_coefficient::Float64, levee::Bool, 
    breach::Bool, breach_null::Float64, risk_averse::Float64, flood_mem::Int64, fixed_effect::Float64, base_move::Float64, seed::Int64) = Simulator(default_df, balt_base, balt_levee; 
    slr_scen = slr_scen, slr_rate = [3.03e-3,7.878e-3,2.3e-2], scenario = "Baseline", intervention = "Baseline", start_year = 2018, no_of_years = no_of_years, 
    pop_growth_perc = perc_growth, house_choice_mode = house_choice_mode, flood_coefficient = flood_coefficient, levee = levee, breach = breach, 
    breach_null = breach_null, risk_averse = risk_averse, flood_mem = flood_mem, fixed_effect = fixed_effect, perc_move = base_move, seed = seed)


    #Define Function to calculate return period from return level
    surge_event = collect(range(0.75,4.0, step=0.25))
    function GEV_rp(z_p, mu = μ, sig = σ, xi = ξ)
        y_p = 1 + (xi * ((z_p - mu)/sig))
        rp = -exp(-y_p^(-1/xi)) + 1
        rp = round(rp, digits = 3)
        return 1/rp
    end

    #Extract params from GEV distribution calibrated to Baltimore
    mu, sig, xi =  StatsBase.params(CHANCE_C.default_gev)

    #Calculate prob of occurrence of surge events from GEV distribution
    surge_rp = 1 ./ GEV_rp.(surge_event, Ref(mu), Ref(sig), Ref(xi))
end


#Set seed range
seed_range = range(1000, 1999, step = 4)

#create function to run model using samples
function balt_mom(param_values::Vector)
    #For slr scenario
    d = Dict( 1.0 => "low", 2.0 => "medium", 3.0 => "high")

    #Select correct event dictionary based on breach occurrence in realization
    if Bool(round(param_values[2])) #breach is true
        breach_prob = levee_breach.(m_to_ft.(surge_event); n_null = 0.4)
        breach_dict = Dict(zip(surge_event,breach_prob))
    else #breach is false, overtopping only
        overtop_only = zeros(length(surge_event))
        breach_dict = Dict(zip(surge_event,overtop_only))
    end
   
    base_dam, lev_dam = risk_damage(balt_ddf, breach_dict, seed_range; slr_scen=d[round(param_values[6])], no_of_years=50, perc_growth=param_values[3], house_choice_mode="flood_mem_utility", flood_coefficient=-10.0^5, 
    breach=Bool(round(param_values[2])), breach_null=0.4, risk_averse=param_values[1], flood_mem=Int(round(param_values[4])), fixed_effect=param_values[5], base_move=0.025, showprogress = false)

    #Calculate Risk Shifting integral
    RSI = log.(sum(Matrix(lev_dam) .* surge_rp, dims = 1) ./ sum(Matrix(base_dam) .* surge_rp, dims = 1))
    Y = mean(RSI)

    return Y
end


#create variable of vector bounds
var_vec = [(0,1),(0,1),(0.0,0.02),(3,15),(0,0.01),(1,3)]

#Run Method of Morris

println("Starting Method of Morris")

s = gsa(balt_mom, Morris(num_trajectory=100, relative_scale=true), var_vec)

#Get mean and variance of EE 
param_avg = abs.(s.means)
param_var = s.variances

#Save To DataFrame
println("Saving Results to DataFrame")

MoM_results = DataFrame(params=["Risk Averse", "Breach", "Pop. Growth", "Flood Memory", "Expectation Effect", "SLR"],
          exp_mean = param_avg[1,:],
          exp_var = param_var[1,:]
)

CSV.write(joinpath(@__DIR__, "SA_Results/MoM_results_balt_100_norm.csv"), MoM_results)
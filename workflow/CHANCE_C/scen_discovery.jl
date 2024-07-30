#File for running sensitivity analysis on Cluster 
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
function flood_scen(param_values::AbstractArray{<:Number, N}) where N

    numruns = size(param_values, 1)
    Y = zeros(numruns, 1)
    #For slr scenario
    d = Dict( 1.0 => "low", 2.0 => "medium", 3.0 => "high")

    progress = Agents.ProgressMeter.Progress(numruns; enabled = true)
    #Select correct event dictionary based on breach occurrence in realization
    if Bool(param_values[1,2]) #breach is true
        breach_prob = levee_breach.(m_to_ft.(surge_event); n_null = 0.4)
        breach_dict = Dict(zip(surge_event,breach_prob))
    else #breach is false, overtopping only
        overtop_only = zeros(length(surge_event))
        breach_dict = Dict(zip(surge_event,overtop_only))
    end
   
    base_dam, lev_dam = risk_damage(balt_ddf, breach_dict, seed_range; slr_scen=d[param_values[1,6]], no_of_years=50, perc_growth=param_values[1,3], house_choice_mode="flood_mem_utility", flood_coefficient=-10.0^5, 
    breach=Bool(param_values[1,2]), breach_null=0.4, risk_averse=param_values[1,1], flood_mem=Int(param_values[1,4]), fixed_effect=param_values[1,5], base_move=0.025, showprogress = true)

    #Calculate Risk Shifting integral
    RSI = log.(sum(Matrix(lev_dam) .* surge_rp, dims = 1) ./ sum(Matrix(base_dam) .* surge_rp, dims = 1))
    Y[1,1] = mean(RSI)
    Agents.ProgressMeter.next!(progress)
    
    Agents.ProgressMeter.progress_map(2:numruns; progress) do i
         #Select correct event dictionary based on breach occurrence in realization
        
        if Bool(param_values[i,2]) #breach is true
            breach_prob = levee_breach.(m_to_ft.(surge_event); n_null = 0.4)
            breach_dict = Dict(zip(surge_event,breach_prob))
        else #breach is false, overtopping only
            overtop_only = zeros(length(surge_event))
            breach_dict = Dict(zip(surge_event,overtop_only))
        end
        
        base_dam, lev_dam = risk_damage(balt_ddf, breach_dict, seed_range; slr_scen=d[param_values[i,6]], no_of_years=50, perc_growth=param_values[i,3], house_choice_mode="flood_mem_utility", flood_coefficient=-10.0^5, 
        breach=Bool(param_values[i,2]), breach_null=0.4, risk_averse=param_values[i,1], flood_mem=Int(param_values[i,4]), fixed_effect=param_values[i,5], base_move=0.025, showprogress = false)

        #Calculate Risk Shifting integral
        RSI = log.(sum(Matrix(lev_dam) .* surge_rp, dims = 1) ./ sum(Matrix(base_dam) .* surge_rp, dims = 1))
        Y[i,1] = mean(RSI)
    end
    
    return Y
end

##Create Parameter combinations
seed = Random.seed!(1)

#Define Parameter ranges
allcombinations(v...) = vec(collect(Iterators.product(v...)))

params = OrderedDict(:risk_averse => [0.0, 0.2, 0.4, 0.6, 0.8], :breach => [1.0, 0.0], :pop_growth => [0.0, 0.005, 0.01, 0.015],
    :mem => [5.0, 10.0, 15.0], :fixed_effect => [0.0, 0.02, 0.04, 0.06, 0.08], :slr => [1.0, 2.0, 3.0],)


param_combs = allcombinations(getindex.(Ref(params), params.keys)...)

samples = [tup[k] for tup in param_combs, k in 1:6]
#samples = GSA.sample(data)
for i in 1:size(samples)[1]
    averse_dist = Uniform(samples[i,1], samples[i,1] + 0.2) #r_a
    growth_dist = Uniform(samples[i,3], samples[i,3] + 0.005) #pop_growth
    fe_dist = Uniform(samples[i,5], samples[i,5] + 0.02) #fixed_effect

    samples[i,1] = rand(seed, averse_dist)
    samples[i,3] = rand(seed, growth_dist)
    samples[i,5] = rand(seed, fe_dist)
end


#run model
Y = flood_scen(samples)

## Save results
#Create Dataframe to store values

params = params.keys
push!(params, :RSI)

factor_samples = DataFrame(hcat(samples,Y), params)
CSV.write(joinpath(@__DIR__, "SA_Results/scen_disc_table.csv"), factor_samples)

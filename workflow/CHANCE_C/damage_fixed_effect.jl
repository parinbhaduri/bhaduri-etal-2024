### Calculate expected flood losses at the BG level in the baseline and levee scenarios 
# Determining how large the fixed effect parameter needs to be to result in risk transference
### 
 
using Distributed

num_cores = parse(Int,ENV["SLURM_TASKS_PER_NODE"])
addprocs(num_cores)

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
    using Optim
    using StatsBase
end

@everywhere include(joinpath(@__DIR__, "src/damage_functions.jl"))

##Input Data
@everywhere begin
    data_location = "baltimore-data/model_inputs"
    balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
    balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))
    balt_ddf = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "ddfs", "ens_agg_bg.csv")))
end

##Import results from original benchmark damage scenario (breaching, 1% pop growth)
@everywhere begin
    base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
    levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

    #Calculate Median and 95% Uncertainty Interval
    bench_diff = Matrix(levee_dam) .- Matrix(base_dam) 
    bench_med = vec(mapslices(x -> median(x), bench_diff, dims=2))
end

## Create wrapper of Simulator function to avoid specifying input data and hyperparameters every time
@everywhere begin 
    BaltSim(;slr::Bool, no_of_years::Int64, perc_growth::Float64, house_choice_mode::String, flood_coefficient::Float64, levee::Bool, 
    breach::Bool, breach_null::Float64, risk_averse::Float64, flood_mem::Int64, fixed_effect::Float64, base_move::Float64, seed::Int64) = Simulator(default_df, balt_base, balt_levee;  
    slr = slr, slr_scen = [3.03e-3,7.878e-3,2.3e-2], scenario = "Baseline", intervention = "Baseline", start_year = 2018, no_of_years = no_of_years,  
    pop_growth_perc = perc_growth, house_choice_mode = house_choice_mode, flood_coefficient = flood_coefficient, levee = levee, breach = breach, 
    breach_null = breach_null, risk_averse = risk_averse, flood_mem = flood_mem, fixed_effect = fixed_effect, perc_move = base_move, seed = seed)

    #Calculate breach probability for each surge event (All zero since considering overtopping only)
    surge_event = collect(range(0.75,4.0, step=0.25))
    breach_prob = zeros(length(surge_event))

    surge_overtop = Dict(zip(surge_event,breach_prob))

    #wrapper function for risk_damage to just accept f_e term
    risk_fe(f_e; perc_growth = 0.01) = risk_damage(balt_ddf, surge_overtop, seed_range;slr=true, no_of_years=50, perc_growth=perc_growth, house_choice_mode="flood_mem_utility", flood_coefficient=-10.0^5, 
    breach=false, breach_null=0.45, risk_averse=0.3, flood_mem=10, fixed_effect=f_e, base_move=0.025, showprogress = false)
end



## Find the fixed_effect parameter that approximates the median benchmark scenario

seed_range = range(1000, 1999, step = 1)

#Create function to run optimizer over
function damage_optimizer(f_e)
    #Calculate damages 
    base, levee = risk_fe(f_e; perc_growth = 0.0)
    #Calculate Median damage estimate
    diff_dam = Matrix(levee) .- Matrix(base) 
    diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))
    #Calculate RMSE with benchmark
    err = rmsd(bench_med, diff_med)
    return err
end


results = optimize(damage_optimizer, 0.0, 0.1; iterations = 100, show_trace = true)

println("Optimal fixed effect parameter is: ", results.minimizer)
println(results)

## Calculate damage ensemble using optimal fixed_effect parameter
breach = false
perc_growth = 0.0
fixed_effect = Optim.minimizer(results) #f_e = 5.697610e-03 w/ 1% growth

base_optim, levee_optim = risk_fe(fixed_effect; perc_growth = perc_growth)

#Save Dataframes
CSV.write(joinpath(@__DIR__,"dataframes/base_event_optimFE_no_breach_no_growth.csv"), base_optim)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_optimFE_no_breach_no_growth.csv"), levee_optim)






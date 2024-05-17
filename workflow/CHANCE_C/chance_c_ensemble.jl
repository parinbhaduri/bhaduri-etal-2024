#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

##Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))
#using CHANCE_C
#using CSV, DataFrames
#include("src/data_collect.jl")

@everywhere data_location = "baltimore-housing-data/model_inputs"
@everywhere balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
@everywhere balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))

## specify data collection
adata = [(:new_price, mean, f_bgs), (:new_price, mean, nf_bgs), (:population, sum, f_bgs), (:pop90, sum, f_bgs), (:population, sum, nf_bgs), (:pop90, sum, nf_bgs)]
mdata = [flood_scenario, flood_record, total_fld_area]

## Create wrapper of Simulator function to avoid specifying input data and hyperparameters every time
@everywhere BaltSim(;slr::Bool, no_of_years::Int64, perc_growth::Float64, house_choice_mode::String, flood_coefficient::Float64, levee::Bool,
 breach::Bool, breach_null::Float64, risk_averse::Float64, flood_mem::Int64, fixed_effect::Float64, base_move::Float64, seed::Int64) = Simulator(default_df, balt_base, balt_levee; 
 slr = slr, slr_scen = [3.03e-3,7.878e-3,2.3e-2], scenario = "Baseline", intervention = "Baseline", start_year = 2018, no_of_years = no_of_years, 
 pop_growth_perc = perc_growth, house_choice_mode = house_choice_mode, flood_coefficient = flood_coefficient, levee = levee, breach = breach, 
 breach_null = breach_null, risk_averse = risk_averse, flood_mem = flood_mem, fixed_effect = fixed_effect, perc_move = base_move, seed = seed)

#BaltSim(;slr=true, slr_scen = [3.03e-3,7.878e-3,2.3e-2], scenario = "test", intervention = "test", start_year = 2018, no_of_years = 10, perc_growth = 0.01, house_choice_mode = "flood_mem_utility", flood_coefficient=-10.0^5, levee=true,
# breach=true, breach_null=0.45, risk_averse=0.3, flood_mem=10, fixed_effect=0.0, seed=1500)
##Evolve models over different parameter combinations for baseline scenario
params = Dict(
    :no_of_years => 50,
    :slr => [true, false],
    :perc_growth => 0.01,
    :house_choice_mode => "flood_mem_utility",
    :flood_coefficient => -10.0^5,
    :risk_averse => [0.3, 0.7],
    :levee => [false, true],
    :breach => true,
    :breach_null => 0.45,
    :flood_mem => 10,
    :fixed_effect => 0.0,
    :base_move => 0.025,  
    :seed => collect(range(1000,1999)), 
)


adf, mdf = paramscan(params, BaltSim; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = CHANCE_C.model_step!, n = 50)

CSV.write(joinpath(@__DIR__,"dataframes/adf_balt.csv"), adf)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_balt.csv"), mdf)

rmprocs(workers())
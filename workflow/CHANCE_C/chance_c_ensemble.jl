#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

##Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))
#using CHANCE_C
#using CSV, DataFrames
#include("src/data_collect.jl")

## specify data collection
adata = [(:new_price, mean, f_c_bgs), (:new_price, mean, nf_c_bgs), (:population, sum, f_c_bgs), (:pop90, sum, f_c_bgs), (:population, sum, nf_c_bgs), (:pop90, sum, nf_c_bgs)]
mdata = [flood_scenario, flood_record, total_fld_area]

#Define model parameters or parameter ranges for ABM initialization
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

#Run models and collect data
adf, mdf = paramscan(params, BaltSim; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = CHANCE_C.model_step!, n = 50)

CSV.write(joinpath(@__DIR__,"dataframes/adf_balt_city.csv"), adf)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_balt_city.csv"), mdf)

rmprocs(workers())
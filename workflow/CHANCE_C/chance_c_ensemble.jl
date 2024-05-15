#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

##Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))

data_location = "baltimore-housing-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))

## specify data collection
adata = [(:flood_hazard, sum, BG), (:population, sum, f_bgs), (:pop90, sum, f_bgs), (:population, sum, nf_bgs), (:pop90, sum, nf_bgs)]
mdata = [flood_scenario, flood_record, total_fld_area]

## Create wrapper of Simulator function to avoid specifying input data and hyperparameters every time
Simulator(default_df, balt_base, balt_levee; slr = true, slr_scen = [3.03e-3,7.878e-3,2.3e-2], scenario = scenario, intervention = intervention, start_year = start_year, no_of_years = no_of_years,
pop_growth_perc = perc_growth, house_choice_mode = house_choice_mode, flood_coefficient = flood_coefficient, levee = false, breach = breach, breach_null = breach_null, risk_averse = i,
 flood_mem = flood_mem, fixed_effect = fixed_effect)

##Evolve models over different parameter combinations for baseline scenario
params = Dict(
    :scenario => "Baseline",
    :intervention => "Baseline",
    :start_year => 2018,
    :no_of_years => 50,
    :slr => true,
    :slr_scen => [3.03e-3,7.878e-3,2.3e-2],
    :perc_growth => 0.01,
    :house_choice_mode => "flood_mem_utility",
    :flood_coefficient => -10^5,
    :risk_averse => [0.3, 0.7],
    :levee => false,
    :breach => true,
    :breach_null => 0.45,
    :flood_mem => 10,
    :fixed_effect => 0,
    :prob_move => 0.025,  
    :seed => collect(range(1000,2000)), 
)


adf, mdf = paramscan(params, Simulator; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = CHANCE_C.model_step!, n = 50)

CSV.write(joinpath(@__DIR__,"dataframes/adf_base_balt.csv"), adf)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_base_balt.csv"), mdf)

###Repeat for Levee Scenario 
##Evolve models over different parameter combinations
params_levee = Dict(
    :scenario => "Baseline",
    :intervention => "Baseline",
    :start_year => 2018,
    :no_of_years => 50,
    :slr => true,
    :slr_scen => [3.03e-3,7.878e-3,2.3e-2],
    :perc_growth => 0.01,
    :house_choice_mode => "flood_mem_utility",
    :flood_coefficient => -10^5,
    :risk_averse => [0.3, 0.7],
    :levee => true,
    :breach => true,
    :breach_null => 0.45,
    :flood_mem => 10,
    :fixed_effect => 0,
    :prob_move => 0.025,  
    :seed => collect(range(1000,2000)), 
)


adf, mdf = paramscan(params_levee, Simulator; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = CHANCE_C.model_step!, n = 50)

CSV.write(joinpath(@__DIR__,"dataframes/adf_base_balt.csv"), adf_levee)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_base_balt.csv"), mdf_levee)

rmprocs(workers())
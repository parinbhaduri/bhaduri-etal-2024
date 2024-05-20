
## Create wrapper of Simulator function to avoid specifying input data and hyperparameters every time
BaltSim(;slr::Bool, no_of_years::Int64, perc_growth::Float64, house_choice_mode::String, flood_coefficient::Float64, levee::Bool,
 breach::Bool, breach_null::Float64, risk_averse::Float64, flood_mem::Int64, fixed_effect::Float64, base_move::Float64, seed::Int64) = Simulator(default_df, balt_base, balt_levee; 
 slr = slr, slr_scen = [3.03e-3,7.878e-3,2.3e-2], scenario = "Baseline", intervention = "Baseline", start_year = 2018, no_of_years = no_of_years, 
 pop_growth_perc = perc_growth, house_choice_mode = house_choice_mode, flood_coefficient = flood_coefficient, levee = levee, breach = breach, 
 breach_null = breach_null, risk_averse = risk_averse, flood_mem = flood_mem, fixed_effect = fixed_effect, perc_move = base_move, seed = seed)


#import input data 
data_location = "baltimore-housing-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))
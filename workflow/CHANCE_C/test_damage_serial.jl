### Calculate expected flood losses at the BG level in the baseline and levee scenarios ### 
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Agents
using CHANCE_C
using LinearAlgebra

#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config.jl"))
include("src/damage_functions.jl")

#import input data 
data_location = "baltimore-housing-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))

balt_ddf = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "ddfs", "ens_agg_bg.csv")))

#Define input parameters
slr = true
no_of_years = 50
perc_growth = 0.01
house_choice_mode = "flood_mem_utility"
flood_coefficient = -10.0^5
breach = true
breach_null = 0.45 
risk_averse = 0.3
flood_mem = 10
fixed_effect = 0.0 
base_move = 0.025

#Calculate breach likelihood for each surge event
surge_event = collect(range(0.75,4.0, step=0.25))
breach_prob = levee_breach.(m_to_ft.(surge_event); n_null = breach_null)

surge_breach = Dict(zip(surge_event,breach_prob))
##  Calculate expected losses

#For serial: 
seed_range = range(1000, 1004, step = 1)

occupied = DataFrame(zeros(length(surge_event),length(seed_range)), string.(collect(seed_range)))
occupied_levee = copy(occupied)

for seed in seed_range
    test_base = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
            breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=seed)
            
    test_levee = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
            breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=seed)
    
    step!.([test_base test_levee], dummystep, CHANCE_C.model_step!, 50)
    #calculate damages and add to dataframes
    occupied[!, string(seed)] = event_damage(test_base, balt_ddf, surge_breach; scen = "base")
    occupied_levee[!, string(seed)] = event_damage(test_levee, balt_ddf, surge_breach; scen = "levee")
end 
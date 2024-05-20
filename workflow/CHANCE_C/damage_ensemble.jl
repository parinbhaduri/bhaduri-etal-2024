### Calculate expected flood losses at the BG level in the baseline and levee scenarios ### 
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))

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

#For Parallel:
seed_range = range(1000, 1004, step = 1)

base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)






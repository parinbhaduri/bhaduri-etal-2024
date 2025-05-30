### Calculate expected flood losses at the BG level in the baseline and levee scenarios ### 
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))

#Define input parameters
slr_scen = "medium"
no_of_years = 50
perc_growth = 0.01
house_choice_mode = "flood_mem_utility"
flood_coefficient = -10.0^5
breach = true
breach_null = 0.4 
risk_averse = 0.3
flood_mem = 10
fixed_effect = 0.0 
base_move = 0.025

#Calculate breach likelihood for each surge event
surge_event = collect(range(0.75,4.0, step=0.25))
breach_prob = levee_breach.(m_to_ft.(surge_event); n_null = breach_null)

surge_breach = Dict(zip(surge_event,breach_prob))

#For Parallel:
seed_range = range(1000, 1999, step = 1)



base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)

#Save Dataframes
CSV.write(joinpath(@__DIR__,"dataframes/base_event_damage.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_damage.csv"), levee_damage)


## Look at alternative benchmark scenario (low RA)
risk_averse = 0.7

base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)

#Save Dataframess
CSV.write(joinpath(@__DIR__,"dataframes/base_event_low_RA.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_low_RA.csv"), levee_damage)


## Look at alternative benchmark scenario (0% growth, high and low RA)
perc_growth = 0.0

risk_averse = 0.3
base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true
)
CSV.write(joinpath(@__DIR__,"dataframes/base_event_damage_no_growth.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_damage_no_growth.csv"), levee_damage)


risk_averse = 0.7
base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true
)
CSV.write(joinpath(@__DIR__,"dataframes/base_event_no_growth_low_RA.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_no_growth_low_RA.csv"), levee_damage)


## Look at alternative benchmark scenario (2% growth, high and low RA)
perc_growth = 0.02

risk_averse = 0.3
base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true
)
CSV.write(joinpath(@__DIR__,"dataframes/base_event_damage_two_growth.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_damage_two_growth.csv"), levee_damage)


risk_averse = 0.7
base_damage, levee_damage = risk_damage(balt_ddf, surge_breach, seed_range;slr_scen=slr_scen, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true
)
CSV.write(joinpath(@__DIR__,"dataframes/base_event_two_growth_low_RA.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_two_growth_low_RA.csv"), levee_damage)


 
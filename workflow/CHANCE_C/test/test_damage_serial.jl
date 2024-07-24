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
include(joinpath(dirname(@__DIR__), "src/config.jl"))
include(joinpath(dirname(@__DIR__), "src/damage_functions.jl"))

#import input data 
data_location = "baltimore-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))

balt_ddf = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "ddfs", "ens_agg_bg.csv")))
#sum(eachcol(select(balt_ddf, r"loss_diff")))
#sum(eachcol(select(balt_ddf, r"depth_diff")))

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


#Test damage calculations 
model_base = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
breach=false, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=1897)

step!(model_base, dummystep, CHANCE_C.model_step!, 50)
#Grab Block Group id, population, and cumulative housing value from the Block Group agents
pop_df = DataFrame(stack([[a.id, a.occupied_units, a.new_price] for a in allagents(model_base) if a isa BlockGroup], dims = 1), ["id", "pop", "avg_price"])
#join pop data with the ABM dataframe
base_df = leftjoin(model_base.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
#Join ABM dataframe with depth-damage ensemble
new_df = innerjoin(base_df, balt_ddf, on= :GEOID => :bg_id)
    
## calculate losses across event sizes
#Find total number of Household Agents
total_pop_base = length([a for a in allagents(model_base) if a isa HHAgent])
bg_pop_base = new_df.pop ./ total_pop_base
bg_price_base = new_df.avg_price
#Calculate cumulative housing value across block groups
total_value_base = sum(new_df.pop .* new_df.avg_price) 
#Change inf values (price or pop is 0) to 0
#test_dam .= ifelse.(test_dam .== Inf, 0.0, test_dam)
scen = "base"   
p_breach_base = ones(length(keys(surge_breach)))

      
#Calculate weighted average of losses for each event. Sum over block groups  
event_damages_base = (Matrix(select(new_df, r"naccs_loss_Base")) .* p_breach_base') .+ (Matrix(select(new_df, r"naccs_loss_Levee")) .* (1 .- p_breach_base'))
exp_loss_base = sum(event_damages_base .* bg_pop_base, dims = 1)
#return vec(event_damages)
vec(exp_loss_base)


model_levee = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=1897)

step!(model_levee, dummystep, CHANCE_C.model_step!, 50)
#Grab Block Group id, population, and cumulative housing value from the Block Group agents
pop_df = DataFrame(stack([[a.id, a.occupied_units, a.new_price] for a in allagents(model_levee) if a isa BlockGroup], dims = 1), ["id", "pop", "avg_price"])
#join pop data with the ABM dataframe
base_df = leftjoin(model_levee.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
#Join ABM dataframe with depth-damage ensemble
new_df = innerjoin(base_df, balt_ddf, on= :GEOID => :bg_id)
    
## calculate losses across event sizes
#Find total number of Household Agents
total_pop_levee = length([a for a in allagents(model_levee) if a isa HHAgent])
bg_pop_levee = new_df.pop ./ total_pop_levee
bg_price_levee = new_df.avg_price
#Calculate cumulative housing value across block groups
total_value = sum(new_df.pop .* new_df.avg_price) 
#Change inf values (price or pop is 0) to 0
#test_dam .= ifelse.(test_dam .== Inf, 0.0, test_dam)
scen = "levee"   
p_breach_levee = sort(collect(values(surge_breach)))

      
#Calculate weighted average of losses for each event. Sum over block groups  
event_damages_levee = (Matrix(select(new_df, r"naccs_loss_Base")) .* p_breach_levee') .+ (Matrix(select(new_df, r"naccs_loss_Levee")) .* (1 .- p_breach_levee'))
exp_loss_levee = sum(event_damages_levee .* bg_pop_levee, dims = 1)
#return vec(event_damages)
vec(exp_loss_levee)

#for scen == "base"
sum(Matrix(select(new_df, r"naccs_loss_Base")) .* p_breach' .+ Matrix(select(new_df, r"naccs_loss_Levee")) .* (1 .- p_breach'), dims = 1) == sum(Matrix(select(new_df, r"naccs_loss_Base")), dims = 1)

#for scen == levee
Matrix(select(new_df, r"naccs_loss_Levee"))[:,1:5] == event_damages_levee[:,1:5]

sum(Matrix(select(new_df, r"naccs_loss_Levee"))[:,1:5] .- Matrix(select(new_df, r"naccs_loss_Base"))[:,1:5], dims = 1)

#Plot
using Plots
diff_dam = vec(exp_loss_levee) - vec(exp_loss_base)

Plots.plot(collect(range(0.75, 4.0, step = 0.25)),diff_dam)

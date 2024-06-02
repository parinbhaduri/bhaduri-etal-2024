#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Agents
using CHANCE_C
using LinearAlgebra
using Plots

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

#Test damage calculations 
model = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=1897)

#Grab Block Group id, population, and cumulative housing value from the Block Group agents
pop_df = DataFrame(stack([[a.id, a.occupied_units, a.new_price] for a in allagents(model) if a isa BlockGroup], dims = 1), ["id", "pop", "avg_price"])
#join pop data with the ABM dataframe
base_df = leftjoin(model.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
#Join ABM dataframe with depth-damage ensemble
new_df = innerjoin(base_df, balt_ddf, on= :GEOID => :bg_id)
    
## calculate losses across event sizes
bg_pop1 = new_df.pop
bg_price1 = new_df.avg_price

step!(model, dummystep, CHANCE_C.model_step!, 50)


#Grab Block Group id, population, and cumulative housing value from the Block Group agents
pop_df = DataFrame(stack([[a.id, a.occupied_units, a.new_price] for a in allagents(model) if a isa BlockGroup], dims = 1), ["id", "pop", "avg_price"])
#join pop data with the ABM dataframe
base_df = leftjoin(model.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
#Join ABM dataframe with depth-damage ensemble
new_df = innerjoin(base_df, balt_ddf, on= :GEOID => :bg_id)
    
## calculate losses across event sizes
bg_pop2 = new_df.pop
bg_price2 = new_df.avg_price

model = BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=1897)

#Track population and price values in the 17 block groups over time
bg_agents = collect(Int.(new_df.fid_1))
pop_matrix = zeros(51,length(bg_agents))
price_matrix = copy(pop_matrix)

pop_matrix[1,:] = [model[id].occupied_units for id in bg_agents]
price_matrix[1,:] = [model[id].new_price for id in bg_agents]

n=1
while n <= 50
    step!(model, dummystep, CHANCE_C.model_step!, 1)
    pop_matrix[n+1,:] = [model[id].occupied_units for id in bg_agents]
    price_matrix[n+1,:] = [model[id].new_price for id in bg_agents]
    n += 1
end

pop_plot1 = Plots.plot(pop_matrix[:,1:6], labels = bg_agents', legend = :topleft)
Plots.ylabel!("Agent Population")
price_plot1 = Plots.plot(price_matrix[:,1:6], labels = bg_agents', legend = false)
Plots.ylabel!("Avg Home Price")

pop_plot2 = Plots.plot(pop_matrix[:,8:17], labels = bg_agents', legend = :topleft)
Plots.ylabel!("Agent Population")
price_plot2 = Plots.plot(price_matrix[:,8:17], labels = bg_agents', legend = false)
Plots.ylabel!("Avg Home Price")

price_pop_trend1 = Plots.plot(pop_plot1, price_plot1, layout = (1,2), dpi = 300)
price_pop_trend2 = Plots.plot(pop_plot2, price_plot2, layout = (1,2), dpi = 300)

savefig(price_pop_trend1, joinpath(pwd(),"figures/price_pop_trend1.png"))
savefig(price_pop_trend2, joinpath(pwd(),"figures/price_pop_trend2.png"))
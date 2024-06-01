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

models = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

models_levee = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

progress = Agents.ProgressMeter.Progress(length(models); enabled = true)
all_data = Agents.ProgressMeter.progress_pmap(models, models_levee; progress) do model, model_levee
    step!.([model model_levee], dummystep, CHANCE_C.model_step!, 50)
    occ = event_damage(model, balt_ddf, surge_breach; scen = "base")
    occ_lev = event_damage(model_levee, balt_ddf, surge_breach; scen = "levee")
    return occ, occ_lev
end

p_occupied = DataFrame(zeros(length(surge_event),length(seed_range)), string.(collect(seed_range)))
p_occupied_levee = copy(p_occupied)
#Reshape results into two matrices of return period by seed range size 
for (seed, data) in zip(collect(seed_range),all_data)
    p_occupied[!, string(seed)] = data[1]
    p_occupied_levee[!, string(seed)] = data[2]
end



#To calculate area value:
seed_range = range(1000, 1004, step = 1)

models = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

models_levee = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

progress = Agents.ProgressMeter.Progress(length(models); enabled = true)
all_data = Agents.ProgressMeter.progress_pmap(models, models_levee; progress) do model, model_levee
    step!.([model model_levee], dummystep, CHANCE_C.model_step!, 50)
    occ = event_damage(model, balt_ddf, surge_breach; scen = "base", mode = "value")
    occ_lev = event_damage(model_levee, balt_ddf, surge_breach; scen = "levee", mode = "value")
    return occ, occ_lev
end

area_val = DataFrame("base" => Float64[], "levee" => Float64[])
    

#Add damage data to dataframes by seed value  
for data in all_data
    push!(area_val, data)
end
area_val
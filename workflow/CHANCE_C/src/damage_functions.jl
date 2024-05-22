###Stores functions needed to calculate damage estimates
function event_damage(model::ABM, ddf::DataFrame, surge_char::Dict{Float64}; scen::String, mode = "damage")
    #Grab Block Group id, population, and cumulative housing value from the Block Group agents
    pop_df = DataFrame(stack([[a.id, a.population * a.new_price] for a in allagents(model) if a isa BlockGroup], dims = 1), ["id", "bg_val"])
    #join pop data with the ABM dataframe
    base_df = leftjoin(model.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
    #Join ABM dataframe with depth-damage ensemble
    new_df = innerjoin(base_df, ddf, on= :GEOID => :bg_id)

    ## calculate cumulative losses across event sizes
    #Calculate ratio between total BG flood loss and total BG housing value for each event 

    #Calculate cumulative housing value across block groups
    total_value = sum(new_df.bg_val)

    if mode == "value" #Return cumulative value in block group
        return total_value
    elseif mode == "damage" #calculate proportion of losses across surge events

        if scen == "levee"
            p_breach = sort(collect(values(surge_char)))
        else
            p_breach = ones(length(keys(surge_char)))
        end
            
        #Calculate weighted average of losses for each event. Sum over block groups  
        event_damages = sum(Matrix(select(new_df, r"naccs_loss_Base")) .* p_breach' .+ Matrix(select(new_df, r"naccs_loss_Levee")) .* (1 .- p_breach'), dims = 1)
        exp_loss = event_damages ./ total_value
        return vec(exp_loss)
    end
end


function risk_damage(ddf, breach_dict, seed_range; slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)

    #Create model ensembles based on input parameters
    models = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

    models_levee = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

    #Evolve models. Calculate damages
    progress = Agents.ProgressMeter.Progress(length(models); enabled = showprogress)
    all_data = Agents.ProgressMeter.progress_pmap(models, models_levee; progress) do model, model_levee
        step!.([model model_levee], dummystep, CHANCE_C.model_step!, 50)
        occ = event_damage(model, ddf, breach_dict; scen = "base", mode = "damage")
        occ_lev = event_damage(model_levee, ddf, breach_dict; scen = "levee", mode = "damage")
        return occ, occ_lev
    end

    occupied = DataFrame(zeros(length(keys(breach_dict)),length(seed_range)), string.(collect(seed_range)))
    occupied_levee = copy(occupied)

    #Add damage data to dataframes by seed value  
    for (seed, data) in zip(collect(seed_range),all_data)
        occupied[!, string(seed)] = data[1]
        occupied_levee[!, string(seed)] = data[2]
    end
    return occupied, occupied_levee
end

function area_value(ddf, breach_dict, seed_range; slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)
    ### Returns the total block group value before flood damages. Function runs ABM scenarios across seed range and calculates total value
    #Create model ensembles based on input parameters
    models = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=false,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

    models_levee = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient, levee=true,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=i) for i in seed_range]

    #Evolve models. Calculate damages
    progress = Agents.ProgressMeter.Progress(length(models); enabled = showprogress)
    all_data = Agents.ProgressMeter.progress_pmap(models, models_levee; progress) do model, model_levee
        step!.([model model_levee], dummystep, CHANCE_C.model_step!, 50)
        occ = event_damage(model, ddf, breach_dict; scen = "base", mode = "value")
        occ_lev = event_damage(model_levee, ddf, breach_dict; scen = "levee", mode = "value")
        return occ, occ_lev
    end

    area_val = DataFrame("base" => Float64[], "levee" => Float64[])
    

    #Add damage data to dataframes by seed value  
    for data in all_data
        push!(area_val, data)
    end

    return area_val
end

"""
function event_damage(model::ABM, ddf::DataFrame, surge_char::Dict{Float64}; scen::String)
    #Grab Block Group id, population, and cumulative housing value from the Block Group agents
    pop_df = DataFrame(stack([[a.id, a.population, a.population * a.new_price] for a in allagents(model) if a isa BlockGroup], dims = 1), ["id", "bg_pop", "bg_val"])
    #join pop data with the ABM dataframe
    base_df = leftjoin(model.df[:,[:fid_1, :GEOID, :new_price]], pop_df, on=:fid_1 =>:id)
    #Join ABM dataframe with depth-damage ensemble
    new_df = innerjoin(base_df, ddf, on= :GEOID => :bg_id)

    ## calculate losses across event sizes
    #Calculate ratio between BG flood loss and BG housing value
    #for each intervention scenario and event
    test_dam = select(new_df, r"naccs") ./ new_df.bg_val 
    #Change inf values (price or pop is 0) to 0
    test_dam .= ifelse.(test_dam .== Inf, 0.0, test_dam)

    if scen == "levee"
        p_breach = sort(collect(values(surge_char)))
    else
        p_breach = ones(length(keys(surge_char)))
    end
    
    #Calculate weighted average of losses for each event. Sum over block groups  
    event_damages = sum(Matrix(select(test_dam, r"_Base_")) .* p_breach' .+ Matrix(select(test_dam, r"_Levee_")) .* (1 .-p_breach'), dims = 1)
    return vec(event_damages)
end
"""
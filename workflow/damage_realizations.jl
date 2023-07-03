

include("../../flood-risk-abm/src/base_model.jl")
#Define plot attributes
include("../../flood-risk-abm/src/visual_attrs.jl")

using CSV

function depth_difference(model::ABM, flood_rps; breach_null = 0.45)
    occupied_feet = []
    for rp in flood_rps
        #Calculate flood depth for given return period, store elevations of agents in floodplain
        f_depth = GEV_return(1/rp)
        #Calculate floodplain based on flood return period 
        floodplain = Tuple.(findall(<(f_depth), model.Elevation))
        #Set intial breach values (prob_fail = 0 if breach doesnt occur)
        f_breach = copy(f_depth)
        prob_fail = 0
        #Subtract levee height from flood depth if levee is present
        if model.levee != nothing
            depth_levee = f_depth - GEV_return(model.levee)
            f_depth = depth_levee > 0 ? depth_levee : 0
            #Calculate flood depth if breach occurs
            if model.breach == true
                #calculate breach probability for flood return period
                prob_fail = levee_breach(f_breach, n_null = breach_null)
            end
        end
        #Gather elevations of agents in the floodplain
        damage_agents_elev = [model.Elevation[a.pos[1], a.pos[2]] for a in allagents(model) if a isa Family && a.pos in floodplain]

        ## Subtract Agent Elevation from flood depth at given timestep
        exp_top = f_depth .- damage_agents_elev #overtop exposure
        exp_total = f_breach .- damage_agents_elev #total exposure
        #turn negative values (meaning cell is not flooded) to zero
        exp_top[exp_top .< 0] .= 0
        exp_total[exp_total .< 0] .= 0
  
        ## Calculate total exposure experienced for breach and overtop scenario
        #(return zero if no agents exist in the floodplain)
        cum_exp_top = length(exp_top) > 0 ? sum(exp_top) : 0
        cum_exp_total = length(exp_total) > 0 ? sum(exp_total) : 0

        ### Calculate expected exposure based on likelihood of breaching
        occ_avg = (prob_fail * cum_exp_total) + ((1-prob_fail) * cum_exp_top)
        #Add value to flood_rps
        append!(occupied_feet, occ_avg)
        
    end
    return occupied_feet
end

function depth_sat_difference(model::ABM, flood_rps; breach_null = 0.45)
    """provides analytical curve for a saturated population grid. expected exposure at
    each flood rp can be calculated since agents do not move.Thus, exposure between levee and 
    no levee scenario will be the same. Only applies to ABM models where levee is included"""
    occupied_feet = []
    lev_height = GEV_return(model.levee)
    for rp in flood_rps
    ### Exposure calculation
        ## Calculate flood depth for given return period, store elevations of agents in floodplain
        f_depth = GEV_return(1/rp)
        #Calculate floodplain based on flood return period 
        floodplain = Tuple.(findall(<(f_depth), model.Elevation))
        #Set intial breach values (prob_fail = 0 if breach doesnt occur)
        f_breach = copy(f_depth)
        prob_fail = 0
        #Subtract levee height from flood depth if levee is present
        if model.levee != nothing
            depth_levee = f_depth - lev_height
            f_depth = depth_levee > 0 ? depth_levee : 0
            #Calculate flood depth if breach occurs
            if model.breach == true
                #calculate breach probability for flood return period
                prob_fail = levee_breach(f_breach, n_null = breach_null)
            end
        end
        #Gather elevations of agents in the floodplain
        damage_agents_elev = [model.Elevation[a.pos[1], a.pos[2]] for a in allagents(model) if a isa Family && a.pos in floodplain]

        ## Subtract Agent Elevation from flood depth at given timestep
        exp_top = f_depth .- damage_agents_elev #overtop exposure
        exp_total = f_breach .- damage_agents_elev #total exposure
        #turn negative values (meaning cell is not flooded) to zero
        exp_top[exp_top .< 0] .= 0
        exp_total[exp_total .< 0] .= 0

        ## Calculate total exposure experienced for breach and overtop scenario
        #(return zero if no agents exist in the floodplain)
        cum_exp_top = length(exp_top) > 0 ? sum(exp_top) : 0
        cum_exp_total = length(exp_total) > 0 ? sum(exp_total) : 0

        ### Calculate expected exposure based on likelihood of breaching
        if f_depth < lev_height
            #occ_avg = prob_fail * cum_exp_total #just levee scenario
            occ_avg = (prob_fail - 1) * cum_exp_total #diff bw levee and no levee scenario
            append!(occupied_feet, occ_avg)
        else
            #occ_avg = cum_exp_top + (prob_fail *(cum_exp_total - cum_exp_top)) #just levee scenario
            occ_avg = ((1-prob_fail) * cum_exp_top) + ((prob_fail - 1) * cum_exp_total) #diff bw levee and no levee scenario
            append!(occupied_feet, occ_avg)
        end
        
    end
    return occupied_feet
end


#Multiple seeds
function risk_shift(Elev, seed_range; risk_averse = 0.3, levee = 1/100, breach = true, 
    pop_growth = 0, breach_null = 0.45)
    seed_range = seed_range

    models = [flood_ABM(;Elev = Elev, risk_averse = risk_averse, pop_growth = pop_growth, seed = i) for i in seed_range]
    models_levee = [flood_ABM(;Elev = Elev, risk_averse = risk_averse, levee = levee, breach = breach, pop_growth = pop_growth, seed = i) for i in seed_range]
    #Run models
    _ = ensemblerun!(models, dummystep, combine_step!, 50)
    _ = ensemblerun!(models_levee, dummystep, combine_step!, 50)

    flood_rps = range(10,1000, step = 10)
    #Create matrix to store 
    occupied = zeros(length(flood_rps),length(seed_range))
    occupied_levee = copy(occupied)
    #Calculate depth difference for each model in category
    for i in eachindex(models)
        occupied[:,i] = depth_difference(models[i], flood_rps)
        occupied_levee[:,i] = depth_difference(models_levee[i], flood_rps; breach_null = breach_null)
    end

    #Take difference of two matrices
    occ_diff = occupied_levee - occupied
    #Calculate median and 95% Uncertainty interval
    occ_med = mapslices(x -> median(x), occ_diff, dims=2)
    occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occ_diff, dims=2)
    #Save results to DataFrame
    occ_df = DataFrame(return_period = [ i for i in flood_rps], median = occ_med[:,1], LB = occ_quantiles[:,1], RB = occ_quantiles[:,2])
    return occ_df
end


function risk_sat_shift(Elev, seed_range; risk_averse = 0.3, levee = 1/100, breach = true, 
    pop_growth = 0, breach_null = 0.45)
    """Use with depth_sat_difference function"""
    seed_range = seed_range
    #Only need levee models
    models_levee = [flood_ABM(;Elev = Elev, risk_averse = risk_averse, levee = levee, breach = breach, pop_growth = pop_growth, seed = i) for i in seed_range]
    #Run models
    _ = ensemblerun!(models_levee, agent_step!, model_step!, 50, agents_first = false)

    flood_rps = range(10,1000, step = 10)
    #Create matrix to store 
    occupied_levee = zeros(length(flood_rps),length(seed_range))
    #Calculate depth difference for each model in category
    for i in eachindex(models_levee)
        occupied_levee[:,i] = depth_sat_difference(models_levee[i], flood_rps; breach_null = breach_null)
    end

    #No need to take a difference since depth_sat_difference already
    #returns the expected difference between the levee and no levee scenarios

    #Calculate median and 95% Uncertainty interval
    occ_med = mapslices(x -> median(x), occupied_levee, dims=2)
    occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occupied_levee, dims=2)
    #Save results to DataFrame
    occ_df = DataFrame(return_period = [ i for i in flood_rps], median = occ_med[:,1], LB = occ_quantiles[:,1], RB = occ_quantiles[:,2])
    return occ_df
end
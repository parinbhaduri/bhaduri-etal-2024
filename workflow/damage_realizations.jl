

include("../../flood-risk-abm/src/base_model.jl")
#Define plot attributes
include("../../flood-risk-abm/src/visual_attrs.jl")

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
                prob_fail = levee_breach(f_depth, n_null = breach_null)
            end
        end
        damage_agents_elev = [model.Elevation[a.pos[1], a.pos[2]] for a in allagents(model) if a isa Family && a.pos in floodplain]  
         #Subtract Agent Elevation from flood depth at given timestep
        depth_diff = f_depth .- damage_agents_elev
        depth_breach = f_breach .- damage_agents_elev
        #turn negative values (meaning cell is not flooded) to zero
        depth_diff[depth_diff .< 0] .= 0
        depth_breach[depth_breach .< 0] .= 0

        depth_diff_avg = length(depth_diff) > 0 ? sum(depth_diff) : 0
        depth_breach_avg = length(depth_breach) > 0 ? sum(depth_breach) : 0

        occ_avg = (prob_fail * depth_breach_avg) + ((1-prob_fail) * depth_diff_avg)
        #Add value to flood_rps
        append!(occupied_feet, occ_avg)
        
    end
    return occupied_feet
end
"""
#For single seed, comparing high and low
risk_abm_high = flood_ABM(Elevation)
risk_abm_low = flood_ABM(Elevation; risk_averse = 0.7)

risk_abm_100_high = flood_ABM(Elevation;levee = 1/100, breach = true)
risk_abm_100_low = flood_ABM(Elevation; risk_averse = 0.7, levee = 1/100, breach = true)
#Run models for 50 years
_ = ensemblerun!([risk_abm_high risk_abm_low risk_abm_100_high risk_abm_100_low], agent_step!, model_step!, 50, agents_first = false)

flood_rps = range(10,1000, step = 10)
occupied_high = depth_difference(risk_abm_high, flood_rps)
occupied_high_levee = depth_difference(risk_abm_100_high, flood_rps)

occupied_low = depth_difference(risk_abm_low, flood_rps)
occupied_low_levee = depth_difference(risk_abm_100_low, flood_rps)

occupied_diff_high = occupied_high_levee - occupied_high
occupied_diff_low = occupied_low_levee - occupied_low

Plots.plot(flood_rps, [occupied_diff_high occupied_diff_low], labels = ["high" "low"], xscale = :log10)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")
"""




range(1000,2000, step = 1)

#Multiple seeds
function risk_shift(Elev, seed_range; risk_averse = 0.3, levee = 1/100, breach = true, 
    breach_null = 0.45)
    seed_range = seed_range

    models = [flood_ABM(Elev; risk_averse = risk_averse, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], seed = i) for i in seed_range]
    models_levee = [flood_ABM(Elev; risk_averse = risk_averse, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], levee = levee, breach = breach, seed = i) for i in seed_range]
    #Run models
    _ = ensemblerun!(models, agent_step!, model_step!, 50, agents_first = false)
    _ = ensemblerun!(models_levee, agent_step!, model_step!, 50, agents_first = false)

    flood_rps = range(10,1000, step = 10)
    #Create matrix to store 
    occupied = zeros(length(flood_rps),length(seed_range))
    occupied_levee = copy(occupied)
    for i in eachindex(models)
        occupied[:,i] = depth_difference(models[i], flood_rps)
    end

    for i in eachindex(models_levee)
        occupied_levee[:,i] = depth_difference(models_levee[i], flood_rps; breach_null = breach_null)
    end

    #Take difference of two matrices
    occ_diff = occupied_levee - occupied

    occ_med = mapslices(x -> median(x), occ_diff, dims=2)
    occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occ_diff, dims=2)
    return occ_med, occ_quantiles
end

include("damage_realizations.jl")
"""File used for profiling risk_shift function"""

seed_range = range(1000, 1250, step = 1)
flood_rps = range(10,1000, step = 10)

#run once for compilation
@profview risk_shift(Elevation, range(1000, 1002, step = 1))
#Check runtime
@profview risk_shift(Elevation, seed_range)





### Benchmark risk-shift
using BenchmarkTools, TimerOutputs
tmr = TimerOutput()

function test_shift(Elev, seed_range; risk_averse = 0.3, levee = 1/100, breach = true, 
    pop_growth = 0, breach_null = 0.45)
    seed_range = seed_range

    @timeit tmr "model initialization" begin 
        models = [flood_ABM(Elev; risk_averse = risk_averse, pop_growth = pop_growth, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], seed = i) for i in seed_range]
        models_levee = [flood_ABM(Elev; risk_averse = risk_averse, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], levee = levee, breach = breach, pop_growth = pop_growth, seed = i) for i in seed_range]
    end
    #Run models
    @timeit tmr "model runs" begin 
        _ = ensemblerun!([models models_levee], dummystep, combine_step!, 50, agents_first = false)
        #_ = ensemblerun!(models_levee, agent_step!, model_step!, 50, agents_first = false)
    end

    @timeit tmr "depth difference" begin
        flood_rps = range(10,1000, step = 10)
        #Create matrix to store 
        occupied = zeros(length(flood_rps),length(seed_range))
        occupied_levee = copy(occupied)
        #Calculate depth difference for each model in category
        for i in eachindex(models)
            occupied[:,i] = depth_difference(models[i], flood_rps)
            occupied_levee[:,i] = depth_difference(models_levee[i], flood_rps; breach_null = breach_null)
        end
    end

    @timeit tmr "quantile calc" begin
        #Take difference of two matrices
        occ_diff = occupied_levee - occupied
        #Calculate median and 95% Uncertainty interval
        occ_med = mapslices(x -> median(x), occ_diff, dims=2)
        occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occ_diff, dims=2)
        #Save results to DataFrame
        occ_df = DataFrame(return_period = [ i for i in flood_rps], median = occ_med[:,1], LB = occ_quantiles[:,1], RB = occ_quantiles[:,2])
    end

    return occ_df
end

#Time individual sections within function
test_shift(Elevation, seed_range)
show(tmr)
reset_timer!(tmr)
#scalability
for n in [1010, 1050, 1250, 1750]
    seed_range = range(1000, n, step = 1)
    println("iterations: $(n-1000) ")
    @btime test_shift($Elevation, $seed_range)
end


#activate project environment
using Pkg
Pkg.activate(dirname(@__DIR__))
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(dirname(@__DIR__), "workflow/toy_model/src/parallel_setup.jl"))

## Look at individual cumulative exposure curves
seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)

models = [flood_ABM(;Elev = Elevation, seed = i) for i in seed_range]
models_levee = [flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, seed = i) for i in seed_range]
#Run models
_ = ensemblerun!(models, dummystep, combine_step!, 50)#, parallel = true)
_ = ensemblerun!(models_levee, dummystep, combine_step!, 50)#, parallel = true)

#Try parallel evolution
#occupied = zeros(length(flood_rps),length(seed_range))
#occupied_levee = copy(occupied)

progress = Agents.ProgressMeter.Progress(length(models)*2; enabled = true)
final_models = Agents.ProgressMeter.progress_pmap(models, models_levee) do model, model_levee
    step!.([model model_levee], dummystep, combine_step!, 50)
    occ = depth_difference(model, flood_rps)
    occ_lev = depth_difference(model_levee, flood_rps)
    return occ, occ_lev
end

occupied, occupied_levee = reduce.(hcat, map(x->getindex.(final_models,x), 1:2))
#Create matrix to store 
occupied = zeros(length(flood_rps),length(seed_range))
occupied_levee = copy(occupied)
#Calculate depth difference for each model in category

for i in 1:length(seed_range)
    occupied[:,i] = depth_difference(final_models[i,1], flood_rps)
    occupied_levee[:,i] = depth_difference(final_models[i,2], flood_rps)
end

#Take difference of two matrices
occ_diff = occupied_levee - occupied
#Calculate median and 95% Uncertainty interval
occ_med = mapslices(x -> median(x), occ_diff, dims=2)
occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occ_diff, dims=2)
#Save results to DataFrame
occ_df = DataFrame(return_period = collect(flood_rps), median = occ_med[:,1], LB = occ_quantiles[:,1], RB = occ_quantiles[:,2])

threshold = zeros(length(flood_rps))
breach_averse = Plots.plot(occ_df[:, "return_period"], occ_df.median, lw = 2.5, xscale = :log10, 
xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_df[:, "return_period"], occ_df.LB, fillrange= occ_df.RB,
 linecolor = "blue", fillcolor = "blue", fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

#Calculate Risk Shifting integral
RSI = sum(occupied_levee .* (1 ./ collect(flood_rps)), dims = 1) ./ sum(occupied .* (1 ./ collect(flood_rps)), dims = 1)

#Plot RSIs
using StatsPlots

Plots.boxplot(repeat(["high"],1001), RSI', legend = false)


occ_med = mapslices(x -> median(x), occupied, dims=2)
occ_med_levee = mapslices(x -> median(x), occupied_levee, dims=2)

Plots.plot(collect(flood_rps), [occ_med occ_med_levee], xscale = :log10, labels = ["no levee (high)" "levee (high)"])



models_low = [flood_ABM(;Elev = Elevation, risk_averse = 0.7, seed = i) for i in seed_range]
models_levee_low = [flood_ABM(;Elev = Elevation, risk_averse = 0.7, levee = 1/100, breach = true, seed = i) for i in seed_range]
#Run models
_ = ensemblerun!(models_low, dummystep, combine_step!, 50)
_ = ensemblerun!(models_levee_low, dummystep, combine_step!, 50)

flood_rps = range(10,1000, step = 10)
#Create matrix to store 
occupied_low = zeros(length(flood_rps),length(seed_range))
occupied_levee_low = copy(occupied)
#Calculate depth difference for each model in category
for i in eachindex(models_low)
    occupied_low[:,i] = depth_difference(models_low[i], flood_rps)
    occupied_levee_low[:,i] = depth_difference(models_levee_low[i], flood_rps)
end

occ_med_low = mapslices(x -> median(x), occupied_low, dims=2)
occ_med_levee_low = mapslices(x -> median(x), occupied_levee_low, dims=2)

Plots.plot!(collect(flood_rps), [occ_med_low occ_med_levee_low], xscale = :log10, labels = ["no levee (low)" "levee (low)"])


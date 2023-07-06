#Compares risk shifting properties between low risk and high risk aversion populations
include("damage_realizations.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#high risk aversion
occ_high = risk_shift(Elevation, seed_range)
occ_low = risk_shift(Elevation, seed_range; risk_averse = 0.7)

#Join two dataframes and savefig
occ_high[!, "group"] .= "high"
occ_low[!, "group"] .= "low"

occ_averse = vcat(occ_high,occ_low)

#Save/open dataframe
#CSV.write("workflow/dataframes/occ_averse.csv", occ_averse)
occ_averse = DataFrame(CSV.File("workflow/dataframes/occ_averse.csv"))


threshold = zeros(length(flood_rps))
#Plot results
breach_averse = Plots.plot(occ_averse[:, "return_period"], occ_averse.median, group = occ_averse.group, lw = 2.5, xscale = :log10, 
xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_averse[:, "return_period"], occ_averse.LB, fillrange= occ_averse.RB, group = occ_averse.group,
 linecolor = ["blue" "orange"], fillcolor = ["blue" "orange"], fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

savefig(breach_averse, "figures/breach_averse.svg")





### Look at individual cumulative exposure curves

models = [flood_ABM(;Elev = Elevation, seed = i) for i in seed_range]
models_levee = [flood_ABM(;Elev = Elevation, levee = 1/100, breach = true, seed = i) for i in seed_range]
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
    occupied_levee[:,i] = depth_difference(models_levee[i], flood_rps)
end

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
include("damage_realizations.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Model with population growth
occ_pop_05 = risk_shift(Elevation, seed_range; pop_growth = 0.005)
occ_pop_1 = risk_shift(Elevation, seed_range; pop_growth = 0.01)
occ_pop_2 = risk_shift(Elevation, seed_range; pop_growth = 0.02)
occ_pop_5 = risk_shift(Elevation, seed_range; pop_growth = 0.05)



#Join two dataframes and savefig
occ_pop_05[!, "group"] .= 0.5
occ_pop_1[!, "group"] .= 1.0
occ_pop_2[!, "group"] .= 2.0
occ_pop_5[!, "group"] .= 5.0

occ_pop = vcat(occ_pop_05,occ_pop_1,occ_pop_2,occ_pop_5)

#Save/open dataframe
#CSV.write("workflow/dataframes/occ_pop.csv", occ_pop)
occ_pop = DataFrame(CSV.File("workflow/dataframes/occ_pop.csv"))

threshold = zeros(length(flood_rps))
#Plot results
breach_pop = Plots.plot(occ_pop[:, "return_period"], occ_pop.median, group = occ_pop.group, linecolor = ["blue" "orange" "green" "purple"],
lw = 2.5, xscale = :log10, xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_pop[:, "return_period"], occ_pop.LB, fillrange= occ_pop.RB, group = occ_pop.group,
 linecolor = ["blue" "orange" "green" "purple"], fillcolor = ["blue" "orange" "green" "purple"], fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")


savefig(breach_pop, "figures/breach_pop.svg")



pop_mod = flood_ABM(Elevation; risk_averse = 0.3, pop_growth = 0.0075)
run!(pop_mod, agent_step!, model_step!, 50, agents_first = false)




#Test risk shift behavior on saturated grid
seed_range = range(10, 20, step = 1)
flood_rps = range(10,1000, step = 10)
#analytical process
occ_pop_5 = risk_shift(Elevation, seed_range; pop_growth = 0.01)
occ_pop_5_sat = risk_sat_shift(Elevation, seed_range; pop_growth = 0.05)

occ_pop_5[!, "group"] .= "original"
occ_pop_5_sat[!, "group"] .= "analytical"

occ_pop = vcat(occ_pop_5, occ_pop_5_sat)

threshold = zeros(length(flood_rps))
#Plot results
breach_pop = Plots.plot(occ_pop[:, "return_period"], occ_pop.median, group = occ_pop.group, linecolor = ["blue" "orange"],
lw = 2.5, xscale = :log10, xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_pop[:, "return_period"], occ_pop.LB, fillrange= occ_pop.RB, group = occ_pop.group,
 linecolor = ["blue" "orange" "green" "purple"], fillcolor = ["blue" "orange"], fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")



### Compare levee exposures   
models_levee = [flood_ABM(Elevation; risk_averse = 0.3, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], pop_growth = 0.05, seed = i) for i in seed_range] #really no levee
#models_levee = [flood_ABM(Elevation; risk_averse = 0.3, flood_depth = [GEV_event(MersenneTwister(i)) for _ in 1:100], levee = 1/100, breach = true, pop_growth = 0.05, seed = i) for i in seed_range]
#Run models
   
_ = ensemblerun!(models_levee, agent_step!, model_step!, 50, agents_first = false)

#Create matrix to store 
occupied_levee = zeros(length(flood_rps),length(seed_range))
   
#Calculate depth difference for each model in category
for i in eachindex(models_levee)
    occupied_levee[:,i] = depth_difference(models_levee[i], flood_rps)
end

#Calculate median and 95% Uncertainty interval
occ_med = mapslices(x -> median(x), occupied_levee, dims=2)
occ_quantiles = mapslices(x -> quantile(x, [0.025, 0.975]), occupied_levee, dims=2)
#Save results to DataFrame
occ_pop_5_levee = DataFrame(return_period = [ i for i in flood_rps], median = occ_med[:,1], LB = occ_quantiles[:,1], RB = occ_quantiles[:,2])

occ_pop_5_sat_levee = risk_sat_shift(Elevation, seed_range; pop_growth = 0.05) #uncomment levee calculations in depth_sat_difference

occ_pop_5_levee[!, "group"] .= "original"
occ_pop_5_sat_levee[!, "group"] .= "analytical"

occ_pop_levee = vcat(occ_pop_5_levee, occ_pop_5_sat_levee)

threshold = zeros(length(flood_rps))
#Plot results
breach_pop = Plots.plot(occ_pop_levee[:, "return_period"], occ_pop_levee.median, group = occ_pop_levee.group, linecolor = ["blue" "orange"],
lw = 2.5, xscale = :log10, xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")


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
#occ_pop = DataFrame(CSV.File("workflow/dataframes/occ_pop.csv"))

threshold = zeros(length(flood_rps))
#Plot results
Plots.plot(occ_pop[:, "return_period"], occ_pop.median, group = occ_pop.group, linecolor = ["blue" "orange" "green" "purple"],
lw = 2.5, xscale = :log10, xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_pop[:, "return_period"], occ_pop.LB, fillrange= occ_pop.RB, group = occ_pop.group,
 linecolor = ["blue" "orange" "green" "purple"], fillcolor = ["blue" "orange" "green" "purple"], fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")


savefig(breach_pop, "figures/breach_pop.svg")


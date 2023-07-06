include("damage_realizations.jl")
## Create Elevation Matrix for study area:
grid_length = 44

basin_flat = range(0, 10, length = Int64(grid_length/2))
basin_steep = range(0, 50, length = Int64(grid_length/2))

Elev_flat = zeros(grid_length, grid_length).+ [reverse(basin_flat); basin_flat]
Elev_steep = zeros(grid_length, grid_length).+ [reverse(basin_steep); basin_steep]


seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#high risk aversion
occ_flat = risk_shift(Elev_flat, seed_range)
occ_base = risk_shift(Elevation, seed_range)
occ_steep = risk_shift(Elev_steep, seed_range)

#Join two dataframes and savefig
occ_flat[!, "group"] .= "flat"
occ_base[!, "group"] .= "base"
occ_steep[!, "group"] .= "steep"

occ_elev = vcat(occ_flat, occ_base, occ_steep)

#Save/open dataframe
CSV.write("workflow/dataframes/occ_elev.csv", occ_elev)
#occ_elev = DataFrame(CSV.File("workflow/dataframes/occ_elev.csv"))


threshold = zeros(length(flood_rps))
#Plot results
breach_elev = Plots.plot(occ_elev[:, "return_period"], occ_elev.median, group = occ_elev.group, linecolor = ["blue" "orange" "green"],
lw = 2.5, xscale = :log10, xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_elev[:, "return_period"], occ_elev.LB, fillrange= occ_elev.RB, group = occ_elev.group,
 linecolor = ["blue" "orange" "green"], fillcolor = ["blue" "orange" "green"], fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

using Gadfly

init_theme = Gadfly.Theme(background_color = "white", grid_color = "white")

Gadfly.with_theme(init_theme) do 
    Gadfly.plot(occ_elev, x = :return_period, y = :median, ymax=:RB, ymin=:LB, color = :group, 
    Geom.line, Geom.ribbon, alpha = [0.35], Guide.xlabel("Return Period (Years)"),
    Guide.ylabel("Difference in Occupied in Exposure"), Scale.x_log10(labels = x -> mod(x,1) == 0 ? "$(10^x)" : ""), Scale. y_continuous(format=:plain))
end

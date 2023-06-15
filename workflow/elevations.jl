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
occ_high[!, "group"] .= "high"
occ_low[!, "group"] .= "low"

occ_averse = vcat(occ_high,occ_low)

#Save/open dataframe
CSV.write("workflow/dataframes/occ_averse.csv", occ_averse)
#occ_averse = DataFrame(CSV.File("workflow/dataframes/occ_averse.csv"))
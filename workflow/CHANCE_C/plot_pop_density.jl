#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Plots, StatsPlots
using ColorSchemes

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt.csv")))

transform!(adf, [:sum_population_f_bgs, :sum_pop90_f_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :flood_pop_change)
                
transform!(adf, [:sum_population_nf_bgs, :sum_pop90_nf_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :nf_pop_change)

#Select rows corresponding with the final model step 
filter!(row -> (row.step == 50), adf)

#Subset dataframes by scenario
adf_high = subset(adf, :risk_averse => ByRow(isequal(0.3)), :slr => ByRow(isequal(false)))
adf_high_slr = subset(adf, :risk_averse => ByRow(isequal(0.3)), :slr => ByRow(isequal(true)))

#adf_base_high = subset(adf_base, :risk_averse => ByRow(isequal(0.3)))
#adf_base_low = subset(adf_base,  :risk_averse => ByRow(isequal(0.7)))


adf_low = subset(adf, :risk_averse => ByRow(isequal(0.7)), :slr => ByRow(isequal(false)))
adf_low_slr = subset(adf, :risk_averse => ByRow(isequal(0.7)), :slr => ByRow(isequal(true)))

#adf_levee_high = subset(adf_levee, :risk_averse => ByRow(isequal(0.3)))
#adf_levee_low = subset(adf_levee, :risk_averse => ByRow(isequal(0.7)))

## Create density plots
dfs = [adf_high, adf_high_slr, adf_low, adf_low_slr]
labels = ["No SLR, High RA", "SLR, High RA", "No SLR, Low RA", "SLR, Low RA"]

p = Plots.plot(layout=(2, 2), dpi = 300, size = (900,600))

for i in eachindex(dfs)
    df_base = subset(dfs[i],:levee => ByRow(isequal(false)))
    df_levee = subset(dfs[i],:levee => ByRow(isequal(true)))
    density!(p[i], df_base.sum_population_f_bgs, label="Baseline")
    density!(p[i], df_levee.sum_population_f_bgs, label = "Levee")
    Plots.title!(p[i], labels[i])
end

Plots.ylabel!(p[1], "Density")
Plots.ylabel!(p[3], "Density")
Plots.xlabel!(p[3], "Floodplain Population")
Plots.xlabel!(p[4], "Floodplain Population")

display(p)

savefig(p, joinpath(pwd(),"figures/final_pop_dens.png"))
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Plots, StatsPlots
using Plots.PlotMeasures
using ColorSchemes

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt_city.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt_city.csv")))

transform!(adf, [:sum_population_f_c_bgs, :sum_pop90_f_c_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :flood_pop_change)
                
transform!(adf, [:sum_population_nf_c_bgs, :sum_pop90_nf_c_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :nf_pop_change)

#Select rows corresponding with the final model step 
filter!(row -> (row.step == 50), adf)

#Subset dataframes by scenario
adf_high_slr_high = subset(adf, :risk_averse => ByRow(isequal(0.3)), :slr_scen => ByRow(isequal("high")))
adf_high_slr_med = subset(adf, :risk_averse => ByRow(isequal(0.3)), :slr_scen => ByRow(isequal("medium")))
adf_high_slr_low = subset(adf, :risk_averse => ByRow(isequal(0.3)), :slr_scen => ByRow(isequal("low")))

#adf_base_high = subset(adf_base, :risk_averse => ByRow(isequal(0.3)))
#adf_base_low = subset(adf_base,  :risk_averse => ByRow(isequal(0.7)))


adf_low_slr_high = subset(adf, :risk_averse => ByRow(isequal(0.7)), :slr_scen => ByRow(isequal("high")))
adf_low_slr_med = subset(adf, :risk_averse => ByRow(isequal(0.7)), :slr_scen => ByRow(isequal("medium")))
adf_low_slr_low = subset(adf, :risk_averse => ByRow(isequal(0.7)), :slr_scen => ByRow(isequal("low")))

#adf_levee_high = subset(adf_levee, :risk_averse => ByRow(isequal(0.3)))
#adf_levee_low = subset(adf_levee, :risk_averse => ByRow(isequal(0.7)))

## Create density plots
dfs = [adf_high_slr_low, adf_low_slr_low, adf_high_slr_med, adf_low_slr_med, adf_high_slr_high, adf_low_slr_high]
labels = ["Low SLR, High RA", "Low SLR, Low RA", "Medium SLR, High RA", "Medium SLR, Low RA", "High SLR, High RA", "High SLR, Low RA"]

p = Plots.plot(size = (1000, 750), layout=(3, 2), dpi = 300)

for i in eachindex(dfs)
    df_base = subset(dfs[i],:levee => ByRow(isequal(false)))
    df_levee = subset(dfs[i],:levee => ByRow(isequal(true)))
    histogram!(p[i], df_base.sum_population_f_c_bgs, alpha = 0.5, ticks = nothing, label="No Levee",
     legend_foreground_color = :transparent, left_margin = 5mm, bottom_margin = 5mm)
    histogram!(p[i], df_levee.sum_population_f_c_bgs, alpha = 0.5, ticks = nothing, label = "Levee")
    Plots.ylabel!(p[i], "Count"; yguidefontsize=10)
    Plots.xlabel!(p[i], "Floodplain Population"; xguidefontsize=10)
    #density!(p[i], df_base.sum_population_f_bgs, label="Baseline")
    #density!(p[i], df_levee.sum_population_f_bgs, label = "Levee")
    Plots.title!(p[i], labels[i])
end

display(p)

savefig(p, joinpath(pwd(),"figures/final_pop_dens.png"))
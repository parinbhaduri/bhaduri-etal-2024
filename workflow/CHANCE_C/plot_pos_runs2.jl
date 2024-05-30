## Assess the evolution of model realizations where risk transference is observed.
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Plots, StatsPlots
using ColorSchemes

##load damage data
## Read in dataframes
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

event_size = collect(range(0.75, 4.0, step = 0.25))
seed_range = collect(range(1000,1999, step = 1))

#Calculate scenario difference and determine seeds that show risk trensference
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 
pos_seeds = seed_range[findall(i ->(i>0), diff_dam[end,:])]

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt_city.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt_city.csv")))

filter!(row -> !(row.step == 0), mdf)
filter!(row -> (row.step == 50), adf)

subset!(adf, :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))
subset!(mdf, :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

#Select model realization to highlight in plots
adf_pos = filter(:seed => in(pos_seeds), adf)
mdf_pos = filter(:seed => in(pos_seeds), mdf)

adf_neg = filter(:seed => !in(pos_seeds), adf)
mdf_neg = filter(:seed => !in(pos_seeds), mdf)

#Subset dataframes by scenario
adf_base_pos = subset(adf_pos, :levee => ByRow(isequal(false)))
mdf_base_pos = subset(mdf_pos, :levee => ByRow(isequal(false)))

adf_levee_pos = subset(adf_pos, :levee => ByRow(isequal(true)))
mdf_levee_pos = subset(mdf_pos, :levee => ByRow(isequal(true)))

adf_base_neg = subset(adf_neg, :levee => ByRow(isequal(false)))
mdf_base_neg = subset(mdf_neg, :levee => ByRow(isequal(false)))

adf_levee_neg = subset(adf_neg, :levee => ByRow(isequal(true)))
mdf_levee_neg = subset(mdf_neg, :levee => ByRow(isequal(true)))

p = Plots.plot(layout=(2, 1), dpi = 300)

pop_diff_pos = adf_levee_pos.sum_population_f_c_bgs - adf_base_pos.sum_population_f_c_bgs
pop_diff_neg = adf_levee_neg.sum_population_f_c_bgs - adf_base_neg.sum_population_f_c_bgs

histogram!(p[1], pop_diff_pos, alpha = 0.5, label="Positive Seeds",
 left_margin = 5mm, bottom_margin = 5mm)

histogram!(p[1], pop_diff_neg, alpha = 0.5, label="Remaining Seeds",
 left_margin = 5mm, bottom_margin = 5mm)

#Plots.ylabel!(p[1], "Count"; yguidefontsize=10)
#Plots.xlabel!(p[1], "Floodplain Population"; xguidefontsize=10)
#Plots.title!(p[i], labels[i])

price_diff_pos = adf_levee_pos.mean_new_price_f_c_bgs - adf_base_pos.mean_new_price_f_c_bgs
price_diff_neg = adf_levee_neg.mean_new_price_f_c_bgs - adf_base_neg.mean_new_price_f_c_bgs

histogram!(p[2], price_diff_pos, alpha = 0.5, label="Positive Seeds",
 left_margin = 5mm, bottom_margin = 5mm)

histogram!(p[2], price_diff_neg, alpha = 0.5, label="Remaining Seeds",
 left_margin = 5mm, bottom_margin = 5mm)
display(p)


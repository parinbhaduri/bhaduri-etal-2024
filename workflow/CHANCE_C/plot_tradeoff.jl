#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CHANCE_C
using CSV, DataFrames
using Statistics, StatsBase
using CairoMakie
using FileIO


## Read in dataframes
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

event_size = collect(range(0.75, 4.0, step = 0.25))
seed_range = collect(range(1000,1999, step = 1))

#Calculate scenario difference and determine seeds that show risk trensference
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 
pos_seeds = findall(i ->(i>0), diff_dam[end,:])

value = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/total_val_default.csv")))
val_pos = value[pos_seeds, :]

val_diff = value[:,"levee"] - value[:,"base"]
val_diff_pos = val_pos[:,"levee"] - val_pos[:,"base"]


## Calculate residual risk across realizations

event_size = collect(range(0.75, 4.0, step = 0.25))
#Define Function to calculate return period from return level
function GEV_rp(z_p, mu = μ, sig = σ, xi = ξ)
    y_p = 1 + (xi * ((z_p - mu)/sig))
    rp = -exp(-y_p^(-1/xi)) + 1
    rp = round(rp, digits = 3)
    return 1/rp
end

#Extract params from GEV distribution calibrated to Baltimore
mu, sig, xi =  StatsBase.params(CHANCE_C.default_gev)

#Calculate prob of occurrence of surge events from GEV distribution
surge_rp = 1 ./ GEV_rp.(event_size, Ref(mu), Ref(sig), Ref(xi))

base_risk = surge_rp' * Matrix(base_dam)
levee_risk = surge_rp' * Matrix(levee_dam)

resid_risk = levee_risk .- base_risk
resid_pos = resid_risk[pos_seeds]


## Plot results
val_fig = Figure(size = (900,600), fontsize = 16, pt_per_unit = 1, figure_padding = 10)

ax1 = Axis(val_fig[1, 1], ylabel = "Residual Risk", xlabel = "Difference in Value",limits = (nothing, nothing),
 xgridvisible = false, titlealign = :center, title = "Comparing Residual Risk and Economic Gain")

CairoMakie.scatter!(ax1, val_diff, vec(resid_risk), color = "blue")
 #, label = false)
CairoMakie.scatter!(ax1, val_diff_pos, vec(resid_pos), color = "orange")

display(val_fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_risk_value.png"), val_fig)

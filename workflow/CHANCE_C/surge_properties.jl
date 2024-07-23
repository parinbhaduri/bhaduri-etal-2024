#Find Parameters
import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Extremes
using Plots

dat_annmax = DataFrame(CSV.File(joinpath(dirname(pwd()), "baltimore-data/model_inputs", "balt_tide.csv")))

fm = gevfit(dat_annmax, :residual)

params(fm)

diagnosticplots(fm)

dense_plot = histplot(fm)

#using Gadfly, Cairo, Fontconfig

#image = PNG("gev_hist_balt.png",6inch,4inch)
#draw(image, dense_plot)





## Determine Return Levels from GEV 
return_periods = collect(range(10,1000,step=10))

return_levels = [returnlevel.(Ref(fm), rp).value[] for rp in return_periods]

ret_level_plt = plot(return_periods, return_levels, xticks = 0:100:1000, yticks = 0:0.25:4, lw = 2.5, legend = false, dpi = 300)
xaxis!(ret_level_plt, "Return period (years)")
yaxis!(ret_level_plt, "Return level (meters)")

savefig(ret_level_plt, "ret_level_plt.png")

##Create histogram to see what bins GEV samples would fill
GEV_d = GeneralizedExtremeValue(location(fm)[1], Extremes.scale(fm)[1], shape(fm)[1])

#Sample from GEV and return flood depth 
function GEV_event(rng;
    d = GEV_d) #input GEV distribution 
    flood_depth = rand(rng, d)
    return flood_depth
end

#Group flood depths into regular intervals
round_step(x, step) = round(x / step) * step

#Define Function to calculate return period from return level
function GEV_rp(z_p, mu = μ, sig = σ, xi = ξ)
    y_p = 1 + (xi * ((z_p - mu)/sig))
    rp = -exp(-y_p^(-1/xi)) + 1
    rp = round(rp, digits = 3)
    return 1/rp
end

gev_rng = MersenneTwister(1897)
flood_record = [GEV_event(gev_rng) for _ in 1:1000]
# Sea Level Rise
#high scenario of SL change projection for 2031 is 0.28m and 2.57m for 2130 (NOAA)
high_slr = repeat([0.023 * i for i in 1:50], 20)
slr_record = flood_record .+ high_slr

#Count number of occurences of each surge event  
surge_freq = hcat([[i, count(==(i), round_step.(flood_record,0.25))] for i in unique(round_step.(flood_record,0.25))]...)
surge_freq_slr = hcat([[i, count(==(i), round_step.(slr_record,0.25))] for i in unique(round_step.(slr_record,0.25))]...)

surge_interval = bar(surge_freq[1,:], surge_freq[2,:], alpha = 0.5, label = "Surge", legend = :outerright, dpi = 300)
bar!(surge_freq_slr[1,:], surge_freq_slr[2,:], alpha = 0.5, label = "Surge w/ SLR")
#title!("Surge Frequencies at 0.25m intervals")
#savefig(surge_interval, "surge_interval.png")

xaxis!(surge_interval, "Surge Level (meters)")
yaxis!(surge_interval, "Frequency")
vline!([returnlevel(fm, 100).value[]], lw = 2.5, label = "100-Year Event")
vline!([2.804], lw = 2.5, label = "Sea Wall Height")
#title!("Surge Frequencies at 0.25m intervals")

savefig(surge_interval, "surge_interval.png")
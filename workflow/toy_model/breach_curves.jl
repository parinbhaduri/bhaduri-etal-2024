#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Plots
#Levee Breach Probability surface
#import breach functions from toy model
include(joinpath(@__DIR__, "src/toy_ABM_functions.jl"))

water_level = [n for n in range(0,15,step=0.1)]

levee_fail_low = levee_breach.(water_level, n_null = 0.35)
levee_fail = levee_breach.(water_level)
levee_fail_high = levee_breach.(water_level, n_null = 0.50)

breach_curve = Plots.plot(water_level, [levee_fail_low levee_fail levee_fail_high],
 label = ["low breach likelihood" "base breach likelihood" "high breach likelihood"],
 legend = :outerbottom, legendcolumns = 3, legend_foreground_color = :transparent, lw = 2.5, dpi = 300)
Plots.xlabel!("Flood Depth (feet)")
Plots.ylabel!("Levee Failure Probability")

#cgrad([colorant"#0A9396", colorant"#E9D8A6", colorant"#BB3E03"], [0.3,0.4])

savefig(breach_curve, joinpath(pwd(),"figures/breach_func.png"))


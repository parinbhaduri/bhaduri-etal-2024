#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

#Levee Breach Probability surface
#import breach functions from toy model
include(joinpath(dirname(@__DIR__), "src/toy_ABM_functions.jl"))

water_level = [n for n in range(0,15,step=0.1)]

levee_fail_low = levee_breach.(water_level, n_null = 0.35)
levee_fail = levee_breach.(water_level)
levee_fail_high = levee_breach.(water_level, n_null = 0.50)

Plots.plot(water_level, levee_fail, label = false, lw = 2.5)
Plots.xlabel!("Flood Depth")
Plots.ylabel!("Failure Probability")

cgrad([colorant"#0A9396", colorant"#E9D8A6", colorant"#BB3E03"], [0.3,0.4])

dirname(pwd())
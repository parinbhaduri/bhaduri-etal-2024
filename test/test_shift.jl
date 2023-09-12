###Cases to test Risk Shifting index calculation
include("../workflow/damage_realizations.jl")


#test integral calculation for known integral curves
flood_rps = range(10,1000, step = 10)
x = collect(flood_rps)

model = flood_ABM(;Elev = Elevation, risk_averse = 0.7, seed = 1999) 
model_levee = flood_ABM(;Elev = Elevation, risk_averse = 0.7, levee = 1/100, breach = true, seed = 1999)
step!.([model model_levee], dummystep, combine_step!, 50)

occ = depth_difference(model, flood_rps)
occ_lev = depth_difference(model_levee, flood_rps)

#Plot Exposure curves
Plots.plot(x, [occ, occ_lev], xscale = :log10, labels = ["no levee" "levee"])
#Plot Difference
Plots.plot(x, occ_lev - occ, xscale = :log10, labels = false)

#Plot Final Model states
risk_fig, ax, abmobs = abmplot(model; plotkwargs...)
#Change resolution of scene
resize!(risk_fig.scene, (1450,1450))
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)
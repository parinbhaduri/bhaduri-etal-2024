###Cases to test Risk Shifting index calculation
include("../workflow/damage_realizations.jl")


#test integral calculation for known integral curves
flood_rps = range(10,1000, step = 10)
x = collect(flood_rps)
weights = 1 ./ collect(flood_rps)


model = flood_ABM(;Elev = Elevation, risk_averse = 0.7, seed = 1999) 
model_levee = flood_ABM(;Elev = Elevation, risk_averse = 0.7, levee = 1/100, breach = true, seed = 1999)
step!.([model model_levee], dummystep, combine_step!, 50)
#step!(model, dummystep, combine_step!, 50)

occ = depth_difference(model, flood_rps)
occ_lev = depth_difference(model_levee, flood_rps)

#alter values to create more pronounced difference
#occ[1:10] .= 1000
#occ_lev[80:100].= 15000

#Plot Exposure curves
Plots.plot(x, [occ, occ_lev], xscale = :log10, labels = ["no levee" "levee"])
#Plot weighted exposure curves
Plots.plot(x, [occ .* weights, occ_lev .* weights], xscale = :log10, labels = ["no levee (weighted)" "levee (weighted)"])
#Plot Difference
Plots.plot(x, occ_lev - occ, xscale = :log10, labels = false)


#Calculate RSI
log(sum(occ_lev .* (1 ./ collect(flood_rps))) / sum(occ .* (1 ./ collect(flood_rps))))



#Plot Final Model states
risk_fig, ax, abmobs = abmplot(model_levee; plotkwargs...)
#Change resolution of scene
resize!(risk_fig.scene, (1550,1550))
colsize!(risk_fig.layout, 1, Aspect(1, 1.0))
display(risk_fig)

#for No Levee

sum_first_10 = sum(occ[1:10] .* weights[1:10])
sum_rest = sum(occ[11:100] .* weights[11:100])

sum_first_10_l = sum(occ_lev[1:10] .* weights[1:10])
sum_rest_l = sum(occ_lev[11:100] .* weights[11:100])
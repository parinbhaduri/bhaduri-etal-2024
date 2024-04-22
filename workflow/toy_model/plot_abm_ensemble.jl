#activate project environment
using Pkg
Pkg.activate(dirname(dirname(@__DIR__)))
Pkg.instantiate()

#Read in ABM ensemble evolution data
adf_base = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/adf_base.csv")))
mdf_base = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/mdf_base.csv")))

adf_levee = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/adf_levee.csv")))
mdf_levee = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/mdf_levee.csv")))

#Select one model realization to highlight in plots
adf_show = filter(:seed => isequal(1897), adf_base)
mdf_show = filter(:seed => isequal(1897), mdf)_base

adf_show_levee = filter(:seed => isequal(1897), adf_levee)
mdf_show_levee = filter(:seed => isequal(1897), mdf_levee)


##Plot Baseline Results

#plot agents deciding to move
agent_plot = Plots.plot(adf.step, adf.count_action_fam, group = adf.risk_averse, label = false, linecolor = [colorant"#0A9396" colorant"#CA6702"], alpha = 0.35, lw = 1, tickfontsize = 10)

Plots.plot!(adf_show.step, adf_show.count_action_fam, group = adf_show.risk_averse, label = ["high RA" "low RA"], 
 linecolor = [colorant"#0A9396" colorant"#CA6702"],
legend = :outerright, legendfontsize = 16, foreground_color_legend=nothing,background_color_legend=nothing, lw = 3)
Plots.ylims!(0,300)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot = Plots.plot(adf.step, adf.count_floodplain_fam, group = adf.risk_averse, label = false, linecolor = [colorant"#0A9396" colorant"#CA6702"], alpha = 0.35, lw = 1, tickfontsize = 10)

Plots.plot!(adf_show.step, adf_show.count_floodplain_fam, group = adf_show.risk_averse, label = ["high RA" "low RA"], 
legend = :outerright, legendfontsize = 16, foreground_color_legend=nothing,background_color_legend=nothing, linecolor = [colorant"#0A9396" colorant"#CA6702"], lw = 3)
#Plots.ylabel!("Floodplain Pop.", pointsize = 28)
Plots.ylims!(0,500)
#Plots.xlabel!("Year", pointsize = 28)

#plot flood depths
model_plot = Plots.plot(mdf.step[1:51051], mdf.floodepth[1:51051], legend = false, label = false, linecolor = :gray, alpha = 0.35, lw = 1,tickfontsize = 10)
Plots.plot!(mdf_show.step[1:51], mdf_show.floodepth[1:51], legend = false, label = false, linecolor = colorant"#005F73", lw = 3)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(mdf_show.step[1:51],flood_100, line = :dash, legend = :outerright, legendfontsize = 12, foreground_color_legend=nothing, label = "100-year level", linecolor = colorant"#001219", lw = 3)
#annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,40)
#Plots.ylabel!("Flood Depth", pointsize = 28)

#create subplot
averse_real = Plots.plot(model_plot, agent_plot, fp_plot, layout = (3,1), dpi = 300, size = (800,800))

savefig(averse_real, "test/Test_visuals/paramscan_averse_realizations.svg")


##Plot Levee Scenario Results

#plot agents deciding to move
agent_plot_levee = Plots.plot(adf_levee.step, adf_levee.count_action_fam, group = adf_levee.risk_averse, label = false, linecolor = [colorant"#0A9396" colorant"#CA6702"], alpha = 0.35, lw = 1, tickfontsize = 10)

Plots.plot!(adf_show_levee.step, adf_show_levee.count_action_fam, group = adf_show_levee.risk_averse, label = ["high RA" "low RA"], 
legend = :outerright, legendfontsize = 16, foreground_color_legend=nothing,background_color_legend=nothing, linecolor = [colorant"#0A9396" colorant"#CA6702"], lw = 3)
Plots.ylims!(0,300)
Plots.ylabel!("Moving Agents", pointsize = 24)

#plot agents in the floodplain
fp_plot_levee = Plots.plot(adf_levee.step, adf_levee.count_floodplain_fam, group = adf_levee.risk_averse, label = false, linecolor = [colorant"#0A9396" colorant"#CA6702"], alpha = 0.35, lw = 1, tickfontsize = 10)

Plots.plot!(adf_show_levee.step, adf_show_levee.count_floodplain_fam, group = adf_show_levee.risk_averse, label = ["high RA" "low RA"], 
legend = :outerright, legendfontsize = 16, foreground_color_legend=nothing,background_color_legend=nothing, linecolor = [colorant"#0A9396" colorant"#CA6702"], lw = 3)
#Plots.ylabel!("Floodplain Pop.", pointsize = 28)
Plots.ylims!(0,500)
#Plots.xlabel!("Year", pointsize = 28)

#plot flood depths
model_plot_levee = Plots.plot(mdf_levee.step[1:51051], mdf_levee.floodepth[1:51051], legend = false, label = false, linecolor = :gray, alpha = 0.35, lw = 1,tickfontsize = 10)
Plots.plot!(mdf_show_levee.step[1:51], mdf_show_levee.floodepth[1:51], legend = false, label = false, linecolor = colorant"#005F73", lw = 3)
#Add line showing 100- yr level 
flood_100 = [GEV_return(1/100) for _ in 1:51]
Plots.plot!(mdf_show_levee.step[1:51],flood_100, line = :dash, legend = :outerright, legendfontsize = 12, foreground_color_legend=nothing, label = "100-year level", linecolor = colorant"#001219", lw = 3)
#annotate!(32,14,Plots.text("100-year level", family="serif", pointsize = 18, color = RGB(213/255,111/255,62/255)))
Plots.ylims!(0,40)
#Plots.ylabel!("Flood Depth", pointsize = 28)


#create subplot
levee_real = Plots.plot(model_plot_levee, agent_plot_levee, fp_plot_levee, layout = (3,1), dpi = 300, size = (800,800))

savefig(levee_real, "test/Test_visuals/paramscan_levee_realizations.svg")
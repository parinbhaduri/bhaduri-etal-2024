using Gadfly

init_theme = Gadfly.Theme(background_color = "white", grid_color = "white")
aes = layer(x = :return_period, y = :median, ymax=:RB, ymin=:LB,yintercept=[0], color = :group, 
Geom.hline(color="black", style=:dot), Geom.line, Geom.ribbon, alpha = [0.35])
Gadfly.with_theme(init_theme) do 
    Gadfly.plot(occ_elev, aes, Guide.xlabel("Return Period (Years)"), 
    Guide.ylabel("Difference in Occupied in Exposure"), 
    Scale.x_log10(labels = x -> mod(x,1) == 0 ? "$(10^x)" : ""), Scale.y_continuous(format=:plain))
end
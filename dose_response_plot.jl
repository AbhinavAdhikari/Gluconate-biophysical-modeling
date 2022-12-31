include("Include.jl")

data = readdlm("./dose_response_simulations_5/results_matrix.dat")

# first column contains the gluconate concentration
gluconate_concentration = data[:,1]
# the remaining columns contain the data
response = data[:,2:end]

μ = mean(response,dims=2)
σ = std(response,dims=2)

# LB = μ .- (1.96/sqrt(1))*σ
# UB = μ .+ (1.96/sqrt(1))*σ

# read dose response data
dose_response_exp = CSV.read("Dose_response.csv",DataFrame)
gluconate_concentration_exp = dose_response_exp[!,"Gluconate_concentration (mM)"] # mM
venus_mean_exp = dose_response_exp[!,"Mean (micromolar)"] # μM
venus_stderr_exp = dose_response_exp[!,"STD_ERR (micromolar)"] # μM

# # Plot simulated protein
# Plots.plot()
# # p1 = Plots.plot!(log.(gluconate_concentration), μ, ribbon=(LB,UB),label = "Dose Response Simulated", legend = :topright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (μM)", lw=3,fillalpha=0.35,c=:orange)
# # p1 = Plots.plot!(log.(gluconate_concentration), μ, fillbetween=[LB UB],label = "Dose Response Simulated", legend = :topleft,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (μM)", lw=3,fillalpha=0.35,c=:orange)
# p1 = Plots.plot!(log.(gluconate_concentration), μ, ribbon=2.576*(σ),label = "Dose Response Simulated", legend = :topright,xlabel="log[ Gluconate Concentration (mM) ]",ylabel = "Venus Concentration (μM)", lw=3,fillalpha=0.35,grid=false)


# # Plot experimental protein
# p2 = Plots.scatter!(log.(gluconate_concentration_exp),venus_mean_exp,label = "Dose Response Exp", markercolor = "black", legend = :topleft, yerror=venus_stderr_exp)
# Plots.plot(p2)
# # Plots.savefig("dose_response_simulations_5/Dose_response_ABHI_smooth_normalized.pdf")
# Plots.savefig("dose_response_simulations_5/Dose_response_ABHI_smooth.pdf")

LB = μ .- (1.96/sqrt(1))*σ
UB = μ .+ (1.96/sqrt(1))*σ
clf()
figure(2)
fill_between(log.(gluconate_concentration), vec(UB), vec(LB), color="powderblue", alpha=0.60)
PyPlot.plot(log.(gluconate_concentration),μ,"-",color="black",lw=1.0)
yerr_array = transpose([venus_stderr_exp venus_stderr_exp])
PyPlot.errorbar(log.(gluconate_concentration_exp), venus_mean_exp,yerr=yerr_array,fmt="o",mfc="#252525",mec="#252525",color="#252525", lw=1)

# labels - 
PyPlot.plot()
PyPlot.xlabel("log [Gluconate](mM)", fontsize=15)
PyPlot.ylabel("[Venus] (μM)", fontsize=15)
# PyPlot.axis([-0.5,16.5,-50,1600])
PyPlot.xticks(fontsize=15)
PyPlot.yticks([0,0.4,0.8,1.2,1.6,2.0], fontsize=15)
PyPlot.tight_layout()
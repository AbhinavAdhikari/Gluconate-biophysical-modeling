# ----------------------------------------------------------------------------------- #
# Copyright (c) 2019 Varnerlab
# Robert Frederick School of Chemical and Biomolecular Engineering
# Cornell University, Ithaca NY 14850

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# ----------------------------------------------------------------------------------- #

# include -
include("Include.jl")

# Script to solve the balance equations -
time_start = 0.0
time_stop = 12.0
time_step_size = 0.01

# what is the host_type?
host_type = :cell_free

# path to parameters -
path_to_biophysical_constants_file = "./CellFree.json"

# Load the data dictionary (uses the default biophysical_constants file)
data_dictionary = build_data_dictionary((time_start,time_stop,time_step_size), path_to_biophysical_constants_file, host_type)
#print(data_dictionary)

R = data_dictionary["R"]
T_K = data_dictionary["T_K"]
# compute W -

PC = readdlm("./poets_ensemble_W/PC_T5.dat")
poets_params = PC[:,1]

# Update the data dictionary
control_parameter_dictionary = data_dictionary["control_parameter_dictionary"]
control_parameter_dictionary["W_GntR_RNAP"] = exp(-1*(poets_params[1]))
control_parameter_dictionary["W_GntR_sigma_70"] = exp(-1*(poets_params[2]))
control_parameter_dictionary["W_Venus_RNAP"] = exp(-1*(poets_params[3]))
control_parameter_dictionary["W_Venus_sigma_70"] = exp(-1*(poets_params[4]))
control_parameter_dictionary["W_Venus_GntR"] = exp(-1*(poets_params[5]))
data_dictionary["control_parameter_dictionary"] = control_parameter_dictionary

binding_parameter_dictionary = data_dictionary["binding_parameter_dictionary"]
binding_parameter_dictionary["n_GntR_sigma_70"] = poets_params[6]
binding_parameter_dictionary["K_GntR_sigma_70"] = poets_params[7]
binding_parameter_dictionary["n_Venus_sigma_70"] = poets_params[8]
binding_parameter_dictionary["K_Venus_sigma_70"] = poets_params[9]
binding_parameter_dictionary["n_Venus_GntR"] = poets_params[10]
binding_parameter_dictionary["K_Venus_GntR"] = poets_params[11]
data_dictionary["binding_parameter_dictionary"] = binding_parameter_dictionary

time_constant_modifier_array = [
    0.0							;	# 1	GntR
    0.0							;	# 2	Venus
    0.0							;	# 3	sigma_70
    poets_params[12]	        ;	# 4	mRNA_GntR
    poets_params[13]	        ;	# 5	mRNA_Venus
    1.0							;	# 6	mRNA_sigma_70
    poets_params[14]	        ;	# 7	protein_GntR
    poets_params[15]	        ;	# 8	protein_Venus
    1.0							;	# 9	protein_sigma_70
]

data_dictionary["time_constant_modifier_array"] = time_constant_modifier_array

degradation_modifier_array = [
    0.0	;	# 1	GntR
    0.0	;	# 2	Venus
    0.0	;	# 3	sigma_70
    poets_params[16]	;	# 4	mRNA_GntR
    poets_params[17]	;	# 5	mRNA_Venus
    1.0	;	# 6	mRNA_sigma_70
    poets_params[18]	;	# 7	protein_GntR
    poets_params[19]	;	# 8	protein_Venus
    poets_params[20]	;	# 9	protein_sigma_70
]

data_dictionary["degradation_modifier_array"] = degradation_modifier_array

# update the translation time -
data_dictionary["half_life_translation_capacity"] = poets_params[21]

biophysical_constants_dictionary = data_dictionary["biophysical_constants_dictionary"]
biophysical_constants_dictionary["translation_saturation_constant"] = poets_params[22]
data_dictionary["biophysical_constants_dictionary"] = biophysical_constants_dictionary

# gluconate GntR binding parameters
gluconate_parameter_dictionary = data_dictionary["gluconate_parameter_dictionary"]
gluconate_parameter_dictionary["n_gluconate_GntR"] = poets_params[23]
gluconate_parameter_dictionary["K_gluconate_GntR"] = poets_params[24]
data_dictionary["gluconate_parameter_dictionary"] = gluconate_parameter_dictionary

# update the transcription capacity parameters
data_dictionary["transcription_capacity_delay"] = poets_params[25]
data_dictionary["transcription_capacity_slope"] = poets_params[26]



species_symbol_type_array = data_dictionary["species_symbol_type_array"]
protein_coding_length_array = data_dictionary["protein_coding_length_array"]
gene_coding_length_array = data_dictionary["gene_coding_length_array"]
time_constant_modifier_array = data_dictionary["time_constant_modifier_array"]
initial_condition_array = data_dictionary["initial_condition_array"]

# # get gene IC -
idx_gene = findall(x->x==:gene,species_symbol_type_array)
gene_abundance_array = initial_condition_array[idx_gene]

# Precompute the translation parameters -
translation_parameter_array = precompute_translation_parameter_array(biophysical_constants_dictionary, protein_coding_length_array, time_constant_modifier_array,host_type)
data_dictionary["translation_parameter_array"] = translation_parameter_array

# Precompute the kinetic limit of transcription -
transcription_kinetic_limit_array = precompute_transcription_kinetic_limit_array(biophysical_constants_dictionary, gene_coding_length_array, gene_abundance_array, time_constant_modifier_array, host_type)
data_dictionary["transcription_kinetic_limit_array"] = transcription_kinetic_limit_array

# Dilution degrdation matrix -
dilution_degradation_matrix = build_dilution_degradation_matrix(biophysical_constants_dictionary, species_symbol_type_array, degradation_modifier_array)
data_dictionary["dilution_degradation_matrix"] = dilution_degradation_matrix

# read dose response data
dose_response = CSV.read("Dose_response.csv",DataFrame)
gluconate_concentration = dose_response[!,"Gluconate_concentration (mM)"] # mM
venus_mean = dose_response[!,"Mean (micromolar)"] # ??M
venus_stderr = dose_response[!,"STD_ERR (micromolar)"] # ??M

# venus = zeros(length(gluconate_concentration))
#
# # looping through the range of gluconate parameter values
# for i in 1:length(gluconate_concentration)
#
#     gluconate_parameter_dictionary = data_dictionary["gluconate_parameter_dictionary"]
#     gluconate_parameter_dictionary["gluconate_concentration"] = gluconate_concentration[i]
#     data_dictionary["gluconate_parameter_dictionary"] = gluconate_parameter_dictionary
#
#     # Solve the model equations -
#     (T,X) = SolveBalances(time_start,time_stop,time_step_size,data_dictionary)
#
#     venus[i] = X[end,8]
#
# end
#
# # Plot simulated protein
# Plots.plot()
# p1 = Plots.scatter!(gluconate_concentration,venus,label = "Dose Response Simulated", markercolor = "black", legend = :bottomright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (??M)")
# Plots.plot(p1)
# # Plots.plot(gluconate_concentration,venus,label = "Dose Response Simulated", marker = "--",markercolor = "black", legend = :bottomright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (??M)")
#
# # # Plot experimental protein
# # Plots.plot()
# p2 = Plots.scatter!(gluconate_concentration,venus_mean,label = "Dose Response Exp", markercolor = "blue", legend = :bottomright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (??M)",yerror=venus_stdev)
# Plots.plot(p2)
#

# get more data
# itp =  Interpolations.LinearInterpolation(gluconate_concentration, venus_mean)
# gluconate_range = range(0,stop = 20, length = 100)
# venus_mean_itp = itp[gluconate_range]

gluconate_range = gluconate_concentration
venus = zeros(length(gluconate_range))

# looping through the range of gluconate parameter values
for i in 1:length(gluconate_range)

    gluconate_parameter_dictionary = data_dictionary["gluconate_parameter_dictionary"]
    gluconate_parameter_dictionary["gluconate_concentration"] = gluconate_range[i]
    data_dictionary["gluconate_parameter_dictionary"] = gluconate_parameter_dictionary

    # Solve the model equations -
    (T,X) = SolveBalances(time_start,time_stop,time_step_size,data_dictionary)

    venus[i] = X[end,8]

end

# # Plot simulated protein
# Plots.plot()
# p1 = Plots.scatter!(gluconate_range,venus,label = "Dose Response Simulated", markercolor = "black", legend = :bottomright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (??M)")
# Plots.plot(p1)
#
# # Plot experimental protein
# p2 = Plots.scatter!(gluconate_concentration,venus_mean,label = "Dose Response Exp", markercolor = "blue", legend = :bottomright,xlabel="Gluconate Concentration (mM)",ylabel = "Venus Concentration (??M)",yerror=venus_stderr)
# Plots.plot(p2)

# Plot simulated protein
Plots.plot()
p1 = Plots.scatter!(log.(gluconate_range),venus,label = "Dose Response Simulated", markercolor = "black", legend = :topleft,xlabel="log[ Gluconate Concentration (mM) ]",ylabel = "Venus Concentration (??M)")
Plots.plot(p1)

# Plot experimental protein
p2 = Plots.scatter!(log.(gluconate_concentration),venus_mean,label = "Dose Response Exp", markercolor = "blue", legend = :topleft,xlabel="log[ Gluconate Concentration (mM) ]",ylabel = "Venus Concentration (??M)",yerror=venus_stderr)
Plots.plot(p2)

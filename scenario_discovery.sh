#!/bin/bash
#SBATCH --job-name=balt_disc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=50
#SBATCH --output=workflow/CHANCE_C/test/output_text.txt
#SBATCH --error=workflow/CHANCE_C/test/error_text.txt
#SBATCH --exclusive

# Run the Julia code
julia +1.7 workflow/CHANCE_C/scen_discovery.jl
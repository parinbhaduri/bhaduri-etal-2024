#!/bin/bash
#SBATCH --job-name=optimize_fe
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --output=workflow/CHANCE_C/test/output_text.txt
#SBATCH --error=workflow/CHANCE_C/test/error_text.txt
#SBATCH --exclusive

# Run the Julia code
julia +1.7 damage_fixed_effect.jl
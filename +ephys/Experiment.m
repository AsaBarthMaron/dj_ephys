%{
# experiment
exp_id: int unsigned               		# unique experiment id
---
data_path	  	 : varchar(1000)		# path to data
date         	 : date                 # experiment date
age = -1         : tinyint				# expected value of age, in hours, -1 is unknown.
exp_name         : varchar(200)	 		# experiment name
genotype = ''    : varchar(200)
#recording_line  : varchar(200)
#perturb_line     : varchar(200)
#perturbation     : varchar(50)			# Name of opsin or etc used in experiment, 
										# e.g. 'GtACR1', 'CsChrimson', or 'None' if none.
#is_pair = 0: tinyint unsigned			 # logical being stored as int.
%}
classdef Experiment < dj.Manual
end
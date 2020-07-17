%{
# cell

-> ephys.Experiment
cell_id = 1		: int               # unique cell id
---
#cell_type		: varchar(50)		# Cell type
r_access = -1   : float
r_pipette = -1  : float
r_input = -1    : float

%}
classdef Cell < dj.Imported
	methods(Access=protected)
    	function makeTuples(self,key)
    		% TODO: logic to change cell_id in case of pairs
    		% 		resistance calculations
    		%		cell_type designations
    		disp(key)
    		self.insert(key)
    	end
    end
end
%{
# trial external command stimulus and properties

-> ephys.Trial
---
cmd_units    		  : varchar(50)      # units (converted) to indicate stimulus magnitude. Typically pA or mV.
cmd_mag  			  : float	         # magnitude of stimulus, in cmd_units.
response_mag		  : float			 # magnitude of response, in ephys.Trial.units
-> ephys.Waveform    

%}

classdef TrialExtCmd < dj.Part
    properties(SetAccess=protected)
        master = ephys.Trial
    end
    methods
        function make(self, key)
            self.insert(key);
        end
    end
end
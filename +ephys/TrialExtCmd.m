%{
# trial external command stimulus and properties

-> ephys.Trial
---
units    			  : varchar(50)      # units (converted) to indicate stimulus magnitude. Typically pA or mV.
cmd_mag  			  : smallint         # magnitude of stimulus, in units.
-> ephys.Waveform    

%}

classdef TrialExtCmd < dj.Part
    properties(SetAccess=protected)
        master = ephys.Trial
    end
    methods
        function make(self, key)
            self.insert(key)
        end
    end
end
%{
# trial odor stimulus and properties

-> ephys.Trial
---
odor           : varchar(50)            # odor name
concentration  : tinyint unsigned       # Log of dilution, unsigned. 
                                        # e.g. 3 = abs(log10(10^-3)), corresponds to 1:10^-3
-> ephys.Waveform

%}

classdef TrialOdor < dj.Part
    properties(SetAccess=protected)
        master = ephys.Trial
    end
    methods
        function make(self, key)
        	tuple = key
        	tuple.odor = 'test_odor'
        	tuple.concentration = 3
        	tuple.wave_name = 'slow'
            self.insert(tuple)
        end
    end
end
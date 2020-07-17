%{
# amplifier (200B) properties

units  : enum('mV', 'pA')		
-> ephys.Mode
-> ephys.Gain
-> ephys.FilterFreq
---

%}
classdef Amplifier < dj.Computed
    methods(Access=protected)
        function makeTuples(self, key)
        	if strcmp(key.mode, 'V-clamp')
        		key.units = 'pA';
        	else
        		key.units = 'mV';
        	end
            self.insert(key)
        end
    end
end
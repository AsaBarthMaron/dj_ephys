%{
# amplifier (200B) properties
	
units  				 : enum('mV', 'pA')		
-> ephys.Mode
-> ephys.Gain
-> ephys.FilterFreq
---
#i_ch = 1     		 : tinyint unsigned
#v_ch = 2     		 : tinyint unsigned
#so_ch = 3    		 : tinyint unsigned
#gain_ch = 4  		 : tinyint unsigned
#freq_ch = 5			 : tinyint unsigned
#mode_ch = 6 		 : tinyint unsigned		

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
%{
# amplifier (axopatch 200B) mode

mode          : enum("V-clamp", "I-zero", "I-normal", "I-fast")
---
mode_voltage  : tinyint unsigned
units		  : enum('mV', 'pA')		# scaled output units (post gain and x1000 V / nA -> mV / pA conversion)
    
%}
classdef Mode < dj.Lookup
    properties
        contents = {
            'V-clamp' 6 'pA'
            'I-zero' 3 'mV'
            'I-normal' 2 'mV'
            'I-fast' 1 'mV'
        }
    end
end
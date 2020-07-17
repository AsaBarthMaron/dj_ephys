%{
# amplifier (axopatch 200B) mode

mode          : enum("V-clamp", "I-zero", "I-normal", "I-fast")
---
mode_voltage  : tinyint unsigned
    
%}
classdef Mode < dj.Lookup
    properties
        contents = {
            'V-clamp' 6
            'I-zero' 3
            'I-normal' 2
            'I-fast' 1
        }
    end
end
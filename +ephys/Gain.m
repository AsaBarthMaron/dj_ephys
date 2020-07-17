%{
# amplifier (axopatch 200B) mode

gain          : smallint unsigned       # amplifier gain 
---
gain_voltage  : tinyint unsigned        # 10x corresponding amplifier voltage

%}
classdef Gain < dj.Lookup
    properties
        contents = {
            1 25
            2 30
            5 35
            10 40
            20 45
            50 50
            100 55
            200 60
            500 65
        }
    end
end
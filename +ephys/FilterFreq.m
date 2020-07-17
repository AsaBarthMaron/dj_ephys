%{
# amplifier (axopatch 200B) scaled output filtering cutoff (low pass) frequency

filter_freq          : smallint unsigned        # low-pass cutoff frequency, in kHz
---
filter_freq_voltage  : tinyint unsigned         # corresponding amplifier voltage

%}
classdef FilterFreq < dj.Lookup
    properties
        contents = {
            1 2
            2 4
            5 6
            10 8
            100 10
        }
    end
end


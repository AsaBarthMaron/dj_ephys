%{
# Region of interest resulting from segmentation

-> ephys.Trial
---

%}

classdef TrialSealTest < dj.Part
    properties(SetAccess=protected)
        master = ephys.Trial
    end
    methods
        function make(self, key)

            
        end
    end
end
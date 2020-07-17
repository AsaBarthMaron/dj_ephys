%{
# amplifier (200B) properties

-> ephys.Mode
-> ephys.Gain
-> ephys.FilterFreq
---

%}
classdef Amplifier < dj.Computed
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
        end
    end
end
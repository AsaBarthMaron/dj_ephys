%{
# trial optogenetics stimulus and properties

-> ephys.Trial
---
opsin               : varchar(50)
nd_25               : tinyint unsigned       # number of ND25 filters in the light path.
nd_3                : tinyint unsigned       # number of ND3 filters in the light path.
mercury_lamp = 0    : tinyint unsigned       # logical being stored as int.
led_power = 0       : tinyint unsigned       # LED power, 0 if mercury lamp was in use instead.
led_wavelength = 0  : smallint unsigned      # LED wavelength, 0 if mercury lamp was in use.
# TODO: filter_cube, led and mercury as separate part tables
-> ephys.Waveform

%}

classdef TrialOpto < dj.Part
    properties(SetAccess=protected)
        master = ephys.Trial
    end
    methods
        function make(self, key)
        	self.insert(key);
        end
    end
end
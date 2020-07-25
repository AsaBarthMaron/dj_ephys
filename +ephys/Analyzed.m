%{
# analyzed data, prototype
	
-> ephys.Trial
---
bandpass_cutoff			: blob
ds_factor				: smallint unsigned
med_filt_window 		: smallint unsigned
psth					: longblob
psth_bin_size			: smallint unsigned
psth_method				: varchar(50)
spike_inds				: blob
spd_min_prom			: float
spd_max_width			: float
spd_min_width			: float
spd_min_distance		: float
vm_filt					: longblob

%}
classdef Analyzed < dj.Computed
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
        end
    end
end
%{
# trial
-> ephys.Cell
trial_id = 1: int                  # unique trial id
---
trace=NULL: longblob
-> ephys.Amplifier
units = 'mV': varchar(20)			   # Should be defined in Amplifier, then fetched using keys.

odor = NULL: varchar(50)
odor_concentration = NULL: tinyint unsigned
odor_on_duration =  NULL: smallint unsigned
odor_freq =  NULL: tinyint unsigned
odor_cmd =  NULL: longblob

led_power = NULL: tinyint unsigned
light_on_duration = NULL: smallint unsigned
light_freq =  NULL: smallint unsigned
light_cmd =  NULL: longblob
mercury_lamp = NULL: varchar(20)	# unsure what datatype to use actually

cmd_mag = NULL: smallint
ext_cmd = NULL: longblob

seal_test = NULL: tinyint unsigned	# 1 for true
holding_current = NULL: smallint  # in pA
holding_command = NULL: smallint # in mV
spacer = NULL: tinyint unsigned	# 1 for true
r_input = NULL: smallint unsigned
clearing_trial = NULL: tinyint unsigned	# 1 for true
%}

classdef Trial < dj.Imported
	methods(Access=protected)
    	function makeTuples(self,key)
			dataPath = fetchn(ephys.Experiment & ['exp_id=' string(key.exp_id)], 'data_path');
			dataPath = dataPath{1};

			dataFiles = dir(dataPath);
			dataFiles = dataFiles(~[dataFiles.isdir]);
			[~,idx] = sort([dataFiles.datenum]);
			dataFiles = dataFiles(idx);

			for iFile = 1:length(dataFiles)
				blk = load(fullfile(dataPath,dataFiles(iFile).name))
				disp([dataFiles(iFile).name ' was loaded --- success!!'])
				key.trial_id = iFile
				tuple = key
				tuple.trace = blk.data(:,3,1)
				tuple.gain = 100;
				tuple.mode = 'I-normal';
				tuple.filter_freq = 5;
				disp(tuple)
				self.insert(tuple)
				make(ephys.TrialOdor, key)
			end
    	end
    end
end
% TODO: 7/16 - clean up Trial table definition & write Trial import logic!! We're ready!
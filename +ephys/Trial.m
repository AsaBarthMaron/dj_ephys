%{
# trial

-> ephys.Cell
trial_id = 1     		: int                  # unique trial id
---
voltage  		 		: longblob
current  		 		: longblob
holding_current         : smallint  # in pA
holding_command = NULL  : smallint # in mV
-> ephys.Amplifier 							

odor_stim = 0     		: tinyint unsigned 		# logical, was odor used in this trial?
opto_stim = 0     		: tinyint unsigned 		# logical, was otpo stim used in this trial?
ext_cmd  = 0      		: tinyint unsigned 		# logical, was an external command sent (from amplifier)?
seal_test = 0     		: tinyint unsigned 		# logical, was the seal test on?
spacer_trial = 1  		: tinyint unsigned		# logical, was this a 'spacer' trial?

%}

classdef Trial < dj.Imported
	methods(Access=protected)
    	function makeTuples(self,key)

    		% Experiment-level operations
    		% each call of makeTuples will iterate through and import all trials for a given experiment.

    		% get path to data for experiment
			dataPath = fetchn(ephys.Experiment & ['exp_id=' string(key.exp_id)], 'data_path');
			dataPath = dataPath{1};
			% get struct of files to be loaded
			dataFiles = dir(dataPath);
			dataFiles = dataFiles(~[dataFiles.isdir]);
			[~,idx] = sort([dataFiles.datenum]);
			dataFiles = dataFiles(idx);

			% iterate through each data file, a single file often consists of multipel trials ('block')
			for iFile = 1:length(dataFiles)
				blk = load(fullfile(dataPath,dataFiles(iFile).name))
				disp([dataFiles(iFile).name ' was loaded --- success!!'])
				key.trial_id = iFile
				tuple = key
				tuple.voltage = blk.data(:,3,1)
				tuple.current = blk.data(:,1,1)
				tuple.holding_current = 10;
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
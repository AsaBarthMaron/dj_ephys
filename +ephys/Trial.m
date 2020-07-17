%{
# trial

-> ephys.Cell
trial_id = 1     		: int                  # unique trial id
---
voltage  		 		: longblob
current  		 		: longblob
holding_current         : smallint  			# in pA
holding_command = NULL  : smallint 				# in mV
samp_rate				: int unsigned			# sampling rate (samples / second)
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
    		% TODO: these should maybe go in Amplifier or Experiment?
    		I_CH = 1;
    		V_CH = 2;
    		SO_CH = 3;
    		GAIN_CH = 4;
    		FILTER_CH = 5;
    		MODE_CH = 6;
    		I_SCALING = 100; 		% hard coded switch on back of amplifier, set to 100 mV / pA (beta = 1)

    		% Experiment-level operations
    		% each call of makeTuples will iterate through and import all trials for a given experiment.
    		expQuery = ephys.Experiment & ['exp_id=' num2str(key.exp_id)];

    		% get path to data for experiment
			dataPath = expQuery.fetchn('data_path');
			dataPath = dataPath{1};
			% get struct of files to be loaded
			dataFiles = dir(dataPath);
			dataFiles = dataFiles(~[dataFiles.isdir]);
			[~,idx] = sort([dataFiles.datenum]);
			dataFiles = dataFiles(idx);

			% get exp_name
			exp_name = expQuery.fetchn('exp_name');
            exp_name = exp_name{1};

			% Trial-block level operations
			% iterate through each data file, a single file often consists of multiple trials (a 'block').
			for iFile = 1:length(dataFiles)
				fname = dataFiles(iFile).name;
				f = load(fullfile(dataPath,fname));

				% Trial-level operations
				% the majority of this code will be logic to parse filenames of various trial types.

				% 'while patching' trials
				% acquired using 'staq/run_spacer_trial.m'
				% e.g., bath, seal, vclamp (sealtest), early Iclamp single trials, etc.
				% they have an important regularity - 
				% they are the only files with 'exp_name' in the file name
				if ~isempty(strfind(fname, exp_name))
					key.trial_id = 1;
					tuple = key
					tuple.samp_rate = f.sampRate

					% get & set amplifier settings
					mode_voltage = num2str(round(median(f.spacer_data(:, MODE_CH))))
					gain_voltage = num2str(round(median(f.spacer_data(:, GAIN_CH)*10)))
					filter_voltage = num2str(round(median(f.spacer_data(:, FILTER_CH))))
					tuple.mode = fetch(ephys.Mode & ['mode_voltage=' mode_voltage]).mode
					% tuple.gain = fetch(ephys.Gain & ['gain_voltage=' gain_voltage]).gain
					tuple.gain = 10 % TODO: fix the above, these measurements are not as good as I thought
					tuple.filter_freq = fetch(ephys.FilterFreq & ['filter_freq_voltage=' filter_voltage]).filter_freq
					tuple.units = fetch(ephys.Mode & ['mode="' tuple.mode '"'], 'units').units

					scaling_factor = 1e3 / tuple.gain 		% x1000 factor for (V / nA) -> (mV / pA) conversion)
					
					if strcmp('V-clamp', tuple.mode)
						tuple.voltage = f.spacer_data(:, V_CH) * (1e3/10);
						tuple.current = f.spacer_data(:, SO_CH) * scaling_factor;
					else
						tuple.voltage = f.spacer_data(:, SO_CH) * scaling_factor;
						tuple.current = f.spacer_data(:, I_CH) * (1e3/I_SCALING);
					end
					tuple.holding_current = round(median(tuple.current))
					tuple.holding_command = round(median(tuple.voltage))

					if ~isempty(strfind(fname, 'whole_cell_current_step'))
						tuple.ext_cmd = 1;
						self.insert(tuple);
						I = tuple.current;
						tuple = key;
						tuple.units = 'pA'
						tuple.wave_name = 'r_input_test'
						tuple.cmd_mag = round(median(I((0.75 * sampRate):sampRate)) - median(I))
						make(ephys.TrialExtCmd, tuple)
					elseif ~isempty([strfind(fname, 'Vclamp_bath'), strfind(fname, 'Vclamp_seal'), strfind(fname, 'Vclamp_cell')])
					end
				else 	
					key.trial_id = iFile
					tuple = key
					tuple.samp_rate = f.sampRate				
					tuple.samp_rate = f.sampRate
					tuple.voltage = f.data(:,3,1)
					tuple.current = f.data(:,1,1)
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
end
% TODO: 7/16 - clean up Trial table definition & write Trial import logic!! We're ready!
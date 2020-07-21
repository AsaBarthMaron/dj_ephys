%{
# trial

-> ephys.Cell
trial_id = 1     		: int                  # unique trial id
---
voltage  		 		: longblob
current  		 		: longblob
holding_current         : smallint  			# in pA
holding_command = NULL  : smallint 				# in mV
trial_name				: varchar(100)
trial_time				: time 					# the time the trial/block was saved
samp_rate				: int unsigned			# sampling rate (samples / second)
-> ephys.Amplifier 							

odor_stim = 0     		: tinyint unsigned 		# logical, was odor used in this trial?
opto_stim = 0     		: tinyint unsigned 		# logical, was otpo stim used in this trial?
ext_cmd  = 0      		: tinyint unsigned 		# logical, was an external command sent (from amplifier)?
seal_test = 0     		: tinyint unsigned 		# logical, was the seal test on?
spacer_trial = 0  		: tinyint unsigned		# logical, was this a 'spacer' trial?
block = 0				: tinyint unsigned		# logical, is this trial part of a block?
%}

classdef Trial < dj.Imported
	methods(Access=protected)
    	function makeTuples(self,key)
    		% TODO: these should maybe go in Amplifier or Experiment?
    		c.I_CH = 1;
    		c.V_CH = 2;
    		c.SO_CH = 3;
    		c.GAIN_CH = 4;
    		c.FILTER_CH = 5;
    		c.MODE_CH = 6;
    		c.I_SCALING = 100; 		% hard coded switch on back of amplifier, set to 100 mV / pA (beta = 1)

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
			trialId = 1;
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
					% trial metadata
					key.trial_id = trialId; 		
					tuple = key;
					tuple.trial_time = dataFiles(iFile).date(end-7:end);
					tuple.samp_rate = f.sampRate;
					tuple.trial_name = fname((13 + length(exp_name)):end-4);

					% add recording trace and metadata
					tuple = self.addTrace(tuple, f.spacer_data, c);

					% logic to handle different 'spacer' trial types
					if ~isempty(strfind(fname, 'whole_cell_current_step'))
						tuple.ext_cmd = 1;
						self.insert(tuple);
						I = tuple.current;
						tuple = key;
						tuple.units = 'pA'
						tuple.wave_name = 'r_input_test'
						tuple.cmd_mag = round(median(I((0.75 * f.sampRate):f.sampRate)) - median(I))
						make(ephys.TrialExtCmd, tuple);
					elseif ~isempty([strfind(fname, 'Vclamp_bath'), strfind(fname, 'Vclamp_seal'), strfind(fname, 'Vclamp_cell')])
						tuple.seal_test = 1;
						self.insert(tuple);
						tuple = key;
						make(ephys.TrialSealTest, tuple);
					elseif ~isempty([strfind(fname, 'Vclamp_seal_spikes'), strfind(fname, 'Iclamp_zero')])
						self.insert(tuple);
					else
						error(['Unrecognized file name: ', fname])
					end
				else
					nTrials = size(f.data, 3);
					spacer = isfield(f, 'spacer_data');
					for iTrial = 1:nTrials
						key.trial_id = trialId; 		
						tuple = key;
						tuple.trial_time = dataFiles(iFile).date(end-7:end);
						tuple.samp_rate = f.sampRate;
						tuple.trial_name = fname(12:end-4);
						tuple.block = 1;

						% if there is a spacer trial, insert it
						if spacer
							spacer_tuple = tuple;
							spacer_tuple.spacer_trial = 1;
							spacer_tuple = self.addTrace(spacer_tuple, f.spacer_data(:,:,iTrial), c);
							self.insert(spacer_tuple);
							trialId = trialId + 1;
							tuple.trial_id = trialId;
							key.trial_id = trialId;
						end

						% add recording trace and metadata, insert tuple
						tuple = self.addTrace(tuple, f.data(:,:,iTrial), c);
						self.insert(tuple);
						make(ephys.TrialOdor, key);
						trialId = trialId + 1;
					end
					trialId = trialId - 1;
				end
				trialId = trialId + 1;
			end
    	end

    	function tuple = addTrace(self,tuple, data, c)
    		% and related recording / amplifier metadata.

			% get & set amplifier settings
			mode_voltage = num2str(round(median(data(:, c.MODE_CH))));
			filter_voltage = num2str(round(median(data(:, c.FILTER_CH))));
			tuple.mode = fetch(ephys.Mode & ['mode_voltage=' mode_voltage]).mode;
			tuple.filter_freq = fetch(ephys.FilterFreq & ['filter_freq_voltage=' filter_voltage]).filter_freq;
			tuple.units = fetch(ephys.Mode & ['mode="' tuple.mode '"'], 'units').units;

			gain_voltage = round(median(data(:, c.GAIN_CH)*10));
			if mod(gain_voltage, 5) ~= 0 	% hack, because in some trials there is a DC offset
				common_gain_v = [40, 55];
				[~, i_closer] = min(abs(common_gain_v - gain_voltage));
				gain_voltage = common_gain_v(i_closer);
			end
			gain_voltage = num2str(gain_voltage);
			tuple.gain = fetch(ephys.Gain & ['gain_voltage=' gain_voltage]).gain;
			% tuple.gain = 10 % TODO: fix the above, these measurements are not as good as I thought

			scaling_factor = 1e3 / tuple.gain 		% x1000 factor for (V / nA) -> (mV / pA) conversion)
			
			if strcmp('V-clamp', tuple.mode)
				tuple.voltage = data(:, c.V_CH) * (1e3/10);
				tuple.current = data(:, c.SO_CH) * scaling_factor;
			else
				tuple.voltage = data(:, c.SO_CH) * scaling_factor;
				tuple.current = data(:, c.I_CH) * (1e3/c.I_SCALING);
			end
			tuple.holding_current = round(median(tuple.current));
			tuple.holding_command = round(median(tuple.voltage));
		end
    end
end
% TODO: 7/16 - clean up Trial table definition & write Trial import logic!! We're ready!
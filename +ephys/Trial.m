%{
# trial

-> ephys.Cell
trial_id = 1     		: int                  # unique trial id
---
voltage  		 		: longblob
current  		 		: longblob
holding_current         : smallint  			# in pA
holding_command = NULL  : smallint 				# in mV
resting_v = NULL		: float					# in mV
r_input = NULL			: float					# in GOhms
trial_name				: varchar(100)
file_name 				: varchar(200)		
new_fname = NULL		: varchar(200)			# to be used if original fname has a typo (typoLookup)	
save_time				: time 					# the time the trial/block was saved
samp_rate				: int unsigned			# sampling rate (samples / second)
-> ephys.Amplifier 							

odor_stim = 0     		: tinyint unsigned 		# logical, was odor used in this trial?
clearing_trial = 0	    : tinyint unsigned		# logical, if odor trial, was this trial #1?
opto_stim = 0     		: tinyint unsigned 		# logical, was otpo stim used in this trial?
ext_cmd  = 0      		: tinyint unsigned 		# logical, was an external command sent (from amplifier)?
seal_test = 0     		: tinyint unsigned 		# logical, was the seal test on?
spacer_trial = 0  		: tinyint unsigned		# logical, was this a 'spacer' trial?
trial_block = 0			: tinyint unsigned		# logical, is this trial part of a block?
%}

classdef Trial < dj.Imported
	methods(Access=protected)
    	function makeTuples(self,key)
    		disp(key.exp_id)
    		% TODO: these should maybe go in Amplifier or Experiment?
    		c.I_CH = 1;
    		c.V_CH = 2;
    		c.SO_CH = 3;
    		c.GAIN_CH = 4;
    		c.FILTER_CH = 5;
    		c.MODE_CH = 6;
    		c.I_SCALING = 100; 		% hard coded switch on back of amplifier, set to 100 mV / pA (beta = 1)

    		% TODO: should this be part of ephys.Waveform?
    		waveNameLookup = containers.Map({'1s', '2s', '2.5s', '8s', '10Hz', '2Hz', '0.5Hz', '0.1s', '0.05s', 'fast', 'med', 'slow', 'train'}, ... 
    										{'1_second', '2.5s', '2_seconds', '8_seconds', 'fast', 'med', 'slow', '0.1s', '0.05s', 'fast', 'med', 'slow', 'Emre'});

    		% skippedFiles = struct('fname', []', 'dataPath', [], 'warningMsg', []);
    		load('skippedFiles.mat')

    		% load the lookup table that helps handle filename typos
			typoTable = readtable('/Volumes/SSD_DATA/2020-07-27_typo_lookup.xlsx');
			typoLookup = containers.Map(typoTable.fname, typoTable.new_fname);

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

			% get date
			exp_date = expQuery.fetchn('date');
            exp_date = exp_date{1};

            % get experiment type ('LN_dynamics', 'optogenetic_LN_stim')
            ln_dynamics = contains(dataPath, 'LN_dynamics');
            optogenetic_ln_stim = contains(dataPath, 'optogenetic_LN_stim');

			% Trial-block level operations
			% iterate through each data file, a single file often consists of multiple trials (a 'block').
			trialId = 1;
			for iFile = 1:length(dataFiles)
				fname = dataFiles(iFile).name;
				typo_present = contains(fname, keys(typoLookup));
				if contains(fname, 'actually') && ~typo_present
					warningMsg = ['filename: ', fname, ' cannot be read correctly'];
					warning(warningMsg)
					skippedFiles(end+1).fname = fname;
					skippedFiles(end).dataPath = dataPath;
					skippedFiles(end).warningMsg = warningMsg;
					continue
				elseif ~contains(fname(end-3:end), '.mat') || ~contains(fname, exp_date) || contains(fname, 'dataFiles')
					warningMsg = [fname, ' is not a data file'];
					warning(warningMsg)
					continue
				end
				f = load(fullfile(dataPath,fname));
				fname_split = strsplit(fname, '_');

				% load pre-analyzed data, if it exists.
				analyzed_file = fullfile(dataPath, 'analyzed', [fname(1:end-4), '_analyzed.mat']);
				if isfile(analyzed_file)
					f_analyzed = load(analyzed_file);
				end

				% handle filename typos
				if typo_present
					old_fname = fname;
					fname = typoLookup(fname);
					fname_split = strsplit(fname, '_');
				end
				% Trial-level operations
				% the majority of this code will be logic to parse filenames of various trial types.


				% 'while patching' trials
				% acquired using 'staq/run_spacer_trial.m'
				% e.g., bath, seal, vclamp (sealtest), early Iclamp single trials, etc.
				% they have an important regularity - 
				% they are the only files with 'exp_name' in the file name
				if contains(fname, {exp_name, 'bath', 'seal', 'Vclamp_cell', 'seal_spikes', 'Iclamp_zero', 'Iclamp_fast', 'Iclamp_whole_cell', 'Iclamp_normal'})
					% trial metadata
					key.trial_id = trialId; 		
					tuple = key;
					tuple.save_time = dataFiles(iFile).date(end-7:end);
					tuple.samp_rate = f.sampRate;
					tuple.trial_name = fname((13 + length(exp_name)):end-4);
					if ~typo_present
						tuple.file_name = fname;
					else
						tuple.file_name = old_fname;
						tuple.new_fname = fname;
					end
					tuple.trial_block = 0;
					tuple.spacer_trial = 0;

					% add recording trace and metadata
					try
						tuple = self.addTrace(tuple, f.spacer_data, c);
					catch
						error(fname)
					end

					% logic to handle different 'spacer' trial types
					if contains(fname, {'whole_cell_current_step', 'Iclamp_normal', 'Iclamp_fast'})
						self.insertExtCmdTrial(key, tuple);
					elseif contains(fname, {'Vclamp_bath', 'Vclamp_seal', 'Vclamp_cell'})
						tuple.seal_test = 1;
						self.insert(tuple);
						tuple = key;
						make(ephys.TrialSealTest, tuple);
					elseif contains(fname, {'Vclamp_seal_spikes', 'Iclamp_zero'})
						self.insert(tuple);
					else
						warningMsg = ['Unrecognized file name: ', fname];
						warning(warningMsg)
						skippedFiles(end+1).fname = fname;
						skippedFiles(end).dataPath = dataPath;
						skippedFiles(end).warningMsg = warningMsg;
						continue
					end
				else
					try
						nTrials = size(f.data, 3);
					catch
						error(fname)
					end
					spacer = isfield(f, 'spacer_data');
                    % if nTrials >= 2
                    %     nTrials = 2;
                    % end
					for iTrial = 1:nTrials
						key.trial_id = trialId; 		
						tuple = key;
						tuple.save_time = dataFiles(iFile).date(end-7:end);
						tuple.samp_rate = f.sampRate;
						tuple.trial_name = fname(12:end-4);
						if ~typo_present
							tuple.file_name = fname;
						else
							tuple.file_name = old_fname;
							tuple.new_fname = fname;
						end						
						tuple.trial_block = 1;
						tuple.odor_stim = 0;
						tuple.opto_stim = 0;

						% if there is a spacer trial, insert it
						if spacer
							spacer_tuple = tuple;
							spacer_tuple.spacer_trial = 1;
							try
								spacer_tuple = self.addTrace(spacer_tuple, f.spacer_data(:,:,iTrial), c);
							catch
								error(fname)
							end
							self.insertExtCmdTrial(key, spacer_tuple);
							if isfile(analyzed_file)
								self.insertAnalyzed(key, f_analyzed, iTrial, spacer_tuple.spacer_trial);
							end

							trialId = trialId + 1;
							tuple.trial_id = trialId;
							key.trial_id = trialId;
						else
							spacer_tuple.spacer_trial = 0;
						end

						% add recording trace and metadata
						tuple = self.addTrace(tuple, f.data(:,:,iTrial), c);
						trialId = trialId + 1;

						% Logic to handle different trial types

						% odor trials - parse filename and set odorTuple, tuple
						if contains(fname, {'2-hep', 'farnesol', 'PO', 'blank', 'valve'})
							tuple.odor_stim = 1;
							if iTrial == 1
								tuple.clearing_trial = 1;
							end

							% TODO: configure things so multiple odors can be used
							if (contains(fname, '2-hep') && contains(fname, 'farnesol'))
								warningMsg = ['Multiple odors in: ', fname];
								warning(warningMsg)
								skippedFiles(end+1).fname = fname;
								skippedFiles(end).dataPath = dataPath;
								skippedFiles(end).warningMsg = warningMsg;
								break
							end

							% set odor identity and concentration
							odorTuple = key;
                            if contains(fname, '10^-')
                                iOdor = find(contains(fname_split, '10^-'))-1;
                                iOdor = iOdor(1);
    							odorTuple.concentration = str2num(fname_split{iOdor + 1}(5:end));
    							odorTuple.odor = fname_split{iOdor};
                            elseif contains(fname, 'PO')
                                iOdor = find(contains(fname_split, 'PO'));
                                iOdor = iOdor(1);
                                odorTuple.concentration = -1;
                                odorTuple.odor = 'PO';
                            elseif contains(fname, 'valve')
                                iOdor = find(contains(fname_split, 'valve'));
                                iOdor = iOdor(1);
                                odorTuple.concentration = -1;
                                odorTuple.odor = 'no_odor_valve';
                            else
								warningMsg = ['Unrecognized odor or concentratoin: ', fname];
								warning(warningMsg)
								skippedFiles(end+1).fname = fname;
								skippedFiles(end).dataPath = dataPath;
								skippedFiles(end).warningMsg = warningMsg;
								break                            
                            end

							
							% figure out waveform, and set it
							if ln_dynamics || strcmpi(fname_split{iOdor-1}, 'stim') || iOdor == 2	% hack
								WAV_LOOKUP = {'fast', 'med', 'slow'};
								odorTuple.wave_name = WAV_LOOKUP{f.randTrials(iTrial)};
							elseif optogenetic_ln_stim || iOdor ~= 2	% also hack
								odorTuple.wave_name = fname_split{iOdor - 1};

								if contains(odorTuple.wave_name, keys(waveNameLookup))
									odorTuple.wave_name = waveNameLookup(odorTuple.wave_name);
								else
									warningMsg = ['Unrecognized odor waveform for: ' fname];
									warning(warningMsg)
									skippedFiles(end+1).fname = fname;
									skippedFiles(end).dataPath = dataPath;
									skippedFiles(end).warningMsg = warningMsg;
									break		
								end
							else
								warningMsg = ['Unrecognized odor waveform for: ' fname];
								warning(warningMsg)
								skippedFiles(end+1).fname = fname;
								skippedFiles(end).dataPath = dataPath;
								skippedFiles(end).warningMsg = warningMsg;
								break						
							end
						end


						% opto trials - parse filename and set optoTuple, tuple
						if contains(fname, {'LED', '2.5s_shutter_pulse'})
							iLed = find(contains(fname_split, 'LED'));
							tuple.opto_stim = 1;
							optoTuple = key;
							% set opsin
							if contains(exp_name, 'ACR1')
								optoTuple.opsin = 'GtACR1';
							elseif contains(exp_name, 'ACR2')
								optoTuple.opsin = 'GtACR2';
							elseif contains(exp_name, 'CsChrimson')
								optoTuple.opsin = 'CsChrimson';
							end
							optoTuple.nd_25 = sum(contains(fname_split, 'ND25'));
							optoTuple.nd_3 = sum(contains(fname_split, 'ND3'));

							% the following logic is a hack to deal with filename inconsistency
							if contains(fname, 'LED_pulse')
								% TODO: 7/23 
								optoTuple.led_power = fname_split{iLed + 2};
								optoTuple.led_wavelength = fname_split{iLed - 1};
								optoTuple.wave_name = fname_split{iLed - 2};
								if contains(fname, 'same_waveform')		% Only needed for 2019-07-09 and 2019-07-19 experiments
									optoTuple.led_power = fname_split{iLed + 4};
									optoTuple.wave_name = odorTuple.wave_name;
								end
							elseif contains(fname, 'LED')
								% TODO: 7/23 
								optoTuple.led_power = fname_split{iLed - 2};
								optoTuple.led_wavelength = fname_split{iLed - 1};
								optoTuple.wave_name = fname_split{iLed - 3};
							% handle mercury lamp trials
							elseif contains(fname, '2.5s_shutter_pulse')
								optoTuple.led_power = 0;
								optoTuple.led_wavelength = 0;
								optoTuple.mercury_lamp = 1;
								optoTuple.wave_name = '2.5s';
							end

							% check LED trials for valid wavelength & LED power
							if contains(fname, 'LED')
								optoTuple.led_wavelength = str2num(optoTuple.led_wavelength);
								if isempty(optoTuple.led_wavelength)
									warningMsg = ['Unrecognized opto wavelength for: ' fname];
									warning(warningMsg)
									skippedFiles(end+1).fname = fname;
									skippedFiles(end).dataPath = dataPath;
									skippedFiles(end).warningMsg = warningMsg;
									break	
								end
								if any(optoTuple.led_wavelength == [470, 480, 490])
									optoTuple.led_wavelength = 470;
								end

								if contains(optoTuple.led_power, 'max')
									optoTuple.led_power = 100;
								else 
									optoTuple.led_power = str2num(optoTuple.led_power(1:end-1));
								end
							end

							% check opto trials for valid waveform
							if contains(optoTuple.wave_name, keys(waveNameLookup))
                                optoTuple.wave_name = waveNameLookup(optoTuple.wave_name);
                            % TODO: read in 'same_waveform' opto trials
                            % (e.g., NP1227 2019-07-09)
							else
								warningMsg = ['Unrecognized opto waveform for: ' fname];
								warning(warningMsg)
								skippedFiles(end+1).fname = fname;
								skippedFiles(end).dataPath = dataPath;
								skippedFiles(end).warningMsg = warningMsg;
								break		
							end
						end

						% insert tuples and make part / computed tables
						if tuple.odor_stim && ~tuple.opto_stim
							self.insert(tuple);
							make(ephys.TrialOdor, odorTuple);
						elseif ~tuple.odor_stim && tuple.opto_stim
							self.insert(tuple);
							try
								make(ephys.TrialOpto, optoTuple);		
							catch
								error(fname)
							end					
						elseif tuple.odor_stim && tuple.opto_stim

							% LED is on on odd trials, even trials if 'reversed'
							% LED is never on on the 1st trial - 'clearing_trial'
							opto_on = logical(mod(iTrial, 2));	
							if contains(fname, 'reversed')
								opto_on = ~opto_on;
							end
							if opto_on && iTrial ~= 1
								self.insert(tuple);
								make(ephys.TrialOdor, odorTuple);
								try
									make(ephys.TrialOpto, optoTuple);
								catch
									error(fname)
								end
							else
								tuple.opto_stim = 0;
								self.insert(tuple);
                                try
                                    make(ephys.TrialOdor, odorTuple);
                                catch
                                    error(fname)
                                end
                            end
						% current step trials
						elseif contains(fname, 'current_steps')
							self.insertExtCmdTrial(key, tuple);
						else
							warningMsg = ['Unrecognized file name: ', fname];
							warning(warningMsg)
							skippedFiles(end+1).fname = fname;
							skippedFiles(end).dataPath = dataPath;
							skippedFiles(end).warningMsg = warningMsg;
							break				
						end

						if isfile(analyzed_file)
							self.insertAnalyzed(key, f_analyzed, iTrial, 0);
						end
					end
					trialId = trialId - 1;
				end
				trialId = trialId + 1;
			end
			save('skippedFiles.mat', 'skippedFiles');
    	end

    	function tuple = addTrace(self,tuple,data,c)
    		% and related recording / amplifier metadata.

    		% hack to clean up DAQ contamination
    		% at one point (winter 2016/17) the 7th channel (output copy) was
    		% improperly grounded and bleeding into the other channels
    		% apparently this only occured on trials where an external command
    		% was being sent from the computer (e.g., spacer trials)
    		if size(data,2) > 6 && abs(median(data(:,6))) > 0.25
    			data = data - data(:,7);
    		end

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

			scaling_factor = 1e3 / tuple.gain; 		% x1000 factor for (V / nA) -> (mV / pA) conversion)
			
			if strcmp('V-clamp', tuple.mode)
				tuple.voltage = data(:, c.V_CH) * (1e3/10);
				tuple.current = data(:, c.SO_CH) * scaling_factor;
				tuple.holding_command = round(median(tuple.voltage));
			else
				tuple.voltage = data(:, c.SO_CH) * scaling_factor;
				tuple.current = data(:, c.I_CH) * (1e3/c.I_SCALING);
				tuple.resting_v = median(tuple.voltage);
			end
			tuple.holding_current = round(median(tuple.current));
		end

		function insertExtCmdTrial(self,key,tuple)
			tuple.ext_cmd = 1;
			extTuple = key;
			if contains(tuple.file_name, 'current_steps')
				iExt = (3.5 * tuple.samp_rate):(4 * tuple.samp_rate);
				extTuple.wave_name = 'current_step';
			elseif tuple.spacer_trial || (~tuple.trial_block)
				iExt = (0.75 * tuple.samp_rate):(1 * tuple.samp_rate);
				extTuple.wave_name = 'r_input_test';
			end
			
			extTuple.cmd_units = 'pA';	% Right now these ExtCmd trials are assumed to be in Iclamp
			extTuple.cmd_mag = median(tuple.current(iExt)) - median(tuple.current);
			extTuple.response_mag = median(tuple.voltage(iExt)) - median(tuple.voltage);
            tuple.r_input = extTuple.response_mag / extTuple.cmd_mag;
            if isinf(tuple.r_input)
                tuple.r_input = -1;
            end
			self.insert(tuple);
			make(ephys.TrialExtCmd, extTuple);
		end

		function insertAnalyzed(self, key, f, iTrial, is_spacer)
			tuple = key;

			tuple.bandpass_cutoff = f.bandpassCutoff;
			tuple.ds_factor = f.dsFactor;
			tuple.med_filt_window = f.medFiltWindow;
			
			tuple.psth_bin_size = f.psthVar.binSize;
			tuple.psth_method= f.psthVar.method;
			
			tuple.spd_min_prom = f.spd.minProm;
			tuple.spd_max_width = f.spd.maxWidth;
			tuple.spd_min_width = f.spd.minWidth;
			tuple.spd_min_distance = f.spd.minDistance;

			if is_spacer
				tuple.spike_inds = f.spacerSpikeInds{iTrial};
				tuple.psth = f.spacerPsth(:, iTrial);
				tuple.vm_filt = f.spacerVmFilt(:, iTrial);
			else
				tuple.spike_inds = f.spikeInds{iTrial};
				tuple.psth = f.psth(:, iTrial);
				tuple.vm_filt = f.VmFilt(:, iTrial);
			end
			insert(ephys.Analyzed, tuple);
		end
    end
end
% TODO: 7/16 - clean up Trial table definition & write Trial import logic!! We're ready!
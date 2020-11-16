%% Populate Waveform

% R input test waveform
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/r_input_test.mat');
insert(ephys.Waveform, s);

% Most common 1s stimulus
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/1_second.mat');
insert(ephys.Waveform, s);

% Most common 2s stimulus
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/2_seconds.mat');
insert(ephys.Waveform, s);

% Most common 8s stimulus
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/8_seconds.mat');
insert(ephys.Waveform, s);

% Most common fluctuating odor stimulus. 
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/var_freq_stim.mat');
for iWav = 1:length(s)
	insert(ephys.Waveform, s(iWav));
end

% 'fastmed' is 2f the 'med' ~1.7Hz stimulus, first exp using it was on 2020-09-17
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/Emre.mat');
insert(ephys.Waveform, s);

% 'Emre' stimulus - 10Hz 50p duty for 6s
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/Emre.mat');
insert(ephys.Waveform, s);

% current step waveform
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/current_step.mat');
insert(ephys.Waveform, s);

% 0.1s and 0.05s (NP1227 CsChrimson 1 off experiments, 2019-07-09)
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/0p1s.mat');
insert(ephys.Waveform, s);
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/0p05s.mat');
insert(ephys.Waveform, s);

% 2.5s_shutter_pulse - mercury lamp experiments
load('/Users/asa/Documents/Code/ephys_meta_analysis/dj_ephys/stimuli/2p5s.mat');
insert(ephys.Waveform, s);

% %% Populate OdorStim
% waveform = {'fast', 'med', 'slow', '1_second', '2_seconds'}
% odor = {'2-heptanone', 'farnesol'};
% concentration = [8, 7, 6, 5, 4, 3, 2, 1];
% for iWav = 1:length(waveform)
% 	for iOdor = 1:length(odor)
% 		for iConc = 1:length(concentration)
% 			insert(dj_ephys.OdorStim, {odor{iOdor}, concentration(iConc), waveform{iWav}});
% 		end
% 	end
% end
% 
% %% Populate OptoStim
% % opsin = {'GtACR1', 'GtACR2', 'CsChrimson', 'ReaChR'}
% opsin = {'GtACR1', 'GtACR2', 'CsChrimson'}	% TODO: add back 'ReaChR'
% nd_25 = [0, 1, 2];
% nd_3 = [0, 1, 2];
% mercury_lamp = [0, 1];
% led_power = 5:5:100		% TODO: Will have to add other values later
% led_wavelength = [470, 565]
% waveform = {'fast', 'med', 'slow', '1_second', '2_seconds', '8_seconds', 'Emre'}
% for iWav = 1:length(waveform)
% 	for iOpsin = 1:length(opsin)
% 		for iND_25 = 1:length(nd_25)
% 			for iND_3 = 1:length(nd_3)
% 				for iMerc = 1:length(mercury_lamp)
% 					if logical(mercury_lamp(iMerc))
% 						insert(dj_ephys.OptoStim, ...
% 							   {opsin{iOpsin}, ...
% 							   	nd_25(iND_25), ...
% 							   	nd_3(iND_3), ...
% 							   	mercury_lamp(iMerc), ...
% 							   	0, ...
% 							   	0, ...
% 							   	waveform{iWav}});
% 					else
% 						for iLedPower = 1:length(led_power)
% 							for iLedWav = 1:length(led_wavelength)
% 								if (nd_25(iND_25) + nd_3(iND_3)) >= 3
% 									continue
% 								end
% 								insert(dj_ephys.OptoStim, ...
% 									   {opsin{iOpsin}, ...
% 									   	nd_25(iND_25), ...
% 									   	nd_3(iND_3), ...
% 									   	mercury_lamp(iMerc), ...
% 									   	led_power(iLedPower), ...
% 									   	led_wavelength(iLedWav), ...
% 									   	waveform{iWav}});
% 							end
% 						end
% 					end
% 				end
% 			end
% 		end
% 	end
% end				   	

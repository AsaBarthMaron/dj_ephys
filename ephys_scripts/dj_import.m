t = readtable('/Users/asa/Downloads/2020-07-14_Experiment_table_import.xlsx')
s = table2struct(t)
for i = 1:length(s)
    s(i).data_path = ['/Volumes/SSD_DATA', s(i).data_path(21:end)]
end
s = rmfield(s, 'Exp__')
s = rmfield(s, 'Stack')
s = rmfield(s, 'CellType')
s = rmfield(s, 'PhysiologyComments')
s = rmfield(s, 'AnatomyComments')
s = rmfield(s, 'ExpressionComments')
s = s([61:63, 117, 134, 155])
s(1).data_path = '/Volumes/SSD_DATA/2017-05-24'
s(2).data_path = '/Volumes/SSD_DATA/2017-05-28'
s(3).data_path = '/Volumes/SSD_DATA/2017-05-29'
s(4).data_path = '/Volumes/SSD_DATA/2019-07-26_2'
s(5).data_path = '/Volumes/SSD_DATA/2019-10-25'
s(6).data_path = '/Volumes/SSD_DATA/2020-02-03'

insert(ephys.Experiment, s)

%% 
t = readtable('/Users/asa/Downloads/2020-07-14_Experiment_table_import.xlsx')
s = table2struct(t)
for i = 1:length(s)
    s(i).data_path = ['/Volumes/SSD_DATA', s(i).data_path(21:end)]
end
s = rmfield(s, 'Exp__')
s = rmfield(s, 'Stack')
s = rmfield(s, 'CellType')
s = rmfield(s, 'PhysiologyComments')
s = rmfield(s, 'AnatomyComments')
s = rmfield(s, 'ExpressionComments')
s = s(155)
s(1).data_path = '/Volumes/SSD_DATA/2020-02-03'

insert(ephys.Experiment, s)

%%
t = readtable('/Users/asa/Downloads/2020-07-23_Experiment_table_import.xlsx')
s = table2struct(t)
for i = 1:length(s)
    s(i).data_path = ['/Volumes/SSD_DATA', s(i).data_path(21:end)]
end
s = rmfield(s, 'Exp__')
s = rmfield(s, 'Stack')
s = rmfield(s, 'CellType')
s = rmfield(s, 'PhysiologyComments')
s = rmfield(s, 'AnatomyComments')
s = rmfield(s, 'ExpressionComments')
i_exclude = [1, 3]  % #1 has crazy electrical drift, #3 has offset of 60.6mV from forgetting to zero the pipette (gives Infs upon insertion, rinput?).
i_exclude = 1:79;
% i_exclude = [1:130, 133:156];
s(i_exclude) = [];
insert(ephys.Experiment, s)

% dj Setup
ephys.Mode
ephys.Gain
ephys.FilterFreq
populate(ephys.Amplifier)
populate(ephys.Cell)
ephys.Waveform

draw(dj.ERD(ephys.getSchema))

%% Get trial metadata
trial_query = ephys.Trial;
fields = {trial_query.header.attributes.name};
trial_table = fetch(trial_query, 'resting_v', 'holding_current', 'holding_command', 'r_input', 'trial_name', 'file_name', 'odor_stim', 'clearing_trial', 'opto_stim', 'ext_cmd', 'seal_test', 'spacer_trial', 'trial_block');
trial_table = struct2table(trial_table);

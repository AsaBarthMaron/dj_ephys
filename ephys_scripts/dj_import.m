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
s = s([61:63, 117, 134])
s(1).data_path = '/Volumes/SSD_DATA/2017-05-24'
s(2).data_path = '/Volumes/SSD_DATA/2017-05-28'
s(3).data_path = '/Volumes/SSD_DATA/2017-05-29'
s(4).data_path = '/Volumes/SSD_DATA/2019-07-26_2'
s(5).data_path = '/Volumes/SSD_DATA/2019-10-25'

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
s = s(134)
s(1).data_path = '/Volumes/SSD_DATA/2019-10-25'

insert(ephys.Experiment, s)

%% dj Setup
ephys.Mode
ephys.Gain
ephys.FilterFreq
populate(ephys.Amplifier)
populate(ephys.Cell)
ephys.Waveform

draw(dj.ERD(ephys.getSchema))
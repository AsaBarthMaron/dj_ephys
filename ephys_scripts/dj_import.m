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
s = s(61:63)
s(1).data_path = '/Volumes/SSD_DATA/2017-05-24'
s(2).data_path = '/Volumes/SSD_DATA/2017-05-28'
s(3).data_path = '/Volumes/SSD_DATA/2017-05-29'

insert(ephys.Experiment, s)
%% dj Setup
populate(ephys.Cell)
populate_stimuli
populate(ephys.Trial)
% dj_ephys.OptoStim
% dj_ephys.OdorStim
% dj_ephys.ExtCmd
% dj_ephys.TrialOdor
% dj_ephys.TrialOpto
% dj_ephys.TrialExtCmd
% dj_ephys.TrialSealTest
draw(dj.ERD(ephys.getSchema))
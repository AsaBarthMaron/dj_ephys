t = readtable('/Volumes/SSD_DATA/2020-07-27_exp_table_health_cutoff.xlsx');
t(contains(t.trialToCutData, '-'), :) = [];

for iExp = 1:size(t,1)
    expId = t.exp_id(iExp);
    trialToCutData = t.trialToCutData{iExp};
    del(ephys.Trial & ['exp_id=' num2str(expId)] & ['trial_id>=' trialToCutData]);
end
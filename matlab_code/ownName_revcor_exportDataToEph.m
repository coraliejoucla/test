if (~isdeployed)
    pathPrograms = 'G:\MATLAB\analysisCode';
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'D:\PROCESSED EEG DATA\2021-own-name-revcor';

fileList = uipickfiles('FilterSpec', 'D:\PROCESSED EEG DATA\2021-own-name-revcor\EEG', 'Type', {'*.set', 'eeglab-files'}, 'REFilter', 'finalEEG'); % pick .set file

% run eeglab to add path properly
run 'G:\eeglab2020_0\eeglab.m'
close(gcf);

for iter = 2:length(fileList)
    file = char(fileList{iter});
    [filepath, filename, ext] = fileparts(file);
    EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);
    EEG.setname = filename(end-3:end);
    EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
    EEG.icachansind = [];
    EEG.data = EEG.data(:, 101:700, :);
    EEG.xmin = 0.001;
    EEG = eeg_checkset(EEG);

    folder_save = [path_save, filesep, 'own_name_revcor_subject_', EEG.setname];
    if ~isfolder(folder_save)
        mkdir(folder_save)
    end

    for ii = 1:size(EEG.data, 3)
        saveName = [folder_save, filesep, 'own_name_revcor_subject_', EEG.setname, '_epoch_', num2str(ii),'.eph'];
        saveeph(saveName,EEG.data(:, :, ii)', 1000);
    end
end
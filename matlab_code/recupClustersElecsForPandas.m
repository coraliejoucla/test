%% MODIFY PATHS ACCORDINGLY
if (~isdeployed)
    pathPrograms = 'G:\MATLAB\analysisCode'; %%%%% modify
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'G:\MATLAB\results'; %%%%% modify

fileList = uipickfiles('FilterSpec', 'D:\PROCESSED EEG DATA\2021-own-name-revcor', 'Type', {'*.set', 'eeglab-files'}, 'REFilter', 'finalEEG_soft'); % pick .set file

% run eeglab to add path properly
run 'G:\eeglab2020_0\eeglab.m'
close(gcf);

savingSuffix = 'ownName_revcor_cluster_';

baselineLength = 100;
load([path_save, filesep, 'allSubjectsClusters.mat'])

count = 1;
for ii = 1:length(allSubjectsClusters)
    % setting EEGLab options to double precision
    pop_editoptions('option_single', false);
    
    subjectNumber = allSubjectsClusters(ii).subjectNumber;
    [filepath, filename, ext] = fileparts(fileList{subjectNumber});
    
    fprintf('ii = %d', ii);

    % eeg loading
    if isequal(ii, 1)
        finalEEG = pop_loadset('filename', [filename, ext], 'filepath', filepath);
    elseif ii>1
        if ~isequal(subjectNumber, allSubjectsClusters(ii-1).subjectNumber)
            finalEEG = pop_loadset('filename', [filename, ext], 'filepath', filepath);
        end
    end

    % retriving subject ID
    subjectName = filename(end-3:end);
    disp(subjectName);

    EEG = finalEEG;
    if isequal(allSubjectsClusters(ii).sign, 'pos')
        EEG.data = finalEEG.stats.posMatrix;
    elseif isequal(allSubjectsClusters(ii).sign, 'neg')
        EEG.data = finalEEG.stats.negMatrix;
    end
    EEG.trials = 1;
    EEG = eeg_checkset(EEG);

    start = allSubjectsClusters(ii).start + baselineLength;
    stop = allSubjectsClusters(ii).stop + baselineLength;
    elecsNumber = [];
    for elec = 1:64
        if any(EEG.data(elec,start:stop))
%             elecsNumber = [elecsNumber elec];
            allSubjectsClustersFinal(count).subject = allSubjectsClusters(ii).subject;
            allSubjectsClustersFinal(count).cluster = allSubjectsClusters(ii).cluster;
            allSubjectsClustersFinal(count).sign_t_stats = allSubjectsClusters(ii).sign;
            allSubjectsClustersFinal(count).start_time = allSubjectsClusters(ii).start;
            allSubjectsClustersFinal(count).stop_time = allSubjectsClusters(ii).stop;
            allSubjectsClustersFinal(count).elecs_cluster = EEG.chanlocs(elec).labels;
            count = count+1;
        end
    end
end

save([path_save, filesep, 'allSubjectsClusters.mat'], 'allSubjectsClusters');

writetable(struct2table(allSubjectsClustersFinal), 'all_subjects_clusters.csv')
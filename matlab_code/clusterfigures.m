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
new_frequentMarker = 'frequent';
new_deviantMarker = 'deviant';
baselineRange = [-100 0]; % in ms

finalMarkerList = {new_frequentMarker, new_deviantMarker};

allSubjectsClusters = readtable('G:\WORK\own-name-revcor\analysis\data2\all_subjects_clusters.csv');

% Pipeline
for iter = 1:length(fileList) % i.e. for each subject

      % setting EEGLab options to double precision
    pop_editoptions('option_single', false);
    
    [filepath, filename, ext] = fileparts(fileList{iter});
    
    % eeg loading
    finalEEG = pop_loadset('filename', [filename, ext], 'filepath', filepath);

    % retriving subject ID
    subjectName = filename(end-3:end);
    subjectNumber = str2double(subjectName);
    
    maxCluster = max(allSubjectsClusters(allSubjectsClusters.subject == 6, :).cluster);

    for cluster = 1:maxCluster
        subjectCluster = allSubjectsClusters(allSubjectsClusters.subject == subjectNumber & allSubjectsClusters.cluster == cluster,:);
        
        start = subjectCluster.start_time(1);
        stop = subjectCluster.stop_time(1);

        elecsNumber = zeros(1, height(subjectCluster));
        for jj = 1:height(subjectCluster)
            elecsNumber(jj) = strmatch(subjectCluster.elecs_cluster(jj), {finalEEG.chanlocs.labels}, 'exact');
        end
        
        data = zeros(finalEEG.nbchan, finalEEG.pnts);
        data(elecsNumber, :) = 1;

        EEG = finalEEG; 
        EEG.data = data;
        EEG.trials = 1;
        EEG = eeg_checkset(EEG);

%         attention, topoplot prend en compte la baseline
        titleFig = "Subject " + num2str(subjectNumber) + ", cluster " + num2str(cluster) + ", " + num2str(start) + "-" + num2str(stop) + ", " + subjectCluster.sign_t_stats(1);

        pop_topoplot(EEG,...
            1,... % plot ERP 1 or ICA components 0
            250,... % latency to plot
            char(titleFig),... % title for figure
            [1 1],... % organize subplots
            0,... % plot associated dipole(s) for scalp map if present in dataset
            'electrodes', 'labels',...
            'maplimits', [0 1]);
        set(gcf, 'Position', get(0, 'Screensize'));
        saveName = strrep(char(titleFig), ' ', '_');
        saveName = strrep(saveName, ',', '');
        saveas(gcf, [path_save, filesep, saveName, '.png']);
        close(gcf);
        
    end
end


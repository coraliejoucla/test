if (~isdeployed)
    pathPrograms = 'G:\MATLAB\analysisCode';
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'D:\PROCESSED EEG DATA\2021-own-name-revcor';

fileList = uipickfiles('FilterSpec', 'D:\PROCESSED EEG DATA\2021-own-name-revcor\EEG', 'Type', {'*.set', 'eeglab-files'}, 'REFilter', 'preprocessed'); % pick .set file

% run eeglab to add path properly
run 'G:\eeglab2020_0\eeglab.m'
close(gcf);

ALLEEG = [];
for iter = 1:length(fileList)
    %% 3.3 Data selection and aggregation
    %% 3.3.1 Loading datasets in EEGLAB, group version
    file = char(fileList{iter});
    [filepath, filename, ext] = fileparts(file);
    EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);

    if ~isequal(iter, 10)
        EEG.setname = filename(end-3:end);
        EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
        EEG.icachansind = [];
        EEG.data = EEG.data(:, 101:700, :);
        EEG.xmin = 0.001;
        EEG = eeg_checkset(EEG);
    else
        EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
        EEG.icachansind = [];
        EEG = eeg_checkset(EEG);
    end
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
end

%% 3.3.2 Select data for microstate analysis
[EEG, ALLEEG] = pop_micro_selectdata(EEG, ALLEEG,...
    'datatype', 'ERPavg',...
    'avgref', 0, ...
    'normalise', 1, ...
    'dataset_idx', 1:10);

% store data in a new EEG structure
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% 3.4 Microstate segmentation
% select the "average dataset" and make it the active set
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 10, 'retrieve', 10+1, 'study', 0);
% Perform the microstate segmentation
EEG = pop_micro_segment(EEG, ...
    'algorithm', 'taahc', ...
    'sorting', 'Global explained variance', ... % 'Global explained variance','Chronological appearance','Frequency'
    'Nmicrostates', 2:8, ... 
    'verbose', 0, ...
    'normalise', 1); % wheighing each dataset equally in the microstate clustering. Might skew the weights if datasets contain high amplitude artefacts.

EEG = pop_micro_smooth(EEG, 'label_type', 'segmentation', ...
        'smooth_type', 'reject segments', ...
        'minTime', 30, ...
        'polarity', 1);

[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% 3.5 Review and select microstate segmentation 
%% 3.5.1 Plot microstate prototype topographies
% figure;
% MicroPlotTopo(EEG, 'plot_range', []);
%     saveas(gcf, ['own_name_revcor_microstates_',EEG.setname, '.png'], 'png');
%     close(gcf);

%% 3.5.2 Select active number of microstates
EEG = pop_micro_selectNmicro(EEG, 'Measures', 'ALL', 'do_subplots', 0);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% Import microstate prototypes from other dataset to the datasets that should be back-fitted
for ii = 1:length(ALLEEG)-1
    fprintf('Importing prototypes and backfitting for dataset %i\n',ii)
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ii,'study',0);
    EEG = pop_micro_import_proto(EEG, ALLEEG, 11);

    % 3.6 Back-fit microstates on EEG
    EEG = pop_micro_fit(EEG, 'polarity', 1);

    % 3.7 Temporally smooth microstates labels
    EEG = pop_micro_smooth(EEG, 'label_type', 'backfit', ...
        'smooth_type', 'reject segments', ...
        'minTime', 30, ...
        'polarity', 1);

    % 3.9 Calculate microstate statistics
    EEG = pop_micro_stats(EEG, 'label_type', 'backfit', 'polarity', 1);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    %     pop_saveset(EEG, 'filepath', filepath, 'filename', filename);
%     EEG.data = mean(EEG.data, 3);
%     figure;
%     MicroPlotSegments(EEG, 'label_type', 'backfit', ...
%         'plotsegnos', 'none', 'plottopos', 1);
    %
    %     saveas(gcf, ['own_name_revcor_microstatesGroup_',EEG.setname, '.png'], 'png');
    %     close(gcf);
end


%% 3.6 3.7 3.9 bis same for average to plot
fprintf('Importing prototypes and backfitting for average dataset')

[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',11,'study',0);
%     fprintf('EEG number %i\n', EEG.event.urevent)
EEG = pop_micro_import_proto(EEG, ALLEEG, length(ALLEEG));

% 3.6 Back-fit microstates on EEG
EEG = pop_micro_fit(EEG, 'polarity', 1);

% 3.7 Temporally smooth microstates labels
EEG = pop_micro_smooth(EEG, 'label_type', 'backfit', ...
    'smooth_type', 'reject segments', ...
    'minTime', 30, ...
    'polarity', 1);

% 3.9 Calculate microstate statistics
EEG = pop_micro_stats(EEG, 'label_type', 'backfit', 'polarity', 1);

%% 3.8 Illustrating microstate segmentation
% [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',1,'study',0);
figure;
MicroPlotSegments(EEG, 'label_type', 'backfit', ...
    'plotsegnos', 'all', 'plottopos', 1);
% saveas(gcf, ['own_name_revcor_microstatesSegmentation_',EEG.setname, '.png'], 'png');
% close(gcf);

%% labels and GMD for each backfitted trial
for iter = 1:length(ALLEEG)-1
    GMD = ALLEEG(iter).microstate.fit.GMDorder;
    labels = ALLEEG(iter).microstate.fit.labels;
    labels = labels';
    labels = reshape(labels,1,[]);

    for ii = 1:length(labels)
        GMDfinal(ii) = GMD(labels(ii), ii);
    end
    GMD_microstates = squeeze(reshape(GMDfinal, 1, ALLEEG(iter).pnts, ALLEEG(iter).trials))';
%     save(['GMD_group_microstates_', ALLEEG(iter).setname, '.mat'], 'GMD_microstates');
    clear labels
    clear GMDfinal
end

%% labels from backfitted grand average and GMD for each backfitted trial

for iter = 1:length(ALLEEG)-1
    GMD = ALLEEG(iter).microstate.fit.GMDorder;
    labels = EEG.microstate.fit.labels;
    labels = repmat(labels, [size(ALLEEG(iter).microstate.fit.labels, 1), 1]);
    labels = labels';
    labels = reshape(labels,1,[]);

    for ii = 1:length(labels)
        GMDfinal(ii) = GMD(labels(ii), ii);
    end
    GMD_microstates = squeeze(reshape(GMDfinal, 1, ALLEEG(iter).pnts, ALLEEG(iter).trials))';
%     save(['GMD_group_microstates_grandAvg_', ALLEEG(iter).setname, '.mat'], 'GMD_microstates');
%     clear labels
%     clear GMDfinal
end

% test = GMD(1, :);
subj = 10;
bob = squeeze(reshape(ALLEEG(subj).microstate.fit.GMDorder, 5, ALLEEG(subj).pnts, ALLEEG(subj).trials));
meanbob = mean(bob,3);
figure
for state = 1:5
    plot(meanbob(state,:))
    hold on
end


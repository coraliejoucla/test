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

%% 3.3 Data selection and aggregation

%% 3.3.1 Loading datasets in EEGLAB
% for iter = 1:length(fileList)
%     % load file
%     file = char(fileList{iter});
%     [filepath, filename, ext] = fileparts(file);
%     EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);
%     EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
%     [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
% %     eeglab redraw % updates EEGLAB datasets
% end

%% 3.3.1 individuel
ALLEEG = [];
for iter = 1%:length(fileList)
    % load file
    file = char(fileList{iter});
    [filepath, filename, ext] = fileparts(file);
    EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);
    EEG.setname = filename(end-3:end);
    EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
    EEG.icachansind = [];
    EEGtmp = EEG;
    for ii = 1:size(EEG.data, 3)
        EEGtmp.data = EEG.data(:, 101:700, ii);
        EEGtmp.pnts = size(EEGtmp.data, 2);
        EEGtmp.trials = 1;
        EEGtmp.event = EEG.event(ii);
        EEGtmp.epoch = [];
        [ALLEEG, EEGtmp] = eeg_store(ALLEEG, EEGtmp, 0);
    end
end
%% 3.3.2 Select data for microstate analysis
[EEG, ALLEEG] = pop_micro_selectdata(EEG, ALLEEG,...
    'datatype', 'ERPavg',...
    'avgref', 0, ...
    'normalise', 1, ...
    'dataset_idx', 1:size(EEG.data, 3));
CURRENTSET = length(ALLEEG);
% store data in a new EEG structure
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% 3.4 Microstate segmentation
% select the "average dataset" and make it the active set
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, size(EEG.data, 3), 'retrieve', size(EEG.data, 3)+1);
% Perform the microstate segmentation
EEG = pop_micro_segment(EEG, ...
    'algorithm', 'taahc', ...
    'sorting', 'Global explained variance', ...
    'Nmicrostates', 2:6, ...
    'verbose', 1, ...
    'normalise', 0);

%% ADD SMOOTHING HERE
CURRENTSET = length(ALLEEG); % ici le dernier dataset car on update
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% 3.5 Review and select microstate segmentation

%% 3.5.1 Plot microstate prototype topographies
figure;
MicroPlotTopo(EEG, 'plot_range', []);

%% 3.5.2 Select active number of microstates
EEG = pop_micro_selectNmicro(EEG);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% Import microstate prototypes from other dataset to the datasets that should be back-fitted
% note that dataset number 5 is the GFPpeaks dataset with the microstate
% prototypes
for ii = 1:length(ALLEEG)-1
    fprintf('Importing prototypes and backfitting for dataset %i\n',ii)
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ii,'study',0);
    EEG = pop_micro_import_proto(EEG, ALLEEG, length(ALLEEG));


    %% 3.6 Back-fit microstates on EEG
    EEG = pop_micro_fit(EEG, 'polarity', 0);

    %% 3.7 Temporally smooth microstates labels
    EEG = pop_micro_smooth(EEG, 'label_type', 'backfit', ...
        'smooth_type', 'reject segments', ...
        'minTime', 30, ...
        'polarity', 0);

    %% 3.9 Calculate microstate statistics
    EEG = pop_micro_stats(EEG, 'label_type', 'backfit', 'polarity', 0);

    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
end

%% 3.8 Illustrating microstate segmentation
% Plotting GFP of active microstates for the first 1500 ms for subject 1.
% [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',1,'study',0);
figure;
MicroPlotSegments(EEG, 'label_type', 'backfit', ...
    'plotsegnos', 'all', 'plottopos', 1);




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

nbMicro = [4 4 4 4 4 5 4 5 4 5];

for iter = 2:length(fileList)
    %% 3.3 Data selection and aggregation
    %% 3.3.1 Loading datasets in EEGLAB, individual version
    ALLEEG = [];
    % load file
    file = char(fileList{iter});
    [filepath, filename, ext] = fileparts(file);
    EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);
    EEG.setname = filename(end-3:end);
    EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
    EEG.icachansind = [];
    EEG.data = EEG.data(:, 101:700, :);
    EEG.xmin = 0.001;
    EEG = eeg_checkset(EEG);

    EEGtmp = EEG;
    for ii = 1:size(EEG.data, 3)
        EEGtmp.data = EEG.data(:, :, ii);
        EEGtmp.pnts = size(EEGtmp.data, 2);
        EEGtmp.trials = 1;
        EEGtmp.event = EEG.event(ii);
        EEGtmp.epoch = [];
        [ALLEEG, EEGtmp] = eeg_store(ALLEEG, EEGtmp, 0);
    end

    EEGavg = EEG;
    EEGavg.data = mean(EEG.data, 3);
    EEGavg = eeg_checkset(EEGavg);

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
    [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, size(EEG.data, 3), 'retrieve', size(EEG.data, 3)+1);
    % Perform the microstate segmentation
    EEG = pop_micro_segment(EEG, ...
        'algorithm', 'taahc', ...
        'sorting', 'Global explained variance', ... % 'Global explained variance','Chronological appearance','Frequency'
        'Nmicrostates', nbMicro(iter), ... % nbMicro(iter)
        'verbose', 0, ...
        'normalise', 1); % wheighing each dataset equally in the microstate clustering. Might skew the weights if datasets contain high amplitude artefacts.
    
    EEG = pop_micro_smooth(EEG, 'label_type', 'segmentation', ...
            'smooth_type', 'reject segments', ...
            'minTime', 30, ...
            'polarity', 1);

    CURRENTSET = length(ALLEEG); % ici le dernier dataset car on update
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %% 3.5 Review and select microstate segmentation 
    %% 3.5.1 Plot microstate prototype topographies
%     figure;
%     MicroPlotTopo(EEG, 'plot_range', []);
%     saveas(gcf, ['own_name_revcor_microstates_',EEG.setname, '.png'], 'png');
%     close(gcf);

    %% 3.5.2 Select active number of microstates
%     EEG = pop_micro_selectNmicro_Coralie(EEG, 'Measures', 'ALL', 'do_subplots', 0);
%     EEG = pop_micro_selectNmicro(EEG, 'Measures', 'ALL', 'do_subplots', 0);

%     EEG.microstate.Res.K_act = nbMicro(iter);
%     saveas(gcf, ['own_name_revcor_microstatesMeasures_',EEG.setname, '.png'], 'png');
%     close(gcf);
%     [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    filename = strrep(filename, 'preprocessedData', 'microstatesData');
    pop_saveset(EEG, 'filepath', filepath, 'filename', [filename, '.set']);
%     allSubjectsMicrostates = eeg_store(allSubjectsMicrostates, EEG, 0);
% end
% save('allSubjectsMicrostates', 'allSubjectsMicrostates');
%     save(['save_ALLEEG_microstates_', ])

    %% Import microstate prototypes from other dataset to the datasets that should be back-fitted
    % note that dataset number 5 is the GFPpeaks dataset with the microstate
    % prototypes
%     for ii = 1:length(ALLEEG)-1
%         fprintf('Importing prototypes and backfitting for dataset %i\n',ii)
%         [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ii,'study',0);
%         fprintf('EEG number %i\n', EEG.event.urevent)
%         EEG = pop_micro_import_proto(EEG, ALLEEG, length(ALLEEG));
%     
%         %% 3.6 Back-fit microstates on EEG
%         EEG = pop_micro_fit(EEG, 'polarity', 1);
%     
%         %% 3.7 Temporally smooth microstates labels
%         EEG = pop_micro_smooth(EEG, 'label_type', 'backfit', ...
%             'smooth_type', 'reject segments', ...
%             'minTime', 30, ...
%             'polarity', 1);
%     
%         %% 3.9 Calculate microstate statistics
%         EEG = pop_micro_stats(EEG, 'label_type', 'backfit', 'polarity', 1);
%         [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%     end
    

    %% 3.6 3.7 3.9 bis same for average to plot
    fprintf('Importing prototypes and backfitting for average dataset')

%     [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ii,'study',0);
%     fprintf('EEG number %i\n', EEG.event.urevent)
    EEGavg = pop_micro_import_proto(EEGavg, ALLEEG, length(ALLEEG));

    % 3.6 Back-fit microstates on EEG
    EEGavg = pop_micro_fit(EEGavg, 'polarity', 1);

    % 3.7 Temporally smooth microstates labels
    EEGavg = pop_micro_smooth(EEGavg, 'label_type', 'backfit', ...
        'smooth_type', 'reject segments', ...
        'minTime', 30, ...
        'polarity', 1);

    % 3.9 Calculate microstate statistics
    EEGavg = pop_micro_stats(EEGavg, 'label_type', 'backfit', 'polarity', 1);
%     [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %% 3.8 Illustrating microstate segmentation
    % [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',1,'study',0);
    figure;
    MicroPlotSegments(EEGavg, 'label_type', 'backfit', ...
        'plotsegnos', 'all', 'plottopos', 1);

    states = [];
    for kk = 1:length(EEGavg.microstate.fit.labels)
        if isequal(kk, 1)
        else
            if ~isequal(EEGavg.microstate.fit.labels(kk), EEGavg.microstate.fit.labels(kk-1))
                states = [states, kk];
            end
        end
    end
%     saveas(gcf, ['own_name_revcor_microstatesSegmentation_',EEG.setname, '.png'], 'png');
%     close(gcf);
    
end


% avgStatSet = ALLEEG(end);


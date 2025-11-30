%% PATHS
clear
clc

pathPrograms = 'G:\MATLAB\code_own_name_revcor'; % where this analysis program is stored
if (~isdeployed)
    addpath(genpath(pathPrograms));
    addpath(genpath([pathPrograms, filesep, 'pipeline_code']));
end

eeglabLocation = 'G:\eeglab2020_0';

path_save = 'D:\PROCESSED EEG DATA\2021-own-name-revcor';

fileList = uipickfiles('FilterSpec', 'D:\RAW DATA\2021-own-name-revcor\EEG', 'Type', {'*.vhdr', 'header-files'}); % pick .vhdr file
csvList = uipickfiles('FilterSpec', 'D:\RAW DATA\2021-own-name-revcor\log', 'Type', {'*.csv', 'header-files'}); % pick .csv file

%% PARAMETERS
savingSuffix = 'ownName_revcor_';
nbBlocks = 3;

frequentMarker = 'R 12';
deviantMarker = 'R 13';
originalMarkerList = {frequentMarker, deviantMarker};

new_frequentMarker = 'frequent';
new_deviantMarker = 'deviant';
finalMarkerList = {new_frequentMarker, new_deviantMarker};

flagSoundIn = 1; % 0 for markers, 1 for sound-in

% for pipeline
params.flagDownsample = 1; % 0 for no, 1 for yes
params.downFreq = 128;
params.bandpass_hard = [1 30]; % in Hz
params.bandpass = [0.1 30]; % in Hz
params.epochLimits = [-0.1 0.6]; % in s %%%%% attention, more length overlaps with next trial
params.baselineRange = [-100 0]; % in ms
params.nbChannels = 64; % nb of electrodes recorded

%% INITIALIZATION
% Get the name of the PC the script is executed on
[~, machine_ID] = system('hostname');
% Get the full path of this script at time of execution
m_file_path = matlab.desktop.editor.getActiveFilename;

load('coordinatesPattern_64.mat');

run([eeglabLocation, filesep, 'eeglab.m'])
close(gcf);

% setting EEGLab options to double precision
pop_editoptions('option_single', false);

%% PIPELINE
for iter = 1:length(fileList) % i.e. for each subject
    % eeg loading
    [filePath, fileName, fileExt] = fileparts(fileList{iter});
    originalEEG = pop_loadbv(filePath, [fileName, fileExt]);
    originalEEG.chanlocs = coordinatesPattern;
    
    % csv loading
    csvResults = readtable(csvList{iter});
    
    % retriving subject ID
    idxName = strfind(fileName, '0');
    subjectName = fileName(idxName(1):end);
    
    % Create log file
    log_file_ID = fopen(strcat(path_save, filesep, 'ownName_revcor_log_', subjectName, '.txt'),'a');
    fprintf(log_file_ID,'%s: Script started on machine: %s (MATLAB Version: %s',datestr(now), machine_ID, version);
    fprintf(log_file_ID,'\nFull path of this script:\n%s', m_file_path);
    fprintf(log_file_ID,'\n\n******************** Task and file ********************');
    fprintf(log_file_ID, '\nTask: own name for reverse correlation \n\nEEG file processed: %s', subjectName);
    
    %% Check markers
    markersInventory = checkMarkers(originalEEG, originalMarkerList);
    fprintf(log_file_ID,'\n\n%s %s','marker','number');
    for ii = 1:length(originalMarkerList)
        fprintf(log_file_ID,'\n%s %f',markersInventory{ii, 1}, markersInventory{ii, 2});
    end

    %% check if there is any NaN values in data
    [EEG, sumNaN] = checkNan(originalEEG);
    fprintf(log_file_ID,'\n\n%s NaN have been removed from this EEG file.', num2str(sumNaN));
        
    %% replace markers by names so it is clearer, and taking the "sound-in" marker immediately after identification marker
%     EEG = renameMarkers(EEG, originalMarkerList, finalMarkerList);
    tmpeventtype = {EEG.event.type};
    % replace markers by name
    for jj = 1:length(finalMarkerList)
        Index = strmatch(originalMarkerList{jj}, tmpeventtype, 'exact');
        for ii = 1:length(Index)
            nn = 0;
            for kk = 1:4
                if isequal(EEG.event(Index(ii)+kk).code, 'Stimulus')
                    nn = nn+1;
                else
                    eventID{kk} = EEG.event(Index(ii)+kk+nn).type;
                end
            end
            newStr = strrep(eventID,'R',''); newStr = strrep(newStr,' ',''); newStr = strrep(newStr,'15','0');
            eventNumber = strcat(newStr{:});
            EEG.event(Index(ii)).type = finalMarkerList{jj};
            EEG.event(Index(ii)).code = 'marker';
            EEG.event(Index(ii)).eventNumber = str2num(eventNumber);
        end
    end
    fprintf(log_file_ID,'\n\nReplacement of markers %s by %s, and %s by %s.', frequentMarker, new_frequentMarker, deviantMarker, new_deviantMarker);
    
    % getting rid of any residual events that are of no interest
    EEG = pop_selectevent(EEG, 'code', {'marker', 'Stimulus'}, 'deleteevents','on');
   
    % Delay between marker and sound-in
    meanDelay = delayMarkerSoundin(EEG);
    fprintf(log_file_ID,'\n\nMean delay between markers and sound-in: %s', num2str(meanDelay));

    % selecting only sound-in right after marker
    if isequal(flagSoundIn, 1)
        fprintf(log_file_ID,'\n\nSelection of sound-ins.');
        EEG = selectSoundin(EEG);
    else
        fprintf(log_file_ID,'\n\nSelection of markers.');
    end
    
    % get latency of first and last sound-in to get rid of what is before and after
    EEG = cutUselessEEG(EEG, params.epochLimits); 

    %% add sound number from csv results in event structure
    tmpcsv = (csvResults.sound_file(:));
    for ii = 1:height(csvResults)
        soundFile = tmpcsv{ii};
       if ~contains(soundFile, 'standard')
           I = strfind(soundFile, '.');
           LIST(ii,1) = str2double(soundFile(I(1)+1:(I(2)-1)));
       end
    end
    uniqueLIST = unique(LIST, 'stable');
    
    countDev = 2;
    for ii = 1:length(EEG.event)
        if isequal(EEG.event(ii).type, 'deviant')
            EEG.event(ii).soundNumber = uniqueLIST(countDev);
            countDev = countDev+1;
        end
    end        
    
    for ii = 1:nbBlocks-1
        latencyLastBlock = EEG.event(1+ii*1000).latency;
        latencyNewBlock = EEG.event(1+ii*1000+1).latency;
        
        EEG = pop_select(EEG, 'nopoint', [latencyLastBlock+(params.epochLimits(2)*EEG.srate)+500 latencyNewBlock-(params.epochLimits(1)*EEG.srate)-500]);
    end
    
    %% PREPROCESSING PIPELINE
    finalEEG = eeg_preprocessing_pipeline(EEG, log_file_ID, eeglabLocation, finalMarkerList, params);

    %% Saving EEGlab set (all data)
    save_name = ['finalEEG_preprocessedData_', savingSuffix, subjectName];
    pop_saveset(finalEEG, 'filepath', path_save, 'filename', save_name);

    fprintf(log_file_ID,'\n\nFile saved at: %s', [path_save, filesep, save_name, '.set']);
    fclose(log_file_ID);
end



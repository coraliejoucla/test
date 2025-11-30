%% MODIFY PATHS ACCORDINGLY
if (~isdeployed)
    pathPrograms = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode'; %%%%% modify
    addpath(genpath(pathPrograms));
end

clear
clc

% path_save = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData'; %%%%% modify
path_save = 'D:\WORKPOSTDOC\OWN_NAME\results_jupyter';

fileList = uipickfiles('FilterSpec', 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData', 'REFilter', 'finalEEG_softAfterICA*', 'Type', {'*.set', 'EEGLAB files'}); % pick .vhdr file
csvList = uipickfiles('FilterSpec', 'D:\WORKPOSTDOC\OWN_NAME\results_revcor', 'Type', {'*.csv', 'header-files'}); % pick .csv file

% fileList = {'compressed_EEG_clean_subj18_211123_10.38.mat'};
% csvList = {'D:\WORKPOSTDOC\OWN_NAME\results_revcor\results_subj18_211123_10.38.csv'};
% run eeglab to add path properly
run 'D:\WORKPOSTDOC\eeglab2020_0\eeglab.m'
close(gcf);

%% Analysis
baselineLength = 100; % in ms
segmentNumber = 7;

for iter = 1:length(fileList)
    [filePath, fileName, fileExt] = fileparts(fileList{iter});
    EEG = pop_loadset('filepath', filePath, 'filename', [fileName, fileExt]);
    EEG = pop_selectevent(EEG, 'type', 'deviant', 'deleteevents','on');

%     % Extract for each trial the maximum amplitude between 150-350 ms
%     % post-stimulus on Cz electrode => weight for ponderation
%     for ii = 1:size(EEG.data,3)
%         trial = EEG.data(64, baselineLength+1+150:baselineLength+350, ii);
%         weights(ii) = max(trial);
%     end
    
%     % z-score the weights => ponderation by z-score value
%     zscoredWeigths = zscore(weights);
%     
%     % keep z-score sign => ponderation by z-score sign
%     zscoreSigns = zscoredWeigths;
%     zscoreSigns(zscoreSigns>0)=1;
%     zscoreSigns(zscoreSigns<0)=-1;
%     
%     % retrieve pitch transformations from csv results file
%     finalPitchValues = zeros(length(EEG.event), segmentNumber);
    csvResults = readtable(csvList{iter});
    [csvPath, csvName, csvExt] = fileparts(csvList{iter});
%     for ii = 1:length(EEG.event)
%         resultsByTrial = csvResults(csvResults.stim_id_marker == EEG.event(ii).eventNumber, :);
%         finalPitchValues(ii, 1:segmentNumber) = zscoreSigns(ii)*[resultsByTrial.pitch(1:segmentNumber)];
%     end
%     
%     % finally mean and standard deviation of trials
% 
%     meanPitchBySegment = mean(finalPitchValues, 1);
%     
%     SDPitchBySegment = std(finalPitchValues)/sqrt(693);
%     haut = meanPitchBySegment+SDPitchBySegment;
%     bas = meanPitchBySegment-SDPitchBySegment;
%     
%     % normalisation by RMS
% %     rmsPitch = rms(meanPitchBySegment);
%     
%     plot(meanPitchBySegment)
%     hold on
%     plot(haut)
%     hold on
%     plot(bas)
    
    data = EEG.data;
%     save([path_save, filesep,strrep(csvName, 'results', 'EEG_clean'), '.mat'], 'data');
    writetable(struct2table(EEG.event), [path_save, filesep,strrep(csvName, 'trials', 'events'), csvExt])
    
end




%% MODIFY PATHS ACCORDINGLY
if (~isdeployed)
    pathPrograms = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode'; %%%%% modify
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData'; %%%%% modify

fileList = uipickfiles('FilterSpec', 'D:\WORKPOSTDOC\OWN_NAME\EEG', 'Type', {'*.vhdr', 'header-files'}); % pick .vhdr file %%%%% modify

% run eeglab to add path properly
run 'D:\WORKPOSTDOC\eeglab2020_0\eeglab.m'
close(gcf);

%% Parameters
downsampleFlag = 0; % 0 for no, 1 for yes
downFreq = 100;

bandpass = [0.1 30]; % in Hz
epochLimits = [-0.1 0.47]; % in s %%%%% attention, more length overlaps with next trial
baselineRange = [-100 0]; % in ms

periodToExamine = [100 300];
peakPolarity = 'positive';

% frequentMarker = 'R  4';
% frequentAfterDeviantMarker = 'R  8';
% neutralOwnNameMarker = 'R 12';
% smileOwnNameMarker = 'R 16';
% roughOwnNameMarker = 'R 20';

frequentMarker = 'R  1';
frequentAfterDeviantMarker = 'R  2';
neutralOwnNameMarker = 'R  3';
smileOwnNameMarker = 'R  4';
roughOwnNameMarker = 'R  5';

originalMarkerList = {frequentMarker, neutralOwnNameMarker, smileOwnNameMarker, roughOwnNameMarker};

new_frequentMarker = 'frequent';
new_frequentAfterDeviantMarker = 'frequentAfterDeviant';
new_neutralOwnNameMarker = 'neutralOwnName';
new_smileOwnNameMarker = 'smileOwnName';
new_roughOwnNameMarker = 'roughOwnName';

finalMarkerList = {new_frequentMarker, new_neutralOwnNameMarker, new_smileOwnNameMarker, new_roughOwnNameMarker};

topoFlag = 0; % 0 for pvalue topography, 1 for significant channels
alphaThreshold = 0.05;

nbChannels = 64; % nb of electrodes recorded
chanToStat = {'Cz'};

savingSuffix = 'ownName_NSR_';
load('D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\coordinatesPattern_64.mat');
% coordinatesPattern = originalEEG.chanlocs;
% save('D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\coordinatesPattern_64.mat', 'coordinatesPattern');
coordinatesFile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp';
eventlistPath = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\eventlist.txt';

%% Pipeline
for iter = 1:length(fileList) % i.e. for each subject
    % setting EEGLab options to double precision
    pop_editoptions('option_single', false);
    
    % eeg loading
    [filePath, fileName, fileExt] = fileparts(fileList{iter});
    originalEEG = pop_loadbv(filePath, [fileName, fileExt]);
    originalEEG.chanlocs = coordinatesPattern;
    
    % retriving subject ID
    idxName = strfind(fileName, 'e');
    subjectName = fileName(idxName(end)+1:end);

    %% Check data if necessary
    countResponse = 0;
    countStimulus = 0;
    countNewSegment = 0;
%     countR4 = 0;
%     countR8 = 0;
%     countR12 = 0;
%     countR16 = 0;
%     countR20 = 0;
    countR1 = 0;
    countR2 = 0;
    countR3 = 0;
    countR4 = 0;
    countR5 = 0;

%     for ii = 1:length(originalEEG.event)
%         if isequal(originalEEG.event(ii).code, 'Response')
%             countResponse = countResponse+1;
%         elseif isequal(originalEEG.event(ii).code, 'Stimulus')
%             countStimulus = countStimulus+1;
%         elseif ~isempty(strfind(originalEEG.event(ii).code, 'Segment'))
%             segmentLocations(countNewSegment+1) = ii;
%             countNewSegment = countNewSegment+1;
%         end
%         if isequal(originalEEG.event(ii).type, 'R  4')
%             countR4 = countR4+1;
%         elseif isequal(originalEEG.event(ii).type, 'R  8')
%             countR8 = countR8+1;
%         elseif isequal(originalEEG.event(ii).type, 'R 12')
%             countR12 = countR12+1;
%         elseif isequal(originalEEG.event(ii).type, 'R 16')
%             countR16 = countR16+1;
%         elseif isequal(originalEEG.event(ii).type, 'R 20')
%             countR20 = countR20+1;
%         end
%     end
    for ii = 1:length(originalEEG.event)
        if isequal(originalEEG.event(ii).code, 'Response')
            countResponse = countResponse+1;
        elseif isequal(originalEEG.event(ii).code, 'Stimulus')
            countStimulus = countStimulus+1;
        elseif ~isempty(strfind(originalEEG.event(ii).code, 'Segment'))
            segmentLocations(countNewSegment+1) = ii;
            countNewSegment = countNewSegment+1;
        end
        if isequal(originalEEG.event(ii).type, frequentMarker)
            countR1 = countR1+1;
        elseif isequal(originalEEG.event(ii).type, frequentAfterDeviantMarker)
            countR2 = countR2+1;
        elseif isequal(originalEEG.event(ii).type, neutralOwnNameMarker)
            countR3 = countR3+1;
        elseif isequal(originalEEG.event(ii).type, smileOwnNameMarker)
            countR4 = countR4+1;
        elseif isequal(originalEEG.event(ii).type, roughOwnNameMarker)
            countR5 = countR5+1;
        end
    end

    if countNewSegment > 1
        originalEEG.event(segmentLocations(2:end)) = [];
    end

    %% % downsample (if necessary)
    if isequal(downsampleFlag, 1)
        EEG = pop_resample(originalEEG, downFreq);
    else
        EEG = originalEEG;
    end
    
    %% replace markers by names so it is clearer, and taking the "sound-in" marker immediately after identification marker
    tmpeventtype = {EEG.event.type};
    for jj = 1:length(finalMarkerList)
        Index = strmatch(originalMarkerList{jj}, tmpeventtype, 'exact');
        for ii = 1:length(Index)
            EEG.event(Index(ii)+1).type = finalMarkerList{jj};
        end
    end
    
    % getting rid of any residual events that are of no interest
    EEG = pop_selectevent(EEG, 'type', finalMarkerList, 'deleteevents','on');
    
    %     % selecting only frequent right before deviant
    %     tmpeventtype = {EEG.event.type};
    %     Index = strmatch(new_frequentMarker, tmpeventtype, 'exact');
    %     for ii = 1:length(Index)
    %         if isequal(tmpeventtype{Index(ii)+1}, new_frequentMarker)
    %             EEG.event(Index(ii)).type = 'frequentToEliminate';
    %         end
    %     end
    %     EEG = pop_selectevent(EEG, 'type', finalMarkerList, 'deleteevents','on');
    
    %% Filtering
    % bandpass filtering using erplab butterworth filter
    filteredEEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Cutoff', bandpass, ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    
    % Parks-McClellan notch
    filteredEEG  = pop_basicfilter(filteredEEG, 1:EEG.nbchan, 'Cutoff', 50,...
        'Design', 'notch', 'Filter', 'PMnotch', 'Order', 180);
    
    %% Channels interpolation
    % Retrieving channels locations
    filteredEEG = pop_chanedit(filteredEEG, 'lookup', coordinatesFile);
    
    % Finding electrodes to be interpolated
%     interpolatedEEG = trimOutlier(filteredEEG, 2, 100, Inf, 0); % Inf and 0 because no rejection of datapoints
    
    % plus efficace ?
    [interpolatedEEG, interpolatedEEG.reject.indelec] = pop_rejchan(filteredEEG,'elec',1:filteredEEG.nbchan, 'threshold',5,'norm','on','measure','kurt');
    
    % Makoto alternative
%     interpolatedEEG = clean_rawdata(filteredEEG,...
%         5,... Maximum tolerated flatline duration. (secs).
%         -1,... Highpass -1 = disabled
%         0.85,... Minimum channel correlation
%         4,... Channel abnormality if line noise/signal more than value
%         8,...Data portions whose variance is larger than this threshold relative to the calibration data are removed
%         0.25);% Criterion for removing time windows that were not repaired completely.
% %         vis_artifacts(interpolatedEEG, filteredEEG);
    
    % Bad channels interpolation
    interpolatedEEG = pop_interp(interpolatedEEG, filteredEEG.chanlocs, 'spherical');
    
    %% Average referencing
    avgEEG = fullRankAveRefCoralie(interpolatedEEG); % adds Cz to count of elec AND keep it after AvgRef
    avgEEG = eeg_checkset(avgEEG);
    
    % adding Cz coordinates
    avgEEG.chanlocs(nbChannels).labels = 'Cz'; % so it can be recognized in the file
    avgEEG = pop_chanedit(avgEEG, 'lookup', coordinatesFile);
%     pop_saveset(avgEEG, 'filepath', path_save, 'filename', ['avgEEG_', savingSuffix, subjectName]);

    %% Epoching
    epochEEG = pop_epoch(avgEEG, finalMarkerList, epochLimits); % time limits in seconds
    
    % removing baseline
    finalEEG = pop_rmbase(epochEEG, baselineRange);
    chanList = {finalEEG.chanlocs.labels};
    
    %% Retrieving single-trial ERP latency and amplitude 
    % Retrieving raw measures on each trial
%     chanToExamine = strmatch(chanToStat, chanList, 'exact');
%     erpMeasures = retrieveERPmeasures(avgEEG, baselineRange(1), epochLimits(2)*1000, periodToExamine, eventlistPath, chanToExamine, peakPolarity);
%     erpMeasures(:).event = {finalEEG.event(:).type}';
%     erpMeasures = structofarrays2arrayofstructs(erpMeasures);
%     finalEEG.erpMeasures = erpMeasures;
%     
%     % formatting data for anova
%     idx_markers = cell(length(finalMarkerList), 1);
%     nbTrialsPerCondition = zeros(length(finalMarkerList), 1);
%     for ii = 1:length(finalMarkerList)
%         idx_markers{ii, 1} = strmatch(finalMarkerList{ii}, {finalEEG.erpMeasures.event}, 'exact');
%         nbTrialsPerCondition(ii) = length(idx_markers{ii, 1});
%     end
%     numberToPad = max(nbTrialsPerCondition);
%     
%     data_anovaPeakLatency = NaN(numberToPad, length(finalMarkerList));
%     data_anovaPeakAmplitude = NaN(numberToPad, length(finalMarkerList));
%     for ii = 1:length(finalMarkerList)
%         data_anovaPeakLatency(1:nbTrialsPerCondition(ii), ii) = [finalEEG.erpMeasures(idx_markers{ii, 1}).peakLatency];
%         data_anovaPeakAmplitude(1:nbTrialsPerCondition(ii), ii) = [finalEEG.erpMeasures(idx_markers{ii, 1}).peakAmplitude];
%     end
%     
%     % performing ANOVAS on latencies
%     [~,~,stats] = anova1(data_anovaPeakLatency, finalMarkerList, 'on'); % displayopt: 'on' or 'off' to plot boxes
%     resultsComparison = multcompare(stats,'CType','bonferroni');
%     
%     % plot
%     resultsComparison = array2table(resultsComparison(:, [1,2,6]), 'VariableNames',{'Group1','Group2','pValue'});
%     h = figure;
%     u = uitable('Data',resultsComparison{:,:},'ColumnName',resultsComparison.Properties.VariableNames,...
%         'RowName',resultsComparison.Properties.RowNames, 'Position',[0, 0, 1, 1]);
%     table_extent = get(u,'Extent');
%     set(u,'Position',[1 1 table_extent(3) table_extent(4)])
%     figure_size = get(h,'outerposition');
%     desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+15 table_extent(4)+65];
%     set(h,'outerposition', desired_fig_size);
% 
%     % performing ANOVAS on amplitudes
%     [~,~,stats] = anova1(data_anovaPeakAmplitude, finalMarkerList, 'on'); % displayopt: 'on' or 'off' to plot boxes
%     resultsComparison = multcompare(stats,'CType','bonferroni');
%     
%     % plot
%     resultsComparison = array2table(resultsComparison(:, [1,2,6]), 'VariableNames',{'Group1','Group2','pValue'});
%     h = figure;
%     u = uitable('Data',resultsComparison{:,:},'ColumnName',resultsComparison.Properties.VariableNames,...
%         'RowName',resultsComparison.Properties.RowNames, 'Position',[0, 0, 1, 1]);
%     table_extent = get(u,'Extent');
%     set(u,'Position',[1 1 table_extent(3) table_extent(4)])
%     figure_size = get(h,'outerposition');
%     desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+15 table_extent(4)+65];
%     set(h,'outerposition', desired_fig_size);

    %% Saving EEGlab set (all data)
    pop_saveset(finalEEG, 'filepath', path_save, 'filename', ['finalEEG_', savingSuffix, subjectName]);
    %     finalEEG = pop_loadset('filepath', path_save, 'filename', ['finalEEG_', savingSuffix, subjectName, '.set']);
    
    %% INTRA-SUBJECT STATISTICS
    %% Create study for intra-subject statistics
    ALLEEG = [];
    for ii = 1:length(finalMarkerList)
        bobby = pop_selectevent(finalEEG, 'type', finalMarkerList{ii}, 'deleteevents','on');
        ALLEEG = eeg_store(ALLEEG, bobby);
        ALLEEG(ii).setname = [finalMarkerList{ii}, '_', subjectName];
        ALLEEG(ii).subject = subjectName;
        ALLEEG(ii).condition = finalMarkerList{ii};
%             pop_saveset(ALLEEG(1), 'filepath', path_save, 'filename', [finalMarkerList{ii}, '_', subjectName]);
    end
    
    % 'frequent'    'neutralOwnName'    'smileOwnName'    'roughOwnName'
%     ALLEEG = [];
%     ALLEEG = eeg_store(ALLEEG, pop_selectevent(finalEEG, 'type', {'neutralOwnName'    'smileOwnName'    'roughOwnName'}, 'deleteevents','on'));
%     ALLEEG(1).setname = ['deviant', '_', subjectName];
%     ALLEEG(1).subject = subjectName;
%     ALLEEG(1).condition = 'deviant';
%     
%     ALLEEG = eeg_store(ALLEEG, pop_selectevent(finalEEG, 'type', 'frequent', 'deleteevents','on'));
%     ALLEEG(2).setname = ['frequent', '_', subjectName];
%     ALLEEG(2).subject = subjectName;
%     ALLEEG(2).condition = 'frequent';
%     
    
    STUDY = [];
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name','Stats intraSubject Split','task','ownName','updatedat','off','rmclust','on');
    STUDY.filename = ['STUDY_', savingSuffix, subjectName];
    STUDY.filepath = path_save;
    [STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);
%     STUDY = pop_savestudy(STUDY, ALLEEG, 'filename', ['STUDY_', savingSuffix, subjectName],  'filepath', path_save);%, 'savemode', 'resave', 'resavedatasets', 'on');
    
    %% Statistics on ERPs
    % parameters
    [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','erp','on','erpparams',{'rmbase' baselineRange});
    STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','method','perm','mcorrect','none','alpha',alphaThreshold);
    STUDY = pop_erpparams(STUDY, 'plotconditions','together');
    
    % Compute stats
    [STUDY, ~, ~, ~, pcond, ~] = std_erpplot(STUDY,ALLEEG,'channels',{chanToStat}, 'noplot', 'off');
    % [STUDY, ~, ~, ~, pcond, ~] = std_erpplot(STUDY,ALLEEG, 'noplot', 'on'); % to retrieve significance for all channels without plotting anything
       
    %% Statistics on topography
    % parameters
    if isequal(topoFlag, 0)
        STUDY = pop_statparams(STUDY, 'condstats','on', 'singletrials','on','method','perm','mcorrect','none','alpha',NaN); % plot pvalue topographies
    elseif isequal(topoFlag, 1)
        STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','method','perm','mcorrect','bonferoni','alpha',alphaThreshold); % plot significant channels at this threshold
    end
    
    % retrieve periods of interest based on ERPs stats
    countInf = 1;
    countSup = 1;
    for ii = abs(baselineRange(1))+1:size(pcond{1}, 1)-1
        if pcond{1}(ii+1) > pcond{1}(ii)
            infLim(countInf) = ii+1-100;
            countInf = countInf+1;
        end
        if pcond{1}(ii+1) < pcond{1}(ii)
            supLim(countSup) = ii-100;
            countSup = countSup+1;
        end
    end
    
    % Compute stats
    for ii = 1:countInf-1
        STUDY = pop_erpparams(STUDY, 'topotime',[infLim(ii) supLim(ii)]);
        STUDY = std_erpplot(STUDY,ALLEEG,'channels',chanList, 'design', 1);
    end
    
end

%% loc sources
% 'frequent'    'neutralOwnName'    'smileOwnName'    'roughOwnName'
frequentEEG = pop_selectevent(finalEEG, 'type', {'frequent'}, 'deleteevents','on');
frequentMean = mean(frequentEEG.data,3);


neutralOwnNameEEG = pop_selectevent(finalEEG, 'type', {'neutralOwnName'}, 'deleteevents','on');
neutralOwnNameMean = mean(neutralOwnNameEEG.data,3);

smileOwnNameEEG = pop_selectevent(finalEEG, 'type', {'smileOwnName'}, 'deleteevents','on');
smileOwnNameMean = mean(smileOwnNameEEG.data,3);

roughOwnNameEEG = pop_selectevent(finalEEG, 'type', {'roughOwnName'}, 'deleteevents','on');
roughOwnNameMean = mean(roughOwnNameEEG.data,3);






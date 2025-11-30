%% MODIFY PATHS ACCORDINGLY
if (~isdeployed)
    pathPrograms = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode'; %%%%% modify
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData'; %%%%% modify

fileList = uipickfiles('FilterSpec', 'D:\WORKPOSTDOC\OWN_NAME\EEG', 'Type', {'*.vhdr', 'header-files'}); % pick .vhdr file
csvList = uipickfiles('FilterSpec', 'D:\WORKPOSTDOC\OWN_NAME\results_revcor', 'Type', {'*.csv', 'header-files'}); % pick .csv file

% run eeglab to add path properly
run 'D:\WORKPOSTDOC\eeglab2020_0\eeglab.m'
close(gcf);

%% Parameters
downsampleFlag = 0; % 0 for no, 1 for yes
downFreq = 100;

bandpass_hard = [1 30]; % in Hz
bandpass = [0.1 30]; % in Hz
epochLimits = [-0.1 0.6]; % in s %%%%% attention, more length overlaps with next trial
baselineRange = [-100 0]; % in ms

nbBlocks = 3;

frequentMarker = 'R 12';
deviantMarker = 'R 13';

originalMarkerList = {frequentMarker, deviantMarker};

new_frequentMarker = 'frequent';
new_deviantMarker = 'deviant';

finalMarkerList = {new_frequentMarker, new_deviantMarker};

flagSoundIn = 0; % 0 for markers, 1 for sound-in

% topoFlag = 0; % 0 for pvalue topography, 1 for significant channels
alphaThreshold = 0.05;

nbChannels = 64; % nb of electrodes recorded
chanToStat = {'Cz'};

savingSuffix = 'ownName_revcor_';
coordinatesFile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BEM\elec\standard_1005.elc';
% coordinatesFile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp';
load('D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\coordinatesPattern_64.mat');
eventlistPath = 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\eventlist.txt';

% Pipeline
for iter = 1:length(fileList) % i.e. for each subject
% iter = 1;
%     clearvars originalEEG filteredEEG interpolatedEEG avgEEG epochEEG finalEEG
    % setting EEGLab options to double precision
    pop_editoptions('option_single', false);
    
    % eeg loading
    [filePath, fileName, fileExt] = fileparts(fileList{iter});
    originalEEG = pop_loadbv(filePath, [fileName, fileExt]);
    originalEEG.chanlocs = coordinatesPattern;
    
    % csv loading
    csvResults = readtable(csvList{iter});
    
    % retriving subject ID
    idxName = strfind(fileName, '0');
    subjectName = fileName(idxName(1):end);

    %% Check data if necessary
    countResponse = 0;
    countStimulus = 0;
    countNewSegment = 0;
    segmentLocations = 0;
    countR12 = 0;
    countR13 = 0;

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
            countR12 = countR12+1;
        elseif isequal(originalEEG.event(ii).type, deviantMarker)
            countR13 = countR13+1;
        end
    end

    if countNewSegment > 1
        originalEEG.event(segmentLocations(2:end)) = [];
    end
    
    %% check if there is any NaN values in data
    sumNaN = sum(sum(isnan(originalEEG.data)));
    if ~isequal(sumNaN, 0)
        indices = find(isnan(originalEEG.data) == 1);
        [~,J] = ind2sub(size(originalEEG.data),indices);
        EEG = pop_select(originalEEG, 'nopoint', [2 50200 ; 3400000 originalEEG.pnts]);%[J(1):J(end)]);
    else
        EEG = originalEEG;
    end
    sumNaN = sum(sum(isnan(EEG.data)));
%     plot(EEG.data','DisplayName','EEG.data')
    
    %% downsample (if necessary)
    if isequal(downsampleFlag, 1)
        EEG = pop_resample(EEG, 1);
    end
        
    %% replace markers by names so it is clearer, and taking the "sound-in" marker immediately after identification marker
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
%             EEG.event(Index(ii)).type = strcat(finalMarkerList{jj}, '_', eventNumber);
            EEG.event(Index(ii)).type = finalMarkerList{jj};
            EEG.event(Index(ii)).code = 'marker';
            EEG.event(Index(ii)).eventNumber = str2num(eventNumber);
        end
    end
    
    % getting rid of any residual events that are of no interest
    EEG = pop_selectevent(EEG, 'code', {'marker', 'Stimulus'}, 'deleteevents','on');
   
    % Delay between marker and sound-in
    tmpeventcode = {EEG.event.code};
    idxMarker = strmatch('marker', tmpeventcode, 'exact');
    for ii = 1:length(idxMarker)
        latencies(ii, 1) = EEG.event(idxMarker(ii)).latency;
        latencies(ii, 2) = EEG.event(idxMarker(ii)+1).latency;
        if ii<length(idxMarker)
            if isequal(idxMarker(ii+1), idxMarker(ii)+1)
                disp('next is no sound-in');
                latencies(ii, 1) = 0;
                latencies(ii, 2) = 0;
            end
        end
    end
     
    latencyDelay = latencies(:, 2)-latencies(:, 1);
    meanDelay = mean(latencyDelay);
    
    % selecting only sound-in right after marker
    tmpeventcode = {EEG.event.code};
    Index = strmatch('marker', tmpeventcode, 'exact');
    
    if isequal(flagSoundIn, 1)
        for ii = 1:length(Index)
            EEG.event(Index(ii)).latency = EEG.event(Index(ii)+1).latency;
        end
    end
    EEG = pop_selectevent(EEG, 'code', 'marker', 'deleteevents','on');
    
    % get latency of first and last sound-in to get rid of what is before
    % and after
    I = find(strcmp({EEG.event.code}, 'marker'));
    latencyFirst = EEG.event(I(1)).latency;
    if latencyFirst-abs(epochLimits(1)*EEG.srate)-500<2
        latencyFirst = EEG.event(I(1)+1).latency;
    end
    latencyLast = EEG.event(I(end)).latency;
    if latencyLast+(epochLimits(2)*EEG.srate)+500>EEG.pnts
        latencyLast = EEG.event(I(end)-1).latency;
    end
    EEG = pop_select(EEG, 'nopoint', [2 latencyFirst-abs(epochLimits(1)*EEG.srate)-500 ; latencyLast+(epochLimits(2)*EEG.srate)+500 EEG.pnts]);
   
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
%         I = find([csvResults.block_number] == ii);
%         latencyLastBlock = EEG.event(I(1)-1).latency;
%         latencyNewBlock = EEG.event(I(end)+1).latency;
        latencyLastBlock = EEG.event(1+ii*1000).latency;
        latencyNewBlock = EEG.event(1+ii*1000+1).latency;
        
        EEG = pop_select(EEG, 'nopoint', [latencyLastBlock+(epochLimits(2)*EEG.srate)+500 latencyNewBlock-(epochLimits(1)*EEG.srate)-500]);
    end
    
    %% Soft processing for final run 
    % Retrieving channels locations
    EEG = pop_chanedit(EEG, 'lookup', coordinatesFile);
    
    EEG_soft = EEG;
    
    %% Filtering
    % bandpass filtering using erplab butterworth filter
    EEG_soft = pop_basicfilter(EEG_soft, 1:EEG_soft.nbchan, 'Cutoff', bandpass, ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    
    % Parks-McClellan notch
    EEG_soft  = pop_basicfilter(EEG_soft, 1:EEG_soft.nbchan, 'Cutoff', 50,...
        'Design', 'notch', 'Filter', 'PMnotch', 'Order', 180);
   
    %% Channels interpolation
    % Finding electrodes to be interpolated
    EEG_soft = trimOutlier(EEG_soft, 2, 100, Inf, 0); % Inf and 0 because no rejection of datapoints
    
    % Bad channels interpolation
    EEG_soft = pop_interp(EEG_soft, EEG.chanlocs, 'spherical');
    
    %% Average referencing with elimination of Cz in the end (Makoto function)
    EEG_soft = fullRankAveRef(EEG_soft); % allows to get data rank = channels number (here 128)
    EEG_soft = eeg_checkset(EEG_soft);
    
    %% Reject artifacted datapoints   
    % Clean data artifacts
    EEG_soft = clean_rawdata(EEG_soft,...
        5, ... Maximum tolerated flatline duration. (secs).
        -1, ... Highpass -1 = disabled
        -1, ... Minimum channel correlation
        -1, ... Channel abnormality if line noise/signal more than value
        20, ... Data portions whose variance is larger than this threshold relative to the calibration data are removed
        0.25); % Criterion for removing time windows that were not repaired completely.
    
    %% Average referencing with elimination of Cz in the end (Makoto function)
    EEG_soft = fullRankAveRef(EEG_soft); % allows to get data rank = channels number (here 128)
    EEG_soft = eeg_checkset(EEG_soft);

    pop_saveset(EEG_soft, 'filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName]);
%     EEG_soft = pop_loadset('filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName, '.set']);

    %% Hard preprocessing for ICA
    EEG_ICA = EEG;
    %% Filtering
    % bandpass filtering using erplab butterworth filter
    EEG_ICA = pop_basicfilter(EEG_ICA, 1:EEG_ICA.nbchan, 'Cutoff', bandpass_hard, ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    
    % Parks-McClellan notch
    EEG_ICA  = pop_basicfilter(EEG_ICA, 1:EEG.nbchan, 'Cutoff', 50,...
        'Design', 'notch', 'Filter', 'PMnotch', 'Order', 180);
    
    %% Run cleanLineNoise
    % Retrieving channels locations
    EEG_ICA = pop_chanedit(EEG_ICA, 'lookup', coordinatesFile);
   
    %% Channels interpolation
    % Transferring electrodes to be interpolated so they are the same
    EEG_ICA.etc.trimOutlier = EEG_soft.etc.trimOutlier;
    
    % Bad channels interpolation
    EEG_ICA = pop_interp(EEG_ICA, EEG.chanlocs, 'spherical');

    %% Average referencing with elimination of Cz in the end (Makoto function)
    EEG_ICA = fullRankAveRef(EEG_ICA); % allows to get data rank = channels number (here 128)
    EEG_ICA = eeg_checkset(EEG_ICA);
    
    %% Reject artifacted datapoints   
    % Clean data artifacts
    EEG_ICA = clean_rawdata(EEG_ICA,...
        5, ... Maximum tolerated flatline duration. (secs).
        -1, ... Highpass -1 = disabled
        -1, ... Minimum channel correlation
        -1, ... Channel abnormality if line noise/signal more than value
        20, ... Data portions whose variance is larger than this threshold relative to the calibration data are removed
        0.25); % Criterion for removing time windows that were not repaired completely.
    
        %% Average referencing with elimination of Cz in the end (Makoto function)
    EEG_ICA = fullRankAveRef(EEG_ICA); % allows to get data rank = channels number (here 128)
    EEG_ICA = eeg_checkset(EEG_ICA);
%     Re-reference the data to average again--this is to reset the data to be zero-sum across channels again. 

    %% ICA de-artifacting (ocular movements and blinks)
    % Perform PCA to find nb components to keep
    % nb of PCA components kept for ICA = number of ICA components obtained before rejection
    % Normalise the data
    dataToSee_normalised = EEG_ICA.data';
    for f = 1:size(dataToSee_normalised, 2)
        dataToSee_normalised(:, f) = dataToSee_normalised(:, f) - nanmean(dataToSee_normalised(:, f));
        dataToSee_normalised(:, f) = dataToSee_normalised(:, f) / nanstd(dataToSee_normalised(:, f));
    end
    [~,~,~,~,explained,~] = pca(dataToSee_normalised);
    
    nbComponentsToCompute = find(cumsum(explained)>95,1);

    % Computing ICA components
    % should run pca here to avoid shortage of data to learn due to downsampling and huge nb of channels
%     nbComponentsToCompute = 60; % nb of PCA components kept for ICA = number of ICA components obtained before rejection
    tic
    EEG_ICA = pop_runica(EEG_ICA,'icatype','runica', 'pca', nbComponentsToCompute, 'maxsteps', 750, 'interupt', 'off'); % more channels => more steps
    t = toc; disp(t);
    EEG_ICA = eeg_checkset(EEG_ICA);

    %% Estimating single equivalent current dipoles
    % Co-registration of EGI 128 channels system with standard 10-05 system
    hdmfile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BEM\standard_vol.mat';
    mrifile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BEM\standard_mri.mat';
    chanfile = 'D:\WORKPOSTDOC\eeglab2020_0\plugins\dipfit\standard_BEM\elec\standard_1005.elc';
    
    [~,coordinateTransformParameters] = coregister(EEG_ICA.chanlocs, chanfile, 'warp', 'auto', 'manual', 'off');

    EEG_ICA = pop_dipfit_settings(EEG_ICA, 'hdmfile', hdmfile, 'coordformat', 'MNI',...
        'mrifile', mrifile, 'chanfile', chanfile,...
        'coord_transform', coordinateTransformParameters, 'chansel', 1:EEG_ICA.nbchan);
    
    EEG_ICA = pop_multifit(EEG_ICA, 1:EEG_ICA.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}, 'rmout', 'on'); % very long

    % Search for and estimate symmetrically constrained bilateral dipoles
    EEG_ICA = fitTwoDipoles(EEG_ICA, 'LRR', 35);
    
    %% IClabels plug-in to automatically label, flag and reject noise components
    EEG_ICA = pop_iclabel(EEG_ICA, 'default');
    %            Brain  / Muscle / Eye / Heart / Line Noise /Channel Noise / Other
    threshold = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; 0.9 1;      0.9 1;         0.95 1];
    
    % reject if component is less than 20% brain category
%     threshold = [0 0.25; 0.9 1; 0.9 1; NaN NaN; 0.9 1; 0.9 1; 0 0];
    EEG_ICA = pop_icflag(EEG_ICA, threshold);
    EEG_ICA = eeg_checkset(EEG_ICA);
    
    pop_saveset(EEG_ICA, 'filepath', path_save, 'filename', ['EEG_ICA_allComponents', savingSuffix, subjectName]);
%     EEG_soft = pop_loadset('filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName, '.set']);

    %% Transfer ICA components from hard to soft processed data
    EEG_soft.icawinv = EEG_ICA.icawinv;
    EEG_soft.icasphere = EEG_ICA.icasphere;
    EEG_soft.icaweights = EEG_ICA.icaweights;
    EEG_soft.icachansind = EEG_ICA.icachansind;
    EEG_soft = eeg_checkset(EEG_soft);
  
    % Removing marked components
    EEG_soft = pop_subcomp(EEG_soft,find(EEG_soft.reject.gcompreject),0); % ICs are flagged for removal in the gcompreject field of the EEG.reject structure.
    EEG_soft = eeg_checkset(EEG_soft);    
    
    %% Average referencing
    EEG_soft = fullRankAveRefCoralie(EEG_soft); % adds Cz to count of elec AND keep it after AvgRef
    EEG_soft = eeg_checkset(EEG_soft);
    
    % adding Cz coordinates
    EEG_soft.chanlocs(nbChannels).labels = 'Cz'; % so it can be recognized in the file
    EEG_soft = pop_chanedit(EEG_soft, 'lookup', coordinatesFile);
%     pop_saveset(avgEEG, 'filepath', path_save, 'filename', ['avgEEG_', savingSuffix, subjectName]);

    %% Epoching
    epochEEG = pop_epoch(EEG_soft, finalMarkerList, epochLimits); % time limits in seconds
    
    % removing baseline
    finalEEG = pop_rmbase(epochEEG, baselineRange);
    chanList = {finalEEG.chanlocs.labels};

    %% Saving EEGlab set (all data)
    pop_saveset(finalEEG, 'filepath', path_save, 'filename', ['finalEEG_softAfterICA_', savingSuffix, subjectName]);
    %     finalEEG = pop_loadset('filepath', path_save, 'filename', ['finalEEG_', savingSuffix, subjectName, '.set']);
    
%     %% INTRA-SUBJECT STATISTICS
%     %% Create study for intra-subject statistics
%     finalEEG = pop_loadset('filename', 'finalEEG_softAfterICA_ownName_revcor_0018.set', 'filepath', 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData');
%     ALLEEG = [];
% %     subjectName = finalEEG.setname;
%     for ii = 1:length(finalMarkerList)
%         tmpcsv = pop_selectevent(finalEEG, 'type', finalMarkerList{ii}, 'deleteevents','on');
%         ALLEEG = eeg_store(ALLEEG, tmpcsv);
%         ALLEEG(ii).setname = [finalMarkerList{ii}, '_', subjectName];
%         ALLEEG(ii).subject = subjectName;
%         ALLEEG(ii).condition = finalMarkerList{ii};
% %             pop_saveset(ALLEEG(1), 'filepath', path_save, 'filename', [finalMarkerList{ii}, '_', subjectName]);
%     end
%     
%     STUDY = [];
%     [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name','Stats intraSubject Split','task','ownName','updatedat','off','rmclust','on');
%     STUDY.filename = ['STUDY_', savingSuffix, subjectName];
%     STUDY.filepath = path_save;
%     [STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);
% %     STUDY = pop_savestudy(STUDY, ALLEEG, 'filename', ['STUDY_', savingSuffix, subjectName],  'filepath', path_save);%, 'savemode', 'resave', 'resavedatasets', 'on');
%     
%     %% Statistics on ERPs
%     % parameters
%     [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','erp','on','erpparams',{'rmbase' baselineRange});
%     
%     % fieldtrip cluster permutations
%     STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','mode', 'fieldtrip', 'effect', 'main',...
%         'fieldtripmethod', 'montecarlo', 'fieldtripmcorrect', 'cluster','fieldtripalpha',alphaThreshold);
%     
%     % eeglab stats
% %     STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','method','perm','mcorrect','bonferoni','alpha',alphaThreshold);
%     STUDY = pop_erpparams(STUDY, 'plotconditions','together');
%     
%     % Compute stats
%     [STUDY, ~, ~, ~, pcond, ~] = std_erpplot(STUDY,ALLEEG,'channels',{'Cz'}, 'noplot', 'off');
%     % [STUDY, ~, ~, ~, pcond, ~] = std_erpplot(STUDY,ALLEEG, 'noplot', 'on'); % to retrieve significance for all channels without plotting anything
%     set(gcf, 'Position', get(0, 'Screensize'));
%     saveas(gcf, [path_save, filesep, 'marker_HardCleaned_graph_Cz_', savingSuffix, subjectName, '.png']);
%     close(gcf);
    
    
    %% Statistics on topography
    % parameters
%     if isequal(topoFlag, 0)
%         STUDY = pop_statparams(STUDY, 'condstats','on', 'singletrials','on','method','perm','mcorrect','none','alpha',NaN); % plot pvalue topographies
%     elseif isequal(topoFlag, 1)
%         STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','method','perm','mcorrect','bonferoni','alpha',alphaThreshold); % plot significant channels at this threshold
%     end
%     
%     % retrieve periods of interest based on ERPs stats
%     countInf = 1;
%     countSup = 1;
%     for ii = abs(baselineRange(1))+1:size(pcond{1}, 1)-1
%         if pcond{1}(ii+1) > pcond{1}(ii)
%             infLim(countInf) = ii+1-100;
%             countInf = countInf+1;
%         end
%         if pcond{1}(ii+1) < pcond{1}(ii)
%             supLim(countSup) = ii-100;
%             countSup = countSup+1;
%         end
%     end
%     
%     % Compute stats
%     for ii = 1:countInf-1
%         STUDY = pop_erpparams(STUDY, 'topotime',[infLim(ii) supLim(ii)]);
%         STUDY = std_erpplot(STUDY,ALLEEG,'channels',chanList, 'design', 1);
%     end

end







function [finalEEG, EEG_ICA] = eeg_preprocessing_pipeline(EEG, log_file_ID, eeglabLocation, finalMarkerList, params)

    %% FILES    
    hdmfile = [eeglabLocation, filesep, 'plugins\dipfit\standard_BEM\standard_vol.mat'];
    mrifile = [eeglabLocation, filesep, 'plugins\dipfit\standard_BEM\standard_mri.mat'];
    chanfile = [eeglabLocation, filesep, 'plugins\dipfit\standard_BEM\elec\standard_1005.elc'];

    %% Soft processing for final run %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Retrieving channels locations
    EEG = pop_chanedit(EEG, 'lookup', chanfile);
    
    EEG_soft = EEG;
    fprintf(log_file_ID,'\n\n******************** Soft processing for final run ********************');
    
    %% Filtering
    % bandpass filtering using erplab butterworth filter
    EEG_soft = pop_basicfilter(EEG_soft, 1:EEG_soft.nbchan, 'Cutoff', params.bandpass, ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    fprintf(log_file_ID,'\n\nBandpass filter applied: Butterworth, order 2, %s - %s Hz.', num2str(params.bandpass(1)), num2str(params.bandpass(2)));
    
    % Parks-McClellan notch
    EEG_soft  = pop_basicfilter(EEG_soft, 1:EEG_soft.nbchan, 'Cutoff', 50,...
        'Design', 'notch', 'Filter', 'PMnotch', 'Order', 180);
    fprintf(log_file_ID,'\n\nNotch filter applied: Parks-McClellan, order 180, 50 Hz.');

    %% Bad channels rejection
    % Finding electrodes to be interpolated
    EEG_soft = trimOutlier(EEG_soft, 2, 90, Inf, 0); % Inf and 0 because no rejection of datapoints
    tmpchanlocs = {EEG.chanlocs(:).labels};
    badChans = tmpchanlocs(~EEG_soft.etc.trimOutlier.cleanChannelMask);
    
    if ~isempty(badChans)
        fprintf(log_file_ID,'\n\nChannels rejected:');
        for ii = 1:length(badChans)
            fprintf(log_file_ID, '\n%s', badChans{ii});
        end
    else
        fprintf(log_file_ID,'\n\nNo channels rejected.');
    end
    
    %% Reject artifacted datapoints   
    % Clean data artifacts
    fprintf(log_file_ID,'\n\nReject artifacted datapoints using clean_rawdata function with parameters: \n     - Maximum tolerated flatline duration (secs): %s \n     - Highpass: %s, \n     - Minimum channel correlation: %s \n     - Channel abnormality: %s \n     - Threshold for elimination of data portions: %s \n     - Criterion for removing time windows that were not repaired completely: %s',...
        num2str(5), num2str(-1), num2str(-1), num2str(-1), num2str(20), num2str(0.25));
    EEG_soft = clean_rawdata(EEG_soft,...
        5, ... Maximum tolerated flatline duration. (secs).
        -1, ... Highpass -1 = disabled
        -1, ... Minimum channel correlation
        -1, ... Channel abnormality if line noise/signal more than value
        20, ... Data portions whose variance is larger than this threshold relative to the calibration data are removed
        0.25); % Criterion for removing time windows that were not repaired completely.

%     pop_saveset(EEG_soft, 'filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName]);
%     EEG_soft = pop_loadset('filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName, '.set']);

    %% Hard preprocessing for ICA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    EEG_ICA = EEG;
    fprintf(log_file_ID,'\n\n******************** Hard preprocessing for ICA ********************');
    
    %% Downsampling for ICA (if necessary)
    if isequal(params.flagDownsample, 1)
        EEG_ICA = pop_resample(EEG_ICA, params.downFreq);
        fprintf(log_file_ID,'\n\nResampling for ICA from %s to %s.', num2str(EEG_ICA.srate), num2str(params.downFreq));
    else
        fprintf(log_file_ID,'\n\nNo resampling for ICA. Sampling frequency: %s Hz.', num2str(EEG_ICA.srate));
    end

    %% Filtering
    % bandpass filtering using erplab butterworth filter
    EEG_ICA = pop_basicfilter(EEG_ICA, 1:EEG_ICA.nbchan, 'Cutoff', params.bandpass_hard, ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    fprintf(log_file_ID,'\n\nBandpass filter applied: Butterworth, order 2, %s - %s Hz.', num2str(params.bandpass_hard(1)), num2str(params.bandpass_hard(2)));

    % Parks-McClellan notch
    EEG_ICA  = pop_basicfilter(EEG_ICA, 1:EEG.nbchan, 'Cutoff', 50,...
        'Design', 'notch', 'Filter', 'PMnotch', 'Order', 180);
    fprintf(log_file_ID,'\n\nNotch filter applied: Parks-McClellan, order 180, 50 Hz.');
   
    %% Bad channels rejection
    % Transferring electrodes to be rejected so they are the same
    EEG_ICA.etc.trimOutlier = EEG_soft.etc.trimOutlier;
    badChanMask = ~EEG_ICA.etc.trimOutlier.cleanChannelMask;
    badChanIdx  = find(badChanMask);
    EEG_ICA = pop_select(EEG_ICA, 'nochannel', badChanIdx);

    %% Reject artifacted datapoints   
    % Clean data artifacts
    fprintf(log_file_ID,'\n\nReject artifacted datapoints using clean_rawdata function with parameters: \n     - Maximum tolerated flatline duration (secs): %s \n     - Highpass: %s, \n     - Minimum channel correlation: %s \n     - Channel abnormality: %s \n     - Threshold for elimination of data portions: %s \n     - Criterion for removing time windows that were not repaired completely: %s',...
        num2str(5), num2str(-1), num2str(-1), num2str(-1), num2str(20), num2str(0.25));
    EEG_ICA = clean_rawdata(EEG_ICA,...
        5, ... Maximum tolerated flatline duration. (secs).
        -1, ... Highpass -1 = disabled
        -1, ... Minimum channel correlation
        -1, ... Channel abnormality if line noise/signal more than value
        20, ... Data portions whose variance is larger than this threshold relative to the calibration data are removed
        0.25); % Criterion for removing time windows that were not repaired completely.

    %% ICA de-artifacting (ocular movements and blinks)
    % Computing ICA components
    EEG_ICA = pop_runica(EEG_ICA,'icatype','runica', 'maxsteps', 750, 'interupt', 'off'); % more channels => more steps
    EEG_ICA = eeg_checkset(EEG_ICA);
    fprintf(log_file_ID,'\n\nICA de-artifacting (ocular movements and blinks):');

    %% Estimating single equivalent current dipoles
    % Co-registration of channels system with standard 10-05 system
    if isequal(params.nbChannels, 64)
        [~,coordinateTransformParameters] = coregister(EEG_ICA.chanlocs, chanfile, 'warp', 'auto', 'manual', 'off');
    
        EEG_ICA = pop_dipfit_settings(EEG_ICA, 'hdmfile', hdmfile, 'coordformat', 'MNI',...
            'mrifile', mrifile, 'chanfile', chanfile,...
            'coord_transform', coordinateTransformParameters, 'chansel', 1:EEG_ICA.nbchan);
        
        EEG_ICA = pop_multifit(EEG_ICA, 1:EEG_ICA.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}, 'rmout', 'on'); % very long
    
        % Search for and estimate symmetrically constrained bilateral dipoles
        EEG_ICA = fitTwoDipoles(EEG_ICA, 'LRR', 35);
        fprintf(log_file_ID,'\n- using estimated single equivalent current dipoles (dipfit)');
    end
    %% IClabels plug-in to automatically label, flag and reject noise components
    EEG_ICA = pop_iclabel(EEG_ICA, 'default');
    %            Brain  / Muscle / Eye / Heart / Line Noise /Channel Noise / Other
    threshold = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; 0.9 1;      0.9 1;         0.95 1];

    EEG_ICA = pop_icflag(EEG_ICA, threshold);
    EEG_ICA = eeg_checkset(EEG_ICA);

    fprintf(log_file_ID,'\n- using IClabels to automatically label, flag and reject noise components');
    fprintf(log_file_ID,'\n- parameters: \n     - Brain: %s - %s \n     - Muscle: %s - %s, \n     - Eye: %s - %s \n     - Heart: %s - %s \n     - Line noise: %s - %s \n     - Channel Noise: %s - %s \n     - Other: %s - %s',...
        num2str(NaN), num2str(NaN), num2str(0.9), num2str(1), num2str(0.9), num2str(1), num2str(NaN), num2str(NaN), num2str(0.9), num2str(1), num2str(0.9), num2str(1), num2str(0.95), num2str(1));
%     pop_saveset(EEG_ICA, 'filepath', path_save, 'filename', ['EEG_ICA_allComponents', savingSuffix, subjectName]);
%     EEG_soft = pop_loadset('filepath', path_save, 'filename', ['EEG_soft_', savingSuffix, subjectName, '.set']);

    %% Transfer ICA components from hard to soft processed data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf(log_file_ID,'\n\n******************** After transfer of ICA components from hard to soft processed data ********************');

    EEG_soft.icawinv = EEG_ICA.icawinv;
    EEG_soft.icasphere = EEG_ICA.icasphere;
    EEG_soft.icaweights = EEG_ICA.icaweights;
    EEG_soft.icachansind = EEG_ICA.icachansind;
    EEG_soft = eeg_checkset(EEG_soft);
  
    % Removing marked components
    EEG_soft = pop_subcomp(EEG_soft,find(EEG_soft.reject.gcompreject),0); % ICs are flagged for removal in the gcompreject field of the EEG.reject structure.
    EEG_soft = eeg_checkset(EEG_soft);
    fprintf(log_file_ID,'\n\nRemoving of marked components.');
    
    %% Bad channels interpolation
    EEG_soft = pop_interp(EEG_soft, EEG.chanlocs, 'spherical');

    %% Average referencing
    EEG_soft = fullRankAveRefCoralie(EEG_soft); % adds Cz to count of elec AND keep it after AvgRef
    EEG_soft = eeg_checkset(EEG_soft);

    fprintf(log_file_ID,'\n\nAverage referencing with keeping of Cz in the end (Coralie function).');
    
    % adding Cz coordinates
    EEG_soft.chanlocs(EEG_soft.nbchan).labels = 'Cz'; % so it can be recognized in the file
    EEG_soft = pop_chanedit(EEG_soft, 'lookup', chanfile);

    %% Epoching
    epochEEG = pop_epoch(EEG_soft, finalMarkerList, params.epochLimits); % time limits in seconds
    
    % removing baseline
    finalEEG = pop_rmbase(epochEEG, params.baselineRange);

    fprintf(log_file_ID,'\n\nCreation of epochs: \n- limits: %s to %s ms, \n- baseline: %s to %s ms.', num2str(params.epochLimits(1)*epochEEG.srate), num2str(params.epochLimits(2)*epochEEG.srate), num2str(params.baselineRange(1)), num2str(params.baselineRange(2)));
end
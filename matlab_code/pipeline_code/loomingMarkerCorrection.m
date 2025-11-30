function EEG = loomingMarkerCorrection(EEG, csvResults)
    diff_csv_eeg = size(EEG.event, 2) - height(csvResults);
    for ii = 1:height(csvResults)
        if isequal(EEG.event(ii).type, 'boundary')
            EEG.event(ii).typeInCSV = 'boundary';
        end
        EEG.event(ii+diff_csv_eeg).typeInCSV = char(csvResults.stim_type(ii));
        EEG.event(ii+diff_csv_eeg).markerInCSV = csvResults.stim_marker_code(ii);
    end


    for ii = 1:size(EEG.event, 2)
        if isequal(EEG.event(ii).type, char(EEG.event(ii).typeInCSV))
            EEG.event(ii).error = 0;
        else
            EEG.event(ii).type = char(EEG.event(ii).typeInCSV);
        end
    end

    for ii = 1:size(EEG.event, 2)
        if isequal(EEG.event(ii).type, char(EEG.event(ii).typeInCSV))
            EEG.event(ii).error = 0;
        else
            EEG.event(ii).error = 1;
        end
    end

    sumError = sum([EEG.event(:).error]);
    if ~isequal(sumError, 0)
        error('Les marqueurs csv et eeg ne correspondent pas.')
    end
end
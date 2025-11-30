function counts = checkMarkers_v2(EEG, originalMarkerList)
    countResponse = 0;
    countStimulus = 0;
    countNewSegment = 0;
    segmentLocations = 0;
    counts = cell(length(originalMarkerList), 2);

    % check marker type (python/sound-in/segment)
    for ii = 1:length(EEG.event)
        if isequal(EEG.event(ii).code, 'Response') % response = marker python/presentation
            countResponse = countResponse+1;
        elseif isequal(EEG.event(ii).code, 'Stimulus') % stimulus = sound in
            countStimulus = countStimulus+1;
        elseif ~isempty(strfind(EEG.event(ii).code, 'Segment'))
            segmentLocations(countNewSegment+1) = ii;
            countNewSegment = countNewSegment+1;
        end
    end

    % check marker name (stimulus type)
    for jj = 1:length(originalMarkerList)
        countMarker = 0;
        counts{jj,1} = originalMarkerList{jj};
        for ii = 1:length(EEG.event)
            if isequal(EEG.event(ii).type, originalMarkerList{jj})
                countMarker = countMarker+1;
            end
        end
        counts{jj,2} = countMarker;
    end

    if countNewSegment > 1
        EEG.event(segmentLocations(2:end)) = [];
    end
end


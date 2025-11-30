function EEG = renameMarkers(EEG, originalMarkerList, finalMarkerList)
%% replace markers by names so it is clearer, and taking the "sound-in" marker immediately after identification marker
tmpeventtype = {EEG.event.type};

for jj = 1:length(finalMarkerList)
    Index = strmatch(originalMarkerList{jj}, tmpeventtype, 'exact');
    for ii = 1:length(Index)
        EEG.event(Index(ii)).type = finalMarkerList{jj};
        EEG.event(Index(ii)).code = 'marker';
    end
end
end
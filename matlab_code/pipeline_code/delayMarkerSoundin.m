function meanDelay = delayMarkerSoundin(EEG)
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
end
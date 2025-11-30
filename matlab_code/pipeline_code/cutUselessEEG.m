function EEG = cutUselessEEG(EEG, epochLimits)
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
    if EEG.pnts-latencyLast+(epochLimits(2)*EEG.srate)>5000
        EEG = pop_select(EEG, 'nopoint', [2 latencyFirst-abs(epochLimits(1)*EEG.srate)-500 ; latencyLast+(epochLimits(2)*EEG.srate)+5000 EEG.pnts]);
    else
        EEG = pop_select(EEG, 'nopoint', [2 latencyFirst-abs(epochLimits(1)*EEG.srate)-500]);
    end
end
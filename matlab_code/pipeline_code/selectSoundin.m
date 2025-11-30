function EEG = selectSoundin(EEG)
% selecting only sound-in right after marker
    tmpeventcode = {EEG.event.code};
    Index = strmatch('marker', tmpeventcode, 'exact');
    for ii = 1:length(Index)
        EEG.event(Index(ii)).latency = EEG.event(Index(ii)+1).latency;
    end
    EEG = pop_selectevent(EEG, 'code', 'marker', 'deleteevents','on');
end
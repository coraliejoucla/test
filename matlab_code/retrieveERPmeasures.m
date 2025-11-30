function erpMeasures = retrieveERPmeasures(EEG, epochLowerLimit, epochUpperLimit, periodToExamine, eventlistPath, chanToExamine, peakPolarity)
% This function retrieves ERP peak amplitude and latency within a given
% period of time.
% Input : 
% EEG : structure EEGLAB
% epochLowerLimit: double, beginning of epoch including the baseline, in ms (ex: -100)
% epochUpperLimit: double, end of epoch including the baseline, in ms (ex: 500)
% periodToExamine: array of two, limits of perdiod to look at, in ms (ex: [100 300])
% eventlistPath: char, path to ERPlab eventlist model
% chanToExamine: double, number of the electrode to look at
% peakPolarity: char, polarity of peak to search for (positive or negative)


% create ERPlab eventlist
EEG = pop_editeventlist(EEG, 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'}, 'List', eventlistPath,...
 'SendEL2', 'EEG', 'UpdateEEG', 'off');

%% modify eventlist structure
EEG.EVENTLIST.nbin = size(EEG.event, 2) - sum(isnan([EEG.event(:).duration])); % tous les trials sauf boundary
EEG.EVENTLIST.trialsperbin = ones(1, EEG.EVENTLIST.nbin);

for ii = 1:length(EEG.EVENTLIST.eventinfo)
    EEG.EVENTLIST.eventinfo(ii).code = EEG.EVENTLIST.eventinfo(ii).item-1;
    EEG.EVENTLIST.eventinfo(ii).bini = EEG.EVENTLIST.eventinfo(ii).item-1;
    if isequal(EEG.EVENTLIST.eventinfo(ii).codelabel, 'boundary')
        EEG.EVENTLIST.eventinfo(ii).binlabel = '""';
    else
        EEG.EVENTLIST.eventinfo(ii).binlabel = ['B', num2str(EEG.EVENTLIST.eventinfo(ii).code), '(', EEG.EVENTLIST.eventinfo(ii).codelabel, ')'];
        EEG.EVENTLIST.eventinfo(ii).codelabel = ['B', num2str(EEG.EVENTLIST.eventinfo(ii).code), '(', EEG.EVENTLIST.eventinfo(ii).codelabel, ')'];
        EEG.EVENTLIST.bdf(ii).description = EEG.EVENTLIST.eventinfo(ii).binlabel;
        EEG.EVENTLIST.bdf(ii).namebin = ['BIN', num2str(EEG.EVENTLIST.eventinfo(ii).code)];
    end
end
EEG.EVENTLIST.bdf(1) = [];

%%
EEG = pop_epochbin(EEG, [epochLowerLimit  epochUpperLimit], 'pre');
ERP = pop_averager(EEG, 'Criterion', 'all', 'ExcludeBoundary', 'on', 'SEM', 'off');

%% peak latency
[~, outcome] = pop_geterpvalues(ERP, periodToExamine, 1:EEG.EVENTLIST.nbin, chanToExamine, 'Baseline', 'pre', 'FileFormat', 'wide', 'Filename', 'blob.no_save', 'Fracreplace', 'NaN',...
 'InterpFactor', 1, 'Measure', 'peaklatbl', 'Neighborhood',  5, 'PeakOnset',  1, 'Peakpolarity', peakPolarity, 'Peakreplace', 'absolute',...
 'Resolution', 3, 'SendtoWorkspace', 'on');

erpMeasures(:).peakLatency = outcome;

% peak amplitude
[~, outcome] = pop_geterpvalues(ERP, periodToExamine, 1:EEG.EVENTLIST.nbin, chanToExamine, 'Baseline', 'pre', 'FileFormat', 'wide', 'Filename', 'blob.no_save', 'Fracreplace', 'NaN',...
 'InterpFactor', 1, 'Measure', 'peakampbl', 'Neighborhood',  5, 'PeakOnset',  1, 'Peakpolarity', peakPolarity, 'Peakreplace', 'absolute',...
 'Resolution', 3, 'SendtoWorkspace', 'on');

erpMeasures(:).peakAmplitude = outcome;


end

run 'D:\WORKPOSTDOC\eeglab2020_0\eeglab.m'
close(gcf);

path_save = 'D:\WORKPOSTDOC\Data\ownName_revCorr'; %%%%% modify
savingSuffix = 'ownName_NSR_';

avgEEG = pop_loadset('filepath', path_save, 'filename', ['avgEEG_', savingSuffix, '0003.set']);

% create ERPlab eventlist
EEG  = pop_editeventlist(avgEEG , 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'}, 'List', 'D:\WORKPOSTDOC\EEG\ownName_NSR\analysisCode\eventlist.txt',...
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
EEG = pop_epochbin(EEG , [-100.0  470.0], 'pre');
% pop_saveset(lastEEG, 'filename', 'lastEEG');

ERP = pop_averager(EEG, 'Criterion', 'all', 'ExcludeBoundary', 'on', 'SEM', 'on');

ERP = pop_savemyerp(ERP, 'erpname', 'S1_ERPs.set','filename', 'S1_ERPs.erp', 'filepath', 'D:\WORKPOSTDOC\EEG\ownName_NSR\analyzedData');

ERP = pop_ploterps(ERP,  3,  32 , 'Axsize', [0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [1 1], 'ChLabel', 'on', 'FontSizeChan',...
  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' }, 'LineWidth',  1, 'Maximize', 'on',...
 'Position', [55.1667 12.8125 106.833 31.9375], 'SEM', 'on', 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0.5, 'xscale',...
 [ -100.0 469.0   -100:100:400 ], 'YDir', 'normal', 'yscale', [-6.5 6.5   -7 -5.3 -3.5 -1.8:1.8:1.8 3.5 5.3 7 ]); 

ERP = pop_scalplot(ERP,  3,  [160 200] , 'Animated', 'off', 'Blc', 'pre', 'Colormap', 'jet', 'Compression', 'none', 'Electrodes', 'off',...
 'Filename', 'fviy.eps', 'FontName', 'Courier New', 'FontSize',  10, 'FPS',  2, 'Legend', 'bn-la', 'Maplimit', 'maxmin', 'Mapstyle', 'both',...
 'Maptype', '2D', 'Mapview', '+X', 'Plotrad',  0.55, 'Quality',  60, 'Value', 'mean');

% ERP = pop_scalplot(ERP,  1:4,  100:10:460 , 'Animated', 'on', 'Blc', 'pre', 'Colormap', 'jet', 'Compression', 'none', 'Electrodes', 'on',...
%  'Filename', 'fviy.gif', 'FontName', 'Courier New', 'FontSize',  10, 'FPS',  2, 'Legend', 'bn-la', 'Maplimit', 'maxmin', 'Mapstyle', 'both',...
%  'Maptype', '2D', 'Mapview', '+X', 'Plotrad',  0.55, 'Quality',  60, 'Value', 'insta', 'VideoIntro', 'erplab');

%% peak latency
ALLERP = pop_geterpvalues(ERP, [100 300], 1:EEG.EVENTLIST.nbin,  32 , 'Baseline', 'pre', 'FileFormat', 'wide', 'Filename', 'blob.no_save', 'Fracreplace', 'NaN',...
 'InterpFactor', 1, 'Measure', 'peaklatbl', 'Neighborhood',  5, 'PeakOnset',  1, 'Peakpolarity', 'positive', 'Peakreplace', 'absolute',...
 'Resolution', 3, 'SendtoWorkspace', 'on');

erpMeasures(:).peakLatency = ERP_MEASURES;

% peak amplitude
ALLERP = pop_geterpvalues(ERP, [100 300], 1:EEG.EVENTLIST.nbin,  32 , 'Baseline', 'pre', 'FileFormat', 'wide', 'Filename', 'blob.no_save', 'Fracreplace', 'NaN',...
 'InterpFactor', 1, 'Measure', 'peakampbl', 'Neighborhood',  5, 'PeakOnset',  1, 'Peakpolarity', 'positive', 'Peakreplace', 'absolute',...
 'Resolution', 3, 'SendtoWorkspace', 'on');
erpMeasures(:).peakAmplitude = ERP_MEASURES;
erpMeasures(:).bob = {finalEEG.event(:).type}';

EEEEEEEEEEEE = structofarrays2arrayofstructs(erpMeasures);











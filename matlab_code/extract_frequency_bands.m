if (~isdeployed)
    pathPrograms = 'G:\MATLAB\code_own_name_revcor';
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'D:\PROCESSED EEG DATA\2021-own-name-revcor';

fileList = uipickfiles('FilterSpec', 'D:\PROCESSED EEG DATA\2021-own-name-revcor\EEG', 'Type', {'*.set', 'eeglab-files'}, 'REFilter', 'preprocessed'); % pick .set file

% run eeglab to add path properly
run 'G:\eeglab2020_0\eeglab.m'
close(gcf);

lowPassFreq = 0.1;
highPassFreq = 30;
FFT = 'abs';
wholeFourier = 0;

dataTransformedAnalysis.Fourier = '4bands';
% delta
intervalFreq(1).min = 1;
intervalFreq(1).max = 3;
% theta
intervalFreq(2).min = 4;
intervalFreq(2).max = 7;
% alpha
intervalFreq(3).min = 8;
intervalFreq(3).max = 12;
% beta 
intervalFreq(4).min = 13;
intervalFreq(4).max = 30;

all_subjects_bands = table;

for iter = 1:length(fileList)
    file = char(fileList{iter});
    [filepath, filename, ext] = fileparts(file);
    EEG = pop_loadset('filepath', filepath, 'filename', [filename, ext]);

    if ~isequal(iter, 10)
        EEG.setname = filename(end-3:end);
        EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
        EEG.icachansind = [];
        EEG.data = EEG.data(:, 101:700, :);
        EEG.xmin = 0.001;
        EEG = eeg_checkset(EEG);
    else
        EEG = pop_selectevent(EEG, 'type', {'deviant'}, 'deleteevents','on');
        EEG.icachansind = [];
        EEG = eeg_checkset(EEG);
    end

    nbBands = 4;
    numberOfChannels = EEG.nbchan;
    inSamplingFreq = EEG.srate;
    outSamplingFreq = EEG.srate;
    numberOfSignals = size(EEG.data, 3);
    start = 0.001;
    stop = 0.6;

    dataAnalyzed = [];
    for ii = 1:numberOfSignals % pour chaque essai de ce sujet
        signal_data = EEG.data(:, :, ii); % signal_data est un essai

        signal = [];
        for jj = 1:numberOfChannels % pour chaque colonne de signal_data
            dataSignalToSend = signal_data(jj, :);
            outDataSignal = signalFFTSpectralAnalysis(dataSignalToSend, inSamplingFreq, outSamplingFreq, intervalFreq, FFT, start, stop, wholeFourier);
            signal = horzcat(signal, outDataSignal);
        end
        dataAnalyzed = [dataAnalyzed;signal];
    end

    writematrix(dataAnalyzed, ['frequency_bands_',EEG.setname, '.csv'])
end

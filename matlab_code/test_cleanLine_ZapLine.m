function test_cleanLine_ZapLine(EEG)
% Plot power spectral density (PSD).
L = EEG.pnts;            % Length of signal in frame 
X = EEG.data;
Y = fft(X);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f  = EEG.srate*(0:(L/2))/L;

% Run cleanLineNoise (hereafter CLN).
signal      = struct('data', EEG.data, 'srate', EEG.srate);
lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
                     'lineNoiseChannels', 1:EEG.nbchan,...
                     'Fs', EEG.srate, ...
                     'lineFrequencies', [50, 100, 150, 200, 250, 300, 350, 400, 450, 500],...
                     'p', 0.01, ...
                     'fScanBandWidth', 2, ...
                     'taperBandWidth', 2, ...
                     'taperWindowSize', 4, ...
                     'taperWindowStep', 1, ...
                     'tau', 100, ...
                     'pad', 2, ...
                     'fPassBand', [0 EEG.srate/2], ...
                     'maximumIterations', 10);
[clnEEG, ~] = cleanLineNoise(signal, lineNoiseIn);

% Apply zapline
[zapEEG] = clean_data_with_zapline_plus_eeglab_wrapper(EEG,struct('noisefreqs',50, 'plotResults', 0)); % specifying the config is optional and can be done as above

subplot(1,3,1)
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
xlim([0 100])
ylim([0 1.5])
title('Original signal')

% Plot power spectral density (PSD) for CLN.
subplot(1,3,2)
X = clnEEG.data;
Y = fft(X);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f  = EEG.srate*(0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
xlim([0 100])
ylim([0 1.5])
title('cleanLineNoise')

% Plot power spectral density (PSD) for ZL.
subplot(1,3,3)
X = zapEEG.data;
Y = fft(X);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f  = EEG.srate*(0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
xlim([0 100])
ylim([0 1.5])
title('zapLine')

% Change font size.
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 11)
set(gcf, 'position', [1 630 1120 300], 'color', [0.93 0.96 1]);

% Save the figure.
print('psd', '-djpeg95', '-r150')

%% Compare time-domain residues.
figure
subplot(1,3,1)
plot(EEG.times, EEG.data)
% xlim([0 50])
% ylim([-1.5 1.5])
title('Original signal')
xlabel('Time (s)')
ylabel('Amplitude (µV)')

subplot(1,3,2)
plot(EEG.times, clnEEG.data)
% xlim([0 50])
% ylim([-1.5 1.5])
title('cleanLineNoise result')
xlabel('Time (s)')
ylabel('Amplitude (µV)')

subplot(1,3,3)
plot(EEG.times, zapEEG.data)
% xlim([0 50])
% ylim([-1.5 1.5])
title('zapLine result')
xlabel('Time (s)')
ylabel('Amplitude (µV)')

% Change font size.
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 11)
set(gcf, 'position', [1 630 1120 300], 'color', [0.93 0.96 1]);

% Save the figure.
print('residual', '-djpeg95', '-r150')
end
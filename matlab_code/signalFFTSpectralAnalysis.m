function [outDataSignal] = signalFFTSpectralAnalysis(dataSignal, inSamplingFreq, outSamplingFreq, intervalFreq, FFT, start, stop, wholeFourier)
% function [outDataSignal] = signalFFTSpectralAnalysis(dataSignal, inSamplingFreq, outSamplingFreq, intervalFreq_min, intervalFreq_max, FFT, start, stop, wholeFourier)
    
    % the function runs the Fourier transform on the dataSignal with the
    % arbitary number of channels
    %
    % dataSignal - the input signal
    % inSamplingFreq - the sampling frequency in Hz of the input signal (for ms - 1000 Hz, for 10 ms - 100 Hz etc.)
    % outSamplingFreq - the sampling frequency in Hz of the output signal
    %
    % lowPassFreq and highPassFreq - the low and high pass frequencies,
    % these parameters are not mandatory
    
    % the output parameters
    % outDataSignal - FF transformed signal
    % freq - the array of frequencies
    
    if (outSamplingFreq > inSamplingFreq)
        ratio = 1;
    else
        ratio = inSamplingFreq/outSamplingFreq;
    end
    outDataSignal_temp = double(dataSignal(:, 1:ratio:end));
    
    start = ceil(start*outSamplingFreq);
    stop = floor(stop*outSamplingFreq);
    
    outDataSignal_temp = outDataSignal_temp(start:stop);
    
    
    dataLength = length(outDataSignal_temp);

    NFFT = 2^nextpow2(dataLength);
    outDataSignal_temp = fft(double(outDataSignal_temp), NFFT, 2); 
    % 2 stands for dimension (the data is organized in rows)
    
    %this code takes the abs values of the fft'ed signal
    if ( nargin<2 || strcmp(FFT,'abs')==1)
        %     disp('FFT=abs')
        outDataSignal = (abs(outDataSignal_temp))/dataLength;
    else
    %          disp('FFT=log abs')
        outDataSignal = log(abs(outDataSignal_temp)/dataLength);
    end   
    % this code is used to compute the power spectral density
    %outDataSignal = outDataSignal_temp.*conj(outDataSignal_temp)/dataLength;
    
   
    % this code creates the output
    outDataSignal = outDataSignal(:, 1:NFFT/2 + 1);
    freq = inSamplingFreq/2 * linspace(0, 1, NFFT/2 + 1);
    
    if isequal(wholeFourier, 1)
    % pour tous les features
    outDataSignal = outDataSignal(:, freq >= 1 & freq <= 30);
    
    else
        % pour bandes de frequences
        nbInterval=length(intervalFreq);
        outDataSignalMean=[];
        for ii=1:nbInterval
            outDataSignalMean(:,ii) = mean(outDataSignal(:, freq >= intervalFreq(ii).min & freq < intervalFreq(ii).max )');
        end
        outDataSignal = outDataSignalMean;
%       outDataSignal = mean(outDataSignal(:, freq >= intervalFreq_min & freq < intervalFreq_max)');
    end

end


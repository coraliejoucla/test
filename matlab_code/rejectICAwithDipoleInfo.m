function EEG = rejectICAwithDipoleInfo(EEG)
% Obtain the most dominant class label and its label probability.
    [~, mostDominantClassLabelVector] = max(EEG.etc.ic_classification.ICLabel.classifications, [], 2);
    mostDominantClassLabelProbVector = zeros(length(mostDominantClassLabelVector),1);
    for icIdx = 1:length(mostDominantClassLabelVector)
             mostDominantClassLabelProbVector(icIdx)  = EEG.etc.ic_classification.ICLabel.classifications(icIdx, mostDominantClassLabelVector(icIdx));
    end
 
    %% Option 1: Identify artifact ICs. The order of the classes are {'Brain'  'Muscle'  'Eye'  'Heart'  'Line Noise'  'Channel Noise'  'Other'}.
    artifactLabelProbThresh = 0; % [0-1]
    artifactIcIdx = find((mostDominantClassLabelVector==2 & mostDominantClassLabelProbVector>=artifactLabelProbThresh)|...
        (mostDominantClassLabelVector==3 & mostDominantClassLabelProbVector>=artifactLabelProbThresh)|...
        (mostDominantClassLabelVector==4 & mostDominantClassLabelProbVector>=artifactLabelProbThresh)|...
        (mostDominantClassLabelVector==5 & mostDominantClassLabelProbVector>=artifactLabelProbThresh)|...
        (mostDominantClassLabelVector==6 & mostDominantClassLabelProbVector>=artifactLabelProbThresh));
    nonartifactIcIdx = setdiff(1:size(EEG.icaweights,1), artifactIcIdx);
    nonartifactGoodDipIcIdx = intersect(insideBrainAndGoodRvIdx, nonartifactIcIdx);
    EEG.etc.icStack.nonartifactIcIdx = nonartifactGoodDipIcIdx;

%     % Option 2: Identify brain ICs. The order of the classes are {'Brain'  'Muscle'  'Eye'  'Heart'  'Line Noise'  'Channel Noise'  'Other'}.
%     brainLabelProbThresh  = 0; % [0-1]
%     brainIdx = find((mostDominantClassLabelVector==1 & mostDominantClassLabelProbVector>=brainLabelProbThresh));
 
    % Perform IC rejection using residual variance of the IC scalp maps.
    rvList    = [EEG.dipfit.model.rv];
    goodRvIdx = find(rvList < 0.15)'; % < 15% residual variance == good ICs.
 
    % Perform IC rejection using inside brain criterion.
    load(EEG.dipfit.hdmfile); % This returns 'vol'.
    dipoleXyz = zeros(length(EEG.dipfit.model),3);
    for icIdx = 1:length(EEG.dipfit.model)
        dipoleXyz(icIdx,:) = EEG.dipfit.model(icIdx).posxyz(1,:);
    end
    depth = ft_sourcedepth(dipoleXyz, vol);
    depthThreshold = 1;
    insideBrainIdx = find(depth<=depthThreshold);
 
    % Take AND across the three criteria.
    goodIcIdx = intersect(brainIdx, goodRvIdx);
    goodIcIdx = intersect(goodIcIdx, insideBrainIdx);
 
    % Perform IC rejection.
    EEG = pop_subcomp(EEG, goodIcIdx, 0, 1);
 
    % Post-process to update ICLabel data structure.
    EEG.etc.ic_classification.ICLabel.classifications = EEG.etc.ic_classification.ICLabel.classifications(goodIcIdx,:);
 
    % Post-process to update EEG.icaact.
    EEG.icaact = [];
    EEG = eeg_checkset(EEG, 'ica');
end
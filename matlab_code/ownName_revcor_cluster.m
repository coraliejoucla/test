%% MODIFY PATHS ACCORDINGLY
if (~isdeployed)
    pathPrograms = 'G:\MATLAB\analysisCode'; %%%%% modify
    addpath(genpath(pathPrograms));
end

clear
clc

path_save = 'G:\MATLAB\results'; %%%%% modify

fileList = uipickfiles('FilterSpec', 'D:\PROCESSED EEG DATA\2021-own-name-revcor', 'Type', {'*.set', 'eeglab-files'}, 'REFilter', 'finalEEG_soft'); % pick .set file

% run eeglab to add path properly
run 'G:\eeglab2020_0\eeglab.m'
close(gcf);

savingSuffix = 'ownName_revcor_cluster_';
new_frequentMarker = 'frequent';
new_deviantMarker = 'deviant';
baselineRange = [-100 0]; % in ms

finalMarkerList = {new_frequentMarker, new_deviantMarker};

% Pipeline
for iter = 1:length(fileList) % i.e. for each subject
% iter = 1;
    % setting EEGLab options to double precision
    pop_editoptions('option_single', false);
    
    [filepath, filename, ext] = fileparts(fileList{iter});
    
    % eeg loading
    finalEEG = pop_loadset('filename', [filename, ext], 'filepath', filepath);
%     kk = finalEEG;
    % retriving subject ID
    subjectName = filename(end-3:end);
    
    % taking only frequent immediatly preceeding deviant
    tmpeventtype = {finalEEG.event.type};
    Index = strmatch('deviant', tmpeventtype, 'exact');
    count = 0;
    for ii = 1:length(Index)
        if ~isequal(finalEEG.event(Index(ii)-1).type, 'deviant')
            finalEEG.event(Index(ii)-1).type = 'freqBeforeDeviant';
        else
            finalEEG.event(Index(ii)).type = 'devToEliminate';
            count=count+1;
        end
    end
    
    finalEEG = pop_selectevent(finalEEG, 'type', {'deviant', 'freqBeforeDeviant'}, 'deleteevents','on');
    finalMarkerList = {'deviant', 'freqBeforeDeviant'};
    
    % Create study for intra-subject statistics
    ALLEEG = [];
    for ii = 1:length(finalMarkerList)
        tmpcsv = pop_selectevent(finalEEG, 'type', finalMarkerList{ii}, 'deleteevents','on');
        ALLEEG = eeg_store(ALLEEG, tmpcsv);
        ALLEEG(ii).setname = [finalMarkerList{ii}, '_', subjectName];
        ALLEEG(ii).subject = subjectName;
        ALLEEG(ii).condition = finalMarkerList{ii};
    end
    
    STUDY = [];
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name','Stats intraSubject Split','task','ownName','updatedat','off','rmclust','on');
    STUDY.filename = ['STUDY_', savingSuffix, subjectName];
    STUDY.filepath = path_save;
    [STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);
    
    % Statistics on ERPs
    % parameters
    [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','erp','on','erpparams',{'rmbase' baselineRange});
    
    dataFieldtrip = eeglab2fieldtrip(finalEEG, 'timelockanalysis');
    
    cfg.channel = {finalEEG.chanlocs.labels};
    cfg.method = 'triangulation';
    cfg.compress = 'yes';
    cfg.feedback = 'no';
    cfg.clusterstatistic = 'wvm';
    
    
    cfg.neighbours = ft_prepare_neighbours(cfg, dataFieldtrip);
    cfg.chanlocs = finalEEG.chanlocs;
    
    data{1} = ALLEEG(1).data;
    data{2} = ALLEEG(2).data;
    
    [cluster_stats, ~, ~] = statcondfieldtrip(...
        data,...
        'paired', 'off',...
        'method', 'permutation',...
        'naccu', 1000,...
        'alpha', 0.05,...
        'neighbours', cfg.neighbours,...
        'correctm', 'cluster',...
        'clusterthreshold', 'nonparametric_common',...
        'clusterstatistic', 'wcm',...
        'minnbchan', 3,...
        'structoutput', 'on');
    finalEEG.stats.clusterStats = cluster_stats;
%     imagesc(cluster_stats.mask)
%     pop = sum(cluster_stats.mask, 1);
%     plot(pop(:, 101:end));
    
    
    %% time cluster
    durationOfEffect = 10;
    for ii = 1:size(cluster_stats.mask, 1)
        significantTime = regionprops(cluster_stats.mask(ii, :), {'Area', 'PixelIdx'});
        significantTime(find([significantTime.Area]<durationOfEffect)) = [];
        array = zeros(1, size(cluster_stats.mask, 2));
        array(vertcat(significantTime(1:end).PixelIdxList)) = 1;
        cluster_stats.timeClusteredMask(ii, :) = array;
    end
%     imagesc(cluster_stats.timeClusteredMask)
    imagesc(cluster_stats.timeClusteredMask.*cluster_stats.t)
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, [path_save, filesep, 'stats_t_subject_', subjectName, '.png']);
    close(gcf);   
    
    %% spatial cluster
%     signifmat = cluster_stats.mask;
    signifmat = cluster_stats.timeClusteredMask.*cluster_stats.t;
    
    pos = max(signifmat, 0); % only significant moments with positive t
    neg = min(signifmat, 0); % only significant moments with negative t
    
    % get connectivity matrix for the spatially neighbouring elements
    cfg.connectivity = ft_getopt(cfg, 'connectivity', []); % the default is dealt with below
    cfg.neighbours = ft_getopt(cfg, 'neighbours', []);
    cfg.connectivity = channelconnectivity(cfg);
    connmat = full(ft_getopt(cfg, 'connectivity', false));
    
    % min number of neighbouring channels
    cfg.minnbchan = 3;
    
    [finalEEG.stats.negMatrix, ~] = findcluster_coralie(neg, connmat, cfg.minnbchan);
    [finalEEG.stats.posMatrix, ~] = findcluster_coralie(pos, connmat, cfg.minnbchan);
    finalEEG.stats.posCluster = find(sum(abs(finalEEG.stats.posMatrix), 2)>0);
    finalEEG.stats.negCluster = find(sum(abs(finalEEG.stats.negMatrix), 2)>0);
%     imagesc(cluster)
    
    timeVector = [249:50:599];
%     timeVector = [350:5:370];
    EEG = finalEEG;
    EEG.data = finalEEG.stats.posMatrix;
    EEG.trials = 1;
    EEG = eeg_checkset(EEG);
    % attention, topoplot prend en compte la baseline
    pop_topoplot(EEG, 1, timeVector, ['positive cluster subject ', subjectName],[ceil(length(timeVector)/4) ceil(length(timeVector)/2)],0,'electrodes','labels', 'maplimits', [0 1]);
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, [path_save, filesep, 'positiveCluster_subject_', subjectName, '.png']);
    close(gcf);
    
    EEG.data = finalEEG.stats.negMatrix;
    EEG.trials = 1;
    EEG = eeg_checkset(EEG);
    % attention, topoplot prend en compte la baseline
    pop_topoplot(EEG, 1, timeVector, ['negative cluster subject ', subjectName],[ceil(length(timeVector)/4) ceil(length(timeVector)/2)],0,'electrodes','on', 'maplimits', [0 1]);
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, [path_save, filesep, 'negativeCluster_subject_', subjectName, '.png']);
    close(gcf);

    pop_saveset(finalEEG, 'filename', filename, 'filepath', filepath);
end


    
    % %% Simple 2-D movie
    
    % % Above, convert latencies in ms to data point indices
    % pnts1 = round(eeg_lat2point(-100/1000, 1, finalEEG.srate, [finalEEG.xmin finalEEG.xmax]));
    % pnts2 = round(eeg_lat2point( 600/1000, 1, finalEEG.srate, [finalEEG.xmin finalEEG.xmax]));
    % scalpERP = cluster_stats.mask(:,pnts1:pnts2);
    %
    % % Smooth data
    % % for iChan = 1:size(scalpERP,1)
    % %     scalpERP(iChan,:) = conv(scalpERP(iChan,:) ,ones(1,5)/5, 'same');
    % % end
    %
    % % 2-D movie
    % figure; [Movie,Colormap] = eegmovie(scalpERP, finalEEG.srate, finalEEG.chanlocs, 'framenum', 'off', 'vert', 0, 'startsec', -0.1, 'topoplotopt', {'numcontour' 0});
    % seemovie(Movie,-5,Colormap);
    %
    % % save movie
    % vidObj = VideoWriter('erpmovie2d.mp4', 'MPEG-4');
    % open(vidObj);
    % writeVideo(vidObj, Movie);
    % close(vidObj);
    %
    %
    % end


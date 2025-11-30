function STUDY = createStudy(EEG, finalMarkerList, folder_save, subjectName, taskName)
    % create study
    ALLEEG = [];
    commands = cell(length(finalMarkerList), 1);
    for ii = 1:length(finalMarkerList)
        commands{ii} = {'index', ii, 'subject', num2str(subjectName)};
        tmpEEG = pop_selectevent(EEG, 'type', finalMarkerList{ii}, 'deleteevents','on');
        ALLEEG = eeg_store(ALLEEG, tmpEEG);
        ALLEEG(ii).setname = [finalMarkerList{ii}, '_', subjectName];
        ALLEEG(ii).subject = subjectName;
        ALLEEG(ii).condition = finalMarkerList{ii};
        ALLEEG(ii).filename = ['tmpEEG_', taskName, '_', finalMarkerList{ii}, '_', EEG.setname, '.set'];
        ALLEEG(ii).filepath = folder_save;
        pop_saveset(tmpEEG, 'filename', ['tmpEEG_', taskName, '_', finalMarkerList{ii}, '_', EEG.setname], 'filepath', folder_save) % save a dataset for each subject and each marker
    end

    STUDY = [];
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', [taskName, '_', EEG.setname],...
        'commands', commands,...
        'task', taskName,...
        'updatedat','off',...
        'rmclust','on');

    % save study for individual subjects
    pop_savestudy(STUDY, ALLEEG, 'filepath', folder_save, 'filename', [taskName, '_', EEG.setname, '.study'], 'savemode', 'standard', 'resavedatasets', 'off');
end
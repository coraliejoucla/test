function [EEG, sumNaN2] = checkNan(EEG)
    sumNaN = sum(sum(isnan(EEG.data)));
    if ~isequal(sumNaN, 0)
        indices = find(isnan(EEG.data) == 1);
        [~,J] = ind2sub(size(EEG.data),indices);
        EEG = pop_select(EEG, 'nopoint', [2 50200 ; 3400000 EEG.pnts]);%[J(1):J(end)]);
    end
    sumNaN2 = sum(sum(isnan(EEG.data)));
end
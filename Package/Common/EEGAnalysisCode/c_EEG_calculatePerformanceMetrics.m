function m = c_EEG_calculatePerformanceMetrics(EEG)

trialOutcomes = c_EEG_extractTrialOutcomes(EEG);

trialTargets = cell2mat({EEG.event(ismember({EEG.event.type},'TargetCode')).position});

m.numTrials = length(trialOutcomes);
m.numCorrect = sum(trialOutcomes==trialTargets);
m.numAborts = sum(isnan(trialOutcomes));
m.numIncorrect = m.numTrials - m.numCorrect - m.numAborts;

m.PVC = m.numCorrect / (m.numIncorrect + m.numCorrect);

m.PTC = m.numCorrect / m.numTrials;

end
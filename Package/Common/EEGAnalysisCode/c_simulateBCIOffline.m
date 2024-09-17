function newEEG = c_simulateBCIOffline(varargin)

persistent pathModified;
if isempty(pathModified)
	addpath('../'); %TODO: only run if not already on path
	pathModified = true;
end

if nargin == 0
	% for testing
	c_sayResetLevel;
	c_say('No input parameters, running test...');
	testPath = 'D:/BCIYoga/SubjectData/JMP/JMP_LRt_20141017001/JMP_LRt_20141017S001R02.dat';
% 	testPath = 'D:/BCIYoga/SubjectData/AMG/AMG_LRt_20141104001/AMG_LRt_20141104S001R01.dat';

	c_simulateBCIOffline(testPath,...
		'leftChannel','C3','rightChannel','C4',...
		'normalization','online',...
		'spatialFilter','none',...
		'doCompareToOnline',false,...
		'doPlot',true);
	c_sayDone();
	
	return
end

%% input parameters
p = inputParser();
p.addRequired('EEG',@(x) ischar(x) || isstruct(x));  % path to data file, or raw EEG struct already imported with EEGLAB
p.addParameter('BCI2000Path','C:/Program Files/BCI2000');
p.addParameter('montage','Neuroscan68',@ischar);
p.addParameter('channelsToKeep',{'C3','C4'},@iscell);
% p.addParameter('channelsToKeep',{'C3','FC3','C1','CP3','C5','C4','FC4','C6','CP4','C2'},@iscell);
% p.addParameter('channelsToKeep',{},@iscell);
p.addParameter('windowDuration',0.16,@iscalar); % window length, in seconds
p.addParameter('dt',40e-3,@isscalar); % time between frames, in s
p.addParameter('ARArgs',{},@iscell);
p.addParameter('controlType','left/right',@ischar); %valid: 'left/right', 'up/down', '2D'
p.addParameter('spatialFilter','none',@ischar); %valid 'none','laplacian','rereference'
p.addParameter('leftChannel','C3',@ischar);
p.addParameter('rightChannel','C4',@ischar);
p.addParameter('normalization','offline',@ischar); % valid: online, offline, none
p.addParameter('onlineNormalizer_bufferDuration',30,@isscalar); % in s
p.addParameter('onlineNormalizer_initialOffset',0,@isscalar);
p.addParameter('onlineNormalizer_initialGain',0.05,@isscalar);
p.addParameter('normalizer_typeWeights',[1 1]'/2,@ismatrix); % each column is a single output channel, each row a separate buffer (for trial type)
p.addParameter('classification_hitThreshold',0.8e3,@isscalar);
p.addParameter('screenCenter',[2050 2050 2050]);
p.addParameter('screenMultiplier',[50 50 50]);
p.addParameter('doPlot',false,@islogical);
p.addParameter('doCompareToOnline',false,@islogical);
p.parse(varargin{:});

if strcmpi(p.Results.controlType,'left/right')
	numOutputDim = 1;
else
	error('Only left/right control currently supported');
	%TODO: add support for up/down and 2D control
end

dt = p.Results.dt;

marker_left = 1;
marker_right = 2;
marker_abort = nan;

%% load EEG data as needed
EEG = p.Results.EEG;

% If path was specified, load data file with EEGlab
if ~isstruct(EEG)
	c_say('Loading BCI2000 data file from specified path');
	EEG = c_loadBCI2000Data(EEG);
	c_sayDone();
end

originalEEG = EEG; % keep copy of unmodified struct

%%
		
% add channel labels
EEG = c_EEG_setChannelLabelsFromMontage(EEG,p.Results.montage);

% epoch
EEG = c_EEG_epoch(EEG,...
	'doUseEEGLab',false,...
	'eventType','TargetCode',...
	'timeBeforeEvent',-2 + p.Results.windowDuration,...
	'timeAfterEvent',-1);

% spatial filter
switch(lower(p.Results.spatialFilter))
	case 'laplacian'
		c_say('Applying laplacian filter');
		EEG = c_EEG_filter_laplacian(EEG,...
			'channelsToKeep',{p.Results.leftChannel, p.Results.rightChannel});
		c_sayDone();
		
	case 'rereference'
		c_say('Applying re-referencing filter');
		EEG = c_EEG_filter_rereference(EEG);
		c_sayDone();
		
	case 'none'
		% do nothing
		
	otherwise
		error('Invalid spatial filter: %s',p.Results.spatialFilter);	
end

% cut out unneeded channels
if ~isempty(p.Results.channelsToKeep)
	EEG = c_EEG_reduceChannelData(EEG,[p.Results.channelsToKeep p.Results.leftChannel p.Results.rightChannel]);
else
	EEG = c_EEG_reduceChannelData(EEG,{p.Results.leftChannel p.Results.rightChannel});
end


%% feature extraction (AR filter)
c_say('Extracting features with AR spectral estimator');
EEG = c_EEG_epochExtractData(EEG);
sig = EEG.epochs.data;

[Pxx, F, T] = c_spectralEstimatorAR(sig,EEG.srate,...
	'windowDuration',p.Results.windowDuration,...
	'windowSeparation',dt,...
	'detrendType','linear',...
	'doFillInBetweenWindows',false);
c_sayDone();

%% classification (to generate instantaneous control signal)

[~,freqIndex] = min(abs(F-12)); % find index of bin closest to 12 Hz
% for each trial, calculate power spectra difference between C3 and C4, then integrate over the whole trial
index_leftChannel = c_EEG_getChannelIndex(EEG,p.Results.leftChannel);
index_rightChannel = c_EEG_getChannelIndex(EEG,p.Results.rightChannel);
controlSignal = squeeze(Pxx(index_rightChannel,:,:,freqIndex) - Pxx(index_leftChannel,:,:,freqIndex));

if p.Results.doPlot
	exampleTrialIndex = 1;
	figure; 
	c_subplot(1,4);
	plot(controlSignal(exampleTrialIndex,:));
	title('Un-normalized signal in one trial');
	c_subplot(2,4);
	plot(cumsum(controlSignal(exampleTrialIndex,:)));
	title('Un-normalized cumulative sum of signal in one trial');
end;

%% normalization
switch(lower(p.Results.normalization))
	case 'offline'
		c_say('Performing offline normalization');
		
		trialTypes = EEG.epochs.types;
		numTrialTypes = length(unique(trialTypes));
		uniqueTrialTypes = 1:numTrialTypes;
		subMeans = zeros(numTrialTypes,1);
		subStds = zeros(numTrialTypes,1);
		for i=1:numTrialTypes
			sig = reshape(controlSignal(trialTypes==uniqueTrialTypes(i),:),1,[]);
			subMeans(i) = nanmean(sig);
			subStds(i) = nanstd(sig);
		end
		if size(p.Results.normalizer_typeWeights,2) ~= numOutputDim
			error('Incorrect size of normalizer_typeWeights');
		end
		
		normalizerOffset = -1*subMeans'*p.Results.normalizer_typeWeights;
		normalizerGain = 1./sqrt(subStds'.^2*p.Results.normalizer_typeWeights);
		
		controlSignal = (controlSignal + normalizerOffset) * normalizerGain;
		
		c_sayDone();
	case 'online'
		c_say('Performing online-style normalization');
		% use separate buffers for separate trial targets
		trialTypes = EEG.epochs.types;
		numBuffers = length(unique(trialTypes));
		bufferLength = round(p.Results.onlineNormalizer_bufferDuration / dt);
		normalizationBuffers = nan(numBuffers, bufferLength);
		ringCounters = ones(numBuffers,1);
		buffersInitialized = zeros(numBuffers,1);
		
		if size(p.Results.normalizer_typeWeights,2) ~= numOutputDim
			error('Incorrect size of normalizer_typeWeights');
		end
		
		% initialize buffer with values such that specified initial offset and gain will be used
		% (assuming that first trial which will override these will be at least two samples long)
		normalizationBuffers(:,1:2) = repmat(...
			- p.Results.onlineNormalizer_initialOffset + ... %TODO: check sign on initial offset
			[-1 1]/sqrt(2)/p.Results.onlineNormalizer_initialGain,...
			numBuffers,1);

		% calculate normalizers gains and offsets at each trial
		for i=1:size(controlSignal,1) % for each trial
			if any(~buffersInitialized) && any(buffersInitialized)
				modifiedTypeWeights = (p.Results.normalizer_typeWeights .* buffersInitialized);
				modifiedTypeWeights = modifiedTypeWeights * norm(p.Results.normalizer_typeWeights,1) / norm(modifiedTypeWeights,1);
			else
				modifiedTypeWeights = p.Results.normalizer_typeWeights;
			end
			
			if 1
				normalizerOffset_perTrial(i) = -1*nanmean(normalizationBuffers,2)'*modifiedTypeWeights;
				normalizerGain_perTrial(i) = 1./sqrt(nanstd(normalizationBuffers,0,2).^2'*modifiedTypeWeights);
			else
				dataMean = nanmean(normalizationBuffers,2)'*modifiedTypeWeights;
				dataSqMean = nanmean(normalizationBuffers.^2,2)'*modifiedTypeWeights;
				dataVar = dataSqMean - dataMean.^2;
				
				normalizerOffset_perTrial(i) = -1*dataMean
				normalizerGain_perTrial(i) = 1/sqrt(dataVar)
			end
				
			% incorporate information from this trial into buffer
			trialLength = find(~isnan(controlSignal(i,:)),1,'last');
			normalizationBuffers(trialTypes(i),mod(ringCounters(trialTypes(i)) + (1:trialLength) - 2,bufferLength)+1) = controlSignal(i,1:trialLength);
			ringCounters(trialTypes(i)) = mod(ringCounters(trialTypes(i)) + trialLength - 1, bufferLength) + 1;
			buffersInitialized(trialTypes(i)) = true;
		end
		
		% apply gains and offsets to control signal for each trial
		for i=1:size(controlSignal,1)
			controlSignal(i,:) = (controlSignal(i,:) + normalizerOffset_perTrial(i)) * normalizerGain_perTrial(i);
		end
		
		c_sayDone();
	case 'none'
		% do nothing
	otherwise
		error('invalid normalization type: %s',p.Results.normalization);
end

finalCumulativeSignals = nansum(controlSignal,2);
if p.Results.doPlot
	figure;
	bar(finalCumulativeSignals)
end

%% new classification (simulated)

new.cursorPosition = zeros(size(controlSignal,1),3,size(controlSignal,2));
new.cursorPosition(:,1,:) = cumsum(controlSignal,2);
for i=1:size(new.cursorPosition,1)
	new.cursorPosition(i,2:3,isnan(new.cursorPosition(i,1,:))) = NaN;
end
new.cursorPositionTimes = repmat(((1:size(new.cursorPosition,3))-1)*(dt),size(new.cursorPosition,1),1);
new.cursorPositionTimes = bsxfun(@plus,new.cursorPositionTimes,(EEG.epochs.startTimes'+ p.Results.windowDuration)); % convert from relative to absolute time

% convert to screen coordinates to match recorded cursor positions
new.cursorPosition = bsxfun(@plus,bsxfun(@times,new.cursorPosition,p.Results.screenMultiplier),p.Results.screenCenter);

centeredPosition = squeeze(new.cursorPosition(:,1,:) - p.Results.screenCenter(1));

% set threshold for classification
if ~isnan(p.Results.classification_hitThreshold)
	% fixed threshold (related to screen size)
	threshold = p.Results.classification_hitThreshold;
else
	% classification based on exceeding dynamic limit
	threshold = sqrt(nanmean(centeredPosition(:).^2));
end	
	
% classify trials and calculate new trial durations
for i=1:size(new.cursorPosition,1) % for each trial
	endIndex = find(abs(centeredPosition(i,:)) > threshold,1,'first');
	if isempty(endIndex)
		new.outcomes(i) = marker_abort;
		endIndex = find(~isnan(centeredPosition(i,:)),1,'last');
	elseif centeredPosition(i,endIndex) > 0
		new.outcomes(i) = marker_left;
	elseif centeredPosition(i,endIndex) < 0
		new.outcomes(i) = marker_right;
	else
		error('invalid threshold?');
	end
	new.durations(i) = new.cursorPositionTimes(i,endIndex) - new.cursorPositionTimes(i,1);
end

%% old classification (original data)	
if p.Results.doCompareToOnline
	orig.outcomes = c_EEG_extractTrialOutcomes(EEG);
	orig.durations = EEG.epochs.durations - p.Results.windowDuration;

	[orig.cursorPosition, orig.cursorPositionTimes] = c_EEG_extractCursorPosition(EEG,'doReturnPaddedMatrix',true);
	% make times relative to beginning of each trial
	%orig.cursorPositionTimes = bsxfun(@minus,orig.cursorPositionTimes,orig.cursorPositionTimes(:,1)); 
end

%% embed results back into EEG struct

c_say('Embedding new results into EEG struct');
newEEG = c_EEG_modifyEvents(originalEEG,...
	'cursorPositions',new.cursorPosition,...
	'cursorPositionTimes',new.cursorPositionTimes,...
	'trialDurations',new.durations,...
	'trialOutcomes',new.outcomes);
c_sayDone();

if 0
	% (for testing)
	secondEEG = c_simulateBCIOffline(newEEG,...
			'leftChannel','C3','rightChannel','C4',...
			'normalization','online',...
			'spatialFilter','none',...
			'doPlot',true);
		
	thirdEEG = c_simulateBCIOffline(secondEEG,...
			'leftChannel','C3','rightChannel','C4',...
			'normalization','online',...
			'spatialFilter','none',...
			'doPlot',true);
end


%% analyze results

if p.Results.doCompareToOnline
	results = [orig new];
	titles = {'Online','Offline'};
else
	results = [new];
	titles = {'Offline'};
end

for j=1:length(results);
	res = results(j);
	numTrials = length(res.outcomes);
	numCorrect = sum(res.outcomes == EEG.epochs.types);
	numAborts = sum(isnan(res.outcomes));
	numIncorrect = numTrials - numCorrect - numAborts;
	PVC = numCorrect/(numIncorrect + numCorrect);
	PTC = numCorrect/numTrials;
	c_saySingle('%s: %d correct, %d miss, %d abort, %.2f PVC %.2f PTC',...
		titles{j}, numCorrect, numIncorrect, numAborts, PVC, PTC); 
end

if p.Results.doPlot
	% compare all trials with one version to all trials with another
	figure;
	for j=1:length(results);
		res = results(j);
		
		% convert from absolute to relative time
		res.cursorPositionTimes = bsxfun(@minus,res.cursorPositionTimes,res.cursorPositionTimes(:,1)); 
		
		c_subplot(j,length(results));
		for i=1:size(res.cursorPosition,1) % for each trial
			intensity = 1;
% 			intensity = i/size(res.cursorPosition,1);
			if (isnan(marker_abort) && isnan(res.outcomes(i))) || res.outcomes(i)==marker_abort
				color = [0.5 0.5 0.5];
			elseif res.outcomes(i)==marker_right
				color = [1 0 0];
			elseif res.outcomes(i)==marker_left
				color = [0 0 1];
			else
				color = [0 0 0];
			end
			if ~isnan(res.durations(i))
				index = c_indexInAClosestToB(res.cursorPositionTimes(i,:)-res.cursorPositionTimes(i,1), res.durations(i));
			else
				index = size(res.cursorPositionTimes,2);
			end
			plot(res.cursorPositionTimes(i,1:index)',squeeze(res.cursorPosition(i,1,1:index))','color',color*intensity);
			hold on;
			plot(res.cursorPositionTimes(i,index:end)',squeeze(res.cursorPosition(i,1,index:end))','color',color*intensity,'LineStyle','--');
			plot(res.durations(i),res.cursorPosition(i,1,index),'.k');
			
		end
		title(titles{j});
	end
	
	if 1 % compare trial-by-trial
		figure;
		for i=1:size(results(1).cursorPosition,1) % for each trial
			c_subplot(i,size(results(1).cursorPosition,1));
			for j=1:length(results);
				res = results(j);
				intensity = 1;
	% 			intensity = i/size(res.cursorPosition,1);
				if (isnan(marker_abort) && isnan(res.outcomes(i))) || res.outcomes(i)==marker_abort
					color = [0.5 0.5 0.5];
				elseif res.outcomes(i)==marker_right
					color = [1 0 0];
				elseif res.outcomes(i)==marker_left
					color = [0 0 1];
				else
					color = [0 0 0];
				end
				color = color*intensity;
				color(2) = color(2) + (j-1)/2;
				plot(res.cursorPositionTimes(i,:)',squeeze(res.cursorPosition(i,1,:))','color',color);
				hold on;
			end
			legend(titles);
		end
	end
	
	keyboard
end








end




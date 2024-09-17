function c_EEG_spectopo(varargin)
% The EEGLab spectopo function just concatenates epochs, does not maintain boundaries at epoch boundaries
% This provides an alternative.

persistent pathModified;
if isempty(pathModified)
	addpath(genpath('../Common/ThirdParty/boundedline'));
	pathModified = true;
end

p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('freq',[],@(x) isvector(x) || isempty(x));
p.addParameter('channels',[],@(x) isempty(x) || isvector(x) || iscell(x));
p.addParameter('timeRange',[],@(x) length(x)==2 && isnumeric(x)); % time in s to analyze (for if only want to look at smaller timespan within epochs)
p.addParameter('freqRange',[],@(x) length(x)==2 && isnumeric(x)); % freq in Hz to set spectra plot limits
p.addParameter('epochIndices',[],@isvector); % to only analyze a subset of epochs
p.addParameter('psdMethod','pwelch',@ischar);
p.addParameter('doPlotStdErr',true,@islogical);
p.addParameter('plotArgs',{},@iscell);
p.addParameter('doPlotByGroup',false,@islogical); % whether to use EEG.epochGroups and EEG.epochGroupLabels
p.parse(varargin{:});


EEG = p.Results.EEG;
epochIndices = p.Results.epochIndices;

doPlotTopos = ~isempty(p.Results.freq);
doPlotByGroup = p.Results.doPlotByGroup && c_isFieldAndNonEmpty(EEG,'epochGroups');
if doPlotByGroup && ~c_isFieldAndNonEmpty(EEG,'epochGroupLabels')
	for g=1:length(EEG.epochGroups)
		EEG.epochGroupLabels{g} = sprintf('Group %d',g);
	end
end


% channels to plot spectra
if isempty(p.Results.channels)
	plotChannelIndices = 1:size(EEG.data,1);
else
	if iscell(p.Results.channels)
		plotChannelIndices = c_EEG_getChannelIndex(EEG,p.Results.channels);
	else
		plotChannelIndices = p.Results.channels;
	end
end

% channels to actually calculate
if doPlotTopos
	channelIndices = 1:size(EEG.data); 
else
	channelIndices = plotChannelIndices;
	plotChannelIndices = 1:length(channelIndices);
end

if isempty(p.Results.timeRange)
	timeIndices = 1:size(EEG.data,2);
else
	timeIndices = EEG.times/1e3 >= p.Results.timeRange(1) & EEG.times/1e3 < p.Results.timeRange(2);
end

if isempty(epochIndices)
	epochIndices = 1:size(EEG.data,3);
end

%% calculate PSD for each channel, for each epoch
data = EEG.data(channelIndices,timeIndices,epochIndices);
numChannels = size(data,1);
numTimes = size(data,2);
numEpochs = size(data,3);
data = permute(data,[2 1 3]); % (channel, time, epoch) -> (time, channel, epoch)
data = reshape(data,numTimes,numChannels*numEpochs);

switch p.Results.psdMethod
	case 'fft'
		NFFT = 2^nextpow2(numTimes);

		data = bsxfun(@times,data,hamming(numTimes));

		Data = fft(data,NFFT,1);
		Data = Data(1:NFFT/2+1,:);
		Data = 1/(EEG.srate*numTimes)*abs(Data).^2;
		Data(2:end-1,:) = 2*Data(2:end-1,:);
		f = linspace(0,EEG.srate/2,size(Data,1));
	
	case 'pwelch'
		for i=1:numChannels*numEpochs
			[Data(:,i),f] = pwelch(data(:,i),floor(numTimes/2),[],[],EEG.srate);
		end
	
	case 'pmtm'
		for i=1:numChannels*numEpochs
			[Data(:,i),f] = pmtm(data(:,i),3,[],EEG.srate);
		end
		
	otherwise
		error('Unrecognized PSD method: %s',p.Results.psdMethod);
		
end

Data = 10*log10(Data); % convert to dB
numFreqs = size(Data,1);
Data = reshape(Data,numFreqs,numChannels,numEpochs);
Data = ipermute(Data,[2 1 3]); % (time, channel, epoch) -> (channel, time, epoch)

%% average across epochs
meanData = mean(Data,3);
stdErrData = std(Data,1,3)/sqrt(size(Data,3));

if doPlotByGroup
	numGroups = length(EEG.epochGroupLabels);
	for g=1:numGroups
		meanGroupData(:,:,g) = mean(Data(:,:,EEG.epochGroups{g}),3);
		if islogical(EEG.epochGroups{g}) 
			numEpochsInGroup = sum(EEG.epochGroups{g});
		else
			numEpochsInGroup = length(EEG.epochGroups{g});
		end
		stdErrGroupData(:,:,g) = std(Data(:,:,EEG.epochGroups{g}),1,3)/sqrt(numEpochsInGroup);
	end
else
	numGroups = 1;
	meanGroupData = meanData;
	stdErrGroupData = stdErrData;
end

%% plot

if doPlotTopos && ~doPlotByGroup
	c_subplot('position',[0 0 1 0.5]);
end

numPlotChannels = length(plotChannelIndices);
if numPlotChannels ~= 1 || numGroups ~= 1
	colors = c_getColors(numPlotChannels*numGroups);
	colors = permute(reshape(colors,[numPlotChannels,numGroups,3]),[1 3 2]);
	for i=1:numPlotChannels
		for g=1:numGroups
			j = plotChannelIndices(i);
			if ~p.Results.doPlotStdErr
				plot(f,meanGroupData(j,:,g),'color',colors(i,:,g),p.Results.plotArgs{:});
			else
				c_boundedline(f,meanGroupData(j,:,g)',stdErrGroupData(j,:,g)',...
					'cmap',colors(i,:,g),p.Results.plotArgs{:});
			end
			hold on;
		end
	end
	
	% legend
	if doPlotByGroup
		legendEntries = {};
		for i=1:numPlotChannels
			for g=1:numGroups
				legendEntries = [legendEntries, sprintf('%s %s', ...
					EEG.chanlocs(plotChannelIndices(i)).labels, EEG.epochGroupLabels{g})];
			end
		end
	else
		legendEntries = {EEG.chanlocs(plotChannelIndices).labels};
	end		
	legend(legendEntries);
	if numPlotChannels*numGroups > 8
		legend('hide'); % hide legend if it's too big
	end
else
	j = plotChannelIndices(1);
	if ~p.Results.doPlotStdErr
		plot(f,meanData(j,:),p.Results.plotArgs{:});
	else
		[hl, hp] = boundedline(f,meanData(j,:),stdErrData(j,:),p.Results.plotArgs{:});
		% do not include bounds in legend entries
		set(get(get(hp,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
	end
end

xlabel('Frequency (Hz)');
ylabel('Power (dB)');
if ~isempty(p.Results.freqRange)
	xlim(p.Results.freqRange);
end



if doPlotTopos
	numFreq = length(p.Results.freq);
	
% 	plotTopoAtFreq = @(freq) ...
% 		c_subplot('position',0,0.5,1/numFreq,0.5);...
% 		[~,freqIndex] = min(abs(freq-f));...
% 		topoplot(meanData(:,freqIndex),EEG.chanlocs);
	if doPlotByGroup
		% just create a separate figure to keep things simpler
		figure('name','topos by group');
	end

	subplotLims = linspace(0,1,numFreq+1);
	for j=1:numFreq
		for g=1:numGroups
			if ~doPlotByGroup
				c_subplot('position',[subplotLims(j),0.5,1/numFreq,0.5]);
			else
				c_subplot(numGroups*2-1,numFreq,g,j);
			end
			fp = p.Results.freq(j);
			[freqError,freqIndex] = min(abs(fp - f));
			if freqError > 1
				warning('Plotting topo at f=%.2g Hz instead of f=%.2g Hz.',f(freqIndex),fp);
			end
			topoplot(meanGroupData(:,freqIndex,g), EEG.chanlocs,'maplimits','maxmin');
			if ~doPlotByGroup
				title(sprintf('f=%.2g Hz',f(freqIndex)));
			else
				title(sprintf('f=%.2g Hz, %s',f(freqIndex),EEG.epochGroupLabels{g}));
			end
			if doPlotByGroup && g>1
				% plot topo difference
				c_subplot(numGroups*2-1,numFreq,numGroups+g-1,j);
				topoplot(meanGroupData(:,freqIndex,1)-meanGroupData(:,freqIndex,g),EEG.chanlocs,'maplimits','absmax');
				title(strjoin([...
					setdiff(strsplit(EEG.epochGroupLabels{1}),strsplit(EEG.epochGroupLabels{g})),...
					{' - '},...
					setdiff(strsplit(EEG.epochGroupLabels{g}),strsplit(EEG.epochGroupLabels{1}))]));
					
			end
		end
	end
end
	
end
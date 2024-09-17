function c_EEG_plotEpochs(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('data','data',@(x) ischar(x) || isnumeric(x)); % name of field in EEG struct or raw data
p.addParameter('COI',[],@(x) iscell(x) || isnumeric(x)); % channel(s) of interest (channel labels if cell array), or
	% indices into first dimension of data (for channels, dipoles, ROIs, etc.)
p.addParameter('dataLabels',{},@iscell);
p.addParameter('doSoftmaxLimits',false,@islogical);
p.addParameter('autoscaleIgnoreTimespan',[],@isnumeric); % in s, time period to ignore when autoscaling
p.addParameter('doPlotIndividualEpochs',false,@islogical);
p.addParameter('doPlotBounds',false,@islogical);
p.addParameter('doPlotGMFA',false,@islogical);
p.addParameter('reduceOperation','mean',@(x) ischar(x) || isa(x,'function_handle'));
p.addParameter('doClickableLegend',true,@islogical);
p.addParameter('doPlotStacked',false,@islogical);
p.addParameter('boundsMethod','stderr',@(x) ischar(x) || isa(x,'function_handle')); % valid: std, stderr, or custom callback of form f(x,dim)
p.addParameter('groupIndices',{},@iscell);
p.addParameter('groupLabels',{},@iscell);
p.addParameter('xLabel','Time (ms)',@ischar);
p.addParameter('yLabel','Voltage (uV)',@ischar);
p.addParameter('singleTraceColor',[1 1 1]*0.5,@isnumeric);
p.addParameter('singleTraceAvgColor',[0 0 0],@isnumeric);
p.addParameter('lineWidth',[],@isscalar);
p.addParameter('SNRdBFloor',-30,@isscalar);
p.parse(varargin{:});
s = p.Results;

%% initialization and parsing
EEG = s.EEG;
gi = s.groupIndices;

figHandle = gcf;

persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/boundedline'));
	addpath(fullfile(mfilepath,'../ThirdParty/clickable_legend'));
	pathModified = true;
end

% data
if ischar(s.data)
	% name of field in EEG struct
	data = c_getField(EEG,s.data);
else
	% raw data
	data = s.data;
end

% COI
if isempty(s.COI)
	% plot all channels
	s.COI = 1:size(data,1);
end
if iscell(s.COI)
	% convert from cell array of channel labels to indices
	s.COI = c_EEG_getChannelIndex(EEG,s.COI);
end

if length(s.COI) > 1
	channelColors = c_getColors(length(s.COI));
end

% reduce data to just relevant subset
data = data(s.COI,:,:);


% convert multiple channels to single "channel" GMFA if requested
if s.doPlotGMFA
	data = c_EEG_calculateGMFA(data);
	s.COI = 1; 
end

if ~c_EEG_isEpoched(EEG)
	error('EEG not epoched.');
end
	
t = EEG.times;
	
if isempty(gi)
	% no groups (make all data one group)
	groupColors = s.singleTraceColor;
	groupAvgColors = s.singleTraceAvgColor;
	
	gi{1} = true(1,size(data,3));
else
	if length(s.COI) > 1
		error('Multiple channels and multiple groups not currently supported.');
	end
	
	groupColors = c_getColors(length(gi));
	groupAvgColors = groupColors * 0.8;
end
	

if s.doPlotStacked
	tmpY = nan(length(t),length(gi));
	stackedHandles = c_plot_stacked(t,tmpY,'xlabel',s.xLabel,'ylabel',s.yLabel,'ylabels',s.groupLabels);
end

if s.doPlotIndividualEpochs
	if length(s.COI) > 1
		error('Plotting individual epochs for multiple channels not currently supported');
		%TODO
	end
	
	for g=1:length(gi)
		groupData = data(1,:,gi{g});
	
		if s.doPlotStacked
% 			set(figHandle, 'CurrentHandle', stackedHandles(g));
			set(figHandle, 'CurrentAxes', stackedHandles(g));
		end
		plot(t,squeeze(groupData(1,:,:)),'Color',groupColors(g,:),'LineWidth',0.5);
		hold on;
	end
end

groupwiseDataToPlotExtrema = [inf, -inf];

if ischar(s.reduceOperation)
	switch(s.reduceOperation)
		case 'mean'
			s.reduceOperation = @(x,dim) nanmean(x,dim);
		case 'median'
			s.reduceOperation = @(x,dim) nanmedian(x,dim);
		case 'std'
			s.reduceOperation = @(x,dim) nanstd(x,0,dim);
		case 'SNR'
			s.reduceOperation = @(x,dim) abs(nanmean(x,dim)) ./ nanstd(x,0,dim);
			if ismember('yLabel',p.UsingDefaults)
				s.yLabel = 'SNR';
			end
		case 'SNRdB'
			s.reduceOperation = @(x,dim) 20*log10(abs(nanmean(x,dim)) ./ nanstd(x,0,dim));
			if ismember('yLabel',p.UsingDefaults)
				s.yLabel = 'SNR (dB)';
			end
		otherwise
			error('Unrecognized reduce operation: %s',s.reduceOperation);
	end
end

if ~isempty(s.autoscaleIgnoreTimespan)
	indicesToIgnore = t>=s.autoscaleIgnoreTimespan(1)*1e3 & t<=s.autoscaleIgnoreTimespan(2)*1e3;
else
	indicesToIgnore = false(size(t));
end

hl = [];
hp = [];
for g=1:length(gi)
	groupData = data(:,:,gi{g});
	
	dataToPlot = s.reduceOperation(groupData,3);
			
	dataToPlotExtrema = extrema(dataToPlot(:,~indicesToIgnore,:),[],2);
	if ~isvector(dataToPlotExtrema) % multichannel data
		dataToPlotExtrema = diag(extrema(dataToPlotExtrema,[],1));
	end
	if groupwiseDataToPlotExtrema(1) > dataToPlotExtrema(1), groupwiseDataToPlotExtrema(1) = dataToPlotExtrema(1); end;
	if groupwiseDataToPlotExtrema(2) < dataToPlotExtrema(2), groupwiseDataToPlotExtrema(2) = dataToPlotExtrema(2); end;
	
	if s.doPlotStacked
		set(figHandle, 'CurrentAxes', stackedHandles(g));
	end
	
	if ~s.doPlotBounds
		if length(s.COI)==1
			plot(t,squeeze(dataToPlot),'Color',groupAvgColors(g,:),'LineWidth',1.5);
		else
			set(gca,'Colororder',channelColors,'NextPlot','replacechildren');
			plot(t,squeeze(dataToPlot));
		end
	else
		if ischar(s.boundsMethod)
			switch(s.boundsMethod)
				case 'std'
					boundsFn = @(x,dim) std(x,0,dim);
				case 'stderr'
					boundsFn = @(x,dim) std(x,0,dim)./sqrt(size(x,dim));
				otherwise
					error('invalid');
			end
		else
			boundsFn = s.boundsMethod;
		end
		
		groupBounds = boundsFn(groupData,3);
		
		if length(s.COI)==1
			[hl(g), hp(g)] = c_boundedline(t,dataToPlot,groupBounds,'cmap',groupAvgColors(g,:),'nan','gap');
		else
			[hl(g,:), hp(g,:)] = c_boundedline(t,dataToPlot,permute(groupBounds,[2 3 1]),'cmap',channelColors,'nan','gap');
		end
		if ~isempty(s.lineWidth)
			set(hl,'LineWidth',s.lineWidth);
		end
		xlim('auto'); % this is for some reason necessary when plotting stacked with bounds, but not other cases
	end
	hold on;
end


if s.doPlotStacked
	% redo axis labels
	for g = 1:length(gi)
		ylabel(stackedHandles(g),'');
		set(stackedHandles(g),'XTick',[]);
		set(stackedHandles(g),'YTick',[]);
		ylabel(stackedHandles(g),'');
	end
	tmpY = nan(length(t),length(gi));
	c_plot_stacked(t,tmpY,'xlabel',s.xLabel,'ylabels',s.groupLabels,'existingHandles',stackedHandles);
end

if ~isempty(s.groupLabels) && length(s.COI)==1 && ~s.doPlotStacked
	if ~s.doClickableLegend
		legend(s.groupLabels,'location','southwest');
	else
		if ~s.doPlotBounds
			clickableLegend(s.groupLabels,'location','southwest');
		else
			% specify groups so that bounds and lines are enabled/disabled together
			clickableLegend([hl hp],s.groupLabels,'groups',[repmat(1:length(hl),1,2)]);
		end
	end
elseif length(s.COI)~=1 
	if ~isempty(s.dataLabels)
		labels = s.dataLabels;
		assert(length(s.dataLabels)==length(s.COI))
	else
		if ~isequal('data',s.data)
			% data isn't necessarily channel data
			labels = arrayfun(@num2str,s.COI,'UniformOutput',false);
		else
			labels = c_EEG_getChannelName(EEG,s.COI);
		end
	end
	if ~s.doClickableLegend
		legend(labels,'location','southwest');
	else
		if ~s.doPlotBounds
			clickableLegend(labels,'location','southwest');
		else
			% specify groups so that bounds and lines are enabled/disabled together
			clickableLegend([hl hp],labels,'groups',[repmat(1:length(hl),1,2)]);
		end
	end
	if length(labels) > 10
		legend('hide');
	end
end

if s.doSoftmaxLimits
	
	tmpData = s.reduceOperation(data(:,~indicesToIgnore,:),3);
	
	upperLim = prctile(tmpData,95)*3;
% 	upperLim = prctile(tmpData(tmpData>=0),90)*3;
	lowerLim= prctile(tmpData,5)*3;
% 	lowerLim= prctile(tmpData(tmpData<=0),10)*3;
	ylim([lowerLim, upperLim]);
else
	ylims = c_limits_multiply(groupwiseDataToPlotExtrema,1.1);
	ylim(ylims);
end

xlim([EEG.xmin EEG.xmax]*1e3);

if ~s.doPlotStacked
	xlabel(s.xLabel);
	ylabel(s.yLabel);
end

end
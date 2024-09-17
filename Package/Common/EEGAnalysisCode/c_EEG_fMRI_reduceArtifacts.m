function EEG = c_EEG_fMRI_reduceArtifacts(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('TREvent','R128',@ischar);
p.addParameter('TR',NaN,@isscalar); % TR in s. NaN = estimate from events
p.addParameter('doCheckForMissingTRs',true,@islogical);
p.addParameter('doCheckForSaturatedChannels',true,@islogical);
p.addParameter('doInterpolateSaturatedValues',false,@islogical);
p.addParameter('gradient_method','AMRI',@ischar); % gradient artifact correction method
p.addParameter('gradient_doExcludeNonEEGChannels',false,@islogical);
p.addParameter('gradient_AMRIArgs',{},@iscell);
p.addParameter('heartbeat_method','AMRI',@ischar); % heartbeat QRS detection method
p.addParameter('ecgChannelName','ECG',@ischar);
p.addParameter('bcg_method','FMRIB',@ischar); % ballistocardiogram artifact correction method
p.addParameter('bcg_doExcludeNonEEGChannels',false,@islogical);
p.addParameter('doPlot',true,@islogical);
p.addParameter('exemplaryChannel','Cz',@ischar);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

%% dependencies
persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/AMRI_EEGfMRI'));
	pathModified = true;
end

%% TR handling

TREventIndices = ismember({EEG.event.type},s.TREvent);
TREventTimeIndices = cell2mat({EEG.event(TREventIndices).latency});
TREventTimes = EEG.times(TREventTimeIndices);

estimatedTR = median(diff(TREventTimes));
if isnan(s.TR)
	c_saySingle('Estimated TR: %.4g ms',estimatedTR);
	s.TR = estimatedTR;
else
	if s.TR < 10
		% correctly specified in s, but now convert to ms
		s.TR = s.TR*1e3;
	else
		warning('TR is large. Assuming specified in ms rather than s');
		% don't change TR
	end
	c_saySingle('Specified TR: %.4g ms',s.TR);
	if s.TR ~= estimatedTR
		warning('Estimated TR (%.4g ms) does not match specified TR (%.4g ms)',estimatedTR, s.TR);
	end
end

if s.doCheckForMissingTRs
	trIntervals = diff(TREventTimes)/s.TR;
	if any(abs(mod(trIntervals+0.1,1)-0.1)>0.1) || any(trIntervals > 11)
		error('Something may be wrong with triggers');
	end
	trIntervals = round(trIntervals); % first assertion above makes sure this rounding is reasonable
	
	% fill in gaps that are multiples of TR time with synthetic TRs
	gapIndices = find(trIntervals>1);
	c_saySingle('Inserting %d missing TRs',sum(trIntervals(gapIndices)-1));
	newTRIndices = [];
	for i=length(gapIndices):-1:1
		startIndex = gapIndices(i);
		endIndex = startIndex+1;
		numToInsert = trIntervals(gapIndices(i))-1;
		% inserted TRs should be roughly TRtime apart, but just evenly distribute them across gap time
		newTimes = paren(linspace(TREventTimes(startIndex),TREventTimes(endIndex),numToInsert+2),2:numToInsert+1);
		TREventTimes = [TREventTimes(1:startIndex), newTimes, TREventTimes(endIndex:end)];
		newTRIndices = [newTRIndices, startIndex+(1:length(newTimes))];
	end
	if any(abs(diff(TREventTimes)-s.TR)>0.1*s.TR)
		error('Unexpected deviation in TR intervals between events');
	end
	
	if ~isempty(newTRIndices)
		% add these new TRs to events structure
		EEG = c_EEG_addEvents(EEG,'eventTimes',TREventTimes(newTRIndices)*1e-3,...
			'eventPositions',1,... 
			'eventDurations',1,...
			'eventTypes',s.TREvent);
	end
end
	
if s.doPlot
	numPlots = 2;

	figure('name',sprintf('%s TR timing',mfilename));
	
	c_subplot(1,numPlots);
	yvals = zeros(size(TREventTimes));
	yvals(2:end) = diff(TREventTimes);
	stem(TREventTimes/1e3,yvals);
	title('TR trigger times');
	ylabel('dt (ms)');
	xlabel('t (s)');

	tmp = c_EEG_epoch(EEG,'eventType',s.TREvent,'timespan',[-estimatedTR, estimatedTR]*1.1*1e-3);

	c_subplot(2,numPlots);
	c_EEG_plotEpochs(tmp,...
		'doPlotGMFA',true,...
		'COI',c_EEG_getChannelNamesOfType(EEG,'EEG'));
end

%% handle saturated channels
if s.doCheckForSaturatedChannels
	c_say('Checking for saturated channels');
	saturatedChannelNames = c_EEG_checkForSaturatedChannels(EEG,'doPlot',s.doPlot);
	if ~isempty(saturatedChannelNames)
		warning('%d saturated channels detected: %s',length(saturatedChannelNames),c_toString(saturatedChannelNames));
		if length(saturatedChannelNames) > 5
			%figure; plot(EEG.times/1e3,EEG.data(32,:),'.-'); xlim(20+[0,4]); xlabel('Time (s)'); ylabel('Amplitude (uV)');
			%figure; plot(EEG.times/1e3,EEG.data(5,:),'.-'); xlim(20+[0,4]); xlabel('Time (s)'); ylabel('Amplitude (uV)');
			keyboard
		end
		%warning('returning early');
		%return; %TODO: debug, delete
	else
		c_saySingle('No saturated channels detected');
	end
	c_sayDone();
end

if s.doInterpolateSaturatedValues
	c_say('Interpolating any saturated values');
	tmp = c_EEG_interpolateSaturatedValues(EEG);
	%figure; plot(EEG.data(32,:),'.-'); hold on; plot(tmp.data(32,:),'o-'); xlim(1e6+[0,0.5e3])
	EEG = tmp;
	c_sayDone();
end

%% gradient artifact reduction

if s.doPlot
	EEGBeforeGradient = EEG;
end

c_say('Running %s gradient correction',s.gradient_method);
switch s.gradient_method
	case 'FMRIB'
		EEG = c_EEG_fMRI_FASTR(EEG,...
			'TREvent',s.TREvent,...
			'doExcludeNonEEGChannels',s.gradient_doExcludeNonEEGChannels);
	case 'AMRI'
		EEG = amri_eeg_gac(EEG,...
			'method','PCA',...
			'correctby','volume',...
			'winsize',2,...
			'trigger.name',s.TREvent,...
			'trigger.type','volume',...
			'fmri.tr',s.TR/1e3,... % in s
			'downsample',EEG.srate,...
			'verbose',1,... %TODO: debug, delete
			s.gradient_AMRIArgs{:});
	case 'loadPrevious' %TODO: debug, delete this case
		warning('loading previous results');
		load('todelete-AG-EEG1.mat');
	case 'none'
		% do nothing
	otherwise
		error('Invalid method: %s',s.gradient_method);
end
c_sayDone()

% c_save('todelete-AG-EEG1.mat','EEG'); %TODO: debug, delete

if s.doPlot
	figure('name',sprintf('%s Before and after gradient artifact reduction',mfilename));
	tmp = c_EEG_epoch(EEG,'eventType',s.TREvent,'timespan',[-estimatedTR, estimatedTR]*1.1*1e-3);
	c_EEG_plotEpochs(tmp,...
		'doPlotGMFA',true,...
		'COI',c_EEG_getChannelNamesOfType(EEG,'EEG'));
	
	c_EEG_plotRawComparison({EEGBeforeGradient,EEG},'descriptors',{'Before','After'});
end

keyboard

%% heartbeat detection

s.ecgChannelIndex = c_EEG_getChannelIndex(EEG,s.ecgChannelName);

QRSEventType = '';

ECG = pop_select(EEG,'channel',{s.ecgChannelName}); % pull out ECG channel only

c_say('Running %s heartbeat detection',s.heartbeat_method);
switch s.heartbeat_method
	case 'FMRIB'
		QRSEventType = 'R';
		EEG = pop_fmrib_qrsdetect(EEG,s.ecgChannelIndex,QRSEventType,'yes');
	case 'AMRI'
		EEG = amri_eeg_rpeak(EEG,ECG,...
			'PulseRate',[40 120]); 
		QRSEventType = 'R'; % hardcoded inside amri_eeg_rpeak
	case 'loadPrevious' %TODO: debug, delete this case
		warning('loading previous results');
		load('todelete-AG-EEG2.mat');
	otherwise
		error('Invalid method: %s',s.heartbeat_method)
end
c_sayDone();

% save('todelete-AG-EEG2.mat','EEG','QRSEventType'); %TODO: debug, delete

if s.doPlot
	% copy QRS events from EEG struct (which potentially doesn't have ECG trace) to ECG struct, which only has ECG trace
	QRSEvents = EEG.event(ismember({EEG.event.type},QRSEventType));
	labeledECG = c_EEG_addEvents(ECG,'events',QRSEvents); 
	
	epochedECG = c_EEG_epoch(labeledECG,...
		'eventType',QRSEventType,...
		'timespan',[-1 1]);
	
	% plot average QRS 
	figure('name',sprintf('%s Heartbeat detection',mfilename));
	c_EEG_plotEpochs(epochedECG);
	
	% plot raw ECG
	pop_eegplot(epochedECG,1,0,0);
end

keyboard

%% BCG artifact reduction

assert(~isempty(QRSEventType));

if s.doPlot
	EEGBeforeBCG = EEG;
end

c_say('Running %s BCG correction',s.bcg_method);
switch s.bcg_method
	case 'FMRIB'
		keyboard %TODO
	case 'AMRI'
		EEG = amri_eeg_cbc(EEG,ECG,...
			'method','ICA-PCA',...
			'rmarkername',QRSEventType);
	otherwise
		error('Invalid method: %s',s.bcg_method);
end
c_sayDone();


if s.doPlot
	figure('name',sprintf('%s Before and after gradient artifact reduction',mfilename));
	tmp = c_EEG_epoch(EEG,'eventType',s.TREvent,'timespan',[-estimatedTR, estimatedTR]*1.1*1e-3);
	c_EEG_plotEpochs(tmp,...
		'doPlotGMFA',true,...
		'COI',c_EEG_getChannelNamesOfType(EEG,'EEG'));
	
	c_EEG_plotRawComparison({EEGBeforeBCG,EEG},'descriptors',{'Before','After'});
end

keyboard


end

function EEG = c_EEG_fMRI_FASTR(varargin)
% wrapper around FMRIB fastr function for gradient artifact reduction
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('LowPassFilterCutoff',70,@isscalar);
p.addParameter('NumInterpolationFolds','auto',@isscalar);
p.addParameter('NumArtifactsToAverage',30,@isscalar);
p.addParameter('TREvent','',@ischar);
p.addParameter('doExcludeNonEEGChannels',false,@islogical);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

if strcmpi(s.NumInterpolationFolds,'auto')
	s.NumInterpolationFolds = ceil(20e3/EEG.srate);
end

if s.doExcludeNonEEGChannels
	excludeChannels = c_EEG_getChannelIndex(EEG,...
		c_EEG_getChannelNamesOfType(EEG,'notType','EEG'));
else
	excludeChannels = [];
end

if isempty(s.TREvent)
	error('Must specify ''TREvent''');
end

EEG = pop_fmrib_fastr(EEG,...
	s.LowPassFilterCutoff,... % low pass filter cutoff, in Hz (default []=70)
	s.NumInterpolationFolds,... % number of interpolation folds ("recommended" upsampling to about 20 kHz)
	s.NumArtifactsToAverage,... % number of artifacts in avg. window (default []=30)
	s.TREvent,...
	0,... % artifact-timing event type (0 = volume triggers, 1 = slice triggers)
	0,... % do adaptive noise cancellation (0 = no, 1 = yes)
	0,....% do correct for missing triggers (0 = no, 1 = yes)
	[],... % fMRI volumes (only needed if correcting for missing triggers)
	[],... % fMRI slices (only needed if correcting for missing triggers)
	[],... % relative location of slice triggers to actual start of slice
	excludeChannels,... % channels to exclude from residual artifact PC fitting
	'auto'... % num principal components to fit to noise residuals
);

end
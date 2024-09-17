function EEG = c_EEG_modifyEvents(varargin)
%% Delete old events and insert new ones, for given event types
% (for use, for example, after offline simulation of new cursor trajectories, to embed new cursor positions in EEG.events)
% Note: does not modify the underlying EEG.urevent structure by default.

%TODO: modify to also change durations of TargetCode events

p = inputParser;
p.addRequired('EEG',@isstruct);
p.addParameter('cursorPositions',[],@isnumeric); % input as continuous positions, will be reduced into events on changes only
p.addParameter('cursorPositionTimes',[],@isnumeric); % in s
p.addParameter('trialOutcomes',[],@isnumeric);
p.addParameter('trialDurations',[],@isnumeric); % in s
p.addParameter('feedbackStartTimes',[],@isnumeric); % in s
p.addParameter('doModifyUrevent',false,@islogical);
p.addParameter('dt',40e-3,@isscalar); % in s
p.parse(varargin{:});

EEG = p.Results.EEG;

if p.Results.doModifyUrevent
	error('Modification of EEG.urevent struct not yet implemented');
	%TODO: add support below for modifying EEG.urevent to match EEG.event and updating indices
end

newEvents = EEG.event;

if ~isempty(p.Results.feedbackStartTimes)
	feedbackStartTimes = p.Results.feedbackStartTimes;
elseif ~isempty(p.Results.cursorPositionTimes)
	feedbackStartTimes = p.Results.cursorPositionTimes(:,1)' - p.Results.dt;
else
	error('No trial start times available');
end

if ~isempty(p.Results.trialDurations)
	trialDurations = p.Results.trialDurations;
	if size(trialDurations) ~= size(feedbackStartTimes)
		error('size mismatch between trialDurations and feedbackStartTimes');
	end
else
	warning('No trial duration information. Setting feedback durations to 0');
	trialDurations = zeros(size(feedbackStartTimes));
end

%% cursor positions
if ~isempty(p.Results.cursorPositions)
	if isempty(p.Results.cursorPositionTimes)
		error('cursorPositions and cursorPositionsTimes must be specified together.');
	end
	
	eventTypeLabels = {'CursorPosX','CursorPosY','CursorPosZ'};
	if length(eventTypeLabels) ~= size(p.Results.cursorPositions,2) 
		error('Unexpected size of cursorPositions');
	end
	
	% remove any existing events, which will be replaced
	newEvents = deleteEvents(newEvents, eventTypeLabels);
	
	% flatten cursorPositions (separated into epochs) into single time sequence
	cursorPositionTimes = reshape(p.Results.cursorPositionTimes',1,[]);
	cursorPositions = reshape(permute(p.Results.cursorPositions,[2 3 1]),size(p.Results.cursorPositions,2),[]);
	
	% remove NaNs in sequence
	indicesToRemove = all(isnan(cursorPositions),1);
	cursorPositions(:,indicesToRemove) = [];
	cursorPositionTimes(indicesToRemove) = [];
	
	% create new events for changes in cursor position
	for i=1:length(eventTypeLabels) % for x,y,z
		changes = [NaN diff(cursorPositions(i,:))];
		changeIndices = find(changes~=0 & ~isnan(cursorPositions(i,:)));
		changePositions = cursorPositions(i,changeIndices);
		changeTimes = cursorPositionTimes(changeIndices);
		changeUrevents = NaN(size(changeIndices)); %TODO: overwrite later to actually match up to a urevent (if modifying ur events at all)
		changeDurations = [diff(changeTimes) (cursorPositionTimes(end) - changeTimes(end))];
		for j=1:length(changeTimes) % for each new event
			newEvent = struct(...
				'latency',changeTimes(j)*1e3,...
				'position',changePositions(j),...
				'duration',changeDurations(j)*1e3,...
				'type',eventTypeLabels{i},...
				'urevent',changeUrevents(j));
			newEvents(end+1) = newEvent;
		end
	end
end

%% feedback events
if ~isempty(feedbackStartTimes)
	
	newEvents = deleteEvents(newEvents,{'Feedback'});
	
	for j=1:length(feedbackStartTimes)
		newEvent = struct(...
			'latency',feedbackStartTimes(j)*1e3,...
			'position',1,...
			'duration',trialDurations(j)*1e3,...
			'type','Feedback',...
			'urevent',0);
		newEvents(end+1) = newEvent;
	end
end

%% result code
if ~isempty(p.Results.trialOutcomes)
	
	previousResultEventIndices = find(ismember({EEG.event.type},'ResultCode'));
	if ~isempty(previousResultEventIndices)
		assumedResultDuration = EEG.event(previousResultEventIndices(1)).duration;
	else
		assumedResultDuration = 0;
	end
	
	newEvents = deleteEvents(newEvents,{'ResultCode'});
	
	for j=1:length(p.Results.trialOutcomes)
		if ~isnan(p.Results.trialOutcomes(j))
			newEvent = struct(...
				'latency',(feedbackStartTimes(j) + trialDurations(j))*1e3,...
				'position',p.Results.trialOutcomes(j),...
				'duration',assumedResultDuration*1e3,...
				'type','ResultCode',...
				'urevent',0);
			newEvents(end+1) = newEvent;
		end
	end
end

%% target code
targetEventIndices = find(ismember({EEG.event.type},'TargetCode'));
feedbackEventIndices = find(ismember({EEG.event.type},'Feedback'));
addedDurationBeforeFeedback = EEG.event(targetEventIndices(1)).duration - EEG.event(feedbackEventIndices(1)).duration;

targetEventIndices = find(ismember({newEvents.type},'TargetCode'));
for j=1:length(targetEventIndices)
	newEvents(targetEventIndices(j)).duration = trialDurations(j)*1e3 + addedDurationBeforeFeedback;
end


%% re-sort events by latency
eventLatencies = cell2mat({newEvents.latency});
[~,i] = sort(eventLatencies,'ascend');
newEvents = newEvents(i);

EEG.event = newEvents;

end

function events = deleteEvents(events,eventTypesToRemove)
	eventTypes = {events.type};
	indicesToRemove = ismember(eventTypes,eventTypesToRemove);
	events = events(~indicesToRemove);
end



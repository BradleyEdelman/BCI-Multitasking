function EEG = c_EEG_addEvents(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('events',struct(),@isstruct); 
p.addParameter('eventLatencies',[],@c_isinteger); % in indices (assume non fractional indices, though could remove this restriction)
p.addParameter('eventPositions',[],@isnumeric);
p.addParameter('eventTimes',[],@isnumeric); % in s
p.addParameter('eventDurations',[],@c_isinteger); % in indices
p.addParameter('eventTypes','',@(x) ischar(x) || iscellstr(x));
p.addParameter('eventUrevents',[],@isempty); % should not actually be specified, just here for consistent structure with other fields
%TODO: add a 'ureventLatencies' option to specify original (e.g. non-epoched) event latency separate from epoched event latency
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

if ischar(s.eventTypes)
	s.eventTypes = {s.eventTypes};
end

inputFields = {'eventLatencies','eventPositions','eventTimes','eventDurations','eventTypes','eventUrevents'};
mapToOutputFields = {'latency','position','','duration','type','urevent'};
assert(length(inputFields)==length(mapToOutputFields));

structFields = mapToOutputFields(~cellfun(@isempty,mapToOutputFields))';

if ~c_isEmptyStruct(s.events)
	% events specified
	if any(~ismember(inputFields,p.UsingDefaults))
		error('If specifying ''events'' struct, should not specify any individual event fields separately');
	end
	if ~isequal(sort(structFields),sort(fieldnames(s.events)))
		error('Missing fields in specified ''events'' struct');
	end
else
	% construct events from individual fields
	lengths = cellfun(@(x) length(s.(x)), inputFields);
	
	numEvents = max(lengths);
	
	if numEvents == 0
		% no events specified
		warning('No events to add');
		% return EEG unmodified
		return;
	end
	
	assert(all(lengths==0 | lengths==1 | lengths==numEvents)); 
	
	indicesToRep = find(lengths==1);
	for iF = indicesToRep
		s.(inputFields{iF}) = repmat(s.(inputFields{iF}),1,numEvents);
	end
	
	if ~isempty(s.eventLatencies) && ~isempty(s.eventTimes)
		error('Should not specify both eventLatencies and eventTimes')
	elseif ~isempty(s.eventTimes)
		% convert times to latencies
		s.eventLatencies = round(s.eventTimes * EEG.srate);
		s.eventTimes = [];
	end
	
	args = cell(1,length(structFields)*2);
	args(1:2:end) = structFields;
	args(2:2:end) = {repmat({},1,length(structFields))};
	s.events = struct(args{:});
	
	for iE = 1:numEvents
		newEvent = struct();
		for iF = 1:length(inputFields)
			if isempty(mapToOutputFields{iF})
				continue; % skip
			end
			if isempty(s.(inputFields{iF}))
				val = NaN;
			else
				val = s.(inputFields{iF})(iE);
			end
			if iscell(val) && length(val)==1
				val = val{1};
			end
			newEvent.(mapToOutputFields{iF}) = val;
		end
		s.events(iE) = newEvent;
	end
end

if ~c_isEmptyStruct(EEG.event) && ~isequal(sort(structFields),sort(fieldnames(EEG.event)))
	error('Fieldnames are not as expected in EEG.event');
end

% make sure that new events are sorted by latency
s.events = c_struct_sortByField(s.events,'latency');

% insert events into existing EEG struct, sorting by latency
numEvents = length(s.events);
EEG.urevent = [EEG.urevent, rmfield(s.events,'urevent')];
for iE = 1:numEvents
	% note that this overwrites any previously specified urevent values
	s.events(iE).urevent = length(EEG.event) + iE;
end
iOE = 1;
for iE = 1:length(s.events) % assumes events are ordered by increased latency
	while iOE <= length(EEG.event) && EEG.event(iOE).latency < s.events(iE).latency
		iOE = iOE + 1;
	end
	EEG.event = [EEG.event(1:iOE-1), s.events(iE), EEG.event(iOE:end)];
	iOE = iOE + 1;
end

end

function EEG = c_EEG_convertTriggerChToEvents(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('TriggerChannel','T',@ischar);
p.addParameter('NumBits',16,@isscalar);
p.parse(varargin{:});
s = p.Results;
EEG = p.Results.EEG;

iCh = c_EEG_getChannelIndex(EEG,s.TriggerChannel);
if iCh == 0
	error('Specified trigger channel ''%s'' not in EEG',s.TriggerChannel);
end

if c_EEG_isEpoched(EEG)
	error('Fn does not support working with epoched data.');
end

trigData = EEG.data(iCh,:);

% all values should be integers
if ~all(ceil(trigData)==trigData)
	error('Trigger values are not integers. Was data already rereferenced or filtered? This could corrupt trigger info and data.');
end

% BCI2000 trigger data (at least from RDAClient) seems to have opposite endianness than assumed by matlab
% so swap byte order here
assert(s.NumBits==16);
trigData = swapbytes(uint16(trigData));

% look for nonzero values in trigger channel
if trigData(1) ~= 0 % treat the first point as a non-trigger baseline
	error('Trigger channel baseline is not zero. Was data already rereferenced or filtered? This could corrupt trigger info and data.');
	% if data without triggers is not zero, channel may have been (incorrectly) rereferenced or filtered
end

if all(trigData==0)
	warning('No triggers (nonzero values) in trigger channel data');
else
	% convert changes in trigger values to events
	diffTrigData = diff(double(trigData));
	candidateIndices = find(diffTrigData~=0)+1;
	
	%TODO: test that this code works well for nested/overlapping triggers with different values
	% (it was only tested with single-trigger-value data)
	events = struct('latency',{},'position',{},'duration',{},'type',{},'urevent',{});
	pendingEvents = struct('latency',{},'position',{},'duration',{},'type',{},'urevent',{});
	for iE = 1:length(candidateIndices)
		trigBefore =	dec2bin(trigData(candidateIndices(iE)-1),	s.NumBits);
		trigAfter =		dec2bin(trigData(candidateIndices(iE)),	s.NumBits);
		assert(~isequal(trigBefore,trigAfter));
		evtVal = find(trigBefore ~= trigAfter);
		assert(length(evtVal)==1); %TODO: add support for multiple simultaneous events
		if trigBefore(evtVal)=='0' && trigAfter(evtVal)=='1'
			% this was the start of an event
			pendingEvents(end+1) = struct(...
				'latency',candidateIndices(iE),...
				'position',1,...
				'duration',inf,... % we don't know duration until we find end of the event
				'type',['R', num2str(2^(s.NumBits-evtVal))],...
				'urevent',NaN... % will be determined when we insert into event list
			);
		elseif trigBefore(evtVal)=='1' && trigAfter(evtVal)=='0'
			% this was the end of an event
			matchFound = false;
			newType = ['R', num2str(2^(s.NumBits-evtVal))];
			for iPE = length(pendingEvents):-1:1
				if isequal(newType,pendingEvents(iPE).type)
					matchFound = true;
					break;
				end
			end
			if ~matchFound
				error('No matching start of event found');
			end
			pendingEvents(iPE).duration = candidateIndices(iE) - pendingEvents(iPE).latency;
			events(end+1) = pendingEvents(iPE);
			pendingEvents(iPE) = [];
		else
			error('Problem with trigger value conversion');
		end
	end
	assert(isempty(pendingEvents)); %TODO: handle events that did not end
	
	% merge new events and original EEG events
	EEG.urevent = [EEG.urevent, rmfield(events,'urevent')];
	for iE = 1:length(events)
		events(iE).urevent = length(EEG.event) + iE;
	end
	iOE = 1;
	for iE = 1:length(events) % assumes events are ordered by increasing latency
		while iOE <= length(EEG.event) && EEG.event(iOE).latency < events(iE).latency 
			iOE = iOE + 1;
		end
		EEG.event = [EEG.event(1:iOE-1), events(iE), EEG.event(iOE:end)];
		iOE = iOE + 1;
	end
end
	
EEG = c_EEG_removeChannel(EEG,s.TriggerChannel);

end
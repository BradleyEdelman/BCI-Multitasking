function EEG = c_EEG_setEventDateTimes(varargin)
% adds a 'datetime' field to each event with absolute time (year/month/day/hour/minute/second) info
% (only supported for some EEG formats)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('method','BVTime',@ischar);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

if ~c_EEG_isEpoched(EEG)
	error('EEG should be epoched');
	%TODO: add support for on-the-fly epoching (without full manipulation of data) here
	% (similar to as in c_EEG_epoch_getOriginalEventTimes() )
end

switch(lower(s.method))
	case 'bvtime'
		% get absolute time from Brain Vision boundary events' bvtime fields
		
		% make sure that bvtime field is available and in useful format
		% assume first urevent in each file is boundary event
		evt = EEG.urevent(1);
		if ~strcmpi(evt.type,'boundary')
			error('Expected first event to be of type boundary (for BrainVision files)');
		end
		if ~c_isFieldAndNonEmpty(evt,'bvtime')
			error('Expected ''bvtime'' field in event');
		end
		if isscalar(evt.bvtime)
			error('bvtime not in useful format. Need to modify EEGLab parsbvmrk function to correctly read bvtime field');
			if 0
				% changes to make in parsebvmrk function to fix parsing of bvtime:
				% modify token string to change last field from int to string
				[mrkType mrkDesc EVENT(idx).latency EVENT(idx).duration  EVENT(idx).channel EVENT(idx).bvtime] = ...
					strread(MRK.markerinfos{idx, 1}, '%s%s%f%d%d%s', 'delimiter', ',');

				% add conversion from cell to string
				if iscell(EVENT(idx).bvtime) && length(EVENT(idx).bvtime)==1
					EVENT(idx).bvtime = EVENT(idx).bvtime{1};
				end
			end
		end
		
		boundaryEventIndices = ismember({EEG.event.type},{'boundary'});
		if sum(boundaryEventIndices) > 1
			%TODO: handle reseting of time at later boundary events
		else
			% single boundary event at very beginning
			startTime = bvtimeStrToDate(evt.bvtime);
			for iE = 1:length(EEG.urevent)
				timeOffset = (EEG.urevent(iE).latency - EEG.urevent(1).latency)/EEG.srate;
				EEG.urevent(iE).datetime = startTime + seconds(timeOffset);
			end
			for iE = 1:length(EEG.event)
				if ~isempty(EEG.event(iE).urevent)
					EEG.event(iE).datetime = EEG.urevent(EEG.event(iE).urevent).datetime;
				end
			end
		end
		
	otherwise
		error('Invalid method: %s',s.method);
end

end

function dateTime = bvtimeStrToDate(str)
	format = 'yyyyMMddHHmmssSSSSSS';
	%TODO: confirm whether last digits are actually fractional seconds vs something else
	dateTime = datetime(str,'InputFormat',format);
end
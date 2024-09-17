function EEG = c_EEG_ReplaceEpochTimeSegment(varargin)
	if nargin == 0
		testfn();
		return;
	end

	p = inputParser();
	p.addRequired('EEG',@isstruct);
	p.addParameter('timespanToReplace',[],@(x) isnumeric(x) && length(x)==2); % in s
	p.addParameter('eventType','',@ischar);
	p.addParameter('method','spline',@(x) ischar(x) || isscalar(x)); % if scalar, will be used as a constant to replace values
	p.parse(varargin{:});
	
	EEG = p.Results.EEG;
	
	if isempty(p.Results.timespanToReplace)
		error('Need to specify timespanToReplace');
	end

	if c_EEG_isEpoched(EEG)
		if ~isempty(p.Results.eventType)
			error('Event type shouldn''t be specified if data is already epoched');
		end
	
		indicesToReplace = EEG.times > p.Results.timespanToReplace(1)*1e3 & EEG.times < p.Results.timespanToReplace(2)*1e3;
		
		if strcmp(p.Results.method,'delete')
			% don't actually interpolate, but instead delete data entirely, and fix time and other metadata
			EEG.data(:,indicesToReplace,:) = [];
			EEG.times(indicesToReplace) = [];
			EEG.pnts = length(EEG.times);
		else
			for i=1:EEG.trials
				EEG.data(:,:,i) = interpolateWithinIndices(EEG.data(:,:,i),indicesToReplace,p.Results.method);
			end
		end
	else
		if isempty(p.Results.eventType)
			error('Event type must be specified if data is not epoched');
		end
		
		if strcmp(p.Results.method,'delete')
			error('Delete not supported for continuous data');
			%TODO: implement
		end
		
		t = c_EEG_epoch_getOriginalEventTimes(EEG,'eventType', p.Results.eventType);
		
		indicesToReplace = false(1,length(EEG.times));
		
		for i=1:length(t)
			tstart = (t(i)+p.Results.timespanToReplace(1))*1e3;
			tend = (t(i)+p.Results.timespanToReplace(2))*1e3;
			indicesToReplace(EEG.times > tstart & EEG.times < tend) = true;
		end
		
		EEG.data = interpolateWithinIndices(EEG.data,indicesToReplace,p.Results.method);
	end
end


function data = interpolateWithinIndices(data,indices,method)

	if nargin < 3
		method = 'spline';
	end
	
	assert(length(indices)==size(data,2));
	assert(length(size(data))==2) % code below assumes data is [nchan x ntime]	
	assert(islogical(indices)); % code below assumes logical indexing
	
	if strcmp(method,'zero')
		method = 0; % convert string to num for below
	end

	times = 1:size(data,2); % arbitrary units
	knownTimes = times(~indices);
	unknownTimes = times(indices);

	if ischar(method)
	% 	for i=1:size(data,1)
	% 		data(i,indices) = interp1(knownTimes,data(i,~indices),unknownTimes,method);
	% 	end
		data(:,indices) = interp1(knownTimes,data(:,~indices).',unknownTimes,method).';
	elseif isscalar(method)
		% method is actually a constant scalar to use to replace all unknown values
		data(:,indices) = method;
	else
		error('Invalid method');
	end
end

function testfn()
	t = linspace(0,10,1000);
	x(1,:) = sin(2*t);
	x(2,:) = cos(3*t);
	x(3,:) = cumsum(randn(1,length(t)));
	x(3,:) = x(3,:) / max(abs(x(3,:)));
	
	indicesToReplace = t>4 & t<6;
	
	figure;
	c_subplot(2,1,1);
	plot(t,x);
	
	c_subplot(2,1,2);
	y = interpolateWithinIndices(x,indicesToReplace,'spline');
	
	plot(t,y);
end
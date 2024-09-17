function EEG = c_EEG_interpolateSaturatedValues(varargin)
if nargin==0, testfn(); return; end;
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('interpolationMethod','spline',@ischar);
p.addParameter('doInsertPoints',true,@islogical);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

channelIndices = 1:EEG.nbchan; %TODO: make parameter to allow only a subset of channels

assert(ndims(EEG.data)==2); % epoched data not currently supported

% specify possible saturated values to avoid marking intermediate (non-saturated) extrema values as saturated when a channel never saturates
possibleSaturatedValues = [16383.5,-16383.5]; %TODO: add values for other gains and other eeg systems

% each channel might have a different gain, and therefore a different saturated value

prog = c_progress(length(channelIndices),'Processing channel %d/%d');
EEGdata = EEG.data;
% parfor c = channelIndices
for c = channelIndices
	prog.update(c);
	tmp = ismember(possibleSaturatedValues,extrema(EEGdata(c,:)));
	channelDidSaturate = any(tmp);
	if ~channelDidSaturate
		continue;
	end
	
	relevantExtrema = extrema(EEGdata(c,:),[],2);
	negExtrema = relevantExtrema(1);
	posExtrema = relevantExtrema(2);

	negTimeIndicesToReplace = ismember(EEGdata(c,:),negExtrema);
	posTimeIndicesToReplace = ismember(EEGdata(c,:),posExtrema);
	
	if s.doInsertPoints
		EEGdata(c,:) = interpolateAssumingSaturatedWithinIndices(...
			EEGdata(c,:),negTimeIndicesToReplace,posTimeIndicesToReplace,s.interpolationMethod);
	else
		EEGdata(c,:) = interpolateWithinIndices(...
			EEGdata(c,:),negTimeIndicesToReplace | posTimeIndicesToReplace,s.interpolationMethod);
	end
end
EEG.data = EEGdata;
prog.stop();

end

function data = interpolateWithinIndices(data,indices,method)

	if nargin < 3
		method = 'spline';
	end
	
	assert(length(indices)==size(data,2));
	assert(length(size(data))==2) % code below assumes data is [nchan x ntime]	
	assert(islogical(indices)); % code below assumes logical indexing

	times = 1:size(data,2); % arbitrary units
	knownTimes = times(~indices);
	unknownTimes = times(indices);

% 	for i=1:size(data,1)
% 		data(i,indices) = interp1(knownTimes,data(i,~indices),unknownTimes,method);
% 	end
	data(:,indices) = interp1(knownTimes,data(:,~indices).',unknownTimes,method).';
end

function data = interpolateAssumingSaturatedWithinIndices(data,negIndices,posIndices,method)
	if nargin < 4
		method = 'spline';
	end
	
	indicesByType = {negIndices, posIndices};
	
	indices = c_or(indicesByType{:});
	
	assert(length(size(data))==2) % code below assumes data is [nchan x ntime]	
	for iT = 1:length(indicesByType)
		assert(length(indicesByType{iT})==size(data,2));
		assert(islogical(indicesByType{iT})); % code below assumes logical indexing
	end
	
	times = 1:size(data,2); % arbitrary units
	dt = 1;
	
	% insert points at saturated extremes halfway between neighboring known and unknown samples to force 
	%  values to always be beyond or equal to saturated value
	startInterpRegionIndices = false(size(indices));
	endInterpRegionIndices = false(size(indices));
	for iT = 1:length(indicesByType)
		startInterpRegionIndices = startInterpRegionIndices | [false, ~indicesByType{iT}(1:end-1) & indicesByType{iT}(2:end)];
		endInterpRegionIndices = endInterpRegionIndices | [indicesByType{iT}(1:end-1) & ~indicesByType{iT}(2:end), false];
	end
	startInterpRegionIndices = find(startInterpRegionIndices);
	endInterpRegionIndices = find(endInterpRegionIndices);
	
	assert(length(startInterpRegionIndices)==length(endInterpRegionIndices));
	
	numRegions = length(startInterpRegionIndices);
% 	prog = c_progress(numRegions,'Inserting boundary values for region %d/%d',...
% 		'waitToPrint',5);
	newTimes = nan(1,length(times)+numRegions*2);
	newIndices = false(1,length(indices)+numRegions*2);
	newData = nan(size(data,1),size(data,2)+numRegions*2);
	
	insertedIndices = reshape([startInterpRegionIndices; endInterpRegionIndices+1],1,[]);
	insertedIndices = insertedIndices + (1:length(insertedIndices)) - 1;
	insertedValues = nan(size(data,1),length(insertedIndices));
	insertedValues(:,1:2:end) = data(:,startInterpRegionIndices);
	insertedValues(:,2:2:end) = data(:,startInterpRegionIndices);
	insertedTimes = nan(1,length(insertedIndices));
	insertedTimes(1:2:end) = (times(startInterpRegionIndices-1) + times(startInterpRegionIndices))/2;
	insertedTimes(2:2:end) =(times(endInterpRegionIndices) + times(endInterpRegionIndices+1))/2;
	
	% repeat times occur when switching between full pos saturation to full neg saturation and vice versa
	% adjust these times slightly so they are not the same
	repeatTimeIndices = find([insertedTimes(1:end-1)==insertedTimes(2:end),false]);
	insertedTimes(repeatTimeIndices) = insertedTimes(repeatTimeIndices) - dt/6;
	insertedTimes(repeatTimeIndices+1) = insertedTimes(repeatTimeIndices+1) + dt/6;
	
% 	assert(isequal(sort(insertedIndices),insertedIndices)); %TODO: debug, remove b/c computationally expensive
	
	indicesFromOrig = 1:length(times);
	mapToIndices = indicesFromOrig;
	
	for iI = 1:numRegions
% 		prog.update();
		if iI == 1, startIndex = 1;
		else
			startIndex = endInterpRegionIndices(iI-1)+1;
		end
		indicesSubset = startIndex:startInterpRegionIndices(iI)-1;
		mapToIndices(indicesSubset) = mapToIndices(indicesSubset) + iI*2-2;
		indicesSubset = startInterpRegionIndices(iI):endInterpRegionIndices(iI);
		mapToIndices(indicesSubset) = mapToIndices(indicesSubset) + iI*2-1;
	end
	indicesSubset = endInterpRegionIndices(end)+1:length(mapToIndices);
	mapToIndices(indicesSubset) = mapToIndices(indicesSubset) + numRegions*2;
		
	% unmodified points
	newTimes(mapToIndices) = times(indicesFromOrig);
	newIndices(mapToIndices) = indices(indicesFromOrig);
	newData(:,mapToIndices) = data(:,indicesFromOrig);
	
	% inserted points
	newTimes(insertedIndices) = insertedTimes;
	newIndices(insertedIndices) = false;
	newData(:,insertedIndices) = insertedValues;
	
% 	prog.stop();

	knownTimes = newTimes(~newIndices);
	knownValues = newData(:,~newIndices).';
	unknownTimes = newTimes(newIndices);

% 	c_say('Interpolating');
	data(:,indices) = interp1(knownTimes,knownValues,unknownTimes,method).';
% 	c_sayDone();
	
end
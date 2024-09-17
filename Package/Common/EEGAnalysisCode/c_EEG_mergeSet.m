function EEG = c_EEG_mergeSet(varargin)
p = inputParser();
p.addRequired('EEGs',@iscell);
p.addParameter('doHandleAuxData',true,@islogical);
p.addParameter('doMergeEpochGroups',true,@islogical);
p.addParameter('doAddEpochGroups',true,@islogical);
p.addParameter('datasetLabels',{},@iscellstr);
p.addParameter('doSilenceEEGLab',true,@islogical);
p.addParameter('fieldsToClear',{'filename','filepath','datfile'},@iscellstr);
p.parse(varargin{:});
s = p.Results;
EEGs = p.Results.EEGs;

numDatasets = length(EEGs);
for i=1:numDatasets
	assert(isstruct(EEGs{i})); % each element should be an EEG struct
end

if ~isempty(s.datasetLabels)
	assert(length(s.datasetLabels)==numDatasets);
end

if s.doHandleAuxData
	didHaveAuxData = false(1,numDatasets);
	for i=1:numDatasets
		if c_EEG_hasAuxData(EEGs{i})
			EEGs{i} = c_EEG_mergeAuxData(EEGs{i});
			didHaveAuxData(i) = true;
		end
	end
	assert(all(didHaveAuxData) || all(~didHaveAuxData)); % require that all datasets either have or don't have aux data
	%TODO: add code to drop aux data if only some datasets have it
	didHaveAuxData = didHaveAuxData(1);
end

if numDatasets > 1
	tmp = c_cellArrayToArray(EEGs,'doDiscardUncommonFields',false);
	
	fn = @() pop_mergeset(tmp,1:length(EEGs));
	if ~s.doSilenceEEGLab
		EEG = fn();
	else
		[~,EEG] = evalc('fn();');
	end
else
	EEG = EEGs{1};
end

if s.doHandleAuxData && didHaveAuxData
	EEG = c_EEG_splitAuxData(EEG);
end

if s.doMergeEpochGroups
	% merge epoch groups from individual datasets into combined dataset
	% (make combined epoch groups logical, regardless of whether they were logical or numeric previously)
	EEG.epochGroups = {};
	EEG.epochGroupLabels = {};
	
	numEpochsInDataset = nan(1,numDatasets);
	for i = 1:numDatasets
		numEpochsInDataset(i) = EEGs{i}.trials;
	end
	assert(sum(numEpochsInDataset)==EEG.trials);
	
	for i = 1:numDatasets
		if ~c_isFieldAndNonEmpty(EEGs{i},'epochGroupLabels')
			continue;
		end
		assert(length(EEGs{i}.epochGroupLabels)==length(EEGs{i}.epochGroups));
		for iG = 1:length(EEGs{i}.epochGroupLabels)
			label = EEGs{i}.epochGroupLabels{iG};
			jG = find(ismember(EEG.epochGroupLabels,label),1);
			if isempty(jG)
				% group not yet listed
				jG = length(EEG.epochGroupLabels)+1;
				EEG.epochGroupLabels{jG} = label;
				EEG.epochGroups{jG} = false(1,EEG.trials);
			end
			localIndices = EEGs{i}.epochGroups{iG};
			if ~islogical(localIndices)
				% convert from numeric indexing to logical
				tmp = localIndices;
				localIndices = false(1,numEpochsInDataset(i));
				localIndices(tmp) = true;
			end
			
			EEG.epochGroups{jG}(sum(numEpochsInDataset(1:i-1))+(1:numEpochsInDataset(i))) = localIndices;
		end
	end
end

if s.doAddEpochGroups && ~isempty(s.datasetLabels)
	if ~isfield(EEG,'epochGroupLabels')
		EEG.epochGroups = {};
		EEG.epochGroupLabels = {};
	end
	
	numEpochsInDataset = nan(1,numDatasets);
	for i = 1:numDatasets
		numEpochsInDataset(i) = EEGs{i}.trials;
	end
	assert(sum(numEpochsInDataset)==EEG.trials);
	
	for i=1:numDatasets
		label = s.datasetLabels{i};
		jG = find(ismember(EEG.epochGroupLabels,label),1);
		if isempty(jG)
			% group not yet listed
			jG = length(EEG.epochGroupLabels)+1;
			EEG.epochGroupLabels{jG} = label;
			EEG.epochGroups{jG} = false(1,EEG.trials);
		else
			warning('Duplicate dataset label found while adding epoch groups: %s',label);
			doMerge = false;
			keyboard
			if doMerge
				% don't modify labels, merge two sets of epoch groups with the same label into one group
			else
				newLabel = [label ' 2']; % note this doesn't look good for cases of where there is more than 2 duplicate labels
				c_say('Changing epoch group label from %s to %s',label, newLabel);
				label = newLabel;
				jG = length(EEG.epochGroupLabels)+1;
				EEG.epochGroupLabels{jG} = label;
				EEG.epochGroups{jG} = false(1,EEG.trials);
			end
		end
		EEG.epochGroups{jG}(sum(numEpochsInDataset(1:i-1))+(1:numEpochsInDataset(i))) = true;
	end
	
	keyboard
end

for iF = 1:length(s.fieldsToClear)
	if isfield(EEG,s.fieldsToClear{iF})
		EEG.(s.fieldsToClear{iF}) = [];
	end
end

end
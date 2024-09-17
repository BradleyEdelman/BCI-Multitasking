function chanStrs = c_EEG_getChannelNamesOfType(varargin)
p = inputParser();
p.addRequired('EEG',@isstruct);
p.addOptional('type','',@(x) ischar(x) && ~strcmpi('notType',x));
p.addParameter('notType','',@ischar);
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

if isempty(s.type) && isempty(s.notType)
	error('must either specify type or notType');
end

if ~isempty(s.type) && ~isempty(s.notType)
	error('should not specify both type and notType');
end

if ~isempty(s.type)
	channelIndices = ismember({EEG.chanlocs.type},s.type);
else
	channelIndices = ~ismember({EEG.chanlocs.type},s.notType);
end

chanStrs = c_EEG_getChannelName(EEG,channelIndices);

end
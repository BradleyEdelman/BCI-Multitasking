function [s, usedDefaults] = c_checkSettings(settings,defaultSettings,warn,err)
% c_checkSettings Validates / merges default and non-default settings
% passed in as an argument to a function. 

s = settings;
ds = defaultSettings;

defaultFields = fieldnames(ds);

if nargin >= 3
	warnFields = fieldnames(warn);
else
	warnFields = {};
end
if nargin >= 4
	errFields = fieldnames(err);
else
	errFields = {};
end

for i=1:length(errFields)
	if ~isfield(s,errFields{i})
		error(err.(errFields{i}));
	end
end
for i=1:length(errFields)
	if ~isfield(s,errFields{i})
		warning(warn.(errFields{i}));
	end
end

% look to see whether there are any settings specified that we don't recognize
fieldsSpecified = fieldnames(s);
indices = ~ismember(fieldsSpecified,defaultFields);
if sum(indices)~=0
	error('Unrecognized setting(s): %s',strjoin(fieldsSpecified(indices),','));
end

% grab any default settings that are not specified
for i=1:length(defaultFields)
	if ~isfield(s,defaultFields{i})
		s.(defaultFields{i}) = ds.(defaultFields{i});
		usedDefaults.(defaultFields{i}) = true;
	else
		usedDefaults.(defaultFields{i}) = false;
	end
end

end
function c_Brainsight_save(varargin)
p = inputParser();
p.addRequired('Brainsight',@isstruct);
p.addRequired('OutputPath',@ischar);
p.parse(varargin{:});
s = p.Results;

B = s.Brainsight;

% note that this function does not do much error checking, and an exported file may NOT be valid to open in Brainsight
% (it is recommended to only use this when modifying a Brainsight struct first imported with c_loadBrainsightData, 
%  not to create from scratch).

if B.version ~= 5 && B.version ~= 7
	error('Only version 5 and 7 of Brainsight files currently supported, not %d',r.version);
end

f = fopen(s.OutputPath,'w');
assert(f~=-1);

fprintf(f,'# Version: %d\n',B.version);

fprintf(f,'# Coordinate system: %s\n',B.coordinateSystem);

fprintf(f,'%s',B.headerStr);

printRowColumnSection(f,B.targets);

printRowColumnSection(f,B.samples);

if isfield(B,'electrodes')
	printRowColumnSection(f,B.electrodes);
end

if B.version == 5
	printRowColumnSection(f,B.landmarks);
elseif B.version == 7
	printRowColumnSection(f,B.planLandmarks);
	printRowColumnSection(f,B.sessLandmarks);
end

fclose(f);


end


function printRowColumnSection(f,section)

%% print header row
fields = fieldnames(section);
columnNames = fields;

% some column names had to have spaces converted to underscores when importing to make valid field names
% undo this now
for i=1:length(columnNames)
	columnNames{i} = strrep(columnNames{i},'_',' ');
end

% some names also had periods that were removed entirely or dashes that were replaced with underscores.
% Put these back in according to a list of pre-known fields
namesToConvert = {...
	'Loc X',				'Loc. X';
	'Loc Y',				'Loc. Y';
	'Loc Z',				'Loc. Z';
	'Assoc Target',			'Assoc. Target';
	'Dist to Target',		'Dist. to Target';
	'Stim Power',			'Stim. Power';
	'EMG Res',				'EMG Res.';
	'EMG Peak to peak 0',	'EMG Peak-to-peak 0';
	'EMG Peak to peak 1',	'EMG Peak-to-peak 1';
	};

fromNames = namesToConvert(:,1)';
toNames = namesToConvert(:,2)';

for i=1:length(columnNames)
	for j=1:length(fromNames)
		if strcmp(columnNames{i},fromNames{j})
			columnNames{i} = toNames{j};
		end
	end
end

fprintf(f,'# ');
for i=1:length(columnNames)
	fprintf(f,'%s',columnNames{i});
	if i~=length(columnNames)
		fprintf(f,'\t');
	end
end
fprintf(f,'\n');

%% print values

for iS = 1:length(section)
	sample = section(iS);
	for iC = 1:length(columnNames)
		fprintf(f,valToBSString(sample.(fields{iC}),fields{iC}));
		if iC~=length(columnNames)
			fprintf(f,'\t');
		end
	end
	fprintf(f,'\n');
end


end

function str = valToBSString(val,fieldName)
	if ischar(val) && isempty(val)
		str = '(null)';
	elseif ischar(val)
		str = val;
	elseif strcmpi(fieldName,'Time')
		assert(length(val)==4);
		str = sprintf('%02d:%02d:%02d.%03d',val);
	elseif strcmpi(fieldName,'Date')
		assert(length(val)==3);
		str = sprintf('%d-%02d-%02d',val);
	elseif ismember({fieldName},{'Index','EMG_Channels'})
		assert(length(val)==1);
		str = sprintf('%d',val);
	elseif isscalar(val)
		str = sprintf('%.03f',val);
	elseif isvector(val)
		str = sprintf('%.03f;',val);
	else
		keyboard
		error('Format not yet supported');
	end
end



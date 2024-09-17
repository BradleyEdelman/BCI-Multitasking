function r = c_loadBrainsightData(varargin)
if nargin == 0
	% test
% 	r = c_loadBrainsightData('D:\TMS-EEG\SubjectData\AF\AF_160208\AF_160208_Brainsight.txt');
	r = c_loadBrainsightData('D:\TMS-EEG\SubjectData\AR\20160205_AR\AR_Exported Session Data.txt');
	return;
end

p = inputParser();
p.addRequired('filePath',@ischar);
p.parse(varargin{:});


fp = p.Results.filePath;
if ~exist(fp,'file')
	error('File does not exist at %s', fp);
end

f = fopen(fp,'r');
if f==-1
	error('Could not open file at %s', fp);
end

% first line should be version
str = fgets(f);
[r.version, count] = sscanf(str,'# Version: %d');
if count ~= 1, error('invalid read'); end;
if r.version ~= 5 && r.version ~= 7
	error('Only version 5 and 7 of Brainsight files currently supported, not %d',r.version);
end

% second line should be coordinate system
str = fgets(f);
[r.coordinateSystem, count] = sscanf(str,'# Coordinate system: %s');
if count ~= 1, error('invalid read'); end;

% header continues until next-to-last sequential line beginning with "#"
str = '';
r.headerStr = '';
pos = ftell(f);
while true
	prevStr = str;
	prevPos = pos;
	pos = ftell(f);
	str = fgets(f);
	if strcmp(str(1),'#')
		r.headerStr = [r.headerStr prevStr];
	else
		fseek(f,prevPos,'bof');
		break;
	end
end

% parse section with targets
r.targets = parseRowColumnSection(f,'# Target');
	
% parse section with samples
r.samples = parseRowColumnSection(f,'# Sample');

% parse section with electrodes
r.electrodes = parseRowColumnSection(f,'# Electrode');

% parse section with landmarks
if r.version == 5
	r.landmarks = parseRowColumnSection(f,'# Anatomical Landmark');
elseif r.version == 7
	r.planLandmarks = parseRowColumnSection(f,'# Planned Landmark');
	r.sessLandmarks = parseRowColumnSection(f,'# Session Landmark');
end

% "high-level" parsing (e.g. converting strings of numbers to numbers)

fieldsToConvertIfPresent = {'targets','samples','landmarks','planLandmarks','sessLandmarks'};
for i = 1:length(fieldsToConvertIfPresent)
	if ~isfield(r,fieldsToConvertIfPresent{i})
		continue;
	end
	if ~isempty(r.(fieldsToConvertIfPresent{i}))
		r.(fieldsToConvertIfPresent{i}) = convertFields(r.(fieldsToConvertIfPresent{i}));
	end
end

fclose(f);

end

function [res] = parseRowColumnSection(f,expectedStart)
	% parse each table-like section of Brainsight data file
	% Returns empty struct if section is only a header.
	if nargin > 1
		% next line should start with expectedStart
		str = fgets(f);
		if ~strcmp(str(1:length(expectedStart)),expectedStart), error('invalid read'); end;
	end

	columnLabels = strsplit(str(3:end-1),sprintf('\t'));
	% modify labels to make valid struct field names
	for i=1:length(columnLabels)
		columnLabels{i} = strrep(columnLabels{i},' ','_'); % convert spaces to underscores
		columnLabels{i} = strrep(columnLabels{i},'-','_'); % convert dashes to underscores
		columnLabels{i} = strrep(columnLabels{i},'.',''); % remove periods
	end

	% until the next comment, each line should have length(columnLabels) columns with data in each
	numRows = 0;
	while true
		prevPos = ftell(f);
		str = fgetl(f);
		if strcmp(str(1),'#')  || (isnumeric(str) && str==-1)
			% reached end of section or EOF
			fseek(f,prevPos,'bof');
			break;
		end
		newRow = struct();
		rowEntries = strsplit(str,sprintf('\t'));
		if length(rowEntries) ~= length(columnLabels), error('invalid read'); end;
		for i=1:length(columnLabels)
			newRow.(columnLabels{i}) = rowEntries{i};
		end
		numRows = numRows+1;
		res(numRows) = newRow;
	end
	
	if numRows==0
		% create empty struct that still has field names extracted from header
		args = {};
		for i=1:length(columnLabels)
			args = [args, columnLabels{i},{{}}];
		end
		res = struct(args{:});
	end
end

function [res] = convertFields(res, fieldNames)
	if nargin < 2
		fieldNames = fieldnames(res);
	end
	if ~iscell(fieldNames)
		fieldNames = {fieldNames};
	end
	for j=1:length(fieldNames)
		for i=1:length(res)
			tmp = str2double(res(i).(fieldNames{j}));
			if ~isnan(tmp)
				% conversion was successful
				res(i).(fieldNames{j}) = tmp;
				continue;
			end
			if strcmp(res(i).(fieldNames{j})(end),';') % matrix ending in delimiter
			[tmp, matches] = strsplit(res(i).(fieldNames{j})(1:end-1),';');
				if ~isempty(matches)
					tmp2 = str2double(tmp);
					if all(~isnan(tmp2))
						% conversion was successful
						res(i).(fieldNames{j}) = tmp2;
						continue;
					end
				end
			end
			if strcmpi(fieldNames{j},'Date')
				[tmp, status] = sscanf(res(i).(fieldNames{j}), '%d-%d-%d'); % date format
				if status==3
					% conversion was successful
					res(i).(fieldNames{j}) = tmp;
					continue;
				end
			end
			if strcmpi(fieldNames{j},'Time')
				[tmp, status] = sscanf(res(i).(fieldNames{j}), '%d:%d:%d.%d'); % time format
				if status==4
					% conversion was successful
					res(i).(fieldNames{j}) = tmp;
					continue;
				end
			end
			if strcmp(res(i).(fieldNames{j}),'(null)')
				res(i).(fieldNames{j}) = '';
			end
			% else leave unchanged (as a string)
		end
	end
end

function plotEMGSample(s)
	t = (s.EMG_Start:s.EMG_Res:s.EMG_End);
	if isnumeric(s.EMG_Data_0)
		plot(t,s.EMG_Data_0);
		hold on;
	end
	if isnumeric(s.EMG_Data_1)
		plot(t,s.EMG_Data_1);
		hold on;
	end
end


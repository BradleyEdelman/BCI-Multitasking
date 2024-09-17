function [chanlocs, raw] = c_digitizer_loadData(varargin)
p = inputParser();
p.addRequired('filePath',@ischar);
p.addParameter('type','autodetect',@ischar);
p.addParameter('transform','',@(x) isempty(x) || ischar(x) || iscellstr(x)); % spatial transformation to apply to xyz points
p.parse(varargin{:});
s = p.Results;

assert(exist(s.filePath,'file')>0);

if strcmpi(s.type,'autodetect')
	[~,~,ext] = fileparts(s.filePath);
	switch(lower(ext))
		case '.pos'
			s.type = 'polhemus';
		case '.elp'
			s.type = 'elp';
		case '.3dd'
			s.type = '3dd';
		otherwise
			error('Unsupported extension: %s');
	end
end

switch(lower(s.type))
	case 'polhemus'
		raw = c_digitizer_loadPolhemus(s.filePath);
	case 'elp'
		raw = loadELP(s.filePath);
	case '3dd'
		raw = c_digitizer_load3DD(s.filePath);
	otherwise
		error('Unsupported type: %s',s.type);
end

if ~isempty(s.transform)
	raw = c_digitizer_applyTransform(raw,s.transform);
end

chanlocs = convertRawToChanlocs(raw);

end

function raw = loadELP(filepath)
	%TODO: refactor to avoid converting raw to chanlocs twice (redundant)
	[~, raw] = c_loadBrainsightDigitizerData(filepath);
end

function chanlocs = convertRawToChanlocs(raw)
	indicesToDelete = [];
	
	%c_EEG_openEEGLabIfNeeded();

	for i=1:length(raw.electrodes.electrodes)
		newE = raw.electrodes.electrodes(i);
		newE.type = '';
		if isfield(newE,'label')
			newE.labels = newE.label;
			rmfield(newE,'label');
		end
		for j='XYZ'
			newE.(j) = newE.(j)*1e3; % convert from m to mm
		end
		tmp = strsplit(newE.labels,'_');
		if isempty(tmp) || length(tmp)==1
			% do not change newE.labels
			newE.urchan = i; 
		else
			if strcmp(tmp{2}(1:2),'(n') % format example: Fp1_(n1) -> label=Fp1, urchan=1
				newE.labels = tmp{1};
				newE.urchan = str2num(tmp{2}(3:(end-1)));
			else
				if strcmp(tmp{2},'(FCz)') || ...
						strcmp(tmp{2},'(AFz)') || ...
						strcmp(newE.labels,'Tip_of_nose') || ...
						strcmp(newE.labels,'Tip_of_nose_2')
					indicesToDelete = [indicesToDelete, i];
					newE.urchan = 0;	
				else
					error('Unrecognized channel label format: %s',newE.labels);
				end
			end
		end
		chanlocs(i) = newE;
	end

	raw.deletechanlocs = chanlocs(indicesToDelete);
	chanlocs(indicesToDelete) = [];

	% use EEGLab to add other coordinate system values
	if exist('convertlocs','file')
		chanlocs = convertlocs(chanlocs,'cart2all');
	else
		warning('Skipping chanlocs conversion');
	end
end


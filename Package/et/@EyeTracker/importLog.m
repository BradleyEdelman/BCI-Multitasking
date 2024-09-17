function [data, labels, descriptions] = importLog(log,useParallel, showProgress)

	if nargin < 3
		showProgress = true;
	end
	if nargin < 2
		useParallel = true;
	end

	if useParallel
		numPar = 256;  % arbitrary upper limit
	else
		numPar = 0;
	end

	allPossibleKeys = EyeTracker.listOfKeys();
	keyCount =  zeros(size(allPossibleKeys)); % keep track of which keys we actually encountered
	timeLength = 6;

	data = nan*zeros(1,timeLength + length(allPossibleKeys)); % create first dummy row
	keysPresent = zeros(1,length(allPossibleKeys));

	lines = strsplit(log,'\n');

	lineErr = false;
	ignoreLine = false;

	numLines = length(lines);
	%waitBarHandle = waitbar(0,'Parsing lines...');

	%parfor (l=1:numLines, numPar)
	for l=1:numLines

% 				if mod(l,10)==0
% 					waitbar(l/numLines,waitBarHandle,['Parsing lines... ' num2str(l) '/' num2str(numLines)]);
% 				end

		dataVector = nan*zeros(1,timeLength + length(allPossibleKeys)); % vector is time + key values
% 				if lineErr==true
% 					fprintf('Unable to parse line %d: %s\n',l-1,lines{l-1});
% 					lineErr = false;
% 				end
% 				if ignoreLine==true
% 					fprintf('Skipping line %d: %s\n',l-1,lines{l-1});
% 					ignoreLine = false;
% 				end

		tokens = strsplit(lines{l});

		if length(tokens) < 4
			lineErr=true; continue;
		end

		% first token should be timestamp
		[time,~,~,nextIndex] = sscanf(tokens{1},'%4d.%02d.%02d.%02d.%02d.%f ');
		if nextIndex ~= (length(tokens{1}) + 1)
			lineErr=true; continue;
		end
		dataVector(1:timeLength) = time;

		% only import REC lines, ignoring acks, nacks, and
		% calibration data (for now)
		if strcmp('<REC',tokens{2})

			vec = nan(size(tokens));
			keyPresent = false(1,length(allPossibleKeys));
			index = zeros(size(tokens));
			%parfor t=3:length(tokens)
			for t=3:length(tokens)
				subtokens = strsplit(tokens{t},'=');
				if length(subtokens) < 2
					%fprintf('Not a key,value pair\n');
					continue;
				end
				key = subtokens{1};
				ind = find(ismember(allPossibleKeys,key));
				if isempty(ind)
					fprintf('Invalid key %s\n',key);
					continue;
				end

				% Assume (for now) that all values are numbers
				% (no non-numeric strings)
				[val, n] = sscanf(subtokens{2},'"%f"');
				if n~=1
					fprintf('Invalid value for key %s\n',key);
					continue;
				end

				vec(t) = val;
				index(t) = ind;
			end

			for t=3:length(tokens)
				if ~isnan(vec(t))
					dataVector(timeLength+index(t)) = vec(t);
					keyPresent(index(t)) = true;
					%keyCount(index(t)) = keyCount(index(t)) + 1;
				end
			end

			data = [data; dataVector];
			keysPresent = [keysPresent; keyPresent];

		elseif strcmp('<ACK',tokens{2})
			%TODO
			ignoreLine=true; continue;
		elseif strcmp('<CAL',tokens{2})
			%TODO
			ignoreLine=true; continue;
		elseif strcmp('<NACK',tokens{2})
			%TODO
			ignoreLine=true; continue;
		else 
			lineErr = true; continue;
		end	
	end

	%close(waitBarHandle);

	% remove first dummy row
	data = data(2:end,:);
	keysPresent = keysPresent(2:end,:);

	keyCount = sum(keysPresent,1)';

	timeLabels = {'T_Y';'T_M';'T_D';'T_h';'T_m';'T_s'};

	actualKeys = allPossibleKeys(keyCount>0);
	data = data(:,[true(timeLength,1); keyCount>0]);

	labels = containers.Map([timeLabels; actualKeys],1:(timeLength + length(actualKeys)));

	descriptions = ''; %TODO
end
function result = c_offlineBCIComparison(varargin)

persistent pathModified;
if isempty(pathModified)
	addpath('../../Common'); %TODO: only run if not already on path
	addpath('../../Common/EEGAnalysisCode');
	pathModified = true;
end

if nargin == 0
	testPaths = {...
		'D:/BCIYoga/SubjectData/AMG/AMG_LRt_20141104001/AMG_LRt_20141104S001R01.dat',...
		'D:/BCIYoga/SubjectData/JMP/JMP_LRt_20141017001/JMP_LRt_20141017S001R02.dat',...
		};
	
	c_offlineBCIComparison(testPaths);
	
	return
	
end

%%
p = inputParser();
p.addRequired('EEG',@(x) ischar(x) || isstruct(x) || iscell(x));  % path to data file, or raw EEG struct already imported with EEGLAB
p.addParameter('dataLabels',{},@iscell);
p.addParameter('doPlot',true,@islogical);
p.parse(varargin{:});


EEG = p.Results.EEG;

global EEGLabLaunched;
if isempty(EEGLabLaunched)
	c_say('Launching EEGLab');
	eeglab
	c_sayDone();
	EEGLabLaunched = true;
end

% If path was specified, load data file with EEGlab
if ~isstruct(EEG)
	eegPaths = EEG;
	clearvars('EEG');
	if ~iscell(eegPaths)
		eegPaths = {eegPaths};
	end
	c_say('Loading BCI2000 data');
	for i=1:length(eegPaths)
		if length(eegPaths) > 1, c_say('File %d/%d',i,length(eegPaths)); end;
		EEG(i) = c_loadBCI2000Data(eegPaths{i});
		if length(eegPaths) > 1, c_sayDone(); end;
		
		if isempty(p.Results.dataLabels)
			dataLabels{i} = ['Data ' num2str(i)];
		else
			dataLabels{i} = p.Results.dataLabels{i};
		end
	end
	c_sayDone();
end


%% construct argument sets
commonArgs = {...
	'leftChannel','C3',...
	'rightChannel','C4',...
	'channelsToKeep',{},...
	'spatialFilter','laplacian',...
	'normalization','offline'};

% like meshgrid for arguments, construct all combinations of given paremeters
parametersToVary = {'leftChannel','rightChannel','spatialFilter'};
% parametersToVary = {'spatialFilter'};
variableArgs = {};
for j=1:length(parametersToVary)
	parameterToVary = parametersToVary{j};
	
	switch(parameterToVary)
		case 'spatialFilter'
			parameterValues = {'none','laplacian','rereference'};
% 			parameterValues = {'none','laplacian'};

		case 'leftChannel'
% 			parameterValues = {'C3','CP3','C1'};
			parameterValues = {'C3','CP3'};

		case 'rightChannel'
% 			parameterValues = {'C4','CP4','C2'};
			parameterValues = {'C4','CP4'};
% 			parameterValues = {'C4'};

		otherwise
			error('invalid');
	end
	
	newVariableArgs = {};
	for i=1:length(parameterValues)
		if ~isempty(variableArgs)
			for k=1:length(variableArgs)
				newVariableArgs = [newVariableArgs, ...
					{[variableArgs{k}, parameterToVary, parameterValues{i}]}];
			end
		else
			newVariableArgs = [newVariableArgs, {{parameterToVary, parameterValues{i}}}];
		end
	end
	variableArgs = newVariableArgs;
end

for i=1:length(variableArgs)
	tmp = '';
	for j=2:2:length(variableArgs{i})
		if ~isempty(tmp), tmp = [tmp, ' ']; end;
		tmp = [tmp,variableArgs{i}{j}];
	end
	argSetLabels{i} = tmp;
end

%% run simulations
for j=1:length(EEG)
	c_say('Running simulations for dataset %d/%d',j,length(EEG));
	for i=1:length(variableArgs) %TODO: change back to parfor
		c_say('Running simulation %d/%d',i,length(variableArgs));
		eeg(j,i) = c_simulateBCIOffline(EEG(j),...
			commonArgs{:},...
			variableArgs{i}{:});

		resultMetrics(j,i) = c_EEG_calculatePerformanceMetrics(eeg(j,i));
		c_sayDone();
	end
	c_sayDone();
end

%% analyze results
if p.Results.doPlot
	fieldsToPlot = {'PVC','PTC','numCorrect','numIncorrect'};
	h1 = figure;
	for i=1:length(fieldsToPlot)
		fieldToPlot = fieldsToPlot{i};
		valuesToPlot = c_extractNumericalValuesFromStructArray(resultMetrics,fieldToPlot);

		doPlotMean = true;
		if doPlotMean % calculate mean values to plot
			valuesToPlot = [valuesToPlot; mean(valuesToPlot,1)];
			dataLabels = [dataLabels, 'Mean'];
		end

		% bar plot over all parameter combinations
		figure(h1);
		c_subplot(i,length(fieldsToPlot));
		if 1 % group by subject, color by parameter set
			bar(1:size(valuesToPlot,1), valuesToPlot)
			set(gca,'XTickLabel',dataLabels);
			legend(argSetLabels);
		else % group by parameter combination, color by subject
			bar(1:size(valuesToPlot,2), valuesToPlot')
			set(gca,'XTickLabel',argSetLabels);
			legend(dataLabels);
		end
		title(fieldToPlot);
		legend('hide');


		% line plot (assuming datasets are ordered over time)
		if 0
		figure('name',[fieldToPlot ' line plot']);
		plot(1:size(eeg,1),valuesToPlot(1:size(eeg,1),:));
		legend(argSetLabels,'location','eastOutside');
		end
	end
end

%% return 
if nargout > 0
	result.variableArgs = variableArgs;
	result.metrics = resultMetrics;
	result.argSetLabels = argSetLabels;
end


end



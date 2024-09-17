function c_plot_scatterBinned(varargin)
	p = inputParser();
	p.addRequired('x',@isnumeric);
	p.addRequired('y',@isnumeric);
	p.addParameter('center',@mean,@(x) isa(x,'function_handle'));
	p.addParameter('bounds',@std,@(x) isa(x,'function_handle') || isempty(x));
	p.addParameter('doScatter',true,@islogical);
	p.addParameter('scatterColor',[0.5 0.5 0.5],@isnumeric);
	p.addParameter('numBins',8,@isscalar);
	p.addParameter('binLimits',[NaN NaN],@isvector);
	p.addParameter('boundedLineArgs',{},@iscell);
	p.parse(varargin{:});
	
	x = p.Results.x;
	y = p.Results.y;
	
	%% bin scattered data for averaging
	binLimits = p.Results.binLimits;
	numBins = p.Results.numBins;
	
	if isnan(binLimits(1))
		binLimits(1) = min(x);
	end
	if isnan(binLimits(2))
		binLimits(2) = max(x);
	end
	
	if any(x < binLimits(1) | x > binLimits(2))
		warning('Points outside of bin limits will not be included in bins');
	end
	
	binBoundaries = linspace(binLimits(1),binLimits(2),numBins+1);
	
	binYCenters = nan(numBins,1);
	binBounds = nan(numBins,2);
	for b=1:numBins
		binXCenters(b) = mean(binBoundaries(b:b+1));
		binDataIndices = x >= binBoundaries(b) & x < binBoundaries(b+1);
		if sum(binDataIndices(:)) == 0
			binYCenters(b) = NaN;
			binBounds(b,:) = [NaN, NaN];
		else
			binYCenters(b) = p.Results.center(y(binDataIndices));
			if ~isempty(p.Results.bounds)
				binBounds(b,:) = p.Results.bounds(y(binDataIndices));
			end
		end
	end
	
	%% plot
	if ~isempty(p.Results.bounds)
		% use boundedline
		[~,hp] = boundedline(binXCenters,binYCenters,binBounds,p.Results.boundedLineArgs{:});
		% do not include bounds in legend entries
		set(get(get(hp,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
	else
		% use plot without bounds
		plot(binXCenters,binYCenters);
	end
	
	if p.Results.doScatter
		hold on;
		scatter(x,y,[],p.Results.scatterColor);
	end
end
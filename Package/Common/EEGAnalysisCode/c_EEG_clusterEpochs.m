function EEG = c_EEG_clusterEpochs(varargin)

p = inputParser();
p.addRequired('EEG',@isstruct);
p.addParameter('timespan',[],@(x) isempty(x) || isvector(x)); % can use this to specify temporal subset of data to use for clustering
p.addParameter('timepoints',[],@(x) isempty(x) || isvector(x)); % can use to specify certain time points at which to cluster (instead of timespan / downsampling)
p.addParameter('timepointsTimespan',[-2 2]*1e-3,@(x) isempty(x) || (isvector(x) && length(x)==2)); 
p.addParameter('downsampleFs',[],@(x) isempty(x) || isscalar(x)); % frequency (Hz) to downsample data to before clustering (to reduce dimensionality)
p.addParameter('clusterInputMode','channels',@(x) ischar(x));
p.addParameter('clusterInputSet',[],@(x) isempty(x) || isvector(x) || iscell(x)); % use to specify subset of channels / components for clustering
p.addParameter('doNormalizeInput',false,@islogical);
p.addParameter('doPCA',false,@islogical);
p.addParameter('numPCAComponents',0.99,@isscalar); % if not integer, will select number of components to explain specified fraction of variance in input
p.addParameter('numClusters',10,@isscalar);
p.addParameter('clusterMethod','hierarchical',@(x) ischar(x) && ismember(x,{'kmeans','hierarchical'}));
p.addParameter('doPlot',true,@islogical);
p.addParameter('doDebugPlot',false,@islogical);
p.addParameter('doPlotPCScatter',true,@islogical);
p.addParameter('plotDispMonitor',1,@isnumeric);
p.addParameter('doReplaceGroups',false,@islogical); % whether to replace or just add to any existing epoch groups in EEG struct
p.addParameter('pruneMethod','interactive',@(x) ischar(x) && ismember(x,{'interactive','none'}));
p.parse(varargin{:});
s = p.Results;
EEG = s.EEG;

c_say('Clustering epochs');

if ~isempty(s.timepoints)
	% cluster based on values at specific time points only
	c_saySingle('Clustering based on values at time points: %s ms',c_toString(s.timepoints*1e3));
	
	if ~isempty(s.timespan)
		warning('Time points specified, so ignoring timespan.');
	end
	if ~isempty(s.downsampleFs)
		warning('Time points specified, so not downsampling.');
	end
	
	vals = c_EEG_calculateAmplitudesAtTimes(EEG,s.timepoints,...
		'localTimespan',s.timepointsTimespan);
	
	EEG.data = vals;
else
	% reduce to subset of time if specified
	if ~isempty(s.timespan)
		%TODO: modify code to, if cutting down to a subset of channels later, cut down here to reduce 
		% downsampling computation time
		c_saySingle('Cutting epochs to timespan %s',c_toString(s.timespan));
		EEG = c_EEG_epoch(EEG,'timespan',s.timespan);
	end

	% downsample epochs if specified
	if ~isempty(s.downsampleFs)
		if s.doDebugPlot
			tmpEEG = EEG;
		end
		
		c_saySingle('Downsampling to %d Hz',s.downsampleFs);
		EEG = c_EEG_resample(EEG,s.downsampleFs);
		
		if s.doDebugPlot
			tmpEEG2 = c_EEG_resample(EEG,tmpEEG.srate);
			tmpEEG3 = c_EEG_epoch(tmpEEG2,'timespan',[tmpEEG.xmin tmpEEG.xmax]);
			c_EEG_plotRawComparison({tmpEEG,tmpEEG3},'descriptors',{'Before downsampling','After downsampling/upsampling'});
			clearvars tmpEEG tmpEEG2 tmpEEG3
		end
	end
end

% extract subset of data for clustering
switch(s.clusterInputMode)
	case 'channels'
		if isempty(s.clusterInputSet)
			s.clusterInputSet = 1:EEG.nbchan; % all channels
		elseif iscell(s.clusterInputSet)
			% assume channel names were specified, convert to numbers
			s.clusterInputSet = c_EEG_getChannelIndex(EEG,s.clusterInputSet);
		end

		%TODO: add option to take mean of cluster input set (e.g. across ROI of channels) instead of 
		%  concatenating into higher dimensional feature space

		c_saySingle('Using %d channels of data for clustering',length(s.clusterInputSet)); %TODO: modify count to also work with logical indexing

		dataToCluster = EEG.data(s.clusterInputSet,:,:);
	
	case 'components'
		if isempty(s.clusterInputSet)
			s.clusterInputSet = 1:size(EEG.icaweights,1); % all components
		else
			assert(isvector(s.clusterInputSet)); % cell input type not supported for component set
		end

		c_saySingle('Using %d ICA components for clustering',length(s.clusterInputSet));

		EEG = c_EEG_calculateICAAct(EEG); % force (re)calculation of component time courses

		dataToCluster = EEG.icaact(s.clusterInputSet,:,:);
	
	case 'sources'
		
		% recalculate source timecourses
		% (ignore any existing src.data since it was not necessarily epoched and downsampled in the same way as EEG.data above)
		if isempty(s.clusterInputSet)
			EEG.src.data = c_mtimes(EEG.src.kernel,EEG.data);
			dataToCluster = EEG.src.data;
		else
			% only calculate for subset of sources of interest
			dataToCluster = c_mtimes(EEG.src.kernel(s.clusterInputSet,:),EEG.data);
		end
		
		c_saySingle('Using %d source%s for clustering',size(dataToCluster,1),c_strIfNumIsPlural(size(dataToCluster,1)));
		
	case 'sourceROIs'
		
		if isempty(s.clusterInputSet)
			s.clusterInputSet = 1:length(EEG.src.ROIs);
		else
			assert(isvector(s.clusterInputSet));
		end
		
		dataToCluster = c_EEG_calculateROIData(EEG,'ROIs',EEG.src.ROIs(s.clusterInputSet));
		
		c_saySingle('Using %d source ROIs for clustering',size(dataToCluster,1));
		
	otherwise
		error('Unsupported clusterInputMode: %s',s.clusterInputMode);
end

dataToCluster = permute(dataToCluster,[3 2 1]);
dataToCluster = reshape(dataToCluster,EEG.trials,[]);	

if s.doNormalizeInput
	c_say('Normalizing data before clustering');
	dataNorms = c_norm(dataToCluster,2,2); % normalize each epoch
	dataToCluster = bsxfun(@rdivide,dataToCluster,dataNorms);
	c_sayDone();
end

%% dimensionality reduction

if s.doPCA
	[coeff,score,~,~,explained,mu] = pca(dataToCluster);
	pvarExplained = cumsum(explained); % percent variance explained by including all components up to index
	
	if s.doPlot
		figure('name','Pre-clustering PCA');

		c_subplot(1,2);
		
		pvarsToMark = [90,95,99];
		
		if c_isinteger(s.numPCAComponents)
			pvarsToMark(end+1) = pvarExplained(min(s.numPCAComponents,length(pvarExplained)));
		else
			pvarsToMark(end+1) = s.numPCAComponents*100;
		end
		pvarsToMark = unique(pvarsToMark);
		
		for iM = 1:length(pvarsToMark)
			index = find(pvarExplained >= pvarsToMark(iM),1,'first');
			if isempty(index), break; end;
			x = index;
			y = pvarExplained(index);
			line([x x],[-10 y],'Color',[1 1 1]*0.8);
			line([-10 x],[y y],'Color',[1 1 1]*0.8);
			xlim([-1, size(coeff,2)+1]);
			ylim([-1 101]);
			c_saySingle('%d components explain %.2g%% of variance',index,pvarExplained(index));
		end

		hold on;

		plot(1:length(explained),pvarExplained);

		xlabel('Number of principal components');
		ylabel('% variance explained');
		title('PCA');
	end
	
	if c_isinteger(s.numPCAComponents)
		numComponentsToKeep = min(s.numPCAComponents,size(coeff,2));
		c_saySingle('Keeping %d/%d principal components, which explains %.2g%% of variance',...
			numComponentsToKeep,size(coeff,2),pvarExplained(numComponentsToKeep));
	else
		pvarToExplain = s.numPCAComponents; % non-integer input represents fraction of variance to explain
		numComponentsToKeep = find(pvarExplained >= pvarToExplain*100,1,'first');
		c_saySingle('Keeping %d/%d principal components to explain %.2g%% of variance',...
			numComponentsToKeep,size(coeff,2),pvarExplained(numComponentsToKeep));
	end
	
	truncatedCoeff = coeff(:,1:numComponentsToKeep);
	truncatedScores = score(:,1:numComponentsToKeep);
	
	if s.doPlot
		c_subplot(2,2);
		exampleIndex = 1;
		orig = dataToCluster(exampleIndex,:);
		recon = truncatedScores(exampleIndex,:)*truncatedCoeff' + mu;
		plot(1:length(orig),cat(1,orig,recon));
		legend('Input','Approximation');
		title('Example of PCA dimensionality reduction');
	end
	
	dataToCluster = truncatedScores;
	
	if s.doPlot
		% plot top PC coeffs in original feature space
		switch(s.clusterInputMode)
			case 'channels'
				toPlot = truncatedCoeff;
				EEGCh = {EEG.chanlocs(s.clusterInputSet).labels};
				toPlot = reshape(toPlot,[length(EEG.times) length(EEGCh) size(toPlot,2) ]); % last dim is # of components
				
				if length(EEGCh) > 1 && ~c_isFieldAndNonEmpty(EEG,'dataIsSrcData')
					hf = [];
					for iC = 1:3
						hf(iC) = figure('Name',sprintf('Clustering PC %d',iC));
						fn = @() timtopo(toPlot(:,:,iC)',EEG.chanlocs,...
							'limits',[extrema(EEG.times)],...
							'plottimes',linspace(EEG.xmin, EEG.xmax,6)*1e3,...
							'chaninfo',EEG.chaninfo);
						evalc('fn();');
					end
					c_fig_arrange('tile',hf);
				elseif length(EEGCh)==1
					numPCsToPlot = 5;
					hf = figure('Name',sprintf('Clustering Top %d PCs',numPCsToPlot));
					colors = c_getColors(numPCsToPlot);
					for iC = 1:numPCsToPlot
						plot(EEG.times,toPlot(:,:,iC),'Color',colors(iC,:));
						hold on;
					end
					xlabel('Time (ms)');
					ylabel('PC amplitude');
					title(sprintf('PCs for channel %s',EEGCh{1}));
					clickableLegend(arrayfun(@(x) sprintf('PC %d',x),1:numPCsToPlot,'UniformOutput',false));
				end
				
			otherwise
				% this particular plot is not yet supported
				% (so do nothing)
				warning('PC coeff plotting not supported for inputMode %s',s.clusterInputMode);
		end
	end
end

%% clustering

switch(s.clusterMethod)
	case 'kmeans'
		c_say('Running k-means clustering, dividing %d trials into %d clusters',size(dataToCluster,1),s.numClusters);
		idx = kmeans(dataToCluster,s.numClusters);
		c_sayDone();

		if s.doPlot
			h = figure('name','K-means silhouette results');
			c_silhouette(dataToCluster,idx);
			c_fig_arrange('top-right',h,'monitor',s.plotDispMonitor);
		end

		% reformat cluster indices from format (for example) [1,2,1,1,2] to {[1 3 4],[2,5]}
		clusterGroupIndices = cell(1,s.numClusters);
		for iC = 1:s.numClusters
			clusterGroupIndices{iC} = find(idx==iC);
		end
		clusterGroupLabels = arrayfun(@(x) sprintf('Cluster %d',x), 1:length(clusterGroupIndices),'UniformOutput',false);

	case 'hierarchical'
		distanceMetric = 'euclidean';
		c_say('Running hierarchical clustering');
		method = 'ward';
		doCreateParentGroups = true;

		T = linkage(dataToCluster,method,distanceMetric);
		c_sayDone();

		doSlowLeafOrderCalculation = false;
		doFastLeafOrderCalculation = true;
		
		
		% calculate distance threshold to obtain desired number of clusters
		if doSlowLeafOrderCalculation
			c_say('Calculating optimal leaf order with slow method');
			dists = pdist(dataToCluster,distanceMetric);
			leafOrder = optimalleaforder(T,dists);
			c_sayDone();
		else
			leafOrder = 1:(size(T,1)+1);
		end
		

		c_say('Processing clustering results');
		
		% convert linkage matrix to nested struct tree
		tree = c_bintree_constructFromLinkageTree(T); 
		% re-number in optimal leaf order
		tree = c_bintree_remapNodeValues(tree,'linkageIndex',...
			'map_origValues',leafOrder,...
			'map_newValues',1:length(leafOrder),...
			'nodeSet','leaves',...
			'copyOriginalValuesToField','dataIndex');
		% merge nodes to obtain desired number of clusters
		tree = c_bintree_agglomerate(tree,s.numClusters,...
			'sortField','linkageDistance',...
			'collectLeafFields',{'dataIndex'}); 

		if doFastLeafOrderCalculation
			% reorder branches of condensed tree
			[Tp, tree] = c_bintree_exportLinkageTree(tree,...
				'valueFields',{'linkageDistance'},...
				'leafIndexField','clusterNumber');
			
			clusterGroupIndices = c_bintree_getNodeValues(tree,'dataIndex',...
				'nodeSet','leaves',...
				'nodeIndexField','nodeIndex',...
				'valuesField','leafValues',...
				'valuesFn',@cell2mat);
			
			numClusters = length(clusterGroupIndices);
			clusterMeans = nan(numClusters,size(dataToCluster,2));
			for iC = 1:numClusters
				clusterMeans(iC,:) = mean(dataToCluster(clusterGroupIndices{iC},:),1);
			end
			dists = pdist(clusterMeans,distanceMetric);
			leafOrder = optimalleaforder(Tp,dists);
			
			tree = c_bintree_remapNodeValues(tree,'clusterNumber',...
				'map_origValues',leafOrder,...
				'map_newValues',1:length(leafOrder),...
				'nodeSet','leaves');
			
			tree = c_bintree_sortLeftRight(tree,'clusterNumber');
		end
		
		[Tp, tree] = c_bintree_exportLinkageTree(tree,...
			'valueFields',{'linkageDistance'},...
			'leafIndexField','clusterNumber');
		
		clusterGroupIndices = c_bintree_getNodeValues(tree,'dataIndex',...
			'nodeSet','all',...
			'nodeIndexField','nodeIndex',...
			'valuesField','leafValues',...
			'valuesFn',@cell2mat);
		
		c_sayDone();

		if s.doPlot
			h = figure('name','Clustered dendrogram');
			dendrogram(Tp,0,'Reorder',size(Tp,1)+1:-1:1,'orientation','left');
			xlabel('Linkage distance');
			ylabel('Cluster');
			ylim([0 numClusters+1]);
			c_fig_arrange('top-left-top',h,'monitor',s.plotDispMonitor);
		end

		clusterGroupLabels = arrayfun(@(x) sprintf('Cluster %d',x), 1:length(clusterGroupIndices),'UniformOutput',false);
		childIndices = cell(1,length(clusterGroupIndices));
		for iC = 1:length(clusterGroupIndices)
			for iCb = 1:length(clusterGroupIndices)
				if ~isempty(childIndices{iCb})
					% child is itself a metacluster, so don't test here
					continue;
				end
				if iCb==iC
					continue;
				end
				if length(intersect(clusterGroupIndices{iCb},clusterGroupIndices{iC}))==length(clusterGroupIndices{iCb})
					% cluster iC is a parent of cluster iCb
					childIndices{iC} = [childIndices{iC}, iCb];
				end
			end
			if ~isempty(childIndices{iC})
				clusterGroupLabels{iC} = sprintf('Metacluster %s',c_toString(childIndices{iC}));
			end
		end

		% convert clusterDataIndices to format exected by silhouette
		idx = nan(size(dataToCluster,1),1);
		for iC = length(clusterGroupIndices):-1:1
			% go backwards to overwrite membership in non-leaf clusters
			idx(clusterGroupIndices{iC}) = iC;
		end

		if s.doPlot
			h = figure('name','Hierarchical clustering silhouette results');
			c_plot_silhouette(dataToCluster,idx);
			c_fig_arrange('top-right-top',h,'monitor',s.plotDispMonitor);
		end

	otherwise
		error('Invalid cluster method: %s',s.clusterMethod);
end

%% prune clusters

switch(s.pruneMethod)
	case 'interactive'
		%TODO
		
	case 'none'
		% do nothing
	otherwise
		error('Invalid pruneMethod: %s',pruneMethod);
end

%% extra plotting

if s.doPCA && s.doPlotPCScatter
	% only plot child cluster membership, not parent clusters (to avoid having a particular scatter point belong to > 1 cluster)
	[clusterIndicesToPlot,clusterLabelsToPlot] = c_str_matchRegex(clusterGroupLabels,'^Cluster*');
	clusterIndicesToPlot = find(clusterIndicesToPlot);
	
	figure('Name','Clustering PCs scatter 2D');
	PC1 = [1 1 2];
	PC2 = [2 3 3];
	assert(length(PC1)==length(PC2));
	colors = c_getColors(length(clusterIndicesToPlot));
	for i=1:length(PC1)
		ii = PC1(i);
		jj = PC2(i);
		c_subplot(i,length(PC1));
		for iC = 1:length(clusterIndicesToPlot)
			indices = clusterGroupIndices{iC};
			scatter(dataToCluster(indices,ii),dataToCluster(indices,jj),...
				'MarkerEdgeColor',colors(iC,:));
			hold on;
		end
		clickableLegend(clusterLabelsToPlot);
		xlabel(sprintf('Component %d',ii));
		ylabel(sprintf('Component %d',jj));
	end
	c_fig_arrange('maximize',gcf,'monitor',s.plotDispMonitor+1);
	
	PC1 = [1 1];
	PC2 = [2 4];
	PC3 = [3 5];
	assert(length(PC1)==length(PC2) && length(PC1)==length(PC3));
	colors = c_getColors(length(clusterIndicesToPlot));
	hf = [];
	for i=1:length(PC1)
		ii = PC1(i);
		jj = PC2(i);
		kk = PC3(i);
		hf(i) = figure('Name',sprintf('Clustering PCs scatter 3D (%d,%d,%d)',ii,jj,kk));
		for iC = 1:length(clusterIndicesToPlot)
			indices = clusterGroupIndices{iC};
			c_plot_scatter3(dataToCluster(indices,[ii jj kk]),...
				'markerType','.',...
				'ptColors',colors(iC,:));
			hold on;
		end
		clickableLegend(clusterLabelsToPlot);
		xlabel(sprintf('Component %d',ii));
		ylabel(sprintf('Component %d',jj));
		zlabel(sprintf('Component %d',kk));
	end
	c_fig_arrange('tile',hf,'monitor',s.plotDispMonitor+1);
end


%%

% restore EEG struct
EEG = s.EEG;

% write outputs
if ~c_isFieldAndNonEmpty(EEG,'epochGroups') || s.doReplaceGroups
	EEG.epochGroups = clusterGroupIndices;
	EEG.epochGroupLabels = clusterGroupLabels;
else
	EEG.epochGroups = cat(2,EEG.epochGroups, clusterGroupIndices);
	EEG.epochGroupLabels = cat(2,EEG.epochGroupLabels, clusterGroupLabels);
end

c_sayDone();

end
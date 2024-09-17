function c_plot_silhouette(varargin)
% modified silhouette plot which evenly spaces clusters (to match other plot types)

p = inputParser();
p.addRequired('data',@ismatrix);
p.addRequired('clust',@isvector);
p.addParameter('silhouetteArgs',{},@iscell);
p.addParameter('doPlotUniformSpacing',true,@islogical);
p.addParameter('paddingLength',2,@isnumeric);
p.addParameter('orientation','left',@(x) ismember(x,{'top','bottom','left','right'}));
p.parse(varargin{:});
s = p.Results;

if ~s.doPlotUniformSpacing
	silhouette(s.data,s.clust,s.silhouetteArgs{:});
else
	sVals = silhouette(s.data,s.clust,s.silhouetteArgs{:});
	
	groupedSVals = {};
	assert(length(s.clust)==size(s.data,1)); % require that clust is vector of cluster labels, one per data point
	% (could add support for other cluster specification types later)
	clusterIDs = sort(unique(s.clust));
	numClusters = length(clusterIDs);
	for iC = 1:numClusters
		indicesInCluster = ismember(s.clust,clusterIDs(iC));
		groupedSVals{iC} = sort(sVals(indicesInCluster),'descend');
	end
	
	numInClusters = cellfun(@length,groupedSVals);
	maxNumInCluster = max(numInClusters);
	
	s.paddingLength = round(s.paddingLength);
	
	widthPerCluster = s.paddingLength + maxNumInCluster;
	
	assembledVals = nan(1,widthPerCluster*numClusters);
	
	for iC = 1:numClusters
		leftPadding = floor((widthPerCluster - numInClusters(iC))/2);
		indices = (iC-1)*widthPerCluster + leftPadding + (1:numInClusters(iC));
		assembledVals(indices) = groupedSVals{iC};
	end
	
	clusterLabels = 1:numClusters;  %TODO: use cluster label strings if available
	clusterCenters = ((1:numClusters)-0.5) * widthPerCluster;
	switch(s.orientation)
		case 'bottom'
			h = bar(1:widthPerCluster*numClusters,assembledVals,1);
			clusterAxis = 'X';
			clusterAxisDir = 'normal';
			nonclusterAxis = 'Y';
		case 'left'
			h = barh(1:widthPerCluster*numClusters,assembledVals,1);
			clusterAxis = 'Y';
			clusterAxisDir = 'reverse';
			nonclusterAxis = 'X';
			
		otherwise
			error('Orientation %s not supported',s.orientation);
	end
	ha = gca;
	ha.([clusterAxis 'Tick']) = clusterCenters;
	ha.([clusterAxis 'TickLabel']) = clusterLabels;
	ha.([clusterAxis 'Label']).String = 'Cluster';
	ha.([clusterAxis 'Dir']) = clusterAxisDir;
	ha.([nonclusterAxis 'Label']).String = 'Silhouette value';
	ha.([clusterAxis 'Lim']) = [-0.5 (numClusters+0.5)]*widthPerCluster;
end

end
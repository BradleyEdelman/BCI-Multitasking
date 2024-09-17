function reducedTree = c_bintree_agglomerate(varargin)

	if nargin == 0, testfn(); return; end;
	
	p = inputParser();
	p.addRequired('tree',@isstruct);
	p.addRequired('numClusters',@isscalar);
	p.addParameter('sortField','linkageDistance',@ischar);
	p.addParameter('clusterNumberField','clusterNumber',@ischar);
	p.addParameter('clusterSortField','linkageIndex',@ischar);
	p.addParameter('collectLeafFields',{'linkageIndex'},@iscell);
	p.parse(varargin{:});
	s = p.Results;
	tree = s.tree;

	s.collectLeafFields = union(s.collectLeafFields,{s.clusterSortField});

	tree = c_bintree_collectLeafValues(tree,s.collectLeafFields);
	tree = c_bintree_sortLeftRight(tree,s.sortField);

	% proceed down tree in breadth-first search until number of (new) leaf nodes matches number of clusters
	thresholdValue = tree.value.(s.sortField);
	isDone = false;

	while ~isDone
		subtree = c_bintree_mergeSubthresholdNodes(tree,thresholdValue,s.sortField,s.clusterNumberField);
		newNumClusters = c_bintree_getNumLeaves(subtree);
		if newNumClusters >= s.numClusters,
			% note this could return more than numClusters if there are two or more nodes "tie"
			break;
		else
			% set thresholdValue to next smallest node value
			tmpTree = c_bintree_collectLeafValues(subtree,s.sortField);
			tmpIndices = cell2mat(tmpTree.leafValues.(s.sortField)) < thresholdValue;
			if isempty(tmpIndices)
				% there are no smaller node values
				break;
			else
				thresholdValue = max(cell2mat(tmpTree.leafValues.(s.sortField)(tmpIndices)));
			end
		end
	end
	
	% renumber cluster numbers to match order of collectLeafField as much as possible
	% (requires that original tree had leaf values collected before merging)
	numClusters = c_bintree_getNumLeaves(subtree);
	clusterMinLinkageIndices = nan(1,numClusters);
	for iC = 1:numClusters
		[val, leafValues] = c_bintree_getValuesForNode(subtree,'clusterNumber',iC);
		assert(~isempty(val));
		clusterMinLinkageIndices(iC) = min(cell2mat(leafValues.(s.clusterSortField)));
	end
	[~,sortOrder] = sort(clusterMinLinkageIndices);
	subtree = c_bintree_remapNodeValues(subtree,'clusterNumber',...
		'map_origValues',sortOrder,...
		'map_newValues',1:numClusters,...
		'nodeSet','leaves');
	
	reducedTree = subtree;
end

function [tree, numClusters] = c_bintree_mergeSubthresholdNodes(tree,threshold,thresholdField,clusterNumberField,numClusters)
	if nargin < 5
		numClusters = 0;
	end
	if tree.isLeaf
		numClusters = numClusters + 1;
		tree.value.(clusterNumberField) = numClusters;
		return;
	elseif tree.value.(thresholdField) < threshold
		tree.left = [];
		tree.right = [];
		tree.isLeaf = true;
		numClusters = numClusters + 1;
		tree.value.(clusterNumberField) = numClusters;
	else
		[tree.left, numClusters] = c_bintree_mergeSubthresholdNodes(tree.left,threshold,thresholdField,clusterNumberField,numClusters);
		[tree.right, numClusters] = c_bintree_mergeSubthresholdNodes(tree.right,threshold,thresholdField,clusterNumberField,numClusters);
	end
end

function numLeaves = c_bintree_getNumLeaves(tree)
	if tree.isLeaf
		numLeaves = 1;
	else
		numLeaves = c_bintree_getNumLeaves(tree.left) + c_bintree_getNumLeaves(tree.right);
	end
end

function testfn()
	testTree = linkage(rand(10,3));
	figure; dendrogram(testTree);
	tree = c_bintree_constructFromLinkageTree(testTree)
	tree = c_bintree_agglomerate(tree,5);
	keyboard
end
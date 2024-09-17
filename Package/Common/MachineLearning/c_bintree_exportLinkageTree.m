function [linkageTree, numberedTree] = c_bintree_exportLinkageTree(varargin)
	if nargin == 0, testfn(); return; end;

	p = inputParser();
	p.addRequired('tree',@isstruct);
	p.addParameter('valueFields',{},@iscell);
	p.addParameter('leafIndexField','',@ischar); % read leaf index values from this field
	p.addParameter('nodeIndexField','nodeIndex',@ischar); % write node index values to this field
	p.parse(varargin{:});
	s = p.Results;
	tree = s.tree;
	
	numLeaves = c_bintree_getNumLeaves(tree);
	
	linkageTree = nan(numLeaves-1,2+length(s.valueFields));
	
	assert(~tree.isLeaf); % assume tree has at least two leaves
	
	numberedTree = numberLeaves(tree,s.leafIndexField,s.nodeIndexField);
	numberedTree = swapBranchesToSort(numberedTree,s.nodeIndexField);
	numberedTree = numberNonLeaves(numberedTree,numLeaves,s.nodeIndexField);
	linkageTree = storeLinkages(numberedTree,numLeaves,s.valueFields,s.nodeIndexField,linkageTree);
end

function [tree, leafCount] = numberLeaves(tree,leafIndexField,nodeIndexField,leafCount)
	if nargin < 4
		leafCount = 0;
	end
	if tree.isLeaf
		leafCount = leafCount + 1;
		if isempty(leafIndexField)
			tree.value.(nodeIndexField) = leafCount;
		else
			tree.value.(nodeIndexField) = tree.value.(leafIndexField);
		end
	else
		[tree.left, leafCount] = numberLeaves(tree.left,leafIndexField,nodeIndexField,leafCount);
		[tree.right, leafCount] = numberLeaves(tree.right,leafIndexField,nodeIndexField,leafCount);
	end
end

function [tree, rootSortVal] = swapBranchesToSort(tree,nodeIndexField)
	if tree.isLeaf
		rootSortVal = tree.value.(nodeIndexField);
	else
		[tree.left, leftSortVal] = swapBranchesToSort(tree.left,nodeIndexField);
		[tree.right,rightSortVal] = swapBranchesToSort(tree.right,nodeIndexField);
		if leftSortVal > rightSortVal
			tmp = tree.right;
			tree.right = tree.left;
			tree.left = tmp;
		end
		rootSortVal = min(leftSortVal,rightSortVal);
	end
end

function [tree, nonLeafNodeCount] = numberNonLeaves(tree,numLeaves,nodeIndexField,nonLeafNodeCount)	
	% assumes that nodeIndex was already set for leaves (using numberLeaves())
	if nargin < 4
		nonLeafNodeCount = 0;
	end
	
	if tree.isLeaf
		% do nothing
	else
		[tree.left,nonLeafNodeCount] = numberNonLeaves(tree.left,numLeaves,nodeIndexField,nonLeafNodeCount);
		[tree.right,nonLeafNodeCount] = numberNonLeaves(tree.right,numLeaves,nodeIndexField,nonLeafNodeCount);
		nonLeafNodeCount = nonLeafNodeCount + 1;
		tree.value.(nodeIndexField) = numLeaves + nonLeafNodeCount;
	end

end

function linkageTree = storeLinkages(tree,numLeaves,valueFields,nodeIndexField,linkageTree)
	if tree.isLeaf
		% do nothing
	else
		linkageTree(tree.value.(nodeIndexField)- numLeaves,1) = tree.left.value.(nodeIndexField);
		linkageTree(tree.value.(nodeIndexField) - numLeaves,2) = tree.right.value.(nodeIndexField);
		if ~isempty(valueFields)
			linkageTree(tree.value.(nodeIndexField) - numLeaves,3:end) = c_struct_mapToArray(tree.value,valueFields);
		end
		linkageTree = storeLinkages(tree.left,numLeaves,valueFields,nodeIndexField,linkageTree);
		linkageTree = storeLinkages(tree.right,numLeaves,valueFields,nodeIndexField,linkageTree);
	end
end

	
function testfn()
	dataToCluster = rand(10,3);
	numClusters = 5;
	T = linkage(dataToCluster);
	figure; dendrogram(T);
	if 1
		dists = pdist(dataToCluster,'euclidean');
		leafOrder = optimalleaforder(T,dists);
	else
		leafOrder = 1:(size(T,1)+1);
	end
	origTree = c_bintree_constructFromLinkageTree(T); 
	% re-number in optimal leaf order
	tree = c_bintree_remapNodeValues(origTree,'linkageIndex',...
		'map_origValues',leafOrder,...
		'map_newValues',1:length(leafOrder),...
		'nodeSet','leaves',...
		'copyOriginalValuesToField','dataIndex');
	renumberedTree = tree;
	% merge nodes to obtain desired number of clusters
	tree = c_bintree_agglomerate(tree,numClusters,...
		'sortField','linkageDistance',...
		'collectLeafFields',{'dataIndex'}); 
	clusteredTree = tree;
	To = c_bintree_exportLinkageTree(origTree,...
		'leafIndexField','linkageIndex',...
		'valueFields',{'linkageDistance'});
	Tr = c_bintree_exportLinkageTree(renumberedTree,...
		'leafIndexField','linkageIndex',...
		'valueFields',{'linkageDistance'});
	Tc = c_bintree_exportLinkageTree(clusteredTree,...
		'valueFields',{'linkageDistance'},...
		'leafIndexField','clusterNumber');
	
	figure; dendrogram(To);
	figure; dendrogram(Tr);
	figure; dendrogram(Tc);
	c_fig_arrange('tile')
	
	keyboard
end
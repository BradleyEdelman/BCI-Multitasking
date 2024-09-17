function tree = c_bintree_constructFromLinkageTree(linkageTree,rootIndex)

	if nargin == 0, testfn(); return; end;

	persistent recursionLevel;
	if isempty(recursionLevel)
		recursionLevel = 1;
	else
		recursionLevel = recursionLevel + 1;
	end

	numLeaves = size(linkageTree,1) + 1;
	numInteriorNodes = numLeaves - 1;
	
	if nargin < 2
		rootMatIndex = numInteriorNodes;
		rootCluIndex = matrixIndexToClusterIndex(numInteriorNodes,numLeaves);
	else
		rootCluIndex = rootIndex;
		rootMatIndex = clusterIndexToMatrixIndex(rootCluIndex, numLeaves);
		if rootCluIndex <= numLeaves
			% reached leaf node, nothing below here
			recursionLevel = recursionLevel - 1;
			tree = struct('left',[],'right',[],'value',struct('linkageIndex',rootCluIndex,'linkageDistance',NaN),'isLeaf',true);
			return;
		end
		
	end
	
	leftCluIndex = linkageTree(rootMatIndex,1);
	rightCluIndex = linkageTree(rootMatIndex,2);
	rootValue = linkageTree(rootMatIndex,3);
	
	leftTree = c_bintree_constructFromLinkageTree(linkageTree,leftCluIndex);
	rightTree = c_bintree_constructFromLinkageTree(linkageTree,rightCluIndex);
	
	tree = struct();
	tree.left = leftTree;
	tree.right = rightTree;
	%tree.rootLabel = sprintf('(%s %s)',tree.left.rootLabel, tree.right.rootLabel);
	tree.value = struct('linkageIndex',rootCluIndex,'linkageDistance',rootValue);
	tree.isLeaf = false;
	
	recursionLevel = recursionLevel - 1;
end


function ind = clusterIndexToMatrixIndex(ind,numLeaves)
	ind = ind - numLeaves;
end

function ind = matrixIndexToClusterIndex(ind,numLeaves)
	ind = ind + numLeaves;
end

function testfn()
	testTree = linkage(rand(10,3));
	figure; dendrogram(testTree);
	tree = c_bintree_constructFromLinkageTree(testTree)
	keyboard
end
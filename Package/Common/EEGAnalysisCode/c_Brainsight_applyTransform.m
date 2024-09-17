function Brainsight = c_Brainsight_applyTransform(varargin)
% apply a spatial transform to all the points and orientations inside a loaded Brainsight struct
p = inputParser();
p.addRequired('Brainsight',@isstruct);
p.addRequired('Transform',@ismatrix);
p.addParameter('NewCoordinateSystem','',@ischar);
p.parse(varargin{:});
s = p.Results;
B = p.Results.Brainsight;
transf = p.Results.Transform;

%TODO: add check to see if transf is identity, and if so, return immediately without modifying Brainsight struct

assert(c_quaternionTransformationIsRigid(transf));

fieldsToModify = {'targets','samples','planLandmarks','sessLandmarks','landmarks'};
for iF = 1:length(fieldsToModify)
	if ~c_isFieldAndNonEmpty(B,fieldsToModify{iF})
		continue;
	end
	
	numNonRigid = 0;
	c_say('Working on field %s',fieldsToModify{iF}); %TODO: debug, delete
	
	% (use "samples" to represent, samples, targets, or landmarks)
	numSamples = length(B.(fieldsToModify{iF}));
	mandatoryFields = {'Loc_X','Loc_Y','Loc_Z'};
	orientationFields = {'m0n0','m0n1','m0n2','m1n0','m1n1','m1n2','m2n0','m2n1','m2n2'};
	if any(~ismember(mandatoryFields,fieldnames(B.(fieldsToModify{iF}))))
		error('Missing mandatory fields');
	end
	if any(ismember(orientationFields,fieldnames(B.(fieldsToModify{iF}))))
		% if any orientation fields are specified, all should be specified
		assert(all(ismember(orientationFields,fieldnames(B.(fieldsToModify{iF})))));
		isOrientation = true;
	else
		isOrientation = false;
	end
		
	for iS = 1:numSamples
		sample = B.(fieldsToModify{iF})(iS);
		if ~isOrientation
			fieldMap = {'Loc_X','Loc_Y','Loc_Z'};
			pt = c_struct_mapToArray(sample,fieldMap);
			pt = c_pts_applyQuaternionTransformation(pt,transf);
			sample = c_array_mapToStruct(pt,fieldMap);
		else
			fieldMap = {...
				'm0n0','m1n0','m2n0','Loc_X';
				'm0n1','m1n1','m2n1','Loc_Y';
				'm0n2','m1n2','m2n2','Loc_Z'};
% 			fieldMap = {...
% 				'm0n0','m0n1','m0n2','Loc_X';
% 				'm1n0','m1n1','m1n2','Loc_Y';
% 				'm2n0','m2n1','m2n2','Loc_Z'};
			or = c_struct_mapToArray(sample,fieldMap);
			or = cat(1,or,[0 0 0 1]); % add bottom row of constants
			isRigid = c_quaternionTransformationIsRigid(or,...
				'relativeErrorThreshold',0.1,...
				'actionIfFalse','print',...
				'testPointScalar',1); %TODO: debug, delete
			if ~isRigid, numNonRigid = numNonRigid+1; end;
			%if ~isRigid, keyboard; end;
			%assert(isRigid);
			or = transf*or;
			%assert(c_quaternionTransformationIsRigid(or)); %TODO: debug, delete
			or = or(1:3,:); % remove bottom row of constants
			sample = c_array_mapToStruct(or,fieldMap);	
		end
		% copy modified fields back into B struct
		%  assume that any field in the original sample that was not removed should stay in, but just not be changed
		%  (e.g. other metadata that is not a coordinate which was not affected by spatial transformation)
		fieldsToCopy = fields(sample);
		for iSF = 1:length(fieldsToCopy)
			B.(fieldsToModify{iF})(iS).(fieldsToCopy{iSF}) = sample.(fieldsToCopy{iSF});
		end
	end
	
	c_sayDone('%d/%d non-rigid',numNonRigid,numSamples);
end

if ~isempty(s.NewCoordinateSystem)
	B.coordinateSystem = s.NewCoordinateSystem;
end
		
Brainsight = B;
		
end




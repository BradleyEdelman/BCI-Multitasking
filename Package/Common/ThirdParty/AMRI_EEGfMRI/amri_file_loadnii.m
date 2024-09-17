%% 
% amri_file_loadnii() - load nifti-formatted data (from a single .nii file 
%                       or a pair of .hdr and .img files)
%
% Usage
%  nii = amri_file_loadnii(fname);
%  nii = amri_file_loadnii(fname,'headeronly',1);
%
% Inputs:
%  fname: filename with extension
%
% See also:
%  amri_file_savenii, amri_nifti_def
%  
% Version:
%   1.05
%
% Examples:
%   nii = amri_file_loadnii('func.nii');   % load from a .nii file
%   nii = amri_file_loadnii('func.hdr');   % load from .hdr and .img files
%   nii = amri_file_loadnii('func.img');   % load from .hdr and .img files
% 
% Reference:
%   http://nifti.nimh.nih.gov/nifti-1

%% DISCLAIMER AND CONDITIONS FOR USE:
%     Use of this software is at the user's OWN RISK. Functionality
%     is not guaranteed by creator nor modifier(s), if any.
%     This software may be freely copied and distributed. The original 
%     header MUST stay part of the file and modifications MUST be
%     reported in the 'MODIFICATION HISTORY'-field, including the
%     modification date and the name of the modifier.
%
% CREATED:
%     Apr. 6, 2010
%     Zhongming Liu, PhD
%     Advanced MRI, NINDS, NIH

%% History
% 1.00 - 04/06/2010 - ZMLIU - Create the file
% 1.01 - 04/14/2010 - ZMLIU - remove temporary files generated 
% 1.02 - 09/27/2010 - ZMLIU - update some code format
% 1.03 - 04/14/2011 - ZMLIU - fix a bug when reading a .nii file
% 1.04 - 04/18/2011 - ZMLIU - remove leading and tailing spaces from fname
%                           - check if file exists at beginning
% 1.05 - 02/03/2012 - ZMLIU - fix a bug when reading .hdr/.img file

function nii = amri_file_loadnii(fname,varargin)

if nargin<1
    eval('help amri_file_loadnii');
    return
end


% default keyword values
headeronly    = false;

if (nargin> 1 && rem(nargin,2) == 0)
    fprintf('amri_file_loadnii(): Odd number of input arguments???\n')
    return
end

% check keywords
for i = 1:2:size(varargin,2)
    Keyword = varargin{i};
    Value = varargin{i+1};
    if ~ischar(Keyword)
        fprintf('amri_file_loadnii(): keywords must be strings\n'); 
        return
    end
    if strcmpi(Keyword,'headeronly')
        headeronly = (Value>=1);
%     elseif strcmpi(Keyword,'machineformat') || ...
%            strcmpi(Keyword,'machine')
%         machineformat = Value;
    end
end

% *****************************************************************
% Check if it is GZipped nii file. 
% If the input file name has an extension of '.gz', then think of it as a
% GZipped nii file. First decompress it and save the decompressed file 
% stored in system temporary folder (e.g. /tmp/ for unix/linux)
% Then, read this temporary file instead. 
% ******************************************************************
fname = strtrim(fname);
if ~exist(fname,'file')
    fprintf(['amri_file_loadnii(): ' fname ' does not exist\n']);
    nii = nan;
    return
end
[junk.pathstr, junk.name, junk.ext] = fileparts(fname);
if strcmpi(junk.ext,'.gz')
    % if compressed nifti (nii.gz), 
    % decompress it and save it as a tmp file 
    os = getenv('OS');
    if strcmpi(os,'Linux') || strcmpi(os,'Unix')
        tmp_fname = [tempname '_' junk.name];
        system(['gzip -d -c ' fname ' > ' tmp_fname]);
        fname = tmp_fname;
    else
        fprintf(['amri_file_loadnii(): *.nii.gz is not supported in ' os '\n']);
        return
    end
    [junk.pathstr, junk.name, junk.ext] = fileparts(fname);
end

% *****************************************************************
% check if the input file is a pair of .hdr and .img, or a single .nii file
% by looking at the extension of the input file
% ******************************************************************
[junk.pathstr, junk.name, junk.ext] = fileparts(fname);
if strcmpi(junk.ext,'.nii')
    fname_hdr = fname;
    fname_img = fname;
    dual=false;
elseif strcmpi(junk.ext,'.hdr')
    fname_hdr = fname;
    fname_img = fullfile(junk.pathstr,[junk.name '.img']);
    dual=true;
elseif strcmpi(junk.ext,'.img')
    fname_hdr = fullfile(junk.pathstr,[junk.name '.hdr']);
    fname_img = fname;
    dual=true;
else
    fprintf('amri_file_loadnii(): file not recognized\n');
    return
end
clear junk;

% ******************************************************************
% Open the header file with appropriate machineformat 
% by checking if dim[0] is within the range 1..7
% ******************************************************************
machineformat = 'ieee-le';
fid = fopen(fname_hdr,'r',machineformat);
if (fid<0)
    fprintf(['amri_file_loadnii(): ' fname_hdr ' cannot be open\n']);
end

fseek(fid,40,'bof');
dim=fread(fid,[1 8],'int16');
if dim(1)<1 || dim(1)>7
    fclose(fid);
    switch machineformat,
        case 'ieee-le', machineformat='ieee-be';
        case 'ieee-be', machineformat='ieee-le';
    end
    fid = fopen(fname_hdr,'r',machineformat);
end

% ******************************************************************
% Check the magic word and the consistency with file extensions (dual)
% ******************************************************************
fseek(fid,344,'bof');
magic = deblank(fread(fid,[1 4],'*char*1'));
if strcmpi(magic,'n+1') && dual
    fprintf('amri_file_loadnii(): hdr expects one .nii file instead of a pair of .hdr/.img files\n');
    return
elseif strcmpi(magic,'ni1') && ~dual
    fprintf('amri_file_loadnii(): hdr expects a pair of .hdr/.img files instead of one .nii file\n');
    return
end
        
% ******************************************************************
% read header
% ******************************************************************
fseek(fid,0,'bof');
nii.hdr = read_nifti1_header(fid);

% ******************************************************************
% read extended header if any
% ******************************************************************
nii.ext.extension=[0 0 0 0];
nii.ext.esize=0;
nii.ext.ecode=0;
nii.ext.edata='';
if ~feof(fid)
    nii.ext.extension=fread(fid,[1 4],'uchar');
    if ~isempty(nii.ext.extension)
        if nii.ext.extension(1) ~= 0
            nii.ext.esize=fread(fid,1,'int32');
            nii.ext.ecode=fread(fid,1,'int32');
            nii.ext.edata=fread(fid,[1 nii.ext.esize-8],'*char*1');
        end
    end
    fclose(fid);
else
    fclose(fid);
end

if headeronly
    if exist('tmp_fname','var')
        delete(tmp_fname);
    end
    return
end

% ******************************************************************
% read data
% ******************************************************************
fid = fopen(fname_img,'r',machineformat);
if dual
    fseek(fid,nii.hdr.vox_offset,'bof');
else
    fseek(fid,max([352 nii.hdr.vox_offset]),'bof');
end
nii.img = read_nifti1_image(fid,nii.hdr);
fclose(fid);

% ******************************************************************
% clear tmp file if exist
% ******************************************************************
if exist('tmp_fname','var')
    if exist(tmp_fname,'file')
        delete(tmp_fname);
    end
end

return

function hdr = read_nifti1_header(fid)

% reader nifti 1 header information
hdr.sizeof_hdr    = fread(fid,1,'*int32');           % MUST be 348
hdr.data_type     = fread(fid,[1 10],'*char*1');     % Unused
hdr.db_name       = fread(fid,[1 18],'*char*1');     % Unused
hdr.extents       = fread(fid,1,'*int32');           % Unused
hdr.session_error = fread(fid,1,'*int16');           % Unused
hdr.regular       = fread(fid, 1,'*char*1');         % Unused
hdr.dim_info      = fread(fid, 1,'*uchar')';         % Unused

hdr.dim           = fread(fid,[1 8],'*int16');       % Data array dimensions
hdr.intent_p1     = fread(fid,1,'*float32')';        % 1st intent parameter
hdr.intent_p2     = fread(fid,1,'*float32')';        % 2nd intent parameter
hdr.intent_p3     = fread(fid,1,'*float32')';        % 3rd intent parameter
hdr.intent_code   = fread(fid,1,'*int16');           % NIFTI_INTENT_* code
hdr.datatype      = fread(fid,1,'*int16');           % Defines data type
hdr.bitpix        = fread(fid,1,'*int16');           % Number bits/voxel
hdr.slice_start   = fread(fid,1,'*int16');           % First slice index
hdr.pixdim        = fread(fid,[1 8],'*float32');     % Grid spacings
hdr.vox_offset    = fread(fid,1,'*float32');         % Offset into .nii file
hdr.scl_slope     = fread(fid,1,'*float32');         % Data scaling: slope
hdr.scl_inter     = fread(fid,1,'*float32');         % Data scaling: offset
hdr.slice_end     = fread(fid,1,'*int16');           % Last slice index
hdr.slice_code    = fread(fid,1,'*uchar');           % Slice timing order
hdr.xyzt_units    = fread(fid,1,'*uchar');           % Units of pixdim[1..4]
hdr.cal_max       = fread(fid,1,'*float32');         % Max display intensity
hdr.cal_min       = fread(fid,1,'*float32');         % Min display intensity
hdr.slice_duration= fread(fid,1,'*float32');         % Time for 1 slice
hdr.toffset       = fread(fid,1,'*float32');         % Time axis shift
hdr.glmax         = fread(fid,1,'*int32')';          % Unused
hdr.glmin         = fread(fid,1,'*int32')';          % Unused

hdr.descrip       = fread(fid,[1 80],'*char*1');     % any text you like
hdr.aux_file      = fread(fid,[1 24],'*char*1');     % auxiliary filename
hdr.qform_code    = fread(fid,1,'*int16');           % NIFTI_XFORM_* code
hdr.sform_code    = fread(fid,1,'*int16');           % NIFTI_XFORM_* code
hdr.quatern_b     = fread(fid,1,'*float32');         % Quaternion b param
hdr.quatern_c     = fread(fid,1,'*float32');         % Quaternion c param
hdr.quatern_d     = fread(fid,1,'*float32');         % Quaternion d param
hdr.qoffset_x     = fread(fid,1,'*float32');         % Quaternion x shift
hdr.qoffset_y     = fread(fid,1,'*float32');         % Quaternion y shift
hdr.qoffset_z     = fread(fid,1,'*float32');         % Quaternion z shift
hdr.srow_x        = fread(fid,[1 4],'*float32');     % 1st row affine transform
hdr.srow_y        = fread(fid,[1 4],'*float32');     % 2nd row affine transform
hdr.srow_z        = fread(fid,[1 4],'*float32');     % 3rd row affine transform
hdr.intent_name   = fread(fid,[1 16],'*char*1');     % 'name' or meaning of data
hdr.magic         = fread(fid,[1 4],'*char*1');      % MUST be "ni1\0" or "n+1\0"

hdr.data_type     = deblank(hdr.data_type);
hdr.db_name       = deblank(hdr.db_name);
hdr.descrip       = deblank(hdr.descrip);
hdr.aux_file      = deblank(hdr.aux_file);
hdr.intent_name   = deblank(hdr.intent_name);
hdr.magic         = deblank(hdr.magic);

return

function img = read_nifti1_image(fid,hdr)

NIFTIDEF = amri_nifti_def;

switch hdr.datatype,
    case NIFTIDEF.DT.BINARY,         precision='ubit1';
    case NIFTIDEF.DT.UINT8,          precision='uchar';
    case NIFTIDEF.DT.INT16,          precision='int16';
    case NIFTIDEF.DT.INT32,          precision='int32';
    case NIFTIDEF.DT.FLOAT,          precision='float32';
    case NIFTIDEF.DT.COMPLEX64,      precision='complex64';  % not supported in matlab, need special care
    case NIFTIDEF.DT.FLOAT64,        precision='float64';
    case NIFTIDEF.DT.RGB24,          precision='rgb24';      % not supported in matlab, need special care
    case NIFTIDEF.DT.INT8,           precision='schar';
    case NIFTIDEF.DT.UINT16,         precision='uint16';
    case NIFTIDEF.DT.UINT32,         precision='uint32';
    case NIFTIDEF.DT.INT64,          precision='int64';
    case NIFTIDEF.DT.UINT64,         precision='uint64';
    case NIFTIDEF.DT.FLOAT128,       precision='float128';  % not supported in matlab, need special care
    case NIFTIDEF.DT.COMPLEX128,     precision='complex128';% not supported in matlab, need special care
    case NIFTIDEF.DT.COMPLEX256,     precision='complex256';% not supported in matlab, need special care
    case NIFTIDEF.DT.RGBA32,         precision='rgba32';    % not supported in matlab, need special care
    otherwise 
        fprintf('amri_file_loadnii(): unknown datatype, quit without reading data \n');
end

if strncmpi(precision,'complex',7)
    % todo...
elseif strncmpi(precision,'rgb',3)
    % todo...
elseif strcmpi(precision,'float128')
    % todo...
else
    img=fread(fid,inf,['*' precision]);
end
% truncate the data to fit the dimension specified in hdr
imgsize=prod(double(hdr.dim(2:hdr.dim(1)+1)));
if length(img)>imgsize
    img=img(1:imgsize);
end
img = reshape(img,hdr.dim(2:hdr.dim(1)+1));

return

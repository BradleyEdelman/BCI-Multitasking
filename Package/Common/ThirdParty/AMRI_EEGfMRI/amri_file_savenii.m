%% 
% amri_file_savenii() - save nifti-formatted data (as a single .nii file or 
%                       a pair of .hdr and .img files)
%
% Usage
%  amri_file_savenii(nii,fname);
%  [fname_hdr,fname_img]=amri_file_savenii(nii,fname);
%
% Inputs:
%  nii:   NIFTI struct
%  fname: filename with extension (.nii,.hdr,.img) or without
%
% Outputs:
%  fname_hdr: hdr file being saved (optional)
%  fname_img: img file being saved (optional) 
%
% See also:
%  amri_file_loadnii, amri_nifti_def
%  
% Version:
%   1.02
%
% Examples:
%   amri_file_savenii(nii,'func.nii');     % save as a .nii file
%   amri_file_savenii(nii,'func.hdr');     % save as .hdr and .img files
%   amri_file_savenii(nii,'func.img');     % save as .hdr and .img files
%   amri_file_savenii(nii,'func');         % save as a .nii file if "magic" word is 'n+1' 
%                                          % or as .hdr and .img files if "magic" word is 'ni1'
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
%     Apr. 8, 2010
%     Zhongming Liu, PhD
%     Advanced MRI, NINDS, NIH

%% History
% 1.00 - 04/08/2010 - ZMLIU - Create the file
% 1.01 - 04/13/2010 - ZMLIU - Allow to save as .nii.gz file
% 1.02 - 09/27/2010 - ZMLIU - update some code format

function [fname_hdr,fname_img]=amri_file_savenii(nii,fname)

if nargin<1
    eval('help amri_file_savenii');
    return
end

[junk.pathstr, junk.name, junk.ext] = fileparts(fname);
if strcmpi(deblank(junk.ext),'.nii')
    fname_hdr = fname;
    fname_img = fname;
    dual=false;
    if strcmpi(deblank(nii.hdr.magic),'ni1')
        nii.hdr.vox_offset=352;
        if isfield(nii.ext,'esize')
            nii.hdr.vox_offset=nii.hdr.vox_offset+nii.ext.esize;
        end
    end
    nii.hdr.magic='n+1';
elseif strcmpi(deblank(junk.ext),'.hdr')
    fname_hdr = fname;
    fname_img = fullfile(junk.pathstr,[junk.name '.img']);
    dual=true;
    nii.hdr.magic='ni1';
    nii.hdr.vox_offset=0;
elseif strcmpi(deblank(junk.ext),'.img')
    fname_hdr = fullfile(junk.pathstr,[junk.name '.hdr']);
    fname_img = fname;
    dual=true;
    nii.hdr.magic='ni1';
    nii.hdr.vox_offset=0;
elseif isempty(deblank(junk.ext))
    if strcmpi(deblank(nii.hdr.magic),'n+1')
        fname_hdr = [fname '.nii'];
        fname_img = [fname '.nii'];
        dual=false;
    elseif strcmpi(deblank(nii.hdr.magic),'ni1')
        fname_hdr = [fname '.hdr'];
        fname_img = [fname '.img'];
        dual=true;
        nii.hdr.vox_offset=0;
    else 
        fname_hdr = [fname '.nii'];
        fname_img = [fname '.nii'];
        nii.hdr.magic='n+1';
        dual=false;
    end    
elseif strcmpi(deblank(junk.ext),'.gz')   
    os = getenv('OS');
    if ~strcmpi(os,'Linux') && ~strcmpi(os,'Unix')
        fprintf(['amri_file_savenii(): *.gz is not supported in ' os '\n']);
        return
    end
    fname=fullfile(junk.pathstr,junk.name);
    [fname_hdr,fname_img]=amri_file_savenii(nii,fname);
    if ~strcmpi(fname_hdr,fname_img)
        system(['gzip -c -f ' fname_hdr ' > ' fname_hdr '.gz']);
        system(['gzip -c -f ' fname_img ' > ' fname_img '.gz']);
        system(['rm ' fname_hdr ' -f']);
        system(['rm ' fname_img ' -f']);
        fname_hdr = [fname_hdr '.gz'];
        fname_img = [fname_img '.gz'];
    else
    	system(['gzip -c -f ' fname_hdr ' > ' fname_hdr '.gz']);
        system(['rm ' fname_hdr ' -f']);
        fname_hdr = [fname_hdr '.gz'];
        fname_img = fname_hdr;
    end
    return
else
    fprintf('amri_file_savenii(): file not recognized\n');
    return
end
clear junk;

% ******************************************************************
% write header
% ******************************************************************
machineformat = 'native';
fid = fopen(fname_hdr,'w+',machineformat);
fseek(fid,0,'bof');
write_nifti_header(fid,nii.hdr);
fwrite(fid,nii.ext.extension,'uchar');
if nii.ext.extension(1)~=0
    fwrite(fid,nii.ext.esize,'int32');
    fwrite(fid,nii.ext.ecode,'int32');
    edata = addblank(nii.ext.edata,nii.ext.esize-8);
    fwrite(fid,edata,'char*1');
    fclose(fid);
else
    fclose(fid);
end

% ******************************************************************
% write data
% ******************************************************************
if dual
    fid = fopen(fname_img,'w',machineformat);
    vox_offset=max([0 nii.hdr.vox_offset]);
    junk=uint8(zeros(1,vox_offset));
    fwrite(fid,junk,'uint8');
    fseek(fid,vox_offset,'bof');
else
    fid = fopen(fname_img,'a+',machineformat);
    vox_offset = max([352 nii.hdr.vox_offset]);
    fseek(fid,0,'eof');
    if ftell(fid)<vox_offset
        junk=uint8(zeros(1,max([0 vox_offset-ftell(fid)])));
        fwrite(fid,junk,'uchar');
        fseek(fid,vox_offset,'bof');
    end
end
write_nifti_image(fid,nii.hdr,nii.img);
fclose(fid);


function write_nifti_header(fid,hdr)

hdr.data_type   = addblank(hdr.data_type,10);
hdr.db_name     = addblank(hdr.db_name,18);
hdr.descrip     = addblank(hdr.descrip,80);
hdr.aux_file    = addblank(hdr.aux_file,24);
hdr.intent_name = addblank(hdr.intent_name,16);
hdr.magic       = addblank(hdr.magic,4);
fseek(fid,0,'bof');
fwrite(fid,hdr.sizeof_hdr,'int32');
fwrite(fid,hdr.data_type,'char*1');
fwrite(fid,hdr.db_name,'char*1');
fwrite(fid,hdr.extents,'int32');
fwrite(fid,hdr.session_error,'int16');
fwrite(fid,hdr.regular,'char*1');
fwrite(fid,hdr.dim_info,'uchar');

fwrite(fid,hdr.dim,'int16');
fwrite(fid,hdr.intent_p1,'float32');
fwrite(fid,hdr.intent_p2,'float32');
fwrite(fid,hdr.intent_p3,'float32');
fwrite(fid,hdr.intent_code,'int16');
fwrite(fid,hdr.datatype,'int16');
fwrite(fid,hdr.bitpix,'int16');
fwrite(fid,hdr.slice_start,'int16');
fwrite(fid,hdr.pixdim,'float32');
fwrite(fid,hdr.vox_offset,'float32');
fwrite(fid,hdr.scl_slope,'float32');
fwrite(fid,hdr.scl_inter,'float32');
fwrite(fid,hdr.slice_end,'int16');
fwrite(fid,hdr.slice_code,'uchar');
fwrite(fid,hdr.xyzt_units,'uchar');
fwrite(fid,hdr.cal_max,'float32');
fwrite(fid,hdr.cal_min,'float32');
fwrite(fid,hdr.slice_duration,'float32');
fwrite(fid,hdr.toffset,'float32');
fwrite(fid,hdr.glmax,'int32');
fwrite(fid,hdr.glmin,'int32');

fwrite(fid,hdr.descrip,'char*1');
fwrite(fid,hdr.aux_file,'char*1');
fwrite(fid,hdr.qform_code,'int16');
fwrite(fid,hdr.sform_code,'int16');
fwrite(fid,hdr.quatern_b,'float32');
fwrite(fid,hdr.quatern_c,'float32');
fwrite(fid,hdr.quatern_d,'float32');
fwrite(fid,hdr.qoffset_x,'float32');
fwrite(fid,hdr.qoffset_y,'float32');
fwrite(fid,hdr.qoffset_z,'float32');
fwrite(fid,hdr.srow_x,'float32');
fwrite(fid,hdr.srow_y,'float32');
fwrite(fid,hdr.srow_z,'float32');
fwrite(fid,hdr.intent_name,'char*1');
fwrite(fid,hdr.magic,'char*1');

function write_nifti_image(fid,hdr,img)
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
        fprintf('amri_file_savenii(): unknown datatype, quit without reading data \n');
end
if strncmpi(precision,'complex',7)
    % todo...
elseif strncmpi(precision,'rgb',3)
    % todo...
elseif strcmpi(precision,'float128')
    % todo...
else
    fwrite(fid,img,precision);
end

function newstr = addblank(str,len)
newstr = [str char(zeros(1,max([0 len-length(str)])))];

























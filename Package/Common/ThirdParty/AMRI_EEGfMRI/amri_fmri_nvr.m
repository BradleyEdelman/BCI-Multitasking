%%   
% amri_fmri_nvr() - Nuisance Variable Analysis (NVR). 
%	            Regress out the time series of no interest from the input fMRI data.
%
% Usage:
%   odata = amri_fmri_nvr(idata,nv)
%
% Inputs
%   idata: 4d matrix [dimx,dimy,dimz,dimt]
%      nv: 2d matrix [dimt,nrofnv]
%
% Output
%   odata: 4d matrix [dimx,dimy,dimz,dimt]
%
% See also
%   amri_sig_nvr
%
% Version:
%   0.07

%% DISCLAIMER AND CONDITIONS FOR USE:
%     Use of this software is at the user's OWN RISK. Functionality
%     is not guaranteed by creator nor modifier(s), if any.
%     This software may be freely copied and distributed. The original 
%     header MUST stay part of the file and modifications MUST be
%     reported in the 'MODIFICATION HISTORY'-field, including the
%     modification date and the name of the modifier.
%
% CREATED:
%     Mar. 13, 2010
%     Zhongming Liu, PhD
%     Advanced MRI, NINDS, NIH

%% MODIFICATION HISTORY
% 0.00 - 03/13/2010 - ZMLIU - run multiple regression using '\'
% 0.01 - 04/13/2010 - ZMLIU - rename as amri_fmri_nvr.m
% 0.02 - 06/21/2010 - ZMLIU - check whether size(nv,2)==size(data,4)
% 0.03 - 06/22/2010 - ZMLIU - normalize each regressor
% 0.04 - 06/23/2010 - ZMLIU - call amri_sig_nvr instead
% 0.05 - 06/23/2010 - ZMLIU - skip zero-intensity voxels to speed up
% 0.06 - 04/19/2010 - ZMLIU - return original data anything when nvr is
%                           - empty or nan
% 0.07 - 02/14/2012 - ZMLIU - release this code

function odata = amri_fmri_nvr(idata, nv)

if nargin<1
    eval('help amri_fmri_nvr');
    return
end

if isnan(nv) 
    odata = idata;
    return
end 

if isempty(nv)
    odata = idata;
    return
end

if size(nv,1)~=size(idata,4)
    error('amri_fmri_nvr(): matrix dimesions do not mismatch');
end

[nx,ny,nz,nt] = size(idata);
idata = reshape(idata,nx*ny*nz,nt);
mask  = sum(abs(idata),2)>0;
odata = idata;
idata = idata(mask,:);

for i=1:size(idata,1)
    ts = idata(i,:)';
    ts = amri_sig_nvr(ts,nv);
    idata(i,:) = cast(ts',class(idata));
end

odata(mask,:) = idata;
odata = reshape(odata,nx,ny,nz,nt);




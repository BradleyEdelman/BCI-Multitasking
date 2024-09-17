%%   
% amri_sig_nvr() - Nuisance Variable Analysis (NVR). 
%	            Regress out the time series of no interest from a given
%	            time series
%
% Usage:
%   y = amri_sig_nvr(x,nv);
%   [y,p] = amri_sig_nvr(x,nv);
%
% Inputs:
%   x: 1-vector
%  nv: a matrix with each column representing a nuisance variable 
%
% Output:
%   y: 1-vector
%   p: regression coefficients
%
% Version:
%   0.07

%% History
% 0.00 - 06/23/2010 - ZMLIU - create the file
% 0.01 - 06/23/2010 - ZMLIU - allow parts of nv time series are nan
% 0.03 - 08/16/2010 - ZMLIU - ensure x and nv are double
% 0.04 - 08/17/2010 - ZMLIU - ensure x and nv are double in computation
% 0.05 - 04/19/2011 - ZMLIU - return y=x when nv is empty or nan
% 0.06 - 05/30/2011 - ZMLIU - remove constant column from nv
% 0.07 - 02/14/2012 - ZMLIU - release this code

function [y,p] = amri_sig_nvr(x,nv)

if nargin<1
    eval('help amri_sig_nvr');
    return
end

if isnan(nv)
    y=x;
    p=zeros(1,size(nv,2));
    return
end

if isempty(nv)
    y=x;
    p=zeros(1,size(nv,2));
    return
end

% remove constant columns in nv
isconstant=false(size(nv,2),1);
for i=1:size(nv,2)
    if std(nv(:,i))==0
        isconstant(i)=true;
    end    
end
nv(:,isconstant)=[];
    
% check the number of dimensions of the inputs
if ndims(nv)>2, error('not support nv of more than 2 dimensions'); end 
if ~isvector(x),error('not support x of more than 1 dimension'); end

if isvector(x)
    x=x(:);
end
if isvector(nv)
    nv=nv(:);
end

% store the original dimensional information
dim1 = size(x,1);
dim2 = size(x,2);

% transpose nv so that each column of it corresponds to the time series of a single nuisance variable
if size(nv,1)==length(x)
    % do nothing
elseif size(nv,2)==length(x)
    nv=nv';
else
    error('dimensional mismatch between x and nv');
end

valid = ~isnan(x);
% demean x
if any(~valid)
    mean_x = mean(x(~isnan(x))); 
else
    mean_x = mean(x);
end
x = x - mean_x;

% demean and normalize nv
for i =1:size(nv,2)
   tmp = ~isnan(nv(:,i));
   nv(tmp,i) = nv(tmp,i) - mean(nv(tmp,i));
   nv(tmp,i) = nv(tmp,i) / norm(nv(tmp,i));
   nv(~tmp,i) = 0;
   valid = valid & tmp;
end 

% run multiple regression and take the residual
p=double(nv(valid,:))\double(x(valid));
y=double(x)-double(nv)*p;

% add the mean back
y=y+mean_x;

% restore the original dimension
y = reshape(y,dim1,dim2);
% y = cast(y,old_class);

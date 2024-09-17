function [esi,varargout]=bci_ESI_ESI(action,esi,varargin)


nargs=nargin;
if nargs<2
else

    %% EXTRACT INPUT ARGS
    if ~(round((nargs-2)/2) == (nargs-2)/2)
        error('Odd number of input arguments??')
    end
    
    str=cell(0); val=cell(0);
    for i=1:2:length(varargin)
        str{end+1}=varargin{i};
        val{end+1}=varargin{i+1};
    end
    
    if strcmp(action,'initiate')
        %% INITIATE STIMULI
        if ~ismember('handles',str)
            error('Need handles to designate stimuli\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
            if isempty(flags)
                flags=struct;
            else
                v2struct(flags)
            end
        else
            flags=struct;
        end
        
        if isempty(esi)
            esi=struct;
        end
        flags.paradigm=get(handles.paradigm,'value');
        flags.spatdomainfield=handles.TRAINING.spatdomainfield;
        v2struct(flags)
        
        switch spatdomainfield
            case 'Sensor'
                
                
            case {'Source','SourceCluster'}

                noise=handles.ESI.noisetype;
                switch noise
                    case {1,2} % None or no noise estimation
                        noisefieldreal='nomodel';
                        noisefieldimag='nomodel';
                    case {3,4}
                        noisefieldreal='real';
                        noisefieldimag='imag';
                end

                switch spatdomainfield
                    case 'Source'
                        esi.invreal=handles.ESI.NOCLUSTER.inv.(noisefieldreal);
                        esi.invimag=handles.ESI.NOCLUSTER.inv.(noisefieldimag);
                        
                        vertidxinclude=handles.TRAINING.Source.param.vertidxinclude;
                        if isempty(vertidxinclude)
                            vertidxinclude=handles.ESI.vertidxinclude;
                        end
                        esi.vertidxinclude=vertidxinclude;
                        esi.numvert=numvert;
                    case 'SourceCluster'
                        esi.invreal=handles.ESI.CLUSTER.inv.(noisefieldreal);
                        esi.invimag=handles.ESI.CLUSTER.inv.(noisefieldimag);
                        esi.clusters=handles.ESI.CLUSTER.clusters;
                        
                        vertidxinclude=handles.TRAINING.Source.param.vertidxinclude;
                        if isempty(vertidxinclude)
                            vertidxinclude=handles.ESI.vertidxinclude;
                        end
                        esi.vertidxinclude=vertidxinclude;
                        esi.numvert=size(vertidxinclude,2);
                        
                        clusteridxinclude=handles.TRAINING.SourceCluster.SMR.param.clusteridxinclude;
                        if isempty(clusteridxinclude)
                            clusteridxinclude=handles.ESI.CLUSTER.clusters;
                        end
                        esi.clusteridxinclude=clusteridxinclude;
                        esi.numcluster=size(clusteridxinclude,2);
                end

        end
        
        varargout{1}=flags;
        
    elseif strcmp(action,'inverse')
        
        if ~ismember('flags',str)
            error('Need flags to perform source imaging\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        
        
        if ~ismember('data',str)
            error('Need data structure to preform source imaging\n');
        else
            data=val{strcmp(str,'data')};
        end
        v2struct(flags)
        v2struct(esi)
        
        Save.Sensor=squeeze(sum(abs(data),2))';
        switch spatdomainfield
            
            case 'Sensor'
                
                data=abs(data);
                
            case 'Source'
                
                for i=1:numfreq
                    Esourcefreq=data(i,:,:);
                    Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',numchan,[]);
                    Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',numchan,[]);

                    Jreal=invreal*Erealsourcefreq;
                    Jimag=invimag*Eimagsourcefreq;
                    Jtmp=complex(Jreal(vertidxinclude,:),Jimag(vertidxinclude,:))';
                    J(i,:,:)=reshape(Jtmp,1,size(EEG.data,2)-2*analysiswindowpaddingprocess,size(vertidxinclude,2));

                end
                J=abs(J);

                data=J;
                Save.Source=squeeze(sum(J,2))';
                
            case 'SourceCluster'
                
                for i=1:numfreq

                    Esourcefreq=data(i,:,:);
                    Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',numchan,[]);
                    Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',numchan,[]);

                    for j=1:numcluster
                        Jreal=sum(invreal{j}*Erealsourcefreq,1);
                        Jimag=sum(invimag{j}*Eimagsourcefreq,1);
                        J(i,:,j)=complex(Jreal,Jimag);
                    end

                end
                J=abs(J);

                data=J;
                Save.SourceCluster=squeeze(sum(J,2))';
                
        end
        
        varargout{1}=data;
        varargout{2}=Save;
        
    end
    
end 
        
        
        
        
function [trialidx,winner]=bci_ESI_SSVEPClass(handles,eeg,trialidx)

targets=handles.BCI.SSVEP.control.targets;
targetfreq=handles.BCI.SSVEP.control.targetfreq;
% % taskorder=handles.BCI.SSVEP.control.taskorder;

numtask=size(targets,1);

eeg=eeg.data;

feattype=handles.BCI.SSVEP.control.feattype;
switch feattype
    
    case 'CCA'
            
            refsig=handles.BCI.SSVEP.control.refsig;
            wx=cell(1,size(refsig,2));
            wy=cell(1,size(refsig,2));
            r=cell(1,size(refsig,2));
            Mtmp=zeros(1,size(refsig,2));
            for i=1:size(refsig,2)
                [wx{i},wy{i},r{i}]=bci_ESI_CCA(eeg,refsig{i});
                Mtmp(i)=max(r{i});
            end
            
            M=zeros(1,size(refsig,2)/3);
            for i=1:size(M,2)
                M(i)=max(Mtmp(1+3*(i-1):3+3*(i-1)));
            end
            
            numfreq=size(handles.BCI.SSVEP.control.freq,1);
            [v,idx]=max(M);
            if idx>numfreq
                idx=0;
            end
            
            winner=idx;
            
            
    case 'RLDA'

        t=1/handles.SYSTEM.dsfs:1/handles.SYSTEM.dsfs:size(eeg,2)/handles.SYSTEM.dsfs;
        for i=1:size(eeg,1)

            for j=1:numtask

                COS=dot(eeg(i,:),cos(2*pi*str2double(targetfreq(j))*t))^2;
                SIN=dot(eeg(i,:),sin(2*pi*str2double(targetfreq(j)))*t)^2;
                A=sqrt(COS+SIN);

                COS2=dot(eeg(i,:),cos(2*pi*2*str2double(targetfreq(j))*t))^2;
                SIN2=dot(eeg(i,:),sin(2*pi*2*str2double(targetfreq(j)))*t)^2;
                B=sqrt(COS2+SIN2);

                F(j+(i-1)*2*numtask)=A;
                F(j+numtask+(i-1)*2*numtask)=B;

            end

        end

        combinations=combnk(1:numtask,2);
        numcomb=size(combinations,1);

        % switch ssvepfeattype

        W=handles.BCI.SSVEP.control.w;
        W0=handles.BCI.SSVEP.control.w0;

        vote=zeros(1,numtask);
        for i=1:numcomb

            Wtmp=W(:,i);
            W0tmp=W0(i);

            DF=F*Wtmp+W0tmp;

            if DF>0
                vote(combinations(i,2))=vote(combinations(i,2))+1;
            elseif DF<0
                vote(combinations(i,1))=vote(combinations(i,1))+1;
            end

        end
        
        winner=find(vote==max(vote));

end

% % Record result and adjust stimulus
% performance{trialidx.result,1}=taskorder{trialidx.target};
% 
% if ~isequal(winner,0)
%     performance{trialidx.result,2}=targets{winner};
% else
%     performance{trialidx.result,2}='0';
% end
% 
% if strcmp(performance{trialidx.result,2},'0')
%     performance{trialidx.result,3}='Abort';
%     trialidx.result=trialidx.result+1;
% elseif strcmp(taskorder{trialidx.target},targets{winner})
%     performance{trialidx.result,3}='Hit';
%     trialidx.target=trialidx.target+1;
%     trialidx.result=trialidx.result+1;
% else
%     performance{trialidx.result,3}='Miss';
%     trialidx.result=trialidx.result+1;
% end
% % performance
% 
% stimidx=taskorder{trialidx.target};
% stimidx=find(strcmp(targets,stimidx));
% 
% stimtmp=handles.BCI.SSVEP.control.image{stimidx};
% 
% fftxplot=handles.BCI.SSVEP.fftx;
% targetfftx=handles.BCI.SSVEP.targetfftx;    
% set(stimulus.SSVEP.targH1,'Xdata',fftxplot(targetfftx(stimidx))*ones(1,2));    
% set(stimulus.SSVEP.targH2,'Xdata',2*fftxplot(targetfftx(stimidx))*ones(1,2));     
    
    
    
    
    
    
    
    
    
    
    
    
    
        
    
    
    


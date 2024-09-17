function [hObject,handles,dataout]=bci_ESI_SegmentBCI2000Data(hObject,handles,datain,taskinfo,trialstruct)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE SPATIAL DOMAIN
spatdomainfield=handles.TRAINING.spatdomainfield;
switch spatdomainfield
    case 'Sensor'
        chanidxinclude=handles.TRAINING.(spatdomainfield).param.chanidxinclude;
    case 'Source'
        chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
        vertidxinclude=handles.TRAINING.(spatdomainfield).param.vertidxinclude;
        noisetype=handles.ESI.noisetype;
        switch noisetype
            case {1,2}
                INVreal=handles.ESI.NOCLUSTER.nomodel;
                INVimag=handles.ESI.NOCLUSTER.nomodel;
            case {3,4}
                INVreal=handles.ESI.NOCLUSTER.real;
                INVimag=handles.ESI.NOCLUSTER.imag;
        end
    case 'SourceCluster'
        chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
        clusters=handles.ESI.CLUSTER.clusters;
        numcluster=size(clusters,2)-1;
%         clusteridxinclude=handles.TRAINING.(spatdomainfield).param.clusteridxinclude;
        noisetype=handles.ESI.noisetype;
        switch noisetype
            case {1,2}
                INVreal=handles.ESI.CLUSTER.nomodel;
                INVimag=handles.ESI.CLUSTER.nomodel;
            case {3,4}
                INVreal=handles.ESI.CLUSTER.real;
                INVimag=handles.ESI.CLUSTER.imag;
        end
end



% Data type
numfreq=size(handles.TRAINING.(spatdomainfield).param.mwparam.freqvect,2);
morwav=handles.TRAINING.(spatdomainfield).param.morwav;

analysiswindowprocess=round(handles.SYSTEM.analysiswindow/1000*handles.SYSTEM.dsfs);
updatewindowprocess=round(handles.SYSTEM.updatewindow/1000*handles.SYSTEM.dsfs);

a=handles.SYSTEM.filterds.a;
b=handles.SYSTEM.filterds.b;
dt=1/handles.SYSTEM.dsfs;


taskinfo(1,:)=[];

dataout.runbase=[];
dataout.base=cell(1,size(taskinfo,1));
dataout.trial=cell(1,size(taskinfo,1));
dataout.targetidx=cell2mat(taskinfo(:,2))';

tasktype=trialstruct.tasktype;
switch tasktype
    case 'Cursor'
        startidx=[3 4];
        endidx=[4 6];
    case 'Stimulus'
        startidx=[7 4];
        endidx=[8 5];
end
label={'base','trial'};

for i=1:size(taskinfo,1)
    
    for j=1:2
    
        sectiontartidx=cell2mat(taskinfo(i,startidx(j)));
        sectionendidx=cell2mat(taskinfo(i,endidx(j)));

        windowbegidx=sectiontartidx;
        windowendidx=windowbegidx+analysiswindowprocess-1;
        
        win=1;
        while windowendidx<sectionendidx

            datatmp=datain(:,windowbegidx:windowendidx);
            % Filter data
            datatmp=filtfilt(b,a,double(datatmp'));
            datatmp=datatmp';
            % Mean correct
            datatmp=datatmp-repmat(mean(datatmp,2),[1 size(datatmp,2)]);
            % Common average reference
            datatmp=datatmp-repmat(mean(datatmp,1),[size(datatmp,1),1]);

            Acomplex=zeros(numfreq,size(datatmp,2),size(datatmp,1));
            for k=1:size(datatmp,1)
                for l=1:numfreq
                    Acomplex(l,:,k)=conv2(datatmp(k,:),morwav{l},'same')*dt;
                end
            end

            switch spatdomainfield

                case 'Sensor'

                    E=abs(Acomplex);
                    for k=1:numfreq
                        Etmp=squeeze(E(k,:,:))';
                        dataout.(label{j}){win}{i}{k}=Etmp;
                    end
                    Etmp=squeeze(sum(E,1))';
                    dataout.(label{j}){win}{i}{numfreq+1}=Etmp;

                case 'Source'

                    J=zeros(numfreq,analysiswindowprocess,size(vertidxinclude,2));
                    for k=1:numfreq
                        Esourcefreq=Acomplex(k,:,:);
                        Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',size(chanidxinclude,1),[]);
                        Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',size(chanidxinclude,1),[]);

                        switch noisetype
                            case {1,2} % None or no noise estimation

                                Jreal=INVreal*Erealsourcefreq;
                                Jimag=INVimag*Eimagsourcefreq;
                                Jtmp=complex(Jreal(vertidxinclude,:),Jimag(vertidxinclude,:))';
                                J(k,:,:)=reshape(Jtmp,1,analysiswindowprocess,size(vertidxinclude,2));

                            case {3,4} % Diagonal or full noise covariance

                                Jreal=INVreal*Erealsourcefreq;
                                Jimag=INVimag*Eimagsourcefreq;
                                Jtmp=complex(Jreal(vertidxinclude,:),Jimag(vertidxinclude,:))';
                                J(k,:,:)=reshape(Jtmp,1,analysiswindowprocess,size(vertidxinclude,2));

                        end

                    end

                    J=abs(J);
                    for k=1:numfreq
                        Jtmp=squeeze(J(k,:,:))';
                        dataout.(label{j}){win}{i}{k}=Jtmp;
                    end
                    Jtmp=squeeze(sum(J,1))';
                    dataout.(label{j}){win}{i}{numfreq+1}=Jtmp;
                    
                case 'SourceCluster'

                    J=zeros(numfreq,analysiswindowprocess,numcluster);
                    for k=1:numfreq

                        Esourcefreq=Acomplex(j,:,:);
                        Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',size(chanidxinclude,1),[]);
                        Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',size(chanidxinclude,1),[]);

                        switch noisetype
                            case {1,2} % None or no noise estimation

                                for l=1:numcluster
                                    Jreal=sum(INVreal{l}*Erealsourcefreq,1);
                                    Jimag=sum(INVimag{l}*Eimagsourcefreq,1);
                                    J(k,:,l)=complex(Jreal,Jimag);
                                end

                            case {3,4} % Diagonal or full noise covariance

                                for l=1:numcluster
                                    Jreal=sum(INVreal{l}*Erealsourcefreq,1);
                                    Jimag=sum(INVimag{l}*Eimagsourcefreq,1);
                                    J(k,:,l)=complex(Jreal,Jimag);
                                end

                        end
                    end

                    J=abs(J);
                    for k=1:numfreq
                        Jtmp=squeeze(J(k,:,:))';
                        dataout.(label{j}){win}{i}{k}=Jtmp;
                    end
                    Jtmp=squeeze(sum(J,1))';
                    dataout.(label{j}){win}{i}{numfreq+1}=Jtmp;

            end

            windowbegidx=windowbegidx+updatewindowprocess;
            windowendidx=windowendidx+updatewindowprocess;
            win=win+1;
            
        end
    end
end

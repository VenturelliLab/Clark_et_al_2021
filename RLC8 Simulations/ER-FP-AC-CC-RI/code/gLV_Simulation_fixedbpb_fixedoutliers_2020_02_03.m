clear all, close all
%Important values to change
Tmax=48;
numspecies=25;
totalOD=0.0066;
bpbindices=[16,18,21,22,23];
but_parameters=csvread('2019_09_08_ButyrateModel_ALLBPB_10fcv.csv');
bpbvector(1:numspecies)=0;
for k=1:length(bpbindices)
    bpbvector(bpbindices(k))=1;
end
problemindices=[1,13,14,16,18,21,22,23,25]
problemvector(1:numspecies)=0;
for k=1:length(problemindices)
    problemvector(problemindices(k))=1;
end

%Create a matrix with the ensemble of parameters (each column is a
%different parameter set)
paramfiles=dir('2019_09_04_RLC8_posterior_KNN/param*');
ensemblesize=length(paramfiles);
ensemble(numspecies*(numspecies+1),ensemblesize)=0;
z=1;
for j=1:ensemblesize
    %Read in Parameters and store in ensemble matrix
    ensemble(:,j)=csvread(strcat('2019_09_04_RLC8_posterior_KNN/',paramfiles(j).name));
	z=z+1;
end

for communitysize=15
	mkdir(strcat(int2str(communitysize),'MemberComms/'));
	%Generate a matrix containing all possible combinations for a given
	%community size
	comms=nchoosek([1:15,17,19,20,24,25],communitysize-5);
	comms=[comms 16.*ones(size(comms,1),1) 18.*ones(size(comms,1),1) 21.*ones(size(comms,1),1) 22.*ones(size(comms,1),1) 23.*ones(size(comms,1),1)];
	comms=sort(comms,2);
	finished=dir(strcat(int2str(communitysize),'MemberComms/*.csv'));
	finished={finished.name};
	parfor k=1:size(comms,1)
		presentvector=ismember([1:25],comms(k,:));
		IC=(totalOD/communitysize)*presentvector;
		data=[]
		mystring='';
		for z=1:communitysize
			if size(mystring,1)==''
				mystring=strcat(mystring,int2str(comms(k,z)));
			else
				mystring=strcat(mystring,'_',int2str(comms(k,z)));
			end
		end
		if any(strcmp(finished,strcat(mystring,'.csv')))
			disp(strcat(mystring,' already finished'))
		else
			disp(k)
			tic
			for j=1:ensemblesize
				%Read in Parameters
				vector=ensemble(:,j);
				params=[];
				for q=1:numspecies
					params=[params vector((numspecies+1)*(q-1)+1:(numspecies+1)*q)];
				end
				output=runsim(presentvector,problemvector,Tmax, IC, params);
				if size(output)>0
					data=[data; output];
				end
			end
			[butyrate]=MakePrediction(data, but_parameters, presentvector);
			data=[data butyrate];
			data=data(data(:,26)<100,:); %Remove really large Butyrate values
			data(data<0)=0;
			for i=1:25
				data=data(data(:,i)<5,:); %Remove really large species abundances
			end
			dlmwrite(strcat(int2str(communitysize),'MemberComms/',mystring,'.csv'),[mean(data) median(data) std(data) prctile(data,5) prctile(data,20) prctile(data,80) prctile(data,95) size(data,1)],'delimiter',',');
			toc
		end
	end
end
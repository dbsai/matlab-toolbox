% Fast2Matlab
% Function for reading FAST input files in to a MATLAB struct.
%
%
%This function returns a structure DataOut, which contains 2 cell arrays,
%.Val: An array of values
%.Label: An array of matching labels
%.OutList: An array of variables to outputt
%These arrays are extracted from the FAST input file
%
% In:   FST_file    -   Name of FAST input file
%       hdrLines    -   Number of lines to skip at the top (optional)
%
% Knud A. Kragh, May 2011, NREL, Boulder
%
% Modfied by Paul Fleming, JUNE 2011

function DataOut = Fast2Matlab(FST_file,hdrLines)

if nargin < 2
    hdrLines = 0;
end

%----------------------Read FST main file----------------------------------
fid = fopen([FST_file],'r');
if fid == -1
    Flag = 0;
    error('FST file could not be found')
end

%skip hdr
for hi = 1:hdrLines
    fgets(fid);
end

%PF: Commenting this out, not sure it's necessary
%DataOut.Sections=0;

%Loop through the file line by line, looking for value-label pairs
%Stop once we've reached the OutList which this function is the last
%occuring thing before the EOF
count=1;


while true %loop until discovering Outlist, than brak
    fgets(fid); %Advanced to the next line
    skipLine = false; %reset skipline
    %Label=[]; %Re-initialize label  PF: Temp disabling this
    
    
    % Get the Value, number or string
    testVal=fscanf(fid,'%f',1);  %First check if line begins with a number
    if isempty(testVal)
        testVal=fscanf(fid,'%s',1);  %If not look for a string instead
        
        %now check to see if the string in test val makes sense as a value
        if strcmpi(testVal,'false') || strcmpi(testVal,'true') || testVal(1)=='"'
            %disp(testVal) %this is a parameter
        else
            skipLine = true;
            if testVal(1)~='-' %test if this non parameter not a comment
                DataOut.Label{count}=testVal;  %if not a comment, make the value the label
                DataOut.Val{count}=' ';
                count=count+1;
            end
            
        end
    end    
    
    % Check to see if the value is Outlist
    if double(strcmpi(testVal,'OutList'))==1
        break; %testval is OutList, break the loop
    end
        

    if ~skipLine %if this is actually a parameter line add it
        DataOut.Val{count}=testVal; %assign Val
        
        
        % Now get the label, some looping is necessary because often
        % times, old values for FAST parameters and kept next to new
        % ones seperated by a space and need to be ignored
        test=0;
        while test==0
            testVal=fscanf(fid,'%f',1);
            if isempty(testVal) %if we've reached something besides a number
                testVal=fscanf(fid,'%s',1);
                if testVal(1)==',' %commas are an indication that this parameter is a list
                    %handle list case by appending list
                    DataOut.Val{count}=[DataOut.Val{count} str2num(testVal)];
                else
                    test=1;
                end
            end
        end
        DataOut.Label{count}=testVal; %Now save label
        
        
%         if isempty(Label)==0

%         end
        count=count+1;
    end %endif
end %end while

%Now loop and read in the OutList
fgets(fid); %Advance to the next line
outVar = fscanf(fid,'%s',1);
outCount = 1;

while ~strcmp(outVar,'END') %loop until we reach the word END
    DataOut.OutList{outCount} = outVar;
    outCount = outCount + 1;
    fgets(fid); %Advance to the next line
    outVar = fscanf(fid,'%s',1);
end %end while

fclose(fid); %close file

end %end function
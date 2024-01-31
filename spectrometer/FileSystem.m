classdef FileSystem < handle
    
    properties (SetAccess = private)
        DateString;
        DatePath;
        FileIndex;
        dataDirLocal='C:/data';
%         dataDirRemote='c:/Users/INFRARED/Box/data/2dir_data';
        dataDirRemote2='c:/Users/INFRARED/OneDrive - University of Pittsburgh/data/2dir_data';
%         dataDirRemote3='\\share.files.pitt.edu\CHEM-SGR\sgr-laser1.chem.pitt.edu';
        hostname = getPublicHostName;
        eln;
    end
    properties
        flagSaveLocal=true;
        flagSaveRemote=true;
        flagSaveELN=true; %IF CRASHING SET TO FALSES
    end
    
    %hold the instance as a persistent variable
    methods (Static)
        function singleObj = getInstance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = FileSystem;
            end
            singleObj = localObj;
        end
    end
    
    methods (Access = private)
        
        function obj = FileSystem
            fprintf('\nInitializing file system ... \n')
            obj.updateParameters;
            try
                obj.eln = labarchivesCallObj('notebook',obj.hostname,...
                    'page',obj.DateString);
            catch
                warning('Failed to connect to ELN.')
                obj.flagSaveELN=false;
            end
            fprintf('Done.\n')
        end
    end
    
    methods (Access = public)
        
        function Save(obj, data)
            if obj.flagSaveLocal
                obj.SaveLocal(data);
            end
            if obj.flagSaveRemote
                obj.SaveRemote(data);
            end
            if obj.flagSaveELN
                obj.SaveELN(data);
            end
            
            %after saving update the file directory and file count
            %this has the side effect of moving into a new directory after the
            %first save after midnight (sorry)
            obj.updateParameters;
        end
        
        function SaveLocal(obj,data)
            file_name_and_path = sprintf('%s/%3.3d.mat', obj.DatePath, obj.FileIndex);
            save(file_name_and_path, 'data');
        end
        
        function SaveRemote(obj,data)
%             file_name_and_path = sprintf('%s/%s/%3.3d.mat',...
%                 obj.dataDirRemote, obj.DateString, obj.FileIndex);
            file_name_and_path2 = sprintf('%s/%s/%3.3d.mat',...
                obj.dataDirRemote2, obj.DateString, obj.FileIndex);
%             file_name_and_path3 = sprintf('%s/%s/%3.3d.mat',...
%                 obj.dataDirRemote3, obj.DateString, obj.FileIndex);
%             dirname =  sprintf('%s/%s',obj.dataDirRemote, obj.DateString);
            dirname2 =  sprintf('%s/%s',obj.dataDirRemote2, obj.DateString);
%             dirname3 =  sprintf('%s/%s',obj.dataDirRemote3, obj.DateString);
%             if ~exist(dirname, 'file')
%                 mkdir(dirname);
%             end
            if ~exist(dirname2, 'file')
                mkdir(dirname2);
            end
%             if ~exist(dirname3, 'file')
%                 mkdir(dirname3);
%             end
%             save(file_name_and_path, 'data');
            save(file_name_and_path2, 'data');
%             save(file_name_and_path3, 'data');
        end
        
        function SaveELN(obj,data)
            %make sure we are on the right page. If not then udate the page
            
            originalPath = pwd;
            cd(obj.DatePath)

            try
                if ~strcmp(obj.DateString,obj.eln.page_name)
                    %if they are not the same, update
                    obj.eln = labarchivesCallObj('page',obj.DateString);
                end
                filename = sprintf('%3.3d.mat', obj.FileIndex);
                obj.eln=obj.eln.addAttachment(filename);
            catch err
                warning('Spectrometer:FileSystem', ['Failed to upload data file to Lab Archives.\n', err.message]);
                cd(originalPath)
            end
            
            cd(originalPath)
        end
        
        function SaveTemp(obj, data, counter)
            path = sprintf([obj.dataDirLocal,'/%s/temp/%3.3d-%4.4d.mat'], obj.DateString, obj.FileIndex, counter);
            save(path, 'data');
        end
        
    end
    
    methods (Access = public)
        
        function SaveOutputFile(obj)
            
            if obj.flagSaveRemote
                try
                    obj.SaveRemoteOutputFile();
                catch err
                    fprintf(1, '\n');
                    warning('Spectrometer:FileSystem', ['Failed to upload experimental details output file to remote (Box).\n', err.message]);
                end
            end
            
            if obj.flagSaveELN
                try
                    obj.SaveELNOutputFile();
                catch err
                    fprintf(1, '\n');
                    warning('Spectrometer:FileSystem', ['Failed to upload experimental details output file to Lab Archives.\n', err.message]);
                end
            end
            
            %after saving update the file directory and file count
            %this has the side effect of moving into a new directory after the
            %first save after midnight (sorry)
            obj.updateParameters;
        end
        
        function SaveRemoteOutputFile(obj)
            
%             remote_file_name_and_path = sprintf('%s/%s/experimental_details.txt',...
%                 obj.dataDirRemote, obj.DateString);
            remote_file_name_and_path2 = sprintf('%s/%s/experimental_details.txt',...
                obj.dataDirRemote2, obj.DateString);
            local_file_name_and_path = sprintf('%s/experimental_details.txt', obj.DatePath);
            
%             dirname =  sprintf('%s/%s',obj.dataDirRemote, obj.DateString);
%             if ~exist(dirname, 'file')
%                 mkdir(dirname);
%             end
            dirname2 =  sprintf('%s/%s',obj.dataDirRemote2, obj.DateString);
            if ~exist(dirname2, 'file')
                mkdir(dirname2);
            end
%             copyfile(local_file_name_and_path, remote_file_name_and_path);
            copyfile(local_file_name_and_path, remote_file_name_and_path2);
        end
        
        function SaveELNOutputFile(obj)
            %make sure we are on the right page. If not then udate the page
            if ~strcmp(obj.DateString,obj.eln.page_name)
                %if they are not the same, update
                obj.eln = labarchivesCallObj('page',obj.DateString);
            end
            
            currentPath = pwd;
            cd(obj.DatePath)
            filename = 'experimental_details.txt';
            
            obj.eln = obj.eln.loadEntriesForPage();
            
            
            
            if length(obj.eln.entries) == 1
                entryNames = obj.eln.entries.attach_dash_file_dash_name.Text;
            else
                entryNames = cell(1, length(obj.eln.entries));
                for ii = 1:length(obj.eln.entries)
                    entryNames{ii} = obj.eln.entries{ii}.attach_dash_file_dash_name.Text;
                end
            end
            
            entryNames = string(entryNames);
            
            if ~isempty(find(strcmp(entryNames, filename), 1))
                obj.eln = obj.eln.updateAttachment(filename);
            else
                obj.eln=obj.eln.addAttachment(filename);
            end
            
            cd(currentPath);
        end
        
        
        function InitializeLocalOutputFile(obj)
            global method
            file_name_and_path = sprintf('%s/experimental_details.txt', obj.DatePath);
            fid = fopen(file_name_and_path,'a+'); %open a file for appending text to
            
            methodString = class(method);
            methodString = strrep(methodString, 'Method_', '');
            methodString = strrep(methodString, '_', ' ');
            methodString = strrep(methodString, '.m', '');
            fprintf(fid, '\r\n|------------------------------------------------|\r\n');
            fprintf(fid, '|%48s|\r\n', methodString);
            
            dd = datestr(now);
            fprintf(fid,'|%48s|\r\n',dd);
            fprintf(fid, '|------------------------------------------------|\r\n');
            
            fprintf(fid,'|%10s|%10s|%10s|%15s|\r\n','Run','nScans','t2 (fs)', 'Polarization');
            fprintf(fid,'|----------|----------|----------|---------------|\r\n');
            fclose(fid);
        end
        
        function AppendLocalOutputFile(obj, nScans, t2, polarization)
            file_name_and_path = sprintf('%s/experimental_details.txt', obj.DatePath);
            
            fid = fopen(file_name_and_path,'a+'); %open a file for appending text to
            fprintf(fid,'|%10i|%10i|%10i|%15s|\r\n',obj.FileIndex, nScans, t2, polarization);
            fclose(fid);
        end
        
        function CloseLocalOutputFile(obj)
            file_name_and_path = sprintf('%s/experimental_details.txt', obj.DatePath);
            fid = fopen(file_name_and_path,'a+'); %open a file for appending text to
            fprintf(fid, '|------------------------------------------------|\r\n\r\n');
            fclose(fid);
        end
    end
    
    methods (Access = private)
        
        % Note problem: if an exception occurs after some temp files are
        % written but before final files, there will be orphan files.
        % in the temp folder.
        function updateParameters(obj)
            
            % Verify that root data directory structure exists.
            
            if ~exist(obj.dataDirLocal, 'file')
                mkdir(obj.dataDirLocal)
            end
            
            % Verify that folder for today exists
            
            obj.DateString = datestr(now, 'yyyy-mm-dd');
            obj.DatePath = [obj.dataDirLocal '/' obj.DateString];
            if ~exist(obj.DatePath, 'file')
                mkdir(obj.DatePath);
            end
            dateTmpPath = [obj.DatePath '/temp/'];
            if ~exist(dateTmpPath, 'file')
                mkdir(dateTmpPath);
            end
            
            % Get next file index (run number)
            
            files = dir(obj.DatePath);
            files = {files.name};
            matches = regexp(files, '(^\d+)\.mat', 'tokens');
            matches = matches(~cellfun('isempty',matches));
            
            if isempty(matches)
                obj.FileIndex = 1;
            else
                
                % As to what is going on here.  regexp returns a cell array of
                % cells containing strings, and it was a bit of a bitch to figure
                % out how to get them out of there without resorting to a clumsy
                % for loop.  the cat function indexes each item of the cell array
                % and puts the contents into a string array.  The following line
                % converts them to integers, finds the maximum, and adds one for
                % the next run.
                values = cat(2, matches{1,:});
                values = cat(2, values{1,:});
                obj.FileIndex = max(str2double(values))+1;
            end
            
        end
        
    end
end

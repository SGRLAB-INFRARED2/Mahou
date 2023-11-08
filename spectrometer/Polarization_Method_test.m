classdef Polarization_Method_test < Method
properties (SetAccess = protected)
%    PARAMS = struct('polAngle',-90:10:90);
end
    methods

        function Scan(obj)
            global method
            obj.ScanIsRunning = true;
            
            for ii = 1:length(obj.PARAMS.polAngle)
%                 while obj.ScanIsRunning
%                     pause(1)
%                 end
                if ~obj.ScanIsStopping
                    obj.source.rotors(1).MoveTo(obj.PARAMS.polAngle(ii)/2);
                    obj.source.rotors(2).MoveTo(obj.PARAMS.polAngle(ii));
                    obj.result.polarization = sprintf('%0.2f',polAngle(ii));
                    set(obj.handles.editnScans, 'String');
                    if contains(class(method), 'Multi_Time')
                        obj.fileSystem.AppendLocalOutputFile(obj.current_nScans, obj.current_t2, obj.result.polarization);
                    end
%                 elseif ii == 2 && ~obj.ScanIsStopping
%                     obj.source.rotors(1).MoveTo(45);
%                     obj.source.rotors(2).MoveTo(270); %can be 90 depending on alignment and where the "scratch" is...
%                     obj.result.polarization = 'ZZXX';
%                     set(obj.handles.editnScans, 'String', get(obj.handles.editnScans_Perp, 'String'));
%                     if contains(class(method), 'Multi_Time')
%                         obj.fileSystem.AppendLocalOutputFile(obj.current_nScans_Perp, obj.current_t2, obj.result.polarization);
%                     end
                end
                
                if ~obj.ScanIsStopping
                    Scan@Method(obj)
                end
                
                set(obj.handles.textDate, 'String', obj.fileSystem.DateString);
                set(obj.handles.textRunNumber, 'String', ['Run # ' num2str(obj.fileSystem.FileIndex)]);

%                 pause(1)
                
                
            end
%             obj.source.rotors(1).MoveTo(0);
%             obj.source.rotors(2).MoveTo(0);
            
            obj.ScanIsRunning = false;
            if ~contains(class(obj), 'Multi_Time')
                obj.ScanIsStopping = false;
            end
        end
    end
end
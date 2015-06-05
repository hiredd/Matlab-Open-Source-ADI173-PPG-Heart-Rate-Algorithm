%% SENtrodeAsync2SyncLogConv.m 
% script converts Aschronous style logs generated by the SENtrode Application
% to sychronous type datalog.
% Basically, the SENtrode .CSV log has one line per device type, all with
% independant timestamps. This converter merges all sensor data to a single
% timestamp will all  last known sensor values represented on each and every line.

clear;clc;

% datalog file prototype (index:field name)
%   1:Timestamp, 2:peripheral, 3:id,          4:GATT,        5:heartrate,	
%   6:ax,        7:ay,         8:az,          9:aTimestamp,	
%  10:SLOTA_PD1, 11:SLOTA_PD2, 12:SLOTA_PD3, 13:SLOTA_PD4,	14: rawTimestamp,	
%  15:led,	
%  16:SLOTB_PD1, 17:SLOTB_PD2, 18:SLOTB_PD3, 19:SLOTB_PD4,  20:rawTimestamp,
%  21:rawPulse,	 22:firmware

% NOTE on wrapped vs. unwrapped Sensor Timestamps and AppTimestamps
% The Process_NewPPGData function can deal with unwrapped timestamps.
%   It unwraps values only as needed (to compare to a previous value for
%   pulse rate calculation)
% In this Matlab code, for further anaysis and comparison to reference 
%  sensors the SensorTimestamp domain will be used over the application 
%  timestamp, which is known to be inconsistant.



%% Setup data structures
% PPG_struct = initPPG_struct();
% Filt_struct = initFilt_struct();



%% read input file

[DataLogFilename, pathname] = uigetfile('*.csv','Select SENTrode Generated Log File');
cd(pathname);

fileID = fopen(DataLogFilename);

OneRow = fgetl(fileID);
Index = 1;LineNumber = 1; FirstError = 1;
fprintf('Reading...\n');
BadLines = 0;

while ~feof(fileID)                % Corrupt Rows of data where found to be common
    OneRow = fgetl(fileID);          % this step necessary to weed them out
    if length(strfind(OneRow,',')) == 21   % Allow only if proper num of delimiters
        M = textscan(OneRow,'%f%s%s%s%d%f%f%f%d%d%d%d%d%d%d%d%d%d%d%d%d%d','Delimiter',',');
        if Index==1, T_Zero = double(M{1});end
        %        if Index==1, T_Zero = double(0);end

        % Parse csvread output array 'M' into meaningful variable names
        Timestamp(Index)          =   double(M{1}) - T_Zero; %1/1000 second inc
        Peripheral(Index)         =   M{2};
        ID(Index)                 =   M{3};
        if ~isempty(M{4}),			GATT(Index)               =   M{4};
        else                        GATT(Index)               =   '';end;
        if ~isempty(M{5}),			MeanHeartPulseRate(Index) =   uint8(M{5});
        else                        MeanHeartPulseRate(Index) =   uint8(0);end;
        if ~isempty(M{6}),			AX(Index)                 =   single(M{6});
        else                        AX(Index)                 =   single(0);end;
        if ~isempty(M{7}),			AY(Index)                 =   single(M{7});
        else                        AY(Index)                 =   single(0);end;
        if ~isempty(M{8}),			AZ(Index)                 =   single(M{8});
        else                        AZ(Index)                 =   single(0);end;
        if ~isempty(M{9}),			AccTimestamp(Index)       =   uint16(M{9});
        else                        AccTimestamp(Index)       =   uint16(0);end;
        if ~isempty(M{10}),			SlotA_PD1(Index)          =   uint16(M{10});
        else                        SlotA_PD1(Index)          =   uint16(0); end;
        if ~isempty(M{11}),			SlotA_PD2(Index)          =   uint16(M{11});
        else                        SlotA_PD2(Index)          =   uint16(0);end;
        if ~isempty(M{12}),			SlotA_PD3(Index)          =   uint16(M{12});
        else                        SlotA_PD3(Index)          =   uint16(0);end;
        if ~isempty(M{13}),			SlotA_PD4(Index)          =   uint16(M{13});
        else                        SlotA_PD4(Index)          =   uint16(0);end;
        if ~isempty(M{14}),			SlotA_Timestamp(Index)    =   uint32(M{14});
        else                        SlotA_Timestamp(Index)    =   2^16;end;
        if ~isempty(M{15}),			Status(Index)             =   uint8(M{15});
        else                        Status(Index)             =   uint8(0);end;
        if ~isempty(M{16}),			SlotB_PD1(Index)          =   uint16(M{16});
        else                        SlotB_PD1(Index)          =   uint16(0);end;
        if ~isempty(M{17}),			SlotB_PD2(Index)          =   uint16(M{17});
        else                        SlotB_PD2(Index)          =   uint16(0);end;
        if ~isempty(M{18}),			SlotB_PD3(Index)          =   uint16(M{18});
        else                        SlotB_PD3(Index)          =   uint16(0);end;
        if ~isempty(M{19}),			SlotB_PD4(Index)          =   uint16(M{19});
        else                        SlotB_PD4(Index)          =   uint16(0);end;
        if ~isempty(M{20}),			SlotB_Timestamp(Index)    =   uint32(M{20});
        else                        SlotB_Timestamp(Index)    =   2^16;end;
        if ~isempty(M{21}),			Raw_PulseRate(Index)      =   uint8(M{21});
        else                        Raw_PulseRate(Index)      =   uint8(0);end;
        if ~isempty(M{22}),			Firmware_Level(Index)     =   uint8(M{22});
        else                        Firmware_Level(Index)     =   uint8(0);end;

        Index = Index + 1;
    else
        if FirstError
            fprintf('Error(s) found on the following Datalog line(s):');
        end
        fprintf('%d ',LineNumber+1);
        BadLines = BadLines + 1;
        FirstError = 0;
    end
    LineNumber = LineNumber + 1;
end
fclose(fileID);

M_Len = Index - 1;

%split the values in the status field into its 2 components
NumberLEDPulses(1:M_Len)    =   mod(Status(1:M_Len),64);
Stillness(1:M_Len)          =   (Status(1:M_Len)-NumberLEDPulses(1:M_Len))/64;


fprintf('\n\nDatafile: "%s"  has \n',DataLogFilename);
fprintf('%d Bad lines\n',BadLines);
fprintf('%d Good lines\n',M_Len);


%Determin number of peripherals (refernce HPR sensors) used in this log
    Index = 1; NumberOfRefs = 0;
    clear RefPeripherals;
    while Index < M_Len
        if ~strcmp(Peripheral(Index),'BlueNRG')
            if NumberOfRefs > 0
                Test = 1;
                for i = 1:NumberOfRefs
                    if strcmp(Peripheral(Index),RefPeripherals(i))
                        Test = 0;
                    end
                end

                if Test == 1
                    NumberOfRefs = NumberOfRefs + 1;
                    RefPeripherals(NumberOfRefs) = Peripheral(Index);
                end

            else
                NumberOfRefs = 1;
                RefPeripherals(NumberOfRefs) = Peripheral(Index);
            end
        end
        Index = Index + 1;
    end
    fprintf('%d Refernce Heart Rates Sensors used\n\n',NumberOfRefs);



% Create Synchronous Style Data logs
OUT_Filename = [DataLogFilename(1:length(DataLogFilename)-4) '_Sychronous.csv'];
HeartRate = 0; Wraps = 0;
ti = 1;
SensorTimestamp = zeros(M_Len,1);

if (NumberOfRefs > 0)
    fn = fopen(OUT_Filename,'w');
    fprintf(fn,'Timestamp(seconds),heartrate,ax,ay,az,SLOTA_PD1,SLOTA_PD2,SLOTA_PD3,SLOTA_PD4,led_Pulses,SLOTB_PD1,SLOTB_PD2,SLOTB_PD3,SLOTB_PD4\n');

    for i = 1:(M_Len-1)

        if strcmp(Peripheral(i),RefPeripherals(1))
            HeartRate = MeanHeartPulseRate(i);

        elseif (NumberLEDPulses(i)~= 0) && (SlotB_PD1(i+1) ~= 0) % denotes a slot A field

            if (ti > 1) %unwrap Timestamp
                if (uint32(SlotA_Timestamp(i))+ Wraps*2^16) < SensorTimestamp(ti-1)
                    Wraps = Wraps + 1;
                end
            end
            SensorTimestamp(ti) = uint32(SlotA_Timestamp(i)) + Wraps*2^16;

            fprintf(fn,'%f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', ...
                double(SensorTimestamp(ti))/32000,HeartRate,...
                AX(i),AX(i),AX(i),...
                SlotA_PD1(i),SlotA_PD2(i),SlotA_PD3(i),SlotA_PD4(i),...
                NumberLEDPulses(i),...
                SlotB_PD1(i+1),SlotB_PD2(i+1),SlotB_PD3(i+1),SlotB_PD4(i+1));
                ti = ti + 1;
        end
    end

    fclose(fn);
    clear fn;

end
clear fileID;

fprintf('-- DONE  --\n');
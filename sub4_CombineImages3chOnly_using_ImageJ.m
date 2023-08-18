%% Combine single-channle TIF files to multi-channel TIF.

import ij.IJ
import ij.ImagePlus
import ij.WindowManager

if ~exist('path0', 'var') %check if path0 is in this workspace.
    path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
end

%% Get File names.
fSkipInput = false;
%fOverwriteMetadata = false;
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
        %fOverwriteMetadata = true;
    end
end
if fSkipInput
    disp('Combine TIF files to one... (skip uigetfile)')
else
    cd(path0);
    [files,path]=uigetfile('*.tif','Select all files to analyze','MultiSelect','on');
    if ~iscell(files) % files is not a cell whne only one file is selected.
        files = {files};
    end
    nfiles = size(files,2);
end
cd(path)


for i=1:nfiles
    filename = files{i};
    [filepath,filenamehead,ext] = fileparts(filename);
    filename = [filenamehead '.tif'];

    filename1 = [filenamehead '_chan1_drftc.tif'];
    filename2 = [filenamehead '_chan2_drftc.tif'];
    filename3 = [filenamehead '_chan3_drftc_reg.tif'];
    filename3b = [filenamehead '_chan3_drftc.tif']; %to delete
    SaveFilenamehead = [filenamehead '_drftc_reg'];

    %% open image stacks
    %imgFileFull = fullfile(path, filename);

    % to get "info" saved by ImageJ
    imp0 = IJ.openImage(fullfile(path, filename));
    thisInfoData = imp0.getProperty("Info");
    imp0.close;

    info = imfinfo(fullfile(path, filename));
    info1=info(1);
    thisImgDes = info1.ImageDescription;
    tokens = regexp(thisImgDes, 'frames=([\d\.]+)', 'tokens');
    %nFrame = str2double(tokens{1}{1});
    nFrame = tokens{1}{1};
    tokens = regexp(thisImgDes, 'finterval=([\d\.]+)', 'tokens');
    frameInterval = tokens{1}{1};


    % close all windows
    ij.IJ.run("Close All");

    imp1 = IJ.openImage(fullfile(path, filename1));
    imp1.show()
    title1 = ij.WindowManager.getImageTitles();

    imp2 = IJ.openImage(fullfile(path, filename2));
    imp2.show()
    title2 = ij.WindowManager.getImageTitles();

    imp3 = IJ.openImage(fullfile(path, filename3));
    imp3.show()
    title3 = ij.WindowManager.getImageTitles();
    %imp.show()

    % Get the list of open images
    list = ij.WindowManager.getImageTitles();

    % Merge and set lookup tables
    nChan = length(list);

    if nChan == 3
        % Merge the three channels into a composite image
        temp = ['c1=' char(list(1)) ' c2=' char(list(2)) ' c3=' char(list(3)) ' create'];
        ij.IJ.run("Merge Channels...", temp)

        % Set the lookup tables for each channel
        imp = ij.IJ.getImage();
        imp.setPosition(1)
        ij.IJ.run(imp, "Grays", "")
        imp.setPosition(2)
        ij.IJ.run(imp, "Green", "")
        imp.setPosition(3)
        ij.IJ.run(imp, "Red", "")

        % Check and reset the iamge stack dimension
        dims = imp.getDimensions;
        if dims(4)>1 && dims(5)==1
            disp('Dimensionality was reset: XYCTZ to XYCZT')
            imp.setDimensions(dims(3), dims(5), dims(4));
        end

        str = ['channels=3 slices=1' ' frames=' nFrame ' interval=' frameInterval];
        ij.IJ.run("Properties...", str);

        %saveAs("Tiff", fullfile(path, [filenamehead '.tif']));
        fullFilename2save = fullfile(path, [SaveFilenamehead '.tif']);
        ij.IJ.saveAs(imp, "Tiff", fullFilename2save);

        imp.close
        delete(filename)
        delete(filename1)
        delete(filename2)
        delete(filename3)
        delete(filename3b)

    else
        disp('Warning: not configured channel number')
    end



end
% Quite the ImageJ instance
%ij.IJ.run("Quit","")



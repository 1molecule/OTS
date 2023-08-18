%% Combine single-channle TIF files to multi-channel TIF.

import ij.IJ
import ij.ImagePlus
import ij.WindowManager

if ~exist('path0', 'var') %check if path0 is in this workspace.
    path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
end

%% Get File names.
fSkipInput = false;
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
        nChan = master_nChan;    
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
    
    filenames = cell(nChan,1);
    for ch=1:nChan-1
        filenames{ch} = [filenamehead '_chan' num2str(ch) '_drftc.tif'];
    end
    filenames{nChan} = [filenamehead '_chan' num2str(nChan) '_drftc_reg.tif'];
    filenames2delete = [filenamehead '_chan' num2str(nChan) '_drftc.tif'];
    SaveFilenamehead = [filenamehead '_drftc_reg'];

    % filename1 = [filenamehead '_chan1_drftc.tif'];
    % filename2 = [filenamehead '_chan2_drftc.tif'];
    % filename3 = [filenamehead '_chan3_drftc_reg.tif'];
    % filename3b = [filenamehead '_chan3_drftc.tif']; %to delete

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
    
    imps = cell(nChan,1);
    titles  = cell(nChan,1);
    for ch=1:nChan
        imps{ch} =  IJ.openImage(fullfile(path,  filenames{ch}));
        imps{ch}.show()
        titles{ch} = ij.WindowManager.getImageTitles();
    end

    % imp1 = IJ.openImage(fullfile(path, filename1));
    % imp1.show()
    % title1 = ij.WindowManager.getImageTitles();
    % 
    % imp2 = IJ.openImage(fullfile(path, filename2));
    % imp2.show()
    % title2 = ij.WindowManager.getImageTitles();
    % 
    % imp3 = IJ.openImage(fullfile(path, filename3));
    % imp3.show()
    % title3 = ij.WindowManager.getImageTitles();
    % %imp.show()

    % Get the list of open images
    list = ij.WindowManager.getImageTitles();

    % Merge and set lookup tables
    if nChan ~= length(list)
        error('Error: the nubmer of color channels do not match')
    end

    if ~(nChan == 3 || nChan == 4) 
        error('Error: not configured channel number')
    end


    % Merge the three channels into a composite image & Set the lookup table
    if nChan == 3
        temp = ['c1=' char(list(1)) ' c2=' char(list(2)) ' c3=' char(list(3)) ' create'];
        ij.IJ.run("Merge Channels...", temp)
        imp = ij.IJ.getImage();
        imp.setPosition(1)
        ij.IJ.run(imp, "Grays", "")
        imp.setPosition(2)
        ij.IJ.run(imp, "Green", "")
        imp.setPosition(3)
        ij.IJ.run(imp, "Red", "")
    end

    if nChan == 4
        temp = ['c1=' char(list(1)) ' c2=' char(list(2)) ' c3=' char(list(3)) ' c4=' char(list(4)) ' create'];
        ij.IJ.run("Merge Channels...", temp)
        imp = ij.IJ.getImage();
        imp.setPosition(1)
        ij.IJ.run(imp, "Grays", "")
        imp.setPosition(2)
        ij.IJ.run(imp, "Blue", "")
        imp.setPosition(3)
        ij.IJ.run(imp, "Green", "")
        imp.setPosition(4)
        ij.IJ.run(imp, "Red", "")
    end

    % Check and reset the iamge stack dimension
    dims = imp.getDimensions;
    if dims(4)>1 && dims(5)==1
        disp('Dimensionality was reset: XYCTZ to XYCZT')
        imp.setDimensions(dims(3), dims(5), dims(4));
    end

    %str = ['channels=3 slices=1' ' frames=' nFrame ' interval=' frameInterval];
    str = ['channels=' num2str(nChan) ' slices=1' ' frames=' nFrame ' interval=' frameInterval];
    ij.IJ.run("Properties...", str);

    % save the composite image stack
    fullFilename2save = fullfile(path, [SaveFilenamehead '.tif']);
    ij.IJ.saveAs(imp, "Tiff", fullFilename2save);
    imp.close


    % delete intermediate image files
    delete(filename)
    delete(filenames2delete)
    for ch=1:nChan
        delete(filenames{ch})
    end
    % delete(filename1)
    % delete(filename2)
    % delete(filename3)
    % delete(filename3b)
end




% Quite the ImageJ instance
%ij.IJ.run("Quit","")



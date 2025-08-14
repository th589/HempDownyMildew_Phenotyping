%-------------------------------------------------------------------------
function user_training_GUI_7 %same name; specifies function to run w/ file
    global current_im;
    global handles;
    global subpix;
    global saved;    
    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    % Define figure handle:
    handles.h_fig = figure('Name','CNN Image Training App','NumberTitle','off',...
        'CloseRequestFcn', @closeapp, 'resize', 'on' ,...
        'Position', [600 400 1000 450],'menubar','none');

    % Set up GUI:
    handles.infect_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 16, 'Position', [880 100 100 50], 'Enable', 'off',...
        'String','Infected','Callback', @put_category, 'Parent', handles.h_fig); 
    
    handles.clear_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 16, 'Position', [880 40 100 50], 'Enable', 'off',...
        'String', 'Clear','Callback', @put_category, 'Parent', handles.h_fig); 
    
    handles.back_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 14, 'Position', [900 160 60 25], 'Enable', 'off',...
        'String', 'Back','Callback', @go_back, 'Parent', handles.h_fig); 
    
    
    handles.open_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 13, 'Position', [880 365 100 30], 'Enable', 'on',...
        'String','Open training...','Callback', @open_train, 'Parent', handles.h_fig); 
    
    handles.save_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 13, 'Position', [880 325 100 30], 'Enable', 'off',...
        'String','Save training...','Callback', @save_train, 'Parent', handles.h_fig);
    
    handles.new_button = uicontrol('Style', 'pushbutton',... 
        'FontSize', 13, 'Position', [880 405 100 30], 'Enable', 'on',...
        'String','New training...','Callback', @new_train_init, 'Parent', handles.h_fig);
    
    handles.t_progress = uicontrol('Style', 'text',... 
        'FontSize', 14, 'Position', [870 220 120 30], 'Enable', 'on',...
        'String','0/0','Parent', handles.h_fig);
    
    handles.h_axes2 = axes(handles.h_fig, 'Units', 'pixels', 'Position', [15 15 420 420]);
    handles.h_image2 = image(zeros(224*5,224*5,3), 'Parent', handles.h_axes2);
    
    hold(handles.h_axes2,'on');
    handles.h_sqim = plot(handles.h_axes2,0,0,'r-','Linewidth',3);
    hold(handles.h_axes2,'off');
    
    handles.h_axes = axes(handles.h_fig, 'Units', 'pixels', 'Position', [445 15 420 420]);
    handles.h_image = image(zeros(224,224,3), 'Parent', handles.h_axes);
    
    axis(handles.h_axes, 'off');
    axis(handles.h_axes2, 'off');
    
    %Square size of the subimage in pixels
    subpix = 224;
    
    %Flag determining if current results have been saved
    saved = 1;
    
    current_im.im_name = '';
end
%-------------------------------------------------------------------------


function new_train_init(~,~)
    global handles;
    
    handles.h_fig_train = figure('Name','','NumberTitle','off','WindowStyle','modal',...
        'resize', 'off','Position', [500 250 200 180],...
        'DockControls','off','Toolbar','none','menubar','none');
    
                 
    handles.h_r1 = uicontrol(handles.h_fig_train,'Style','radiobutton','String','Start new classification',...
      'Position',[10 150 180 20],'Callback',@bselection,'Value',1);
    
    uicontrol(handles.h_fig_train,'Style','text','String','Sub-images per Image',...
      'Position',[40 120 120 20]);
    
    handles.e_subim = uicontrol(handles.h_fig_train,'Style','edit','String','100',...
      'Position',[75 100 50 20],'Value',1);
    
    handles.h_r2 = uicontrol(handles.h_fig_train,'Style','radiobutton','String','Re-classification for comparison',...
      'Position',[10 60 180 20],'Callback',@bselection);
    
    handles.b_ok = uicontrol(handles.h_fig_train,'Style','pushbutton','String','OK',...
      'Position',[75 15 50 30],'Callback',@check_train_init);
end


function bselection(obj,~)
    global handles;
        switch obj.String
            case 'Start new classification'
                handles.h_r2.Value = 0;
                handles.e_subim.Enable = 'on';
            case 'Re-classification for comparison'
                handles.h_r1.Value = 0;
                handles.e_subim.Enable = 'off';
        end
end


function check_train_init(~,~)
    global handles exp_data;

    if handles.h_r1.Value
        exp_data.subxsample = str2double(handles.e_subim.String);
        if isnan(exp_data.subxsample) | exp_data.subxsample < 1
            errordlg('Sub-image value not valid!','ERROR!');
            return;
        end
        delete(handles.h_fig_train);
        new_train();
    else
        exp_data = load_check_data;
        if isempty(exp_data)
            return;
        end
        delete(handles.h_fig_train);
        re_classify;
    end
end


%Open folder selection wizard and return path
function new_train(~,~)
    global exp_data;
    global handles;
    
    dir_path = uigetdir('C:\','Select training images directory');
    
    %If user clicks on cancel or closes the window, dir_path is 0 so throw
    %an error
    if dir_path == 0
        errordlg('Invalid path.', 'Error');
    end

    %This function automatically search for images in the selected directory
    %path. We set we don't want it to look into the subfolders. We
    %also set it to look only for TIF image format
    
    %Change 12/12/2022: look for .png format per new Blackbird stacking
    
    try
    exp_data.image_collection = imageDatastore(dir_path,'IncludeSubfolders',false,...
        'FileExtensions','.png');
    catch
       errordlg('No images found.', 'Error');
       return;
    end

    %Obtain the number of total images to analyze
    exp_data.total_images = length(exp_data.image_collection.Files);
    
    %Create a table to store the results as sample image name, index of the
    % subimage, and category (infected or not)
    exp_data.result_table = table('Size',[(exp_data.subxsample * exp_data.total_images) 3], 'VariableNames',...
        {'imagename' 'subindex' 'category'},'VariableTypes', {'cellstr' 'double' 'categorical'});
    
    
    handles.t_progress.String = ['0/' num2str(exp_data.subxsample * exp_data.total_images)];
    
    %Create a table index and set it to the first position
    exp_data.table_ind = 1;
    exp_data.non_visited = [];
    exp_data.r_indx = 0;
    
    exp_data.reclassify = 0;
    
    load_image;
    if exp_data.table_ind > height(exp_data.result_table) % Control if buttons are pushed > table index
        return;
    else
        show_subimage;
        handles.save_button.Enable = 'on';
    end
end


function re_classify
    global exp_data;
    global handles;

    %Restart classification
    exp_data.result_table(exp_data.table_ind:end,:)=[];
    exp_data.result_table{:,3} = removecats(exp_data.result_table{:,3},{'Clear','Infected'});
    
    handles.t_progress.String = ['0/' num2str(height(exp_data.result_table))];
    
    exp_data.table_ind = 1;
    exp_data.non_visited = [];
    exp_data.r_indx = 0;
    
    exp_data.reclassify = 1;
    
    load_image;
    show_subimage;
    handles.save_button.Enable = 'on';
    
end
%-------------------------------------------------------------------------

function load_image

    global exp_data;
    global subpix;
    global current_im;
    global handles;

    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end


    if exp_data.table_ind > height(exp_data.result_table) % Control if buttons are pushed > table index
        waitfor(warndlg('No more images to classify.','Training finished'))
        save_train;
        delete(handles.h_fig);
        return;
    end

    ind_im = floor((exp_data.table_ind-1) / exp_data.subxsample) + 1;
    im_info = imfinfo(exp_data.image_collection.Files{ind_im});
    aux_str = split(im_info.Filename, symbol );
    
    if strcmp(current_im.im_name,aux_str{end}(1:end-4))
        return;
    end
    
    handles.infect_button.Enable = 'off';
    handles.clear_button.Enable = 'off';
    handles.h_fig.Pointer = 'watch';
    drawnow;

    current_im.rgbdata = imread(exp_data.image_collection.Files{ind_im});

    im_info = imfinfo(exp_data.image_collection.Files{ind_im});
    current_im.im_width = im_info.Width;
    current_im.im_height = im_info.Height;

    %Get the filename without the path and the .tif extension
    aux_str = split(im_info.Filename, symbol);
    current_im.im_name = aux_str{end}(1:end-4);

    %Compute how many subimages we can fit in each axis (X and Y)
    current_im.subim_x = floor(current_im.im_width/subpix);
    current_im.subim_y = floor(current_im.im_height/subpix);

    %Generate image mask of leaf surface by using focal segmentation
    [~,~,~,~,FMimage] = leaf_mask_02f(im2uint8(current_im.rgbdata),4.5);
    
    maxFM = max(FMimage(:));
    idx = find(FMimage < (maxFM/10));
    th = mean(FMimage(idx));
    [current_im.imask,~,~,~,~] = leaf_mask_02f(im2uint8(current_im.rgbdata),th);
    
    %Compute the total number of subimages we can fit at the current image
    current_im.maxsubim = current_im.subim_x * current_im.subim_y;

    %Array of visited random subimage indexes per sample
    if mod(exp_data.table_ind, exp_data.subxsample) == 1
        exp_data.non_visited = 1:current_im.maxsubim;
    end

    handles.h_fig.Pointer = 'arrow';
    drawnow;

end

%Loop that goes along all images found
function show_subimage
    global exp_data;
    global current_im;
    global subpix;
    global handles;
    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    handles.infect_button.Enable = 'off';
    handles.clear_button.Enable = 'off';
    
    if ~exp_data.reclassify
        mask_ratio = 0;
        while mask_ratio < 0.7
    
            if isempty(exp_data.non_visited)
                %Skip subimage table entries until next image
                while mod(exp_data.table_ind, exp_data.subxsample) ~= 0
                    exp_data.table_ind = exp_data.table_ind + 1;
                end
                exp_data.table_ind = exp_data.table_ind + 1;

                if exp_data.table_ind > height(exp_data.result_table)
                    waitfor(warndlg('No more images to classify.','Training finished'));
                    save_train;
                    delete(handles.h_fig);
                    return;              
                end
                load_image;
                show_subimage;
                return;
            end
    
            %Get random index of non-visited subimage  
            indx = floor(rand(1) * numel(exp_data.non_visited))+1;
            exp_data.r_indx = exp_data.non_visited(indx);

            %Remove the index as non-visited
            exp_data.non_visited(indx) = [];

            %Compute the coordinates of the random sub-image
            coord_x = mod(exp_data.r_indx-1,current_im.subim_x)*subpix + 1;
            coord_y = floor((exp_data.r_indx-1)/current_im.subim_x)*subpix + 1;

            %Determine if the sub-image is valid (No background nor unfocused):
            %1 - Get the corresponding mask for the current sub-image
            sub_image_mask = imcrop(current_im.imask,[coord_x coord_y subpix-1 subpix-1]);

            %2 - Compute the mask ratio of useful pixels.
            %    [0 (no leaf pixels in it) to 1 (all pixels are leaf)]
            mask_ratio = mean(sub_image_mask(:));

            %3 - If more than 30% of pixels are background or out of focus
            %    Restart the loop iteration
        end
    else
        %Get sub-image index from the result_table
        exp_data.r_indx = exp_data.result_table{exp_data.table_ind,2};
        while exp_data.r_indx == 0
            exp_data.table_ind = exp_data.table_ind + 1;
            exp_data.r_indx = exp_data.result_table{exp_data.table_ind,2};
        end
        load_image;
        %Compute the coordinates of the random sub-image
        coord_x = mod(exp_data.r_indx-1,current_im.subim_x)*subpix + 1;
        coord_y = floor((exp_data.r_indx-1)/current_im.subim_x)*subpix + 1;
    end
    %Crop and get the color subimage from the sample image
    sub_image = imcrop(current_im.rgbdata,[coord_x coord_y subpix-1 subpix-1]);
    
    %Crop bigger contextual image for the sub-image
    if current_im.im_width < subpix * 5
        context_x = 1;
        context_w = current_im.im_width-1;
    elseif coord_x + subpix*3 > current_im.im_width
        context_x = current_im.im_width - subpix*5;
        context_w = (subpix*5) - 1;
    elseif coord_x - subpix*2 < 1
        context_x = 1;
        context_w = (subpix*5) - 1;
    else
        context_x = coord_x - subpix*2;
        context_w = (subpix*5) - 1;
    end
    
    if current_im.im_height < subpix * 5
        context_y = 1;
        context_h = current_im.im_height-1;
    elseif coord_y + subpix*3 > current_im.im_height
        context_y = current_im.im_height - subpix*5;
        context_h = (subpix*5) - 1;
    elseif coord_y - subpix*2 < 1
        context_y = 1;
        context_h = (subpix*5) - 1;
    else
        context_y = coord_y - subpix*2;
        context_h = (subpix*5) - 1;
    end
    
    context_image = imcrop(current_im.rgbdata,[context_x context_y context_w context_h]);
    
    %Show the image in the GUI and wait for the user category
    set(handles.h_image, 'CDATA', sub_image);
    set(handles.h_image2, 'CDATA', context_image);
    
    %Transform to relative coordinates
    coord_x = coord_x-context_x-1;
    coord_y = coord_y-context_y-1;
    handles.h_sqim.XData = [coord_x coord_x coord_x+subpix coord_x+subpix coord_x];
    handles.h_sqim.YData = [coord_y coord_y+subpix coord_y+subpix coord_y coord_y];
    drawnow;
    
    handles.infect_button.Enable = 'on';
    handles.clear_button.Enable = 'on';
end

function put_category(h,~) %handle of object,event as arguments
    global current_im;
    global exp_data;
    global handles;
    global saved;

    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end
        
    if isempty(exp_data)
        warndlg('Please start a new training or load a saved training.','No images found');
    end
    
    if exp_data.table_ind > height(exp_data.result_table) % Control if buttons are pushed > table index
        waitfor(warndlg('No more images to classify.','Training finished'))
        save_train;
        delete(handles.h_fig);
        return;
    else
        
    %Save the results of the current subimage classification
    exp_data.result_table.imagename{exp_data.table_ind} = current_im.im_name;
    exp_data.result_table.subindex(exp_data.table_ind) = exp_data.r_indx;
    exp_data.result_table.category(exp_data.table_ind) = h.String;
    saved = 0;
    
    handles.infect_button.Enable = 'off';
    handles.clear_button.Enable = 'off';
    handles.back_button.Enable = 'on';
            
    exp_data.table_ind = exp_data.table_ind + 1;
    handles.t_progress.String = [num2str(exp_data.table_ind-1) symbol num2str(height(exp_data.result_table))];
    
        if mod(exp_data.table_ind, exp_data.subxsample) == 1
            handles.infect_button.Enable = 'off';
            handles.clear_button.Enable = 'off';
            load_image;
        end
        if exp_data.table_ind > height(exp_data.result_table) % Control if buttons are pushed > table index
          helpdlg('All sub-images classified!','Congratulations')
          return;
        else
            show_subimage;
        end
    end
end 

% Close figure:
function closeapp(h,~)
    global exp_data;
    global saved
    
    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    if ~isempty(exp_data) & ~saved
        answer = questdlg('Would you like to save?',...
                'Save results', 'Yes', 'No', 'Yes');    
            switch answer
                case 'Yes'
                    uisave('exp_data', 'ImageTraining');
                    delete(h);
                    clear all;
                case 'No'
                    delete(h);
                    clear all;
                otherwise %does not close but does not save 
            end
    else
        delete(h);
        clear all;
    end
end

% Open saved training:
function open_train(~,~)
    global exp_data handles;

    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    exp_data = load_check_data;
    if isempty(exp_data)
        return;
    end
    load_image;
    show_subimage;
    handles.t_progress.String = [num2str(exp_data.table_ind-1) symbol num2str(height(exp_data.result_table))];
    handles.save_button.Enable = 'on';
end

% Check integrity of data to load, then load as experiment data
function exp_data_i = load_check_data
    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    exp_data_i = [];
    file = uigetfile('*.mat','Select training results file');
    if ~file
        error('Error: No valid file!');
    end
    lvar = load(file,'exp_data');
    try
        lvar.exp_data;
    catch
        errordlg('Error: No valid file!','ERROR!');
        return;
    end

    %Find local image directory
    dir = uigetdir( strcat('C:', symbol), 'Select training images directory');
    if ~dir
        error('Error: No valid directory!');
    end

    %Load local images
    try
    local_image_collection = imageDatastore(dir,'IncludeSubfolders',false,...
        'FileExtensions','.png');
    catch
        errordlg('Error: No training images found!','ERROR!');
        return;
    end

    local_fnames = cell(length(local_image_collection.Files),1);
    for i=1:length(local_image_collection.Files)
            aux_str = split(local_image_collection.Files{i}, symbol);
            local_fnames{i} = aux_str{end}(1:end-4);
    end
    
    training_fnames = cell(length(lvar.exp_data.image_collection.Files),1);
    for i=1:length(lvar.exp_data.image_collection.Files)
            aux_str = split(lvar.exp_data.image_collection.Files{i}, symbol);
            training_fnames{i} = aux_str{end}(1:end-4);
    end

    %Check if all trained images are in the local directory.
    
    
    
    
    indx = strfind(lvar.exp_data.image_collection.Files{1}, symbol );
    indx = indx(end);
    for i=1:numel(training_fnames)
        if ~isempty(training_fnames{i})
            if isempty(find(strcmp(local_fnames, training_fnames{i}),1))
                errordlg('Some training images are not found in local directory!','ERROR!');
                return;
            end
        end
        lvar.exp_data.image_collection.Files{i} = [dir lvar.exp_data.image_collection.Files{i}(indx:end)];
    end
    exp_data_i = lvar.exp_data;
end

% Save training:
function save_train(~,~)
    global exp_data;
    global saved;

    if ~saved
        if isempty(exp_data)
            warndlg('No data to save.','No training completed');
        else
            uisave('exp_data', 'ImageTraining');
            saved = 1;
        end
    end
end

function go_back(~,~)
    global exp_data;
    global handles;
    global symbol;
    
    if ismac | isunix
        symbol = '/';
    elseif ispc
        symbol = '\';
    end

    handles.back_button.Enable = 'off';
    handles.infect_button.Enable = 'off';
    handles.clear_button.Enable = 'off';
    
    while ~exp_data.result_table{exp_data.table_ind,2}
        exp_data.table_ind = exp_data.table_ind - 1;
    end
    if exp_data.reclassify
        show_subimage;
    else
        exp_data.non_visited(end+1) = exp_data.r_indx;
        exp_data.reclassify = 1;
        show_subimage;
        exp_data.reclassify = 0;
    end
    handles.t_progress.String = [num2str(exp_data.table_ind-1) symbol num2str(height(exp_data.result_table))];
end
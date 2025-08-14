


function PM_analyzer_05
global win;
global results step;

results = {};

global symbol;

if ismac | isunix
    symbol = '/';
else
    symbol = '\';
end


 
win.h_fig = figure('Position',[500 400 700 300],'Tag','MR_fig','MenuBar',...
            'none','ToolBar','none','Name','Downy Mildew Analyzer','NumberTitle',...
            'off','Resize','off','CloseRequestFcn',@PMclose);

win.b_open = uicontrol('Style','pushbutton','String','Open','Units','normalized',...
         'Position',[.02 .82 .3 .13],'FontSize',15,'Callback',@open_experiment,...
         'Enable','on','Parent',win.h_fig);
     
win.b_start = uicontrol('Style','pushbutton','String','Start analysis','Units','normalized',...
            'Position',[.345 .82 .3 .13],'FontSize',15,'Callback',@select_resolution,...
            'Enable','off','Parent',win.h_fig);
        
win.b_stop = uicontrol('Style','pushbutton','String','Stop analysis','Units','normalized',...
            'Position',[.67 .82 .31 .13],'FontSize',15,'Callback',@stop_analysis,...
            'Enable','off','Parent',win.h_fig);
        
win.h_panel = uipanel('Parent',win.h_fig,'Position',[.02 .2 .96 .57],'BackgroundColor','white');

uicontrol('Style','text','String','Experiment name:','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.03 .7 .4 .2],...
    'HorizontalAlignment','left','FontWeight','bold');
uicontrol('Style','text','String','No. images:','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.03 .48 .4 .2],...
    'HorizontalAlignment','left','FontWeight','bold');
uicontrol('Style','text','String','No. trays:','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.03 .25 .4 .2],...
    'HorizontalAlignment','left','FontWeight','bold');
uicontrol('Style','text','String','No. timepoints:','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.03 .03 .4 .2],...
    'HorizontalAlignment','left','FontWeight','bold');

win.t_expname = uicontrol('Style','text','String','-','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.3 .7 .4 .2],...
    'HorizontalAlignment','left');
win.t_nimages = uicontrol('Style','text','String','-','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.3 .48 .4 .2],...
    'HorizontalAlignment','left');
win.t_ntrays = uicontrol('Style','text','String','-','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.3 .25 .4 .2],...
    'HorizontalAlignment','left');
win.t_ntimepoints = uicontrol('Style','text','String','-','Parent',win.h_panel,...
    'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.3 .03 .4 .2],...
    'HorizontalAlignment','left');

win.a_pbar = axes(win.h_fig,'Position',[.02 .04 .96 .12],'Box','on','XTickLabels',[],...
             'YTickLabels',[],'XTickMode','manual','Xtick',[],'YTick',[]);
win.t_percent = text(win.a_pbar,.5,.5,'0% - ETG 00:00:00','Units','normalized','HorizontalAlignment','center',...
                'FontSize',15);
            
step = 1;

end




function open_experiment(~,~)
global win;
global exp_path;
global i_im nimages fimages strays indtray sdates;
global results scorelog samplename_log;
global symbol;

if ismac | isunix
    symbol = '/';
else
    symbol = '\';
end

    exp_path = uigetdir;
    if ~exp_path
        return;
    end
    

    bars = strfind(exp_path, symbol);
    set(win.t_expname,'String',exp_path(bars(end)+1:end));

    nimages.total = 0;
    [nimages.total,fimages,strays,sdates] = get_expdata(exp_path);
    if ~nimages.total
        errordlg('Invalid Experiment folder: Check data integrity.');
        restart_app;
        return;
    end
    
    %Get unique trays indexes
    ntrays = 0;
    indtray = containers.Map;
    for i=1:numel(sdates)
        for j=1:numel(strays{i})
            if ~indtray.isKey(strays{i}{j})
                ntrays = ntrays + 1;
                indtray(strays{i}{j}) = ntrays;
            end
        end
    end
    
    results = cell(351,numel(sdates),ntrays);

    i_im.cs=1;i_im.ct=1;i_im.cd=1;
    nimages.current = 0;
    results{1,1,1}='Sample';
    
    if isempty(fimages{1}{1}{1})
        results{2,2,1} = 'N/A';
        next_im;
    else
        results{1,2,1} = sdates{i_im.cd};
    end
     
    scorelog = cell(351,numel(sdates),ntrays);
    samplename_log = cell(351,ntrays);

    set(win.t_nimages,'String', num2str(nimages.total));
    set(win.t_ntrays,'String', num2str(ntrays));
    set(win.t_ntimepoints,'String', num2str(numel(sdates)));

    set(win.b_start,'Enable','on');
end

function [nimages,fimages,strays,sdates] = get_expdata(fpath)

    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end

        nimages=0;fimages={};strays={};sdates={};
        
        datefolders = struct2table(dir(fpath));
        datefolders = datefolders(datefolders.isdir,:);
        if numel(datefolders)<3
            return;
        end
        datefolders = datefolders(3:end,:);
        sdates = table2cell(datefolders(:,1));
		
		%%DATEFOLDER SORTING BY DATE
		if ~isempty(strfind(sdates{1},'dpi')) %NEW DPI LABELING
			for i=1:numel(sdates)
				dind = strfind(sdates{i},'_');
				sdates{i} = sdates{i}(1:dind-1);
			end
			ddates = datetime(sdates,'InputFormat','MM-dd-yy');
		else                                  %OLD LABELING
			ddates = datetime(sdates,'InputFormat','MM_dd_yy');
		end
		[~,ind_dates] = sort(ddates);
		datefolders = datefolders(ind_dates,:);
		sdates = table2cell(datefolders(:,1));
        
        for nd=1:numel(datefolders(:,1)) %Loop through date folders
            trayfolders = struct2table(dir([datefolders.folder{nd} symbol datefolders.name{nd}]));
            trayfolders = trayfolders(trayfolders.isdir,:);
            if numel(trayfolders)<3
                return;
            end
            trayfolders_i = trayfolders(3:end,:);
            trayfolders = table;
            for ti=1:size(trayfolders_i,1)
                if isempty(strfind(trayfolders_i.name{ti},'scoremaps'))
                    trayfolders(end+1,:) = trayfolders_i(ti,:);
                end
            end
            strays{nd} = table2cell(trayfolders(:,1));
            
            for nt=1:numel(strays{nd}) %Loop through tray folders
               imagefiles = struct2table(dir([datefolders.folder{nd} symbol ...
                   datefolders.name{nd} symbol trayfolders.name{nt} ]));
               imagefiles = table2cell(imagefiles(:,1));
               imagefiles = imagefiles(contains(imagefiles,'.png'));
           
               fimages{nd}{nt} = cell(1,351);
               for ni=1:numel(imagefiles)
                   nlim = strfind(imagefiles{ni},'-');
                   nsample = str2double(imagefiles{ni}(1:nlim(1)-1));
                   fimages{nd}{nt}{nsample}=imagefiles{ni};
               end
               nimages = nimages+size(imagefiles,1);
            end
        end
end

function select_resolution(~,~)
    global win;

    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end

    win.h_fig_sres = figure('Position',[600 400 350 300],'Tag','Res_fig','MenuBar',...
            'none','ToolBar','none','Name','Select analysis resolution...','NumberTitle',...
            'off','Resize','off','WindowStyle','modal','CloseRequestFcn',@select_resolution_KO);
        
    uicontrol('Style','pushbutton','String','Start','Units','normalized',...
                'Position',[.56 .04 .3 .1],'FontSize',10,'Callback',@select_resolution_OK,...
                'Enable','on','Parent',win.h_fig_sres);
    uicontrol('Style','pushbutton','String','Cancel','Units','normalized',...
                'Position',[.13 .04 .3 .1],'FontSize',10,'Callback',@select_resolution_KO,...
                'Enable','on','Parent',win.h_fig_sres);
            
    win.b_radiogroup = uibuttongroup(win.h_fig_sres,'Position',[0 0.17 1 .8],'SelectionChangedFcn',@bselection);
    
    uicontrol(win.b_radiogroup,'Style','radiobutton','String','Low-Resolution (1:1)','Units','normalized',...
    'Position',[.05 .75 .7 .15],'FontSize',10,'UserData',1);
    uicontrol(win.b_radiogroup,'Style','radiobutton','String','Standard-Resolution (1:2)','Units','normalized',...
    'Position',[.05 .55 .7 .15],'FontSize',10,'UserData',2);
    uicontrol(win.b_radiogroup,'Style','radiobutton','String','High-Resolution (1:5)','Units','normalized',...
    'Position',[.05 .35 .7 .15],'FontSize',10,'UserData',5);
    uicontrol(win.b_radiogroup,'Style','radiobutton','String','Ultra-High Resolution (1:10)','Units','normalized',...
    'Position',[.05 .15 .7 .15],'FontSize',10,'UserData',10);
           
end

function bselection(~,ev)
global step;
    step = ev.NewValue.UserData;
end

function select_resolution_OK(obj,~)
global win;
    delete(win.h_fig_sres);
    start_analysis;
end

function select_resolution_KO(~,~)
global win step;
    step = 1;
    delete(win.h_fig_sres);
end

function start_analysis
    global i_im finish win results fimages sdates strays nimages exp_path scorelog samplename_log indtray step;

    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end


    set(win.b_start,'Enable','off');
    set(win.b_open,'Enable','off');
    set(win.b_stop,'Enable','on');
    drawnow;

    % CHANGE CNN HERE
    % load SporeNet3.mat; % orginal line of code
%     load HairyDMNet.mat;
%     load HwangDMNet_This_works.mat
    load HempDMNet3.mat
    net2 = PMnet;

    pbar = ones(1,nimages.total,3);
    impbar = image(win.a_pbar,pbar);
    set(win.a_pbar,'XTickLabels',[],'YTickLabels',[],'YTick',[]);
    win.t_percent = text(win.a_pbar,.5,.5,'0% - ETG 00:00:00','Units',...
        'normalized','HorizontalAlignment','center','FontSize',15);
    pbar_i = 1;
    drawnow;
    
    t1=tic;t=nan(1,nimages.total);
    finish = 0;
	
	if isempty(fimages{i_im.cd}{i_im.ct}{i_im.cs})
        finish = next_im;
    end
	
    while ~finish
        nimages.current = nimages.current+1;
        impath = [exp_path symbol sdates{i_im.cd} symbol strays{i_im.cd}{i_im.ct} symbol fimages{i_im.cd}{i_im.ct}{i_im.cs}];
        
        sname = fimages{i_im.cd}{i_im.ct}{i_im.cs};
        
        i_tray = indtray(strays{i_im.cd}{i_im.ct});
        
        results{i_im.cs+1,1,i_tray} = [sname(1:end-4) '.'];
        score = compute_sample(impath,net2,sname,step);
        scorelog{i_im.cs,i_im.cd,i_tray} = score;
        samplename_log{i_im.cs,i_tray} = sname(1:end-4);
        
        %Update bar
        pbar(1,pbar_i,2)=0;pbar(1,pbar_i,3)=0;
        pbar_i=pbar_i+1;
        set(impbar,'CDATA',pbar);
        
        %set ETG
        t(nimages.current) = toc(t1);t1=tic;
        ETG = round(mean(t,'omitnan'))*(nimages.total-nimages.current);
        tsec = mod(ETG,60);
        tmin = mod(floor(ETG/60),60);
        thour = floor(ETG/3600);
        percent = floor(nimages.current/nimages.total*100);
        set(win.t_percent,'String',[num2str(percent) '% - ETG ' sprintf('%02u',thour)...
            ':' sprintf('%02u',tmin) ':' sprintf('%02u',tsec)]);
        
        finish = next_im;
        drawnow;
    end
    
    if ~save_results
        restart_app;
    end
    set(win.b_start,'Enable','on');
    set(win.b_open,'Enable','on');
    set(win.b_stop,'Enable','off');
end


function finish = next_im
    global i_im strays sdates fimages;
    while 1
        if i_im.cs==351
            i_im.cs = 1;
            if i_im.ct == numel(strays{i_im.cd})
                i_im.ct = 1;
                if i_im.cd == numel(sdates)
                    finish=1;
                    return;
                else
                    i_im.cd = i_im.cd+1;
                end
            else
                i_im.ct = i_im.ct+1;
            end
        else
            i_im.cs = i_im.cs+1;
        end
        if ~isempty(fimages{i_im.cd}{i_im.ct}{i_im.cs})
            finish = 0;
            break;
        end
    end
end

function result_map = compute_sample(impath,net,sname,step)

    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end

    subSizeX = 224;
    subSizeY = 224;
    result_map = [];
    try
        %tic;
        curImage = im2uint8(imread(impath));
        disp(['Loaded: ' impath]);
        %disp(['Image loading time: ' num2str(toc)]);
    catch
        warning(['Error loading: ' impath]);
        return;
    end
    [h,w,~] = size(curImage);

    %tic;
    
    %Relative thresholding (0 < rth < 1)
    % PMbot works best with 0.2
    % Blackbird works best with 0.1
    % Use mexOpenCV2 script to re-compile if needed
    rth = 0.1;
    [imask,~,~] = leaf_mask_par_02(im2uint8(curImage),rth);
    %figure;imagesc(imask);
    if isempty(imask)
        warning('Image masking ERROR');
        return;
    end
    
    %maskedimage = curImage.*repmat(floor(imask/255),[1,1,3]);
    %figure;image(maskedimage);
    
    step = floor(subSizeX/step);
    offsetX = rem((w-subSizeX),step);
    offsetY = rem((h-subSizeY),step);
    
    last_l_ind = floor((h-subSizeY)/step) * floor((w-subSizeX)/step);
    
    sub_images_ind = zeros(last_l_ind,2);
    for i=1:last_l_ind
        xc = mod(i-1,floor((w-subSizeX)/step))+1;
        yc = (ceil(i/(floor((w-subSizeX)/step))));
  
        curr_subim_mask = imcrop(imask,[((xc-1)*step)+1+offsetX ((yc-1)*step)+1+offsetY subSizeX-1 subSizeY-1]);
        if(isOnFocus(curr_subim_mask))
            sub_images_ind(i,:) = [xc yc];
        end
    end
    sub_images_ind(~sub_images_ind(:,1),:)=[];
    
    n_subim_x_iteration = 2000;
    result_map = nan(ceil((h-subSizeY)/step),ceil((w-subSizeX)/step));
    for i=1:n_subim_x_iteration:length(sub_images_ind)
        if (i+n_subim_x_iteration)>length(sub_images_ind)
            n_subim = length(sub_images_ind)-(i-1);
        else
            n_subim = n_subim_x_iteration;
        end
        sub_images = zeros([subSizeY subSizeX 3 n_subim]);
        
        for j=1:n_subim
            sub_images(:,:,:,j) = imcrop(curImage,[((sub_images_ind((i-1)+j,1)-1)*step)+1+offsetX ...
                                  ((sub_images_ind((i-1)+j,2)-1)*step)+1+offsetY subSizeX-1 subSizeY-1]);
        end
        group = ['Infected', 'clear'];
            [pred,score] = classify(net,sub_images);
        %Check association between result score and category 
        if(score(1,1) > score(1,2))
            if strcmp(char(pred(1)),'Infected')
                score = score(:,1);
            else
                score = score(:,2);
            end
        else
            if strcmp(char(pred(1)),'Infected')
                score = score(:,2);
            else
                score = score(:,1);
            end
        end
        for j=1:n_subim
            result_map(sub_images_ind((i-1)+j,2),sub_images_ind((i-1)+j,1))=score(j);
        end
    end
    %disp(['Image processing time: ' num2str(toc)]);
    
    %generate_result_image(im2uint8(curImage),result_map,step,[offsetX offsetY],impath);
end

function stop_analysis(src,~)
global finish;

    answer = questdlg('Are you sure you want to stop the analysis?','Stop process',...
            'Yes','No','Yes');
    switch answer
        case 'Yes'
            finish = 1;
            set(src,'Enable','off');
            
    end
end

function err = save_results

    global exp_path scorelog samplename_log win indtray sdates;
    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end

    err = 0;
    try
        exp_name = get(win.t_expname,'String');
        strays = indtray.keys;
        save([ exp_path symbol 'PMresults.score'],'scorelog','samplename_log','strays','sdates','exp_name');
    catch
        errordlg('Error saving results! Enough space?');
        err = 1;
        return;
    end
end

function PMclose(src,~)
    global finish win;
    if ~finish
        stop_analysis(win.b_stop,[]);
        if finish
            delete(src);
        end
    else
        delete(src);
    end
end

function restart_app
    global win i_im finish results fimages sdates strays nimages exp_path;
    i_im = []; finish = 1; results = []; fimages = []; sdates = [];
    strays = []; nimages = []; exp_path = [];
    
    set(win.t_percent,'String','0% - ETG 00:00:00');
    set(win.t_nimages,'String', '-');
    set(win.t_ntrays,'String', '-');
    set(win.t_ntimepoints,'String', '-');
    set(win.t_expname,'String','-');
end

function focused = isOnFocus(img)

    mask_ratio = mean(img(:)/255);
    if mask_ratio > .7
        focused = true;
    else
        focused = false;
    end
end

function generate_result_image(im,scoremap,step, offsets, impath)
    global symbol;

    if ismac | isunix
        symbol = '/';
    else
        symbol = '\';
    end
 
    fig = figure('units','normalized','outerposition',[0 0 1 1]);
    ax = axes(fig);
    image(ax,im);
    axis(ax,'equal');
    subSizeX = 224;
    subSizeY = 224;
    
    offsetX = offsets(1);
    offsetY = offsets(2);
    
    offsetW = floor((subSizeX-step)/2);
    
    hold(ax,'on'); 
    yf = size(scoremap,1);
    xf = size(scoremap,2);
    cmap = jet(256);
    for i=1:yf
        for j=1:xf
            if ~isnan(scoremap(i,j))
                c = [cmap(ceil(scoremap(i,j)*255),:) .3];
                rectangle('Position',[offsetX+offsetW+((j-1)*step)+1,offsetY+offsetW+((i-1)*step)+1,step,step],'FaceColor',c,...
                    'EdgeColor','none');
            end
        end
    end
    hold(ax,'off');
    
%%%%%Save figure to file (Uncomment to enable)
%     ind = strfind(impath, symbol );
%     dirpath = impath(1:ind(end)-1);
%     dirpath = [dirpath '_scoremaps'];
%     if ~exist(dirpath, 'dir')
%         mkdir(dirpath);
%     end
%     impath = [dirpath impath(ind(end):end)];
%     impath(end-3:end) = '';
%     saveas(fig,[impath '.jpg']);
%     
%     delete(fig);
end
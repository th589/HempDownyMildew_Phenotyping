function ThresholderAPP_00
global win;

    win.h_fig = figure('Position',[500 400 700 300],'Tag','MR_fig','MenuBar',...
                'none','ToolBar','none','Name','Thresholding App','NumberTitle',...
                'off','Resize','off');

    win.b_open = uicontrol('Style','pushbutton','String','Open','Units','normalized',...
             'Position',[.02 .82 .3 .13],'FontSize',15,'Callback',@open_results,...
             'Enable','on','Parent',win.h_fig);

    win.b_export = uicontrol('Style','pushbutton','String','Export results','Units','normalized',...
                'Position',[.345 .82 .3 .13],'FontSize',15,'Callback',@export_results_win,...
                'Enable','off','Parent',win.h_fig);
            
    win.b_exportQC = uicontrol('Style','pushbutton','String','Export QC','Units','normalized',...
                'Position',[.67 .82 .3 .13],'FontSize',15,'Callback',@export_QC,...
                'Enable','off','Parent',win.h_fig);

    win.h_panel = uipanel('Parent',win.h_fig,'Position',[.02 .2 .96 .57],'BackgroundColor','white');

    uicontrol('Style','text','String','Experiment name:','Parent',win.h_panel,...
        'BackgroundColor','white','Fontsize',12,'Units','normalized','Position',[.03 .7 .4 .2],...
        'HorizontalAlignment','left','FontWeight','bold');
    uicontrol('Style','text','String','No. samples:','Parent',win.h_panel,...
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
    win.t_nsamples = uicontrol('Style','text','String','-','Parent',win.h_panel,...
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
    win.t_percent = text(win.a_pbar,.5,.5,'Load results','Units','normalized','HorizontalAlignment','center',...
                    'FontSize',15);
end

function open_results(~,~)
global win;
global res_path;
global results scores ssamples strays sdates invalidSubim;

    [fname,path] = uigetfile('*.score');
    if ~fname
        return;
    end
    res_path = [path,fname];
    data = load(res_path,'-mat');
    
    if ~isfield(data,'scorelog') || ~isfield(data,'samplename_log') || ~isfield(data,'exp_name')...
            || ~isfield(data,'sdates') || ~isfield(data, 'strays')
        errordlg('Invalid result data file!');
        restart_app;
        return;
    end
    
    sdates = data.sdates;
    strays = data.strays;
    ssamples = data.samplename_log;
    scores = data.scorelog;
    
    nsamples = sum(~cellfun(@isempty,scores(:)));
    
    ntrays = numel(strays);
    
    results = cell(numel(ssamples(:,1)),numel(sdates),ntrays);
    invalidSubim = cell(numel(ssamples(:,1)),numel(sdates),ntrays);
  
% Results:    
    for i=1:ntrays
        results{1,1,i}='Sample';
        for j=1:numel(sdates)
            results{1,1+j,i}=sdates{j};
        end
        for k=1:numel(ssamples(:,i))
            if ~isempty(ssamples{k,i})
                results{1+k,1,i}=ssamples{k,i};
            else
                results{1+k,1,i}='N/A';
            end
        end
    end
    
% Subims:
    for i=1:ntrays
        invalidSubim{1,1,i}='Sample';
        for j=1:numel(sdates)
            invalidSubim{1,1+j,i}=sdates{j};
        end
        for k=1:numel(ssamples(:,i))
            if ~isempty(ssamples{k,i})
                invalidSubim{1+k,1,i}=ssamples{k,i};
            else
                invalidSubim{1+k,1,i}='N/A';
            end
        end
    end
    set(win.t_expname,'String', num2str(data.exp_name));
    set(win.t_nsamples,'String', num2str(nsamples));
    set(win.t_ntrays,'String', num2str(ntrays));
    set(win.t_ntimepoints,'String', num2str(numel(sdates)));

    set(win.b_export,'Enable','on');
    set(win.b_exportQC,'Enable','on');
end

function export_results_win(~,~)
global win;
    win.h_fig2 = figure('Position',[500 400 300 300],'Tag','EXPORT_fig','MenuBar',...
                'none','ToolBar','none','Name','Export results','NumberTitle',...
                'off','Resize','off','WindowStyle','modal','CloseRequestFcn',@EXPORT_close);
            
    win.b_export2 = uicontrol('Style','pushbutton','String','Export','Units','normalized',...
                'Position',[.3 .04 .4 .1],'FontSize',10,'Callback',@export_results,...
                'Enable','on','Parent',win.h_fig2);
            
    win.b_radiogroup = uibuttongroup('Position',[0 0.17 1 .8],'SelectionChangedFcn',@bselection);
              
    win.b_radio2(1) = uicontrol(win.b_radiogroup,'Style','radiobutton','String','Threshold','Units','normalized',...
    'Position',[.05 .8 .5 .15],'FontSize',10);

    uicontrol('Style','text','String','Lower:','Units','normalized',...
    'Position',[.15 .68 .25 .1],'FontSize',10,'Parent',win.h_fig2);
    win.e_thresh(1) = uicontrol('Style','edit','String','0.2','Units','normalized',...
    'Position',[.4 .7 .4 .1],'FontSize',10,'Enable','on');
    uicontrol('Style','text','String','Upper:','Units','normalized',...
    'Position',[.15 .48 .25 .1],'FontSize',10,'Parent',win.h_fig2);
    win.e_thresh(2) = uicontrol('Style','edit','String','0.8','Units','normalized',...
    'Position',[.4 .5 .4 .1],'FontSize',10);

    win.b_radio2(2) = uicontrol(win.b_radiogroup,'Style','radiobutton','String','Average','Units','normalized',...
    'Position',[.05 .2 .5 .15],'FontSize',10);

end

function bselection(~,ev)
global win;
    if strcmp(ev.EventName,'SelectionChanged')
        
        switch(ev.OldValue.String)
            case 'Threshold'
                set(win.e_thresh,'Enable','off');
            case 'Average'
        end
        
        switch(ev.NewValue.String)
            case 'Threshold'
                set(win.e_thresh,'Enable','on');
            case 'Average'
        end
    end
end

function export_results(~,~)
global win results scores strays;

    operation = win.b_radiogroup.SelectedObject.String;
    switch(operation)
        case 'Threshold'
            up_th = str2double(get(win.e_thresh(2),'String'));
            down_th = str2double(get(win.e_thresh(1),'String'));
            if up_th <= down_th
                errordlg('Invalid thresholds');
                return;
            end
        case 'Average'
    end
    [fname,path] = uiputfile({'*.xlsx'});
    if isempty(fname)
        return;
    end
    %Start export
    set(win.b_export,'Enable','off');
    set(win.b_open,'Enable','off');
    close(win.h_fig2);
    
    total_samples = sum(~cellfun(@isempty,scores(:)));
    pbar = ones(1,total_samples,3)*0.8;
    impbar = image(win.a_pbar,pbar);
    set(win.a_pbar,'XTickLabels',[],'YTickLabels',[],'YTick',[]);
    win.t_percent = text(win.a_pbar,.5,.5,'0%','Units',...
        'normalized','HorizontalAlignment','center','FontSize',15);
    pbar_i = 1;
    drawnow;
    refresh;
    
    [nsamples,ndates,ntrays] = size(results);
    nsamples = nsamples-1;
    ndates = ndates - 1;
    curr_sample = 1;
    for i=1:ntrays
        for j=1:ndates
            for k=1:nsamples
                if isempty(scores{k,j,i})
                    continue;
                end
                switch(operation)
                    case 'Threshold'
                        n_infect = numel(find(scores{k,j,i} >= up_th));
                        n_clear = numel(find(scores{k,j,i} <= down_th));
                        value = round(n_infect/(n_clear+n_infect)*100);
                    case 'Average'
                        value = round(mean(scores{k,j,i},'omitnan')*100);
                end               
                results{k+1,j+1,i} = value;
                %Update bar
                pbar(1,pbar_i,1)=0;pbar(1,pbar_i,3)=0;
                pbar_i=pbar_i+1;
                set(impbar,'CDATA',pbar);
                percent = floor(curr_sample/total_samples*100);
                curr_sample = curr_sample + 1;
                set(win.t_percent,'String',[num2str(percent) '%']);
                drawnow;
            end
        end
    end
    
    excel = actxserver('Excel.Application.16');
    try
        for t=1:ntrays
            warning off;
            xlswrite([path fname],results(:,:,t),t,'A1');
            warning on;
            ewb = excel.Workbooks.Open([path fname]);
            ewb.Worksheets.Item(t).Name = strays{t};
            ewb.Save;
            ewb.Close(false);
        end
    catch
        errordlg('Error saving results! Maybe locked by other process.');
    end
    excel.Quit;
    set(win.b_export,'Enable','on');
    set(win.b_open,'Enable','on');
    drawnow;
    refresh;
end

function export_QC(~,~)
global win results scores strays invalidSubim;

    [fname,path] = uiputfile({'*.xlsx'});
    if isempty(fname)
        return;
    end
    
    %Start export
    total_samples = sum(~cellfun(@isempty,scores(:)));
    pbar = ones(1,total_samples,3)*0.8;
    impbar = image(win.a_pbar,pbar);
    set(win.a_pbar,'XTickLabels',[],'YTickLabels',[],'YTick',[]);
    win.t_percent = text(win.a_pbar,.5,.5,'0%','Units',...
        'normalized','HorizontalAlignment','center','FontSize',15);
    pbar_i = 1;
    drawnow;
    refresh;
    
    [nsamples,ndates,ntrays] = size(invalidSubim);
    nsamples = nsamples-1;
    ndates = ndates - 1;
    curr_sample = 1;
    for i=1:ntrays
        for j=1:ndates
            for k=1:nsamples
                if isempty(scores{k,j,i})
                    continue;
                end
                invalidSubim{k+1,j+1,i} = nnz(isnan(scores{k,j,i}));
                %Update bar
                pbar(1,pbar_i,1)=0;pbar(1,pbar_i,3)=0;
                pbar_i=pbar_i+1;
                set(impbar,'CDATA',pbar);
                percent = floor(curr_sample/total_samples*100);
                curr_sample = curr_sample + 1;
                set(win.t_percent,'String',[num2str(percent) '%']);
                drawnow;
            end
        end
    end
    
    excel = actxserver('Excel.Application.16');
    try
        for t=1:ntrays
            warning off;
            xlswrite([path fname],invalidSubim(:,:,t),t,'A1');
            warning on;
            ewb = excel.Workbooks.Open([path fname]);
            ewb.Worksheets.Item(t).Name = strays{t};
            ewb.Save;
            ewb.Close(false);
        end
    catch
        errordlg('Error saving results! Maybe locked by other process.');
    end
    excel.Quit;
    set(win.b_export,'Enable','on');
    set(win.b_open,'Enable','on');
    drawnow;
    refresh;
end

function EXPORT_close(obj,~)
global win;
    set(win.h_fig,'CloseRequestFcn','closereq');
    set([win.b_open win.b_export],'Enable','on');
    delete(obj);
end

function restart_app
global win  exp_path;
    exp_path = [];
    set(win.t_percent,'String','Load results');
    set(win.t_nimages,'String', '-');
    set(win.t_ntrays,'String', '-');
    set(win.t_ntimepoints,'String', '-');
    set(win.t_expname,'String','-');
end
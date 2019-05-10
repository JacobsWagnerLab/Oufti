function [T2]=growthFitbyOD(GC,OD_in,OD_fin,show)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% function [T2]=growthFit_OD(GC,OD_in,OD_fin,show)
%
% @authors: Manuel Campos
% @dat:     December 16 2014
% @copyright 2014-2015 Yale University
%==========================================================================
%**********OUTPUT**********
%T2:        An n_wells-by_3 matrix T2, where 1st column are calculated g
%           doublin times T2, and 2nd and 3 rd columns are the lower and   
%           upper boundaries of the 95% confidence interval of the fitting.
%==========================================================================
%**********INPUT*********** 
% GC:       matrix of OD data with Time data as first column, 
%           other columns are multiple ODs. Create a matrix that you name
%           GC, that contains all the data.
%
% OD_in:    OD at which to start fitting defined as first point at which
%           OD(t_in)=OD_in
%
% OD_fin:   Upper OD boundary for fitting
%
% show:     true/false or 1/0 to show individual growthcurve/fiting results.
%           Put "true" if you want to see the actual fits (opens a figure).
%           You can modify the fitting boundaries through a dialog box.
%           Put "false" if you trust the script (or parameters) for all the
%           growth curves of the experiment.
% 
% Example:
% Type GC=[]; open the empty array and copy the data from the plate reader.
% [T2,T2_table]=growthFit(GC,0.1,0.3,true);
%The function will create a table (T2_table) that contains the doubling
%time (in whatever unit your time data are - first column of GC).

% initial data preparation
TT=GC(:,1);
OD_all=GC(:,2:end);
n_wells=size(OD_all,2);

T2=nan(n_wells,3); % for output

if show
    fit_plot=figure('position',[50 50 560 700]);
    pause on;
end    
 
for kk=1:n_wells
    OD1=OD_all(:,kk); 
    % find t_in-t_fin
    ii_in=find(OD1>OD_in,1,'first');
    ii_fin=find(OD1>OD_fin,1,'first')-1;
    if max(OD1)<OD_fin
        ii_fin=length(OD1);
    end
    if (length([ii_in,ii_fin])>1) && (ii_fin-ii_in>10)
        TTcut=TT(ii_in:ii_fin)-TT(ii_in);
        modelExp = fittype('a*exp(b*x)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a', 'b', 'c'});
        par0 = [0.05 0.01 0.05];
        fit1 = fit(TTcut,OD1(ii_in:ii_fin),modelExp,'Startpoint',par0);
        b=fit1.b;%coeff(2);
   
        if show
            fig_name=['well #',num2str(kk),'     t_2=',num2str(log(2)/fit1.b,3)];
            figure (fit_plot);
            set(fit_plot, 'Name', fig_name);
            subplot(2,1,1);
            plot(fit1,TTcut,OD1(ii_in:ii_fin),'-o');
            hh=legend;set(hh,'location','northwest');
            xlabel('time, min');ylabel('OD');
            subplot(2,1,2);
            plot(fit1,TTcut,OD1(ii_in:ii_fin),'b+','residuals');
            xlabel('time, min');ylabel('fit residuals');
            hold off

            prompt={'new OD start?','new OD end'};
            dlg_title='Choose OD boundaries';
            numlines=1;
            def={num2str(OD_in),num2str(OD_fin)};
            answer=inputdlg(prompt,dlg_title,numlines,def);
            numanswer=[str2double(answer{1}),str2double(answer{2})];

            while numanswer(1)~=OD_in || numanswer(2)~=OD_fin
                OD_in=numanswer(1);OD_fin=numanswer(2);
                ii_in=find(OD1>OD_in,1,'first');
                ii_fin=find(OD1>OD_fin,1,'first')-1;
                if max(OD1)<OD_fin ii_fin=length(OD1); end
                if (length([ii_in,ii_fin])>1) && (ii_fin-ii_in>10)
                TTcut=TT(ii_in:ii_fin)-TT(ii_in);
                modelExp = fittype('a*exp(b*x)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a', 'b', 'c'});
                par0 = [0.05 0.01 0.05];
                fit1 = fit(TTcut,OD1(ii_in:ii_fin),modelExp,'Startpoint',par0);
                b=fit1.b;

                fig_name=['well #',num2str(kk),'     t_2=',num2str(log(2)/fit1.b,3)];
                figure (fit_plot);
                set(fit_plot, 'Name', fig_name);
                subplot(2,1,1);
                plot(fit1,TTcut,OD1(ii_in:ii_fin),'-o');
                hh=legend;set(hh,'location','northwest');
                xlabel('time, min');ylabel('OD');
                subplot(2,1,2);
                plot(fit1,TTcut,OD1(ii_in:ii_fin),'b+','residuals');
                xlabel('time, min');ylabel('fit residuals');
                hold off
                
                prompt={'new OD start?','new OD end'};
                dlg_title='Choose OD boundaries';
                numlines=1;
                def={num2str(OD_in),num2str(OD_fin)};
                answer=inputdlg(prompt,dlg_title,numlines,def);
                numanswer=[str2double(answer{1}),str2double(answer{2})];
                end
            end
        end
        ci = confint(fit1);
        T2(kk,1)=log(2)/b;
        T2(kk,2) = log(2)/ci(2,2);
        T2(kk,3) = log(2)/ci(1,2);

    end
end

close(gcf);
pause off;


figure;
xabs=1:1:length(T2);xabs(2,:)=xabs;
plot(xabs,T2(:,2:3)','-b','linewidth',2);hold on;plot(T2(:,1),'sb','markerfacecolor','w');
set(gca,'Fontname','arial','fontsize',14);
xlabel('strains','Fontname','arial','fontsize',14,'fontweight','b');
ylabel('Doubling time (min)','Fontname','arial','fontsize',14,'fontweight','b');
end

% function [numanswer,fit1]=showFit(figHdl,fit1,Xdata,Ydata,counter,OD_in,OD_fin)
%     fig_name=['well #',num2str(counter),'     t_2=',num2str(fit1.b)];
%     figure (figHdl);
%     set(fit_plot, 'Name', fig_name);
%     subplot(2,1,1);
%     plot(fit1,Xdata,Ydata,'-o');
%     hh=legend;set(hh,'location','northwest');
%     xlabel('time, min');ylabel('OD');
%     subplot(2,1,2);
%     plot(fit1,Xdata,Ydata,'b+','residuals');
%     xlabel('time, min');ylabel('fit residuals');
%     hold off
% 
%     prompt={'new OD start?','new OD end'};
%     dlg_title='Choose OD boundaries';
%     numlines=1;
%     def={num2str(OD_in),num2str(OD_fin)};
%     answer=inputdlg(prompt,dlg_title,numlines,def);
%     numanswer=[str2double(answer{1}),str2double(answer{2})];
%     if numanswer(1)>numanswer(2)
%         prompt={'new OD start?','new OD end'};
%         dlg_title='OD start WAS > OD end!!!!!!!!!!!!';
%         numlines=1;
%         def={num2str(OD_in),num2str(OD_fin)};
%         answer=inputdlg(prompt,dlg_title,numlines,def);
%         numanswer=[str2double(answer{1}),str2double(answer{2})];
%     end
% end        

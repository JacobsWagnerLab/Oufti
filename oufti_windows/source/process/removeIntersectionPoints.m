function [xCoordinateOut, yCoordinateOut] = removeIntersectionPoints(iout,jout,xCoordinateIn,...
                                                                     yCoordinateIn)
                                                                 
 xx = xCoordinateIn;
 yy = yCoordinateIn;
 if (~length(iout) == 0)
     iout = fliplr((sort(iout))');
     jout = fliplr((sort(jout))');
 counterx = 0;
 countery = 0;
 for ii = 1:length(iout)
     if (ii > 1) && (jout(ii) == jout(ii-1)), counterx = counterx + 1;end
     if length(xx) < iout(ii)
%          counterx = counterx + 1;
         xx(iout(ii)-(1+counterx)) = [];
        
     else
         xx(iout(ii)) = [];
     end
     if (ii > 1) && (jout(ii) == jout(ii-1)), countery = countery + 1;end
     if length(yy) < jout(ii)
%          countery = countery + 1;
         yy(jout(ii)-(1+countery)) = [];
         
     else
         yy(jout(ii)) = [];
     end
 end
 end
     
% % % if (~length(iout) == 0)
% % % counter = 0;
% % % for ii = 1:length(iout)
% % %     if counter >= 1
% % %        if isnan(xx(iout(ii)-1))
% % %           if iout(ii) > length(xx)
% % %              xx(iout(ii)-1) = [];
% % %           else
% % %               if isnan(xx(iout(ii)+1))
% % %                  xx(iout(ii)+2) = [];
% % %               elseif isnan(xx(iout(ii)+2))
% % %                      xx(iout(ii)+3) = [];
% % %               elseif isnan(xx(iout(ii)+3))
% % %                      xx(iout(ii)+4) = [];
% % %               elseif isnan(xx(iout(ii)+4))
% % %                      xx(iout(ii)+5) = [];
% % %               elseif isnan(xx(iout(ii)+5))
% % %                      xx(iout(ii)+6) = [];
% % %               else
% % %                       xx(iout(ii)+1) = [];
% % %               end
% % %           end
% % %         else
% % %             xx(iout(ii)) = [];
% % %         end
% % %         if isnan(yy(jout(ii)-1))
% % %            if jout(ii) > length(yy)
% % %               yy(jout(ii)-1) =[];
% % %            else
% % %                if isnan(yy(jout(ii)+1))
% % %                   yy(jout(ii)+2) = [];
% % %                elseif isnan(yy(jout(ii)+2))
% % %                       yy(jout(ii)+3) = [];
% % %                elseif isnan(yy(jout(ii)+3))
% % %                       yy(jout(ii)+4) = [];
% % %                elseif isnan(yy(jout(ii)+4))
% % %                       yy(jout(ii)+5) = [];
% % %                elseif isnan(yy(jout(ii)+5))
% % %                       yy(jout(ii)+6) = [];
% % %                else
% % %                       yy(jout(ii)+1) = [];
% % %                end
% % %            end
% % %         else
% % %             yy(jout(ii)) = [];
% % %         end
% % %      else
% % %          xx(iout(ii)) = [];
% % %          yy(jout(ii)) = [];
% % %      end
% % %          counter = counter + 1;
% % % end
% % % end
xCoordinateOut = xx;
yCoordinateOut = yy;

end





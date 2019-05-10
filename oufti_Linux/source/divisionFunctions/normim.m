function IMn=normim(IM)

IMn=(IM-min(min(IM)))/(max(max(IM))-min(min(IM)));
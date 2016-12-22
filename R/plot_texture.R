library("tidyr")
library("dplyr")
library("ggplot2")
library("cowplot")
library("DeLuciatoR")
library("ggplotTicks")

thm = theme_ggEHD()+theme(aspect.ratio=1.5)

coremass = (read.csv("rawdata/giddings_rootmass.csv")
	%>% mutate(Depth=Depth_top+(Depth_bottom-Depth_top)/2))
core_labels = (coremass
	%>% filter(Depth==5)
	%>% mutate(Depth=10))

texture = (read.csv("rawdata/soil_properties_2008.csv")
	%>% mutate(DepthBottom=as.numeric(DepthBottom)-0.01)
	%>% gather(WhichEnd, Depth, DepthTop, DepthBottom) 
	%>% gather(Class, Pct, PctSand, PctSilt, PctClay)
	%>% mutate(Class=factor(sub("^Pct", "", Class), levels=c("Sand", "Silt", "Clay"))))
texture_labels = (texture
	%>% filter(Depth==10)
	%>% mutate(Pct=(cumsum(Pct)-0.5*Pct)/100))

org = (texture
	%>% select(Depth, starts_with("g_Org"))
	%>% gather(Element, gkg, starts_with("g_Org"))
	%>% mutate(Element=sub("g_(Org[CN])_kg", "\\1", Element)))
org_labels = (org
	%>% filter(Depth==10)
	%>% mutate(gkg=0.9*gkg)
	)

# Want all depths on the same scale.
# Note order: must be (max, min) for use with scale_x_reverse
depth_range=c(
	max(coremass$Depth, org$Depth),
	min(coremass$Depth, org$Depth))

rootplot = (ggplot(coremass, 
	aes(x=Depth,
		y=g_m2,
		ymin=g_m2-sd,
		ymax=g_m2+sd,
		group=Year))
	+ geom_point()
	+ geom_errorbar(width=2)
	+ geom_line()
	+ geom_text(data=core_labels, aes(label=Year))
	+ xlab("Depth (cm)")
	+ ylab(expression("Root biomass ("*g~m^{-2}*")"))
	+ coord_flip()
	+ scale_x_reverse(limits=depth_range)
	+thm)

tplot = (ggplot(texture, aes(Depth, Pct, fill=Class))
	+ geom_area(position=position_fill(reverse=TRUE))
	+ scale_fill_manual(
		name=NULL,
		values=c(Sand="lightgrey", Silt="grey", Clay="darkgrey"))
	+ geom_text(
		data=texture_labels,
		aes(label=Class))
	+ xlab("Depth (cm)")
	+ ylab("Particle proportion")
	+ coord_flip()
	+ scale_x_reverse(limits=depth_range)
	+ thm
	+ theme(legend.position="none"))

cnplot = (ggplot(org, aes(Depth, gkg, group=Element))
	+ geom_line()
	+ geom_text(data=org_labels, aes(label=Element))
	+ coord_flip()
	+ xlab("Depth (cm)")
	+ ylab(expression("Organic C or N (g"~kg^{-3}*")"))
	+ scale_x_reverse(limits=depth_range)
	+ thm)

bdplot = (ggplot(texture, aes(Depth, BulkDens))
	+ geom_line()
	+ coord_flip()
	+ xlab("Depth (cm)")
	+ ylab(expression("Bulk density (g"~cm^{-3}*")"))
	+ scale_x_reverse(limits=depth_range)
	+ thm)

plots = plot_grid(
	mirror_ticks(rootplot),
	mirror_ticks(tplot),
	mirror_ticks(cnplot),
	mirror_ticks(bdplot),
	nrow=2,
	labels=c("(a)", "(b)", "(c)", "(d)"),
	align="hv")

ggsave(
	"figs/mass_texture.pdf",
	plots,
	width=9,
	height=12)

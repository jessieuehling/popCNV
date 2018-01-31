library(ggplot2)
library(RColorBrewer)
library(colorRamps)

#Clus

bedwindows = read.table("coverage/mosdepth.10000bp.gg.tab",header=F)
colnames(bedwindows) = c("Chr","Start","End","Depth","Group","Strain")
#bedwindows = subset(bedwindows,bedwindows$Chr != "MT_CBS_6936") # drop MT for this

bedwindows$CHR <- sub("Supercontig_1\\.","",bedwindows$Chr,perl=TRUE)
chrlist = c(1:8)
d=bedwindows[bedwindows$CHR %in% chrlist, ]

d <- d[order(d$CHR, d$Start), ]
d$index = rep.int(seq_along(unique(d$CHR)), times = tapply(d$Start,d$CHR,length)) 

d$pos=NA

nchr = length(unique(d$CHR))
lastbase=0
ticks = NULL
minorB = vector(,8)
for (i in 1:8 ) {
    if (i==1) {
        d[d$index==i, ]$pos=d[d$index==i, ]$Start
    } else {
        ## chromosome position maybe not start at 1, eg. 9999. So gaps may be produced. 
        lastbase = lastbase + max(d[d$index==(i-1),"Start"])
        minorB[i] = lastbase
        d[d$index == i,"Start"] =
             d[d$index == i,"Start"]-min(d[d$index==i,"Start"]) +1
        d[d$index == i, "pos"] = d[d$index == i,"Start"] + lastbase
    }
}
ticks <-tapply(d$pos,d$index,quantile,probs=0.5)
ticks
minorB
d$Group = factor(d$Group, levels = c("LL", "UL", "Sp1"))
xmax = ceiling(max(d$pos) * 1.03)
xmin = floor(max(d$pos) * -0.03)

pdffile="plots/Genomewide_cov_by_10kb_win_mosdepth.pdf"
pdf(pdffile,width=7,height=2.5)
Title="Genome wide depth of coverage (mosdepth)"

#What about the color scheme I have for Ul/LL/Sp in Fig 1 which is Upper=bright blue, lower=red, sputum=black/dark gray


manualColors = c("dodgerblue2","red1","grey20")
p <- ggplot(d,
            aes(x=pos,y=Depth,color=Group)) +
    geom_point(alpha=0.9,size=0.5,shape=16) +
    scale_fill_manual(values = manualColors) +
    #scale_colour_brewer(palette = "Set1") +
    labs(title=Title,xlab="Position",y="Normalized Read Depth") +
    scale_x_continuous(name="Chromosome",
                       breaks = ticks,
                       minor_breaks = minorB,
                       labels=(unique(d$CHR))) +
    scale_y_continuous(name="Normalized Read Depth",
                       limits = c(0,3)) + theme_classic() +
    guides(fill = guide_legend(keywidth = 3, keyheight = 1))

p

# test plot one chrom
dprime=d[d$CHR %in% 6:6, ]
Title=sprintf("Chr%s plot, mosdepth of coverage","6")
p <- ggplot(dprime,
            aes(x=Start,y=Depth,color=Group))  +
    geom_point(alpha=0.5,size=0.75,shape=16) +
    scale_fill_manual(values = manualColors) +
    labs(title=Title,xlab="Position",y="Normalized Read Depth") +
    scale_x_continuous(name="Chromosome bp") +
    scale_y_continuous(name="Normalized Read Depth",
                       limits = c(0,3)) + theme_classic() +
    guides(fill = guide_legend(keywidth = 3, keyheight = 1))
p


for (strain in unique(d$Strain) ) { 
 l = subset(d,d$Strain == strain)
 Title=sprintf("Chr coverage plot for %s",strain)
 p <- ggplot(l,
            aes(x=pos,y=Depth,color=CHR))  + 
    scale_colour_brewer(palette = "Set2") +
    geom_point(alpha=1,size=1,shape=16) +
    labs(title=Title,xlab="Position",y="Normalized Read Depth") +
    scale_x_continuous(name="Chromosome",
                       breaks=ticks,
                       labels=(unique(d$CHR))) +
    scale_y_continuous(name="Normalized Read Depth",
                       limits = c(0,3)) + theme_classic() +
    guides(fill = guide_legend(keywidth = 3, keyheight = 1))
 ggsave(sprintf("plots/StrainPlot_10kb.%s.pdf",strain),p,width=7,height=2.5)
 p
}

for (n in chrlist ) {

    Title=sprintf("Chr%s depth of coverage (mosdepth)",n)
 print(Title)
 l <- subset(d,d$CHR==n)
 p<-ggplot(l,
           aes(x=Start,y=Depth,color=Group)) +
        geom_point(alpha=0.7,size=0.75,shape=16) +
     scale_colour_brewer(palette = "Set1") +
    labs(title=Title,xlab="Position",y="Normalized Read Depth") +
    scale_y_continuous(name="Normalized Read Depth",
                       limits = c(0,3)) + theme_classic() +
    guides(fill = guide_legend(keywidth = 3, keyheight = 1))
 ggsave(sprintf("plots/ChrPlot_10kb.Chr%s.pdf",n),p,width=7,height=2.5)
 p
}



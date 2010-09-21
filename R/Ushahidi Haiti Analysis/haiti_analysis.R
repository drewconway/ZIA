# File-Name:       haiti_analysis.R                 
# Date:            2010-01-31                                
# Author:          Drew Conway                                       
# Purpose:         Analyze Ushahidi data provided by Patrick Meier 
# Data Used:       Ushahidi_Haiti.csv
# Packages Used:   ggplot2,spdep,geoR
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                        
# Load libraries                            
library(geoR)
library(geoRglm)

# Load Ushahidi data
haiti<-read.csv("Ushahidi_Haiti.csv")

# Create a vector for general report type; currently, 
# there are too many sub-categories
new.category<-as.numeric(sapply(haiti$CATEGORY,function(x) gsub("a|b|c|d|e|f|g|h","",x)))
haiti$CATEGORY<-new.category

# Create subset of data for values occurring in and 
# around Port-au-Prince (effectively removes two obs)
haiti.pup<-subset(haiti,haiti$LONGITUDE< -68 & haiti$LONGITUDE> -74)

# Create count vectors for report types and consolidate duplicates
longlats<-cbind(haiti.pup$LONGITUDE,haiti.pup$LATITUDE)
cat.types<-1:6

cat.count<-function(i) {
    longlat<-longlats[i,]
    events.sub<-subset(haiti.pup,haiti.pup$LONGITUDE==longlat[1] & haiti.pup$LATITUDE==longlat[2])
    cat.counts<-sapply(cat.types,function(x) length(which(events.sub$CATEGORY==x)))
    return(append(longlat,cat.counts))
}

# Now we will have columns for ever event type
data.wide<-t(sapply(1:nrow(haiti.pup),cat.count))
haiti.temp<-as.data.frame(data.wide)
colnames(haiti.temp)<-c("long","lat","cat1","cat2","cat3","cat4","cat5","cat6")
# Combine the duplicates
haiti.clean<-aggregate(haiti.temp,by=list(haiti.temp$long,haiti.temp$lat),function(x) x[1])
# Clean up the results by dropping group columns
haiti.clean<-haiti.clean[,-1]
haiti.clean<-haiti.clean[,-1]
# Finally, create new data frame with a total count column
haiti.new<-transform(haiti.clean,total=haiti.clean$cat1+haiti.clean$cat2+haiti.clean$cat3+haiti.clean$cat4+haiti.clean$cat5+haiti.clean$cat6)

# Create geodata object
geo.coords<-cbind(haiti.new$long,haiti.new$lat)
colnames(geo.coords)<-c("long","lat")
rownames(geo.coords)<-1:nrow(geo.coords)
haiti.geo<-list(coords=geo.coords,data=haiti.new$cat4)
geo.cov<-as.data.frame(cbind(haiti.new$cat1,haiti.new$cat2,haiti.new$cat3,haiti.new$cat5,haiti.new$cat6))
colnames(geo.cov)<-c("CAT1","CAT2","CAT3","CAT5","CAT6")
rownames(geo.cov)<-1:nrow(geo.cov)
haiti.geo$covariate<-geo.cov
attr(haiti.geo, "class")<-"geodata"

# Get spatial weights among incident reports
haiti.nb<-tri2nb(cbind(haiti.new$long,haiti.new$lat),row.names=rownames(haiti.new)) # Create neighbor object
haiti.lw<-nb2listw(haiti.nb,style="B")  # Create list of weights

# Perfrom MCMC simulations
model<-list(cov.pars = c(1, 1), beta = 1, family = "poisson")
mcmc.test<-mcmc.control(S.scale = 0.45, thin = 1)
test.tune<-glsm.mcmc(haiti.geo, model = model, mcmc.input=mcmc.test)
haiti.mcmc<-prepare.likfit.glsm(test.tune)
prior<- prior.glm.control(phi.prior = "fixed", phi = .1)

# Create grid over the Port-au-Prince
min.long<-min(geo.coords[,1])
max.long<-max(geo.coords[,1])
min.lat<-min(geo.coords[,2])
max.lat<-max(geo.coords[,2])
grid.loc<-expand.grid(x = seq(min.long, max.long, l = 100),y = seq(min.lat, max.lat, l = 100))

# Generate probabiltiies for Category 1 reports in each grid
# location and plot choropleth
pkb<-pois.krige.bayes(haiti.geo, locations=grid.loc,prior = prior, mcmc.input = mcmc.test)
png("haiti_choropleth.png",width=1200,height=800,res=120)
plot(haiti.geo$coords,cex=0.4,col="black",main="Choropleth of Probability for Category 1\n(Emergncy) Ushahidi Post in Port-au-Prince",
    xlab="Longitude",ylab="Latitude")
image(pkb,col=rev(heat.colors(50,alpha=0.75)),add=TRUE)
dev.off()





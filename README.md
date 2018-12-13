# amatzi.github.io

My personal website is created with [Hugo](https://gohugo.io/) with the fantastic
[Academic](https://sourcethemes.com/academic/) theme. 

The updating/publishing workflow is further enhanced by automatic: 

1. Deployment: with R package [blogdown](https://github.com/rstudio/blogdown) 
with Travis-CI

2. Adding [ORCID](https://orcid.org/) publications to the website by using the R 
package [kwb.orcid](https://github.com/kwb-r/kwb.orcid) and the Python library 
[academic-admin](https://github.com/sourcethemes/academic-admin)


## 1 How to update the website

### Step 1: Create/add new content

Change file(s) in subdirectory ***content***.

In case that blog posts with Rmarkdown are added that require package dependencies:
define these in the **DESCRIPTION** file in the **Imports** and if necessary 
**Remotes** (e.g. if R Package lives on Github like kwb.utils) field.

### Step 2: Check locally

For checking whether the website can be build successfully after adding your 
content do the following

#### Install "blogdown"
```r
if (!require("remotes")) {
  install.packages("remotes", repos = "https://cloud.r-project.org")
}
remotes::install_github("rstudio/blogdown")
```
### Install "hugo" 

with explicitly specifying version number for reproducibility

```r
blogdown::install_hugo(version = "0.52", force = TRUE)
```

### Build/preview site locally

Check whether the website successfully builds locally after the changes

```r
blogdown::serve_site()
```

### Step 2: Commit/push changes to "dev" branch

In case of successfull local build commit and push only the added **content** 
to the **dev** branch. Do not commit the local webiste build stored in the 
**public** folder as well as the output of rendered .Rmd files (as these will 
be automaticall re-build on the Travis-CI)

### Step 3: Automatic build/deployment the website

The deployment is automated with the help of Travis-CI and blogdown very similar to 
the workflow in the [blogdown docu](https://bookdown.org/yihui/blogdown/travis-github.html). 
However instead of specifying all necessary commands only in the `.travis.yml` 
also the files: 

- `_build.sh` and 

- `_deploy.sh` 

are used as both are sucessfully used for automating the update process 
for the [fakin.doc](https://github.com/kwb-r/fakin.doc) website. 

Each push to the repo`s [dev](https://github.com/mrustl/amatzi.github.io/tree/dev) 
branch triggers a Travis [![Travis build](https://travis-ci.org/mrustl/amatzi.github.io.svg?branch=dev)](https://travis-ci.org/mrustl/amatzi.github.io). 

After finalising the Travis [![Travis build](https://travis-ci.org/mrustl/amatzi.github.io.svg?branch=dev)](https://travis-ci.org/mrustl/amatzi.github.io) the website is automatically pushed to the 
repo`s [master](https://github.com/mrustl/amatzi.github.io/tree/master) branch,
which contains all necessary files for serving the website!

### Step 4: Visit the updated website

The content of the updated website is available at [https://amatzi.github.io](https://amatzi.github.io).



## 2 Automatically add ORCID publications to the website

With the following R script it is possible to automatically import all of your 
publications from ORCID:


```r
###############################################################################
### Create .bibtex file with ORCID publications
###############################################################################

# Install dependencies

## Check installed pkgs
installed_pkgs <- rownames(installed.packages())

## Install missing CRAN pkgs
cran_pkgs <- c("remotes", "dplyr", "RefManageR", "reticulate", "data.table")
cran_missing <- !cran_pkgs %in% installed_pkgs

if(any(cran_missing)) {
  install.packages(cran_pkgs[cran_missing] , repos = "https://cloud.r-project.org")
}

## Install latest version of KWB-R GitHub "kwb.orcid" package
remotes::install_github("kwb-r/kwb.orcid")
  
library(magrittr)

secret <- read.csv("secret.csv")
Sys.setenv("ORCID_TOKEN" =  secret$orcid_token)

## Get all of Michael Rustler`s publications from ORCID
orcid <- kwb.orcid::get_kwb_orcids()[4]
publications <- kwb.orcid::create_publications_df_for_orcids(orcids = orcid)

## Put all with DOI in a data.frame 
publications_with_dois <- data.table::rbindlist(publications$`external-ids.external-id`) %>%  
    dplyr::filter(`external-id-type` == "doi")
  

## Create .bibtex from DOIs with RefManageR
## for details see: browseURL("https://github.com/ropensci/RefManageR/")
write_bibtex <- function(dois, file = "publications_orcid.bib", 
                         overwrite = TRUE) {

if(file.exists(file) == FALSE ||  overwrite == TRUE && file.exists(file))  {
  cat(sprintf("Bibtex file '%s'...", file))  
try(RefManageR::GetBibEntryWithDOI(dois,
                               temp.file = file, 
                               delete.file = FALSE))
  cat("Done!")
} else {
   print(sprintf("Bibtex file %s already existing. Specify 'overwrite=TRUE' if 
   you want to overwrite it!", file))
 }
}

## Export all cited publications to  "publications_orcid.bib"
write_bibtex(dois = publications_with_dois$`external-id-value`)

###############################################################################
### Step 2: Import .bibtex file to publications with Python 
###############################################################################

## Download Anaconda with Python 3.7 from website (if not installed)
#browseURL("https://www.anaconda.com/download/")

python_path <- "C:/Users/amatzi.KWB/AppData/Local/Continuum/anaconda3"

Sys.setenv(RETICULATE_PYTHON = python_path)

reticulate::use_python(python_path)

### Define conda environment name with "env"
env <- "academic"

reticulate::conda_create(envname = env)
reticulate::use_condaenv(env)

### Install required Python library "academic" 
### for details see:
# browseURL("https://github.com/sourcethemes/academic-admin")

reticulate::py_install(packages = "academic", 
           envname = env, 
           pip = TRUE, pip_ignore_installed = TRUE) 


## Should existing publications in content/publication folder be overwritten?
overwrite <- TRUE

option_overwrite <- ifelse(overwrite, "--overwrite", "")

### Create and run "import_bibtex.bat" batch file
cmds <- sprintf('call "%s" activate "%s"\ncd "%s"\nacademic import --bibtex "%s"  %s', 
               normalizePath(file.path(python_path, "Scripts/activate.bat")), 
               env,
               normalizePath(getwd()),
               "knitcitations.bib",
               option_overwrite)

writeLines(cmds,con = "import_bibtex.bat")

shell("import_bibtex.bat")

```

Finally check the content of the folder **content/publication**. Your 
ORCID publications should be added there now! 

**Important note:** in case the it was possible to resolve the DOI and create a
valid bibtex entry with the
[knitcitations](https://github.com/cboettig/knitcitations) package these will be
missing in the **content/publication* folder. Check the step where
`knitcitations::citep` is called and watch for errors!

For pushing the changes to your website go through the steps defined in 
[How to update the website](#1-how-to-update-the-website) again!

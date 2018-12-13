###############################################################################
### Create .bibtex file with ORCID publications
###############################################################################

# Install dependencies

## Check installed pkgs
installed_pkgs <- rownames(installed.packages())

## Install missing CRAN pkgs
cran_pkgs <- c("remotes", "dplyr", "readr", "RefManageR", "reticulate", "data.table")
cran_missing <- !cran_pkgs %in% installed_pkgs

if(any(cran_missing)) {
  install.packages(cran_pkgs[cran_missing] , repos = "https://cloud.r-project.org")
}

#remotes::install_github("ropensci/RefManageR")

## Install latest version of KWB-R GitHub "kwb.orcid" package
remotes::install_github("kwb-r/kwb.orcid")
  
library(magrittr)

secret <- read.csv("secret.csv")
Sys.setenv("ORCID_TOKEN" =  secret$orcid_token)

Sys.setlocale(locale = "german") ### for correct "Umlaute"

## Get all of Michael Rustler`s publications from ORCID
orcid <- kwb.orcid::get_kwb_orcids()[1]
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

python_path <- "C:/Users/mrustl.KWB/AppData/Local/Continuum/anaconda3"

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
               "publications_orcid.bib",
               option_overwrite)

writeLines(cmds,con = "import_bibtex.bat")

shell("import_bibtex.bat")

### Now check the folder "content/publication". Your publications should be added
### now!


#' Get formated results from LM dataset
#'
#' @param data LM hypothesise output (do not ungroup it!)
#' @param contrasts.desc Contrast descriptors
#' @param groupings Additional groupings of data over which FDR adjustments will be made
#' @param Sbrks Significance breaks in -log10 scale
#' @param Slbls Significance labels (one less than breaks)
#' @keywords results
#' @export
#' @examples
#' getresults(data,contrasts.desc)
#'
#'

getresults<-function(data,contrasts.desc,groupings=c(),
                     Sbrks=c(0,-log(0.05,10),2,3,4,1000),
                     Slbls=c('N.S.','<0.05','<0.01','<0.001','<0.0001')) {

  grp.vars<-group_vars(data)
  cnt.vars<-colnames(contrasts.desc)

  results<-contrasts.desc %>%
    mutate(Contrast=as.character(Contrast)) %>%
    right_join(data,by='Contrast') %>%
    #group_by_(groupings c('Contrast')) %>%
    #Adjustments within contrast and original grouping
    adjustments(groupings,Sbrks,Slbls) %>%
    #Set contrast levels
    mutate(Contrast=factor(Contrast,levels=contrasts.desc$Contrast,labels=contrasts.desc$Contrast),
           Description=factor(Description,levels=contrasts.desc$Description,labels=contrasts.desc$Description)) %>%
    select(cnt.vars,grp.vars,everything())

  results.m<-results %>%
    gather(Stat,Value,logFC:logFDR)

  results.castfull<-results.m %>%
    arrange(Contrast,desc(Stat)) %>%
    unite(CS,Contrast,Stat) %>%
    select(grp.vars,CS,Value) %>%
    spread(CS,Value) %>%
    mutate_at(vars(-contains('Stars'),-one_of(grp.vars)),as.numeric)

  results.cast<-results.m %>%
    filter(Stat %in% c('logFC','FDR')) %>%
    arrange(Contrast,desc(Stat)) %>%
    unite(CS,Contrast,Stat) %>%
    select(grp.vars,CS,Value) %>%
    spread(CS,Value) %>%
    mutate_at(vars(-contains('Stars'),-one_of(grp.vars)),as.numeric)

  results.multi<-multiplex(results,grp.vars,3)

  return(list('results'=results,
              'cast'=results.cast,
              'castfull'=results.castfull,
              'multi'=results.multi))

}

/****************************************************************************

    PROGRAM:    Dominostat

    FILE:       Dominostat.h

    PURPOSE:
        This include file is used by both the C compiler and the 
        resource compiler. In other words, it is included in both 
        Dominostat.c and Dominostat.rc.  The errortext macro does nothing 
        in Dominostat.c and only is used by Dominostat.rc. 

****************************************************************************/
#if defined(OS400)
#pragma convert(850)
#endif


#include <globerr.h>

#define SERVER_ADDIN_NAME (PKG_ADDIN+0)  /* PKG_ADDIN+0 must be the name of the task */
#define ADDIN_VERSION (PKG_ADDIN+1) /* PKG_ADDIN+1 must be the version number of the task */
#define ADDIN_MSG_FMT (PKG_ADDIN+2) /* user-defined strings are PKG_ADDIN+2 or greater	*/

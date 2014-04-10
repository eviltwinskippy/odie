/*
** This file implements the main routine for a standalone Tcl/Tk shell.
*/
#include <tcl.h>
#include <tk.h>

/*
** We will be linking against all of these extensions.
*/
extern int Toadkit_Packages_Init(Tcl_Interp*);

extern int Zvfs_Init(Tcl_Interp*);
extern int Zvfs_Mount(Tcl_Interp*, char*, char *);

/*
 *----------------------------------------------------------------------
 *
 * Toadkit_AppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in the interp's result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Toadkit_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
  CONST char *cp=Tcl_GetNameOfExecutable();

  /* We have to initialize the virtual filesystem before calling
  ** Tcl_Init().  Otherwise, Tcl_Init() will not be able to find
  ** its startup script files.
  */
  Zvfs_Init(interp);
  if(Zvfs_Mount(interp, cp, "/zvfs")) {
    printf("Mount Error: %s\nReverting to Wish Shell\n",Tcl_GetObjResult(interp));
    Tcl_SetStartupScript(Tcl_NewStringObj("~/odie/bin/default.tcl",-1),NULL);
  } else {
    Tcl_SetVar2(interp, "env", "TCL_LIBRARY", "/zvfs/tcl", TCL_GLOBAL_ONLY);
    Tcl_SetVar2(interp, "env", "TK_LIBRARY", "/zvfs/tk", TCL_GLOBAL_ONLY);
  }  
  if ((Tcl_Init)(interp) == TCL_ERROR) {
      return TCL_ERROR;
  }

  if (Tk_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
  }
  Tcl_StaticPackage(interp, "Tk", Tk_Init, Tk_SafeInit);

#ifdef TK_TEST
  if (Tktest_Init(interp) == TCL_ERROR) {
      return TCL_ERROR;
  }
  Tcl_StaticPackage(interp, "Tktest", Tktest_Init, 0);
#endif /* TK_TEST */

  /* Start up all extensions.
  */
  Toadkit_Packages_Init(interp);
  
  /*
   * Call Tcl_CreateCommand for application-specific commands, if
   * they weren't already created by the init procedures called above.
   */

  /*
   * Specify a user-specific startup file to invoke if the application
   * is run interactively.  Typically the startup file is "~/.apprc"
   * where "app" is the name of the application.  If this line is deleted
   * then no user-specific startup file will be run under any conditions.
   */
  Tcl_SetVar(interp, "tcl_rcFileName", "~/.wishrc", TCL_GLOBAL_ONLY);
  return TCL_OK;
}


/*
** This routine runs first.  
*/
int main(int argc, char **argv){
  Tcl_FindExecutable(argv[0]);
  Tcl_SetStartupScript(Tcl_NewStringObj("/zvfs/main.tcl",-1),NULL);
  Tk_Main(argc,argv,&Toadkit_AppInit);
  return TCL_OK;
}

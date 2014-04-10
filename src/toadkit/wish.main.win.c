/*
** This file implements the main routine for a standalone Tcl/Tk shell.
*/
#include "tk.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#include <locale.h>
#include <stdlib.h>
#include <tchar.h>

#ifdef TK_TEST
extern Tcl_PackageInitProc Tktest_Init;
#endif /* TK_TEST */

extern Tcl_PackageInitProc Registry_Init;
extern Tcl_PackageInitProc Dde_Init;
extern Tcl_PackageInitProc Dde_SafeInit;

#ifdef TCL_BROKEN_MAINARGS
static void setargv(int *argcPtr, TCHAR ***argvPtr);
#endif

static BOOL consoleRequired = TRUE;

#define TK_LOCAL_APPINIT Toadkit_AppInit
#ifndef MODULE_SCOPE
#   define MODULE_SCOPE extern
#endif
MODULE_SCOPE int Toadkit_AppInit(Tcl_Interp *interp);

#ifdef TK_LOCAL_MAIN_HOOK
MODULE_SCOPE int TK_LOCAL_MAIN_HOOK(int *argc, TCHAR ***argv);
#endif

/* Make sure the stubbed variants of those are never used. */
#undef Tcl_ObjSetVar2
#undef Tcl_NewStringObj

/*
** We will be linking against all of these extensions.
*/
extern int Toadkit_Packages_Init(Tcl_Interp*);

//extern int Tlink_Init(Tcl_Interp*);
//extern int Winico_Init(Tcl_Interp*);
extern int Zvfs_Init(Tcl_Interp*);
extern int Zvfs_Mount(Tcl_Interp*, char*, char *);

/*
 *----------------------------------------------------------------------
 *
 * _tWinMain --
 *
 *	Main entry point from Windows.
 *
 * Results:
 *	Returns false if initialization fails, otherwise it never returns.
 *
 * Side effects:
 *	Just about anything, since from here we call arbitrary Tcl code.
 *
 *----------------------------------------------------------------------
 */

int APIENTRY
#ifdef TCL_BROKEN_MAINARGS
WinMain(
    HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    LPSTR lpszCmdLine,
    int nCmdShow)
#else
_tWinMain(
    HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    LPTSTR lpszCmdLine,
    int nCmdShow)
#endif
{
    TCHAR **argv;
    int argc;
    TCHAR *p;

    /*
     * Create the console channels and install them as the standard channels.
     * All I/O will be discarded until Tk_CreateConsoleWindow is called to
     * attach the console to a text widget.
     */

    consoleRequired = TRUE;

    /*
     * Set up the default locale to be standard "C" locale so parsing is
     * performed correctly.
     */

    setlocale(LC_ALL, "C");

    /*
     * Get our args from the c-runtime. Ignore lpszCmdLine.
     */

#if defined(TCL_BROKEN_MAINARGS)
    setargv(&argc, &argv);
#else
    argc = __argc;
    argv = __targv;
#endif

    /*
     * Forward slashes substituted for backslashes.
     */

    for (p = argv[0]; *p != '\0'; p++) {
	if (*p == '\\') {
	    *p = '/';
	}
    }

    Tcl_FindExecutable(argv[0]);
    Tcl_SetStartupScript(Tcl_NewStringObj("/zvfs/main.tcl",-1),NULL);

    Tk_Main(argc, argv, Toadkit_AppInit);
    return 0;			/* Needed only to prevent compiler warning. */
}

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
    printf("Mount Error: %s\nReverting to Wish Shell",Tcl_GetObjResult(interp));
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
  /*
  if (consoleRequired) {
      if (Tk_CreateConsoleWindow(interp) == TCL_ERROR) {
          return TCL_ERROR;
      }
  }
  */
  
    if (Registry_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "registry", Registry_Init, 0);

    if (Dde_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "dde", Dde_Init, Dde_SafeInit);
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


#if defined(TK_TEST)
/*
 *----------------------------------------------------------------------
 *
 * _tmain --
 *
 *	Main entry point from the console.
 *
 * Results:
 *	None: Tk_Main never returns here, so this procedure never returns
 *	either.
 *
 * Side effects:
 *	Whatever the applications does.
 *
 *----------------------------------------------------------------------
 */

#ifdef TCL_BROKEN_MAINARGS
int
main(
    int argc,
    char **dummy)
{
    TCHAR **argv;
#else
int
_tmain(
    int argc,
    TCHAR **argv)
{
#endif
    /*
     * Set up the default locale to be standard "C" locale so parsing is
     * performed correctly.
     */

    setlocale(LC_ALL, "C");

#ifdef TCL_BROKEN_MAINARGS
    /*
     * Get our args from the c-runtime. Ignore argc/argv.
     */

    setargv(&argc, &argv);
#endif
    /*
     * Console emulation widget not required as this entry is from the
     * console subsystem, thus stdin,out,err already have end-points.
     */

    consoleRequired = FALSE;
    Tcl_FindExecutable(argv[0]);
    Tcl_SetStartupScript(Tcl_NewStringObj("/zvfs/main.tcl",-1),NULL);

    Tk_Main(argc, argv, Toad_AppInit);
    return 0;
}
#endif /* !__GNUC__ || TK_TEST */


/*
 *-------------------------------------------------------------------------
 *
 * setargv --
 *
 *	Parse the Windows command line string into argc/argv. Done here
 *	because we don't trust the builtin argument parser in crt0. Windows
 *	applications are responsible for breaking their command line into
 *	arguments.
 *
 *	2N backslashes + quote -> N backslashes + begin quoted string
 *	2N + 1 backslashes + quote -> literal
 *	N backslashes + non-quote -> literal
 *	quote + quote in a quoted string -> single quote
 *	quote + quote not in quoted string -> empty string
 *	quote -> begin quoted string
 *
 * Results:
 *	Fills argcPtr with the number of arguments and argvPtr with the array
 *	of arguments.
 *
 * Side effects:
 *	Memory allocated.
 *
 *--------------------------------------------------------------------------
 */

#ifdef TCL_BROKEN_MAINARGS
static void
setargv(
    int *argcPtr,		/* Filled with number of argument strings. */
    TCHAR ***argvPtr)		/* Filled with argument strings (malloc'd). */
{
    TCHAR *cmdLine, *p, *arg, *argSpace;
    TCHAR **argv;
    int argc, size, inquote, copy, slashes;

    cmdLine = GetCommandLine();

    /*
     * Precompute an overly pessimistic guess at the number of arguments in
     * the command line by counting non-space spans.
     */

    size = 2;
    for (p = cmdLine; *p != '\0'; p++) {
	if ((*p == ' ') || (*p == '\t')) {	/* INTL: ISO space. */
	    size++;
	    while ((*p == ' ') || (*p == '\t')) { /* INTL: ISO space. */
		p++;
	    }
	    if (*p == '\0') {
		break;
	    }
	}
    }

    /* Make sure we don't call ckalloc through the (not yet initialized) stub table */
    #undef Tcl_Alloc
    #undef Tcl_DbCkalloc

    argSpace = ckalloc(size * sizeof(char *)
	    + (_tcslen(cmdLine) * sizeof(TCHAR)) + sizeof(TCHAR));
    argv = (TCHAR **) argSpace;
    argSpace += size * (sizeof(char *)/sizeof(TCHAR));
    size--;

    p = cmdLine;
    for (argc = 0; argc < size; argc++) {
	argv[argc] = arg = argSpace;
	while ((*p == ' ') || (*p == '\t')) {	/* INTL: ISO space. */
	    p++;
	}
	if (*p == '\0') {
	    break;
	}

	inquote = 0;
	slashes = 0;
	while (1) {
	    copy = 1;
	    while (*p == '\\') {
		slashes++;
		p++;
	    }
	    if (*p == '"') {
		if ((slashes & 1) == 0) {
		    copy = 0;
		    if ((inquote) && (p[1] == '"')) {
			p++;
			copy = 1;
		    } else {
			inquote = !inquote;
		    }
		}
		slashes >>= 1;
	    }

	    while (slashes) {
		*arg = '\\';
		arg++;
		slashes--;
	    }

	    if ((*p == '\0') || (!inquote &&
		    ((*p == ' ') || (*p == '\t')))) {	/* INTL: ISO space. */
		break;
	    }
	    if (copy != 0) {
		*arg = *p;
		arg++;
	    }
	    p++;
	}
	*arg = '\0';
	argSpace = arg + 1;
    }
    argv[argc] = NULL;

    *argcPtr = argc;
    *argvPtr = argv;
}
#endif /* TCL_BROKEN_MAINARGS */

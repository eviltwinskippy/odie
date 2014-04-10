/*
 * Copyright (C) 1997-1999 Sensus Consulting Ltd.
 * Matt Newman <matt@sensus.org>
 *
 * Adds command win32::link to Tcl Interp.
 *
 * TODO:
 *		Handle [GS]etIDList correctly.
 */
/*
** @(#) $Id: tlink32.c,v 1.1.1.1 2009/05/09 16:23:36 pcmacdon Exp $
*/
#if !defined(WITHOUT_TLINK) && (defined(__WIN32__) || defined(_WIN32))

#include "tcl.h"
#include <stdlib.h>
#include <shlobj.h>

#define PACKAGE_NAME tlink32
#define PACKAGE_VERSION 1.1

DLLEXPORT int	Tlink_Init _ANSI_ARGS_((Tcl_Interp *));
DLLEXPORT int	Tlink_SafeInit _ANSI_ARGS_((Tcl_Interp *));
/*
 * Internal Routines
 */
static int	LinkCmd _ANSI_ARGS_((ClientData clientData,
		    Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
static Tcl_Obj*	fconvert _ANSI_ARGS_((char *filename));
static Tcl_ExitProc ExitHandler;

/*
 * Convert windows filename into Tcl format
 */
static Tcl_Obj*
fconvert(filename)
    char*	filename;
{
    char buf[_MAX_PATH], *cp = buf;
    for (cp = buf;*filename;cp++,filename++) {
	if (*filename == '\\') {
	    *cp = '/';
	} else {
	    *cp = *filename;
	}
    }
    *cp = '\0';
    return Tcl_NewStringObj( buf, -1);
}

static IShellLink* psl = NULL;

static int
LinkCmd(data, interp, objc, objv)
    ClientData data;
    Tcl_Interp *interp;
    int		objc;
    Tcl_Obj	*CONST objv[];
{
    int		index;
    static char *options[] = {
	"get", "set", NULL
    };
    enum options {
	LNK_GET, LNK_SET
    };	  
    HRESULT hres;
    IPersistFile* ppf = NULL;
    WORD wpath[MAX_PATH+1];

    if (objc < 2) {
	Tcl_WrongNumArgs(interp, 1, objv, "option ?arg arg ...?");
	return TCL_ERROR;
    }    
    if (Tcl_GetIndexFromObj(interp, objv[1], options, "option", 0,
	&index) != TCL_OK) {
	return TCL_ERROR;
    }
    if (psl == NULL) {
	HRESULT hres;

	hres = CoInitialize(NULL);
	if ( hres != S_OK ) {
	    Tcl_SetResult(interp, "failed to initialize ShellLink subsystem", TCL_STATIC);
	    return TCL_ERROR;
	}
	hres = CoCreateInstance(&CLSID_ShellLink,
				NULL, CLSCTX_INPROC_SERVER,
				&IID_IShellLink, &psl);
	if (!SUCCEEDED(hres)) {
	    Tcl_SetResult(interp, "failed to initialize ShellLink subsystem", TCL_STATIC);
	    return TCL_ERROR;
	}
    }
    switch ((enum options) index) {
    case LNK_GET: {
	/*
	 * info path
	 */
	Tcl_Obj *listPtr;
	char	*path;
	char szBuf[MAX_PATH]; 
	WIN32_FIND_DATA wfd;
	WORD	w;
	int	i;

	if (objc != 3) {
	    Tcl_WrongNumArgs(interp, 2, objv, "path");
	    return TCL_ERROR;
	}
	path = Tcl_GetStringFromObj(objv[2], (int *) NULL);

	/* Get Address list for Load Routine   */
	hres = psl->lpVtbl->QueryInterface(psl,&IID_IPersistFile, &ppf);
	if (!SUCCEEDED(hres)) {
	    Tcl_SetResult(interp, "failed to obtain IPersistFile routine", TCL_STATIC);
	    return TCL_ERROR;
	}
	MultiByteToWideChar(CP_ACP, 0, path, -1, wpath, MAX_PATH);

	listPtr = Tcl_NewListObj(0, (Tcl_Obj **) NULL);

	hres = ppf->lpVtbl->Load(ppf, wpath, STGM_READ);
	if (!SUCCEEDED(hres)) {
err:
	    Tcl_DecrRefCount(listPtr);
	    ppf->lpVtbl->Release(ppf);
	    Tcl_AppendResult(interp, "couldn't load shortcut \"",
			    path, "\"", (char *)NULL);
	    return TCL_ERROR;
	}

        hres = psl->lpVtbl->GetPath( psl, szBuf, MAX_PATH,
				    (WIN32_FIND_DATA *)&wfd, 0 ); 
        if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-path", -1));
	Tcl_ListObjAppendElement(interp, listPtr, fconvert(szBuf));

	hres = psl->lpVtbl->GetArguments( psl, szBuf, MAX_PATH);
        if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-args", -1));
	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( szBuf, -1));

	hres = psl->lpVtbl->GetWorkingDirectory( psl, szBuf, MAX_PATH);
        if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-cwd", -1));
	Tcl_ListObjAppendElement(interp, listPtr, fconvert(szBuf));

        hres = psl->lpVtbl->GetDescription( psl, szBuf, MAX_PATH); 
	if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-desc", -1));
	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( szBuf, -1));

        hres = psl->lpVtbl->GetIconLocation( psl, szBuf, MAX_PATH, &i); 
	if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-icon", -1));
	Tcl_ListObjAppendElement(interp, listPtr, fconvert(szBuf));

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-index", -1));
	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewIntObj( i));

        hres = psl->lpVtbl->GetShowCmd( psl, &i); 
	if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-show", -1));
	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewIntObj( i));

        hres = psl->lpVtbl->GetHotkey( psl, &w); 
	if (!SUCCEEDED(hres))
	    goto err;

	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewStringObj( "-hotkey", -1));
	Tcl_ListObjAppendElement(interp, listPtr, Tcl_NewIntObj( w));

	ppf->lpVtbl->Release(ppf);
	Tcl_SetObjResult(interp, listPtr);
	return TCL_OK;
    }	/* LNK_GET */
    case LNK_SET: {
	/*
	 * set path ?options?
	 */
	Tcl_DString	ds;
	char	*path, *opt, *val;
	char	szBuf[MAX_PATH]; 
	int	i, w;

	if (objc < 3 || (objc % 2) != 1) {
	    Tcl_WrongNumArgs(interp, 2, objv, "path ?options?");
	    return TCL_ERROR;
	}
	Tcl_DStringInit(&ds);
	path = Tcl_TranslateFileName(interp,
				Tcl_GetStringFromObj(objv[2], (int *) NULL),
				&ds);
	if (path == NULL)
	    return TCL_ERROR;

	/* Get Address list for Load Routine   */
	hres = psl->lpVtbl->QueryInterface(psl,&IID_IPersistFile, &ppf);
	if (!SUCCEEDED(hres)) {
	    Tcl_DStringFree(&ds);
	    Tcl_SetResult(interp, "failed to obtain IPersistFile routine", TCL_STATIC);
	    return TCL_ERROR;
	}
	MultiByteToWideChar(CP_ACP, 0, path, -1, wpath, MAX_PATH);
	Tcl_DStringFree(&ds);

	hres = ppf->lpVtbl->Load(ppf, wpath, STGM_CREATE|STGM_READWRITE);
	if (!SUCCEEDED(hres)) {
	    LPITEMIDLIST pidl = 0;
		
	    val = "";
	    i = 0;
	    psl->lpVtbl->SetPath(psl,(LPSTR)val);
	    psl->lpVtbl->SetArguments(psl,(LPSTR)val);
	    psl->lpVtbl->SetWorkingDirectory(psl,(LPSTR)val);
	    psl->lpVtbl->SetDescription(psl,(LPSTR)val);
	    psl->lpVtbl->SetIconLocation(psl, val, i);
	    psl->lpVtbl->SetHotkey(psl, (WORD)i);
	    psl->lpVtbl->SetShowCmd(psl, i);
	    psl->lpVtbl->SetIDList(psl, pidl);
	    /*LPITEMIDLIST*/
	}
	for (i=3;i<objc;i+=2) {
	    opt = Tcl_GetStringFromObj(objv[i], (int *) NULL);
	    val = Tcl_GetStringFromObj(objv[i+1], (int *) NULL);
	    if (strcmp(opt, "-path")==0) {
		psl->lpVtbl->SetPath(psl,(LPSTR)val);
	    } else if (strcmp(opt, "-args")==0) {
		psl->lpVtbl->SetArguments(psl,(LPSTR)val);
	    } else if (strcmp(opt, "-cwd")==0) {
		psl->lpVtbl->SetWorkingDirectory(psl,(LPSTR)val);
	    } else if (strcmp(opt, "-desc")==0) {
		psl->lpVtbl->SetDescription(psl,(LPSTR)val);
	    } else if (strcmp(opt, "-icon")==0) {
		Tcl_DString	ds;
		int	idx;

		hres = psl->lpVtbl->GetIconLocation( psl, szBuf, MAX_PATH, &idx); 
		if (!SUCCEEDED(hres)) {
		    Tcl_AppendResult(interp, "failed to get existing icon location",
				    (char *)NULL);
		    goto setErr;
		}
		Tcl_DStringInit(&ds);
		val = Tcl_TranslateFileName( interp, val, &ds);
		if (val == NULL)
		    goto setErr;
		psl->lpVtbl->SetIconLocation(psl, val, idx);
	    } else if (strcmp(opt, "-index")==0) {
		int	idx, oidx;

		if (Tcl_GetInt(interp, val, &idx)!=TCL_OK)
		    goto setErr;

		hres = psl->lpVtbl->GetIconLocation( psl, szBuf, MAX_PATH, &oidx); 
		if (!SUCCEEDED(hres)) {
		    Tcl_AppendResult(interp, "failed to get existing icon location",
				    (char *)NULL);
		    goto setErr;
		}
		psl->lpVtbl->SetIconLocation(psl, szBuf, idx);
	    } else if (strcmp(opt, "-hotkey")==0) {
		if (Tcl_GetIntFromObj(interp, objv[i+1], &w)!=TCL_OK)
		    goto setErr;
		psl->lpVtbl->SetHotkey(psl, (WORD)w);
	    } else if (strcmp(opt, "-show")==0) {
		if (Tcl_GetIntFromObj(interp, objv[i+1], &w)!=TCL_OK)
		    goto setErr;
		psl->lpVtbl->SetShowCmd(psl, w);
	    } else {
		Tcl_AppendResult(interp, "bad option \"", opt,
			"\": must be one of -args, -cwd, -desc, -hotkey, -icon, -path or -show",
				(char *)NULL);
		goto setErr;
	    }
	}
	hres = ppf->lpVtbl->Save(ppf, wpath, TRUE);
	if (!SUCCEEDED(hres)) {
	    Tcl_AppendResult(interp, "couldn't save shortcut \"",
			path, "\"", (char *)NULL);
setErr:
	    ppf->lpVtbl->Release(ppf);
	    return TCL_ERROR;
	}
	ppf->lpVtbl->Release(ppf);
	return TCL_OK;
    }	/* LNK_SET */
    }	/*switch*/
}


static
VOID ExitHandler(ClientData data)
{
    if (psl != NULL)
	psl->lpVtbl->Release(psl); 
}

int
Tlink_SafeInit(Tcl_Interp *interp) {
    return TCL_ERROR;
}

int
Tlink_Init(Tcl_Interp *interp)
{
    Tcl_CreateObjCommand(interp, "win32::link", LinkCmd,
			  (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);
    Tcl_Eval(interp, "namespace eval win32 {namespace export link}");

    Tcl_CreateExitHandler(ExitHandler, NULL);

    return Tcl_PkgProvide( interp, "tlink32", "1.1");
}

#endif /* !def(WITHOUT_TLINK) && (def(__WIN32) || def(_WIN32)) */

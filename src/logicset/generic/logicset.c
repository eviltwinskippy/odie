
/*
** This file is machine generated. Changes will
** be overwritten on the next run of cstruct.tcl
*/
#include <tcl.h>
#include <strings.h>
#include <ctype.h>
#define UCHAR(c) ((unsigned char) (c))
#define TclFormatInt(buf, n)		sprintf((buf), "%ld", (long)(n))

/*
 * Macros used to cast between pointers and integers (e.g. when storing an int
 * in ClientData), on 64-bit architectures they avoid gcc warning about "cast
 * to/from pointer from/to integer of different size".
 */

#if !defined(INT2PTR) && !defined(PTR2INT)
#   if defined(HAVE_INTPTR_T) || defined(intptr_t)
#	define INT2PTR(p) ((void *)(intptr_t)(p))
#	define PTR2INT(p) ((int)(intptr_t)(p))
#   else
#	define INT2PTR(p) ((void *)(p))
#	define PTR2INT(p) ((int)(p))
#   endif
#endif
#if !defined(UINT2PTR) && !defined(PTR2UINT)
#   if defined(HAVE_UINTPTR_T) || defined(uintptr_t)
#	define UINT2PTR(p) ((void *)(uintptr_t)(p))
#	define PTR2UINT(p) ((unsigned int)(uintptr_t)(p))
#   else
#	define UINT2PTR(p) ((void *)(p))
#	define PTR2UINT(p) ((unsigned int)(p))
#   endif
#endif

#define VERSION "1.0"

/*
** Internal call required for munging integers
*/

typedef struct SortInfo SortInfo;

struct SortInfo {  int isIncreasing;		/* Nonzero means sort in increasing order. */  int sortMode;		/* The sort mode. One of SORTMODE_* values  * defined below. */  Tcl_Obj *compareCmdPtr;	/* The Tcl comparison command when sortMode is  * SORTMODE_COMMAND. Pre-initialized to hold  * base of command. */  int *indexv;		/* If the -index option was specified, this  * holds the indexes contained in the list  * supplied as an argument to that option.  * NULL if no indexes supplied, and points to  * singleIndex field when only one  * supplied. */  int indexc;			/* Number of indexes in indexv array. */  int singleIndex;		/* Static space for common index case. */  int unique;  int numElements;  Tcl_Interp *interp;		/* The interpreter in which the sort is being  * done. */  int resultCode;		/* Completion code for the lsort command. If  * an error occurs during the sort this is  * changed from TCL_OK to TCL_ERROR. */  
};

/*
 * The structure used as the internal representation of Tcl list objects. This
 * struct is grown (reallocated and copied) as necessary to hold all the
 * list's element pointers. The struct might contain more slots than currently
 * used to hold all element pointers. This is done to make append operations
 * faster.
 */

typedef struct List {
    int refCount;
    int maxElemCount;		/* Total number of element array slots. */
    int elemCount;		/* Current number of list elements. */
    int canonicalFlag;		/* Set if the string representation was
				 * derived from the list representation. May
				 * be ignored if there is no string rep at
				 * all.*/
    Tcl_Obj *elements;		/* First list element; the struct is grown to
				 * accomodate all elements. */
} List;

/*
 * During execution of the "lsort" command, structures of the following type
 * are used to arrange the objects being sorted into a collection of linked
 * lists.
 */

typedef struct SortElement {
    union {
	char *strValuePtr;
	long intValue;
	double doubleValue;
	Tcl_Obj *objValuePtr;
    } index;
    Tcl_Obj *objPtr;	        /* Object being sorted, or its index. */
    struct SortElement *nextPtr;/* Next element in the list, or NULL for end
				 * of list. */
} SortElement;

/*
 * These function pointer types are used with the "lsearch" and "lsort"
 * commands to facilitate the "-nocase" option.
 */

typedef int (*SortStrCmpFn_t) (const char *, const char *);
typedef int (*SortMemCmpFn_t) (const void *, const void *, size_t);

/*
 * The "lsort" command needs to pass certain information down to the function
 * that compares two list elements, and the comparison function needs to pass
 * success or failure information back up to the top-level "lsort" command.
 * The following structure is used to pass this information.
 */


/*
 * The "sortMode" field of the SortInfo structure can take on any of the
 * following values.
 */

#define SORTMODE_ASCII		0
#define SORTMODE_INTEGER	1
#define SORTMODE_REAL		2
#define SORTMODE_COMMAND	3
#define SORTMODE_DICTIONARY	4
#define SORTMODE_ASCII_NC	8

/*
 * Magic values for the index field of the SortInfo structure. Note that the
 * index "end-1" will be translated to SORTIDX_END-1, etc.
 */

#define SORTIDX_NONE	-1	/* Not indexed; use whole value. */
#define SORTIDX_END	-2	/* Indexed from end. */

/*
 * Forward declarations for procedures defined in this file:
 */

static int		DictionaryCompare(char *left, char *right);
static SortElement *    MergeLists(SortElement *leftPtr, SortElement *rightPtr,
			    SortInfo *infoPtr);
static int		SortCompare(SortElement *firstPtr, SortElement *second,
			    SortInfo *infoPtr);
static Tcl_Obj *	SelectObjFromSublist(Tcl_Obj *firstPtr,
			    SortInfo *infoPtr);


/*
 *----------------------------------------------------------------------
 *
 * MergeLists -
 *
 *	This procedure combines two sorted lists of SortElement structures
 *	into a single sorted list.
 *
 * Results:
 *	The unified list of SortElement structures.
 *
 * Side effects:
 *	If infoPtr->unique is set then infoPtr->numElements may be updated.
 *	Possibly others, if a user-defined comparison command does something
 *	weird.
 *
 * Note:
 *	If infoPtr->unique is set, the merge assumes that there are no
 *	"repeated" elements in each of the left and right lists. In that case,
 *	if any element of the left list is equivalent to one in the right list
 *	it is omitted from the merged list.
 *	This simplified mechanism works because of the special way
 *	our MergeSort creates the sublists to be merged and will fail to
 *	eliminate all repeats in the general case where they are already
 *	present in either the left or right list. A general code would need to
 *	skip adjacent initial repeats in the left and right lists before
 *	comparing their initial elements, at each step.
 *----------------------------------------------------------------------
 */

static SortElement *
MergeLists(
    SortElement *leftPtr,	/* First list to be merged; may be NULL. */
    SortElement *rightPtr,	/* Second list to be merged; may be NULL. */
    SortInfo *infoPtr)		/* Information needed by the comparison
				 * operator. */
{
    SortElement *headPtr, *tailPtr;
    int cmp;

    if (leftPtr == NULL) {
	return rightPtr;
    }
    if (rightPtr == NULL) {
	return leftPtr;
    }
    cmp = SortCompare(leftPtr, rightPtr, infoPtr);
    if (cmp > 0 || (cmp == 0 && infoPtr->unique)) {
	if (cmp == 0) {
	    infoPtr->numElements--;
	    leftPtr = leftPtr->nextPtr;
	}
	tailPtr = rightPtr;
	rightPtr = rightPtr->nextPtr;
    } else {
	tailPtr = leftPtr;
	leftPtr = leftPtr->nextPtr;
    }
    headPtr = tailPtr;
    if (!infoPtr->unique) {
	while ((leftPtr != NULL) && (rightPtr != NULL)) {
	    cmp = SortCompare(leftPtr, rightPtr, infoPtr);
	    if (cmp > 0) {
		tailPtr->nextPtr = rightPtr;
		tailPtr = rightPtr;
		rightPtr = rightPtr->nextPtr;
	    } else {
		tailPtr->nextPtr = leftPtr;
		tailPtr = leftPtr;
		leftPtr = leftPtr->nextPtr;
	    }
	}
    } else {
	while ((leftPtr != NULL) && (rightPtr != NULL)) {
	    cmp = SortCompare(leftPtr, rightPtr, infoPtr);
	    if (cmp >= 0) {
		if (cmp == 0) {
		    infoPtr->numElements--;
		    leftPtr = leftPtr->nextPtr;
		}
		tailPtr->nextPtr = rightPtr;
		tailPtr = rightPtr;
		rightPtr = rightPtr->nextPtr;
	    } else {
		tailPtr->nextPtr = leftPtr;
		tailPtr = leftPtr;
		leftPtr = leftPtr->nextPtr;
	    }
	}
    }
    if (leftPtr != NULL) {
	tailPtr->nextPtr = leftPtr;
    } else {
	tailPtr->nextPtr = rightPtr;
    }
    return headPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * SortCompare --
 *
 *	This procedure is invoked by MergeLists to determine the proper
 *	ordering between two elements.
 *
 * Results:
 *	A negative results means the the first element comes before the
 *	second, and a positive results means that the second element should
 *	come first. A result of zero means the two elements are equal and it
 *	doesn't matter which comes first.
 *
 * Side effects:
 *	None, unless a user-defined comparison command does something weird.
 *
 *----------------------------------------------------------------------
 */

static int
SortCompare(
    SortElement *elemPtr1, SortElement *elemPtr2,
				/* Values to be compared. */
    SortInfo *infoPtr)		/* Information passed from the top-level
				 * "lsort" command. */
{
    int order = 0;

    if (infoPtr->sortMode == SORTMODE_ASCII) {
	order = strcmp(elemPtr1->index.strValuePtr,
		elemPtr2->index.strValuePtr);
    } else if (infoPtr->sortMode == SORTMODE_ASCII_NC) {
	order = strcasecmp(elemPtr1->index.strValuePtr,
		elemPtr2->index.strValuePtr);
    } else if (infoPtr->sortMode == SORTMODE_DICTIONARY) {
	order = DictionaryCompare(elemPtr1->index.strValuePtr,
		elemPtr2->index.strValuePtr);
    } else if (infoPtr->sortMode == SORTMODE_INTEGER) {
	long a, b;

	a = elemPtr1->index.intValue;
	b = elemPtr2->index.intValue;
	order = ((a >= b) - (a <= b));
    } else if (infoPtr->sortMode == SORTMODE_REAL) {
	double a, b;

	a = elemPtr1->index.doubleValue;
	b = elemPtr2->index.doubleValue;
	order = ((a >= b) - (a <= b));
    } else {
	Tcl_Obj **objv, *paramObjv[2];
	int objc;
	Tcl_Obj *objPtr1, *objPtr2;

	if (infoPtr->resultCode != TCL_OK) {
	    /*
	     * Once an error has occurred, skip any future comparisons so as
	     * to preserve the error message in sortInterp->result.
	     */

	    return 0;
	}


	objPtr1 = elemPtr1->index.objValuePtr;
	objPtr2 = elemPtr2->index.objValuePtr;

	paramObjv[0] = objPtr1;
	paramObjv[1] = objPtr2;

	/*
	 * We made space in the command list for the two things to compare.
	 * Replace them and evaluate the result.
	 */

	Tcl_ListObjLength(infoPtr->interp, infoPtr->compareCmdPtr, &objc);
	Tcl_ListObjReplace(infoPtr->interp, infoPtr->compareCmdPtr, objc - 2,
		2, 2, paramObjv);
	Tcl_ListObjGetElements(infoPtr->interp, infoPtr->compareCmdPtr,
		&objc, &objv);

	infoPtr->resultCode = Tcl_EvalObjv(infoPtr->interp, objc, objv, 0);

	if (infoPtr->resultCode != TCL_OK) {
	    Tcl_AddErrorInfo(infoPtr->interp,
		    "\n    (-compare command)");
	    return 0;
	}

	/*
	 * Parse the result of the command.
	 */

	if (Tcl_GetIntFromObj(infoPtr->interp,
		Tcl_GetObjResult(infoPtr->interp), &order) != TCL_OK) {
	    Tcl_ResetResult(infoPtr->interp);
	    Tcl_AppendResult(infoPtr->interp,
		    "-compare command returned non-integer result", NULL);
	    infoPtr->resultCode = TCL_ERROR;
	    return 0;
	}
    }
    if (!infoPtr->isIncreasing) {
	order = -order;
    }
    return order;
}

/*
 *----------------------------------------------------------------------
 *
 * DictionaryCompare
 *
 *	This function compares two strings as if they were being used in an
 *	index or card catalog. The case of alphabetic characters is ignored,
 *	except to break ties. Thus "B" comes before "b" but after "a". Also,
 *	integers embedded in the strings compare in numerical order. In other
 *	words, "x10y" comes after "x9y", not * before it as it would when
 *	using strcmp().
 *
 * Results:
 *	A negative result means that the first element comes before the
 *	second, and a positive result means that the second element should
 *	come first. A result of zero means the two elements are equal and it
 *	doesn't matter which comes first.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
DictionaryCompare(
    char *left, char *right)	/* The strings to compare. */
{
    Tcl_UniChar uniLeft, uniRight, uniLeftLower, uniRightLower;
    int diff, zeros;
    int secondaryDiff = 0;

    while (1) {
	if (isdigit(UCHAR(*right))		/* INTL: digit */
		&& isdigit(UCHAR(*left))) {	/* INTL: digit */
	    /*
	     * There are decimal numbers embedded in the two strings. Compare
	     * them as numbers, rather than strings. If one number has more
	     * leading zeros than the other, the number with more leading
	     * zeros sorts later, but only as a secondary choice.
	     */

	    zeros = 0;
	    while ((*right == '0') && (isdigit(UCHAR(right[1])))) {
		right++;
		zeros--;
	    }
	    while ((*left == '0') && (isdigit(UCHAR(left[1])))) {
		left++;
		zeros++;
	    }
	    if (secondaryDiff == 0) {
		secondaryDiff = zeros;
	    }

	    /*
	     * The code below compares the numbers in the two strings without
	     * ever converting them to integers. It does this by first
	     * comparing the lengths of the numbers and then comparing the
	     * digit values.
	     */

	    diff = 0;
	    while (1) {
		if (diff == 0) {
		    diff = UCHAR(*left) - UCHAR(*right);
		}
		right++;
		left++;
		if (!isdigit(UCHAR(*right))) {		/* INTL: digit */
		    if (isdigit(UCHAR(*left))) {	/* INTL: digit */
			return 1;
		    } else {
			/*
			 * The two numbers have the same length. See if their
			 * values are different.
			 */

			if (diff != 0) {
			    return diff;
			}
			break;
		    }
		} else if (!isdigit(UCHAR(*left))) {	/* INTL: digit */
		    return -1;
		}
	    }
	    continue;
	}

	/*
	 * Convert character to Unicode for comparison purposes. If either
	 * string is at the terminating null, do a byte-wise comparison and
	 * bail out immediately.
	 */

	if ((*left != '\0') && (*right != '\0')) {
	    left += Tcl_UtfToUniChar(left, &uniLeft);
	    right += Tcl_UtfToUniChar(right, &uniRight);

	    /*
	     * Convert both chars to lower for the comparison, because
	     * dictionary sorts are case insensitve. Covert to lower, not
	     * upper, so chars between Z and a will sort before A (where most
	     * other interesting punctuations occur).
	     */

	    uniLeftLower = Tcl_UniCharToLower(uniLeft);
	    uniRightLower = Tcl_UniCharToLower(uniRight);
	} else {
	    diff = UCHAR(*left) - UCHAR(*right);
	    break;
	}

	diff = uniLeftLower - uniRightLower;
	if (diff) {
	    return diff;
	}
	if (secondaryDiff == 0) {
	    if (Tcl_UniCharIsUpper(uniLeft) && Tcl_UniCharIsLower(uniRight)) {
		secondaryDiff = -1;
	    } else if (Tcl_UniCharIsUpper(uniRight)
		    && Tcl_UniCharIsLower(uniLeft)) {
		secondaryDiff = 1;
	    }
	}
    }
    if (diff == 0) {
	diff = secondaryDiff;
    }
    return diff;
}


int Irm_SortElement_FromObj(
  Tcl_Interp *interp,
  int sortMode,
  Tcl_Obj *valuePtr,
  SortElement *elementPtr
) {
  /*
   * Determine the "value" of this object for sorting purposes
   */
  if (sortMode == SORTMODE_ASCII) {
      elementPtr->index.strValuePtr = Tcl_GetString(valuePtr);
  } else if (sortMode == SORTMODE_INTEGER) {
      long a;

      if (Tcl_GetLongFromObj(interp, valuePtr, &a) != TCL_OK) {
        return TCL_ERROR;
      }
      elementPtr->index.intValue = a;
  } else if (sortMode == SORTMODE_REAL) {
      double a;

      if (Tcl_GetDoubleFromObj(interp, valuePtr, &a) != TCL_OK) {
        return TCL_ERROR;
      }
      elementPtr->index.doubleValue = a;
  } else {
      elementPtr->index.objValuePtr = valuePtr;
  }
  elementPtr->objPtr = valuePtr;
  return TCL_OK;
}

/*
** Converts a linked list of structures into
** a Tcl list object
*/

Tcl_Obj *Irm_MergeList_ToObj(SortElement *elementPtr) {     
  SortElement *loopPtr;
  Tcl_Obj **newArray;
  int i,len=0;
  loopPtr=elementPtr;
  for (len=0; loopPtr != NULL ; loopPtr = loopPtr->nextPtr) {
    len++;
  }
  newArray = (Tcl_Obj **)Tcl_Alloc(sizeof(Tcl_Obj *)*len);
  loopPtr=elementPtr;
  for (i=0; loopPtr != NULL ; loopPtr = loopPtr->nextPtr) {
      Tcl_Obj *objPtr = loopPtr->objPtr;
      newArray[i] = objPtr;
      i++;
      Tcl_IncrRefCount(objPtr);
  }
  return Tcl_NewListObj(len,newArray);
}


int Irm_Lsearch(int listLength,Tcl_Obj **listObjPtrs,char *match,int matchLen) {
  int i,s2len,found;
  const char *s2;

  Tcl_Obj *o;
  if(matchLen < 0) {
    matchLen=strlen(match);
  }

  found = 0;
  for(i=0;i<listLength && !found;i++) {
    o=listObjPtrs[i];
    if (o != NULL) {
        s2 = Tcl_GetStringFromObj(o, &s2len);
    } else {
        s2 = "";
    }
    if (matchLen == s2len) {
      found = (strcmp(match, s2) == 0);
      if(found) {
        return i;
      }
    }
  }
  return -1;
}


Tcl_Obj *Irm_ListObj_Sort(Tcl_Obj *listObj) {
  Tcl_Obj *resultPtr=NULL;
  int i, j, length, sortMode;
  int idx;
  Tcl_Obj **listObjPtrs, *indexPtr;
  SortElement *elementArray, *elementPtr;
  SortInfo sortInfo;

  sortInfo.isIncreasing = 1;
  sortInfo.sortMode = SORTMODE_DICTIONARY;
  sortInfo.indexv = NULL;
  sortInfo.unique = 1;
  sortInfo.interp = NULL;
  sortInfo.resultCode = TCL_OK;

  /*
   * The subList array below holds pointers to temporary lists built during
   * the merge sort. Element i of the array holds a list of length 2**i.
   */
  #   define NUM_LISTS 30
  SortElement *subList[NUM_LISTS+1];


  sortInfo.resultCode = Tcl_ListObjGetElements(sortInfo.interp, listObj,
          &length, &listObjPtrs);

  if(length==0) {
    /*
    ** If the list is zero length, just return
    ** the original pointer
    */
    return listObj;
  }

  if (sortInfo.resultCode != TCL_OK || length <= 0) {
    goto done;
  }

  sortInfo.numElements = length;

  sortMode = sortInfo.sortMode;
  if ((sortMode == SORTMODE_ASCII_NC)
          || (sortMode == SORTMODE_DICTIONARY)) {
      /*
       * For this function's purpose all string-based modes are equivalent
       */
      sortMode = SORTMODE_ASCII;
  }

  /*
   * Initialize the sublists. After the following loop, subList[i] will
   * contain a sorted sublist of length 2**i. Use one extra subList at the
   * end, always at NULL, to indicate the end of the lists.
   */

  for (j=0 ; j<=NUM_LISTS ; j++) {
      subList[j] = NULL;
  }

  /*
   * The following loop creates a SortElement for each list element and
   * begins sorting it into the sublists as it appears.
   */

  elementArray = (SortElement *) Tcl_Alloc( length * sizeof(SortElement));

  for (i=0; i < length; i++){
    idx = i;
    indexPtr = listObjPtrs[idx];
    sortInfo.resultCode=Irm_SortElement_FromObj(sortInfo.interp,sortMode,indexPtr,&elementArray[i]);
    if(sortInfo.resultCode!=TCL_OK) {
      goto done1;
    }
  }
  
  for (i=0; i < length; i++){
      /*
       * Merge this element in the pre-existing sublists (and merge together
       * sublists when we have two of the same size).
       */

      elementArray[i].nextPtr = NULL;
      elementPtr = &elementArray[i];
      for (j=0 ; subList[j] ; j++) {
          elementPtr = MergeLists(subList[j], elementPtr, &sortInfo);
          subList[j] = NULL;
      }
      if (j >= NUM_LISTS) {
          j = NUM_LISTS-1;
      }
      subList[j] = elementPtr;
  }

  /*
   * Merge all sublists
   */

  elementPtr = subList[0];
  for (j=1 ; j<NUM_LISTS ; j++) {
      elementPtr = MergeLists(subList[j], elementPtr, &sortInfo);
  }
  
  /*
   * Now store the sorted elements in the result list.
   */

  if (sortInfo.resultCode == TCL_OK) {
    resultPtr=Irm_MergeList_ToObj(elementPtr);

  }

  done1:
    Tcl_Free((char *) elementArray);

  done:
    if (sortInfo.sortMode == SORTMODE_COMMAND) {
	Tcl_DecrRefCount(sortInfo.compareCmdPtr);
	Tcl_DecrRefCount(listObj);
	sortInfo.compareCmdPtr = NULL;
    }
    if (sortInfo.resultCode != TCL_OK) {
      return NULL;
    }
    return resultPtr;
}


int Irm_ListObjFancy_Sort(Tcl_Obj *listObj,SortInfo *sortInfo,Tcl_Obj **resultPtr) {
  int i, j, length, sortMode;
  int idx;
  Tcl_Obj **listObjPtrs, *indexPtr;
  SortElement *elementArray, *elementPtr;
  SortInfo sortDefault;

  sortDefault.isIncreasing = 1;
  sortDefault.sortMode = SORTMODE_DICTIONARY;
  sortDefault.indexv = NULL;
  sortDefault.unique = 1;
  sortDefault.interp = NULL;
  sortDefault.resultCode = TCL_OK;
  if(!sortInfo) {
    sortInfo=&sortDefault;
  }
  /*
   * The subList array below holds pointers to temporary lists built during
   * the merge sort. Element i of the array holds a list of length 2**i.
   */
  #   define NUM_LISTS 30
  SortElement *subList[NUM_LISTS+1];


  sortInfo->resultCode = Tcl_ListObjGetElements(sortInfo->interp, listObj,
          &length, &listObjPtrs);
  if (sortInfo->resultCode != TCL_OK || length <= 0) {
      goto done;
  }

  sortInfo->numElements = length;

  sortMode = sortInfo->sortMode;
  if ((sortMode == SORTMODE_ASCII_NC)
          || (sortMode == SORTMODE_DICTIONARY)) {
      /*
       * For this function's purpose all string-based modes are equivalent
       */
      sortMode = SORTMODE_ASCII;
  }

  /*
   * Initialize the sublists. After the following loop, subList[i] will
   * contain a sorted sublist of length 2**i. Use one extra subList at the
   * end, always at NULL, to indicate the end of the lists.
   */

  for (j=0 ; j<=NUM_LISTS ; j++) {
      subList[j] = NULL;
  }

  /*
   * The following loop creates a SortElement for each list element and
   * begins sorting it into the sublists as it appears.
   */

  elementArray = (SortElement *) Tcl_Alloc( length * sizeof(SortElement));

  for (i=0; i < length; i++){
    idx = i;
    indexPtr = listObjPtrs[idx];
    sortInfo->resultCode=Irm_SortElement_FromObj(sortInfo->interp,sortMode,indexPtr,&elementArray[i]);
    if(sortInfo->resultCode!=TCL_OK) {
      goto done1;
    }
  }
  
  for (i=0; i < length; i++){
      /*
       * Merge this element in the pre-existing sublists (and merge together
       * sublists when we have two of the same size).
       */

      elementArray[i].nextPtr = NULL;
      elementPtr = &elementArray[i];
      for (j=0 ; subList[j] ; j++) {
          elementPtr = MergeLists(subList[j], elementPtr, sortInfo);
          subList[j] = NULL;
      }
      if (j >= NUM_LISTS) {
          j = NUM_LISTS-1;
      }
      subList[j] = elementPtr;
  }

  /*
   * Merge all sublists
   */

  elementPtr = subList[0];
  for (j=1 ; j<NUM_LISTS ; j++) {
      elementPtr = MergeLists(subList[j], elementPtr, sortInfo);
  }
  
  /*
   * Now store the sorted elements in the result list.
   */

  if (sortInfo->resultCode == TCL_OK) {
    *resultPtr=Irm_MergeList_ToObj(elementPtr);

  } else {
    *resultPtr=NULL;
  }

  done1:
    Tcl_Free((char *) elementArray);

  done:
    if (sortInfo->sortMode == SORTMODE_COMMAND) {
	Tcl_DecrRefCount(sortInfo->compareCmdPtr);
	Tcl_DecrRefCount(listObj);
	sortInfo->compareCmdPtr = NULL;
    }
    return sortInfo->resultCode;
}

static int logicset_method_add (
  ClientData *simulator,
  Tcl_Interp *interp,
  int objc,
  Tcl_Obj *CONST objv[]
) {
  Tcl_Obj *varPtr,*listObj,*resultPtr;
  int length;
  Tcl_Obj **data;
  
  if(objc < 2) {
      Tcl_WrongNumArgs(interp, 1, objv, "varname element ...");
  }
  varPtr=Tcl_ObjGetVar2(interp,objv[1],NULL,0);
  if(!varPtr) {
    Tcl_ResetResult(interp);
    varPtr=Tcl_NewObj();
  }
  /*
  ** Make sure we have well formed list
  */
  if(Tcl_ListObjGetElements(interp,varPtr,&length,&data)!=TCL_OK) {
    return TCL_ERROR;
  }
  listObj=Tcl_NewListObj(length,data);
  
  if(objc>2) {
    if(Tcl_ListObjReplace(interp,listObj,length,0,(objc-2), (objv+2))) {
      return TCL_ERROR;
    }
  }
  resultPtr=Irm_ListObj_Sort(listObj);
  Tcl_ObjSetVar2(interp,objv[1],NULL,resultPtr,0);
  Tcl_SetObjResult(interp,resultPtr);
  return TCL_OK;
}

static int logicset_method_contains (
  ClientData *simulator,
  Tcl_Interp *interp,
  int objc,
  Tcl_Obj *CONST objv[]
) {
  int s1len, listLength, idx, match=1;
  Tcl_Obj *resultPtr;
  Tcl_Obj **listObjPtrs;
  char *s1;

  if (objc < 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "varlist element ...");
    return TCL_ERROR;
  }
  if(Tcl_ListObjGetElements(interp, objv[1], &listLength, &listObjPtrs)) {
    return TCL_ERROR;
  }
  
  for(idx=2;idx<objc && match;idx++) {
    int matchIdx;
    s1 = Tcl_GetStringFromObj(objv[idx], &s1len);
    matchIdx=Irm_Lsearch(listLength,listObjPtrs,s1,s1len);
    if(matchIdx < 0) {
      match=0;
    }
  }
  resultPtr=Tcl_NewBooleanObj(match);
  Tcl_SetObjResult(interp,resultPtr);
  return TCL_OK;
}

static int logicset_method_empty (
  ClientData *simulator,
  Tcl_Interp *interp,
  int objc,
  Tcl_Obj *CONST objv[]
) {
  int length;
  Tcl_Obj **data;
  
  if(objc != 2) {
      Tcl_WrongNumArgs(interp, 1, objv, "varlist");
  }
  /*
  ** Make sure we have well formed list
  */
  if(Tcl_ListObjGetElements(interp,objv[1],&length,&data)!=TCL_OK) {
    return TCL_ERROR;
  }
  if(length) {
    Tcl_SetObjResult(interp,Tcl_NewBooleanObj(0));
  } else {
    Tcl_SetObjResult(interp,Tcl_NewBooleanObj(1));
  }
  return TCL_OK;
}

static int logicset_method_remove (
  ClientData *simulator,
  Tcl_Interp *interp,
  int objc,
  Tcl_Obj *CONST objv[]
) {

int s1len, listLength, idx;
  Tcl_Obj *resultPtr,*listPtr;
  Tcl_Obj **listObjPtrs;
  char *s1;

  if (objc < 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "variable element ...");
    return TCL_ERROR;
  }
  listPtr=Tcl_ObjGetVar2(interp,objv[1],NULL,0);
  if(!listPtr) {
    Tcl_ResetResult(interp);
    listPtr=Tcl_NewObj();
  } else {
    listPtr=Tcl_DuplicateObj(listPtr);
  }
  
  if(Tcl_ListObjGetElements(interp, listPtr, &listLength, &listObjPtrs)) {
    return TCL_ERROR;
  }

  resultPtr=Tcl_NewObj();
  for(idx=0;idx<listLength;idx++) {
    int matchIdx;
    s1 = Tcl_GetStringFromObj(listObjPtrs[idx], &s1len);
    matchIdx=Irm_Lsearch((objc-2),(Tcl_Obj **)(objv+2),s1,s1len);
    if(matchIdx < 0) {
      Tcl_ListObjAppendElement(interp,resultPtr,listObjPtrs[idx]);
    }
  }
  Tcl_ObjSetVar2(interp,objv[1],NULL,resultPtr,0);
  Tcl_SetObjResult(interp,resultPtr);
  return TCL_OK;
}

static int logicset_method_sort (
  ClientData *simulator,
  Tcl_Interp *interp,
  int objc,
  Tcl_Obj *CONST objv[]
) {
    int i, index, unique, nocase = 0;
    Tcl_Obj *resultPtr, *cmdPtr, *listObj;
    SortInfo sortInfo;		/* Information about this sort that needs to
				 * be passed to the comparison function. */
    static const char *const switches[] = {
	"-ascii", "-command", "-decreasing", "-dictionary", "-increasing",
	"-index", "-indices", "-integer", "-nocase", "-real", "-stride",
	"-unique", NULL
    };
    enum Lsort_Switches {
	LSORT_ASCII, LSORT_COMMAND, LSORT_DECREASING, LSORT_DICTIONARY,
	LSORT_INCREASING, LSORT_INDEX, LSORT_INDICES, LSORT_INTEGER,
	LSORT_NOCASE, LSORT_REAL, LSORT_STRIDE, LSORT_UNIQUE
    };

    /*
     * The subList array below holds pointers to temporary lists built during
     * the merge sort. Element i of the array holds a list of length 2**i.
     */

    if (objc < 2) {
	Tcl_WrongNumArgs(interp, 1, objv, "?-option value ...? list");
	return TCL_ERROR;
    }

    /*
     * Parse arguments to set up the mode for the sort.
     */

    sortInfo.isIncreasing = 1;
    sortInfo.sortMode = SORTMODE_ASCII;
    sortInfo.indexv = NULL;
    sortInfo.indexc = 0;
    sortInfo.unique = 0;
    sortInfo.interp = interp;
    sortInfo.resultCode = TCL_OK;
    cmdPtr = NULL;
    unique = 0;

    for (i = 1; i < objc-1; i++) {
	if (Tcl_GetIndexFromObj(interp, objv[i], switches, "option", 0,
		&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum Lsort_Switches) index) {
	case LSORT_ASCII:
	    sortInfo.sortMode = SORTMODE_ASCII;
	    break;
	case LSORT_COMMAND:
	    if (i == (objc-2)) {
		Tcl_AppendResult(interp,
			"\"-command\" option must be followed "
			"by comparison command", NULL);
		return TCL_ERROR;
	    }
	    sortInfo.sortMode = SORTMODE_COMMAND;
	    cmdPtr = objv[i+1];
	    i++;
	    break;
	case LSORT_DECREASING:
	    sortInfo.isIncreasing = 0;
	    break;
	case LSORT_DICTIONARY:
	    sortInfo.sortMode = SORTMODE_DICTIONARY;
	    break;
	case LSORT_INCREASING:
	    sortInfo.isIncreasing = 1;
	    break;
	case LSORT_INTEGER:
	    sortInfo.sortMode = SORTMODE_INTEGER;
	    break;
	case LSORT_NOCASE:
	    nocase = 1;
	    break;
	case LSORT_REAL:
	    sortInfo.sortMode = SORTMODE_REAL;
	    break;
	case LSORT_UNIQUE:
	    unique = 1;
	    sortInfo.unique = 1;
	    break;
	case LSORT_INDICES:
        case LSORT_INDEX:
        case LSORT_STRIDE:
	    break;
      }
    }
    if (nocase && (sortInfo.sortMode == SORTMODE_ASCII)) {
	sortInfo.sortMode = SORTMODE_ASCII_NC;
    }

    listObj = objv[objc-1];

    if (sortInfo.sortMode == SORTMODE_COMMAND) {
	Tcl_Obj *newCommandPtr, *newObjPtr;

	/*
	 * When sorting using a command, we are reentrant and therefore might
	 * have the representation of the list being sorted shimmered out from
	 * underneath our feet. Take a copy (cheap) to prevent this. [Bug
	 * 1675116]
	 */

	listObj = Tcl_DuplicateObj(listObj);
	if (listObj == NULL) {
	    return TCL_ERROR;
	}

	/*
	 * The existing command is a list. We want to flatten it, append two
	 * dummy arguments on the end, and replace these arguments later.
	 */

	newCommandPtr = Tcl_DuplicateObj(cmdPtr);
	newObjPtr=Tcl_NewObj();
	Tcl_IncrRefCount(newCommandPtr);
	if (Tcl_ListObjAppendElement(interp, newCommandPtr, newObjPtr)
		!= TCL_OK) {
	    Tcl_DecrRefCount(newCommandPtr);
	    Tcl_DecrRefCount(listObj);
	    Tcl_IncrRefCount(newObjPtr);
	    Tcl_DecrRefCount(newObjPtr);
	    return TCL_ERROR;
	}
	Tcl_ListObjAppendElement(interp, newCommandPtr, Tcl_NewObj());
	sortInfo.compareCmdPtr = newCommandPtr;
    }
  if(Irm_ListObjFancy_Sort(listObj,&sortInfo,&resultPtr)) {
    return TCL_ERROR;
  }
  Tcl_SetObjResult(interp,resultPtr);
  return TCL_OK;
}

int DLLEXPORT Logicset_Init( Tcl_Interp *interp ) {
  char zAppend[256];
  char yAppend[256]; 
  Tcl_Namespace *modPtr;

  if (Tcl_InitStubs(interp, "8.1", 0) == NULL) {
    return TCL_ERROR;
  }

    if (Tcl_PkgRequire(interp, "Tcl", TCL_VERSION, 0) == NULL) {
        if (TCL_VERSION[0] == '7') {
            if (Tcl_PkgRequire(interp, "Tcl", "8.0", 0) == NULL) {
                return TCL_ERROR;
            }
        }
    }

  modPtr=Tcl_FindNamespace(interp,"logicset",NULL,TCL_NAMESPACE_ONLY);
  if(!modPtr) {
    modPtr = Tcl_CreateNamespace(interp, "logicset", NULL, NULL);
  }

  Tcl_CreateObjCommand(interp,"::logicset::add",(Tcl_ObjCmdProc *)logicset_method_add,NULL,NULL);
  Tcl_CreateObjCommand(interp,"::logicset::contains",(Tcl_ObjCmdProc *)logicset_method_contains,NULL,NULL);
  Tcl_CreateObjCommand(interp,"::logicset::empty",(Tcl_ObjCmdProc *)logicset_method_empty,NULL,NULL);
  Tcl_CreateObjCommand(interp,"::logicset::remove",(Tcl_ObjCmdProc *)logicset_method_remove,NULL,NULL);
  Tcl_CreateObjCommand(interp,"::logicset::sort",(Tcl_ObjCmdProc *)logicset_method_sort,NULL,NULL);
  
  Tcl_CreateEnsemble(interp, modPtr->fullName, modPtr, TCL_ENSEMBLE_PREFIX);
  Tcl_Export(interp, modPtr, "[a-z]*", 1);
    
  Tcl_PkgProvide(interp, "logicset", VERSION);

  return TCL_OK;
}



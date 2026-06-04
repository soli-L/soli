
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_KIOSK_GLOBAL" AUTHID CURRENT_USER AS
/* $Header: frmglobs.pls 120.0 2006/12/14 02:04:30 dvayro noship $ */
----------------------------------------------------------------------------------------
--  PROCEDURE:    ADI_Kiosk_Global                                                    --
--                                                                                    --
--  DESCRIPTION:  Contains a selection of global procedures which are required by     --
--                multiple packages.                                                  --
--                                                                                    --
--  PARAMETERS:   None                                                                --
--                                                                                    --
--  Modifications                                                                     --
--  Date       Username   Description                                                 --
--             cclyde     Initial creation                                            --
--  24-NOV-99  cclyde     Added function SetOwnershipPrivilege.  This checks to see   --
--                        if the current user has System Administration responsibility--
--                        assigned to them.  Anyone with Sys Admin responsibility     --
--                        is allowed to grant ownership.                              --
--  16-FEB-00  cclyde     Added Package_Revision procedure to see if we can capture   --
--                        the revision number of the package during runtime.          --
--                              (Task:  3858)                                         --
--  16-MAY-00  GSANAP     Moved the $Header comment from the top and replaced   --
--                        CREATE OR REPLACE PACKAGE IS TO AS                    --
--  14-NOV-02  GHOOKER    Stub out procedures not used by RM8                         --
----------------------------------------------------------------------------------------
END ADI_Kiosk_Global;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_KIOSK_GLOBAL" AS
/* $Header: frmglobb.pls 120.0 2006/12/14 02:04:20 dvayro noship $ */
----------------------------------------------------------------------------------------
--  PROCEDURE:    ADI_Kiosk_Global                                                    --
--                                                                                    --
--  DESCRIPTION:  Contains a selection of global procedures which are required by     --
--                multiple packages.                                                  --
--                                                                                    --
--  PARAMETERS:   None                                                                --
--                                                                                    --
--  Modifications                                                                     --
--  Date       Username   Description                                                 --
--             cclyde     Initial creation                                            --
--  24-AUG-99  cclyde     Added DebugMode function                                    --
--  31-AUG-99  cclyde     Changed profile option ADI_DEBUG_MODE to FRM_DEBUG_MODE     --
--                        (Task: 3400)    (DebugMode)                                 --
--  08-SEP-99  cclyde     Added the NO_DATA_FOUND exception clause.  This information --
--                        is now called from the banner and the user may, or may not  --
--                        be logged into the Report Manager kiosk.  (Task: 3381)      --
--                        (GetUserId)                                                 --
--  08-SEP-99  cclyde     Modified all the EXCEPTION clauses to include               --
--                        ICX_UTIL.Add_Error.                                         --
--  08-SEP-99  CCLYDE     Modified the way the Help URL was generated.  If the host-  --
--                        name has been defined with a '/' at the end, no trailing    --
--                        '/' is added.  (Task: 3458)  (getHelpURL)                   --
--  03-DEC-99  CCLYDE     Added GetOwnershipPrivilege to determine if the user can    --
--                        grant ownership privilege to any user, for any value.       --
--  16-FEB-00  cclyde     Added Package_Revision procedure to see if we can capture   --
--                        the revision number of the package during runtime.          --
--                              (Task:  3858)                                         --
--  02-MAR-00  GSANAP     Changed the select statement to change from 11.5 to 1.51    --
--                              (Task:  3925)                                         --
--  04-APR-00  GSANAP     Changed the select statement to take care of the spaces in  --
--                        the release name in ap323pc                                 --
--  16-MAY-00  GSANAP     Moved the $Header comment from the top and replaced         --
--                        CREATE OR REPLACE PACKAGE IS TO AS                          --
--  29-JUN-00  GSANAP     Modified the debug stmts to include package names           --
--                        Task 4425                                                   --
--  07-DEC-00  CCLYDE     Modified the getHelpURL procedure to build the Help URL     --
--                        correctly.     (GetHelpURL)                                 --
----------------------------------------------------------------------------------------
END ADI_Kiosk_Global;

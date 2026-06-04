
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_FILE" AUTHID CURRENT_USER AS
/* REM $Header: frmfiles.pls 120.0 2006/12/14 02:04:07 dvayro noship $ */
----------------------------------------------------------------------------------------
--  PACKAGE:      ADI_File                                                            --
--                                                                                    --
--  DESCRIPTION:  Calls procedure wwv_download.  This is done because the webdb       --
--                listener is hard coded to this procedure.                           --
--                                                                                    --
--  MODIFICATION HISTORY                                                              --
--  Date       Username  Description                                                  --
--  06-AUG-99  CCLYDE    Initial Creation                                             --
--  16-FEB-00  cclyde     Added Package_Revision procedure to see if we can capture   --
--                        the revision number of the package during runtime.          --
--                              (Task:  3858)                                         --
--  14-NOV-02  GHOOKER    Stub out procedures not used by RM8                         --
----------------------------------------------------------------------------------------
END ADI_File;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_FILE" AS
/* $Header: frmfileb.pls 120.0 2006/12/14 02:03:57 dvayro noship $ */

END ADI_File;

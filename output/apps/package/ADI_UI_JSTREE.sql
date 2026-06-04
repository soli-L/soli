
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_UI_JSTREE" AUTHID CURRENT_USER AS
/* $Header: frmtrees.pls 120.1 2006/12/14 02:28:52 dvayro noship $ */
-------------------------------------------------------------------------------
--  PROCEDURE:    ADI_UI_JSTREE                                              --
--                                                                           --
--  Description:  Creates the javascript used to build the navigation tree.  --
--                                                                           --
--  Modification History:                                                    --
--  Developer  Date       Description                                        --
--                                                                           --
--  GSANAP     16-MAY-00  Moved the $Header comment from the top to under    --
--                        the CREATE OR REPLACE stmt.                        --
--
--  DVAYRO  8-Jul-2002  Stub for delete
-------------------------------------------------------------------------------
END ADI_ui_jstree;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_UI_JSTREE" as
/* $Header: frmtreeb.pls 120.1 2006/12/14 02:28:41 dvayro noship $ */
-------------------------------------------------------------------------------
--  PROCEDURE:    ADI_UI_JSTREE                                              --
--                                                                           --
--  Description:  Creates the javascript used to build the navigation tree.  --
--                                                                           --
--  Modification History:                                                    --
--  Developer  Date       Description                                        --
--  CCLYDE     08-AUG-99  Redefined the navigation tree icons.               --
--  CCLYDE     09-AUG-99  Changed line icon from ADILINE.gif to ADIVLINE.gif --
--  CCLYDE     16-FEB-00  Added Package_Revision procedure to see if we can  --
--                        capture the revision number of the package during  --
--                        runtime.     (Task: 3858)                          --
--  CCLYDE     24-FEB-00  Purchasing SS links were failing because these     --
--                        forms/reports are being opened into a separate     --
--                        window.  Around the A HREF URLs, there was a set   --
--                        of 'double' single quotes.  The appearance of a    --
--                        single quote in the URL string was closing the     --
--                        string prematurely.  Change the '' to \".          --
--                             OpenJavascriptTags     (Bug: 1211566)         --
-- GSANAP      16-MAY-00  Moved the $Header comment from the top to under    --
--                        CREATE OR REPLACE PACKAGE stmt.                    --
-- DJANCIS     19-MAY-00  Changed chr calls to fnd_global.local_chr as       --
--                        per adchkdrv.                                      --
--
-- DVAYRO 8-Jul-02  Stubbed for delete
-------------------------------------------------------------------------------
END ADI_ui_jstree;

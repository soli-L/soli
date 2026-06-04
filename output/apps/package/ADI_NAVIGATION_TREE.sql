
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_NAVIGATION_TREE" AUTHID CURRENT_USER as
/* $Header: frmnavgs.pls 120.0 2006/12/14 02:06:19 dvayro noship $ */
-----------------------------------------------------------------------------------------
--   PROCEDURE     ADI_Navigation_Tree                                                 --
--                                                                                     --
--   DESCRIPTION:  Displays/creates the navigation structure for the kiosk portal.     --
--                                                                                     --
--   PARAMETERS:   None                                                                --
--                                                                                     --
--   Modifications                                                                     --
--   Date       Username   Description                                                 --
--   16-FEB-00  cclyde     Added Package_Revision procedure to see if we can capture   --
--                         the revision number of the package during runtime.          --
--                               (Task:  3858)                                         --
--   16-MAY-00  GSANAP     Moved the $Header comment from the top to under             --
--                         the CREATE OR REPLACE PACKAGE stmt.                         --
--   15-NOV-02  GHOOKER    Stub out procedures not used by RM8                         --
-----------------------------------------------------------------------------------------
END ADI_Navigation_Tree;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_NAVIGATION_TREE" as
/* $Header: frmnavgb.pls 120.0 2006/12/14 02:06:09 dvayro noship $ */
-----------------------------------------------------------------------------
--   PROCEDURE     ADI_Navigation_Tree                                     --
--                                                                         --
--   DESCRIPTION:  Displays/creates the navigation structure for the kiosk --
--                 portal.                                                 --
--                                                                         --
--   PARAMETERS:   None                                                    --
--                                                                         --
--   Modifications                                                         --
--   Date       Username   Description                                     --
--   05 AUG 99  CCLYDE     Changed the size of icons to display full sizes.--
--   07 AUG 99  CCLYDE     Change No Default frame to use the same shade   --
--                         of yellow used by the icon frame.               --
--   08 AUG 99  CCLYDE     Changed the background colour of the Icon frame --
--                         and add ALT labels to the icons.  Removed the   --
--                         text labels.                                    --
--   08 AUG 99  CCLYDE     Changed the height of the icon frame to 50 pixs --
--   09 AUG 99  CCLYDE     Changed the icon names.                         --
--   09 AUG 99  CCLYDE     Changed the default home page to display the    --
--                         large Apps icon.                                --
--   09 AUG 99  CCLYDE     Modified GetCompanyLogo - no longer a function  --
--                         and returns two values: document id, filename.  --
--   09 AUG 99  CCLYDE     Changed the order of the icons: Login/Logout,   --
--                         Language, Home and Help.  (Icon Frame).         --
--   09-AUG-99  CCLYDE     Background colour only the size of the company  --
--                         logo.   (Show_Tree_Page_Top)                    --
--   09-AUG-99  CCLYDE     Changed .jpg file to a .gif file - Splash Image --
--   23-AUG-99  cclyde     Added the banner to the top of the default 'no  --
--                         default page found' page.  (Task: 3283)         --
--                         (Show_Default_Page)                             --
--   09-SEP-99  cclyde     Commented out the Language icon.  Will fix this --
--                         issue in the next release.  (Show_Icon_Frame)   --
--   17-NOV-99  cclyde     Added a 'LOWER' function around the retrieved   --
--                         Company logo.  This enables us to match the     --
--                         current company logo with the original Apps logo--
--                         provided with the Report Manager product.       --
--                           (Task: 3754)  (Show_Tree_Page_Top)            --
--   17-NOV-99  cclyde     Modified the definition of g_companyLogo to     --
--                         lowercase text only.  (Task: 3754)              --
--   16-FEB-00  cclyde     Added Package_Revision procedure to see if we   --
--                         can capture the revision number of the package  --
--                         during runtime.     (Task: 3858)                --
--   16-MAY-00  GSANAP     Moved the $Header comment from the top to       --
--                         under the CREATE OR REPLACE PACKAGE stmt.       --
--   07-DEC-00  CCLYDE     New Help Tag:  rptmgr1004669                    --
--                              Show_Default_Page                          --
--                              Show_Icon_Frame                            --
--                              PackageRevision                            --
--   15-NOV-02  GHOOKER    Stub out procedures not used by RM8             --
-----------------------------------------------------------------------------
END ADI_Navigation_Tree;


  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADI_KIOSK_LOBS" AUTHID CURRENT_USER AS
/* $Header: frmlurls.pls 120.0 2006/12/14 02:05:58 dvayro noship $ */
/*============================================================================+
 |  Copyright (c) 2000 Oracle Corporation Belmont, California, USA            |
 |                       All rights reserved                                  |
 +============================================================================+
 |                                                                            |
 | FILENAME                                                                   |
 |                                                                            |
 |    frmlurls.pls                                                            |
 |                                                                            |
 | DESCRIPTION: Returns a URL for a file which has been stored in the         |
 |              fnd_lobs table.   This calls an AOL function which            |
 |              is only available in release 11.5 and higher.   It will       |
 |              be a stub module for < 11.5 releases                          |
 |              downloading a document that has been stored in the            |
 |              fnd_lobs table.                                               |
 |                                                                            |
 | NOTES:   The fnd_lobs table only exists in release 11i and higher.  This   |
 |          will therefore be a stub module in releases less than 11i         |
 |                                                                            |
 | HISTORY                                                                    |
 | 20-Mar-2000  Debbie Jancis  Initial Creation.  (TASK: 3769 )               |
 | 16-MAY-00 GSANAP Moved the $Header comment from the top                    |
 | 15-NOV-02 GHOOKER Stub out procedures not used by RM8                      |
 +===========================================================================*/
END ADI_KIOSK_LOBS;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADI_KIOSK_LOBS" AS
/* $Header: frmlurlb.pls 120.0 2006/12/14 02:05:48 dvayro noship $ */

/*============================================================================+
 |  Copyright (c) 2000 Oracle Corporation Belmont, California, USA            |
 |                       All rights reserved                                  |
 +============================================================================+
 |                                                                            |
 | FILENAME                                                                   |
 |                                                                            |
 |    frmlurlb.pls                                                            |
 |                                                                            |
 | DESCRIPTION: Returns a URL for a file which has been stored in the         |
 |              fnd_lobs table.   This calls an AOL function which            |
 |              is only available in release 11.5 and higher.   It will       |
 |              be a stub module for < 11.5 releases                          |
 |              downloading a document that has been stored in the            |
 |              fnd_lobs table.                                               |
 |                                                                            |
 | NOTES:   The fnd_lobs table only exists in release 11i and higher.  This   |
 |          will therefore be a stub module in releases less than 11i         |
 |                                                                            |
 | HISTORY                                                                    |
 | 20-Mar-2000  Debbie Jancis   Initial Creation.  (TASK: 3769 )              |
 | 16-MAY-00    GSANAP Moved the $Header comment from the top                 |
 | 15-NOV-02 GHOOKER Stub out procedures not used by RM8                      |
 +===========================================================================*/
END ADI_KIOSK_LOBS;

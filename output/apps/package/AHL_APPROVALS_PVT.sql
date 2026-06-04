
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPROVALS_PVT" AUTHID CURRENT_USER AS
/* $Header: AHLVAPRS.pls 120.0.12020000.2 2019/10/23 02:16:54 sracha ship $ */

-----------------------------------------------------------
-- PACKAGE
--    Ahl_Approvals_Pvt
--
-- PURPOSE
--    This package is a Private API for managing Approval Rules and Approvers information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    Create_Approvals   (see below for specification)
--    Update_Approvals   (see below for specification)
--    Delete_Approvals   (see below for specification)
--    Validate_Approvals (see below for specification)
--
--    Check_Approvals_Items (see below for specification)
--    Check_Approvals_Record (see below for specification)
--    Init_Approvals_Rec (see below for specification)
--    Complete_Approvals_Rec (see below for specification)
--
--    Create_Approvers (see below for specification)
--    Update_Approvers (see below for specification)
--    Delete_Approvers (see below for specification)
--    Validate_Approvers (see below for specification)
--
--    Check_Approvers_Items (see below for specification)
--    Check_Approvers_Record (see below for specification)
--    Init_Approvers_Rec (see below for specification)
--    Complete_Approvers_Rec (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 21-JAN-2002    SHBHANDA      Created.
-----------------------------------------------------------

-------------------------------------
-- Approval Rules Record Type   -----
-------------------------------------
--
TYPE Approval_Rules_Rec_Type IS RECORD (
   APPROVAL_RULE_ID           NUMBER,
   OBJECT_VERSION_NUMBER      NUMBER,
   APPROVAL_OBJECT_CODE       VARCHAR2(30),
   APPROVAL_PRIORITY_CODE     VARCHAR2(30),
   APPROVAL_TYPE_CODE         VARCHAR2(30),
   APPLICATION_USG_CODE       VARCHAR2(30),
   APPLICATION_USG            VARCHAR2(80),
   OPERATING_UNIT_ID          NUMBER,
   OPERATING_NAME             VARCHAR2(240),
   ACTIVE_START_DATE          DATE,
   ACTIVE_END_DATE            DATE,
   STATUS_CODE                VARCHAR2(30),
   SEEDED_FLAG                VARCHAR2(1),
   ATTRIBUTE_CATEGORY         VARCHAR2(30),
   ATTRIBUTE1                 VARCHAR2(150),
   ATTRIBUTE2                 VARCHAR2(150),
   ATTRIBUTE3                 VARCHAR2(150),
   ATTRIBUTE4                 VARCHAR2(150),
   ATTRIBUTE5                 VARCHAR2(150),
   ATTRIBUTE6                 VARCHAR2(150),
   ATTRIBUTE7                 VARCHAR2(150),
   ATTRIBUTE8                 VARCHAR2(150),
   ATTRIBUTE9                 VARCHAR2(150),
   ATTRIBUTE10                VARCHAR2(150),
   ATTRIBUTE11                VARCHAR2(150),
   ATTRIBUTE12                VARCHAR2(150),
   ATTRIBUTE13                VARCHAR2(150),
   ATTRIBUTE14                VARCHAR2(150),
   ATTRIBUTE15                VARCHAR2(150),
   APPROVAL_RULE_NAME         VARCHAR2(360),
   DESCRIPTION                VARCHAR2(2000),
   CREATION_DATE              DATE,
   CREATED_BY                 NUMBER,
   LAST_UPDATE_DATE           DATE,
   LAST_UPDATED_BY            NUMBER,
   lAST_UPDATE_LOGIN          NUMBER,
   OPERATION_FLAG             VARCHAR2(1),
   --Added by aschakka for Bug#30235037, Start
   PROGRAM_TYPE_CODE          VARCHAR2(30),
   PROGRAM_SUBTYPE_CODE       VARCHAR2(30),
   REVISION_TYPE_CODE         VARCHAR2(30)
   --Added by aschakka for Bug#30235037, End
  );

-------------------------------------
----- Approvers Record Type   -------
-------------------------------------

TYPE Approvers_Rec_Type IS RECORD (
   APPROVAL_APPROVER_ID       NUMBER,
   OBJECT_VERSION_NUMBER      NUMBER,
   APPROVAL_RULE_ID           NUMBER,
   APPROVER_TYPE_CODE         VARCHAR2(30),
   APPROVER_SEQUENCE          NUMBER,
   APPROVER_ID                NUMBER,
   APPROVER_NAME              VARCHAR2(100),
   LAST_UPDATE_DATE           DATE,
   LAST_UPDATED_BY            NUMBER,
   CREATION_DATE              DATE,
   CREATED_BY                 NUMBER,
   LAST_UPDATE_LOGIN          NUMBER,
   ATTRIBUTE_CATEGORY         VARCHAR2(30),
   ATTRIBUTE1                 VARCHAR2(150),
   ATTRIBUTE2                 VARCHAR2(150),
   ATTRIBUTE3                 VARCHAR2(150),
   ATTRIBUTE4                 VARCHAR2(150),
   ATTRIBUTE5                 VARCHAR2(150),
   ATTRIBUTE6                 VARCHAR2(150),
   ATTRIBUTE7                 VARCHAR2(150),
   ATTRIBUTE8                 VARCHAR2(150),
   ATTRIBUTE9                 VARCHAR2(150),
   ATTRIBUTE10                VARCHAR2(150),
   ATTRIBUTE11                VARCHAR2(150),
   ATTRIBUTE12                VARCHAR2(150),
   ATTRIBUTE13                VARCHAR2(150),
   ATTRIBUTE14                VARCHAR2(150),
   ATTRIBUTE15                VARCHAR2(150),
   OPERATION_FLAG             VARCHAR2(1)
   );

---------------------------------------------------
-- Table Type of Approval Rules Record Type   -----
---------------------------------------------------

Type Approvers_Tbl IS TABLE OF Approvers_Rec_Type
INDEX BY BINARY_INTEGER;

---------------------------------------------------------------------
-- PROCEDURE
--    Process_Approvals
--
-- PURPOSE
--    Process Approvals entry.
--
-- PARAMETERS
--    p_x_Approval_Rules_Rec: the record representing AHL_Approval_Rules_B and  AHL_Approval_Rules_TL tables
--    p_x_Approvers_Tbl     : the table representing the records of AHL_Approvers tables.
--
-- NOTES
--    1. Procedure helps out to link between JSP page and API package
--    2. On the basis  of operation flag as one field in each record type
--       the further procedure for create/update/delete for Approvals Rules and Approvers.
---------------------------------------------------------------------

PROCEDURE Process_Approvals (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,

   p_x_Approval_Rules_Rec IN  OUT NOCOPY Approval_Rules_Rec_Type,
   p_x_Approvers_Tbl      IN  OUT NOCOPY Approvers_Tbl,

   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2
);

---------------------------------------------------------------------
------------        APPROVAL RULES                      -------------
---------------------------------------------------------------------

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Approval_Rules
--
-- PURPOSE
--    Create Approval Rules entry.
--
-- PARAMETERS
--    p_Approval_rec: the record representing AHL_Approval_Rules_VL view..
--    x_Approval_Rule_Id: the Approval_Rule_Id.
--
-- NOTES
--    1. object_version_number will be set to 1.
--    2. If Approval_Rules_Id is passed in, the uniqueness will be checked.
--       Raise exception in case of duplicates.
--    4. If a flag column is passed in, check if it is 'Y' or 'N'.
--       Raise exception for invalid flag.
--    5. If a flag column is not passed in, default it to 'Y' or 'N'.
--    6. Please don't pass in any FND_API.g_miss_char/num/date.
-------------------------------------------------------------------
PROCEDURE Create_Approval_Rules (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2,

   p_Approval_Rules_Rec   IN  Approval_Rules_Rec_Type,
   x_Approval_Rules_Id    OUT NOCOPY NUMBER
);

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Approval_Rules
--
-- PURPOSE
--    Update an Approval_Rules entry.
--
-- PARAMETERS
--    p_Approval_Rules_rec: the record representing AHL_Approval_Rules_VL (without the ROW_ID column).
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--    2. If an attribute is passed in as FND_API.g_miss_char/num/date,
--       that column won't be updated.
--------------------------------------------------------------------
PROCEDURE Update_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,

   p_Approval_Rules_rec   IN  Approval_Rules_Rec_Type
);

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Approval_Rules
--
-- PURPOSE
--    Delete a Approval Rules entry.
--
-- PARAMETERS
--    p_Approval_Rules_id: the Approval_Rules_id
--    p_object_version: the object_version_number
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,

   p_Approval_Rule_Id  IN  NUMBER,
   p_object_version    IN  NUMBER
);

--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Approval Rules
--
-- PURPOSE
--    Validate a Approval Rules entry.
--
-- PARAMETERS
--    p_Approval_rec: the record representing AHL_Approval_Rules_VL (without ROW_ID).
--
-- NOTES
--    1. p_Approval_Rules_rec should be the complete Approval Rules record. There
--       should not be any FND_API.g_miss_char/num/date in it.
--    2. If FND_API.g_miss_char/num/date is in the record, then raise
--       an exception, as those values are not handled.
--------------------------------------------------------------------
PROCEDURE Validate_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,

   p_Approval_Rules_rec         IN  Approval_Rules_Rec_Type
);

---------------------------------------------------------------------
-- PROCEDURE
--    Check_Approval_Rules_Items
--
-- PURPOSE
--    Perform the item level checking including unique keys,
--    required columns, foreign keys, domain constraints.
--
-- PARAMETERS
--    p_Approval_Rules_rec: the record to be validated
--    p_validation_mode: JTF_PLSQL_API.g_create/g_update
---------------------------------------------------------------------
PROCEDURE Check_Approval_Rules_Items (
   p_Approval_Rules_rec       IN  Approval_Rules_Rec_Type,
   p_validation_mode IN  VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status   OUT NOCOPY VARCHAR2
);

---------------------------------------------------------------------
-- PROCEDURE
--    Check_Approval_Rules_Record
--
-- PURPOSE
--    Check the record level business rules.
--
-- PARAMETERS
--    p_Approval_Rules_rec: the record to be validated; may contain attributes
--       as FND_API.g_miss_char/num/date
--    p_complete_rec: the complete record after all "g_miss" items
--       have been replaced by current database values
---------------------------------------------------------------------
PROCEDURE Check_Approval_Rules_Record (
   p_Approval_Rules_rec        IN  Approval_Rules_Rec_Type,
   p_complete_rec     IN  Approval_Rules_Rec_Type := NULL,
   x_return_status    OUT NOCOPY VARCHAR2
);

---------------------------------------------------------------------
-- PROCEDURE
--    Init_Approval_Rules_Rec
--
-- PURPOSE
--    Initialize all attributes to be FND_API.g_miss_char/num/date.
---------------------------------------------------------------------
/*PROCEDURE Init_Approval_Rules_Rec (
   x_Approval_Rules_rec         OUT  NOCOPY Approval_Rules_Rec_Type
);
*/
---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Approval_Rules_Rec
--
-- PURPOSE
--    For Update_Approval_Rules, some attributes may be passed in as
--    FND_API.g_miss_char/num/date if the user doesn't want to
--    update those attributes. This procedure will replace the
--    "g_miss" attributes with current database values.
--
-- PARAMETERS
--    p_Approval_Rules_rec: the record which may contain attributes as
--       FND_API.g_miss_char/num/date
--    x_complete_rec: the complete record after all "g_miss" items
--       have been replaced by current database values
---------------------------------------------------------------------
PROCEDURE Complete_Approval_Rules_Rec (
   p_Approval_Rules_rec      IN  Approval_Rules_Rec_Type,
   x_complete_rec            OUT NOCOPY Approval_Rules_Rec_Type
);

---------------------------------------------------------------------
------------        APPROVERS                           -------------
---------------------------------------------------------------------

---------------------------------------------------------------------
-- PROCEDURE
--    Create_Approvers
--
-- PURPOSE
--    Create Approvers entry.
--
-- PARAMETERS
--    p_Approvers_rec: the record representing AHL_Approvers_V view..
--    x_Approval_Approver_Id: the Approval_Approver_Id.
--
-- NOTES
--    1. object_version_number will be set to 1.
--    2. If Approvers_Id is passed in, the uniqueness will be checked.
--       Raise exception in case of duplicates.
--    3. Please don't pass in any FND_API.g_mess_char/num/date.
---------------------------------------------------------------------

PROCEDURE Create_Approvers (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2,

   p_Approvers_Rec        IN  Approvers_Rec_Type,
   x_Approval_Approver_Id  OUT NOCOPY NUMBER
);

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Approvers
--
-- PURPOSE
--    Update an Approvers entry.
--

--
-- PARAMETERS
--    p_Approvers_rec: the record representing AHL_Approvers_V (without the ROW_ID column).
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--    2. If an attribute is passed in as FND_API.g_miss_char/num/date,
--       that column won't be updated.
--------------------------------------------------------------------
PROCEDURE Update_Approvers (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   p_Approvers_rec     IN  Approvers_Rec_Type,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Approvers
--
-- PURPOSE
--    Delete a Approvers entry.
--
-- PARAMETERS
--    p_Approvers_id: the Approvers_id
--    p_object_version: the object_version_number
--
-- ISSUES
--
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------

PROCEDURE Delete_Approvers (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
  p_Approval_Approver_Id     IN  NUMBER,
   p_object_version    IN  NUMBER,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Approvers
--
-- PURPOSE
--    Validate a Approvers entry.
--
-- PARAMETERS
--    p_Approvers_rec: the record representing AHL_Approvers_V (without ROW_ID).
--
-- NOTES
--    1. p_Approvers_rec should be the complete Approvers record. There
--       should not be any FND_API.g_miss_char/num/date in it.
--    2. If FND_API.g_miss_char/num/date is in the record, the raise
--       an exception, as those values are not handled.
--------------------------------------------------------------------
PROCEDURE Validate_Approvers (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,
   p_Approvers_rec     IN  Approvers_Rec_Type
);

--------------------------------------------------------------------
-- PROCEDURE
--    Check_Approvers_Items
--
-- PURPOSE
--    Perform the item level checking including unique keys,
--    required columns, foreign keys, domain constraints.
--
-- PARAMETERS
--    p_Approvers_rec: the record to be validated
--    p_validation_mode: JTF_PLSQL_API.g_create/g_update
---------------------------------------------------------------------
PROCEDURE Check_Approvers_Items (
   p_validation_mode     IN  VARCHAR2 := Jtf_Plsql_Api.g_create,
   p_Approvers_rec       IN  Approvers_Rec_Type,

   x_return_status       OUT NOCOPY VARCHAR2
);

---------------------------------------------------------------------

-- PROCEDURE
--    Check_Approvers_Record
--
-- PURPOSE
--    Check the record level business rules.
--
-- PARAMETERS
--    p_Approvers_rec: the record to be validated; may contain attributes
--       as FND_API.g_miss_char/num/date
--    p_complete_rec: the complete record after all "g_miss" items
--       have been replaced by current database values
---------------------------------------------------------------------
--PROCEDURE Check_Approvers_Record (
  -- p_Approvers_rec    IN  Approvers_Rec_Type,
   --p_complete_rec     IN  Approvers_Rec_Type := NULL,

--   x_return_status    OUT NOCOPY VARCHAR2
--);

---------------------------------------------------------------------
-- PROCEDURE
--    Init_Approvers_Rec
--
-- PURPOSE
--    Initialize all attributes to be FND_API.g_miss_char/num/date.
---------------------------------------------------------------------
/*PROCEDURE Init_Approvers_Rec (
   x_Approvers_rec         OUT  NOCOPY Approvers_Rec_Type
);
*/

---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Approvers_Rec
--
-- PURPOSE
--    For Update_Approvers, some attributes may be passed in as
--    FND_API.g_miss_char/num/date if the user doesn't want to
--    update those attributes. This procedure will replace the
--    "g_miss" attributes with current database values.
--
-- PARAMETERS
--    p_Approvers_rec: the record which may contain attributes as
--       FND_API.g_miss_char/num/date
--    x_complete_rec: the complete record after all "g_miss" items
--       have been replaced by current database values
---------------------------------------------------------------------
PROCEDURE Complete_Approvers_Rec (
   p_Approvers_rec  IN  Approvers_Rec_Type,
   x_complete_rec   OUT NOCOPY Approvers_Rec_Type
);

END Ahl_Approvals_Pvt;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPROVALS_PVT" AS
/* $Header: AHLVAPRB.pls 120.2.12020000.2 2019/10/23 02:21:23 sracha ship $ */
-----------------------------------------------------------
-- PACKAGE
--    AHL_Approval_Rules_PVT
--
-- PROCEDURES
--    AHL_Approval_Rules_B AND AHL_Approval_Rules_TL:
--       Check_Approval_Rules_Req_Items
--       Check_Approval_Rules_UK_Items
--    AHL_Approvers:
--       Check_Approvers_Req_Items
--       Check_Approvers_UK_Items
--
-- NOTES
--
--
-- HISTORY
-- 20-Jan-2002    shbhanda      Created.
-----------------------------------------------------------------
-- Global CONSTANTS
G_PKG_NAME           CONSTANT VARCHAR2(30) := 'AHL_Approvals_PVT';
-- Reema : FND Logging
G_DEBUG          VARCHAR2(1):=AHL_DEBUG_PUB.is_log_enabled;

-- Perform record level(inter-field) validation only
G_VALID_APPROVER     CONSTANT NUMBER:= 50;
G_VALID_QUALIFIER    CONSTANT NUMBER:= 40;
G_MATCH_STATUS       CONSTANT NUMBER:= 30;
G_VALID_NAME         CONSTANT NUMBER:= 20;

/* Start code by shbhanda on 10-MAR-02 */
 -- Added for use by bind_parse.
  TYPE col_val_rec IS RECORD (
      col_name    VARCHAR2(2000),
      col_op      VARCHAR2(10),
      col_value   VARCHAR2(2000) );

  TYPE col_val_tbl IS TABLE OF col_val_rec INDEX BY BINARY_INTEGER;
/* End code by shbhanda on 10-MAR-02 */

--       Check_Approval_Rules_Req_Items
PROCEDURE Check_Approval_Rules_Req_Items (
   p_Approval_Rules_rec    IN    Approval_Rules_Rec_Type,
   x_return_status         OUT NOCOPY   VARCHAR2
);

--       Check_Approval_Rules_UK_Items
PROCEDURE Check_Approval_Rules_UK_Items (
   p_Approval_Rules_rec    IN    Approval_Rules_Rec_Type,
   p_validation_mode       IN    VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status         OUT NOCOPY   VARCHAR2
);

--      Compare Columns
FUNCTION compare_columns(
   l_Approval_Rules_rec    IN     Approval_Rules_Rec_Type
) RETURN VARCHAR2;
-- FND_API.g_true/g_false

--   Check_Approver_for_Rule : to check at least one approver present when status updating to active for approval
PROCEDURE Check_Approver_for_Rule (
   p_Approval_Rules_rec    IN  Approval_Rules_Rec_Type,
   p_complete_rec          IN  Approval_Rules_Rec_Type := NULL,
   x_return_status         OUT NOCOPY VARCHAR2
);

--   Check_Default_Approver : whether ApproverType is Role and Name as Empty
PROCEDURE Check_Approver_Role (
   p_Approvers_rec         IN  Approvers_Rec_Type,
   p_complete_rec          IN  Approvers_Rec_Type := NULL,
   x_return_status         OUT NOCOPY VARCHAR2
);

--  Check_Active_for_Qualifier : to check whether for a particular approval qualifier
--  among all approvals only one of them is to be active
--  Qualifier comprises of 'Approval Object Code', 'Approval Priority Code', 'Approval Type Code' and 'Operating Unit Id'
PROCEDURE Check_Active_for_Qualifier (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
);

--    Check_Approver_Sequence : it should not be Zero OR Negative sequence
PROCEDURE Check_Approver_Sequence (
   p_Approvers_rec        IN  Approvers_Rec_Type,
   p_complete_rec         IN  Approvers_Rec_Type := NULL,
   x_return_status        OUT NOCOPY VARCHAR2
);

--    Check_Approver_User/Role Name : if it is entered by user .[A selected from LOV then
--   retrieve the id value  check whether the entered name is valid
/*PROCEDURE Check_Approver_Name (
   p_Approvers_rec        IN  Approvers_Rec_Type,
   p_complete_rec         IN  Approvers_Rec_Type := NULL,
   x_return_status        OUT NOCOPY VARCHAR2
);*/


--   Check_Operating_Name : if it is entered by user  selected from LOV then
--   retrieve the operating unit id value  check whether the entered name is valid
PROCEDURE Check_Operating_Name (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
);

PROCEDURE Check_Appl_Usg_Code(
    p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
    x_return_status      OUT NOCOPY VARCHAR2
);


--   Check_Match_for_Status : to validate the various combination of current  status code
PROCEDURE Check_Match_for_Status(
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
);

--    Check_Approvers_Req_Items
PROCEDURE Check_Approvers_Req_Items (
   p_Approvers_rec    IN    Approvers_Rec_Type,
   x_return_status    OUT NOCOPY   VARCHAR2
);

--      Check_Approvers_UK_Items
PROCEDURE Check_Approvers_UK_Items (
   p_Approvers_rec    IN    Approvers_Rec_Type,
   p_validation_mode  IN    VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status    OUT NOCOPY   VARCHAR2
);

PROCEDURE Check_Approver_Name_Or_Id(
            p_approvers_rec  IN Approvers_rec_type,
            x_approver_id  OUT NOCOPY NUMBER,
            x_return_status OUT NOCOPY VARCHAR2
            );

--------------------------------------------------------------------
-- PROCEDURE
--    Process_Wf_Mapping for both Approval Rules
--
--------------------------------------------------------------------
PROCEDURE Process_Approvals (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,

   p_x_Approval_Rules_Rec IN  OUT NOCOPY Approval_Rules_Rec_Type,
   p_x_Approvers_Tbl      IN  OUT NOCOPY Approvers_Tbl,

   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2
)
IS
   L_API_VERSION        CONSTANT NUMBER := 1.0;
   L_API_NAME           CONSTANT VARCHAR2(30) := 'Creation';
   L_FULL_NAME          CONSTANT VARCHAR2(60) := 'Approvals' || '.' || L_API_NAME;

   l_x_Approval_Rules_Rec   Approval_Rules_Rec_Type := p_x_Approval_Rules_Rec;
   l_x_Approvers_Tbl        Approvers_Tbl := p_x_Approvers_Tbl;

   l_dummy              NUMBER;
   l_return_status      VARCHAR2(1);
   p_object_version     VARCHAR2(1) := 1;
   x_Approval_Rules_Id  NUMBER;
   x_Approval_Approver_Id NUMBER;

BEGIN
    --------------------- initialize -----------------------
   SAVEPOINT Process_Approvals;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
    Ahl_Debug_Pub.enable_debug;
   END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
   END IF;

   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;

   IF NOT Fnd_Api.compatible_api_call (
         L_API_VERSION,
         p_api_version,
         L_API_NAME,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;

   x_return_status := Fnd_Api.g_ret_sts_success;

   ----------------------- validate -----------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Validate');
   END IF;

   ---------------Manipulations in Approval Rules---------------
   IF (l_x_Approval_Rules_Rec.operation_flag = 'C' OR l_x_Approval_Rules_Rec.operation_flag = 'c') THEN
                  -- For creation of Approvers
              Create_Approval_Rules (
                p_api_version,
                p_init_msg_list,
                p_commit,
                p_validation_level,
                x_return_status ,
                x_msg_count,
                x_msg_data,
                l_x_Approval_Rules_Rec,
                X_APPROVAL_RULES_ID);

                p_x_Approval_Rules_Rec.APPROVAL_RULE_ID:=X_APPROVAL_RULES_ID;

          END IF;
          IF (l_x_Approval_Rules_Rec.operation_flag = 'U' OR l_x_Approval_Rules_Rec.operation_flag = 'u') THEN
            -- For updation of Approvers
              Update_Approval_Rules (
                p_api_version ,
                p_init_msg_list,
                p_commit,
                p_validation_level,
                x_return_status,
                x_msg_count,
                x_msg_data,
                l_x_Approval_Rules_Rec);
          END IF;
   ---------------Manipulations in Approvers---------------
    IF (l_x_Approvers_Tbl.COUNT > 0) THEN
        FOR i IN l_x_Approvers_Tbl.FIRST..l_x_Approvers_Tbl.LAST LOOP
          IF (l_x_Approvers_Tbl(i).operation_flag = 'C' OR l_x_Approvers_Tbl(i).operation_flag = 'c') THEN
            -- For creation of Approvers
              Create_Approvers (
                p_api_version,
                p_init_msg_list,
                p_commit,
                p_validation_level,
                x_return_status,
                x_msg_count,
                x_msg_data,
                l_x_Approvers_Tbl(i),
                x_Approval_Approver_Id);

                p_x_Approvers_Tbl(i).APPROVAL_APPROVER_ID := x_Approval_Approver_Id;

          END IF;
          IF (l_x_Approvers_Tbl(i).operation_flag = 'U' OR l_x_Approvers_Tbl(i).operation_flag = 'u') THEN
            -- For updation of Approvers
              Update_Approvers (
                p_api_version ,
                p_init_msg_list,
                p_commit,
                p_validation_level,
                l_x_Approvers_Tbl(i),
                x_return_status,
                x_msg_count,
                x_msg_data);
          END IF;
          IF (l_x_Approvers_Tbl(i).operation_flag = 'D' OR l_x_Approvers_Tbl(i).operation_flag = 'd') THEN
            -- For deletion of Approvers
              Delete_Approvers (
                   p_api_version,
                   p_init_msg_list,
                   p_commit,
                   p_validation_level,
                   l_x_Approvers_Tbl(i).Approval_Approver_Id,
                   p_object_version,
                   x_return_status,
                   x_msg_count,
                   x_msg_data
                   );
           END IF;
        END LOOP;
     END IF;

   IF l_return_status = Fnd_Api.g_ret_sts_error THEN
      RAISE Fnd_Api.g_exc_error;
   ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;

   --
   -- END of API body.
   --
   -- Standard check of p_commit.
   IF Fnd_Api.To_Boolean (p_commit) THEN
      COMMIT WORK;
   END IF;
   Fnd_Msg_Pub.count_and_get(
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF G_DEBUG='Y' THEN
     Ahl_Debug_Pub.disable_debug;
    END IF;

EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Process_Approvals;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get(
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Process_Approvals;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Process_Approvals;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error) THEN
         Fnd_Msg_Pub.add_exc_msg (g_pkg_name, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );

END Process_Approvals;


--------------------------------------------------------------------
-----          Approval_Rules           -----
--------------------------------------------------------------------
     /* Start code on 11-MAR-02 by shbhanda */

---------------------------------------------------------------------
-- PROCEDURE
--    bind_parse
-- USAGE
--    bind_parse (varchar2, col_val_tbl);
--    The input string must have a space between the AND and operator clause
--    and it must exclude the initial WHERE/AND statement.
--    Example: source_code = 'xyz' and campaign_id <> 1
---------------------------------------------------------------------
PROCEDURE bind_parse (
   p_string IN VARCHAR2,
   x_col_val_tbl OUT NOCOPY col_val_tbl)
IS
   l_new_str   VARCHAR2(4000);
   l_str       VARCHAR2(4000) := p_string;
   l_curr_pos  NUMBER;  -- the position index of the operator string
   l_eq_pos    NUMBER;
   l_not_pos   NUMBER;
   l_and_pos   NUMBER;
   l_like_pos  NUMBER;
   i         NUMBER := 1;
BEGIN
   LOOP
       l_and_pos := INSTR (UPPER (l_str), ' AND ');
      -- handle condition where no more AND's are
      -- left -- usually if only one condition or
      -- the last condition in the WHERE clause.
      IF l_and_pos = 0 THEN
         l_new_str := l_str;
      ELSE
         l_new_str := SUBSTR (l_str, 1, l_and_pos - 1);
      END IF;

      --
      -- The operator should also be passed
      -- back to the calling program.
      l_eq_pos := INSTR (l_new_str, '=');
      l_not_pos := INSTR (l_new_str, '<>');
      l_like_pos := INSTR (l_new_str, 'LIKE');

      --
      -----------------------------------
      -- operator    equal    not equal
      -- error       0        0
      -- =           1        0
      -- <>          0        1
      -- =           1        2
      -- <>          2        1
      -----------------------------------

      IF l_eq_pos = 0 AND l_not_pos = 0 AND l_like_pos = 0 THEN
         -- Could not find either an = or an <>
         -- operator.
         IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_unexp_error) THEN
            Fnd_Message.set_name('AHL', 'AHL_UTIL_NO_WHERE_OPERATOR');
            Fnd_Msg_Pub.ADD;
            RAISE Fnd_Api.g_exc_unexpected_error;
         END IF;
      ELSIF l_eq_pos > 0 AND l_not_pos = 0 THEN
         l_curr_pos := l_eq_pos;
         x_col_val_tbl(i).col_op := '=';
      ELSIF l_not_pos > 0 AND l_eq_pos = 0 THEN
         l_curr_pos := l_not_pos;
         x_col_val_tbl(i).col_op := '<>';
      ELSIF l_eq_pos < l_not_pos THEN
         l_curr_pos := l_eq_pos;
         x_col_val_tbl(i).col_op := '=';
      ELSIF l_eq_pos = 0 AND l_not_pos = 0 AND l_like_pos <> 0 THEN
         l_curr_pos := l_like_pos;
         x_col_val_tbl(i).col_op := 'LIKE';
      ELSE
         l_curr_pos := l_not_pos;
         x_col_val_tbl(i).col_op := '<>';
      END IF;

      x_col_val_tbl(i).col_name := UPPER (LTRIM (RTRIM (SUBSTR (l_new_str, 1, l_curr_pos - 1))));

      IF x_col_val_tbl(i).col_op = 'LIKE' THEN
      -- Add 4 to the current position for 'LIKE'
      x_col_val_tbl(i).col_value := LTRIM (RTRIM (SUBSTR (l_new_str, l_curr_pos + 4)));
      ELSE
      -- Add 2 to the current position for '<>'.
      x_col_val_tbl(i).col_value := LTRIM (RTRIM (SUBSTR (l_new_str, l_curr_pos + 2)));
      --
      END IF;

      -- Remove the single quotes from the begin and end of the string value;
      -- no action if a numeric value.
      IF INSTR (x_col_val_tbl(i).col_value, '''', 1) = 1 THEN
         x_col_val_tbl(i).col_value := SUBSTR (x_col_val_tbl(i).col_value,2);
         x_col_val_tbl(i).col_value := SUBSTR (x_col_val_tbl(i).col_value, 1, LENGTH(x_col_val_tbl(i).col_value) - 1);
      END IF;

      IF l_and_pos = 0 THEN
         EXIT; -- no more to parse
      END IF;

      l_str := SUBSTR (l_str, l_and_pos + 4);
      i := i + 1;
   END LOOP;
END bind_parse;

---------------------------------------------------------------------
-- FUNCTION
--    Check_Rules_Uniqueness
--
-- HISTORY
--    Use bind_parse to enable use of bind variables.
--    p_null_value_flag (values : 'C' = approval_prority_code; 'I' = operating_unit_id;
--                   'B' Both 'C' and 'I'; 'N' = None of them)
---------------------------------------------------------------------
FUNCTION Check_Rules_Uniqueness(
   p_table_name    IN VARCHAR2,
   p_where_clause  IN VARCHAR2,
   p_null_value_flag IN VARCHAR2
)
RETURN VARCHAR2
IS

   l_sql   VARCHAR2(4000);
   l_count NUMBER;
   l_bind_tbl  col_val_tbl;
   l_and_proirity_clause VARCHAR2(100) := ' AND approval_priority_code IS NULL';
   l_and_operating_clause VARCHAR2(100) := ' AND operating_unit_id IS NULL';

BEGIN

   l_sql := 'SELECT 1 FROM DUAL WHERE EXISTS (SELECT 1 FROM ' || UPPER(p_table_name);
   bind_parse (p_where_clause, l_bind_tbl);
   --
   -- Support up to 6 WHERE conditions for uniqueness.  If
   -- the number of conditions changes, then must also revise
   -- the execute portion of the code.
   IF l_bind_tbl.COUNT <= 6 THEN
      l_sql := l_sql || ' WHERE ' || l_bind_tbl(1).col_name || ' ' || l_bind_tbl(1).col_op || ' :b1';
      FOR i IN 2..l_bind_tbl.COUNT LOOP
         l_sql := l_sql || ' AND ' || l_bind_tbl(i).col_name || ' ' || l_bind_tbl(i).col_op || ' :b' || i;
      END LOOP;
   ELSE
      -- Exceeded the number of conditions supported
      -- for bind variables.
      l_sql := l_sql || ' WHERE ' || p_where_clause;
   END IF;

--   IF l_bind_tbl.COUNT < 2 THEN
   IF p_null_value_flag = 'N' THEN
   l_sql := l_sql || ')';
   ELSE
   l_sql := l_sql ;
   END IF;

   Ahl_Utility_Pvt.debug_message('SQL statement: '||l_sql);
   --
   -- Modify here if number of WHERE conditions
   -- supported changes.
   BEGIN
      IF l_bind_tbl.COUNT = 1 OR l_bind_tbl.COUNT = 2 THEN
         EXECUTE IMMEDIATE l_sql INTO l_count
         USING l_bind_tbl(1).col_value;
      ELSIF l_bind_tbl.COUNT = 3 THEN
            EXECUTE IMMEDIATE l_sql || l_and_operating_clause || l_and_proirity_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value;
      ELSIF l_bind_tbl.COUNT = 4 THEN
        IF p_null_value_flag = 'C' THEN
            EXECUTE IMMEDIATE l_sql || l_and_proirity_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value, l_bind_tbl(4).col_value;
        ELSIF p_null_value_flag = 'I' THEN
            EXECUTE IMMEDIATE l_sql || l_and_operating_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value, l_bind_tbl(4).col_value;
        ELSIF p_null_value_flag = 'B' THEN
            EXECUTE IMMEDIATE l_sql || l_and_operating_clause || l_and_proirity_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value, l_bind_tbl(4).col_value;
        ELSE
            EXECUTE IMMEDIATE l_sql INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value, l_bind_tbl(4).col_value;
        END IF;
      ELSIF l_bind_tbl.COUNT = 5 THEN
        IF p_null_value_flag = 'C' THEN
            EXECUTE IMMEDIATE l_sql || l_and_proirity_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value , l_bind_tbl(3).col_value, l_bind_tbl(4).col_value, l_bind_tbl(5).col_value;
        ELSIF p_null_value_flag = 'I' THEN
            EXECUTE IMMEDIATE l_sql || l_and_operating_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value , l_bind_tbl(3).col_value, l_bind_tbl(4).col_value, l_bind_tbl(5).col_value;
        ELSIF p_null_value_flag = 'B' THEN
            EXECUTE IMMEDIATE l_sql || l_and_operating_clause || l_and_proirity_clause || ')' INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value , l_bind_tbl(3).col_value, l_bind_tbl(4).col_value, l_bind_tbl(5).col_value;
        ELSE
            EXECUTE IMMEDIATE l_sql INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value , l_bind_tbl(3).col_value, l_bind_tbl(4).col_value, l_bind_tbl(5).col_value;
        END IF;
      ELSIF l_bind_tbl.COUNT = 6 THEN
            EXECUTE IMMEDIATE l_sql INTO l_count
            USING l_bind_tbl(1).col_value, l_bind_tbl(2).col_value, l_bind_tbl(3).col_value, l_bind_tbl(4).col_value, l_bind_tbl(5).col_value, l_bind_tbl(6).col_value;
      ELSE
            EXECUTE IMMEDIATE l_sql INTO l_count;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_count := 0;
   END;

   IF l_count = 0 THEN
      RETURN Fnd_Api.g_true;
   ELSE
      RETURN Fnd_Api.g_false;
   END IF;

END Check_Rules_Uniqueness;

---------------------------------------------------------------------

/* End code on 11-MAR-02 by shbhanda */
--------------------------------------------------------------------
-- PROCEDURE
--    Create_Approval_Rules
--
--------------------------------------------------------------------

PROCEDURE Create_Approval_Rules (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2,
   p_Approval_Rules_rec   IN  Approval_Rules_Rec_Type,
   x_Approval_Rules_id    OUT NOCOPY NUMBER
)
IS
   L_API_VERSION          CONSTANT NUMBER := 1.0;
   L_API_NAME             CONSTANT VARCHAR2(30) := 'Create_Approval_Rules';
   L_FULL_NAME            CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_Approval_Rules_rec    Approval_Rules_Rec_Type := p_Approval_Rules_rec;
   l_dummy                NUMBER;
   l_return_status        VARCHAR2(1);
   l_rowid                VARCHAR2(30);
   l_object_version_number NUMBER := 1;
   l_status VARCHAR2(30) := 'DRAFT';
   l_seed   VARCHAR2(1) := 'N';

   CURSOR c_seq IS
      SELECT Ahl_Approval_Rules_B_S.NEXTVAL
      FROM   dual;

   CURSOR c_id_exists (x_id IN NUMBER) IS
      SELECT 1
      FROM   dual
      WHERE EXISTS (SELECT 1
                    FROM   Ahl_Approval_Rules_vl
                    WHERE  Approval_Rule_id = x_id);
   CURSOR c_operating IS
      SELECT ORGANIZATION_ID
      FROM HR_OPERATING_UNITS
      WHERE NAME = l_Approval_Rules_rec.OPERATING_NAME;

   -- Reema :
   -- Added cursor for Application Usage Code
   CURSOR c_appl_usg IS
      SELECT LOOKUP_CODE
      FROM FND_LOOKUPS
      WHERE MEANING = l_Approval_Rules_rec.APPLICATION_USG
      AND LOOKUP_TYPE = 'AHL_APPLICATION_USAGE_CODE';

BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Create_Approval_Rules;
   -- Check if API is called in debug mode. If yes, enable debug.
            IF G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;

   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         L_API_VERSION,
         p_api_version,
         L_API_NAME,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;
   ----------------------- validate -----------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Validate');
    END IF;

   Validate_Approval_Rules (
      p_api_version        => l_api_version,
      p_init_msg_list      => p_init_msg_list,
      p_commit             => p_commit,
      p_validation_level   => p_validation_level,
      x_return_status      => l_return_status,
      x_msg_count          => x_msg_count,
      x_msg_data           => x_msg_data,
      p_Approval_Rules_rec => l_Approval_Rules_rec
   );
   IF l_return_status = Fnd_Api.g_ret_sts_error THEN
      RAISE Fnd_Api.g_exc_error;
   ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   --
   -- Check for the ID.
   --
  IF l_Approval_Rules_rec.APPROVAL_RULE_ID IS Null OR l_Approval_Rules_rec.APPROVAL_RULE_ID = Fnd_Api.g_miss_num THEN

      LOOP
         --
         -- If the ID is not passed into the API, then
         -- grab a value from the sequence.
         OPEN c_seq;
         FETCH c_seq INTO l_Approval_Rules_rec.APPROVAL_RULE_ID;
         CLOSE c_seq;

         --
         -- Check to be sure that the sequence does not exist.
         OPEN c_id_exists (l_Approval_Rules_rec.APPROVAL_RULE_ID);
         FETCH c_id_exists INTO l_dummy;
         CLOSE c_id_exists;
         --
         -- If the value for the ID already exists, then
         -- l_dummy would be populated with '1', otherwise,
         -- it receives NULL.
         EXIT WHEN l_dummy IS NULL;
      END LOOP;
   END IF;

   --
   -- To check whether the Operating Name is valid.

  IF l_Approval_Rules_rec.Operating_Unit_Id IS NULL AND l_Approval_Rules_rec.Operating_Name IS NOT NULL THEN
    IF p_validation_level >= G_VALID_NAME THEN
        Check_Operating_Name (
           p_Approval_Rules_rec  => p_Approval_Rules_rec,
           p_complete_rec        => l_Approval_Rules_rec,
           x_return_status       => l_return_status
         );
         IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
            RAISE Fnd_Api.g_exc_unexpected_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
            RAISE Fnd_Api.g_exc_error;
         ELSE
            OPEN  c_operating;
            FETCH c_operating INTO l_Approval_Rules_rec.Operating_Unit_Id;
            CLOSE c_operating;
         END IF;
     END IF;
  END IF;

  -- Reema:
  -- Check whether the Application Usage Code is valid
  /*IF p_validation_level >= G_VALID_NAME THEN
        Check_Appl_Usg_Code (
           p_Approval_Rules_rec  => p_Approval_Rules_rec,
           x_return_status       => l_return_status
         );
         IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
            RAISE Fnd_Api.g_exc_unexpected_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
            RAISE Fnd_Api.g_exc_error;
         ELSE
            OPEN  c_appl_usg;
            FETCH c_appl_usg INTO l_Approval_Rules_rec.Application_Usg_Code;
         IF c_appl_usg%NOTFOUND THEN
        IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_APPUSG_INVALID');
                Fnd_Msg_Pub.ADD;
                END IF;
            RAISE Fnd_Api.g_exc_unexpected_error;
             END IF;
    END IF;
  END IF;
*/
   -------------------------- insert --------------------------
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Insert');
    END IF;

   -- Invoke the table handler to create a record
   --

   Ahl_Approval_Rules_Pkg.Insert_Row (
     X_ROWID                 => l_rowid,
     X_APPROVAL_RULE_ID      => l_Approval_Rules_rec.APPROVAL_RULE_ID,
     X_OBJECT_VERSION_NUMBER => 1,
     X_APPROVAL_OBJECT_CODE  => l_Approval_Rules_rec.APPROVAL_OBJECT_CODE,
     X_APPROVAL_PRIORITY_CODE=> l_Approval_Rules_rec.APPROVAL_PRIORITY_CODE,
     X_APPROVAL_TYPE_CODE    => l_Approval_Rules_rec.APPROVAL_TYPE_CODE,
     X_APPLICATION_USG_CODE  => l_Approval_Rules_rec.APPLICATION_USG_CODE,
     X_OPERATING_UNIT_ID     => l_Approval_Rules_rec.OPERATING_UNIT_ID,
     X_ACTIVE_START_DATE     => l_Approval_Rules_rec.ACTIVE_START_DATE,
     X_ACTIVE_END_DATE       => l_Approval_Rules_rec.ACTIVE_END_DATE,
     X_STATUS_CODE           => l_status,
     X_SEEDED_FLAG           => l_seed,
     X_ATTRIBUTE_CATEGORY    => l_Approval_Rules_rec.ATTRIBUTE_CATEGORY,
     X_ATTRIBUTE1            => l_Approval_Rules_rec.ATTRIBUTE1,
     X_ATTRIBUTE2            => l_Approval_Rules_rec.ATTRIBUTE2,
     X_ATTRIBUTE3            => l_Approval_Rules_rec.ATTRIBUTE3,
     X_ATTRIBUTE4            => l_Approval_Rules_rec.ATTRIBUTE4,
     X_ATTRIBUTE5            => l_Approval_Rules_rec.ATTRIBUTE5,
     X_ATTRIBUTE6            => l_Approval_Rules_rec.ATTRIBUTE6,
     X_ATTRIBUTE7            => l_Approval_Rules_rec.ATTRIBUTE7,
     X_ATTRIBUTE8            => l_Approval_Rules_rec.ATTRIBUTE8,
     X_ATTRIBUTE9            => l_Approval_Rules_rec.ATTRIBUTE9,
     X_ATTRIBUTE10           => l_Approval_Rules_rec.ATTRIBUTE10,
     X_ATTRIBUTE11           => l_Approval_Rules_rec.ATTRIBUTE11,
     X_ATTRIBUTE12           => l_Approval_Rules_rec.ATTRIBUTE12,
     X_ATTRIBUTE13           => l_Approval_Rules_rec.ATTRIBUTE13,
     X_ATTRIBUTE14           => l_Approval_Rules_rec.ATTRIBUTE14,
     X_ATTRIBUTE15           => l_Approval_Rules_rec.ATTRIBUTE15,
     X_APPROVAL_RULE_NAME    => l_Approval_Rules_rec.APPROVAL_RULE_NAME,
     X_DESCRIPTION           => l_Approval_Rules_rec.DESCRIPTION,
     X_CREATION_DATE         => SYSDATE,
     X_CREATED_BY            => Fnd_Global.USER_ID,
     X_LAST_UPDATE_DATE      => SYSDATE,
     X_LAST_UPDATED_BY       => Fnd_Global.USER_ID,
     X_LAST_UPDATE_LOGIN     => Fnd_Global.LOGIN_ID,
     --Added by aschakka for Bug#30235037, Start
     X_PROGRAM_TYPE_CODE     => l_Approval_Rules_rec.program_type_code,
     X_PROGRAM_SUBTYPE_CODE  => l_Approval_Rules_rec.program_subtype_code,
     X_REVISION_TYPE_CODE    => l_Approval_Rules_rec.revision_type_code
     --Added by aschakka for Bug#30235037, End
 );

   ------------------------- finish -------------------------------
    -- set OUT value
    x_Approval_Rules_id := l_Approval_Rules_rec.APPROVAL_RULE_ID;

    --
    -- END of API body.
    --
    -- Standard check of p_commit.
   IF Fnd_Api.To_Boolean ( p_commit ) THEN
      COMMIT WORK;
   END IF;
   Fnd_Msg_Pub.count_and_get(
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;

EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Create_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get(
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Create_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Create_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
        THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Create_Approval_Rules;

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Approval_Rules
--
--------------------------------------------------------------------
PROCEDURE Update_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,
   p_Approval_Rules_rec   IN  Approval_Rules_Rec_Type
)
IS
   L_API_VERSION          CONSTANT NUMBER := 1.0;
   L_API_NAME             CONSTANT VARCHAR2(30) := 'Update_Approval_Rules';
   L_FULL_NAME            CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_Approval_Rules_rec   Approval_Rules_Rec_Type := p_Approval_Rules_rec;
   l_dummy                NUMBER;
   l_return_status        VARCHAR2(1);
   l_seed                 VARCHAR2(1);
   l_status               VARCHAR2(30);
   l_operating_unit       NUMBER;
      CURSOR c_operating IS
      SELECT ORGANIZATION_ID
      FROM HR_OPERATING_UNITS
      WHERE NAME = l_Approval_Rules_rec.OPERATING_NAME;

      CURSOR CUR_STATUS IS
      SELECT Status_code
      FROM Ahl_approval_rules_b
      WHERE Approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

      CURSOR CUR_SEED IS
      SELECT Seeded_Flag
      FROM Ahl_approval_rules_b
      WHERE Approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

      CURSOR c_appl_usg IS
      SELECT LOOKUP_CODE
      FROM FND_LOOKUPS
      WHERE MEANING = l_Approval_Rules_rec.APPLICATION_USG
      AND LOOKUP_TYPE = 'AHL_APPLICATION_USAGE_CODE';

BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Update_Approval_Rules;

 -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call(
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;
   ----------------------- validate ----------------------
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Validate');
    END IF;

    --
    -- To check whether the Operating Name is valid.
    IF l_Approval_Rules_rec.Operating_Unit_Id IS NULL AND l_Approval_Rules_rec.Operating_Name IS NOT NULL THEN
      IF p_validation_level >= G_VALID_NAME THEN
        Check_Operating_Name (
           p_Approval_Rules_rec  => p_Approval_Rules_rec,
           p_complete_rec        => l_Approval_Rules_rec,
           x_return_status       => l_return_status
         );
         IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
            RAISE Fnd_Api.g_exc_unexpected_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
            RAISE Fnd_Api.g_exc_error;
         ELSE
            OPEN  c_operating;
            FETCH c_operating INTO l_operating_unit;
            CLOSE c_operating;
         END IF;
      END IF;
   ELSIF l_Approval_Rules_rec.Operating_Unit_Id IS NOT NULL AND l_Approval_Rules_rec.Operating_Name IS NULL THEN
       l_operating_unit := NULL;
   ELSIF l_Approval_Rules_rec.Operating_Unit_Id IS NOT NULL AND l_Approval_Rules_rec.Operating_Name IS NOT NULL THEN
      OPEN  c_operating;
      FETCH c_operating INTO l_operating_unit;
      CLOSE c_operating;
   ELSE
       l_operating_unit := NULL;
   END IF;



   -- replace g_miss_char/num/date with current column values
   Complete_Approval_Rules_Rec (p_Approval_Rules_rec, l_Approval_Rules_rec);
 -- Reema:
  -- Check whether the Application Usage Code is valid
 /*
  IF p_Approval_Rules_rec.application_usg IS NOT NULL AND p_validation_level >= G_VALID_NAME THEN
        Check_Appl_Usg_Code (
           p_Approval_Rules_rec  => p_Approval_Rules_rec,
           x_return_status       => l_return_status
         );
         IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
            RAISE Fnd_Api.g_exc_unexpected_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
            RAISE Fnd_Api.g_exc_error;
         ELSE
            OPEN  c_appl_usg;
            FETCH c_appl_usg INTO l_Approval_Rules_rec.Application_Usg_Code;
         IF c_appl_usg%NOTFOUND THEN
        IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_APPUSG_INVALID');
                Fnd_Msg_Pub.ADD;
                END IF;
            RAISE Fnd_Api.g_exc_unexpected_error;
             END IF;
         END IF;
END IF;*/
   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item THEN
      Check_Approval_Rules_Items (
         p_Approval_Rules_rec => p_Approval_Rules_rec,
         p_validation_mode    => Jtf_Plsql_Api.g_update,
         x_return_status      => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_record THEN
      Check_Approval_Rules_Record (
         p_Approval_Rules_rec  => p_Approval_Rules_rec,
         p_complete_rec        => l_Approval_Rules_rec,
         x_return_status       => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   IF p_validation_level >= G_VALID_QUALIFIER THEN
      Check_Active_for_Qualifier (
         p_Approval_Rules_rec  => p_Approval_Rules_rec,
         p_complete_rec        => l_Approval_Rules_rec,
         x_return_status       => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   --
   -- Status updated to 'ACTIVE' only if at least one Approver defined for the Approval Rule
   IF p_validation_level >= G_VALID_APPROVER THEN
      Check_Approver_for_Rule (
         p_Approval_Rules_rec  => p_Approval_Rules_rec,
         p_complete_rec        => l_Approval_Rules_rec,
         x_return_status       => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   --
   -- Checking the combinations of status updated  if matches.
       OPEN CUR_STATUS;
       FETCH CUR_STATUS INTO l_status;
       CLOSE CUR_STATUS;

    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':before status order Update');
    END IF;

   IF UPPER(l_status) <> UPPER(p_Approval_Rules_rec.status_code) THEN

       Ahl_Utility_Pvt.check_status_order_change (
       'AHL_APPR_STATUS_TYPE',
       l_status,
       p_Approval_Rules_rec.status_code,
       l_return_status
       );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

  --
  --
/*   IF p_validation_level >= G_MATCH_STATUS THEN

       Check_Match_for_Status (
         p_Approval_Rules_rec  => p_Approval_Rules_rec,
         p_complete_rec        => l_Approval_Rules_rec,
         x_return_status       => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF; */

   --
   -- retrieve value of seeded flag from cursor.
       OPEN CUR_SEED;
       FETCH CUR_SEED INTO l_seed;
       CLOSE CUR_SEED;

 -------------------------- update --------------------
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Update');
    END IF;

    Ahl_Approval_Rules_Pkg.UPDATE_ROW (
     X_APPROVAL_RULE_ID      => l_Approval_Rules_rec.APPROVAL_RULE_ID,
     X_OBJECT_VERSION_NUMBER => l_Approval_Rules_rec.OBJECT_VERSION_NUMBER + 1,
     X_APPROVAL_OBJECT_CODE  => l_Approval_Rules_rec.APPROVAL_OBJECT_CODE,
     X_APPROVAL_PRIORITY_CODE=> l_Approval_Rules_rec.APPROVAL_PRIORITY_CODE,
     X_APPROVAL_TYPE_CODE    => l_Approval_Rules_rec.APPROVAL_TYPE_CODE,
     X_APPLICATION_USG_CODE  => l_Approval_Rules_Rec.APPLICATION_USG_CODE,
     X_OPERATING_UNIT_ID     => l_operating_unit,
     X_ACTIVE_START_DATE     => l_Approval_Rules_rec.ACTIVE_START_DATE,
     X_ACTIVE_END_DATE       => l_Approval_Rules_rec.ACTIVE_END_DATE,
     X_STATUS_CODE           => l_Approval_Rules_rec.STATUS_CODE,
     X_SEEDED_FLAG           => l_seed,
     X_ATTRIBUTE_CATEGORY    => l_Approval_Rules_rec.ATTRIBUTE_CATEGORY,
     X_ATTRIBUTE1            => l_Approval_Rules_rec.ATTRIBUTE1,
     X_ATTRIBUTE2            => l_Approval_Rules_rec.ATTRIBUTE2,
     X_ATTRIBUTE3            => l_Approval_Rules_rec.ATTRIBUTE3,
     X_ATTRIBUTE4            => l_Approval_Rules_rec.ATTRIBUTE4,
     X_ATTRIBUTE5            => l_Approval_Rules_rec.ATTRIBUTE5,
     X_ATTRIBUTE6            => l_Approval_Rules_rec.ATTRIBUTE6,
     X_ATTRIBUTE7            => l_Approval_Rules_rec.ATTRIBUTE7,
     X_ATTRIBUTE8            => l_Approval_Rules_rec.ATTRIBUTE8,
     X_ATTRIBUTE9            => l_Approval_Rules_rec.ATTRIBUTE9,
     X_ATTRIBUTE10           => l_Approval_Rules_rec.ATTRIBUTE10,
     X_ATTRIBUTE11           => l_Approval_Rules_rec.ATTRIBUTE11,
     X_ATTRIBUTE12           => l_Approval_Rules_rec.ATTRIBUTE12,
     X_ATTRIBUTE13           => l_Approval_Rules_rec.ATTRIBUTE13,
     X_ATTRIBUTE14           => l_Approval_Rules_rec.ATTRIBUTE14,
     X_ATTRIBUTE15           => l_Approval_Rules_rec.ATTRIBUTE15,
     X_APPROVAL_RULE_NAME    => l_Approval_Rules_rec.APPROVAL_RULE_NAME,
     X_DESCRIPTION           => l_Approval_Rules_rec.DESCRIPTION,
     X_LAST_UPDATE_DATE      => SYSDATE,
     X_LAST_UPDATED_BY       => Fnd_Global.USER_ID,
     X_LAST_UPDATE_LOGIN     => Fnd_Global.LOGIN_ID,
     --Added by aschakka for Bug#30235037, Start
     X_PROGRAM_TYPE_CODE     => l_Approval_Rules_rec.program_type_code,
     X_PROGRAM_SUBTYPE_CODE  => l_Approval_Rules_rec.program_subtype_code,
     X_REVISION_TYPE_CODE    => l_Approval_Rules_rec.revision_type_code
     --Added by aschakka for Bug#30235037, End
     );

   -------------------- finish --------------------------
   IF Fnd_Api.to_boolean (p_commit) THEN
      COMMIT;
   END IF;
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );

    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;

-- Check if API is called in debug mode. If yes, disable debug.
    IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
                END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Update_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Update_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO update_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
        THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Update_Approval_Rules;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Approver_for_Rule
-- Status updated to 'ACTIVE' only if at least one Approver defined for the Approval Rule
--------------------------------------------------------------------

PROCEDURE Check_Approver_for_Rule (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
)
IS
    l_count   NUMBER;
    l_status  VARCHAR2(30);

    CURSOR check_approver1 IS
    SELECT 1 FROM ahl_approvers
    WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

    CURSOR chk_STATUS IS
    SELECT status_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id;
BEGIN
    x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
      OPEN chk_STATUS;
      FETCH chk_STATUS INTO l_status;
      CLOSE chk_STATUS;
    IF UPPER(l_status) <> UPPER(p_Approval_Rules_rec.status_code) THEN
       IF UPPER(p_Approval_Rules_rec.STATUS_CODE) = 'ACTIVE' THEN
            /*IF p_Approval_Rules_rec.approval_priority_code IS NOT NULL AND p_Approval_Rules_rec.operating_unit_id IS NOT NULL THEN*/
           OPEN check_approver1;
           FETCH check_approver1 INTO l_count;

          IF check_approver1%NOTFOUND THEN
             CLOSE check_approver1;
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_STATUS_NOT_TO_ACTIVE');
                Fnd_Msg_Pub.ADD;
            END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          ELSE
            CLOSE check_approver1;
          END IF;
       /*ELSIF p_Approval_Rules_rec.approval_priority_code IS NULL AND p_Approval_Rules_rec.operating_unit_id IS NOT NULL THEN
          Open check_approver2;
           Fetch check_approver2 into l_count;
          IF check_approver2%notfound THEN
            Close check_approver1;
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_STATUS_NOT_TO_ACTIVE');
                Fnd_Msg_Pub.ADD;
            END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          ELSE
            Close check_approver2;
          END IF;
       ELSIF p_Approval_Rules_rec.approval_priority_code IS NOT NULL AND p_Approval_Rules_rec.operating_unit_id IS NULL THEN
           Open check_approver3;
           Fetch check_approver3 into l_count;
          IF check_approver3%notfound THEN
            Close check_approver3;
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_STATUS_NOT_TO_ACTIVE');
                Fnd_Msg_Pub.ADD;
            END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          ELSE
            Close check_approver3;
          END IF;
       ELSE
          Open check_approver4;
           Fetch check_approver4 into l_count;
          IF check_approver4%notfound THEN
            Close check_approver4;
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_STATUS_NOT_TO_ACTIVE');
                Fnd_Msg_Pub.ADD;
            END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          ELSE
            Close check_approver4;
          END IF;
       END IF;*/

    END IF;
  END IF;
END Check_Approver_for_Rule;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Active_for_Qualifier
--  to check whether for a particular approval qualifier
--  among all approvals only one of them is to be active
--  Qualifier comprises of 'Approval Object Code', 'Approval Priority Code', 'Approval Type Code' and 'Operating Unit Id'
--------------------------------------------------------------------

PROCEDURE Check_Active_for_Qualifier (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
)
IS
   /* Commented by aschakka for Bug#30235037, Start
   l_count1                  NUMBER;
   l_count2                  NUMBER;
   l_count3                  NUMBER;
   l_count4                  NUMBER;
   l_count5                  NUMBER;
   Commented by aschakka for Bug#30235037, End */

   --Added by aschakka for Bug#30235037, Start
   L_API_NAME             CONSTANT VARCHAR2(30) := 'Check_Active_for_Qualifier';
   L_FULL_NAME            CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_prog_type                     VARCHAR2(30);
   l_prog_sub_type                 VARCHAR2(30);
   l_rev_type                      VARCHAR2(30);
   l_check_fmpmr_rule_flag         VARCHAR2(1) := 'N';
   l_appr_rule_id                  NUMBER;
   --Added by aschakka for Bug#30235037, End

    CURSOR check_active1 IS
    SELECT approval_rule_id
    FROM ahl_approval_rules_b
    WHERE UPPER(status_code) = 'ACTIVE'
    AND operating_unit_id = (SELECT ORGANIZATION_ID FROM HR_OPERATING_UNITS WHERE NAME = p_Approval_Rules_rec.OPERATING_NAME)
    AND approval_priority_code = p_Approval_Rules_rec.approval_priority_code
    AND application_usg_code = (SELECT application_usg_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_object_code = (SELECT approval_object_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_type_code = (SELECT approval_type_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_rule_id <> p_Approval_Rules_rec.approval_rule_id
    --Added by aschakka for Bug#30235037, Start
    AND(
       approval_object_code <> 'FMPMR'
       OR(
         approval_object_code = 'FMPMR'
         AND NVL(program_type_code,'X') = NVL(p_Approval_Rules_rec.program_type_code,'X')
         AND NVL(program_subtype_code,'X') = NVL(p_Approval_Rules_rec.program_subtype_code,'X')
         AND NVL(revision_type_code,'X') = NVL(p_Approval_Rules_rec.revision_type_code,'X')
         )
       );
    --Added by aschakka for Bug#30235037, End

    CURSOR check_active2 IS
    SELECT approval_rule_id
    FROM ahl_approval_rules_b
    WHERE UPPER(status_code) = 'ACTIVE'
    AND operating_unit_id = (SELECT ORGANIZATION_ID FROM HR_OPERATING_UNITS WHERE NAME = p_Approval_Rules_rec.OPERATING_NAME)
    AND approval_priority_code IS NULL
    AND application_usg_code = (SELECT application_usg_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_object_code = (SELECT approval_object_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_type_code IS NULL
    AND approval_rule_id <> p_Approval_Rules_rec.approval_rule_id
    --Added by aschakka for Bug#30235037, Start
    AND(
       approval_object_code <> 'FMPMR'
       OR(
         approval_object_code = 'FMPMR'
         AND NVL(program_type_code,'X') = NVL(p_Approval_Rules_rec.program_type_code,'X')
         AND NVL(program_subtype_code,'X') = NVL(p_Approval_Rules_rec.program_subtype_code,'X')
         AND NVL(revision_type_code,'X') = NVL(p_Approval_Rules_rec.revision_type_code,'X')
         )
       );
    --Added by aschakka for Bug#30235037, End

    CURSOR check_active3 IS
    SELECT approval_rule_id
    FROM ahl_approval_rules_b
    WHERE UPPER(status_code) = 'ACTIVE'
    AND operating_unit_id IS NULL
    AND approval_priority_code = p_Approval_Rules_rec.approval_priority_code
    AND application_usg_code = (SELECT application_usg_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_object_code = (SELECT approval_object_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_type_code = (SELECT approval_type_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_rule_id <> p_Approval_Rules_rec.approval_rule_id
    --Added by aschakka for Bug#30235037, Start
    AND(
       approval_object_code <> 'FMPMR'
       OR(
         approval_object_code = 'FMPMR'
         AND NVL(program_type_code,'X') = NVL(p_Approval_Rules_rec.program_type_code,'X')
         AND NVL(program_subtype_code,'X') = NVL(p_Approval_Rules_rec.program_subtype_code,'X')
         AND NVL(revision_type_code,'X') = NVL(p_Approval_Rules_rec.revision_type_code,'X')
         )
       );
    --Added by aschakka for Bug#30235037, End

    CURSOR check_active4 IS
    SELECT approval_rule_id
    FROM ahl_approval_rules_b
    WHERE UPPER(status_code) = 'ACTIVE'
    AND operating_unit_id IS NULL
    AND approval_priority_code IS NULL
    AND application_usg_code =(SELECT application_usg_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_object_code = (SELECT approval_object_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_type_code = (SELECT approval_type_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_rule_id <> p_Approval_Rules_rec.approval_rule_id
    --Added by aschakka for Bug#30235037, Start
    AND(
       approval_object_code <> 'FMPMR'
       OR(
         approval_object_code = 'FMPMR'
         AND NVL(program_type_code,'X') = NVL(p_Approval_Rules_rec.program_type_code,'X')
         AND NVL(program_subtype_code,'X') = NVL(p_Approval_Rules_rec.program_subtype_code,'X')
         AND NVL(revision_type_code,'X') = NVL(p_Approval_Rules_rec.revision_type_code,'X')
         )
       );
    --Added by aschakka for Bug#30235037, End

    CURSOR check_active5 IS
    SELECT approval_rule_id
    FROM ahl_approval_rules_b
    WHERE UPPER(status_code) = 'ACTIVE'
    AND operating_unit_id IS NULL
    AND application_usg_code =  (SELECT application_usg_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_object_code = (SELECT approval_object_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id)
    AND approval_rule_id <> p_Approval_Rules_rec.approval_rule_id
    --Added by aschakka for Bug#30235037, Start
    AND(
       approval_object_code <> 'FMPMR'
       OR(
         approval_object_code = 'FMPMR'
         AND NVL(program_type_code,'X') = NVL(p_Approval_Rules_rec.program_type_code,'X')
         AND NVL(program_subtype_code,'X') = NVL(p_Approval_Rules_rec.program_subtype_code,'X')
         AND NVL(revision_type_code,'X') = NVL(p_Approval_Rules_rec.revision_type_code,'X')
         )
       );
    CURSOR approval_rule_dtls IS
    SELECT
    (select meaning from fnd_lookup_values_vl where lookup_type = 'AHL_FMP_MR_PROGRAM_TYPE' and lookup_code = program_type_code) program_type,
    (select meaning from fnd_lookup_values_vl where lookup_type = 'AHL_FMP_MR_PROGRAM_SUBTYPE' AND lookup_code = program_subtype_code)program_subtype,
    (select meaning from fnd_lookup_values_vl where lookup_type = 'AHL_FMP_REVISION_TYPE' and lookup_code = revision_type_code)revision_type
    FROM ahl_approval_rules_b
    WHERE approval_rule_id = l_appr_rule_id;
    --Added by aschakka for Bug#30235037, End
BEGIN
    x_return_status := Fnd_Api.G_RET_STS_SUCCESS;

    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Check_Active_for_Qualifier');
    END IF;

 IF p_Approval_Rules_rec.STATUS_CODE='ACTIVE' THEN

    IF p_Approval_Rules_rec.approval_priority_code IS NOT NULL AND p_Approval_Rules_rec.OPERATING_NAME IS NOT NULL THEN
       OPEN check_active1;
       --Added by aschakka for Bug#30235037 to fetch Program Type, Program Subtype and Revision Type
       --FETCH check_active1 INTO l_count1;
       FETCH check_active1 INTO l_appr_rule_id;
       IF check_active1%FOUND THEN
         CLOSE check_active1;
         IF p_Approval_Rules_rec.approval_object_code <> 'FMPMR' THEN
           IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
              Fnd_Msg_Pub.ADD;
           END IF;
           RETURN;
         ELSE
            l_check_fmpmr_rule_flag := 'Y';
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
       ELSE
         CLOSE check_active1;
       END IF;
    ELSIF p_Approval_Rules_rec.approval_priority_code IS NULL AND p_Approval_Rules_rec.OPERATING_NAME IS NOT NULL THEN
       OPEN check_active2;
       --Added by aschakka for Bug#30235037 to fetch Program Type, Program Subtype and Revision Type
       --FETCH check_active2 INTO l_count2;
       FETCH check_active2 INTO l_appr_rule_id;
       IF check_active2%FOUND THEN
         CLOSE check_active2;
         --Added by aschakka for Bug#30235037, Start
         IF p_Approval_Rules_rec.approval_object_code <> 'FMPMR' THEN
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
               Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
               Fnd_Msg_Pub.ADD;
            END IF;
         RETURN;
         ELSE
           l_check_fmpmr_rule_flag := 'Y';
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
       ELSE
         CLOSE check_active2;
       END IF;
    ELSIF p_Approval_Rules_rec.approval_priority_code IS NOT NULL AND p_Approval_Rules_rec.OPERATING_NAME IS NULL THEN
       OPEN check_active3;
       --Added by aschakka for Bug#30235037 to fetch Program Type, Program Subtype and Revision Type
       --FETCH check_active3 INTO l_count3;
       FETCH check_active3 INTO l_appr_rule_id;
       IF check_active3%FOUND THEN
        CLOSE check_active3;
        IF p_Approval_Rules_rec.approval_object_code <> 'FMPMR' THEN
           IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
              Fnd_Msg_Pub.ADD;
           END IF;
           RETURN;
        ELSE
           l_check_fmpmr_rule_flag := 'Y';
        END IF;
        x_return_status := Fnd_Api.g_ret_sts_error;
       ELSE
         CLOSE check_active3;
       END IF;
    ELSIF p_Approval_Rules_rec.approval_priority_code IS NULL AND p_Approval_Rules_rec.OPERATING_NAME IS NULL  AND p_Approval_Rules_rec.APPROVAL_TYPE_CODE IS NOT NULL THEN
       OPEN check_active4;
       --Added by aschakka for Bug#30235037 to fetch Program Type, Program Subtype and Revision Type
       --FETCH check_active4 INTO l_count4;
       FETCH check_active4 INTO l_appr_rule_id;
       IF check_active4%FOUND THEN
          CLOSE check_active4;
          IF p_Approval_Rules_rec.approval_object_code <> 'FMPMR' THEN
             IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
                Fnd_Msg_Pub.ADD;
             END IF;
             RETURN;
          ELSE
             l_check_fmpmr_rule_flag := 'Y';
          END IF;
          x_return_status := Fnd_Api.g_ret_sts_error;
       ELSE
          CLOSE check_active4;
       END IF;
    ELSIF p_Approval_Rules_rec.approval_priority_code IS NULL AND p_Approval_Rules_rec.OPERATING_NAME IS NULL  AND p_Approval_Rules_rec.APPROVAL_TYPE_CODE IS NULL THEN
       OPEN check_active5;
       --Added by aschakka for Bug#30235037 to fetch Program Type, Program Subtype and Revision Type
       --FETCH check_active5 INTO l_count5;
       FETCH check_active5 INTO l_appr_rule_id;
       IF check_active5%FOUND THEN
         CLOSE check_active5;
         IF p_Approval_Rules_rec.approval_object_code <> 'FMPMR' THEN
           IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
             Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
             Fnd_Msg_Pub.ADD;
           END IF;
           RETURN;
         ELSE
           l_check_fmpmr_rule_flag := 'Y';
         END IF;
           x_return_status := Fnd_Api.g_ret_sts_error;
        ELSE
           CLOSE check_active5;
        END IF;
    END IF;
 END IF;

 IF G_DEBUG='Y' THEN
     Ahl_Debug_Pub.debug( l_full_name ||':l_check_fmpmr_rule_flag: '||l_check_fmpmr_rule_flag);
 END IF;

 IF l_check_fmpmr_rule_flag = 'Y' THEN

    OPEN approval_rule_dtls;
    FETCH approval_rule_dtls INTO l_prog_type, l_prog_sub_type, l_rev_type;
    CLOSE approval_rule_dtls;

    IF l_prog_type IS NOT NULL AND l_prog_sub_type IS NOT NULL AND l_rev_type IS NOT NULL THEN
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_MR_PPSR_RULE_ACTIVE');
          fnd_message.set_token('PROGTYPE',l_prog_type, false);
          fnd_message.set_token('PROGSUBTYPE',l_prog_sub_type, false);
          fnd_message.set_token('REVTYPE',l_rev_type, false);
          Fnd_Msg_Pub.ADD;
       END IF;
    ELSIF l_prog_type IS NOT NULL AND l_prog_sub_type IS NOT NULL AND l_rev_type IS NULL THEN
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_MR_PPS_RULE_ACTIVE');
          fnd_message.set_token('PROGTYPE',l_prog_type, false);
          fnd_message.set_token('PROGSUBTYPE',l_prog_sub_type, false);
          Fnd_Msg_Pub.ADD;
       END IF;
    ELSIF l_prog_type IS NOT NULL AND l_prog_sub_type IS NULL AND l_rev_type IS NOT NULL THEN
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_MR_PR_RULE_ACTIVE');
          fnd_message.set_token('PROGTYPE',l_prog_type, false);
          fnd_message.set_token('REVTYPE',l_rev_type, false);
          Fnd_Msg_Pub.ADD;
       END IF;
    ELSIF l_prog_type IS NOT NULL AND l_prog_sub_type IS NULL AND l_rev_type IS NULL THEN
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_MR_PROG_RULE_ACTIVE');
          fnd_message.set_token('PROGTYPE',l_prog_type, false);
          Fnd_Msg_Pub.ADD;
       END IF;
    ELSIF l_prog_type IS NULL AND l_prog_sub_type IS NULL AND l_rev_type IS NOT NULL THEN
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_MR_REV_RULE_ACTIVE');
          fnd_message.set_token('REVTYPE',l_rev_type, false);
          Fnd_Msg_Pub.ADD;
       END IF;
    ELSE
       IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
       Fnd_Message.set_name ('AHL', 'AHL_APPR_QUALIFIER_ACTIVE');
       Fnd_Msg_Pub.ADD;
       END IF;
    END IF;
 END IF;
END Check_Active_for_Qualifier;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Operating_Name
-- To check whether the Operating Name is valid.
--------------------------------------------------------------------

PROCEDURE Check_Operating_Name(
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
)
IS
    l_count   NUMBER;
    CURSOR chk_op_name IS
    SELECT 1 FROM HR_OPERATING_UNITS
    WHERE name = p_Approval_Rules_rec.operating_name;
BEGIN

      OPEN chk_op_name;
      FETCH chk_op_name INTO l_count;
      IF chk_op_name%NOTFOUND THEN
          CLOSE chk_op_name;
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_NO_OPERATING_NAME');
          Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
      ELSE
          CLOSE chk_op_name ;
      END IF;
END Check_Operating_Name;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Appl_Usg_Code
-- To check whether the Application Usage Code is valid.
--------------------------------------------------------------------

PROCEDURE Check_Appl_Usg_Code(
    p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
    x_return_status      OUT NOCOPY VARCHAR2
)
IS
 l_count   NUMBER;

 CURSOR chk_appl_usg_code IS
    SELECT 1 FROM FND_LOOKUPS
    WHERE meaning = p_Approval_Rules_rec.Application_Usg
    AND LOOKUP_TYPE = 'AHL_APPLICATION_USAGE_CODE';
BEGIN
      OPEN chk_appl_usg_code;
      FETCH chk_appl_usg_code INTO l_count;
    IF chk_appl_usg_code%NOTFOUND THEN
          CLOSE chk_appl_usg_code;
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
          Fnd_Message.set_name ('AHL', 'AHL_APPR_APPUSG_INVALID');
          Fnd_Msg_Pub.ADD;
          END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
      ELSE
          CLOSE chk_appl_usg_code;
      END IF;
END Check_Appl_Usg_Code;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Match_for_Status
-- Status match from Ahl_Status_Order_Rules for the Approval Rule
--------------------------------------------------------------------

PROCEDURE Check_Match_for_Status (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type,
   x_return_status      OUT NOCOPY VARCHAR2
)
IS
   l_count   NUMBER;
   l_status  VARCHAR2(30);

    CURSOR check_status IS
    SELECT 1 FROM ahl_approval_rules_b t1, ahl_status_order_rules t2
    WHERE t1.approval_rule_id = p_Approval_Rules_rec.approval_rule_id
    AND t2.next_status_code = p_Approval_Rules_rec.status_code
    AND t2.current_status_code = (SELECT status_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id);

    CURSOR CUR_STATUS IS
    SELECT status_code FROM ahl_approval_rules_b WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

BEGIN
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
      OPEN CUR_STATUS;
      FETCH CUR_STATUS INTO l_status;
      CLOSE CUR_STATUS;
           IF l_status <> p_Approval_Rules_rec.status_code THEN
                OPEN check_status;
                FETCH check_status INTO l_count;
              IF check_status%NOTFOUND THEN
                  CLOSE check_status;
                  IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                      Fnd_Message.set_name ('AHL', 'AHL_APPR_INVALID_STATUS');
                      Fnd_Msg_Pub.ADD;
                  END IF;
                 x_return_status := Fnd_Api.g_ret_sts_error;
                 RETURN;
              ELSE
                 CLOSE check_status;
              END IF;
          END IF;
END Check_Match_for_Status;

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Approval_Rules
--
--------------------------------------------------------------------

PROCEDURE Delete_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,
   p_Approval_Rule_id  IN  NUMBER,
   p_object_version    IN  NUMBER
)


IS
   CURSOR c_Approval_Rules IS
      SELECT   *
      FROM     Ahl_Approval_Rules_VL
      WHERE    Approval_Rule_id = p_Approval_Rule_id;
   --
   -- This is the only exception for using %ROWTYPE.
   -- We are selecting from the VL view, which may
   -- have some denormalized columns as compared to
   -- the base tables.
   l_Approval_Rules_rec    c_Approval_Rules%ROWTYPE;
   l_api_version CONSTANT NUMBER       := 1.0;
   l_api_name    CONSTANT VARCHAR2(30) := 'Delete_Approval_Rules';
   l_full_name   CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || l_Api_name;
BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Delete_Approval_Rules;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;

   ------------------------ delete ------------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Delete');
   END IF;

   OPEN c_Approval_Rules;
   FETCH c_Approval_Rules INTO l_Approval_Rules_rec;
   IF c_Approval_Rules%NOTFOUND THEN
      CLOSE c_Approval_Rules;
      IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
   END IF;
   CLOSE c_Approval_Rules;
   -- Delete TL data

    /*DELETE FROM Ahl_Approval_Rules_tl
    WHERE  Approval_Rule_id = p_Approval_Rule_id;
     IF (SQL%NOTFOUND) THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error)
        THEN
         Fnd_Message.set_name ('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
     END IF;

    DELETE FROM Ahl_Approval_Rules_b
    WHERE  Approval_Rule_id = p_Approval_Rule_id;*/

    UPDATE Ahl_Approval_Rules_B
    SET Status_Code = 'OBSOLETE'
    WHERE  Approval_Rule_id = p_Approval_Rule_id;
     IF (SQL%NOTFOUND) THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error)
        THEN
         Fnd_Message.set_name ('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
     END IF;

   -------------------- finish --------------------------
   IF Fnd_Api.to_boolean (p_commit) THEN
      COMMIT;
   END IF;
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
   END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Delete_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Delete_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Delete_Approval_Rules;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
        THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Delete_Approval_Rules;

--------------------------------------------------------------------
-- PROCEDURE
--   Validate_Approval_Rules
--
--------------------------------------------------------------------
PROCEDURE Validate_Approval_Rules (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,
   p_Approval_Rules_rec   IN  Approval_Rules_Rec_Type
)
IS
   L_API_VERSION CONSTANT NUMBER := 1.0;
   L_API_NAME    CONSTANT VARCHAR2(30) := 'Validate_Approval_Rules';
   L_FULL_NAME   CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_return_status   VARCHAR2(1);
BEGIN
   --------------------- initialize -----------------------
   -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;
   ---------------------- validate ------------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Check items');
    END IF;
   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item THEN
      Check_Approval_Rules_Items (
         p_Approval_Rules_rec => p_Approval_Rules_rec,
         p_validation_mode    => Jtf_Plsql_Api.g_create,
         x_return_status      => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Check record');
    END IF;

   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_record THEN
      Check_Approval_Rules_Record (
         p_Approval_Rules_rec   => p_Approval_Rules_rec,
         p_complete_rec         => NULL,
         x_return_status        => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;
   -------------------- finish --------------------------
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      x_return_status := Fnd_Api.g_ret_sts_unexp_error;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
        THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Validate_Approval_Rules;

---------------------------------------------------------------------
-- PROCEDURE
--    Check_Approval_Rules_Items
--
---------------------------------------------------------------------
PROCEDURE Check_Approval_Rules_Items (
   p_Approval_Rules_rec  IN  Approval_Rules_Rec_Type,
   p_validation_mode     IN  VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status   OUT NOCOPY VARCHAR2
)
IS
BEGIN
   --
   -- Validate required items.
   Check_Approval_Rules_Req_Items (
      p_Approval_Rules_rec => p_Approval_Rules_rec,
      x_return_status   => x_return_status
   );
   IF x_return_status <> Fnd_Api.g_ret_sts_success THEN
      RETURN;
   END IF;

   --
   -- Validate uniqueness.
   Check_Approval_Rules_UK_Items (
      p_Approval_Rules_rec => p_Approval_Rules_rec,
      p_validation_mode    => p_validation_mode,
      x_return_status      => x_return_status
   );
   IF x_return_status <> Fnd_Api.g_ret_sts_success THEN
      RETURN;
   END IF;

END Check_Approval_Rules_Items;
---------------------------------------------------------------------
-- PROCEDURE
--    Check_Approval_Rules_Record
--
-- PURPOSE
--    Check the record level business rules.
--
-- PARAMETERS
--    p_Approval_Rules_rec: the record to be validated; may contain attributes
--       as FND_API.g_miss_char/num/date
--    p_complete_rec: the complete record after all "g_miss" items
--       have been replaced by current database values
---------------------------------------------------------------------
PROCEDURE Check_Approval_Rules_Record (
   p_Approval_Rules_rec IN  Approval_Rules_Rec_Type,
   p_complete_rec       IN  Approval_Rules_Rec_Type := NULL,
   x_return_status      OUT NOCOPY VARCHAR2
)
IS
   l_active_start_date      DATE;
   l_active_end_date        DATE;
BEGIN
   --
   -- Use local vars to reduce amount of typing.
   IF p_complete_rec.active_start_date IS NOT NULL THEN
       l_active_start_date := p_complete_rec.active_start_date;
   ELSE
        IF p_Approval_Rules_rec.active_start_date IS NOT NULL AND
            p_Approval_Rules_rec.active_start_date <> Fnd_Api.g_miss_date THEN
            l_active_start_date := p_Approval_Rules_rec.active_start_date;
        END IF;
   END IF;

    IF p_complete_rec.active_end_date IS NOT NULL THEN
       l_active_end_date := p_complete_rec.active_end_date;
    ELSE
        IF p_Approval_Rules_rec.active_end_date IS NOT NULL AND
            p_Approval_Rules_rec.active_end_date <> Fnd_Api.g_miss_date THEN
            l_active_end_date := p_Approval_Rules_rec.active_end_date;
        END IF;
   END IF;

   x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
   --
   -- Validate the active dates.
        IF l_active_start_date IS NOT NULL AND l_active_end_date IS NOT NULL THEN
          IF l_active_start_date > l_active_end_date THEN
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_FROMDT_GTR_TODT');
                Fnd_Msg_Pub.ADD;
             END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          END IF;

          IF l_active_start_date = l_active_end_date THEN
            IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name ('AHL', 'AHL_APPR_FROMDT_EQU_TODT');
                Fnd_Msg_Pub.ADD;
             END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
          END IF;
        END IF;

END Check_Approval_Rules_Record;


---------------------------------------------------------------------
-- PROCEDURE
--    Init_Approval_Rules_Rec
--
---------------------------------------------------------------------
/*PROCEDURE Init_Approval_Rules_Rec (
   x_Approval_Rules_rec         OUT  NOCOPY Approval_Rules_Rec_Type
)
IS
BEGIN
   x_Approval_Rules_rec.approval_rule_id           := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.object_version_number      := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.approval_object_code       := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.approval_priority_code     := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.approval_type_code         := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.OPERATING_UNIT_ID          := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.active_start_date          := Fnd_Api.g_miss_date;
   x_Approval_Rules_rec.active_end_date            := Fnd_Api.g_miss_date;
   x_Approval_Rules_rec.status_code                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.approval_rule_name         := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.description                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.last_update_date           := Fnd_Api.g_miss_date;
   x_Approval_Rules_rec.last_updated_by            := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.creation_date              := Fnd_Api.g_miss_date;
   x_Approval_Rules_rec.created_by                 := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.last_update_login          := Fnd_Api.g_miss_num;
   x_Approval_Rules_rec.attribute_category         := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute1                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute2                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute3                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute4                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute5                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute6                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute7                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute8                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute9                 := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute10                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute11                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute12                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute13                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute14                := Fnd_Api.g_miss_char;
   x_Approval_Rules_rec.attribute15                := Fnd_Api.g_miss_char;

END Init_Approval_Rules_Rec;
*/
---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Approval_Rules_Rec
--
---------------------------------------------------------------------
PROCEDURE Complete_Approval_Rules_Rec (
   p_Approval_Rules_rec      IN  Approval_Rules_Rec_Type,
   x_complete_rec            OUT NOCOPY Approval_Rules_Rec_Type
)
IS
   CURSOR c_Approval_Rules IS
      SELECT   *
      FROM     Ahl_Approval_Rules_v
      WHERE    Approval_Rule_id = p_Approval_Rules_rec.Approval_Rule_id;
   --
   -- This is the only exception for using %ROWTYPE.
   -- We are selecting from the VL view, which may
   -- have some denormalized columns as compared to
   -- the base tables.
   l_Approval_Rules_rec    c_Approval_Rules%ROWTYPE;
BEGIN
   x_complete_rec := p_Approval_Rules_rec;
   OPEN c_Approval_Rules;
   FETCH c_Approval_Rules INTO l_Approval_Rules_rec;
   IF c_Approval_Rules%NOTFOUND THEN
      CLOSE c_Approval_Rules;
      IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
   END IF;
   CLOSE c_Approval_Rules;
   --
   -- APPROVAL_OBJECT_CODE
   IF p_Approval_Rules_rec.approval_object_code is null or p_Approval_Rules_rec.approval_object_code = Fnd_Api.g_miss_char THEN
      x_complete_rec.approval_object_code := l_Approval_Rules_rec.approval_object_code;
   END IF;

   -- APPLICATION_USG_CODE
   IF p_Approval_Rules_rec.application_usg_code is null or p_Approval_Rules_rec.application_usg_code = Fnd_Api.g_miss_char THEN
      x_complete_rec.application_usg_code := l_Approval_Rules_rec.application_usg_code;
   END IF;
   --
   -- APPROVAL_TYPE_CODE
   IF p_Approval_Rules_rec.approval_type_code is null or p_Approval_Rules_rec.approval_type_code = Fnd_Api.g_miss_char THEN
      x_complete_rec.approval_type_code := l_Approval_Rules_rec.approval_type_code;
   END IF;

   --
   -- STATUS_CODE
   IF p_Approval_Rules_rec.status_code is null or p_Approval_Rules_rec.status_code = Fnd_Api.g_miss_char THEN
      x_complete_rec.status_code := l_Approval_Rules_rec.status_code;
   END IF;

   --
   -- ACTIVE_START_DATE
   IF p_Approval_Rules_rec.active_start_date is null or p_Approval_Rules_rec.active_start_date = Fnd_Api.g_miss_date THEN
      x_complete_rec.active_start_date := l_Approval_Rules_rec.active_start_date;
   END IF;

   --
   -- APPROVAL_NAME
   IF p_Approval_Rules_rec.approval_rule_name is null or p_Approval_Rules_rec.approval_rule_name = Fnd_Api.g_miss_char THEN
      x_complete_rec.approval_rule_name := l_Approval_Rules_rec.approval_rule_name;
   END IF;

END Complete_Approval_Rules_Rec;

---------------------------------------------------------
--  Function Compare Columns
-- this procedure will compare that no values have been modified for seeded statuses
-----------------------------------------------------------------
FUNCTION compare_columns(
    l_Approval_Rules_rec    IN    Approval_Rules_Rec_Type
)
RETURN VARCHAR2
IS
  l_count NUMBER := 0;

BEGIN
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( 'START DATE:'||TO_CHAR(l_Approval_Rules_rec.active_start_date,'DD_MON_YYYY'));
       Ahl_Debug_Pub.debug( 'END DATE:'||TO_CHAR(l_Approval_Rules_rec.active_end_date,'DD_MON_YYYY'));
    END IF;

    IF l_Approval_Rules_rec.active_start_date IS NOT NULL THEN
        IF l_Approval_Rules_rec.active_end_Date IS NOT NULL THEN

              BEGIN
                SELECT 1 INTO l_count
                FROM Ahl_Approval_Rules_vl
                WHERE Approval_Rule_id = l_Approval_Rules_rec.Approval_Rule_id
                AND   approval_rule_name = l_Approval_Rules_rec.approval_rule_name
                AND   active_start_date = l_Approval_Rules_rec.active_start_date
                AND   active_end_date = l_Approval_Rules_rec.active_end_Date
                AND   status_code = l_Approval_Rules_rec.status_code;
              EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        l_count := 0;
              END;
        ELSE -- for end date
              BEGIN
                SELECT 1 INTO l_count
                FROM Ahl_Approval_Rules_vl
                WHERE Approval_Rule_id = l_Approval_Rules_rec.Approval_Rule_id
                AND   approval_rule_name = l_Approval_Rules_rec.approval_rule_name
                AND   active_start_date = l_Approval_Rules_rec.active_start_date
                AND   status_code = l_Approval_Rules_rec.status_code;
              EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        l_count := 0;
              END;
        END IF; -- for end date
    ELSE
              BEGIN
                SELECT 1 INTO l_count
                FROM Ahl_Approval_Rules_vl
                WHERE Approval_Rule_id = l_Approval_Rules_rec.Approval_Rule_id
                AND   approval_rule_name = l_Approval_Rules_rec.approval_rule_name
                AND   status_code = l_Approval_Rules_rec.status_code;
              EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        l_count := 0;
              END;
    END IF;

   IF l_count = 0 THEN
      RETURN Fnd_Api.g_false;
   ELSE
      RETURN Fnd_Api.g_true;
   END IF;
END compare_columns;

--       Check_Approval_Rules_Req_Items
PROCEDURE Check_Approval_Rules_Req_Items (
   p_Approval_Rules_rec       IN    Approval_Rules_Rec_Type,
   x_return_status   OUT NOCOPY   VARCHAR2
)
IS
BEGIN
   -- APPROVAL RULE NAME
   IF p_Approval_Rules_rec.Approval_Rule_Name IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_RULE_NAME_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

   IF p_Approval_Rules_rec.Approval_Rule_Id is null OR p_Approval_Rules_rec.Approval_Rule_Id = Fnd_Api.g_miss_num THEN

   -- APPROVAL OBJECT CODE
   IF p_Approval_Rules_rec.Approval_object_code IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_OBJECT_CODE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

   -- APPLICATION USAGE
   IF p_Approval_Rules_rec.application_usg_code IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_APPUSG_ISNULL');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

   -- TYPE CODE
   /*IF p_Approval_Rules_rec.approval_type_code IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_CODE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;
   */

   END IF;

   -- START DATE
   IF p_Approval_Rules_rec.active_start_date IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_ST_DATE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

   /*-- PROIRITY CODE
   IF p_Approval_Rules_rec.approval_priority_code IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_PROIRITY_CODE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;*/

  /* -- OPERATING UNIT CODE
   IF p_Approval_Rules_rec.OPERATING_UNIT_ID IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_OP_UNIT_CODE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF; */

END Check_Approval_Rules_Req_Items;


--       Check_Approval_Rules_UK_Items
PROCEDURE Check_Approval_Rules_UK_Items (
   p_Approval_Rules_rec       IN    Approval_Rules_Rec_Type,
   p_validation_mode IN    VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status   OUT NOCOPY   VARCHAR2
)
IS
   l_valid_flag   VARCHAR2(1);
   l_approval_priority_code VARCHAR2(30);
   l_operating_unit_id NUMBER;
   l_application_usg_code VARCHAR2(30);
   l_operating         NUMBER;
   l_object VARCHAR2(30);
   l_type   VARCHAR2(30);

    CURSOR c_operating IS
    SELECT ORGANIZATION_ID FROM HR_OPERATING_UNITS
    WHERE NAME = p_Approval_Rules_rec.OPERATING_NAME;

    CURSOR c_object IS
    SELECT approval_object_code FROM ahl_approval_rules_b
    WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

    CURSOR c_type IS
    SELECT approval_type_code FROM ahl_approval_rules_b
    WHERE approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

   CURSOR c_appl_usg IS
    SELECT application_usg_code
    FROM ahl_approval_rules_b
    WHERE  approval_rule_id = p_Approval_Rules_rec.approval_rule_id;

BEGIN
   x_return_status := Fnd_Api.g_ret_sts_success;
   --
   -- For Create_Approval_Rules, when ID is passed in, we need to
   -- check if this ID is unique.
   IF p_validation_mode = Jtf_Plsql_Api.g_create
      AND p_Approval_Rules_rec.Approval_Rule_id IS NOT NULL
   THEN
      IF Ahl_Utility_Pvt.check_uniqueness(
              'Ahl_Approval_Rules_v',
                'Approval_Rule_Id = ' || p_Approval_Rules_rec.Approval_Rule_id
            ) = Fnd_Api.g_false
        THEN
         IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
            Fnd_Message.set_name ('AHL', 'AHL_APPR_DUPLICATE_ID');
            Fnd_Msg_Pub.ADD;
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
         RETURN;
      END IF;
   END IF;

   -- check if NAME is UNIQUE
   IF p_validation_mode = Jtf_Plsql_Api.g_create THEN
      l_valid_flag := Ahl_Utility_Pvt.Check_Uniqueness (
         'Ahl_Approval_Rules_v',
         'approval_rule_name = ''' || p_Approval_Rules_rec.approval_rule_name || ''''
          -- ''' AND language = ''' || p_Approval_Rules_rec.language || ''''
      );
   ELSE
      l_valid_flag := Ahl_Utility_Pvt.Check_Uniqueness (
         'Ahl_Approval_Rules_v',
         'approval_rule_name = ''' || p_Approval_Rules_rec.approval_rule_name ||
       --  ''' AND language = ''' || p_Approval_Rules_rec.language ||
         ''' AND approval_rule_id <> ' || p_Approval_Rules_rec.approval_rule_id
      );
   END IF;

   IF l_valid_flag = Fnd_Api.g_false THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_DUPLICATE_NAME');
         Fnd_Msg_Pub.ADD;
      END IF;
        x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

   -- Check if Approval_object_code, Approval_proirity_code, Operating_unit_id, Approval_type_code  make the UNIQUE KEY combination

     l_approval_priority_code := p_Approval_Rules_rec.approval_priority_code;

   /* To retrieve approvals operating unit id from operating unit name ---*/
   OPEN c_operating;
   FETCH c_operating INTO l_operating;
   IF c_operating%FOUND THEN
     CLOSE c_operating;
     l_operating_unit_id := l_operating;
   ELSE
     CLOSE c_operating;
     l_operating_unit_id := NULL;
   END IF;

   -- Reema:
   -- Retrieve the application usage code
   -- from fnd_lookups
  /* OPEN c_appl_usg;
   FETCH c_appl_usg INTO l_application_usg_code;
   IF c_appl_usg%NOTFOUND THEN
     l_application_usg_code := NULL;
   END IF;
   CLOSE c_appl_usg;
   */
   IF p_validation_mode = Jtf_Plsql_Api.g_create THEN
    -- For add approval uniqueness validations
      IF l_approval_priority_code IS NOT NULL AND l_OPERATING_UNIT_ID IS NOT NULL THEN
       l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
         'approval_object_code = ''' || p_Approval_Rules_rec.approval_object_code ||
           ''' AND approval_type_code = '''|| p_Approval_Rules_rec.approval_type_code ||
            ''' AND approval_priority_code = '''|| p_Approval_Rules_rec.approval_priority_code ||
             ''' AND operating_unit_id = ' || l_operating_unit_id ||
        ' AND application_usg_code = ''' || p_Approval_Rules_rec.application_usg_code ||
              ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date || '%''', 'N' );
      ELSIF l_approval_priority_code IS NOT NULL AND l_OPERATING_UNIT_ID IS NULL THEN
         l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_vl',
         'approval_object_code = ''' || p_Approval_Rules_rec.approval_object_code ||
          ''' AND approval_type_code = '''|| p_Approval_Rules_rec.approval_type_code ||
           ''' AND approval_priority_code = ''' || p_Approval_Rules_rec.approval_priority_code ||
        ''' AND application_usg_code = ''' || p_Approval_Rules_rec.application_usg_code ||
                  ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date || '%''', 'I' );
      ELSIF l_approval_priority_code IS NULL AND l_OPERATING_UNIT_ID IS NOT NULL THEN
          l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
         'approval_object_code = ''' || p_Approval_Rules_rec.approval_object_code ||
            ''' AND approval_type_code = '''|| p_Approval_Rules_rec.approval_type_code ||
             ''' AND operating_unit_id = ' || l_operating_unit_id ||
        ' AND application_usg_code = ''' || p_Approval_Rules_rec.application_usg_code ||
                  ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date || '%''', 'C' );
      ELSE
        l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
         'approval_object_code = ''' || p_Approval_Rules_rec.approval_object_code ||
           ''' AND approval_type_code = '''|| p_Approval_Rules_rec.approval_type_code ||
        ''' AND application_usg_code = ''' || p_Approval_Rules_rec.application_usg_code ||
                  ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date || '%''', 'B' );
      END IF;

   ELSE
     -- For edit approval uniqueness validations
      OPEN c_object;
      FETCH c_object INTO l_object;
      CLOSE c_object;

      OPEN c_type;
      FETCH c_type INTO l_type;
      CLOSE c_type;

      OPEN c_appl_usg;
      FETCH c_appl_usg INTO l_application_usg_code;
      CLOSE c_appl_usg;

      IF l_approval_priority_code IS NOT NULL AND l_OPERATING_UNIT_ID IS NOT NULL THEN
        l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
          'approval_object_code = ''' || l_object ||
            ''' AND approval_type_code = '''|| l_type ||
             ''' AND approval_priority_code = '''|| p_Approval_Rules_rec.approval_priority_code ||
              ''' AND operating_unit_id = ' || l_operating_unit_id ||
        ' AND application_usg_code = ''' || l_application_usg_code ||
              ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date ||
              '%'' AND approval_rule_id <> ' || p_Approval_Rules_rec.approval_rule_id, 'N'
         );
      ELSIF l_approval_priority_code IS NOT NULL AND l_OPERATING_UNIT_ID IS NULL THEN
        l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
          'approval_object_code = ''' || l_object ||
            ''' AND approval_type_code = '''|| l_type ||
           ''' AND approval_priority_code = '''|| p_Approval_Rules_rec.approval_priority_code ||
        ''' AND application_usg_code = ''' || l_application_usg_code ||
             ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date ||
              '%'' AND approval_rule_id <> ' || p_Approval_Rules_rec.approval_rule_id, 'I'
         );
      ELSIF l_approval_priority_code IS NULL AND l_OPERATING_UNIT_ID IS NOT NULL THEN
         l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
          'approval_object_code = ''' || l_object ||
          ''' AND approval_type_code = '''|| l_type ||
            ''' AND OPERATING_UNIT_ID = ' || l_operating_unit_id ||
        ' AND application_usg_code = ''' || l_application_usg_code ||
              ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date ||
              '%'' AND approval_rule_id <> ' || p_Approval_Rules_rec.approval_rule_id, 'N'
         );
      ELSE
         l_valid_flag := Check_Rules_Uniqueness (
         'Ahl_Approval_Rules_v',
          'approval_object_code = ''' || l_object ||
          ''' AND approval_type_code = '''|| l_type ||
        ''' AND application_usg_code = ''' || l_application_usg_code ||
             ''' AND active_start_date LIKE  ''%' || p_Approval_Rules_rec.active_start_date ||
                  '%'' AND approval_rule_id <> ' || p_Approval_Rules_rec.approval_rule_id, 'B'
         );
      END IF;
   END IF;
   IF l_valid_flag = Fnd_Api.g_false THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_RULE_NOT_UNIQUE');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

END Check_Approval_Rules_UK_Items;

--------------------------------------------------------------------
-----          Approvers           -----
--------------------------------------------------------------------

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Approvers
--
--------------------------------------------------------------------

PROCEDURE Create_Approvers (
   p_api_version          IN  NUMBER,
   p_init_msg_list        IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit               IN  VARCHAR2,
   p_validation_level     IN  NUMBER    := Fnd_Api.g_valid_level_full,
   x_return_status        OUT NOCOPY VARCHAR2,
   x_msg_count            OUT NOCOPY NUMBER,
   x_msg_data             OUT NOCOPY VARCHAR2,

   p_Approvers_rec        IN  Approvers_Rec_Type,
   x_Approval_Approver_Id  OUT NOCOPY NUMBER
)
IS
   L_API_VERSION        CONSTANT NUMBER := 1.0;
   L_API_NAME           CONSTANT VARCHAR2(30) := 'Create_Approvers';
   L_FULL_NAME          CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_Approvers_rec      Approvers_Rec_Type := p_Approvers_rec;
   l_dummy              NUMBER;
   l_approver_id        NUMBER;
   l_return_status      VARCHAR2(1);
   l_rowid              VARCHAR2(30);
   l_object_version_number NUMBER := 1;

   CURSOR c_seq IS
      SELECT Ahl_Approvers_S.NEXTVAL
      FROM   dual;

   CURSOR c_id_exists (x_id IN NUMBER) IS
      SELECT 1
      FROM   dual
      WHERE EXISTS (SELECT 1
                    FROM   AHL_Approvers
                    WHERE  Approval_Approver_Id = x_id);
BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Create_Approvers;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;

   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         L_API_VERSION,
         p_api_version,
         L_API_NAME,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;
   ----------------------- validate -----------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Validate');
   END IF;

   Validate_Approvers (
      p_api_version        => l_api_version,
      p_init_msg_list      => p_init_msg_list,
      p_commit             => p_commit,
      p_validation_level   => p_validation_level,
      x_return_status      => l_return_status,
      x_msg_count          => x_msg_count,
      x_msg_data           => x_msg_data,
      p_Approvers_rec      => l_Approvers_rec
   );
   IF l_return_status = Fnd_Api.g_ret_sts_error THEN
      RAISE Fnd_Api.g_exc_error;
   ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;

   IF l_Approvers_rec.APPROVER_ID IS NULL THEN
      Check_Approver_Role (
         p_Approvers_rec  => p_Approvers_rec,
         p_complete_rec   => l_Approvers_rec,
         x_return_status  => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

            Check_Approver_Name_Or_Id(p_approvers_rec => p_approvers_rec,
                                                                                                                    x_approver_id   => l_approver_id,
                                                                                                                    x_return_status => l_return_status
                                                                                                                    );
             IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
    ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
    END IF;

                l_approvers_rec.approver_id := l_approver_id;


   IF l_Approvers_rec.APPROVER_SEQUENCE IS NOT NULL THEN
      Check_Approver_Sequence (
         p_Approvers_rec  => p_Approvers_rec,
         p_complete_rec   => l_Approvers_rec,
         x_return_status  => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   --
   -- Check for the ID.
   --
   IF l_Approvers_rec.Approval_Approver_Id IS NULL or l_Approvers_rec.Approval_Approver_Id  = Fnd_Api.g_miss_num THEN
      LOOP
         --
         -- If the ID is not passed into the API, then
         -- grab a value from the sequence.
         OPEN c_seq;
         FETCH c_seq INTO l_Approvers_rec.Approval_Approver_Id;
         CLOSE c_seq;
         --
         -- Check to be sure that the sequence does not exist.
         OPEN c_id_exists (l_Approvers_rec.Approval_Approver_Id);
         FETCH c_id_exists INTO l_dummy;
         CLOSE c_id_exists;
         --
         -- If the value for the ID already exists, then
         -- l_dummy would be populated with '1', otherwise,
         -- it receives NULL.
         EXIT WHEN l_dummy IS NULL;
      END LOOP;
   END IF;

   -------------------------- insert --------------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Insert');
    END IF;
   -- Invoke the table handler to create a record
   --
   Ahl_Approvers_Pkg.Insert_Row (
     X_ROWID                 => l_rowid,
     X_APPROVAL_APPROVER_ID  => l_Approvers_rec.APPROVAL_APPROVER_ID,
     X_OBJECT_VERSION_NUMBER => 1,
     X_APPROVAL_RULE_ID      => l_Approvers_rec.APPROVAL_RULE_ID,
     X_APPROVER_TYPE_CODE    => l_Approvers_rec.APPROVER_TYPE_CODE,
     X_APPROVER_SEQUENCE     => l_Approvers_rec.APPROVER_SEQUENCE,
     X_APPROVER_ID           => l_Approvers_rec.APPROVER_ID,
     X_LAST_UPDATE_DATE      => SYSDATE,
     X_LAST_UPDATED_BY       => Fnd_Global.USER_ID,
     X_CREATION_DATE         => SYSDATE,
     X_CREATED_BY            => Fnd_Global.USER_ID,
     X_LAST_UPDATE_LOGIN     => Fnd_Global.LOGIN_ID,
     X_ATTRIBUTE_CATEGORY    => l_Approvers_rec.ATTRIBUTE_CATEGORY,
     X_ATTRIBUTE1            => l_Approvers_rec.ATTRIBUTE1,
     X_ATTRIBUTE2            => l_Approvers_rec.ATTRIBUTE2,
     X_ATTRIBUTE3            => l_Approvers_rec.ATTRIBUTE3,
     X_ATTRIBUTE4            => l_Approvers_rec.ATTRIBUTE4,
     X_ATTRIBUTE5            => l_Approvers_rec.ATTRIBUTE5,
     X_ATTRIBUTE6            => l_Approvers_rec.ATTRIBUTE6,
     X_ATTRIBUTE7            => l_Approvers_rec.ATTRIBUTE7,
     X_ATTRIBUTE8            => l_Approvers_rec.ATTRIBUTE8,
     X_ATTRIBUTE9            => l_Approvers_rec.ATTRIBUTE9,
     X_ATTRIBUTE10           => l_Approvers_rec.ATTRIBUTE10,
     X_ATTRIBUTE11           => l_Approvers_rec.ATTRIBUTE11,
     X_ATTRIBUTE12           => l_Approvers_rec.ATTRIBUTE12,
     X_ATTRIBUTE13           => l_Approvers_rec.ATTRIBUTE13,
     X_ATTRIBUTE14           => l_Approvers_rec.ATTRIBUTE14,
     X_ATTRIBUTE15           => l_Approvers_rec.ATTRIBUTE15 );

   ------------------------- finish -------------------------------

     -- set OUT value
        x_Approval_Approver_Id := l_Approvers_rec.APPROVAL_APPROVER_ID;
        --
        -- END of API body.
        --
        -- Standard check of p_commit.
   IF Fnd_Api.To_Boolean ( p_commit ) THEN
      COMMIT WORK;
   END IF;
   Fnd_Msg_Pub.count_and_get(
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;

EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Create_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get(
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Create_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Create_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error) THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Create_Approvers;

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Approvers
--
--------------------------------------------------------------------
PROCEDURE Update_Approvers (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   p_Approvers_rec     IN  Approvers_Rec_Type,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2

)
IS
   L_API_VERSION        CONSTANT NUMBER := 1.0;
   L_API_NAME           CONSTANT VARCHAR2(30) := 'Update_Approvers';
   L_FULL_NAME          CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;

   l_Approvers_rec      Approvers_Rec_Type := p_Approvers_rec;
   l_dummy              NUMBER;
   l_return_status      VARCHAR2(1);
BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Update_Approvers;

  -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call(
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
     x_return_status := Fnd_Api.g_ret_sts_success;
   ----------------------- validate ----------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Validate');
    END IF;
   -- replace g_miss_char/num/date with current column values
   Complete_Approvers_Rec (p_Approvers_rec, l_Approvers_rec);
   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item THEN
      Check_Approvers_Items (
         p_validation_mode    => Jtf_Plsql_Api.g_update,
         p_Approvers_rec      => p_Approvers_rec,
         x_return_status      => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;
      IF l_Approvers_rec.APPROVER_ID IS NULL THEN
      Check_Approver_Role (
         p_Approvers_rec  => p_Approvers_rec,
         p_complete_rec   => l_Approvers_rec,
         x_return_status  => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

   IF l_Approvers_rec.APPROVER_SEQUENCE IS NOT NULL THEN
      Check_Approver_Sequence (
         p_Approvers_rec  => p_Approvers_rec,
         p_complete_rec   => l_Approvers_rec,
         x_return_status  => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;

  ------------------------- update --------------------
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Update');
    END IF;

 Ahl_Approvers_Pkg. UPDATE_ROW (
     X_APPROVAL_APPROVER_ID  => l_Approvers_rec.APPROVAL_APPROVER_ID,
     X_OBJECT_VERSION_NUMBER => l_Approvers_rec.OBJECT_VERSION_NUMBER + 1,
     X_APPROVAL_RULE_ID      => l_Approvers_rec.APPROVAL_RULE_ID,
     X_APPROVER_TYPE_CODE    => l_Approvers_rec.APPROVER_TYPE_CODE,
     X_APPROVER_SEQUENCE     => l_Approvers_rec.APPROVER_SEQUENCE,
     X_APPROVER_ID           => l_Approvers_rec.APPROVER_ID,
     X_LAST_UPDATE_DATE      => SYSDATE,
     X_LAST_UPDATED_BY       => Fnd_Global.USER_ID,
     X_LAST_UPDATE_LOGIN     => Fnd_Global.LOGIN_ID,
     X_ATTRIBUTE_CATEGORY    => l_Approvers_rec.ATTRIBUTE_CATEGORY,
     X_ATTRIBUTE1            => l_Approvers_rec.ATTRIBUTE1,
     X_ATTRIBUTE2            => l_Approvers_rec.ATTRIBUTE2,
     X_ATTRIBUTE3            => l_Approvers_rec.ATTRIBUTE3,
     X_ATTRIBUTE4            => l_Approvers_rec.ATTRIBUTE4,
     X_ATTRIBUTE5            => l_Approvers_rec.ATTRIBUTE5,
     X_ATTRIBUTE6            => l_Approvers_rec.ATTRIBUTE6,
     X_ATTRIBUTE7            => l_Approvers_rec.ATTRIBUTE7,
     X_ATTRIBUTE8            => l_Approvers_rec.ATTRIBUTE8,
     X_ATTRIBUTE9            => l_Approvers_rec.ATTRIBUTE9,
     X_ATTRIBUTE10           => l_Approvers_rec.ATTRIBUTE10,
     X_ATTRIBUTE11           => l_Approvers_rec.ATTRIBUTE11,
     X_ATTRIBUTE12           => l_Approvers_rec.ATTRIBUTE12,
     X_ATTRIBUTE13           => l_Approvers_rec.ATTRIBUTE13,
     X_ATTRIBUTE14           => l_Approvers_rec.ATTRIBUTE14,
     X_ATTRIBUTE15           => l_Approvers_rec.ATTRIBUTE15 );

   -------------------- finish --------------------------
    --  dbms_output.put_line('test7');
   IF Fnd_Api.to_boolean (p_commit) THEN
      COMMIT;
   END IF;
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
    IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
    IF  G_DEBUG='Y' THEN
            Ahl_Debug_Pub.disable_debug;
                END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Update_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Update_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Update_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
                THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Update_Approvers;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Approver_Sequence
--
--------------------------------------------------------------------

PROCEDURE Check_Approver_Sequence (
   p_Approvers_rec IN  Approvers_Rec_Type,
   p_complete_rec  IN  Approvers_Rec_Type := NULL,
   x_return_status OUT NOCOPY VARCHAR2
)
IS

BEGIN
    x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
   IF p_Approvers_rec.approver_sequence IS NOT NULL THEN
       IF p_Approvers_rec.approver_sequence = 0 OR p_Approvers_rec.approver_sequence < 0 THEN
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name ('AHL', 'AHL_APPR_ORDER_INVALID_JSP');
              Fnd_Msg_Pub.ADD;
          END IF;
             x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
       END IF;
   END IF;
END Check_Approver_Sequence;

--------------------------------------------------------------------
-- PROCEDURE
-- Check_Approver_Role
--
--------------------------------------------------------------------

PROCEDURE Check_Approver_Role (
   p_Approvers_rec IN  Approvers_Rec_Type,
   p_complete_rec  IN  Approvers_Rec_Type := NULL,
   x_return_status OUT NOCOPY VARCHAR2
)
IS
BEGIN
    x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
   IF p_Approvers_rec.APPROVER_NAME IS NULL THEN
       IF UPPER(p_Approvers_rec.approver_type_code) = 'USER' THEN
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_NOT_USER');
              Fnd_Msg_Pub.ADD;
          END IF;
              x_return_status := Fnd_Api.g_ret_sts_error;
             RETURN;
    END IF;
  END IF;
END Check_Approver_Role;

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Approvers
--
--------------------------------------------------------------------
PROCEDURE Delete_Approvers (
   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,
   p_Approval_Approver_Id   IN  NUMBER,
   p_object_version    IN  NUMBER,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2
)
IS
   CURSOR c_Approvers IS
      SELECT   *
      FROM     AHL_Approvers
      WHERE    APPROVAL_APPROVER_ID = p_Approval_Approver_Id;

   /* Start Code for checking approvals by shbhanda Mar'08---*/
    CURSOR check_approval_rules IS
    SELECT COUNT(*) FROM Ahl_Approvers
    WHERE Approval_Rule_Id IN
    (SELECT Approval_Rule_Id FROM Ahl_Approvers WHERE APPROVAL_APPROVER_ID = p_Approval_Approver_Id);

    CURSOR check_appr_status IS
    SELECT status_code FROM Ahl_Approval_rules_b
    WHERE Approval_Rule_Id IN
    (SELECT Approval_Rule_Id FROM Ahl_Approvers WHERE APPROVAL_APPROVER_ID = p_Approval_Approver_Id);

  /* End Code for checking approvals by shbhanda Mar'08---*/

   --
   -- This is the only exception for using %ROWTYPE.
   -- We are selecting from the VL view, which may
   -- have some denormalized columns as compared to
   -- the base tables.
   l_Approvers_rec    c_Approvers%ROWTYPE;
   l_api_version CONSTANT NUMBER       := 1.0;
   l_api_name    CONSTANT VARCHAR2(30) := 'Delete_Approvers';
   l_full_name   CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || l_api_name;
   l_count  NUMBER;
   l_status VARCHAR2(30);
BEGIN
   --------------------- initialize -----------------------
   SAVEPOINT Delete_Approvers;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
   x_return_status := Fnd_Api.g_ret_sts_success;

   OPEN c_Approvers;
   FETCH c_Approvers INTO l_Approvers_rec;
   IF c_Approvers%NOTFOUND THEN
      CLOSE c_Approvers;
      IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
   END IF;
   CLOSE c_Approvers;

   /* Start Code for checking approvals by shbhanda Mar'08---*/
   OPEN check_appr_status;
   FETCH check_appr_status INTO l_status;
 IF check_appr_status%FOUND THEN
   CLOSE check_appr_status;
   OPEN check_approval_rules;
   FETCH check_approval_rules INTO l_count;
    IF check_approval_rules%FOUND THEN
      IF l_count > 1 THEN
         CLOSE check_approval_rules;
      ELSE
         CLOSE check_approval_rules;
         IF UPPER(l_status) = 'ACTIVE' THEN
           IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name('AHL', 'AHL_APPR_NOT_DELETE');
              Fnd_Msg_Pub.ADD;
           END IF;
            RAISE Fnd_Api.g_exc_error;
         END IF;
     END IF;
    END IF;
 ELSE
    CLOSE check_appr_status;
 END IF;
   /* End Code for checking approvals by shbhanda Mar'08---*/

   ------------------------ delete ------------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Delete');
    END IF;
   -- Delete data

  DELETE FROM Ahl_Approvers
    WHERE  APPROVAL_APPROVER_ID = p_Approval_Approver_Id;
     IF (SQL%NOTFOUND) THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
     END IF;


   -------------------- finish --------------------------
   IF Fnd_Api.to_boolean (p_commit) THEN
      COMMIT;
   END IF;
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      ROLLBACK TO Delete_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      ROLLBACK TO Delete_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      ROLLBACK TO Delete_Approvers;
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
                THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );

END Delete_Approvers;
--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Approvers
--
--------------------------------------------------------------------
PROCEDURE Validate_Approvers (

   p_api_version       IN  NUMBER,
   p_init_msg_list     IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit            IN  VARCHAR2,
   p_validation_level  IN  NUMBER    := Fnd_Api.g_valid_level_full,

   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2,
   p_Approvers_rec   IN  Approvers_Rec_Type
)
IS
   L_API_VERSION CONSTANT NUMBER := 1.0;
   L_API_NAME    CONSTANT VARCHAR2(30) := 'Validate_Approvers';
   L_FULL_NAME   CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   l_return_status   VARCHAR2(1);
BEGIN
   --------------------- initialize -----------------------
   -- Check if API is called in debug mode. If yes, enable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.enable_debug;
            END IF;
   -- Debug info.
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Start');
    END IF;
   IF Fnd_Api.to_boolean (p_init_msg_list) THEN
      Fnd_Msg_Pub.initialize;
   END IF;
   IF NOT Fnd_Api.compatible_api_call (
         l_api_version,
         p_api_version,
         l_api_name,
         G_PKG_NAME
   ) THEN
      RAISE Fnd_Api.g_exc_unexpected_error;
   END IF;
  x_return_status := Fnd_Api.g_ret_sts_success;
   ---------------------- validate ------------------------
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Check items');
   END IF;

   IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item THEN
      Check_Approvers_Items (
         p_validation_mode    => Jtf_Plsql_Api.g_create,
         p_Approvers_rec      => p_Approvers_rec,
         x_return_status      => l_return_status
      );
      IF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
         RAISE Fnd_Api.g_exc_unexpected_error;
      ELSIF l_return_status = Fnd_Api.g_ret_sts_error THEN
         RAISE Fnd_Api.g_exc_error;
      END IF;
   END IF;
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':Check record');
    END IF;

   -------------------- finish --------------------------
   Fnd_Msg_Pub.count_and_get (
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data
   );
   IF  G_DEBUG='Y' THEN
       Ahl_Debug_Pub.debug( l_full_name ||':End');
    END IF;
-- Check if API is called in debug mode. If yes, disable debug.
   IF  G_DEBUG='Y' THEN
        Ahl_Debug_Pub.disable_debug;
            END IF;
EXCEPTION
   WHEN Fnd_Api.g_exc_error THEN
      x_return_status := Fnd_Api.g_ret_sts_error;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN Fnd_Api.g_exc_unexpected_error THEN
      x_return_status := Fnd_Api.g_ret_sts_unexp_error ;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
   WHEN OTHERS THEN
      x_return_status := Fnd_Api.g_ret_sts_unexp_error;
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error)
                THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Validate_Approvers;

---------------------------------------------------------------------
-- PROCEDURE
--    Check_Approvers_Items
--
---------------------------------------------------------------------
PROCEDURE Check_Approvers_Items (
   p_validation_mode IN  VARCHAR2 := Jtf_Plsql_Api.g_create,
   p_Approvers_rec       IN  Approvers_Rec_Type,
   x_return_status   OUT NOCOPY VARCHAR2
)
IS
BEGIN
   --
   -- Validate required items.
   Check_Approvers_Req_Items (
      p_Approvers_rec       => p_Approvers_rec,
      x_return_status   => x_return_status
   );
   IF x_return_status <> Fnd_Api.g_ret_sts_success THEN
      RETURN;
   END IF;
   --
   -- Validate uniqueness.
   Check_Approvers_UK_Items (
      p_Approvers_rec          => p_Approvers_rec,
      p_validation_mode    => p_validation_mode,
      x_return_status      => x_return_status
   );
   IF x_return_status <> Fnd_Api.g_ret_sts_success THEN
      RETURN;
   END IF;

END Check_Approvers_Items;

---------------------------------------------------------------------
-- PROCEDURE
--    Init_Approvers_Rec
--
---------------------------------------------------------------------
/*PROCEDURE Init_Approvers_Rec (
   x_Approvers_rec         OUT  NOCOPY Approvers_Rec_Type
)
IS
BEGIN
     x_Approvers_rec.APPROVAL_APPROVER_ID       := Fnd_Api.g_miss_num;
     x_Approvers_rec.OBJECT_VERSION_NUMBER      := Fnd_Api.g_miss_num;
     x_Approvers_rec.APPROVAL_RULE_ID           := Fnd_Api.g_miss_num;
     x_Approvers_rec.APPROVER_TYPE_CODE         := Fnd_Api.g_miss_num;
     x_Approvers_rec.APPROVER_SEQUENCE          := Fnd_Api.g_miss_char;
     x_Approvers_rec.APPROVER_ID                := Fnd_Api.g_miss_num;
END Init_Approvers_Rec;
*/
---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Approvers_Rec
--
---------------------------------------------------------------------
PROCEDURE Complete_Approvers_Rec (
   p_Approvers_rec      IN  Approvers_Rec_Type,
   x_complete_rec       OUT NOCOPY Approvers_Rec_Type
)
IS
   CURSOR c_Approvers IS
      SELECT   *
      FROM     AHL_Approvers
      WHERE    APPROVAL_APPROVER_ID = p_Approvers_rec.Approval_Approver_Id;
   --
   -- This is the only exception for using %ROWTYPE.
   -- We are selecting from the V view, which may
   -- have some denormalized columns as compared to
   -- the base tables.
   l_Approvers_rec    c_Approvers%ROWTYPE;
BEGIN
   x_complete_rec := p_Approvers_rec;
   OPEN c_Approvers;
   FETCH c_Approvers INTO l_Approvers_rec;
   IF c_Approvers%NOTFOUND THEN
      CLOSE c_Approvers;
      IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
         Fnd_Msg_Pub.ADD;
      END IF;
      RAISE Fnd_Api.g_exc_error;
   END IF;
   CLOSE c_Approvers;

   --
   -- APPROVAL_SEQUENCE
   IF p_Approvers_rec.Approver_sequence is null or p_Approvers_rec.Approver_sequence = Fnd_Api.g_miss_num THEN
      x_complete_rec.Approver_sequence := l_Approvers_rec.Approver_sequence;
   END IF;

   --
   -- APPROVER_ID
   IF p_Approvers_rec.Approver_Id is null or p_Approvers_rec.Approver_Id = Fnd_Api.g_miss_num THEN
      x_complete_rec.Approver_Id := l_Approvers_rec.Approver_Id;
   END IF;

   --
   -- APPROVAL_RULE_ID
   IF p_Approvers_rec.APPROVAL_RULE_ID is null or p_Approvers_rec.APPROVAL_RULE_ID = Fnd_Api.g_miss_num THEN
      x_complete_rec.APPROVAL_RULE_ID := l_Approvers_rec.APPROVAL_RULE_ID;
   END IF;

   --
   -- APPROVAL_TYPE_CODE
   IF p_Approvers_rec.APPROVER_TYPE_CODE is null or p_Approvers_rec.APPROVER_TYPE_CODE = Fnd_Api.g_miss_char THEN
      x_complete_rec.APPROVER_TYPE_CODE := l_Approvers_rec.APPROVER_TYPE_CODE;
   END IF;

END Complete_Approvers_Rec;

--       Check_Approvers_Req_Items
PROCEDURE Check_Approvers_Req_Items (
   p_Approvers_rec   IN    Approvers_Rec_Type,
   x_return_status   OUT NOCOPY   VARCHAR2
)
IS
BEGIN
   -- APPROVAL SEQUENCE
   IF p_Approvers_rec.Approver_sequence IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_SEQUENCE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

  --  APPROVER_NAME - Approver Name is mandatory only if the approver type is user
        -- if approver name is null and the approval type is role, then the default approver is picked up
  IF UPPER(p_Approvers_rec.APPROVER_TYPE_CODE) = 'USER' AND p_Approvers_rec.APPROVER_NAME IS NULL THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_MISSING');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;

END Check_Approvers_Req_Items;


PROCEDURE Check_Approver_Name_Or_Id(
            p_approvers_rec  IN Approvers_rec_type,
            x_approver_id  OUT NOCOPY NUMBER,
            x_return_status OUT NOCOPY VARCHAR2
            )
IS

-- Bug 4919031 (Perf Fix)
-- Spliting cursor c_approver_id into c_approver_id_user and c_approver_id_role
-- The usage is based on p_approvers_rec.approver_type_code to be user or role
/*
        CURSOR c_approver_id (approver_name IN VARCHAR2)
        IS
        SELECT ROLE_ID
          FROM AHL_APPROVERS_TYPE_V
         WHERE UPPER(ROLE_NAME) LIKE UPPER(approver_name)
           AND UPPER(LOOKUP_CODE) LIKE UPPER(p_approvers_rec.approver_type_code);
*/

        CURSOR c_approver_id_user (approver_name IN VARCHAR2)
        IS
        SELECT AJREV.RESOURCE_ID
          FROM  JTF_RS_RESOURCE_EXTNS AJREV,
                FND_USER USR
         WHERE  AJREV.CATEGORY IN ('EMPLOYEE','PARTNER', 'PARTY')
           AND  AJREV.RESOURCE_ID > 0
           AND  USR.USER_NAME LIKE UPPER(approver_name)
           AND  AJREV.USER_ID = USR.USER_ID;


        CURSOR c_approver_id_role (approver_name IN VARCHAR2)
        IS
        SELECT DISTINCT JRRV.role_id
          FROM jtf_rs_role_relations_vl JRRV
         WHERE JRRV.role_type_code in ('AHLAPPR', 'AHLGAPPR')
           AND UPPER(JRRV.role_name) LIKE UPPER(approver_name);

-- Bug 4919031 (Perf Fix)
-- Spliting cursor c_approver_name_id into c_approver_name_id_user and c_approver_name_id_role
-- The usage is based on p_approvers_rec.approver_type_code to be user or role
/*
        CURSOR c_approver_name_id (approver_name IN VARCHAR2,
                                   approver_id IN NUMBER)
        IS
        SELECT ROLE_ID
          FROM AHL_APPROVERS_TYPE_V
         WHERE UPPER(ROLE_NAME) LIKE UPPER(approver_name)
           AND ROLE_ID = approver_id
           AND UPPER(LOOKUP_CODE) LIKE UPPER(p_approvers_rec.approver_type_code);
*/

        CURSOR c_approver_name_id_user (approver_name IN VARCHAR2,
                                   approver_id IN NUMBER)
        IS
        SELECT AJREV.RESOURCE_ID
         FROM  JTF_RS_RESOURCE_EXTNS AJREV
        WHERE  AJREV.CATEGORY IN ('EMPLOYEE','PARTNER', 'PARTY')
          AND  AJREV.RESOURCE_ID > 0
          AND  UPPER(AJREV.USER_NAME) LIKE UPPER(approver_name)
          AND  AJREV.RESOURCE_ID = approver_id;

        CURSOR c_approver_name_id_role (approver_name IN VARCHAR2,
                                   approver_id IN NUMBER)
        IS
        SELECT DISTINCT JRRV.role_id
          FROM jtf_rs_role_relations_vl JRRV
         WHERE JRRV.role_type_code in ('AHLAPPR', 'AHLGAPPR')
           AND UPPER(JRRV.role_name) LIKE UPPER(approver_name)
           AND JRRV.role_id = approver_id;

        l_approver_id NUMBER;

BEGIN
        x_return_status := Fnd_Api.g_ret_sts_success;

        IF(p_approvers_rec.approver_name IS NOT NULL and p_approvers_rec.approver_name <> FND_API.G_MISS_CHAR) THEN


           -- Bug 4919031 (Perf Fix)
           -- Spliting cursor c_approver_id into c_approver_id_user and c_approver_id_role
           -- The usage is based on p_approvers_rec.approver_type_code to be user or role

           IF UPPER(p_approvers_rec.approver_type_code) = 'ROLE' THEN

                -- CHeck if the approver name and approver id match
                OPEN c_approver_name_id_role(p_approvers_rec.approver_name, p_approvers_rec.approver_id);
                FETCH c_approver_name_id_role INTO l_approver_id;
                IF c_approver_name_id_role%NOTFOUND THEN
                -- The approver_name has changed
                        OPEN c_approver_id_role(p_approvers_rec.approver_name);
                        LOOP
                        EXIT WHEN c_approver_id_role%NOTFOUND;
                                FETCH c_approver_id_role INTO l_approver_id;
                        END LOOP;

                        IF c_approver_id_role%ROWCOUNT = 0 THEN
                                IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                                     Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_MISSING');
                                     Fnd_Msg_Pub.ADD;
                                END IF;
                                x_return_status := Fnd_Api.g_ret_sts_error;
                                RETURN;
                        ELSIF c_approver_id_role%ROWCOUNT > 1 THEN
                                IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                                     Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_MISSING');
                                     Fnd_Msg_Pub.ADD;
                                END IF;
                                x_return_status := Fnd_Api.g_ret_sts_error;
                                RETURN;
                        END IF;
                        CLOSE c_approver_id_role;
                END IF;
                x_approver_id := l_approver_id;
                CLOSE c_approver_name_id_role;

           ELSIF UPPER(p_approvers_rec.approver_type_code) = 'USER' THEN

                -- CHeck if the approver name and approver id match
                OPEN c_approver_name_id_user(p_approvers_rec.approver_name, p_approvers_rec.approver_id);
                FETCH c_approver_name_id_user INTO l_approver_id;
                IF c_approver_name_id_user%NOTFOUND THEN
                -- The approver_name has changed
                        OPEN c_approver_id_user(p_approvers_rec.approver_name);
                        LOOP
                        EXIT WHEN c_approver_id_user%NOTFOUND;
                                FETCH c_approver_id_user INTO l_approver_id;
                        END LOOP;

                        IF c_approver_id_user%ROWCOUNT = 0 THEN
                                IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                                     Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_MISSING');
                                     Fnd_Msg_Pub.ADD;
                                END IF;
                                x_return_status := Fnd_Api.g_ret_sts_error;
                                RETURN;
                        ELSIF c_approver_id_user%ROWCOUNT > 1 THEN
                                IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
                                     Fnd_Message.set_name ('AHL', 'AHL_APPR_TYPE_MISSING');
                                     Fnd_Msg_Pub.ADD;
                                END IF;
                                x_return_status := Fnd_Api.g_ret_sts_error;
                                RETURN;
                        END IF;
                        CLOSE c_approver_id_user;
                END IF;
                x_approver_id := l_approver_id;
                CLOSE c_approver_name_id_user;

           END IF;

        END IF;
END Check_Approver_Name_Or_Id;

--       Check_Approvers_UK_Items
PROCEDURE Check_Approvers_UK_Items (
   p_Approvers_rec       IN    Approvers_Rec_Type,
   p_validation_mode IN    VARCHAR2 := Jtf_Plsql_Api.g_create,
   x_return_status   OUT NOCOPY   VARCHAR2
)
IS
   l_valid_flag   VARCHAR2(1);
BEGIN
   x_return_status := Fnd_Api.g_ret_sts_success;
   -- APPROVAL_APPROVER_ID
   -- For Create_Approvers, when ID is passed in, we need to
   -- check if this ID is unique.
    IF p_validation_mode = Jtf_Plsql_Api.g_create
      AND p_Approvers_rec.Approval_Approver_Id IS NOT NULL
   THEN
      IF Ahl_Utility_Pvt.check_uniqueness(
                      'AHL_Approvers',
                                'APPROVAL_APPROVER_ID = ' || p_Approvers_rec.Approval_Approver_Id
                        ) = Fnd_Api.g_false
                THEN
         IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
            Fnd_Message.set_name ('AHL', 'AHL_APPR_DUPLICATE_ID');
            Fnd_Msg_Pub.ADD;
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
         RETURN;
      END IF;
   END IF;
    -- check if Approval_Rule_Id,Approver_Sequence and Approver_Id is UNIQUE

   IF p_validation_mode = Jtf_Plsql_Api.g_create THEN
       l_valid_flag := Ahl_Utility_Pvt.check_uniqueness (
         'AHL_Approvers',
         'Approval_Rule_Id = ' || p_Approvers_rec.Approval_Rule_Id  ||
          ' AND Approver_Sequence = ' || p_Approvers_rec.Approver_Sequence
           );
   ELSE
      l_valid_flag := Ahl_Utility_Pvt.check_uniqueness (
         'AHL_Approvers',
         'Approval_Rule_Id = ' || p_Approvers_rec.Approval_Rule_Id  ||
          ' AND Approver_Sequence = ' || p_Approvers_rec.Approver_Sequence ||
           ' AND Approval_Approver_id <> ' || p_Approvers_rec.Approval_Approver_id
          );
   END IF;
   IF l_valid_flag = Fnd_Api.g_false THEN
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_error) THEN
         Fnd_Message.set_name ('AHL', 'AHL_APPR_SEQ_NOT_UNIQUE');
         Fnd_Msg_Pub.ADD;
      END IF;
      x_return_status := Fnd_Api.g_ret_sts_error;
      RETURN;
   END IF;
END Check_Approvers_UK_Items;

END Ahl_Approvals_Pvt;

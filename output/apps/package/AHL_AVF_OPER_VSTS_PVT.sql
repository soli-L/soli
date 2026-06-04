
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_AVF_OPER_VSTS_PVT" AUTHID CURRENT_USER AS
/* $Header: AHLVOPVS.pls 120.1.12020000.2 2012/12/07 01:22:00 sareepar noship $ */

-- object names mapped to the Workflow process, as defined in the lookup AHL_APPR_OBJECT_TYPE
G_WF_CANC_OBJ       CONSTANT VARCHAR2(30) := 'V_DELE'; -- Visit Deletion
G_WF_VSCE_OBJ       CONSTANT VARCHAR2(30) := 'V_USCE'; -- Visit UE's Service Catergory Exception
G_WF_DISC_OBJ       CONSTANT VARCHAR2(30) := 'V_DISC'; -- Visit Disconnect
G_WF_VDUR_OBJ       CONSTANT VARCHAR2(30) := 'V_DURA'; -- Visit Downtime Duration

-- AOL message codes for the notification subjects
G_VISIT_CANC_SBJ    CONSTANT VARCHAR2(30) := 'AHL_VISIT_DELETE_NTF_SUB'; -- Visit Deletion Review Notification
G_VISIT_USCE_SBJ    CONSTANT VARCHAR2(30) := 'AHL_VISIT_USCE_NTF_SUB'; -- Visit Service Category Exception Review Notificaiton
G_VISIT_DISC_SBJ    CONSTANT VARCHAR2(30) := 'AHL_VISIT_DISCON_NTF_SUB'; -- Visit Disconnect Review Notification
G_VISIT_DURA_SBJ    CONSTANT VARCHAR2(30) := 'AHL_VISIT_DT_DUR_NTF_SUB'; -- Visit Downtime Duration Review Notification

-- AOL function names for the OA regions in the notification body
G_VISIT_CANCEL_FN   CONSTANT VARCHAR2(30) := 'AHL_VISIT_DELETE_NTFCN'; -- Visit Deletion Notification
G_VISIT_USCE_FN     CONSTANT VARCHAR2(30) := 'AHL_VISIT_USCE_NTFCN'; -- Visit Service Category Exception Notificaiton
G_VISIT_DISC_FN     CONSTANT VARCHAR2(30) := 'AHL_VISIT_DISCON_NTFCN'; -- Visit Disconnect Notification
G_VISIT_DURA_FN     CONSTANT VARCHAR2(30) := 'AHL_VISIT_DT_DUR_NTFCN'; -- Visit Downtime Duration Notification

-- names of the parameters, if any, required by the OA regions in the notification body
G_VISIT_ID_FN_PARAM1       CONSTANT VARCHAR2(30)  := 'VisitIds'; -- Visit ID
G_UE_IDS_FN_PARAM2         CONSTANT VARCHAR2(30)  := 'UeIds'; -- Unit Effectivity ID
G_UNIT_SCH_ID_FN_PARAM2    CONSTANT VARCHAR2(30)  := 'UnitSchId'; -- Unit Schedule ID
G_PAGE_FUNC_PARAM3         CONSTANT VARCHAR2(30)  := 'PageFunc'; -- Page Function

--------------------------------------------------------------------
-- START: Defining local functions and procedures            --
--------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------
--  Procedure name    : Create_Oper_Visit
--  Type              : Private
--  Function          : Procedure to create visit based on operational params
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version      IN  NUMBER        Required
--      p_init_msg_list    IN  VARCHAR2      Default  FND_API.G_FALSE
--      p_validation_level IN  NUMBER        Default  FND_API.G_VALID_LEVEL_FULL
--
--  Standard OUT Parameters :
--      x_return_status    OUT VARCHAR2      Required
--      x_msg_count        OUT NUMBER        Required
--      x_msg_data         OUT VARCHAR2      Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Create_Oper_Visit (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2);

----------------------------------------------------------------------------------------------------------------
--  Procedure name    : Update_Oper_Visit
--  Type              : Private
--  Function          : Procedure to Update visit based on operational params
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version      IN  NUMBER        Required
--      p_init_msg_list    IN  VARCHAR2      Default  FND_API.G_FALSE
--      p_validation_level IN  NUMBER        Default  FND_API.G_VALID_LEVEL_FULL
--
--  Standard OUT Parameters :
--      x_return_status    OUT VARCHAR2      Required
--      x_msg_count        OUT NUMBER        Required
--      x_msg_data         OUT VARCHAR2      Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Update_Oper_Visit (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2);


---------------------------------------------------------------------------------------
-- PROCEDURE
--    Get_Visit_Type
-- Type             : Public
-- PURPOSE
--    To find out whether visit associated to the organization is arrival or departure or downtime
----------------------------------------------------------------------------------------

PROCEDURE Get_Visit_Type(
    p_fs_id       IN          NUMBER,
    p_fs_type     IN          VARCHAR2,
    x_vst_typ     OUT NOCOPY  VARCHAR2,
    x_visit_id    OUT NOCOPY  NUMBER,
    x_visit_id2   OUT NOCOPY  NUMBER
    );
--------------------------------------------------------------------
-- PROCEDURE
--    Process_Operational_visit
--
-- PURPOSE
--    Made as an executable for the P2P CP
--  Process_Operational_visit Parameters :
--      errbuf              OUT   VARCHAR2   Required
--         Defines in pl/sql to store procedure to get error messages into log file
--      retcode             OUT   NUMBER     Required
--         To get the status of the concurrent program

--------------------------------------------------------------------
PROCEDURE Process_Operational_visits(
    errbuf            OUT NOCOPY VARCHAR2,
    retcode           OUT NOCOPY NUMBER,
    p_api_version     IN  NUMBER,
    p_oper_flag       IN  VARCHAR2
);

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Can_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a Visit is deleted.
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Can_Notification Parameters:
--       p_visit_id               IN     Visit Id                                       Required
--       p_ue_ids                 IN     Unit Effectivity Ids concatenated by using ',' Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Can_Notification (
    p_visit_id                    IN              NUMBER,
    p_ue_ids                      IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
);

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_SCE_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a Visit UE's Service Category is greater
--                      than the visit's department service category
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_SCE_Notification Parameters:
--       p_visit_id               IN     Visit Id                                       Required
--       p_ue_ids                 IN     Unit Effectivity Ids concatenated by using ',' Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_SCE_Notification (
    p_visit_id                    IN              NUMBER,
    p_ue_ids                      IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
);

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Disc_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a visit is disconnected from the flight
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Disc_Notification Parameters:
--       p_unit_schedule_id       IN     Unit Schedule Id                               Required
--       p_visit_ids              IN     Visit Ids affected by the flight               Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Disc_Notification (
    p_unit_schedule_id            IN              NUMBER,
    p_visit_ids                   IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
);

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Dur_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a visit is disconnected from the flight
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Dur_Notification Parameters:
--       p_unit_schedule_id       IN     Unit Schedule Id                               Required
--       p_visit_ids              IN     Visit Ids affected by the flight               Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Dur_Notification (
    p_unit_schedule_id            IN              NUMBER,
    p_visit_ids                   IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
);
END AHL_AVF_OPER_VSTS_PVT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_AVF_OPER_VSTS_PVT" AS
/* $Header: AHLVOPVB.pls 120.0.12020000.6 2016/03/04 16:31:56 prakkum noship $ */

G_PKG_NAME     CONSTANT VARCHAR2(30) := ' AHL_AVF_OPER_VSTS_PVT';
G_APP_NAME     CONSTANT VARCHAR2(3)  := 'AHL';

------------------------------------
-- Common constants and variables --
------------------------------------
l_log_current_level     NUMBER      := fnd_log.g_current_runtime_level;
l_log_statement         NUMBER      := fnd_log.level_statement;
l_log_procedure         NUMBER      := fnd_log.level_procedure;

---------------------------------------------------------------------
--   Define Record Types for record structures needed by the APIs  --
---------------------------------------------------------------------
--TCHIMIRA :: 14-Jun-2012 :: start
-- Record type for operational visit parameters
TYPE oper_param_rec_type IS RECORD
   (visit_type_code         VARCHAR2(30),
    mc_id                   NUMBER,
    alternate_dep_id        NUMBER,
    autovst_oper_id         NUMBER );

-- Record type for flight schedules
TYPE flight_schedule_rec_type IS RECORD
   (unit_config_header_id    NUMBER,
    departure_org_id         NUMBER,
    departure_dept_id        NUMBER,
    unit_schedule_id         NUMBER,
    est_departure_time       DATE,
    arrival_org_id           NUMBER,
    arrival_dept_id          NUMBER,
    est_arrival_time         DATE);
--TCHIMIRA :: 14-Jun-2012 :: end
--------------------------------------------------------------------
-- Define Table Type for Records Structures                       --
--------------------------------------------------------------------
-- NO TABLE TYPES **************

--------------------------------------------------------------------
-- START: Defining local functions and procedures BODY            --
--------------------------------------------------------------------
--TCHIMIRA :: 14-Jun-2012 :: start
--   To Create a departure visit at the departing org of the flight
PROCEDURE Create_Departure_visit(
    p_oper_param_rec       IN      oper_param_rec_type,
    p_flight_schedule_rec  IN      flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status        OUT NOCOPY     VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2
);

--   To Create an arrival visit at the arrival org of the flight
PROCEDURE Create_Arrival_visit(
    p_oper_param_rec       IN      oper_param_rec_type,
    p_flight_schedule_rec  IN      flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status        OUT NOCOPY     VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2
);

--   To Create a downtime visit at the arrival org of the flight
PROCEDURE Create_Downtime_visit(
    p_oper_param_rec       IN      oper_param_rec_type,
    p_flight_schedule_rec  IN      flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status        OUT NOCOPY     VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2
);

--   To Delete an auto visit
PROCEDURE Delete_Oper_Visit(
    p_visit_id       IN   NUMBER,
    x_return_status  OUT NOCOPY     VARCHAR2);
--TCHIMIRA :: 14-Jun-2012 :: end

-- PRAKKUM :: Bug 13844759 :: 26/07/2012
PROCEDURE Load_Can_Cancel_Visit (
    p_visit_id               IN                     NUMBER,
    p_visit_id2              IN                     NUMBER,
    x_can_cancel_visit       OUT NOCOPY             VARCHAR2,
    x_can_cancel_visit2      OUT NOCOPY             VARCHAR2,
    x_return_status          OUT NOCOPY             VARCHAR2,
    x_msg_count              OUT NOCOPY             NUMBER,
    x_msg_data               OUT NOCOPY             VARCHAR2
);

--PRAKKUM :: 01/08/2012 :: Added procedure
PROCEDURE Disconnect_Flight_Visit (
    p_visit_id               IN                     NUMBER,
    p_unit_schedule_id       IN                     NUMBER,
    x_return_status          OUT NOCOPY             VARCHAR2,
    x_msg_count              OUT NOCOPY             NUMBER,
    x_msg_data               OUT NOCOPY             VARCHAR2
);

----------------------------------------------------------------------------------------------------------------
--  Procedure name    : Create_Oper_Visit
--  Type              : Private
--  Function          : Procedure to create visit based on operational params
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version      IN  NUMBER        Required
--      p_init_msg_list    IN  VARCHAR2      Default  FND_API.G_FALSE
--      p_validation_level IN  NUMBER        Default  FND_API.G_VALID_LEVEL_FULL
--
--  Standard OUT Parameters :
--      x_return_status    OUT VARCHAR2      Required
--      x_msg_count        OUT NUMBER        Required
--      x_msg_data         OUT VARCHAR2      Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Create_Oper_Visit (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2)IS

-- Local Variables

-- Standard in/out parameters
l_api_name                    VARCHAR2(30) := 'CREATE_OPER_VISIT';
l_api_version                 NUMBER       := 1.0;
l_debug_key          CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
l_msg_count                   NUMBER;
l_msg_data                    VARCHAR2(2000);
l_return_status               VARCHAR2(1);
l_init_msg_list               VARCHAR2(10):= p_init_msg_list;
l_visit_type                  VARCHAR2(40);
l_visit_id                    NUMBER;
l_visit_type_duration         NUMBER;
l_visit_id2                   NUMBER;
x_item_key                    VARCHAR2(100);
l_can_cancel_visit            VARCHAR2(1);
l_can_cancel_visit2           VARCHAR2(1);
l_count_prec_arr_org          NUMBER;
l_count_prec_arr_dep          NUMBER;
l_count_prec_arr_cat          NUMBER;
l_visit_type_code             VARCHAR2(30);
l_flight_schedule_rec         flight_schedule_rec_type;
l_oper_param_rec              oper_param_rec_type;
l_prec_flight_schedule_rec    flight_schedule_rec_type;
-- Bug 14336467 :: PRAKKUM :: 13/07/2012
l_present_time                DATE := SYSDATE;
l_is_creation_success         VARCHAR2(1) := 'Y';
l_is_downtime_vst_created     VARCHAR2(1) := 'Y';

-- Cursor to get the visit Number from visit_id
CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

-- Cursor to get all the flight schedule records whose status is 'Created'
Cursor get_flight_schedule_rows(c_status IN VARCHAR2)
IS
SELECT *
FROM AHL_UNIT_SCHEDULES
WHERE AUTOVISIT_PROCESS_STATUS = c_status;

--Get the count of rows matching with the UC and org of the flight schedule and enabled_flag as Y
Cursor get_non_null_org_count (c_uc_id IN NUMBER, c_org_id IN NUMBER)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id;
 l_count_org NUMBER;

--Get the count of rows matching with the UC, org and dep of the flight schedule and enabled_flag as Y
Cursor get_non_null_dep_count (c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id
 AND op.department_id = c_dep_id;
 l_count_dep NUMBER;

--Get the count of rows matching with the UC, org, dep and category of the flight schedule and enabled_flag as Y
Cursor get_non_null_cat_count (c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER, c_flight_cat IN VARCHAR2)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id
 AND op.department_id = c_dep_id
 AND op.flight_category_code = c_flight_cat;
 l_count_cat NUMBER;

-- Get the ground time (in number of hours) between two flight schedules
Cursor get_ground_time (c_prev_fs_id IN NUMBER, c_succ_fs_id IN NUMBER)
IS
SELECT to_number((succ_fs.EST_DEPARTURE_TIME - prev_fs.EST_ARRIVAL_TIME)*24*60)
FROM AHL_UNIT_SCHEDULES prev_fs, AHL_UNIT_SCHEDULES succ_fs
WHERE prev_fs.UNIT_SCHEDULE_ID = c_prev_fs_id
 AND succ_fs.UNIT_SCHEDULE_ID = c_succ_fs_id;
 l_ground_time NUMBER;

--Cursor to fetch operational param rows whose enabled flag is Y and matches master config
Cursor get_oper_param_rows1(c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER, c_cat_code IN VARCHAR2,
                            c_org_count IN NUMBER, c_dep_count IN NUMBER, c_cat_count IN NUMBER,
                            c_create_for IN VARCHAR2, c_ground_time IN NUMBER)
IS
SELECT op.*
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
 WHERE op.enabled_flag = 'Y'
   AND uc.unit_config_header_id = c_uc_id
   AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
   AND ( (op.organization_id = c_org_id)
        OR ( c_org_count = 0 -- there are no non-null org rows meeting mc and enabled_flag
             AND op.organization_id IS NULL))
   AND ( ( c_org_count = 0 )
            OR (op.department_id = c_dep_id)
            OR ( c_dep_count = 0
                 AND op.department_id IS NULL))
   AND ( (op.flight_category_code = c_cat_code)
            OR ( ((c_cat_count = 0) OR ( c_cat_code IS NULL))
                 AND op.flight_category_code IS NULL))
   AND op.create_for = c_create_for
   -- if create_for is not downtime, pass null as c_ground_time to this cursor
   AND ( (c_ground_time IS NULL)
         OR (c_ground_time BETWEEN op.START_TIME AND NVL(op.END_TIME,c_ground_time)));
get_oper_param_rec get_oper_param_rows1%ROWTYPE;

--curosr that checks if there is any succeeding flight for this flight schedule
Cursor get_succeeding_us_det (c_fs_id IN NUMBER)
 IS
 SELECT UNIT_SCHEDULE_ID, EST_DEPARTURE_TIME FROM AHL_UNIT_SCHEDULES
 WHERE  preceding_us_id = c_fs_id;
l_succeeding_us_id NUMBER;
l_succ_dep_time DATE;

Cursor get_visit_type_duration(c_visit_type_code IN VARCHAR2, c_mc_id IN NUMBER)
IS
SELECT estimated_duration
FROM ahl_visit_types_b
WHERE visit_type_code = c_visit_type_code
 AND mc_id = c_mc_id
 AND status_code = 'COMPLETE';

-- Cursor to get preceeding flight schedule details
Cursor get_pre_fs_det(c_unit_schedule_id IN NUMBER)
IS
SELECT *
FROM AHL_UNIT_SCHEDULES
WHERE UNIT_SCHEDULE_ID = c_unit_schedule_id;
pre_fs_det_rec get_pre_fs_det%ROWTYPE;

--Cursor to find if the visit is in planning status and not firmed and not locked
Cursor can_cancel_visit(c_visit_id IN NUMBER)
IS
SELECT 'X'
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id
 AND STATUS_CODE = 'PLANNING'
 AND NVL(FIRMED_FLAG,'N') <> 'Y'
 AND NVL(LOCKED_FLAG,'N') <> 'Y';

-- Cursor to get visit type of a visit
Cursor get_visit_type_code(c_visit_id IN NUMBER)
IS
SELECT visit_type_code
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id;

BEGIN

 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level)THEN
      fnd_log.string
      (
        fnd_log.level_procedure,
       'ahl.plsql.AHL_AVF_OPER_VSTS_PVT.Create_Oper_Visit.begin',
       'At the start of PLSQL procedure'
      );
 END IF;

 -- Standard start of API savepoint
 SAVEPOINT Create_Oper_Visit_pvt;

 -- Initialize message list if p_init_msg_list is set to TRUE

 IF FND_API.To_Boolean( p_init_msg_list) THEN
   FND_MSG_PUB.Initialize;
 END IF;

 -- Initialize API return status to success
 x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Standard call to check for call compatibility.
 IF NOT Fnd_Api.COMPATIBLE_API_CALL(l_api_version,
                                    p_api_version,
                                    l_api_name,G_PKG_NAME)
 THEN
   RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
 END IF;

 -- Added for logging visit numbers :: SATRAJEN
 fnd_file.put_line(fnd_file.log, 'List of Operational Visit Numbers created ');

 -- Loop through all the flight schedule records whose status is Created.
 FOR flight_schedule_rec IN get_flight_schedule_rows('C') LOOP
  -- store all the flight params in the record
  l_flight_schedule_rec.unit_config_header_id := flight_schedule_rec.unit_config_header_id;
  l_flight_schedule_rec.departure_org_id := flight_schedule_rec.departure_org_id;
  l_flight_schedule_rec.departure_dept_id := flight_schedule_rec.departure_dept_id;
  l_flight_schedule_rec.unit_schedule_id := flight_schedule_rec.unit_schedule_id;
  l_flight_schedule_rec.est_departure_time := flight_schedule_rec.est_departure_time;
  l_flight_schedule_rec.arrival_org_id := flight_schedule_rec.arrival_org_id;
  l_flight_schedule_rec.arrival_dept_id := flight_schedule_rec.arrival_dept_id;
  l_flight_schedule_rec.est_arrival_time := flight_schedule_rec.est_arrival_time;

  -- CASE I: First consider the departing org of the flight schedule record
  IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'CASE 1, flight_schedule_rec.unit_schedule_id= '||flight_schedule_rec.unit_schedule_id );
  END IF;

  OPEN get_non_null_org_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id);
  FETCH get_non_null_org_count INTO l_count_org;
  CLOSE get_non_null_org_count;

  OPEN get_non_null_dep_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                              flight_schedule_rec.departure_dept_id);
  FETCH get_non_null_dep_count INTO l_count_dep;
  CLOSE get_non_null_dep_count;

  OPEN get_non_null_cat_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                              flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code);
  FETCH get_non_null_cat_count INTO l_count_cat;
  CLOSE get_non_null_cat_count;

  -- check if there exisits a visit and if yes, get the visit details
  AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'P', l_visit_type, l_visit_id,l_visit_id2);

  IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.preceding_us_id--@>'||flight_schedule_rec.preceding_us_id);
  END IF;
  --If the flight schedule does not have any preceeding event then
  IF ( flight_schedule_rec.preceding_us_id IS NULL ) THEN
    IF substr (l_visit_type,1,1) = 'D' THEN --existing visit is a departure visit
      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' There is an existing departure visit at dep org, do nothing');
      END IF;
      NULL; --Do nothing :: Go to arrival org consideration
    ELSIF l_visit_type = 'N' THEN -- no visit

      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' flight_schedule_rec.unit_config_header_id--@>'||flight_schedule_rec.unit_config_header_id||
                                                    ' ;flight_schedule_rec.departure_org_id--@>'||flight_schedule_rec.departure_org_id||
                                                    ' ;flight_schedule_rec.departure_dept_id--@>'||flight_schedule_rec.departure_dept_id||
                                                    ' ;flight_schedule_rec.flight_category_code--@>'||flight_schedule_rec.flight_category_code||
                                                    ' ;l_count_org--@>'||l_count_org||
                                                    ' ;l_count_dep--@>'||l_count_dep||
                                                    ' ;l_count_cat--@>'||l_count_cat||
                                                    ' ;create for--@>DEPARTURE');
      END IF;
      -- check for the possibility of creating a departure visit;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org,
                                l_count_dep, l_count_cat,'DEPARTURE', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        --If there is a possibility to create a departure visit
        --TYPE 1: Departure Org :: no visit to cancel :: create a departure visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 1 and before calling Create_Departure_visit');
        END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Departure_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012
          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
      END IF;
      CLOSE get_oper_param_rows1;
       -- Go to arrival org consideration
    END IF; --ELSIF l_visit_type = 'N'

  --If the flight schedule has any preceeding event then
  ELSE
   -- check if any of the arrival prec flight visit or departure current flight visit does not satisfy any of
   -- the criteria to be automatically cancelled.
   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   OPEN get_pre_fs_det(flight_schedule_rec.preceding_us_id);
   FETCH get_pre_fs_det INTO pre_fs_det_rec;
   CLOSE get_pre_fs_det;
   -- store all the preceding flight params in the record
   l_prec_flight_schedule_rec := null;
   l_prec_flight_schedule_rec.unit_config_header_id := flight_schedule_rec.unit_config_header_id;
   l_prec_flight_schedule_rec.unit_schedule_id      := pre_fs_det_rec.unit_schedule_id;
   l_prec_flight_schedule_rec.arrival_org_id        := pre_fs_det_rec.arrival_org_id;
   l_prec_flight_schedule_rec.arrival_dept_id       := pre_fs_det_rec.arrival_dept_id;
   l_prec_flight_schedule_rec.est_arrival_time      := pre_fs_det_rec.est_arrival_time;

   IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' flight_schedule_rec.unit_config_header_id--@>'||flight_schedule_rec.unit_config_header_id||
                                                    ' ;flight_schedule_rec.departure_org_id--@>'||flight_schedule_rec.departure_org_id||
                                                    ' ;flight_schedule_rec.departure_dept_id--@>'||flight_schedule_rec.departure_dept_id||
                                                    ' ;flight_schedule_rec.flight_category_code--@>'||flight_schedule_rec.flight_category_code||
                                                    ' ;l_count_org--@>'||l_count_org||
                                                    ' ;l_count_dep--@>'||l_count_dep||
                                                    ' ;l_count_cat--@>'||l_count_cat||
                                                    ' ;create for--@>DEPARTURE');
   END IF;


   -- if arrival prec flight visit can not be cancelled and there is no visit associated to dep org of current FS
   -- then look for the possibility of creating a departure visit
   IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL) AND (l_visit_type <> 'T')) THEN
      -- check for the possibility of creating a departure visit;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org,
                                l_count_dep, l_count_cat,'DEPARTURE', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        --If there is a possibility to create a departure visit
        --TYPE 1a: Departure Org :: no visit to cancel :: create a departure visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 1a and before calling Create_Departure_visit');
        END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Departure_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
             ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
      END IF; -- IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
       -- Go to arrival org consideration
   END IF; --IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL)) THEN

   -- if both arrival prec flight visit and dep visit can be automatically cancelled
   IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
    --Get ground time at the departing org of a FS
    OPEN get_ground_time (flight_schedule_rec.preceding_us_id, flight_schedule_rec.UNIT_SCHEDULE_ID);
    FETCH get_ground_time INTO l_ground_time;
    CLOSE get_ground_time;

    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Ground time is '||l_ground_time);
    END IF;

    OPEN get_non_null_org_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id);
    FETCH get_non_null_org_count INTO l_count_prec_arr_org;
    CLOSE get_non_null_org_count;

    OPEN get_non_null_dep_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id);
    FETCH get_non_null_dep_count INTO l_count_prec_arr_dep;
    CLOSE get_non_null_dep_count;

    OPEN get_non_null_cat_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code);
    FETCH get_non_null_cat_count INTO l_count_prec_arr_cat;
    CLOSE get_non_null_cat_count;

    IF substr (l_visit_type,1,1) <> 'T' THEN -- either no visit or departure visit at the departing org of current FS
      IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'unit_config_header_id: '||pre_fs_det_rec.unit_config_header_id
          ||', pre_fs_det_rec.arrival_org_id: '||pre_fs_det_rec.arrival_org_id||',  arrival_dept_id: , '
          ||pre_fs_det_rec.arrival_dept_id  ||',  flight_category_code: ,'||pre_fs_det_rec.flight_category_code
          ||',  l_count_prec_arr_org: ,'||l_count_prec_arr_org
          ||', l_count_prec_arr_dep:   ,'||l_count_prec_arr_dep||',  l_count_prec_arr_cat: ,'||l_count_prec_arr_cat);
      END IF;
      -- check for the possibility to create a downtime visit
      OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', l_ground_time);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      l_is_downtime_vst_created := 'Y';
      IF get_oper_param_rows1%FOUND THEN   -- there is possibility of creating a downtime visit
       CLOSE get_oper_param_rows1;
       IF l_visit_id2 is null THEN  -- if there is no visit associated to the arrival org of previous FS
        --TYPE 2: Departure Org :: no visit for arrival org of previous FS to cancel :: create a downime visit

        SAVEPOINT OPER_VISIT_CREATION; -- Bug 14336467 :: PRAKKUM :: 13/07/2012

        --cancel the departure visit of the current flight if it is not null
        IF(l_visit_id is not null) then
          Delete_Oper_Visit(
              p_visit_id       => l_visit_id,
              x_return_status  => l_return_status);
        END IF;--IF(l_visit_id is not null) then
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 2 and before calling Create_Downtime_visit');
        END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          -- we need to create a downtime visit and associate to the arrival org of preceeding flight, so pass preceeding flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_prec_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );

        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
        END IF;

        IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
            l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating departure visit
        END IF;
        -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

       ELSE -- l_visit_id2 is not null i.e if there is visit associated to the arrival org of previous FS
        -- We need to match the visit type of the existing visit and operational param row visit type
        OPEN get_visit_type_code(l_visit_id2);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
          -- if it does not match then Cancel the visit assoc to arrival org and also if any departure visit associated
          -- to the dep org of current FS. then create a downtime visit
          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 3');
          END IF;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          --TYPE 3: Departure Org :: cancel arrival visit and dep visit(if exists) :: create a downtime visit
          --Cancel the existing arrival visit of the prec FS since the visit types did not match
          Delete_Oper_Visit(
              p_visit_id       => l_visit_id2,
              x_return_status  => l_return_status);

                --cancel the departure visit of the current if it is not null
          IF(l_visit_id is not null) then
             Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
          END IF;--IF(l_visit_id is not null) then
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- we need to create a downtime visit and associate to the arrival org of preceeding flight, so pass preceeding flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_prec_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
            l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating departure visit
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        ELSE
          -- If the visit type matches, we will retain the arrival visit
          -- check for the possibility of creating a departure visit if there is no dep visit at dep org
          IF l_visit_id is null THEN
           OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org,
                                l_count_dep, l_count_cat,'DEPARTURE', NULL);
           FETCH get_oper_param_rows1 INTO get_oper_param_rec;
           IF get_oper_param_rows1%FOUND THEN
            --there is a possibility to create a departure visit
            --TYPE 4: Departure Org :: no dep visit associated to current FS dep org :: create a departure visit
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 4 and before calling Create_Departure_visit');
            END IF;
            l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
            l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
            l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
            l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
            SAVEPOINT OPER_VISIT_CREATION;

            Create_Departure_visit(
              p_oper_param_rec         => l_oper_param_rec,
              p_flight_schedule_rec    => l_flight_schedule_rec,
              p_present_time           => l_present_time,
              p_is_creation_success    => l_is_creation_success,
              x_return_status          => l_return_status,
              x_msg_count              => l_msg_count,
              x_msg_data               => l_msg_data
            );
            IF (l_log_statement >= l_log_current_level) THEN
               fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
               fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
            END IF;

            IF l_is_creation_success<>'Y' THEN
               ROLLBACK TO OPER_VISIT_CREATION;
            END IF;

            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

           END IF; --IF get_oper_param_rows1%FOUND THEN
           CLOSE get_oper_param_rows1;
           -- Go to arrival org consideration
          END IF; --IF l_visit_id is null THEN
        END IF;--else of l_visit_type_code <> get_oper_param_rec.visit_type_code
       END IF;-- else of l_visit_id2 is null
      ELSE --a downtime visit cannot be created
        CLOSE get_oper_param_rows1;
        l_is_downtime_vst_created := 'N';
      END IF;
      IF l_is_downtime_vst_created = 'N' THEN -- Downtime visit is not applicable, so go for creating departure visit
        -- if there is no existing visit, then check for creation of departure visit;
        IF l_visit_type = 'N' THEN -- no existing visit
          OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                    flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                    'DEPARTURE', NULL);
          FETCH get_oper_param_rows1 INTO get_oper_param_rec;
          IF get_oper_param_rows1%FOUND THEN
            --TYPE 5: Departure Org :: no visit to cancel :: create a departure visit
            IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 5 and before calling Create_Departure_visit');
            END IF;
            l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
            l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
            l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
            l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

             -- Bug 14336467 :: PRAKKUM :: 13/07/2012
             SAVEPOINT OPER_VISIT_CREATION;

            Create_Departure_visit(
              p_oper_param_rec         => l_oper_param_rec,
              p_flight_schedule_rec    => l_flight_schedule_rec,
              p_present_time           => l_present_time,
              p_is_creation_success    => l_is_creation_success,
              x_return_status          => l_return_status,
              x_msg_count              => l_msg_count,
              x_msg_data               => l_msg_data
            );
            IF (l_log_statement >= l_log_current_level) THEN
               fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
               fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
            END IF;

            IF l_is_creation_success<>'Y' THEN
               ROLLBACK TO OPER_VISIT_CREATION;
            END IF;

            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

          END IF; --IF get_oper_param_rows1%FOUND THEN
          CLOSE get_oper_param_rows1;--added by tchimira for bug 14008978 on 27-Apr-2012
        END IF; --IF l_visit_type = 'N' THEN
        -- commented the below line by tchimira for bug 14008978 on 27-Apr-2012
        --CLOSE get_oper_param_rows1;
        -- Go to arrival org consideration
      END IF; --IF get_oper_param_rows1%FOUND for checking the possibility of creating a downtime visit

    ELSE -- existing visit is a downtime visit associated to the arrival org of preceding FS
      -- check for the possibility to create a downtime visit
      OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', l_ground_time);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        OPEN get_visit_type_duration (get_oper_param_rec.visit_type_code,get_oper_param_rec.mc_id);
        FETCH get_visit_type_duration INTO l_visit_type_duration;
        CLOSE get_visit_type_duration;
        -- get the visit type code of the visit associated to the arrival org of prec FS
        OPEN get_visit_type_code(l_visit_id2);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        -- If we can create a downtime visit and existing visit is also a downtime visit, the check if visit type of the current visit matches with row visit type
        IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          --  if it does not match then cancel the existing downtime visit with id 'l_visit_id2'
          --  create a downtime visit
          -- TYPE 6: Departure Org :: cancel existing downtime visit :: create a downtime visit
          IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 6');
          END IF;
          Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- we need to create a downtime visit and associate to the arrival org of preceeding flight, so pass preceeding flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_prec_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
             ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        END IF; -- If condition of comparing visit types: IF substr (l_visit_type,3) <> get_oper_param_rec.visit_type_code
        -- Go to arrival org consideration
      END IF;   --IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
    END IF; --if the existing visit is a downtime visit
   END IF; -- IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
  END IF; -- if there is any preceeding event

  IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'CASE II, flight_schedule_rec.unit_schedule_id= '||flight_schedule_rec.unit_schedule_id );
  END IF;
  -- CASE II: Now consider the arrival org of the flight schedule record
  OPEN get_non_null_org_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id);
  FETCH get_non_null_org_count INTO l_count_org;
  CLOSE get_non_null_org_count;

  OPEN get_non_null_dep_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id);
  FETCH get_non_null_dep_count INTO l_count_dep;
  CLOSE get_non_null_dep_count;

  OPEN get_non_null_cat_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code);
  FETCH get_non_null_cat_count INTO l_count_cat;
  CLOSE get_non_null_cat_count;

  OPEN get_succeeding_us_det (flight_schedule_rec.unit_schedule_id);
  FETCH get_succeeding_us_det INTO l_succeeding_us_id, l_succ_dep_time;
  CLOSE get_succeeding_us_det;

  -- check if there exisits a visit and if yes, what visit type - either arrival or downtime
  AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'S', l_visit_type, l_visit_id,l_visit_id2);
  IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement,L_DEBUG_KEY, ' l_succeeding_us_id--@>'||l_succeeding_us_id);
  END IF;
  --If the flight schedule does not have any succeeding flight then
  IF ( l_succeeding_us_id IS NULL ) THEN
    IF substr (l_visit_type,1,1) = 'A' THEN -- arrival visit associated to the arrival org of current FS
      -- Go to end
      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' There is an existing arrival visit at arrival org, do nothing');
      END IF;
      NULL; --Do nothing :: Go to end
    ELSIF l_visit_type = 'N' THEN -- no visit associated to the arrival org of current FS
      -- check for the possibility of creating an arrival visit;
      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' flight_schedule_rec.unit_config_header_id--@>'||flight_schedule_rec.unit_config_header_id||
                                                    ' ;flight_schedule_rec.arrival_org_id--@>'||flight_schedule_rec.arrival_org_id||
                                                    ' ;flight_schedule_rec.arrival_dept_id--@>'||flight_schedule_rec.arrival_dept_id||
                                                    ' ;flight_schedule_rec.flight_category_code--@>'||flight_schedule_rec.flight_category_code||
                                                    ' ;l_count_org--@>'||l_count_org||
                                                    ' ;l_count_dep--@>'||l_count_dep||
                                                    ' ;l_count_cat--@>'||l_count_cat||
                                                    ' ;create for--@>ARRIVAL');
      END IF;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'ARRIVAL', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        --If there is a possibility , create an arrival visit
        --TYPE 7: Arrival Org :: no visit to cancel :: create an arrival visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 7 and before calling Create_Arrival_visit');
        END IF;
           l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
           l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
           l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
           l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Arrival_visit(
            p_oper_param_rec       => l_oper_param_rec,
            p_flight_schedule_rec  => l_flight_schedule_rec,
            p_present_time         => l_present_time,
            p_is_creation_success  => l_is_creation_success,
            x_return_status        => l_return_status,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data
            );

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
          END IF;

          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

      END IF; -- IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
      -- Go to end
    END If; --ELSIF l_visit_type = 'N'

  --If the flight schedule has any succeeding event then
  ELSE
   -- check if any of the arrival current flight visit or departure succeeding flight visit does not satisfy any of
   -- the criteria to be automatically cancelled.
   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' flight_schedule_rec.unit_config_header_id--@>'||flight_schedule_rec.unit_config_header_id||
                                                    ' ;flight_schedule_rec.arrival_org_id--@>'||flight_schedule_rec.arrival_org_id||
                                                    ' ;flight_schedule_rec.arrival_dept_id--@>'||flight_schedule_rec.arrival_dept_id||
                                                    ' ;flight_schedule_rec.flight_category_code--@>'||flight_schedule_rec.flight_category_code||
                                                    ' ;l_count_org--@>'||l_count_org||
                                                    ' ;l_count_dep--@>'||l_count_dep||
                                                    ' ;l_count_cat--@>'||l_count_cat||
                                                    ' ;create for--@>ARRIVAL');
   END IF;


   -- if departure visit of succ flight can not be cancelled and there is no visit associated to arrival org of current FS
   -- then look for the possibility of creating an arrival visit at arrival org of current FS
   IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL)) THEN
      -- check for the possibility of creating an arrival visit;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'ARRIVAL', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        -- if there is possibility of creating an arrival visit
        --TYPE 8: Arrival Org :: no visit to cancel :: create an arrival visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 8 and before calling Create_Arrival_visit');
        END IF;
        l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
        l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
        l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
        l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Arrival_visit(
            p_oper_param_rec       => l_oper_param_rec,
            p_flight_schedule_rec  => l_flight_schedule_rec,
            p_present_time         => l_present_time,
            p_is_creation_success  => l_is_creation_success,
            x_return_status        => l_return_status,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data
            );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
             ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
      END IF; -- IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
      -- Go to end
   END IF; --IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL)) THEN

   -- if both dep succ flight visit and arrival visit can be automatically cancelled
   IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
    --Get ground time at the arrival org of a FS
    OPEN get_ground_time (flight_schedule_rec.UNIT_SCHEDULE_ID, l_succeeding_us_id);
    FETCH get_ground_time INTO l_ground_time;
    CLOSE get_ground_time;

    IF substr (l_visit_type,1,1) <> 'T' THEN -- either no visit or arrival visit associated to the arrival org of current FS
      -- check for the possibility to create a downtime visit
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'DOWNTIME', l_ground_time);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      l_is_downtime_vst_created := 'Y';
      IF get_oper_param_rows1%FOUND THEN -- if there is possibiliy of creating a downtime visit
        IF l_visit_type = 'N' THEN   -- no visit associated to the arrival org of current FS
           IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 9');
           END IF;
           --TYPE 9: Arrival Org :: no visit of current FS to cancel :: create a downtime visit
           --cancel the departure visit of the succeeding flight if it is not null

           -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
           SAVEPOINT OPER_VISIT_CREATION;

           IF(l_visit_id2 is not null) then
               Delete_Oper_Visit(
                  p_visit_id       => l_visit_id2,
                  x_return_status  => l_return_status);
           END IF;--IF(l_visit_id2 is not null) then
           IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
           END IF;
           l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
           l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
           l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

           -- we need to create a downtime visit and associate to the arrival org of current flight, so pass current flight details
           Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

           IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
           END IF;

           IF l_is_creation_success<>'Y' THEN
              ROLLBACK TO OPER_VISIT_CREATION;
              l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
           END IF;
           -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        ELSIF substr (l_visit_type,1,1) = 'A' THEN -- there is an arrival visit associated to the arrival org of current FS
          -- If we can create a downtime visit and existing visit is an arrival visit, the check if visit type of the current visit matches with row visit type
          -- get the visit type code of the arrival visit
          OPEN get_visit_type_code(l_visit_id);
          FETCH get_visit_type_code INTO l_visit_type_code;
          CLOSE get_visit_type_code;
          IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
            --  if it does not match, then cancel the arrival visit with id 'l_visit_id'
            -- and create a downtime visit
            IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 10');
            END IF;
            --TYPE 10: Arrival Org :: cancel existing arrival visit :: create a downtime visit
             Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);

            --cancel the departure visit of the succeeding flight if it is not null
            IF(l_visit_id2 is not null) then
             Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
            END IF;--IF(l_visit_id2 is not null) then
            IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
            END IF;
            l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
            l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
            l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
            SAVEPOINT OPER_VISIT_CREATION;

            -- we need to create a downtime visit and associate to the arrival org of current flight, so pass current flight details
            Create_Downtime_visit(
             p_oper_param_rec         => l_oper_param_rec,
             p_flight_schedule_rec    => l_flight_schedule_rec,
             p_present_time           => l_present_time,
             p_is_creation_success    => l_is_creation_success,
             x_return_status          => l_return_status,
             x_msg_count              => l_msg_count,
             x_msg_data               => l_msg_data
             );
            IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
            END IF;

            IF l_is_creation_success<>'Y' THEN
              ROLLBACK TO OPER_VISIT_CREATION;
              l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
            END IF;
            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
          END IF; -- IF part of comparing visit types : IF substr (l_visit_type,3) <> get_oper_param_rec.visit_type_code
         -- Go to end
        END IF;  --IF l_visit_type = 'N' THEN
        CLOSE get_oper_param_rows1;
      ELSE --a downtime visit cannot be created
        CLOSE get_oper_param_rows1;
        l_is_downtime_vst_created := 'N';
      END IF;
      IF l_is_downtime_vst_created = 'N' THEN -- Downtime visit cannot be created, so check for availability of creating an arrival visit
        -- if there is no visit, then check for creation of arrival visit;
        IF l_visit_type = 'N' THEN -- no visit associated to the arrival org of current FS
          OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                    flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                    'ARRIVAL', NULL);
          FETCH get_oper_param_rows1 INTO get_oper_param_rec;
          IF get_oper_param_rows1%FOUND THEN
            --TYPE 11: Arrival Org :: no visit to cancel :: create an arrival visit
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 11 and before calling Create_Arrival_visit');
            END IF;
            l_oper_param_rec.visit_type_code  := get_oper_param_rec.visit_type_code;
            l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
            l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
            l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
            SAVEPOINT OPER_VISIT_CREATION;

            Create_Arrival_visit(
              p_oper_param_rec       => l_oper_param_rec,
              p_flight_schedule_rec  => l_flight_schedule_rec,
              p_present_time         => l_present_time,
              p_is_creation_success  => l_is_creation_success,
              x_return_status        => l_return_status,
              x_msg_count         => l_msg_count,
              x_msg_data          => l_msg_data
            );
            IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
            END IF;

            IF l_is_creation_success<>'Y' THEN
               ROLLBACK TO OPER_VISIT_CREATION;
            END IF;
            -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

          END IF; -- IF get_oper_param_rows1%FOUND THEN
          CLOSE get_oper_param_rows1; --added by tchimira for the bug 14008978 on 27-Apr-2012
        END IF; -- IF l_visit_type = 'N' THEN
        -- commented the below line by tchimira for bug 14008978 on 27-Apr-2012
        --CLOSE get_oper_param_rows1;
      END IF; --IF get_oper_param_rows1%FOUND for checking the possibility of creating a downtime visit

    ELSE -- existing visit is a downtime visit
      -- check for the possibility to create a downtime visit
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'DOWNTIME', l_ground_time);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        -- If we can create a downtime visit and existing visit is also a downtime visit, then check if visit type of the current visit matches with row visit type
        -- get the visit type code of the existing visit
        OPEN get_visit_type_code(l_visit_id);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
          -- if it does not match then cancel the existing downtime visit with id 'l_visit_id'
          -- and create a downtime visit
          IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 12 ');
          END IF;
          --TYPE 12: Arrival Org :: cancel existing downtime visit :: create a downtime visit
          Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          -- we need to create a downtime visit and associate to the arrival org of current flight, so pass current flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

           IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
           END IF;

           IF l_is_creation_success<>'Y' THEN
              ROLLBACK TO OPER_VISIT_CREATION;
           END IF;
           -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        END IF; -- IF substr (l_visit_type,3) <> get_oper_param_rec.visit_type_cod
        -- Go to end
      END IF; -- IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
    END IF; --IF substr (l_visit_type,1,1) <> 'T' THEN
   END IF;-- IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
  END IF; -- if there is any succeeding event

  --Update the Flight Schedule auto create status to 'R'
  UPDATE AHL_UNIT_SCHEDULES
  set AUTOVISIT_PROCESS_STATUS = 'R',
      OBJECT_VERSION_NUMBER = object_version_number + 1,
      LAST_UPDATE_DATE      = SYSDATE,
      LAST_UPDATED_BY       = Fnd_Global.USER_ID,
      LAST_UPDATE_LOGIN     = Fnd_Global.LOGIN_ID
  WHERE UNIT_SCHEDULE_ID    = flight_schedule_rec.UNIT_SCHEDULE_ID;
 END LOOP;

    ---------------------------End of Body-------------------------------------
    -- END of API body.
    -- Standard check of p_commit.

     IF Fnd_Api.To_Boolean (p_commit) THEN
        COMMIT WORK;
     END IF;

     Fnd_Msg_Pub.count_and_get(
           p_encoded => Fnd_Api.g_false,
           p_count   => x_msg_count,
           p_data    => x_msg_data
    );

    IF (l_log_procedure >= l_log_current_level) THEN
       fnd_log.string(l_log_procedure,
                      L_DEBUG_KEY ||'.end',
                      'At the end of PL SQL procedure. Return Status = ' || x_return_status);
    END IF;

EXCEPTION

 WHEN FND_API.G_EXC_ERROR THEN

   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Create_Oper_Visit_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Create_Oper_Visit_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Create_Oper_Visit_pvt;

    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Create_Oper_Visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;

    FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Create_Oper_Visit;

---------------------------------------------------------------------------------------
-- PROCEDURE
--    Get_Visit_Type
-- Type             : Public
-- PURPOSE
--    To find out whether visit associated to the organization is arrival or departure or downtime
----------------------------------------------------------------------------------------

PROCEDURE Get_Visit_Type(
    p_fs_id       IN         NUMBER,
    p_fs_type     IN         VARCHAR2,
    x_vst_typ     OUT NOCOPY VARCHAR2,
    x_visit_id    OUT NOCOPY NUMBER,
    x_visit_id2   OUT NOCOPY NUMBER
    )
IS
  -- To find out if there is any visit associated to the passed flight schedule
  -- Cursor to find our departure visit
  CURSOR c_is_visit_departure (c_fs_id IN NUMBER) IS
    SELECT visit.visit_type_code, visit.visit_id
    FROM ahl_visits_b visit, ahl_unit_schedules flight
    WHERE visit.unit_schedule_id = flight.unit_schedule_id
     AND visit.organization_id = flight.departure_org_id
     AND flight.unit_schedule_id = p_fs_id
     AND visit.status_code NOT IN ('DELETED','CANCELLED')
     AND ((NVL(visit.auto_visit_type_flag,'X') = 'D')--Departure --TCHIMIRA :: 14-Jun-2012 :: ER 14015560 ::added the condition
          OR (visit.auto_visit_type_flag IS NULL )); -- TCHIMIRA:: 28-Jun-2012 :: handle upgrade cases

  -- To find out if there is any visit associated to the passed flight schedule
  -- Cursor to find downtime visit at departure org
  CURSOR c_is_visit_downtime (c_fs_id IN NUMBER) IS
    SELECT visit.visit_type_code, visit.visit_id
    FROM ahl_visits_b visit, ahl_unit_schedules flight
    WHERE visit.unit_schedule_id = flight.preceding_us_id
      AND flight.unit_schedule_id = c_fs_id
      AND visit.organization_id = flight.departure_org_id
      AND visit.status_code NOT IN ('DELETED','CANCELLED')
      AND ((NVL(visit.auto_visit_type_flag,'X') = 'T')--Downtime --TCHIMIRA :: 14-Jun-2012 :: ER 14015560 ::added the condition
          OR (visit.auto_visit_type_flag IS NULL -- TCHIMIRA:: 28-Jun-2012 :: handle upgrade cases
	     AND TO_CHAR(visit.close_date_time,'DD-MON-YYYY HH24:MI') = TO_CHAR(flight.est_departure_time,'DD-MON-YYYY HH24:MI')));

  -- To find out if there is any visit associated to the passed flight schedule
  -- Cursor to find visit at arrival org
  CURSOR c_is_visit_arrival_or_dwntm (c_fs_id IN NUMBER) IS
    SELECT visit.visit_type_code, visit.visit_id,visit.AUTO_VISIT_TYPE_FLAG
    FROM ahl_visits_b visit, ahl_unit_schedules flight
    WHERE visit.unit_schedule_id = flight.unit_schedule_id
     and visit.organization_id = flight.arrival_org_id
     and flight.unit_schedule_id = p_fs_id
     AND visit.status_code NOT IN ('DELETED','CANCELLED')
     AND ((NVL(visit.auto_visit_type_flag,'X') IN ('A', 'T'))--TCHIMIRA :: 14-Jun-2012 :: ER 14015560 ::added the condition
          OR (visit.auto_visit_type_flag IS NULL )); -- TCHIMIRA:: 28-Jun-2012 :: handle upgrade cases

  -- Cursor to find visit at arrival org if AUTO_VISIT_TYPE_FLAG for the visit is null
  CURSOR c_is_visit_arr_or_dwntm_old (c_fs_id IN NUMBER) IS
    SELECT succ_flight.est_departure_time, visit.close_date_time, visit.visit_type_code, visit.visit_id
    FROM ahl_visits_b visit, ahl_unit_schedules flight, ahl_unit_schedules succ_flight
    WHERE visit.unit_schedule_id = flight.unit_schedule_id
     and visit.organization_id = flight.arrival_org_id
     and succ_flight.preceding_us_id(+) = flight.unit_schedule_id
     and flight.unit_schedule_id = p_fs_id
     AND visit.status_code NOT IN ('DELETED','CANCELLED')
     AND flight.est_arrival_time = visit.start_date_time; --JROTICH :: 11-July-2012 added this condition to rule out same org departure visits

  -- Cursor to find if there is any arrival visit associated to the preceeding flight
  Cursor c_get_arr_vst_of_prec_flt (c_fs_id IN NUMBER)
  IS
    SELECT visit.visit_id
    FROM ahl_visits_b visit, ahl_unit_schedules flight, ahl_unit_schedules pre_flight
    WHERE visit.unit_schedule_id = pre_flight.unit_schedule_id
      AND flight.unit_schedule_id = c_fs_id
      AND flight.preceding_us_id  = pre_flight.unit_schedule_id
      AND visit.organization_id = flight.departure_org_id
      AND visit.status_code NOT IN ('DELETED','CANCELLED')
      AND ((NVL(visit.auto_visit_type_flag,'X') = 'A')--TCHIMIRA :: 14-Jun-2012 :: ER 14015560 ::added the condition
           OR (visit.auto_visit_type_flag IS NULL
           AND flight.est_departure_time <> visit.close_date_time)); -- TCHIMIRA:: 28-Jun-2012 :: handle upgrade cases

  -- Cursor to find if there is any departure visit associated to the succeeding flight
  Cursor c_get_dep_vst_of_succ_flt (c_fs_id IN NUMBER)
  IS
    SELECT visit.visit_id
    FROM ahl_visits_b visit, ahl_unit_schedules flight, ahl_unit_schedules succ_flight
    WHERE visit.unit_schedule_id = succ_flight.unit_schedule_id
     and visit.organization_id = flight.arrival_org_id
     and succ_flight.preceding_us_id = flight.unit_schedule_id
     and flight.unit_schedule_id = p_fs_id
     AND visit.status_code NOT IN ('DELETED','CANCELLED')
     AND ((NVL(visit.auto_visit_type_flag,'X') = 'D')--TCHIMIRA :: 14-Jun-2012 :: ER 14015560 ::added the condition
            OR (visit.auto_visit_type_flag IS NULL
            AND TO_CHAR(succ_flight.est_departure_time,'DD-MON-YYYY HH24:MI') = TO_CHAR(visit.close_date_time,'DD-MON-YYYY HH24:MI')
            AND flight.est_arrival_time <> visit.start_date_time )); -- TCHIMIRA:: 28-Jun-2012 :: handle upgrade cases

  l_auto_visit_type_flag    VARCHAR2(1); --TCHIMIRA :: 14-Jun-2012 :: ER 14015560
  l_visit_type         VARCHAR2(40):= 'N'; -- No visit associated
  L_API_NAME           CONSTANT VARCHAR2(30) := 'Get_Visit_Type';
  L_DEBUG_KEY          CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
  l_vt_code         VARCHAR2(30);
  l_succ_flight_dep_date DATE;
  l_visit_end_date       DATE;

BEGIN

   IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.begin',
                     'At the start of PL SQL function.');
   END IF;

   IF (l_log_statement >= l_log_current_level) THEN
      fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Flight schedule id: ' || p_fs_id||' , type: '||p_fs_type);
   END IF;

   IF p_fs_type = 'P' THEN  -- we are processing visits associated to the departure org of the flight schedule
     OPEN c_is_visit_departure (p_fs_id);
     FETCH c_is_visit_departure INTO l_vt_code, x_visit_id;
     IF c_is_visit_departure%FOUND THEN
       l_visit_type := 'D' || l_vt_code; --It is Departure visit
     ELSE
       OPEN c_is_visit_downtime (p_fs_id);
       FETCH c_is_visit_downtime INTO l_vt_code, x_visit_id2; --downtime visit ID
       IF c_is_visit_downtime%FOUND THEN
         l_visit_type := 'T' || l_vt_code; --It is Downtime visit
       ELSE
         l_visit_type := 'N'; -- there is no visit
       END IF;
       CLOSE c_is_visit_downtime;
     END IF;
     CLOSE c_is_visit_departure;
     -- if there is no downtime visit associated to the arrival org of prec FS,
     -- then check if there is an arrival visit.
     IF x_visit_id2 is null then
      OPEN c_get_arr_vst_of_prec_flt (p_fs_id);
      FETCH c_get_arr_vst_of_prec_flt INTO x_visit_id2; --arrival visit ID
      CLOSE c_get_arr_vst_of_prec_flt;
     END IF;

   ELSIF p_fs_type = 'S' THEN  -- we are processing visits associated to the arrival org of the flight schedule
     OPEN c_is_visit_arrival_or_dwntm (p_fs_id);
     FETCH c_is_visit_arrival_or_dwntm INTO l_vt_code, x_visit_id,l_auto_visit_type_flag;
     IF c_is_visit_arrival_or_dwntm%FOUND THEN
         l_visit_type := l_auto_visit_type_flag || l_vt_code;
     ELSE
        l_visit_type := 'N'; -- there is no visit
     END IF;
     CLOSE c_is_visit_arrival_or_dwntm;

     -- the following code handles cases where auto visit type flag is null;
     -- if the flag is null, the get assoicated visits based on time and organization match
     IF l_auto_visit_type_flag IS NULL THEN
       OPEN c_is_visit_arr_or_dwntm_old (p_fs_id);
       FETCH c_is_visit_arr_or_dwntm_old INTO l_succ_flight_dep_date, l_visit_end_date, l_vt_code, x_visit_id;
       IF c_is_visit_arr_or_dwntm_old%FOUND THEN
         IF TO_CHAR(l_succ_flight_dep_date,'DD-MON-YYYY HH24:MI') = TO_CHAR(l_visit_end_date,'DD-MON-YYYY HH24:MI') THEN
           l_visit_type := 'T ' || l_vt_code;--It is Downtime visit
         ELSE
           l_visit_type := 'A ' || l_vt_code;--It is arrival visit
         END IF;
       ELSE
          l_visit_type := 'N'; -- there is no visit
       END IF;
       CLOSE c_is_visit_arr_or_dwntm_old;
     END IF;

     -- if there is no downtime visit associated to the arrival org of current FS,
     -- then check if there is an dep visit at succ FS.
     IF NVL(l_auto_visit_type_flag, 'X') <> 'T' THEN
      OPEN c_get_dep_vst_of_succ_flt (p_fs_id);
      FETCH c_get_dep_vst_of_succ_flt INTO x_visit_id2;
      CLOSE c_get_dep_vst_of_succ_flt;
     END IF;
   END IF;

   IF (l_log_statement >= l_log_current_level) THEN
      fnd_log.string(l_log_statement,L_DEBUG_KEY, ' l_visit_type = ' || l_visit_type||',x_visit_id: '||x_visit_id||', x_visit_id2: '||x_visit_id2);
   END IF;

   IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.end',
                     'At the end of PL SQL function.');
   END IF;
   x_vst_typ := l_visit_type;

END Get_Visit_Type;

----------------------------------------------------------------------------------------------------------------
--  Procedure name    : Update_Oper_Visit
--  Type              : Private
--  Function          : Procedure to Update visit based on operational params
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version      IN  NUMBER        Required
--      p_init_msg_list    IN  VARCHAR2      Default  FND_API.G_FALSE
--      p_validation_level IN  NUMBER        Default  FND_API.G_VALID_LEVEL_FULL
--
--  Standard OUT Parameters :
--      x_return_status    OUT VARCHAR2      Required
--      x_msg_count        OUT NUMBER        Required
--      x_msg_data         OUT VARCHAR2      Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Update_Oper_Visit (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2)IS

-- Local Variables

-- Standard in/out parameters
l_api_name                    VARCHAR2(30) := 'Update_Oper_Visit';
l_api_version                 NUMBER       := 1.0;
l_debug_key          CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
l_msg_count                   NUMBER;
l_msg_data                    VARCHAR2(2000);
l_return_status               VARCHAR2(1);
l_init_msg_list               VARCHAR2(10):= p_init_msg_list;
l_visit_type                  VARCHAR2(40);
l_visit_id                    NUMBER;
l_visit_rec                   AHL_VWP_VISITS_PVT.Visit_Rec_Type;
l_start_date                  DATE;
l_end_date                    DATE;
l_visit_type_duration         NUMBER;
l_visit_id2                   NUMBER;
l_visit_end_time              DATE;
l_visit_type_code             VARCHAR2(30);
l_flag                        VARCHAR2(1) := 'N';
l_visit_start_time            DATE;
l_difference_dep_time         NUMBER;
l_difference_arrival_time     NUMBER;
l_profile_varchar             VARCHAR2(100);
l_profile_number              NUMBER;
l_profile_varchar2            VARCHAR2(100);
l_profile_number2             NUMBER;
l_count_prec_arr_org          NUMBER;
l_count_prec_arr_dep          NUMBER;
l_count_prec_arr_cat          NUMBER;
x_item_key                    VARCHAR2(100);
l_can_cancel_visit            VARCHAR2(1);
l_can_cancel_visit2           VARCHAR2(1);
l_can_update_visit            VARCHAR2(1); -- added by tchimira for bug 13844759
l_flight_schedule_rec         flight_schedule_rec_type;
l_oper_param_rec              oper_param_rec_type;
l_prec_flight_schedule_rec    flight_schedule_rec_type;
l_present_time                DATE := SYSDATE; -- Bug 14336467 :: PRAKKUM :: 13/07/2012
l_is_creation_success         VARCHAR2(1) := 'Y'; -- Bug 14336467 :: PRAKKUM :: 13/07/2012
l_is_downtime_vst_created     VARCHAR2(1) := 'Y'; -- Bug 14336467 :: PRAKKUM :: 13/07/2012
l_can_disconnect_visit        VARCHAR2(1) := 'N'; -- Bug 14368696 :: PRAKKUM :: 01/08/2012

-- Cursor to find the visit numbers from visit_ids
CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

-- Cursor to get all the flight schedule records whose status is 'Updated'
Cursor get_flight_schedule_rows(c_status IN VARCHAR2)
IS
SELECT *
FROM AHL_UNIT_SCHEDULES
WHERE AUTOVISIT_PROCESS_STATUS = c_status;

--Get the count of rows matching with the UC and org of the flight schedule and enabled_flag as Y
Cursor get_non_null_org_count (c_uc_id IN NUMBER, c_org_id IN NUMBER)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id;
 l_count_org NUMBER;

--Get the count of rows matching with the UC, org and dep of the flight schedule and enabled_flag as Y
Cursor get_non_null_dep_count (c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id
 AND op.department_id = c_dep_id;
 l_count_dep NUMBER;

--Get the count of rows matching with the UC, org, dep and category of the flight schedule and enabled_flag as Y
Cursor get_non_null_cat_count (c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER, c_flight_cat IN VARCHAR2)
IS
SELECT count (*)
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
WHERE op.enabled_flag = 'Y'
 AND uc.unit_config_header_id = c_uc_id
 AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
 AND op.organization_id = c_org_id
 AND op.department_id = c_dep_id
 AND op.flight_category_code = c_flight_cat;
 l_count_cat NUMBER;

-- Get the ground time (in number of hours) between two flight schedules
Cursor get_ground_time (c_prev_fs_id IN NUMBER, c_succ_fs_id IN NUMBER)
IS
SELECT to_number((succ_fs.EST_DEPARTURE_TIME - prev_fs.EST_ARRIVAL_TIME)*24*60)
FROM AHL_UNIT_SCHEDULES prev_fs, AHL_UNIT_SCHEDULES succ_fs
WHERE prev_fs.UNIT_SCHEDULE_ID = c_prev_fs_id
 AND succ_fs.UNIT_SCHEDULE_ID = c_succ_fs_id;
 l_ground_time NUMBER;

--Cursor to fetch operational param rows whose enabled flag is Y and matches master config
Cursor get_oper_param_rows1(c_uc_id IN NUMBER, c_org_id IN NUMBER, c_dep_id IN NUMBER, c_cat_code IN VARCHAR2,
                            c_org_count IN NUMBER, c_dep_count IN NUMBER, c_cat_count IN NUMBER,
                            c_create_for IN VARCHAR2, c_ground_time IN NUMBER)
IS
SELECT op.*
FROM ahl_oper_vst_autocreate op, ahl_unit_config_headers uc
 WHERE op.enabled_flag = 'Y'
   AND uc.unit_config_header_id = c_uc_id
   AND (select mc_id from ahl_mc_headers_b where mc_header_id = uc.master_config_id) = op.mc_id
   AND ( (op.organization_id = c_org_id)
        OR ( c_org_count = 0 -- there are no non-null org rows meeting mc and enabled_flag
             AND op.organization_id IS NULL))
   AND ( ( c_org_count = 0 )
            OR (op.department_id = c_dep_id)
            OR ( c_dep_count = 0
                 AND op.department_id IS NULL))
   AND ( (op.flight_category_code = c_cat_code)
            OR ( ((c_cat_count = 0) OR ( c_cat_code IS NULL))
                 AND op.flight_category_code IS NULL))
   AND op.create_for = c_create_for
   -- if create_for is not downtime, pass null as c_ground_time to this cursor
   AND ( (c_ground_time IS NULL)
         OR (c_ground_time BETWEEN op.START_TIME AND NVL(op.END_TIME,c_ground_time)));
get_oper_param_rec get_oper_param_rows1%ROWTYPE;

--curosr that checks if there is any succeeding flight for this flight schedule
Cursor get_succeeding_us_det (c_fs_id IN NUMBER)
 IS
 SELECT UNIT_SCHEDULE_ID, EST_DEPARTURE_TIME FROM AHL_UNIT_SCHEDULES
 WHERE  preceding_us_id = c_fs_id;
l_succeeding_us_id NUMBER;
l_succ_dep_time DATE;

Cursor get_visit_type_duration(c_visit_type_code IN VARCHAR2, c_mc_id IN NUMBER)
IS
SELECT estimated_duration
FROM ahl_visit_types_b
WHERE visit_type_code = c_visit_type_code
 AND mc_id = c_mc_id
 AND status_code = 'COMPLETE';

Cursor get_fs_arr_time (c_fs_id IN NUMBER)
IS
SELECT EST_ARRIVAL_TIME
FROM AHL_UNIT_SCHEDULES
WHERE UNIT_SCHEDULE_ID = c_fs_id;

-- Cursor to get all the associated visits for the passed flight schedule
Cursor get_assoc_visits(c_flight_schedule_id IN NUMBER)
IS
SELECT visit_id, organization_id, locked_flag, firmed_flag, status_code, start_date_time, close_date_time,AUTO_VISIT_TYPE_FLAG
FROM AHL_VISITS_B
WHERE UNIT_SCHEDULE_ID = C_FLIGHT_SCHEDULE_ID
AND status_code NOT IN ('DELETED','CANCELLED')
ORDER BY visit_id asc; --added this condition by tchimira for bug 13828335

-- Cursor to get visit end time
Cursor get_visit_end_time(c_visit_id IN NUMBER)
IS
SELECT close_date_time
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id;

-- Cursor to get preceeding flight schedule details
Cursor get_pre_fs_det(c_unit_schedule_id IN NUMBER)
IS
SELECT *
FROM AHL_UNIT_SCHEDULES
WHERE UNIT_SCHEDULE_ID = c_unit_schedule_id;
pre_fs_det_rec get_pre_fs_det%ROWTYPE;

-- Cursor to get visit type of a visit
Cursor get_visit_type_code(c_visit_id IN NUMBER)
IS
SELECT visit_type_code
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id;

-- Cursor to get visit start time
Cursor get_visit_start_time(c_visit_id IN NUMBER)
IS
SELECT start_date_time
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id;

-- To find visit related information
CURSOR c_Visit(c_visit_id IN NUMBER) IS
SELECT * FROM   Ahl_Visits_VL
WHERE  VISIT_ID = c_visit_id;

c_Visit_rec    c_Visit%ROWTYPE;

--To get visit type duration of a given visit
--Modified the below cursor by tchimira as a fix for issue 1 in the bug 13777327 on 01-Mar-2012
CURSOR c_Visit_type_dur(c_visit_id IN NUMBER) IS
SELECT vtyp.estimated_duration
FROM  ahl_visit_types_b vtyp, ahl_visits_b visit, ahl_unit_config_headers unit, ahl_mc_headers_b mc
WHERE  visit.visit_id = c_visit_id
 AND vtyp.visit_type_code = visit.visit_type_code
 AND unit.csi_item_instance_id = visit.item_instance_id
 AND unit.master_config_id = mc.mc_header_id
 AND vtyp.mc_id = mc.mc_id
 AND vtyp.status_code = 'COMPLETE';

--Cursor to find if the visit is in planning status and not firmed and not locked
-- if all the conditions match, then the visit can be updated or cancelled
Cursor can_cancel_visit(c_visit_id IN NUMBER)
IS
SELECT 'X'
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id
 AND STATUS_CODE = 'PLANNING'
 AND NVL(FIRMED_FLAG,'N') <> 'Y'
 AND NVL(LOCKED_FLAG,'N') <> 'Y';

Cursor is_org_in_current_OU (c_org_id IN NUMBER)
IS
SELECT 'X'
FROM org_organization_definitions hou
WHERE hou.organization_id                                  = c_org_id
AND NVL(hou.operating_unit,mo_global.get_current_org_id()) = mo_global.get_current_org_id();
l_is_org_in_curr_OU VARCHAR2(1);

BEGIN

 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level)THEN
      fnd_log.string
      (
        fnd_log.level_procedure,
       'ahl.plsql.AHL_AVF_OPER_VSTS_PVT.Update_Oper_Visit.begin',
       'At the start of PLSQL procedure'
      );
 END IF;

 -- Standard start of API savepoint
 SAVEPOINT Update_Oper_Visit_pvt;

 -- Initialize message list if p_init_msg_list is set to TRUE

 IF FND_API.To_Boolean( p_init_msg_list) THEN
   FND_MSG_PUB.Initialize;
 END IF;

 -- Initialize API return status to success
 x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Standard call to check for call compatibility.
 IF NOT Fnd_Api.COMPATIBLE_API_CALL(l_api_version,
                                    p_api_version,
                                    l_api_name,G_PKG_NAME)
 THEN
   RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
 END IF;

 l_profile_varchar :=  FND_PROFILE.VALUE('AHL_AVF_VST_UPD_FLT_TIME');
 l_profile_varchar2 :=  FND_PROFILE.VALUE('AHL_AVF_FLT_VST_UPD_WINDOW');

 -- Loop through all the flight schedule records whose status is Updated.
 FOR flight_schedule_rec IN get_flight_schedule_rows('U') LOOP
  -- store all the flight params in the record
  l_flight_schedule_rec.unit_config_header_id := flight_schedule_rec.unit_config_header_id;
  l_flight_schedule_rec.departure_org_id := flight_schedule_rec.departure_org_id;
  l_flight_schedule_rec.departure_dept_id := flight_schedule_rec.departure_dept_id;
  l_flight_schedule_rec.unit_schedule_id := flight_schedule_rec.unit_schedule_id;
  l_flight_schedule_rec.est_departure_time := flight_schedule_rec.est_departure_time;
  l_flight_schedule_rec.arrival_org_id := flight_schedule_rec.arrival_org_id;
  l_flight_schedule_rec.arrival_dept_id := flight_schedule_rec.arrival_dept_id;
  l_flight_schedule_rec.est_arrival_time := flight_schedule_rec.est_arrival_time;

  -- For each flight schedule, get all the visits IDs associated
  FOR assoc_visits_rec IN get_assoc_visits(flight_schedule_rec.UNIT_SCHEDULE_ID) LOOP
      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, 'assoc_visits_rec.visit_id is: '||assoc_visits_rec.visit_id||
        ', assoc_visits_rec.AUTO_VISIT_TYPE_FLAG: '||assoc_visits_rec.AUTO_VISIT_TYPE_FLAG||', assoc_visits_rec.organization_id: '||assoc_visits_rec.organization_id
        ||', flight_schedule_rec.departure_org_id: '||flight_schedule_rec.departure_org_id||', flight_schedule_rec.arrival_org_id: '||flight_schedule_rec.arrival_org_id);
      END IF;


    -- For the visit fetched above, see if the visits organization matches with either departing or arrival org
    -- of the flight schedule;
    IF (((assoc_visits_rec.organization_id <> flight_schedule_rec.departure_org_id) AND (assoc_visits_rec.AUTO_VISIT_TYPE_FLAG = 'D'))
            OR ((assoc_visits_rec.organization_id <> flight_schedule_rec.arrival_org_id) AND (assoc_visits_rec.AUTO_VISIT_TYPE_FLAG IN ('A', 'T'))))
      THEN

      --If there is no match then cancel the visit;
      --Cancel the visit only if it is not firm or locked and is in planning status
      IF(assoc_visits_rec.locked_flag <> 'Y' AND assoc_visits_rec.firmed_flag <> 'Y' AND assoc_visits_rec.status_code = 'PLANNING') THEN
        Delete_Oper_Visit(
               p_visit_id       => assoc_visits_rec.visit_id,
               x_return_status  => l_return_status);

      -- If the visit is either firm/locked or not in planning status then disassociate the visit from the flight schedule
      ELSE
        --PRAKKUM :: 01/08/2012 :: Added procedure :: START
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'inside else assoc_visits_rec.visit_id is: '||assoc_visits_rec.visit_id);
        END IF;

        Disconnect_Flight_Visit(
            p_visit_id               => assoc_visits_rec.visit_id,
            p_unit_schedule_id       => flight_schedule_rec.UNIT_SCHEDULE_ID,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );
        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
        END IF;

        IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
         x_msg_count := l_msg_count;
         x_return_status := l_return_status;
         IF l_return_status = Fnd_Api.g_ret_sts_error THEN
           RAISE Fnd_Api.g_exc_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
           RAISE Fnd_Api.g_exc_unexpected_error;
         END IF;
        END IF;
       --PRAKKUM :: 01/08/2012 :: Added procedure :: END
      END IF; -- Check before cancelling the visit
    END IF; --IF condition to compare the organization of the visit with FS orgs
  END LOOP; -- Loop of all the visits associated to the FS

  -- Now we have handled all the scenarios where the organization of the FS is updated. Next step is to look into
  -- the departure and arrival timings update
  -- CASE I: First consider the departing org of the flight schedule record
  IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'CASE 1, flight_schedule_rec.unit_schedule_id= '||flight_schedule_rec.unit_schedule_id );
  END IF;

  OPEN get_non_null_org_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id);
  FETCH get_non_null_org_count INTO l_count_org;
  CLOSE get_non_null_org_count;

  OPEN get_non_null_dep_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                              flight_schedule_rec.departure_dept_id);
  FETCH get_non_null_dep_count INTO l_count_dep;
  CLOSE get_non_null_dep_count;

  OPEN get_non_null_cat_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                              flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code);
  FETCH get_non_null_cat_count INTO l_count_cat;
  CLOSE get_non_null_cat_count;


  -- check if there exisits a visit and if yes, get the visit details
  AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'P', l_visit_type, l_visit_id,l_visit_id2);

  --If the flight schedule does not have any preceeding event then
  IF ( flight_schedule_rec.preceding_us_id IS NULL ) THEN
    IF substr (l_visit_type,1,1) = 'D' THEN --there is a visit at the departing org of the current FS
      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' There is an existing departure visit at dep org, do nothing');
      END IF;
      -- based on the profile value see if you can adjust the visit dates
      OPEN get_visit_end_time(l_visit_id);
      FETCH get_visit_end_time INTO l_visit_end_time;
      CLOSE get_visit_end_time;

      OPEN c_Visit_type_dur (l_visit_id);
      FETCH c_Visit_type_dur INTO l_visit_type_duration;
      CLOSE c_Visit_type_dur;
      -- Added the below code to see if the visit can be updated or not : tchimira: bug 13844759
      l_can_update_visit := null;
      OPEN can_cancel_visit(l_visit_id);
      FETCH can_cancel_visit INTO l_can_update_visit;
      CLOSE can_cancel_visit;

      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_visit_end_time is: '||l_visit_end_time||' ,est_departure_time: '||flight_schedule_rec.est_departure_time||', l_can_update_visit is: '||l_can_update_visit);
      END IF;

      IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
        l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
      ELSE
        l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
      END IF;

      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_dep_time is: '||l_difference_dep_time);
      END IF;

      IF  l_profile_varchar is not null  THEN
      l_profile_number := to_number(l_profile_varchar) ;
      ELSE
      l_profile_number := l_difference_dep_time-1;
      END IF;

      IF  l_profile_varchar2 is not null THEN
      l_profile_number2 := to_number(l_profile_varchar2) ;
      ELSE
      l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
      END IF;

      IF((l_difference_dep_time > l_profile_number)
         AND (l_difference_dep_time <> 0)
         AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN
       -- TCHIMIRA : Bug 13844759 : check if the visit is updateable.
       -- if yes, the update the visit else diconnect the visit
       IF l_can_update_visit IS NOT NULL THEN
        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Before type 1 ');
        END IF;
        --TYPE 1: Departure Org :: dep visit at dep org of current FS :: Update the departure visit dates
        l_start_date := (flight_schedule_rec.est_departure_time - l_visit_type_duration/24);
        l_end_date := flight_schedule_rec.est_departure_time;

        l_visit_rec := null;
        l_visit_rec.START_DATE            := l_start_date;
        l_visit_rec.PLAN_END_DATE         := l_end_date;
        l_visit_rec.visit_id              := l_visit_id;

        OPEN c_Visit(l_visit_id);
        FETCH c_Visit INTO c_Visit_rec;
        IF c_Visit%NOTFOUND THEN
          CLOSE c_Visit;
          IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
             Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
             Fnd_Msg_Pub.ADD;
             IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
               fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
             END IF;
          END IF;
          RAISE Fnd_Api.g_exc_error;
        ELSE
          CLOSE c_Visit;
        END IF;
        -- Complete Visit Record
        l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
        l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
        l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
        l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
        l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
        l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
        l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
        l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
        l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
        l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
        l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
        l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
        l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG; --TCHIMIRA :: 14-Jun-2012 :: ER 14015560

        -- PRAKKUM :: 14/10/2014 :: PA ENH
        l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
        l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
        l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
        l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
        l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

        IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string
                    ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id||', l_visit_rec.START_DATE: '||l_visit_rec.START_DATE);
        END IF;
        AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

        IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string
                    ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
        END IF;
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          x_msg_count := FND_MSG_PUB.count_msg;
          IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,
                             L_DEBUG_KEY,
                             'Errors from Update_Visit. Message count: ' || x_msg_count);
          END IF;
          IF l_return_status = FND_API.G_RET_STS_ERROR THEN
             RAISE FND_API.G_EXC_ERROR;
          ELSE
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
        END IF;  -- Return Status is not Success
       ELSE
        --PRAKKUM :: 01/08/2012 :: Added procedure :: START
        Disconnect_Flight_Visit(
            p_visit_id               => l_visit_id,
            p_unit_schedule_id       => flight_schedule_rec.UNIT_SCHEDULE_ID,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );
        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
        END IF;

        IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
         x_msg_count := l_msg_count;
         x_return_status := l_return_status;
         IF l_return_status = Fnd_Api.g_ret_sts_error THEN
           RAISE Fnd_Api.g_exc_error;
         ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
           RAISE Fnd_Api.g_exc_unexpected_error;
         END IF;
        END IF;
        --PRAKKUM :: 01/08/2012 :: Added procedure :: END
       END IF; --IF condition to see if l_can_update_visit IS NOT NULL
      END IF;  -- IF condition to see if the visit dates has to be updated or not.
    END IF; --IF substr (l_visit_type,1,1) = 'D'

    -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: START
    -- Before this, previous visits can be cancelled so fetch details again
    -- check if there exisits a visit and if yes, what visit type - either arrival or downtime
    AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'P', l_visit_type, l_visit_id,l_visit_id2);

    l_can_update_visit := null;
    IF l_visit_id IS NOT NULL THEN
      OPEN can_cancel_visit(l_visit_id);
      FETCH can_cancel_visit INTO l_can_update_visit;
      CLOSE can_cancel_visit;
    END IF;
    -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: END

    -- TCHIMIRA : Bug 13844759 : 29 - Mar - 2012
    -- If there is no departure visit, look for the possibility of creating one
    IF ((substr (l_visit_type,1,1) <> 'D')OR ( l_can_update_visit IS NULL)) THEN
      -- check for the possibility of creating a departure visit;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org,
                                l_count_dep, l_count_cat,'DEPARTURE', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Type 2 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
        END IF;
        -- there is a possibility to create a departure visit
        --TYPE 2: Departure Org :: no dep visit associated to current FS dep org :: create a departure visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 2 and before calling Create_Departure_visit');
        END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

            Create_Departure_visit(
              p_oper_param_rec         => l_oper_param_rec,
              p_flight_schedule_rec    => l_flight_schedule_rec,
              p_present_time           => l_present_time,
              p_is_creation_success    => l_is_creation_success,
              x_return_status          => l_return_status,
              x_msg_count              => l_msg_count,
              x_msg_data               => l_msg_data
            );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
             ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

      END IF; --IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
      -- Go to arrival org consideration
    END IF; -- if condition to check the if there is no departure visit

  --If the flight schedule has a preceeding event then
  ELSE
   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data

      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   OPEN get_pre_fs_det(flight_schedule_rec.preceding_us_id);
   FETCH get_pre_fs_det INTO pre_fs_det_rec;
   CLOSE get_pre_fs_det;
   -- store all the preceding flight params in the record
   l_prec_flight_schedule_rec := null;
   l_prec_flight_schedule_rec.unit_config_header_id := flight_schedule_rec.unit_config_header_id;
   l_prec_flight_schedule_rec.unit_schedule_id      := pre_fs_det_rec.unit_schedule_id;
   l_prec_flight_schedule_rec.arrival_org_id        := pre_fs_det_rec.arrival_org_id;
   l_prec_flight_schedule_rec.arrival_dept_id       := pre_fs_det_rec.arrival_dept_id;
   l_prec_flight_schedule_rec.est_arrival_time      := pre_fs_det_rec.est_arrival_time;

   -- PRAKKUM :: Bug 13844759 :: 25/07/2012
   -- If existing visit is departure visit, then see whether it needs to be updated or disassociate
   IF substr (l_visit_type,1,1) = 'D' THEN -- if there is a visit
      IF l_visit_id IS NOT NULL THEN

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, ' There is an existing departure visit at dep org, do nothing');
          END IF;
          -- based on the profile value see if you can adjust the visit dates
          OPEN get_visit_end_time(l_visit_id);
          FETCH get_visit_end_time INTO l_visit_end_time;
          CLOSE get_visit_end_time;

          OPEN c_Visit_type_dur (l_visit_id);
          FETCH c_Visit_type_dur INTO l_visit_type_duration;
          CLOSE c_Visit_type_dur;
          -- Added the below code to see if the visit can be updated or not : tchimira: bug 13844759
          l_can_update_visit := null;
          OPEN can_cancel_visit(l_visit_id);
          FETCH can_cancel_visit INTO l_can_update_visit;
          CLOSE can_cancel_visit;

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_visit_end_time is: '||l_visit_end_time||' ,est_departure_time: '||flight_schedule_rec.est_departure_time||', l_can_update_visit is: '||l_can_update_visit);
          END IF;

          IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
            l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
          ELSE
            l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
          END IF;

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_dep_time is: '||l_difference_dep_time);
          END IF;

          IF  l_profile_varchar is not null  THEN
          l_profile_number := to_number(l_profile_varchar) ;
          ELSE
          l_profile_number := l_difference_dep_time-1;
          END IF;

          IF  l_profile_varchar2 is not null THEN
          l_profile_number2 := to_number(l_profile_varchar2) ;
          ELSE
          l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
          END IF;

          IF((l_difference_dep_time > l_profile_number)
             AND (l_difference_dep_time <> 0)
             AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN
           -- TCHIMIRA : Bug 13844759 : check if the visit is updateable.
           -- if yes, the update the visit else diconnect the visit
           IF l_can_update_visit IS NOT NULL THEN
            IF (l_log_statement >= l_log_current_level) THEN
               fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Before type 1 ');
            END IF;
            --TYPE 1: Departure Org :: dep visit at dep org of current FS :: Update the departure visit dates
            l_start_date := (flight_schedule_rec.est_departure_time - l_visit_type_duration/24);
            l_end_date := flight_schedule_rec.est_departure_time;

            l_visit_rec := null;
            l_visit_rec.START_DATE            := l_start_date;
            l_visit_rec.PLAN_END_DATE         := l_end_date;
            l_visit_rec.visit_id              := l_visit_id;

            OPEN c_Visit(l_visit_id);
            FETCH c_Visit INTO c_Visit_rec;
            IF c_Visit%NOTFOUND THEN
              CLOSE c_Visit;
              IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
                 Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
                 Fnd_Msg_Pub.ADD;
                 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
                 END IF;
              END IF;
              RAISE Fnd_Api.g_exc_error;
            ELSE
              CLOSE c_Visit;
            END IF;
            -- Complete Visit Record
            l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
            l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
            l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
            l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
            l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
            l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
            l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
            l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
            l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
            l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
            l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
            l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
            l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG; --TCHIMIRA :: 14-Jun-2012 :: ER 14015560

            -- PRAKKUM :: 14/10/2014 :: PA ENH
            l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
            l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
            l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
            l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
            l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                       fnd_log.string
                        ( fnd_log.level_procedure,
                         'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                         'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id||', l_visit_rec.START_DATE: '||l_visit_rec.START_DATE);
            END IF;
            AHL_VWP_VISITS_PVT.Update_Visit (
                                          p_api_version => l_api_version,
                                          p_init_msg_list => Fnd_Api.g_false,
                                          p_commit => Fnd_Api.g_false,
                                          p_validation_level => p_validation_level,
                                          p_module_type => 'API',
                                          p_x_visit_rec  => l_visit_rec,
                                          x_return_status => l_return_status,
                                          x_msg_count => l_msg_count,
                                          x_msg_data => l_msg_data
                                         );

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                       fnd_log.string
                        ( fnd_log.level_procedure,
                         'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                         'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
            END IF;
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
              x_msg_count := FND_MSG_PUB.count_msg;
              IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,
                                 L_DEBUG_KEY,
                                 'Errors from Update_Visit. Message count: ' || x_msg_count);
              END IF;
              IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                 RAISE FND_API.G_EXC_ERROR;
              ELSE
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
            END IF;  -- Return Status is not Success
           ELSE
             --PRAKKUM :: 01/08/2012 :: Added procedure :: START
             Disconnect_Flight_Visit(
                p_visit_id               => l_visit_id,
                p_unit_schedule_id       => flight_schedule_rec.UNIT_SCHEDULE_ID,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data
             );
             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
             END IF;

             IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
              x_msg_count := l_msg_count;
              x_return_status := l_return_status;
              IF l_return_status = Fnd_Api.g_ret_sts_error THEN
                RAISE Fnd_Api.g_exc_error;
              ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
                RAISE Fnd_Api.g_exc_unexpected_error;
              END IF;
             END IF;
             --PRAKKUM :: 01/08/2012 :: Added procedure :: END
             l_visit_id := NULL; --Since visit is cancelled

           END IF; --IF condition to see if l_can_update_visit IS NOT NULL
          END IF;  -- IF condition to see if the visit dates has to be updated or not.
       END IF; -- l_visit_id IS NOT NULL
   END IF; -- substr (l_visit_type,1,1) = 'D'

   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   -- Recheck to confirm if any visit is disaasociated
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   -- PRAKKUM :: Bug 14368696 :: 01/08/2012 :: START
   IF (l_can_cancel_visit2 IS NULL) THEN -- If downtime or arrival is not allowed to cancel
       IF substr (l_visit_type,1,1) = 'T' AND l_visit_id2 IS NOT NULL THEN --Downtime visit exists

        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Handle case that downtime visit not allowed to cancel--@>');
        END IF;

        --Get ground time at the departing org of a FS
        OPEN get_ground_time (flight_schedule_rec.preceding_us_id, flight_schedule_rec.UNIT_SCHEDULE_ID);
        FETCH get_ground_time INTO l_ground_time;
        CLOSE get_ground_time;

        OPEN get_non_null_org_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id);
        FETCH get_non_null_org_count INTO l_count_prec_arr_org;
        CLOSE get_non_null_org_count;

        OPEN get_non_null_dep_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id);
        FETCH get_non_null_dep_count INTO l_count_prec_arr_dep;
        CLOSE get_non_null_dep_count;

        OPEN get_non_null_cat_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code);
        FETCH get_non_null_cat_count INTO l_count_prec_arr_cat;
        CLOSE get_non_null_cat_count;

        -- check for the possibility to create a downtime visit
        OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', l_ground_time);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        l_can_disconnect_visit := 'N';
        IF get_oper_param_rows1%FOUND THEN -- there is a possibility of creating a downtime visit at arrival org of prec FS
		  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME ::Dono type :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
          OPEN get_visit_type_code(l_visit_id2);
          FETCH get_visit_type_code INTO l_visit_type_code;
          CLOSE get_visit_type_code;
          IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
             l_can_disconnect_visit := 'Y';
          ELSE
             OPEN get_fs_arr_time(flight_schedule_rec.preceding_us_id);
             FETCH get_fs_arr_time INTO l_start_date;
             CLOSE get_fs_arr_time;
             -- based on the profile value see if you can adjust the visit dates
             OPEN get_visit_end_time(l_visit_id2);
             FETCH get_visit_end_time INTO l_visit_end_time;
             CLOSE get_visit_end_time;
             IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
                l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
             ELSE
                l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
             END IF;
             IF  l_profile_varchar is not null  THEN
                 l_profile_number := to_number(l_profile_varchar) ;
             ELSE
                 l_profile_number := l_difference_dep_time-1;
             END IF;

             IF  l_profile_varchar2 is not null THEN
                 l_profile_number2 := to_number(l_profile_varchar2) ;
             ELSE
                 l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
             END IF;

             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_dep_time--@>'||l_difference_dep_time);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number--@>'||l_profile_number);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number2--@>'||l_profile_number);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, '(sysdate + l_profile_number2)--@>'||(cast((sysdate + l_profile_number2) AS timestamp)));
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.est_departure_time--@>'||(cast((flight_schedule_rec.est_departure_time) AS timestamp)));
             END IF;

             IF((l_difference_dep_time > l_profile_number)
                  AND (l_difference_dep_time <> 0)
                  AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN

                  l_can_disconnect_visit := 'Y';

             END IF;
          END IF;
        ELSE
           l_can_disconnect_visit := 'Y';
        END IF;
        CLOSE get_oper_param_rows1;

        IF l_can_disconnect_visit ='Y' THEN
             --PRAKKUM :: 01/08/2012 :: Added procedure :: START
             Disconnect_Flight_Visit(
                p_visit_id               => l_visit_id2,
                p_unit_schedule_id       => pre_fs_det_rec.unit_schedule_id,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data
             );
             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
             END IF;

             IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
              x_msg_count := l_msg_count;
              x_return_status := l_return_status;
              IF l_return_status = Fnd_Api.g_ret_sts_error THEN
                RAISE Fnd_Api.g_exc_error;
              ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
                RAISE Fnd_Api.g_exc_unexpected_error;
              END IF;
             END IF;
             --PRAKKUM :: 01/08/2012 :: Added procedure :: END
             l_visit_id2 := NULL; --Since visit is cancelled

        END IF;--l_can_disconnect_visit ='Y'
       END IF;--Downtime visit exists
   END IF; --IF (l_can_cancel_visit2 IS NULL)

   -- Recheck to confirm if any visit is disaasociated
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;
   -- PRAKKUM :: Bug 14368696 :: 01/08/2012 :: END

   -- if preceding arrival flight visit can not be cancelled and there is no visit associated to departure org of current FS
   -- then look for the possibility of creating an departure visit at departure org of current FS
   IF (l_can_cancel_visit2 IS NULL) THEN -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: START

       IF substr (l_visit_type,1,1) = 'T' AND l_visit_id2 IS NOT NULL THEN --Downtime visit exists

        --Get ground time at the departing org of a FS
        OPEN get_ground_time (flight_schedule_rec.preceding_us_id, flight_schedule_rec.UNIT_SCHEDULE_ID);
        FETCH get_ground_time INTO l_ground_time;
        CLOSE get_ground_time;

        OPEN get_non_null_org_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id);
        FETCH get_non_null_org_count INTO l_count_prec_arr_org;
        CLOSE get_non_null_org_count;

        OPEN get_non_null_dep_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id);
        FETCH get_non_null_dep_count INTO l_count_prec_arr_dep;
        CLOSE get_non_null_dep_count;

        OPEN get_non_null_cat_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code);
        FETCH get_non_null_cat_count INTO l_count_prec_arr_cat;
        CLOSE get_non_null_cat_count;

        -- check for the possibility to create a downtime visit
        OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', l_ground_time);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        l_can_disconnect_visit := 'N';
        IF get_oper_param_rows1%FOUND THEN -- there is a possibility of creating a downtime visit at arrival org of prec FS
		  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Dono Type 2 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
          OPEN get_visit_type_code(l_visit_id2);
          FETCH get_visit_type_code INTO l_visit_type_code;
          CLOSE get_visit_type_code;
          IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
             l_can_disconnect_visit := 'Y';
          ELSE
             OPEN get_fs_arr_time(flight_schedule_rec.preceding_us_id);
             FETCH get_fs_arr_time INTO l_start_date;
             CLOSE get_fs_arr_time;
             -- based on the profile value see if you can adjust the visit dates
             OPEN get_visit_end_time(l_visit_id2);--PRAKKUM :: Bug 14342603 :: 18/07/2012
             FETCH get_visit_end_time INTO l_visit_end_time;
             CLOSE get_visit_end_time;
             IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
                l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
             ELSE
                l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
             END IF;
             IF  l_profile_varchar is not null  THEN
                 l_profile_number := to_number(l_profile_varchar) ;
             ELSE
                 l_profile_number := l_difference_dep_time-1;
             END IF;

             IF  l_profile_varchar2 is not null THEN
                 l_profile_number2 := to_number(l_profile_varchar2) ;
             ELSE
                 l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
             END IF;

             IF (l_log_statement >= l_log_current_level) THEN --PRAKKUM :: Bug 14342603 :: 18/07/2012
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_dep_time--@>'||l_difference_dep_time);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number--@>'||l_profile_number);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number2--@>'||l_profile_number);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, '(sysdate + l_profile_number2)--@>'||(cast((sysdate + l_profile_number2) AS timestamp)));
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.est_departure_time--@>'||(cast((flight_schedule_rec.est_departure_time) AS timestamp)));
             END IF;

             IF((l_difference_dep_time > l_profile_number)
                  AND (l_difference_dep_time <> 0)
                  AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN

                  l_can_update_visit := null;
                  OPEN can_cancel_visit(l_visit_id2);
                  FETCH can_cancel_visit INTO l_can_update_visit;
                  CLOSE can_cancel_visit;

                  IF l_can_update_visit IS NULL THEN
                     l_can_disconnect_visit := 'Y';
                  END IF;

             END IF;
          END IF;
        ELSE
           l_can_disconnect_visit := 'Y';
        END IF;

        IF l_can_disconnect_visit ='Y' THEN
             --PRAKKUM :: 01/08/2012 :: Added procedure :: START
             Disconnect_Flight_Visit(
                p_visit_id               => l_visit_id2,
                p_unit_schedule_id       => pre_fs_det_rec.unit_schedule_id,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data
             );
             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
             END IF;

             IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
              x_msg_count := l_msg_count;
              x_return_status := l_return_status;
              IF l_return_status = Fnd_Api.g_ret_sts_error THEN
                RAISE Fnd_Api.g_exc_error;
              ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
                RAISE Fnd_Api.g_exc_unexpected_error;
              END IF;
             END IF;
             --PRAKKUM :: 01/08/2012 :: Added procedure :: END
             l_visit_id2 := NULL; --Since visit is cancelled

        END IF;--l_can_disconnect_visit ='Y'
       END IF;--Downtime visit exists

       IF l_visit_id IS NULL THEN -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: END

          -- check for the possibility of creating a departure visit;
          OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                    flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org,
                                    l_count_dep, l_count_cat,'DEPARTURE', NULL);
          FETCH get_oper_param_rows1 INTO get_oper_param_rec;
          IF get_oper_param_rows1%FOUND THEN
              IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Type 3 :
                  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
              END IF;
            --If there is a possibility to create a departure visit
            --TYPE 3: Departure Org :: no visit to cancel :: create a departure visit
            IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 3 and before calling Create_Departure_visit');
            END IF;
              l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
              l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
              l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
              l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

              -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
              SAVEPOINT OPER_VISIT_CREATION;

               Create_Departure_visit(
                  p_oper_param_rec         => l_oper_param_rec,
                  p_flight_schedule_rec    => l_flight_schedule_rec,
                  p_present_time           => l_present_time,
                  p_is_creation_success    => l_is_creation_success,
                  x_return_status          => l_return_status,
                  x_msg_count              => l_msg_count,
                  x_msg_data               => l_msg_data
                   );
               IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
               END IF;

              IF l_is_creation_success<>'Y' THEN
                ROLLBACK TO OPER_VISIT_CREATION;
              END IF;
              -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

          END IF;
          CLOSE get_oper_param_rows1;
           -- Go to arrival org consideration

       END IF; -- l_visit_id IS NULL
   END IF; --IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL)) THEN

   IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
    --Get ground time at the departing org of a FS
    OPEN get_ground_time (flight_schedule_rec.preceding_us_id, flight_schedule_rec.UNIT_SCHEDULE_ID);
    FETCH get_ground_time INTO l_ground_time;
    CLOSE get_ground_time;

    OPEN get_non_null_org_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id);
    FETCH get_non_null_org_count INTO l_count_prec_arr_org;
    CLOSE get_non_null_org_count;

    OPEN get_non_null_dep_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id);
    FETCH get_non_null_dep_count INTO l_count_prec_arr_dep;
    CLOSE get_non_null_dep_count;

    OPEN get_non_null_cat_count(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                              pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code);
    FETCH get_non_null_cat_count INTO l_count_prec_arr_cat;
    CLOSE get_non_null_cat_count;

    IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'passing values are unit_config_header_id: '||pre_fs_det_rec.unit_config_header_id
       ||', pre_fs_det_rec.arrival_org_id: '||pre_fs_det_rec.arrival_org_id||',  arrival_dept_id: , '||pre_fs_det_rec.arrival_dept_id
       ||',  flight_category_code: ,'||pre_fs_det_rec.flight_category_code||',  l_count_prec_arr_org: ,'||l_count_prec_arr_org
       ||', l_count_prec_arr_dep:   ,'||l_count_prec_arr_dep||',  l_count_prec_arr_cat: ,'
       ||l_count_prec_arr_cat||' ground time is '||l_ground_time);
    END IF;

    -- check for the possibility to create a downtime visit
    OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', l_ground_time);
    FETCH get_oper_param_rows1 INTO get_oper_param_rec;
    l_is_downtime_vst_created := 'Y';
    IF get_oper_param_rows1%FOUND THEN -- there is a possibility of creating a downtime visit at arrival org of prec FS
      IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: l_can_cancel_visit IS NULL :
              get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
      END IF;
      IF l_visit_id2 is null THEN  -- if there is no visit associated to the arrival org of previous FS
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 4');
        END IF;

        -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
        SAVEPOINT OPER_VISIT_CREATION;

        --TYPE 4: Departure Org :: no visit for arrival org of previous FS to cancel :: create a downime visit
        --cancel the departure visit of the current flight if it is not null
        IF(l_visit_id is not null) then
          Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
        END IF;--IF(l_visit_id is not null) then
        IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
        END IF;
        l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
        l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
        l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

        -- we need to create a downtime visit and associate to the departure org of current flight, so pass preceeding flight details
        Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_prec_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
        END IF;
        IF l_is_creation_success<>'Y' THEN
           ROLLBACK TO OPER_VISIT_CREATION;
           l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
        END IF;
        -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

      ELSE -- l_visit_id2 is not null i.e if there is visit associated to the arrival org of previous FS
        -- We need to match the visit type of the existing visit and operational param row visit type
        OPEN get_visit_type_code(l_visit_id2);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
          -- if it does not match then Cancel the visit assoc to arrival org and also if any departure visit associated
          -- to the dep org of current FS. then create a downtime visit
          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 5');
          END IF;
          --TYPE 5: Departure Org :: cancel arrival visit and dep visit(if exists) :: create a downtime visit
          --Cancel the existing arrival visit of the prec FS since the visit types did not match
           Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
          IF(l_visit_id is not null) then
            Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
          END IF;--IF(l_visit_id is not null) then
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          -- we need to create a downtime visit and associate to the arrival org of preceeding flight, so pass preceeding flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_prec_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;
          IF l_is_creation_success<>'Y' THEN
             ROLLBACK TO OPER_VISIT_CREATION;
             l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
        ELSE
          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 6');
          END IF;
          --TYPE 6::Departure Org::cancel dep visit(if exists):: extend the existing visit
          -- If the visit type matches, we need to update the visit dates
          --Before updating the visit first cancel the departure visit of the current if it is not null
          IF(l_visit_id is not null) then
            Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
          END IF;--IF(l_visit_id is not null) then
          -- Now update the visit dates to span the entire downtime
          OPEN get_fs_arr_time(flight_schedule_rec.preceding_us_id);
          FETCH get_fs_arr_time INTO l_start_date;
          CLOSE get_fs_arr_time;
          -- based on the profile value see if you can adjust the visit dates
          OPEN get_visit_end_time(l_visit_id2);--PRAKKUM :: Bug 14342603 :: 18/07/2012
          FETCH get_visit_end_time INTO l_visit_end_time;
          CLOSE get_visit_end_time;
          IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
            l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
          ELSE
            l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
          END IF;
          IF  l_profile_varchar is not null  THEN
              l_profile_number := to_number(l_profile_varchar) ;
          ELSE
              l_profile_number := l_difference_dep_time-1;
          END IF;

          IF  l_profile_varchar2 is not null THEN
              l_profile_number2 := to_number(l_profile_varchar2) ;
          ELSE
              l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
          END IF;

          IF (l_log_statement >= l_log_current_level) THEN --PRAKKUM :: Bug 14342603 :: 18/07/2012
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_dep_time--@>'||l_difference_dep_time);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number--@>'||l_profile_number);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number2--@>'||l_profile_number);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, '(sysdate + l_profile_number2)--@>'||(cast((sysdate + l_profile_number2) AS timestamp)));
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.est_departure_time--@>'||(cast((flight_schedule_rec.est_departure_time) AS timestamp)));
          END IF;

          IF((l_difference_dep_time > l_profile_number)
              AND (l_difference_dep_time <> 0)
              AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN

            l_end_date := flight_schedule_rec.est_departure_time;
            l_visit_rec.START_DATE            := l_start_date;
            l_visit_rec.PLAN_END_DATE         := l_end_date;
            l_visit_rec.VISIT_ID              := l_visit_id2;--PRAKKUM :: Bug 14342603 :: 18/07/2012

            OPEN c_Visit(l_visit_id2);--PRAKKUM :: Bug 14342603 :: 18/07/2012
            FETCH c_Visit INTO c_Visit_rec;
            IF c_Visit%NOTFOUND THEN
             CLOSE c_Visit;
             IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
              Fnd_Msg_Pub.ADD;
              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
              END IF;
             END IF;
             RAISE Fnd_Api.g_exc_error;
            ELSE
             CLOSE c_Visit;
            END IF;

            -- Complete Visit Record
            l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
            l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
            l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
            l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
            l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
            l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
            l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
            l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
            l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
            l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
            l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
            l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
            l_visit_rec.AUTO_VISIT_TYPE_FLAG  := 'T'; --TCHIMIRA :: 14-Jun-2012 :: ER 14015560

            -- PRAKKUM :: 14/10/2014 :: PA ENH
            l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
            l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
            l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
            l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
            l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string
                 ( fnd_log.level_procedure,
                   'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                   'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
            END IF;
            AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string
                ( fnd_log.level_procedure,
                    'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                    'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
            END IF;
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
              x_msg_count := FND_MSG_PUB.count_msg;
              IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                                'Errors from Update_Visit. Message count: ' || x_msg_count);
              END IF;
              IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                RAISE FND_API.G_EXC_ERROR;
              ELSE
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
            END IF;  -- Return Status is not Success
          END IF;       --IF((l_difference_dep_time > nvl
        END IF;--else of l_visit_type_code <> get_oper_param_rec.visit_type_code
      END IF;-- else of l_visit_id2 is null
      CLOSE get_oper_param_rows1;
    ELSE --a downtime visit cannot be created
      CLOSE get_oper_param_rows1;
      l_is_downtime_vst_created := 'N';
    END IF;
    IF l_is_downtime_vst_created = 'N' THEN -- Downtime visit cannot be created
      -- if there is a visit associated to the arrival org of Prec FS
      IF l_visit_id2 is not null THEN
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 7');
        END IF;
        -- TYPE 7::Departure Org:: there is a visit assoc to arrival org of prev FS::
        -- we need to check the type of the visit associated to the arrival org
        -- it can be either arrival or downtime;
        -- if the visit type of the existing visit matches with any of the visit types of operational param rows then
        -- it is a downtime visit else and arrival visit
        OPEN get_visit_type_code (l_visit_id2);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        OPEN get_oper_param_rows1(pre_fs_det_rec.unit_config_header_id,pre_fs_det_rec.arrival_org_id,
                                pre_fs_det_rec.arrival_dept_id, pre_fs_det_rec.flight_category_code, l_count_prec_arr_org, l_count_prec_arr_dep, l_count_prec_arr_cat,
                                'DOWNTIME', null);
        LOOP
          FETCH get_oper_param_rows1 INTO get_oper_param_rec;
          EXIT WHEN get_oper_param_rows1%NOTFOUND;
          IF get_oper_param_rec.visit_type_code = l_visit_type_code THEN
            l_flag := 'Y';
          END IF;
        END LOOP;
        CLOSE get_oper_param_rows1;

        -- if the visit associated to the arrival org of Prec FS is downtime, then cancel the visit
        IF l_flag = 'Y' THEN
          -- it is a downtime visit and we need to cancel that visit
          Delete_Oper_Visit(
             p_visit_id       => l_visit_id2,
             x_return_status  => l_return_status);
        END IF; --IF l_flag = 'Y'
      END IF;-- l_visit_id2 is not null
      -- PRAKKUM :: Bug 13844759 :: 31/07/2012
      IF substr (l_visit_type,1,1) = 'D' AND l_visit_id IS NOT NULL THEN --existing visit is a departure visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 8');
        END IF;
        -- TYPE 8::Departure Org:: there is a dep visit assoc to dep org of curr FS::
        -- based on the profile value see if you can adjust the visit dates
        OPEN get_visit_end_time(l_visit_id);
        FETCH get_visit_end_time INTO l_visit_end_time;
        CLOSE get_visit_end_time;

        OPEN c_Visit_type_dur (l_visit_id);
        FETCH c_Visit_type_dur INTO l_visit_type_duration;
        CLOSE c_Visit_type_dur;

        IF flight_schedule_rec.est_departure_time > l_visit_end_time THEN
          l_difference_dep_time := (flight_schedule_rec.est_departure_time - l_visit_end_time)*24*60;
        ELSE
          l_difference_dep_time := (l_visit_end_time - flight_schedule_rec.est_departure_time)*24*60;
        END IF;
        IF  l_profile_varchar is not null  THEN
         l_profile_number := to_number(l_profile_varchar) ;
        ELSE
         l_profile_number := l_difference_dep_time-1;
        END IF;

        IF  l_profile_varchar2 is not null THEN
         l_profile_number2 := to_number(l_profile_varchar2) ;
        ELSE
         l_profile_number2 := flight_schedule_rec.est_departure_time-sysdate+1;
        END IF;

        IF((l_difference_dep_time > l_profile_number)
           AND (l_difference_dep_time <> 0)
           AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_departure_time) ) THEN
          l_start_date := flight_schedule_rec.est_departure_time - l_visit_type_duration/24;
          l_end_date := flight_schedule_rec.est_departure_time;

          l_visit_rec := null;
          l_visit_rec.START_DATE            := l_start_date;
          l_visit_rec.PLAN_END_DATE         := l_end_date;
          l_visit_rec.VISIT_ID              := l_visit_id;

          OPEN c_Visit(l_visit_id);
          FETCH c_Visit INTO c_Visit_rec;
          IF c_Visit%NOTFOUND THEN
            CLOSE c_Visit;
            IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
              Fnd_Msg_Pub.ADD;
              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
              END IF;
             END IF;
             RAISE Fnd_Api.g_exc_error;
          ELSE
             CLOSE c_Visit;
          END IF;

          -- Complete Visit Record
          l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
          l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
          l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
          l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
          l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
          l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
          l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
          l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
          l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
          l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
          l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
          l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
          l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG;--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

          -- PRAKKUM :: 14/10/2014 :: PA ENH
          l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
          l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
          l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
          l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
          l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

          IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
                ( fnd_log.level_procedure,
                  'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                  'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
          END IF;
          AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

          IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
                ( fnd_log.level_procedure,
                  'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                  'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
          END IF;
          IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            x_msg_count := FND_MSG_PUB.count_msg;
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,
                               L_DEBUG_KEY,
                               'Errors from Update_Visit. Message count: ' || x_msg_count);
            END IF;
            IF l_return_status = FND_API.G_RET_STS_ERROR THEN
              RAISE FND_API.G_EXC_ERROR;
            ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
          END IF;  -- Return Status is not Success
        END IF;  -- IF((l_difference_dep_time > nvl(FND_PROFIL
      ELSE -- there is no visit at the dep org of current FS
        OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.departure_org_id,
                                    flight_schedule_rec.departure_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                    'DEPARTURE', NULL);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        IF get_oper_param_rows1%FOUND THEN
          --TYPE 9: Departure Org :: no visit at dep org of current FS :: create a departure visit
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 9 and before calling Create_Departure_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

            Create_Departure_visit(
              p_oper_param_rec         => l_oper_param_rec,
              p_flight_schedule_rec    => l_flight_schedule_rec,
              p_present_time           => l_present_time,
              p_is_creation_success    => l_is_creation_success,
              x_return_status          => l_return_status,
              x_msg_count              => l_msg_count,
              x_msg_data               => l_msg_data
            );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Departure_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;
          IF l_is_creation_success<>'Y' THEN
              ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        END IF;   --IF get_oper_param_rows1%FOUND THEN
        CLOSE get_oper_param_rows1;
      END IF; --IF substr (l_visit_type,1,1) = 'D'
    END IF; --IF get_oper_param_rows1%FOUND
   END IF; --IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
  END IF; --IF ( flight_schedule_rec.preceding_us_id IS NULL )


  IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'CASE II, flight_schedule_rec.unit_schedule_id= '||flight_schedule_rec.unit_schedule_id );
  END IF;
  -- CASE II: Now consider the arrival org of the flight schedule record
  OPEN get_non_null_org_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id);
  FETCH get_non_null_org_count INTO l_count_org;
  CLOSE get_non_null_org_count;

  OPEN get_non_null_dep_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id);
  FETCH get_non_null_dep_count INTO l_count_dep;
  CLOSE get_non_null_dep_count;

  OPEN get_non_null_cat_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code);
  FETCH get_non_null_cat_count INTO l_count_cat;
  CLOSE get_non_null_cat_count;

  OPEN get_succeeding_us_det (flight_schedule_rec.unit_schedule_id);
  FETCH get_succeeding_us_det INTO l_succeeding_us_id, l_succ_dep_time;
  CLOSE get_succeeding_us_det;

  -- check if there exisits a visit and if yes, what visit type - either arrival or downtime
  AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'S', l_visit_type, l_visit_id,l_visit_id2);

  --If the flight schedule does not have any succeeding flight then
  IF ( l_succeeding_us_id IS NULL ) THEN

    IF substr (l_visit_type,1,1) = 'A' THEN -- if there is a visit

      IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Before Type 10.There is an existing arrival visit at arrival org');
      END IF;
      --TYPE 10: Arrival Org :: arrival visit associated to the arrival org of current FS :: update the visit

      /* SATRAJEN :: Bug 16626490 :; Commented to retrieve using c_Visit_type_dur in context of Visit_id
      OPEN get_visit_type_duration (get_oper_param_rec.visit_type_code,get_oper_param_rec.mc_id);
      FETCH get_visit_type_duration INTO l_visit_type_duration;
      CLOSE get_visit_type_duration;*/

      OPEN c_Visit_type_dur (l_visit_id);
      FETCH c_Visit_type_dur INTO l_visit_type_duration;
      CLOSE c_Visit_type_dur;

      IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Visit type duration is: '||l_visit_type_duration);
      END IF;
      -- based on the profile value see if you can adjust the visit dates
      OPEN get_visit_start_time(l_visit_id);
      FETCH get_visit_start_time INTO l_visit_start_time;
      CLOSE get_visit_start_time;

      -- Added the below code to see if the visit can be updated or not : tchimira: bug 13844759
      l_can_update_visit := null;
      OPEN can_cancel_visit(l_visit_id);
      FETCH can_cancel_visit INTO l_can_update_visit;
      CLOSE can_cancel_visit;

      IF flight_schedule_rec.est_arrival_time > l_visit_start_time THEN
        l_difference_arrival_time := (flight_schedule_rec.est_arrival_time - l_visit_start_time)*24*60;
      ELSE
        l_difference_arrival_time := (l_visit_start_time - flight_schedule_rec.est_arrival_time)*24*60;
      END IF;

      IF  l_profile_varchar is not null  THEN
      l_profile_number := to_number(l_profile_varchar) ;
      ELSE
      l_profile_number := l_difference_arrival_time-1;
      END IF;

      IF  l_profile_varchar2 is not null THEN
      l_profile_number2 := to_number(l_profile_varchar2) ;
      ELSE
      l_profile_number2 := flight_schedule_rec.est_arrival_time-sysdate+1;
      END IF;

      IF((l_difference_arrival_time > l_profile_number)
         AND (l_difference_arrival_time <> 0)
         AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_arrival_time) ) THEN
       -- TCHIMIRA : Bug 13844759 : check if the visit is updateable.
       -- if yes, the update the visit else diconnect the visit and try to recreate a new departure visit
       IF l_can_update_visit IS NOT NULL THEN

        --TYPE 10: Arrival Org :: there is a visit at arrival org of current FS :: update the visit
        l_start_date := flight_schedule_rec.est_arrival_time;
        l_end_date := flight_schedule_rec.est_arrival_time + l_visit_type_duration/24;

        l_visit_rec := null;
        l_visit_rec.START_DATE            := l_start_date;
        l_visit_rec.PLAN_END_DATE         := l_end_date;
        l_visit_rec.VISIT_ID              := l_visit_id;

        OPEN c_Visit(l_visit_id);
        FETCH c_Visit INTO c_Visit_rec;
        IF c_Visit%NOTFOUND THEN
          CLOSE c_Visit;
          IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
            Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
            Fnd_Msg_Pub.ADD;
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
            END IF;
           END IF;
           RAISE Fnd_Api.g_exc_error;
        ELSE
           CLOSE c_Visit;
        END IF;

        -- Complete Visit Record
        l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
        l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
        l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
        l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
        l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
        l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
        l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
        l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
        l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
        l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
        l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
        l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
        l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG;--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

        -- PRAKKUM :: 14/10/2014 :: PA ENH
        l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
        l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
        l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
        l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
        l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

        IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string
                    ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
        END IF;
        AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

        IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string
                    ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
        END IF;
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            x_msg_count := FND_MSG_PUB.count_msg;
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,
                               L_DEBUG_KEY,
                               'Errors from Update_Visit. Message count: ' || x_msg_count);
            END IF;
            IF l_return_status = FND_API.G_RET_STS_ERROR THEN
               RAISE FND_API.G_EXC_ERROR;
            ELSE
               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
        END IF;  -- Return Status is not Success
       ELSE
          --PRAKKUM :: 01/08/2012 :: Added procedure :: START
          Disconnect_Flight_Visit(
             p_visit_id               => l_visit_id,
             p_unit_schedule_id       => flight_schedule_rec.UNIT_SCHEDULE_ID,
             x_return_status          => l_return_status,
             x_msg_count              => l_msg_count,
             x_msg_data               => l_msg_data
          );
          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
          END IF;

          IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
           x_msg_count := l_msg_count;
           x_return_status := l_return_status;
           IF l_return_status = Fnd_Api.g_ret_sts_error THEN
             RAISE Fnd_Api.g_exc_error;
           ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
             RAISE Fnd_Api.g_exc_unexpected_error;
           END IF;
          END IF;
          --PRAKKUM :: 01/08/2012 :: Added procedure :: END
       END IF;-- check to see if the visit is updateble or not
      END IF; -- IF((l_difference_arrival_time > l_profile_number)
    END IF; --IF substr (l_visit_type,1,1) = 'A' THEN

    -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: START
    -- Before this, previous visits can be cancelled so fetch details again
    -- check if there exisits a visit and if yes, what visit type - either arrival or downtime
    AHL_AVF_OPER_VSTS_PVT.Get_Visit_Type(flight_schedule_rec.unit_schedule_id, 'S', l_visit_type, l_visit_id,l_visit_id2);

    l_can_update_visit := null;
    IF l_visit_id IS NOT NULL THEN
      OPEN can_cancel_visit(l_visit_id);
      FETCH can_cancel_visit INTO l_can_update_visit;
      CLOSE can_cancel_visit;
    END IF;
    -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: END

    -- TCHIMIRA : Bug 13844759 : 29 - Mar - 2012
    -- If there is no arrival visit, look for the possibility of creating one
    IF ((substr (l_visit_type,1,1) <> 'A') OR (l_can_update_visit IS NULL)) THEN
      -- check for the possibility of creating an arrival visit;
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, 'passing values are unit_config_header_id: '||flight_schedule_rec.unit_config_header_id
        ||', flight_schedule_rec.arrival_org_id: '||flight_schedule_rec.arrival_org_id||',  arrival_dept_id: , '||flight_schedule_rec.arrival_dept_id
        ||',  flight_category_code: ,'||flight_schedule_rec.flight_category_code||',  l_count_org: ,'||l_count_org||', l_count_dep:   ,'
        ||l_count_dep||',  l_count_cat: ,'||l_count_cat);
      END IF;
      OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'ARRIVAL', NULL);
      FETCH get_oper_param_rows1 INTO get_oper_param_rec;
      IF get_oper_param_rows1%FOUND THEN
        -- if there is a possibility , create an arrival visit
        --TYPE 11: Arrival Org :: no visit associated to the arrival org of current FS :: create an arrival visit
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 11 and before calling Create_Arrival_visit');
        END IF;
        l_oper_param_rec.visit_type_code  := get_oper_param_rec.visit_type_code;
        l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
        l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
        l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Arrival_visit(
            p_oper_param_rec       => l_oper_param_rec,
            p_flight_schedule_rec  => l_flight_schedule_rec,
            p_present_time         => l_present_time,
            p_is_creation_success  => l_is_creation_success,
            x_return_status        => l_return_status,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data
            );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;
          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

      END IF; --IF get_oper_param_rows1%FOUND THEN
      CLOSE get_oper_param_rows1;
      -- Go to end
    END If; -- if condition to check for the possibility of creating an arrival visit

  --If the flight schedule has a succeeding event then
  ELSE
   -- check if any of the arrival current flight visit or departure succeeding flight visit does not satisfy any of
   -- the criteria to be automatically cancelled.
   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   -- PRAKKUM :: Bug 13844759 :: 25/07/2012
   -- If existing visit is arrival visit, then see whether it needs to be updated or disassociate
   IF substr (l_visit_type,1,1) = 'A' THEN -- if there is a visit
       IF l_visit_id IS NOT NULL THEN

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Before Type 10.There is an existing arrival visit at arrival org');
          END IF;
          --TYPE 10: Arrival Org :: arrival visit associated to the arrival org of current FS :: update the visit

          /* SATRAJEN :: Bug 16626490 :; Commented to retrieve using c_Visit_type_dur in context of Visit_id
          OPEN get_visit_type_duration (get_oper_param_rec.visit_type_code,get_oper_param_rec.mc_id);
          FETCH get_visit_type_duration INTO l_visit_type_duration;
          CLOSE get_visit_type_duration;*/

          OPEN c_Visit_type_dur (l_visit_id);
          FETCH c_Visit_type_dur INTO l_visit_type_duration;
          CLOSE c_Visit_type_dur;

          IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Visit type duration is: '||l_visit_type_duration);
          END IF;
          -- based on the profile value see if you can adjust the visit dates
          OPEN get_visit_start_time(l_visit_id);
          FETCH get_visit_start_time INTO l_visit_start_time;
          CLOSE get_visit_start_time;

          -- Added the below code to see if the visit can be updated or not : tchimira: bug 13844759
          l_can_update_visit := null;
          OPEN can_cancel_visit(l_visit_id);
          FETCH can_cancel_visit INTO l_can_update_visit;
          CLOSE can_cancel_visit;

          IF flight_schedule_rec.est_arrival_time > l_visit_start_time THEN
            l_difference_arrival_time := (flight_schedule_rec.est_arrival_time - l_visit_start_time)*24*60;
          ELSE
            l_difference_arrival_time := (l_visit_start_time - flight_schedule_rec.est_arrival_time)*24*60;
          END IF;

          IF  l_profile_varchar is not null  THEN
          l_profile_number := to_number(l_profile_varchar) ;
          ELSE
          l_profile_number := l_difference_arrival_time-1;
          END IF;

          IF  l_profile_varchar2 is not null THEN
          l_profile_number2 := to_number(l_profile_varchar2) ;
          ELSE
          l_profile_number2 := flight_schedule_rec.est_arrival_time-sysdate+1;
          END IF;

          IF((l_difference_arrival_time > l_profile_number)
             AND (l_difference_arrival_time <> 0)
             AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_arrival_time) ) THEN
           -- TCHIMIRA : Bug 13844759 : check if the visit is updateable.
           -- if yes, the update the visit else diconnect the visit and try to recreate a new departure visit
           IF l_can_update_visit IS NOT NULL THEN

            --TYPE 10: Arrival Org :: there is a visit at arrival org of current FS :: update the visit
            l_start_date := flight_schedule_rec.est_arrival_time;
            l_end_date := flight_schedule_rec.est_arrival_time + l_visit_type_duration/24;

            l_visit_rec := null;
            l_visit_rec.START_DATE            := l_start_date;
            l_visit_rec.PLAN_END_DATE         := l_end_date;
            l_visit_rec.VISIT_ID              := l_visit_id;

            OPEN c_Visit(l_visit_id);
            FETCH c_Visit INTO c_Visit_rec;
            IF c_Visit%NOTFOUND THEN
              CLOSE c_Visit;
              IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
                Fnd_Msg_Pub.ADD;
                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                  fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
                END IF;
               END IF;
               RAISE Fnd_Api.g_exc_error;
            ELSE
               CLOSE c_Visit;
            END IF;

            -- Complete Visit Record
            l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
            l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
            l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
            l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
            l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
            l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
            l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
            l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
            l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
            l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
            l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
            l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
            l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG;--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

            -- PRAKKUM :: 14/10/2014 :: PA ENH
            l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
            l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
            l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
            l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
            l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                       fnd_log.string
                        ( fnd_log.level_procedure,
                         'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                         'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
            END IF;
            AHL_VWP_VISITS_PVT.Update_Visit (
                                          p_api_version => l_api_version,
                                          p_init_msg_list => Fnd_Api.g_false,
                                          p_commit => Fnd_Api.g_false,
                                          p_validation_level => p_validation_level,
                                          p_module_type => 'API',
                                          p_x_visit_rec  => l_visit_rec,
                                          x_return_status => l_return_status,
                                          x_msg_count => l_msg_count,
                                          x_msg_data => l_msg_data
                                         );

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                       fnd_log.string
                        ( fnd_log.level_procedure,
                         'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                         'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
            END IF;
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                x_msg_count := FND_MSG_PUB.count_msg;
                IF (l_log_statement >= l_log_current_level) THEN
                    fnd_log.string(l_log_statement,
                                   L_DEBUG_KEY,
                                   'Errors from Update_Visit. Message count: ' || x_msg_count);
                END IF;
                IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                   RAISE FND_API.G_EXC_ERROR;
                ELSE
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
            END IF;  -- Return Status is not Success
           ELSE
             --PRAKKUM :: 01/08/2012 :: Added procedure :: START
             Disconnect_Flight_Visit(
                p_visit_id               => l_visit_id,
                p_unit_schedule_id       => flight_schedule_rec.UNIT_SCHEDULE_ID,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data
              );
             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
             END IF;

             IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
               x_msg_count := l_msg_count;
               x_return_status := l_return_status;
               IF l_return_status = Fnd_Api.g_ret_sts_error THEN
                 RAISE Fnd_Api.g_exc_error;
               ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
                 RAISE Fnd_Api.g_exc_unexpected_error;
               END IF;
             END IF;
             --PRAKKUM :: 01/08/2012 :: Added procedure :: END
             l_visit_id := NULL; --SInce visit is cancelled

           END IF;-- check to see if the visit is updateble or not
          END IF; -- IF((l_difference_arrival_time > l_profile_number)
      END IF; --l_visit_id IS NOT NULL
   END IF;

   -- PRAKKUM :: Bug 13844759 :: 26/07/2012
   -- check if any of the arrival current flight visit or departure succeeding flight visit does not satisfy any of
   -- the criteria to be automatically cancelled.
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   -- PRAKKUM :: Bug 14368696 :: 01/08/2012 :: START
   IF (l_can_cancel_visit IS NULL) THEN -- If downtime or arrival is not allowed to cancel
       IF substr (l_visit_type,1,1) = 'T' AND l_visit_id IS NOT NULL THEN --Downtime visit exists

        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Handle case that downtime visit not allowed to cancel--@>');
        END IF;

        --Get ground time at the departing org of a FS
        OPEN get_ground_time (flight_schedule_rec.UNIT_SCHEDULE_ID, l_succeeding_us_id);
        FETCH get_ground_time INTO l_ground_time;
        CLOSE get_ground_time;

        -- check for the possibility to create a downtime visit
        OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'DOWNTIME', l_ground_time);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        l_can_disconnect_visit := 'N';
        IF get_oper_param_rows1%FOUND THEN -- there is a possibility of creating a downtime visit at arrival org of prec FS
		  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: l_can_cancel_visit IS NULL :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
          OPEN get_visit_type_code(l_visit_id);
          FETCH get_visit_type_code INTO l_visit_type_code;
          CLOSE get_visit_type_code;
          IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
             l_can_disconnect_visit := 'Y';
          ELSE
             OPEN get_fs_arr_time(flight_schedule_rec.unit_schedule_id);
             FETCH get_fs_arr_time INTO l_start_date;
             CLOSE get_fs_arr_time;

             -- based on the profile value see if you can adjust the visit dates
             OPEN get_visit_start_time(l_visit_id);
             FETCH get_visit_start_time INTO l_visit_start_time;
             CLOSE get_visit_start_time;

             IF flight_schedule_rec.est_arrival_time > l_visit_start_time THEN
                l_difference_arrival_time := (flight_schedule_rec.est_arrival_time - l_visit_start_time)*24*60;
             ELSE
                l_difference_arrival_time := (l_visit_start_time - flight_schedule_rec.est_arrival_time)*24*60;
             END IF;

             IF  l_profile_varchar is not null  THEN
                l_profile_number := to_number(l_profile_varchar) ;
             ELSE
                l_profile_number := l_difference_arrival_time-1;
             END IF;

             IF  l_profile_varchar2 is not null THEN
                l_profile_number2 := to_number(l_profile_varchar2) ;
             ELSE
                l_profile_number2 := flight_schedule_rec.est_arrival_time-sysdate+1;
             END IF;

             IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_arrival_time--@>'||l_difference_arrival_time);
                 fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number--@>'||l_profile_number);
                 fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number2--@>'||l_profile_number);
                 fnd_log.string(l_log_statement,L_DEBUG_KEY, '(sysdate + l_profile_number2)--@>'||(cast((sysdate + l_profile_number2) AS timestamp)));
                 fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.est_arrival_time--@>'||(cast((flight_schedule_rec.est_arrival_time) AS timestamp)));
             END IF;

             IF((l_difference_arrival_time > l_profile_number)
               AND (l_difference_arrival_time <> 0)
               AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_arrival_time) ) THEN
               --TYPE 15: Arrival Org :: update visit at arrival org of current FS:: visit types do match

                  l_can_disconnect_visit := 'Y';

             END IF;
          END IF;
        ELSE
           l_can_disconnect_visit := 'Y';
        END IF;
        CLOSE get_oper_param_rows1;

        IF l_can_disconnect_visit ='Y' THEN
             --PRAKKUM :: 01/08/2012 :: Added procedure :: START
             Disconnect_Flight_Visit(
                p_visit_id               => l_visit_id,
                p_unit_schedule_id       => flight_schedule_rec.unit_schedule_id,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data
              );
             IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Disconnect_Flight_Visit and l_return_status: '||l_return_status);
             END IF;

             IF l_msg_count > 0 OR NVL(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
               x_msg_count := l_msg_count;
               x_return_status := l_return_status;
               IF l_return_status = Fnd_Api.g_ret_sts_error THEN
                 RAISE Fnd_Api.g_exc_error;
               ELSIF l_return_status = Fnd_Api.g_ret_sts_unexp_error THEN
                 RAISE Fnd_Api.g_exc_unexpected_error;
               END IF;
             END IF;
             --PRAKKUM :: 01/08/2012 :: Added procedure :: END
             l_visit_id := NULL; --Since visit is cancelled
        END IF;--l_can_disconnect_visit ='Y'
       END IF;--Downtime visit exists
   END IF; --IF (l_can_cancel_visit2 IS NULL)

   -- Recheck to confirm if any visit is disaasociated
   load_can_cancel_visit(
      p_visit_id               => l_visit_id,
      p_visit_id2              => l_visit_id2,
      x_can_cancel_visit       => l_can_cancel_visit,
      x_can_cancel_visit2      => l_can_cancel_visit2,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
      );
   IF (l_log_statement >= l_log_current_level) THEN
       fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling load_can_cancel_visit and l_return_status: '||l_return_status);
   END IF;

   -- if departure succ flight visit can not be cancelled and there is no visit associated to arrival org of current FS
   -- then look for the possibility of creating an arrival visit at arrival org of current FS
   IF (l_can_cancel_visit2 IS NULL) THEN -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: START

      IF l_visit_id IS NULL THEN -- PRAKKUM :: Bug 13844759 :: 25/07/2012 :: END

        -- check for the possibility of creating an arrival visit;
        IF (l_log_statement >= l_log_current_level) THEN
                          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'passing values are unit_config_header_id: '
                          ||flight_schedule_rec.unit_config_header_id||', flight_schedule_rec.arrival_org_id: '||flight_schedule_rec.arrival_org_id||',  arrival_dept_id: , '
                          ||flight_schedule_rec.arrival_dept_id||',  flight_category_code: ,'||flight_schedule_rec.flight_category_code||',  l_count_org: ,'||l_count_org||', l_count_dep:   ,'
                          ||l_count_dep||',  l_count_cat: ,'||l_count_cat);
        END IF;
        OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                  flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                  'ARRIVAL', NULL);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        IF get_oper_param_rows1%FOUND THEN
		  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Before Type 12 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
          -- if there is possibility of creating an arrival visit
          --TYPE 12: Arrival Org :: no visit to cancel :: create an arrival visit
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 12 and before calling Create_Arrival_visit');
          END IF;
          l_oper_param_rec.visit_type_code  := get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;
            Create_Arrival_visit(
              p_oper_param_rec       => l_oper_param_rec,
              p_flight_schedule_rec  => l_flight_schedule_rec,
              p_present_time         => l_present_time,
              p_is_creation_success  => l_is_creation_success,
              x_return_status        => l_return_status,
              x_msg_count         => l_msg_count,
              x_msg_data          => l_msg_data
              );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;
          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END
        END IF; -- IF get_oper_param_rows1%FOUND THEN
        CLOSE get_oper_param_rows1;

      END IF;
      -- Go to end
   END IF; --IF ((l_can_cancel_visit2 IS NULL) AND (l_visit_id IS NULL)) THEN

   OPEN get_non_null_org_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id);
   FETCH get_non_null_org_count INTO l_count_org;
   CLOSE get_non_null_org_count;

   OPEN get_non_null_dep_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id);
   FETCH get_non_null_dep_count INTO l_count_dep;
   CLOSE get_non_null_dep_count;

   OPEN get_non_null_cat_count(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                              flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code);
   FETCH get_non_null_cat_count INTO l_count_cat;
   CLOSE get_non_null_cat_count;

   -- if both dep succ flight visit and arrival visit can be automatically cancelled
   IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
    --Get ground time at the arrival org of a FS
    OPEN get_ground_time (flight_schedule_rec.UNIT_SCHEDULE_ID, l_succeeding_us_id);
    FETCH get_ground_time INTO l_ground_time;
    CLOSE get_ground_time;

    -- check for the possibility to create a downtime visit
    OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'DOWNTIME', l_ground_time);
    FETCH get_oper_param_rows1 INTO get_oper_param_rec;
    l_is_downtime_vst_created := 'Y';
    IF get_oper_param_rows1%FOUND THEN
	  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Before 13 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
      IF l_visit_id is null THEN -- if there is no visit associated to the arrival org of currrent FS
        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 13');
        END IF;

        -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
        SAVEPOINT OPER_VISIT_CREATION;

        --TYPE 13: Arrival Org :: no arrival visit at arrival org of current FS::create a downime visit
        --cancel the departure visit of the succeeding flight if it is not null
        IF(l_visit_id2 is not null) then
               Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
        END IF;--IF(l_visit_id2 is not null) then
        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
        END IF;
            l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
            l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
            l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- we need to create a downtime visit and associate to the arrival org of current flight, so pass current flight details
            Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
            );

        IF (l_log_statement >= l_log_current_level) THEN
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
          fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
        END IF;

        IF l_is_creation_success<>'Y' THEN
           ROLLBACK TO OPER_VISIT_CREATION;
           l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
        END IF;
        -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

      ELSE -- if there is a visit associated to the arrival org of currrent FS
        -- We need to match the visit type of the visit and operational param row visit type
        OPEN get_visit_type_code(l_visit_id);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        IF l_visit_type_code <> get_oper_param_rec.visit_type_code THEN
          --  if it does not match then call create visit API
          -- Cancel the arrival visit with id 'l_visit_id' and also if any departure visit associated
          -- to the dep org of succ FS. then create a downtime visit
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 14');
          END IF;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          --TYPE 14: Arrival Org :: a visit at arrival org of current FS:: visit types do not match
          --Cancel the existing visit of the current FS
          Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
          --cancel the departure visit of the succ event if it is not null
          IF(l_visit_id2 is not null) then
            Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
          END IF;--IF(l_visit_id2 is not null) then
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before calling Create_Downtime_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- we need to create a downtime visit and associate to the arrival org of current flight, so pass current flight details
          Create_Downtime_visit(
            p_oper_param_rec         => l_oper_param_rec,
            p_flight_schedule_rec    => l_flight_schedule_rec,
            p_present_time           => l_present_time,
            p_is_creation_success    => l_is_creation_success,
            x_return_status          => l_return_status,
            x_msg_count              => l_msg_count,
            x_msg_data               => l_msg_data
          );

          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Downtime_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;

          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
            l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        ELSE
          -- If the visit type matches, we need to update the visit dates
          --Before updating the visit first cancel the departure visit of the succ event if it is not null
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 15');
          END IF;
          --TYPE 15: Arrival Org :: visit types do match ::  update the visit
          IF(l_visit_id2 IS NOT NULL) THEN
             Delete_Oper_Visit(
               p_visit_id       => l_visit_id2,
               x_return_status  => l_return_status);
          END IF;--IF(l_visit_id2 is not null) then
          -- Now update the visit dates to span the entire downtime
          OPEN get_fs_arr_time(flight_schedule_rec.unit_schedule_id);
          FETCH get_fs_arr_time INTO l_start_date;
          CLOSE get_fs_arr_time;

          -- based on the profile value see if you can adjust the visit dates
          OPEN get_visit_start_time(l_visit_id);
          FETCH get_visit_start_time INTO l_visit_start_time;
          CLOSE get_visit_start_time;

          IF flight_schedule_rec.est_arrival_time > l_visit_start_time THEN
             l_difference_arrival_time := (flight_schedule_rec.est_arrival_time - l_visit_start_time)*24*60;
          ELSE
             l_difference_arrival_time := (l_visit_start_time - flight_schedule_rec.est_arrival_time)*24*60;
          END IF;

          IF  l_profile_varchar is not null  THEN
           l_profile_number := to_number(l_profile_varchar) ;
          ELSE
           l_profile_number := l_difference_arrival_time-1;
          END IF;

          IF  l_profile_varchar2 is not null THEN
           l_profile_number2 := to_number(l_profile_varchar2) ;
          ELSE
           l_profile_number2 := flight_schedule_rec.est_arrival_time-sysdate+1;
          END IF;

          IF (l_log_statement >= l_log_current_level) THEN --PRAKKUM :: Bug 14342603 :: 18/07/2012
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_difference_arrival_time--@>'||l_difference_arrival_time);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number--@>'||l_profile_number);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_profile_number2--@>'||l_profile_number);
             fnd_log.string(l_log_statement,L_DEBUG_KEY, '(sysdate + l_profile_number2)--@>'||(cast((sysdate + l_profile_number2) AS timestamp)));
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'flight_schedule_rec.est_arrival_time--@>'||(cast((flight_schedule_rec.est_arrival_time) AS timestamp)));
          END IF;

          IF((l_difference_arrival_time > l_profile_number)
            AND (l_difference_arrival_time <> 0)
            AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_arrival_time) ) THEN
            --TYPE 15: Arrival Org :: update visit at arrival org of current FS:: visit types do match

            l_end_date := l_succ_dep_time;
            l_visit_rec.START_DATE            := l_start_date;
            l_visit_rec.PLAN_END_DATE         := l_end_date;
            l_visit_rec.VISIT_ID              := l_visit_id;

            OPEN c_Visit(l_visit_id);
            FETCH c_Visit INTO c_Visit_rec;
            IF c_Visit%NOTFOUND THEN
              CLOSE c_Visit;
              IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
                Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
                Fnd_Msg_Pub.ADD;
                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                  fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
                END IF;
               END IF;
               RAISE Fnd_Api.g_exc_error;
            ELSE
               CLOSE c_Visit;
            END IF;

            -- Complete Visit Record
            l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
            l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
            l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
            l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
            l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
            l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
            l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
            l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
            l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
            l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
            l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
            l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
            l_visit_rec.AUTO_VISIT_TYPE_FLAG  := 'T';--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

            -- PRAKKUM :: 14/10/2014 :: PA ENH
            l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
            l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
            l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
            l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
            l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string
                  ( fnd_log.level_procedure,
                    'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                    'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
            END IF;
            AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

            IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string
                   ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
            END IF;
            IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
              x_msg_count := FND_MSG_PUB.count_msg;
              IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,
                                 L_DEBUG_KEY,
                                 'Errors from Update_Visit. Message count: ' || x_msg_count);
              END IF;
              IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                 RAISE FND_API.G_EXC_ERROR;
              ELSE
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
            END IF;  -- Return Status is not Success
          END IF;--IF((l_difference_arrival_time > nv
        END IF;--IF of l_visit_type_code <> get_oper_param_rec.visit_type_code
      END IF;-- else of l_visit_id is null
      CLOSE get_oper_param_rows1;
    ELSE
      CLOSE get_oper_param_rows1;
      l_is_downtime_vst_created := 'N'; -- Downtime visit creation failed, so consider for creating arrival visit
    END IF;
    IF l_is_downtime_vst_created = 'N' THEN
      -- We cannot create a downtime visit at the arrival org of current FS
      -- if there is any visit associated to the arrival org of current FS
      IF l_visit_id is not null THEN
        -- we need to check the type of the visit associated to the arrival org
        -- it can be either arrival or downtime
        -- if the visit type of the existing visit matches with visit types of the operational param rows
        OPEN get_visit_type_code (l_visit_id);
        FETCH get_visit_type_code INTO l_visit_type_code;
        CLOSE get_visit_type_code;
        -- we need to check the type of the visit - either arrival or downtime
        OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                'DOWNTIME', null);
        LOOP
         FETCH get_oper_param_rows1 INTO get_oper_param_rec;
         EXIT WHEN get_oper_param_rows1%NOTFOUND;
		 IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Dono type 3 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
         IF get_oper_param_rec.visit_type_code = l_visit_type_code THEN
           l_flag := 'Y';
         END IF;
        END LOOP;
        CLOSE get_oper_param_rows1;
        IF l_flag = 'Y' THEN
          -- it is a downtime visit and we need to cancel that visit
          Delete_Oper_Visit(
               p_visit_id       => l_visit_id,
               x_return_status  => l_return_status);
        END IF; --IF l_flag = 'Y'
      END IF;-- l_visit_id is not null
      -- PRAKKUM :: Bug 13844759 :: 31/07/2012
      IF ((substr (l_visit_type,1,1) <> 'N') and (l_flag <> 'Y') AND l_visit_id is not null) THEN -- there is an arrival visit to the arrival org
        -- based on the profile value see if you can adjust the visit dates
        OPEN get_visit_start_time(l_visit_id);
        FETCH get_visit_start_time INTO l_visit_start_time;
        CLOSE get_visit_start_time;

        OPEN c_Visit_type_dur (l_visit_id);
        FETCH c_Visit_type_dur INTO l_visit_type_duration;
        CLOSE c_Visit_type_dur;

        IF flight_schedule_rec.est_arrival_time > l_visit_start_time THEN
          l_difference_arrival_time := (flight_schedule_rec.est_arrival_time - l_visit_start_time)*24*60;
        ELSE
          l_difference_arrival_time := (l_visit_start_time - flight_schedule_rec.est_arrival_time)*24*60;
        END IF;
        IF  l_profile_varchar is not null  THEN
          l_profile_number := to_number(l_profile_varchar) ;
        ELSE
          l_profile_number := l_difference_arrival_time-1;
        END IF;

        IF  l_profile_varchar2 is not null THEN
          l_profile_number2 := to_number(l_profile_varchar2) ;
        ELSE
          l_profile_number2 := flight_schedule_rec.est_arrival_time-sysdate+1;
        END IF;

        IF((l_difference_arrival_time > l_profile_number)
          AND (l_difference_arrival_time <> 0)
          AND ((sysdate + l_profile_number2)> flight_schedule_rec.est_arrival_time) ) THEN
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 16');
          END IF;
          --TYPE 16: Arrival Org :: a visit at arrival org of current FS:: update the arrival visit
          l_start_date := flight_schedule_rec.est_arrival_time;
          l_end_date := flight_schedule_rec.est_arrival_time + l_visit_type_duration/24;

          l_visit_rec := null;
          l_visit_rec.START_DATE            := l_start_date;
          l_visit_rec.PLAN_END_DATE         := l_end_date;
          l_visit_rec.VISIT_ID              := l_visit_id;

          OPEN c_Visit(l_visit_id);
          FETCH c_Visit INTO c_Visit_rec;
          IF c_Visit%NOTFOUND THEN
            CLOSE c_Visit;
            IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error) THEN
              Fnd_Message.set_name('AHL', 'AHL_API_RECORD_NOT_FOUND');
              Fnd_Msg_Pub.ADD;
              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Visit not found for - ' ||l_visit_rec.visit_id );
              END IF;
             END IF;
             RAISE Fnd_Api.g_exc_error;
          ELSE
             CLOSE c_Visit;
          END IF;

          -- Complete Visit Record
          l_visit_rec.VISIT_TYPE_CODE       := c_Visit_rec.VISIT_TYPE_CODE;
          l_visit_rec.SERVICE_REQUEST_ID    := c_Visit_rec.SERVICE_REQUEST_ID;
          l_visit_rec.SPACE_CATEGORY_CODE   := c_Visit_rec.SPACE_CATEGORY_CODE;
          l_visit_rec.OBJECT_VERSION_NUMBER := c_Visit_rec.OBJECT_VERSION_NUMBER;
          l_visit_rec.VISIT_NAME            := c_Visit_rec.VISIT_NAME;
          l_visit_rec.DESCRIPTION           := c_Visit_rec.DESCRIPTION;
          l_visit_rec.PRIORITY_CODE         := c_Visit_rec.PRIORITY_CODE;
          l_visit_rec.PROJ_TEMPLATE_ID      := c_Visit_rec.PROJECT_TEMPLATE_ID;
          l_visit_rec.ITEM_INSTANCE_ID      := c_Visit_rec.ITEM_INSTANCE_ID;
          l_visit_rec.UNIT_SCHEDULE_ID      := c_Visit_rec.UNIT_SCHEDULE_ID;
          l_visit_rec.ORGANIZATION_ID       := c_Visit_rec.ORGANIZATION_ID;
          l_visit_rec.DEPARTMENT_ID         := c_Visit_rec.DEPARTMENT_ID;
          l_visit_rec.AUTO_VISIT_TYPE_FLAG  := c_Visit_rec.AUTO_VISIT_TYPE_FLAG;--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

          -- PRAKKUM :: 14/10/2014 :: PA ENH
          l_visit_rec.CUSTOMER_ID           := c_Visit_rec.CUSTOMER_ID;
          l_visit_rec.PRICING_FLAG          := c_Visit_rec.PRICING_FLAG;
          l_visit_rec.PRICING_METHOD        := c_Visit_rec.PRICING_METHOD;
          l_visit_rec.RES_COST_PERCENT      := c_Visit_rec.RES_COST_PERCENT;
          l_visit_rec.MAT_COST_PERCENT      := c_Visit_rec.MAT_COST_PERCENT;

          IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
                ( fnd_log.level_procedure,
                  'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                  'Before calling AHL_VWP_VISITS_PVT.Update_Visit autovst_oper_id: '||get_oper_param_rec.autovst_oper_id);
          END IF;
          AHL_VWP_VISITS_PVT.Update_Visit (
                                      p_api_version => l_api_version,
                                      p_init_msg_list => Fnd_Api.g_false,
                                      p_commit => Fnd_Api.g_false,
                                      p_validation_level => p_validation_level,
                                      p_module_type => 'API',
                                      p_x_visit_rec  => l_visit_rec,
                                      x_return_status => l_return_status,
                                      x_msg_count => l_msg_count,
                                      x_msg_data => l_msg_data
                                     );

          IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.string
                    ( fnd_log.level_procedure,
                     'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                     'After calling AHL_VWP_VISITS_PVT.Update_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
          END IF;
          IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            x_msg_count := FND_MSG_PUB.count_msg;
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,
                               L_DEBUG_KEY,
                               'Errors from Update_Visit. Message count: ' || x_msg_count);
            END IF;
            IF l_return_status = FND_API.G_RET_STS_ERROR THEN
              RAISE FND_API.G_EXC_ERROR;
            ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
          END IF;  -- Return Status is not Success
        END If; -- IF((l_difference_arrival_time > nvl(FND_PROFILE
      ELSE  -- there is no visit associated to the arrival org of current FS
        -- Look for creating an arrival visit
        OPEN get_oper_param_rows1(flight_schedule_rec.unit_config_header_id,flight_schedule_rec.arrival_org_id,
                                    flight_schedule_rec.arrival_dept_id, flight_schedule_rec.flight_category_code, l_count_org, l_count_dep, l_count_cat,
                                    'ARRIVAL', NULL);
        FETCH get_oper_param_rows1 INTO get_oper_param_rec;
        IF get_oper_param_rows1%FOUND THEN
		  IF (l_log_statement >= l_log_current_level) THEN
              fnd_log.string(l_log_statement,L_DEBUG_KEY, 'SATRAJEN :: Bug 16626490 :: get_oper_param_rows1 :: Prev Flight :: DOWNTIME :: Type 17 :
			  get_oper_param_rec.visit_type_code is ' || get_oper_param_rec.visit_type_code || 'get_oper_param_rec.mc_id is ' || get_oper_param_rec.mc_id);
          END IF;
          --TYPE 17: Arrival Org :: no visit at arrival org of current FS:: create the arrival visit
          IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string(l_log_statement,L_DEBUG_KEY, 'Before Type 17 and before calling Create_Arrival_visit');
          END IF;
          l_oper_param_rec.visit_type_code  :=  get_oper_param_rec.visit_type_code;
          l_oper_param_rec.mc_id            := get_oper_param_rec.mc_id;
          l_oper_param_rec.alternate_dep_id := get_oper_param_rec.alternate_dep_id;
          l_oper_param_rec.autovst_oper_id  := get_oper_param_rec.autovst_oper_id;

          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: START
          SAVEPOINT OPER_VISIT_CREATION;

          Create_Arrival_visit(
            p_oper_param_rec       => l_oper_param_rec,
            p_flight_schedule_rec  => l_flight_schedule_rec,
            p_present_time         => l_present_time,
            p_is_creation_success  => l_is_creation_success,
            x_return_status        => l_return_status,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data
            );
          IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'After calling Create_Arrival_visit and l_return_status: '||l_return_status);
            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'l_is_creation_success: '||l_is_creation_success);
          END IF;
          IF l_is_creation_success<>'Y' THEN
            ROLLBACK TO OPER_VISIT_CREATION;
          END IF;
          -- Bug 14336467 :: PRAKKUM :: 13/07/2012 :: END

        END IF;
        CLOSE get_oper_param_rows1; -- Added the line for Bug # 13706579 by TCHIMIRA on 15th Feb 2012
      END IF; --IF substr (l_visit_type,1,1) <> 'N'
    END IF; --IF get_oper_param_rows1%FOUND
   END IF; -- IF (l_can_cancel_visit IS NOT NULL) AND (l_can_cancel_visit2 IS NOT NULL) THEN
  END IF; --IF ( l_succeeding_us_id IS NULL )

  --Update the Flight Schedule auto create status to 'R'
  UPDATE AHL_UNIT_SCHEDULES
  set AUTOVISIT_PROCESS_STATUS = 'R',
      OBJECT_VERSION_NUMBER = object_version_number + 1,
      LAST_UPDATE_DATE      = SYSDATE,
      LAST_UPDATED_BY       = Fnd_Global.USER_ID,
      LAST_UPDATE_LOGIN     = Fnd_Global.LOGIN_ID
  WHERE UNIT_SCHEDULE_ID    = flight_schedule_rec.UNIT_SCHEDULE_ID;
 END LOOP;

 -- END of API body.
 -- Standard check of p_commit.
 IF Fnd_Api.To_Boolean (p_commit) THEN
    COMMIT WORK;
 END IF;

 Fnd_Msg_Pub.count_and_get(
           p_encoded => Fnd_Api.g_false,
           p_count   => x_msg_count,
           p_data    => x_msg_data
 );

 IF (l_log_procedure >= l_log_current_level) THEN
     fnd_log.string(l_log_procedure,
                    L_DEBUG_KEY ||'.end',
                    'At the end of PL SQL procedure. Return Status = ' || x_return_status);
 END IF;

EXCEPTION

 WHEN FND_API.G_EXC_ERROR THEN
   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Update_Oper_Visit_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Update_Oper_Visit_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Update_Oper_Visit_pvt;

    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Update_Oper_Visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;

    FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Update_Oper_Visit;

--TCHIMIRA :: 14-Jun-2012 :: start
---------------------------------------------------------------------------------------
-- PROCEDURE
--    Create_Departure_visit
--  Type   : Private
--
-- PURPOSE
--    To create a departure visit at departure organization of the flight
--
--  Parameters :
--  Create_Departure_visit Parameters
--      p_oper_param_rec         IN oper_param_rec_type Required
--      p_flight_schedule_rec    IN flight_schedule_rec_type Required
--
--  Standard OUT Parameters :
--      x_return_status           OUT     VARCHAR2     Required
--      x_msg_count               OUT     NUMBER       Required
--      x_msg_data                OUT     VARCHAR2     Required
--
----------------------------------------------------------------------------------------

PROCEDURE Create_Departure_visit(
    p_oper_param_rec       IN      oper_param_rec_type,
    p_flight_schedule_rec  IN      flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status        OUT NOCOPY     VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2)
IS

-- Cursor to find visit type duration
Cursor get_visit_type_duration(c_visit_type_code IN VARCHAR2, c_mc_id IN NUMBER)
IS
SELECT estimated_duration
FROM ahl_visit_types_b
WHERE visit_type_code = c_visit_type_code
 AND mc_id = c_mc_id
 AND status_code = 'COMPLETE';

Cursor is_org_in_current_OU (c_org_id IN NUMBER)
IS
SELECT 'X'
FROM org_organization_definitions hou
WHERE hou.organization_id                                  = c_org_id
AND NVL(hou.operating_unit,mo_global.get_current_org_id()) = mo_global.get_current_org_id();

-- Cursor to get the visit Number from visit_id
CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

--Added cursor to get flight details for loggin :: PRAKKUM :: 01/08/2012
Cursor get_flight_details (c_us_id IN NUMBER)
IS
SELECT flight_number
FROM ahl_unit_schedules
WHERE unit_schedule_id  = c_us_id;
flt_dets_rec get_flight_details%RowType;

--PRAKKUM :: 24/02/2016 :: Bug 22877137
CURSOR get_item_owner_details(c_uc_id IN NUMBER)
IS
SELECT PARTY_ID CUSTOMER_ID FROM
   AHL_UNIT_CONFIG_HEADERS UC,
   CSI_ITEM_INSTANCES CSIS,
   HZ_PARTIES HZP
WHERE UC.CSI_ITEM_INSTANCE_ID=CSIS.INSTANCE_ID
AND CSIS.ACTIVE_START_DATE <= SYSDATE
AND NVL(CSIS.ACTIVE_END_DATE,SYSDATE) >= SYSDATE
AND  CSIS.INV_MASTER_ORGANIZATION_ID IN
     ( SELECT MASTER_ORGANIZATION_ID FROM
               INV_ORGANIZATION_INFO_V ORG,
               MTL_PARAMETERS MP
               WHERE ORG.ORGANIZATION_ID = MP.ORGANIZATION_ID
               AND NVL(OPERATING_UNIT,MO_GLOBAL.GET_CURRENT_ORG_ID()) = MO_GLOBAL.GET_CURRENT_ORG_ID())
AND CSIS.OWNER_PARTY_ID = HZP.PARTY_ID(+)
AND NVL(HZP.PARTY_TYPE,'NO_VAL') IN ('NO_VAL', 'PERSON' , 'ORGANIZATION' )
AND UC.UNIT_CONFIG_HEADER_ID = c_uc_id;

  L_API_NAME             CONSTANT VARCHAR2(30) := 'Create_Departure_visit';
  L_DEBUG_KEY            CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
  l_visit_type_duration  NUMBER;
  l_visit_rec            AHL_VWP_VISITS_PVT.Visit_Rec_Type;
  l_is_org_in_curr_OU    VARCHAR2(1);
  l_visit_number         NUMBER;
  l_start_date_ts        TIMESTAMP;
  l_end_date_ts          TIMESTAMP;
  l_start_date           DATE;
  l_start_hour           NUMBER;
  l_start_min            NUMBER;
  l_end_date             DATE;
  l_end_hour             NUMBER;
  l_end_min              NUMBER;
  l_return_status        VARCHAR2(1);
  -- SATRAJEN :: Bug 14336467 :: Prevent erroring out in case of Operational visit.
  l_pub_msg              VARCHAR2(2000);

BEGIN

 SAVEPOINT Create_Dep_visit_pvt;

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.begin',
                     'At the start of PL SQL function.');
 END IF;

 -- initialize procedure return status to success
 x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Bug 14336467 :: PRAKKUM :: 13/07/2012
 p_is_creation_success := 'Y'; --initialize to success

 OPEN get_visit_type_duration (p_oper_param_rec.visit_type_code,p_oper_param_rec.mc_id);
 FETCH get_visit_type_duration INTO l_visit_type_duration;
 CLOSE get_visit_type_duration;

 l_visit_rec := null;

 SELECT NAME INTO l_visit_rec.UNIT_NAME FROM AHL_UNIT_CONFIG_HEADERS
  WHERE unit_config_header_id= p_flight_schedule_rec.unit_config_header_id;

 -- Populate all the visit attributes
 l_visit_rec.VISIT_TYPE_CODE       := p_oper_param_rec.visit_type_code;
 l_visit_rec.ORGANIZATION_ID       := p_flight_schedule_rec.departure_org_id;
 l_visit_rec.VISIT_NAME            := 'Auto-Visit';
 l_visit_rec.DEPARTMENT_ID         := NVL(p_oper_param_rec.alternate_dep_id, p_flight_schedule_rec.departure_dept_id);

 l_start_date := p_flight_schedule_rec.est_departure_time - l_visit_type_duration/24;
 l_start_date_ts := cast(l_start_date as timestamp);
 l_start_hour := (extract(HOUR from l_start_date_ts));
 l_start_min := (extract(MINUTE from l_start_date_ts));

 l_end_date := p_flight_schedule_rec.est_departure_time;
 l_end_date_ts := cast(l_end_date as timestamp);
 l_end_hour := (extract(HOUR from l_end_date_ts));
 l_end_min := (extract(MINUTE from l_end_date_ts));

 l_visit_rec.START_DATE            := trunc(l_start_date);
 l_visit_rec.START_HOUR            := l_start_hour;
 l_visit_rec.START_MIN             := l_start_min;
 l_visit_rec.PLAN_END_DATE         := trunc(l_end_date);
 l_visit_rec.PLAN_END_HOUR         := l_end_hour;
 l_visit_rec.PLAN_END_MIN          := l_end_min;
 l_visit_rec.VISIT_CREATE_TYPE     := 'PLANNING';
 l_visit_rec.UNIT_SCHEDULE_ID      := p_flight_schedule_rec.unit_schedule_id;
 l_visit_rec.AUTO_VISIT_TYPE_FLAG  := 'D';--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

 l_visit_rec.PRICING_FLAG          := 'N';--PRAKKUM :: 09/02/2016 :: BUG 22680167

 --PRAKKUM :: 24/02/2016 :: Bug 22877137
 OPEN get_item_owner_details(p_flight_schedule_rec.unit_config_header_id);
 FETCH get_item_owner_details INTO l_visit_rec.CUSTOMER_ID;
 CLOSE get_item_owner_details;

 -- Check if the visit org is in the current OU
 l_is_org_in_curr_OU := null;
 OPEN is_org_in_current_OU (l_visit_rec.ORGANIZATION_ID);
 FETCH is_org_in_current_OU INTO l_is_org_in_curr_OU;
 CLOSE is_org_in_current_OU;

 IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_start_date --@>'||cast(l_start_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_end_date --@>'||cast(l_end_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'p_present_time --@>'||cast(p_present_time as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'mo_global.get_current_org_id() --@>'||mo_global.get_current_org_id());
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_visit_rec.ORGANIZATION_ID --@>'||l_visit_rec.ORGANIZATION_ID);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_is_org_in_curr_OU --@>'||l_is_org_in_curr_OU);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'CUSTOMER_ID --@>'|| l_visit_rec.CUSTOMER_ID);
 END IF;

 IF l_start_date < p_present_time THEN -- Bug 14336486 :: PRAKKUM :: 12/07/2012
    -- Do not create a visit
    OPEN get_flight_details(p_flight_schedule_rec.unit_schedule_id);
    FETCH get_flight_details INTO flt_dets_rec;
    CLOSE get_flight_details;

    IF l_end_date < p_present_time THEN
        fnd_file.put_line(fnd_file.log, 'Validation Failure: No departure visit created, since flight '||flt_dets_rec.flight_number||' is already departured.');
    ELSE
        fnd_file.put_line(fnd_file.log, 'Validation Failure: No departure visit created, since visit start date for flight '||flt_dets_rec.flight_number||' is deriving to past.');
    END IF;
    p_is_creation_success := 'N'; -- Flag as creation failed due to validations

 ELSE
   -- IF the visit org is NOT in current OU, do not create the visit
   IF l_is_org_in_curr_OU = 'X' THEN
     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
             ( fnd_log.level_procedure,
               'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
               'Before calling AHL_VWP_VISITS_PVT.Create_Visit autovst_oper_id: '||p_oper_param_rec.autovst_oper_id);
     END IF;
     AHL_VWP_VISITS_PVT.Create_Visit (
                                         p_api_version => 1.0,
                                         p_module_type => 'API',
                                         p_x_visit_rec  => l_visit_rec,
                                         x_return_status => l_return_status,
                                         x_msg_count => x_msg_count,
                                         x_msg_data => x_msg_data
                                         );

     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
               fnd_log.string
               ( fnd_log.level_procedure,
                 'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                 'After calling AHL_VWP_VISITS_PVT.Create_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
     END IF;

     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: START
     IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         l_pub_msg := FND_MSG_PUB.Get_Detail (p_msg_index => FND_MSG_PUB.G_LAST);
         IF (l_pub_msg like '%AHL_VWP_PRD_MR_ASSOC_FAIL%') THEN
           IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string
             ( l_log_statement,
               L_DEBUG_KEY,
               'visit id= '||l_visit_rec.visit_id || 'Had problems with the MRs associated. So departure visit creation is not successful. ');
           END IF;
           x_return_status := FND_API.G_RET_STS_SUCCESS;
           p_is_creation_success := 'N'; -- Flag as creation of visit failed due to validations
           -- Remove message from FND
           FND_MSG_PUB.Delete_Msg(p_msg_index => FND_MSG_PUB.count_msg);

           OPEN get_flight_details(p_flight_schedule_rec.unit_schedule_id);
           FETCH get_flight_details INTO flt_dets_rec;
           CLOSE get_flight_details;

           fnd_file.put_line(fnd_file.log, 'Validation Failure: Had problems with the MRs associated. So departure visit creation for flight '||flt_dets_rec.flight_number||' is not successful.');
         ELSE
           x_return_status := l_return_status ;
           x_msg_count := FND_MSG_PUB.count_msg;
           IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,
                                 L_DEBUG_KEY,
                                 'Errors from Create_Visit. Message count: ' || x_msg_count);
           END IF;
           IF l_return_status = FND_API.G_RET_STS_ERROR THEN
             RAISE FND_API.G_EXC_ERROR;
           ELSE
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
         END IF;
      ELSE
           x_return_status := l_return_status ;
           l_visit_number := NULL;
           OPEN get_visit_number(l_visit_rec.visit_id);
           FETCH get_visit_number INTO l_visit_number;
           CLOSE get_visit_number;
           fnd_file.put_line(fnd_file.log, 'Created departure visit number -> '||l_visit_number);
         -- End of logging
     END IF;
     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: END
   END IF; -- IF l_is_org_in_curr_OU = 'X'
 END IF; -- l_start_date

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.end',
                     'At the end of PL SQL function.');
 END IF;
EXCEPTION
 WHEN FND_API.G_EXC_ERROR THEN
   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Create_Dep_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Create_Dep_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Create_Dep_visit_pvt;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Create_Departure_visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;
    FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Create_Departure_visit;

---------------------------------------------------------------------------------------
-- PROCEDURE
--    Create_Arrival_visit
-- Type             : Public
-- PURPOSE
--    To create an Arrival visit at arrival organization of the flight schedule
--  Parameters :
--  Create_Arrival_visit Parameters
--      p_oper_param_rec         IN oper_param_rec_type Required
--      p_flight_schedule_rec    IN flight_schedule_rec_type Required
--
--  Standard OUT Parameters :
--      x_return_status           OUT     VARCHAR2     Required
--      x_msg_count               OUT     NUMBER       Required
--      x_msg_data                OUT     VARCHAR2     Required
----------------------------------------------------------------------------------------

PROCEDURE Create_Arrival_visit(
    p_oper_param_rec       IN  oper_param_rec_type,
    p_flight_schedule_rec  IN  flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status      OUT NOCOPY  VARCHAR2,
    x_msg_count          OUT NOCOPY NUMBER,
    x_msg_data           OUT NOCOPY VARCHAR2
)
IS

-- Cursor to find visit type duration
Cursor get_visit_type_duration(c_visit_type_code IN VARCHAR2, c_mc_id IN NUMBER)
IS
SELECT estimated_duration
FROM ahl_visit_types_b
WHERE visit_type_code = c_visit_type_code
 AND mc_id = c_mc_id
 AND status_code = 'COMPLETE';

Cursor is_org_in_current_OU (c_org_id IN NUMBER)
IS
SELECT 'X'
FROM org_organization_definitions hou
WHERE hou.organization_id                                  = c_org_id
AND NVL(hou.operating_unit,mo_global.get_current_org_id()) = mo_global.get_current_org_id();

-- Cursor to get the visit Number from visit_id
CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

--Added cursor to get flight details for loggin :: PRAKKUM :: 01/08/2012
Cursor get_flight_details (c_us_id IN NUMBER)
IS
SELECT flight_number
FROM ahl_unit_schedules
WHERE unit_schedule_id  = c_us_id;
flt_dets_rec get_flight_details%RowType;

--PRAKKUM :: 24/02/2016 :: Bug 22877137
CURSOR get_item_owner_details(c_uc_id IN NUMBER)
IS
SELECT PARTY_ID CUSTOMER_ID FROM
   AHL_UNIT_CONFIG_HEADERS UC,
   CSI_ITEM_INSTANCES CSIS,
   HZ_PARTIES HZP
WHERE UC.CSI_ITEM_INSTANCE_ID=CSIS.INSTANCE_ID
AND CSIS.ACTIVE_START_DATE <= SYSDATE
AND NVL(CSIS.ACTIVE_END_DATE,SYSDATE) >= SYSDATE
AND  CSIS.INV_MASTER_ORGANIZATION_ID IN
     ( SELECT MASTER_ORGANIZATION_ID FROM
               INV_ORGANIZATION_INFO_V ORG,
               MTL_PARAMETERS MP
               WHERE ORG.ORGANIZATION_ID = MP.ORGANIZATION_ID
               AND NVL(OPERATING_UNIT,MO_GLOBAL.GET_CURRENT_ORG_ID()) = MO_GLOBAL.GET_CURRENT_ORG_ID())
AND CSIS.OWNER_PARTY_ID = HZP.PARTY_ID(+)
AND NVL(HZP.PARTY_TYPE,'NO_VAL') IN ('NO_VAL', 'PERSON' , 'ORGANIZATION' )
AND UC.UNIT_CONFIG_HEADER_ID = c_uc_id;

  L_API_NAME             CONSTANT VARCHAR2(30) := 'Create_Arrival_visit';
  L_DEBUG_KEY            CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
  l_visit_type_duration  NUMBER;
  l_visit_rec            AHL_VWP_VISITS_PVT.Visit_Rec_Type;
  l_is_org_in_curr_OU    VARCHAR2(1);
  l_visit_number         NUMBER;
  l_start_date_ts        TIMESTAMP;
  l_end_date_ts          TIMESTAMP;
  l_start_date           DATE;
  l_start_hour           NUMBER;
  l_start_min            NUMBER;
  l_end_date             DATE;
  l_end_hour             NUMBER;
  l_end_min              NUMBER;
  l_return_status        VARCHAR2(1);
  -- SATRAJEN :: Bug 14336467 :: Prevent erroring out in case of Operational visit.
  l_pub_msg              VARCHAR2(2000);

BEGIN

 SAVEPOINT Create_Arr_visit_pvt;
 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.begin',
                     'At the start of PL SQL function.');
 END IF;

 -- initialize procedure return status to success
 x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Bug 14336467 :: PRAKKUM :: 13/07/2012
 p_is_creation_success := 'Y'; -- Initialize to success

 OPEN get_visit_type_duration (p_oper_param_rec.visit_type_code,p_oper_param_rec.mc_id);
 FETCH get_visit_type_duration INTO l_visit_type_duration;
 CLOSE get_visit_type_duration;

 l_visit_rec := null;

 SELECT NAME INTO l_visit_rec.UNIT_NAME FROM AHL_UNIT_CONFIG_HEADERS
  WHERE unit_config_header_id= p_flight_schedule_rec.unit_config_header_id;

 -- Populate all the visit attributes
 l_visit_rec.VISIT_TYPE_CODE       := p_oper_param_rec.visit_type_code;
 l_visit_rec.ORGANIZATION_ID       := p_flight_schedule_rec.arrival_org_id;
 l_visit_rec.VISIT_NAME            := 'Auto-Visit';
 l_visit_rec.DEPARTMENT_ID         := NVL(p_oper_param_rec.alternate_dep_id, p_flight_schedule_rec.arrival_dept_id);

 l_start_date := p_flight_schedule_rec.est_arrival_time;
 l_start_date_ts := cast(l_start_date as timestamp);
 l_start_hour := (extract(HOUR from l_start_date_ts));
 l_start_min := (extract(MINUTE from l_start_date_ts));

 --l_end_date := p_flight_schedule_rec.est_arrival_time + l_visit_type_duration/24;
 l_end_date := l_start_date + l_visit_type_duration/24;
 l_end_date_ts := cast(l_end_date as timestamp);
 l_end_hour := (extract(HOUR from l_end_date_ts));
 l_end_min := (extract(MINUTE from l_end_date_ts));

 l_visit_rec.START_DATE            := trunc(l_start_date);
 l_visit_rec.START_HOUR            := l_start_hour;
 l_visit_rec.START_MIN             := l_start_min;
 l_visit_rec.PLAN_END_DATE         := trunc(l_end_date);
 l_visit_rec.PLAN_END_HOUR         := l_end_hour;
 l_visit_rec.PLAN_END_MIN          := l_end_min;
 l_visit_rec.VISIT_CREATE_TYPE     := 'PLANNING';
 l_visit_rec.UNIT_SCHEDULE_ID      := p_flight_schedule_rec.unit_schedule_id;
 l_visit_rec.AUTO_VISIT_TYPE_FLAG  := 'A';--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

 l_visit_rec.PRICING_FLAG          := 'N';--PRAKKUM :: 09/02/2016 :: BUG 22680167

 --PRAKKUM :: 24/02/2016 :: Bug 22877137
 OPEN get_item_owner_details(p_flight_schedule_rec.unit_config_header_id);
 FETCH get_item_owner_details INTO l_visit_rec.CUSTOMER_ID;
 CLOSE get_item_owner_details;

 -- Check if the visit org is in the current OU
 l_is_org_in_curr_OU := null;
 OPEN is_org_in_current_OU (l_visit_rec.ORGANIZATION_ID);
 FETCH is_org_in_current_OU INTO l_is_org_in_curr_OU;
 CLOSE is_org_in_current_OU;

 IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_start_date --@>'||cast(l_start_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_end_date --@>'||cast(l_end_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'p_present_time --@>'||cast(p_present_time as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'mo_global.get_current_org_id() --@>'||mo_global.get_current_org_id());
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_visit_rec.ORGANIZATION_ID --@>'||l_visit_rec.ORGANIZATION_ID);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_is_org_in_curr_OU --@>'||l_is_org_in_curr_OU);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'CUSTOMER_ID --@>'|| l_visit_rec.CUSTOMER_ID);
 END IF;

  -- Bug 14336486 :: PRAKKUM :: 13/07/2012
 IF l_start_date < p_present_time THEN -- If arrival time is in past, do not create a visit

    OPEN get_flight_details(p_flight_schedule_rec.unit_schedule_id);
    FETCH get_flight_details INTO flt_dets_rec;
    CLOSE get_flight_details;

    -- Do not create a visit
    fnd_file.put_line(fnd_file.log, 'Validation Failure: No arrival visit created, since visit start date for flight '||flt_dets_rec.flight_number||' is deriving to past.');
    p_is_creation_success := 'N'; -- Flag as creation failed due to validations

 ELSE
   -- IF the visit org is NOT in current OU, do not create the visit
   IF l_is_org_in_curr_OU = 'X' THEN
     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
             ( fnd_log.level_procedure,
               'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
               'Before calling AHL_VWP_VISITS_PVT.Create_Visit autovst_oper_id: '||p_oper_param_rec.autovst_oper_id);
     END IF;
     AHL_VWP_VISITS_PVT.Create_Visit (
                                         p_api_version => 1.0,
                                         p_module_type => 'API',
                                         p_x_visit_rec  => l_visit_rec,
                                         x_return_status => l_return_status,
                                         x_msg_count => x_msg_count,
                                         x_msg_data => x_msg_data
                                         );

     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
               fnd_log.string
               ( fnd_log.level_procedure,
                 'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                 'After calling AHL_VWP_VISITS_PVT.Create_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
     END IF;
     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: START
     IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
           l_pub_msg := FND_MSG_PUB.Get_Detail (p_msg_index => FND_MSG_PUB.G_LAST);
           IF (l_pub_msg like '%AHL_VWP_PRD_MR_ASSOC_FAIL%') THEN
             IF (l_log_statement >= l_log_current_level) THEN
               fnd_log.string
               ( l_log_statement,
                 L_DEBUG_KEY,
                 'visit id= '||l_visit_rec.visit_id || 'Had problems with the MRs associated. So arrival visit creation is not successful.');
             END IF;
             x_return_status := FND_API.G_RET_STS_SUCCESS;
             p_is_creation_success := 'N'; -- Flag as creation of visit failed due to validations
             -- Remove message from FND
             FND_MSG_PUB.Delete_Msg(p_msg_index => FND_MSG_PUB.count_msg);

             OPEN get_flight_details(p_flight_schedule_rec.unit_schedule_id);
             FETCH get_flight_details INTO flt_dets_rec;
             CLOSE get_flight_details;

             fnd_file.put_line(fnd_file.log, 'Validation Failure: Had problems with the MRs associated. So arrival visit creation for flight '||flt_dets_rec.flight_number||' is not successful.');
           ELSE
             x_return_status := l_return_status ;
             x_msg_count := FND_MSG_PUB.count_msg;
             IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,
                                 L_DEBUG_KEY,
                                 'Errors from Create_Visit. Message count: ' || x_msg_count);
             END IF;
             IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                RAISE FND_API.G_EXC_ERROR;
             ELSE
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
             END IF;
           END IF;
     ELSE
           x_return_status := l_return_status ;
           l_visit_number := NULL;
           OPEN get_visit_number(l_visit_rec.visit_id);
           FETCH get_visit_number INTO l_visit_number;
           CLOSE get_visit_number;
           fnd_file.put_line(fnd_file.log, 'Created arrival visit number -> '||l_visit_number);
         -- End of logging
     END IF;
     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: END
   END IF; -- IF l_is_org_in_curr_OU = 'X'
 END IF; -- l_start_date < p_present_time

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.end',
                     'At the end of PL SQL function.');
 END IF;
EXCEPTION
 WHEN FND_API.G_EXC_ERROR THEN
   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Create_Arr_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Create_Arr_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Create_Arr_visit_pvt;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Create_Arrival_visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;
    FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Create_Arrival_visit;

---------------------------------------------------------------------------------------
-- PROCEDURE
--    Create_Downtime_visit
--  Type   : Private
--
-- PURPOSE
--    To create a downtime visit at arrival organization of the flight
--
--  Parameters :
--  Create_Downtime_visit Parameters
--      p_oper_param_rec         IN oper_param_rec_type Required
--      p_flight_schedule_rec    IN flight_schedule_rec_type Required
--
--  Standard OUT Parameters :
--      x_return_status           OUT     VARCHAR2     Required
--      x_msg_count               OUT     NUMBER       Required
--      x_msg_data                OUT     VARCHAR2     Required
--
----------------------------------------------------------------------------------------

PROCEDURE Create_Downtime_visit(
    p_oper_param_rec       IN      oper_param_rec_type,
    p_flight_schedule_rec  IN      flight_schedule_rec_type,
    p_present_time         IN      DATE, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    p_is_creation_success  OUT NOCOPY VARCHAR2, -- Bug 14336467 :: PRAKKUM :: 13/07/2012
    x_return_status        OUT NOCOPY     VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2)
IS

--cursor that checks if there is any succeeding flight for this flight schedule
Cursor get_succeeding_us_det (c_fs_id IN NUMBER)
 IS
 SELECT UNIT_SCHEDULE_ID, EST_DEPARTURE_TIME FROM AHL_UNIT_SCHEDULES
 WHERE  preceding_us_id = c_fs_id;

Cursor is_org_in_current_OU (c_org_id IN NUMBER)
IS
SELECT 'X'
FROM org_organization_definitions hou
WHERE hou.organization_id                                  = c_org_id
AND NVL(hou.operating_unit,mo_global.get_current_org_id()) = mo_global.get_current_org_id();

-- Cursor to get the visit Number from visit_id
CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

-- Bug 14336467 :: PRAKKUM :: 12/07/2012
-- Cursor to get visit type duration
CURSOR get_visit_type_dur(c_vst_type_code IN VARCHAR2, c_mc_id IN NUMBER) IS
select estimated_duration from ahl_visit_types_vl
where
visit_type_code = c_vst_type_code
and mc_id = c_mc_id
and status_code = 'COMPLETE';

--Added cursor to get flight details for loggin :: PRAKKUM :: 01/08/2012
Cursor get_flight_details (c_us_id IN NUMBER)
IS
SELECT flight_number
FROM ahl_unit_schedules
WHERE unit_schedule_id  = c_us_id;
flt_dets_rec get_flight_details%RowType;

--PRAKKUM :: 24/02/2016 :: Bug 22877137
CURSOR get_item_owner_details(c_uc_id IN NUMBER)
IS
SELECT PARTY_ID CUSTOMER_ID FROM
   AHL_UNIT_CONFIG_HEADERS UC,
   CSI_ITEM_INSTANCES CSIS,
   HZ_PARTIES HZP
WHERE UC.CSI_ITEM_INSTANCE_ID=CSIS.INSTANCE_ID
AND CSIS.ACTIVE_START_DATE <= SYSDATE
AND NVL(CSIS.ACTIVE_END_DATE,SYSDATE) >= SYSDATE
AND  CSIS.INV_MASTER_ORGANIZATION_ID IN
     ( SELECT MASTER_ORGANIZATION_ID FROM
               INV_ORGANIZATION_INFO_V ORG,
               MTL_PARAMETERS MP
               WHERE ORG.ORGANIZATION_ID = MP.ORGANIZATION_ID
               AND NVL(OPERATING_UNIT,MO_GLOBAL.GET_CURRENT_ORG_ID()) = MO_GLOBAL.GET_CURRENT_ORG_ID())
AND CSIS.OWNER_PARTY_ID = HZP.PARTY_ID(+)
AND NVL(HZP.PARTY_TYPE,'NO_VAL') IN ('NO_VAL', 'PERSON' , 'ORGANIZATION' )
AND UC.UNIT_CONFIG_HEADER_ID = c_uc_id;

  L_API_NAME             CONSTANT VARCHAR2(30) := 'Create_Downtime_visit';
  L_DEBUG_KEY            CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
  l_visit_rec            AHL_VWP_VISITS_PVT.Visit_Rec_Type;
  l_is_org_in_curr_OU    VARCHAR2(1);
  l_visit_number         NUMBER;
  l_start_date_ts        TIMESTAMP;
  l_end_date_ts          TIMESTAMP;
  l_start_date           DATE;
  l_start_hour           NUMBER;
  l_start_min            NUMBER;
  l_end_date             DATE;
  l_end_hour             NUMBER;
  l_end_min              NUMBER;
  l_return_status        VARCHAR2(1);
  l_succeeding_us_id     NUMBER;
  l_succ_dep_time        DATE;
  l_vst_type_est_dur     NUMBER;  -- Bug 14336486 :: PRAKKUM :: 12/07/2012
  -- SATRAJEN :: Bug 14336467 :: Prevent erroring out in case of Operational visit.
  l_pub_msg              VARCHAR2(2000);

BEGIN

 SAVEPOINT Create_Downtime_visit_pvt;

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.begin',
                     'At the start of PL SQL function.');
 END IF;

 -- initialize procedure return status to success
 x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Bug 14336467 :: PRAKKUM :: 13/07/2012
 p_is_creation_success := 'Y'; -- Initialize to success

 l_visit_rec := null;
 SELECT NAME INTO l_visit_rec.UNIT_NAME FROM AHL_UNIT_CONFIG_HEADERS
  WHERE unit_config_header_id= p_flight_schedule_rec.unit_config_header_id;

  OPEN get_succeeding_us_det (p_flight_schedule_rec.unit_schedule_id);
  FETCH get_succeeding_us_det INTO l_succeeding_us_id, l_succ_dep_time;
  CLOSE get_succeeding_us_det;

 -- Populate all the visit attributes
 l_visit_rec.VISIT_TYPE_CODE       := p_oper_param_rec.visit_type_code;
 l_visit_rec.ORGANIZATION_ID       := p_flight_schedule_rec.arrival_org_id;
 l_visit_rec.VISIT_NAME            := 'Auto-Visit';
 l_visit_rec.DEPARTMENT_ID         := NVL(p_oper_param_rec.alternate_dep_id, p_flight_schedule_rec.arrival_dept_id);

 l_start_date := p_flight_schedule_rec.est_arrival_time;
 l_start_date_ts := cast(l_start_date as timestamp);
 l_start_hour := (extract(HOUR from l_start_date_ts));
 l_start_min := (extract(MINUTE from l_start_date_ts));

 l_end_date := l_succ_dep_time;
 l_end_date_ts := cast(l_end_date as timestamp);
 l_end_hour := (extract(HOUR from l_end_date_ts));
 l_end_min := (extract(MINUTE from l_end_date_ts));

 -- Bug 14336486 :: PRAKKUM :: 12/07/2012 :: START

 OPEN  get_visit_type_dur(p_oper_param_rec.visit_type_code, p_oper_param_rec.mc_id);
 FETCH get_visit_type_dur INTO l_vst_type_est_dur;
 CLOSE get_visit_type_dur;

 IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement, L_DEBUG_KEY, 'p_oper_param_rec.visit_type_code--@>' || p_oper_param_rec.visit_type_code);
    fnd_log.string(l_log_statement, L_DEBUG_KEY, 'p_oper_param_rec.mc_id--@>' ||  p_oper_param_rec.mc_id);
    fnd_log.string(l_log_statement, L_DEBUG_KEY, 'l_vst_type_est_dur--@>' ||  l_vst_type_est_dur);
 END IF;

 OPEN get_flight_details(p_flight_schedule_rec.unit_schedule_id);
 FETCH get_flight_details INTO flt_dets_rec;
 CLOSE get_flight_details;

 IF (l_start_date < p_present_time ) THEN
   fnd_file.put_line(fnd_file.log, 'Validation Failure: No downtime visit created, since visit start date for flight '||flt_dets_rec.flight_number||' is deriving to past');
   p_is_creation_success := 'N'; -- Flag as creation of visit failed due to validations
 END IF;

 -- SATRAJEN :: BUG 14475778 :: Checking the condition only if p_is_creation_success := Y from previous contidition :: 13-AUG-2012
 -- SATRAJEN :: BUG 14481051 :: Calculation prob in l_vst_type_est_dur :: 13-AUG-2012
 --IF (l_end_date - l_vst_type_est_dur) < l_start_date THEN
 IF ((p_is_creation_success<>'N') AND ((l_end_date - (l_vst_type_est_dur/24)) < l_start_date)) THEN
   fnd_file.put_line(fnd_file.log, 'Validation Failure: No downtime visit created, since duration of visit for flight '||flt_dets_rec.flight_number||' is lesser than visit type duration');
   p_is_creation_success := 'N'; -- Flag as creation of visit failed due to validations
 END IF;

 -- Bug 14336486 :: PRAKKUM :: 12/07/2012 :: END

 l_visit_rec.START_DATE            := trunc(l_start_date);
 l_visit_rec.START_HOUR            := l_start_hour;
 l_visit_rec.START_MIN             := l_start_min;
 l_visit_rec.PLAN_END_DATE         := trunc(l_end_date);
 l_visit_rec.PLAN_END_HOUR         := l_end_hour;
 l_visit_rec.PLAN_END_MIN          := l_end_min;
 l_visit_rec.VISIT_CREATE_TYPE     := 'PLANNING';
 l_visit_rec.UNIT_SCHEDULE_ID      := p_flight_schedule_rec.unit_schedule_id;
 l_visit_rec.AUTO_VISIT_TYPE_FLAG  := 'T';--TCHIMIRA :: 14-Jun-2012 :: ER 14015560

 l_visit_rec.PRICING_FLAG          := 'N';--PRAKKUM :: 09/02/2016 :: BUG 22680167

 --PRAKKUM :: 24/02/2016 :: Bug 22877137
 OPEN get_item_owner_details(p_flight_schedule_rec.unit_config_header_id);
 FETCH get_item_owner_details INTO l_visit_rec.CUSTOMER_ID;
 CLOSE get_item_owner_details;

 -- Check if the visit org is in the current OU
 l_is_org_in_curr_OU := null;
 OPEN is_org_in_current_OU (l_visit_rec.ORGANIZATION_ID);
 FETCH is_org_in_current_OU INTO l_is_org_in_curr_OU;
 CLOSE is_org_in_current_OU;

 IF (l_log_statement >= l_log_current_level) THEN
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_start_date --@>'||cast(l_start_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_end_date --@>'||cast(l_end_date as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'p_present_time --@>'||cast(p_present_time as timestamp));
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'mo_global.get_current_org_id() --@>'||mo_global.get_current_org_id());
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_visit_rec.ORGANIZATION_ID --@>'||l_visit_rec.ORGANIZATION_ID);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'l_is_org_in_curr_OU --@>'||l_is_org_in_curr_OU);
    fnd_log.string(l_log_statement, L_DEBUG_KEY , 'CUSTOMER_ID --@>'|| l_visit_rec.CUSTOMER_ID);
 END IF;


 -- Bug 14336486 :: PRAKKUM :: 12/07/2012
 IF p_is_creation_success<>'N' THEN --Don't create a downtime visit, if visit duration is going to be lesser than visit type duration
   -- IF the visit org is NOT in current OU, do not create the visit
   IF l_is_org_in_curr_OU = 'X' THEN
     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
              fnd_log.string
             ( fnd_log.level_procedure,
               'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
               'Before calling AHL_VWP_VISITS_PVT.Create_Visit autovst_oper_id: '||p_oper_param_rec.autovst_oper_id);
     END IF;
     AHL_VWP_VISITS_PVT.Create_Visit (
                                         p_api_version => 1.0,
                                         p_module_type => 'API',
                                         p_x_visit_rec  => l_visit_rec,
                                         x_return_status => l_return_status,
                                         x_msg_count => x_msg_count,
                                         x_msg_data => x_msg_data
                                         );

     IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
               fnd_log.string
               ( fnd_log.level_procedure,
                 'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
                 'After calling AHL_VWP_VISITS_PVT.Create_Visit, l_return_status= '||l_return_status||', visit id= '||l_visit_rec.visit_id);
     END IF;

     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: START
     IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         l_pub_msg := FND_MSG_PUB.Get_Detail (p_msg_index => FND_MSG_PUB.G_LAST);
         IF (l_pub_msg like '%AHL_VWP_PRD_MR_ASSOC_FAIL%') THEN
           IF (l_log_statement >= l_log_current_level) THEN
             fnd_log.string
             ( l_log_statement,
               L_DEBUG_KEY,
               'visit id= '||l_visit_rec.visit_id || 'Had problems with the MRs associated. So downtime visit creation is not successful. ');
           END IF;
           x_return_status := FND_API.G_RET_STS_SUCCESS;
           p_is_creation_success := 'N'; -- Flag as creation of visit failed due to validations
           -- Remove message from FND
           FND_MSG_PUB.Delete_Msg(p_msg_index => FND_MSG_PUB.count_msg);
           fnd_file.put_line(fnd_file.log, 'Validation Failure: Had problems with the MRs associated. So downtime visit creation for flight '||flt_dets_rec.flight_number||' is not successful.');
         ELSE
           x_return_status := l_return_status ;
           x_msg_count := FND_MSG_PUB.count_msg;
           IF (l_log_statement >= l_log_current_level) THEN
                  fnd_log.string(l_log_statement,
                                 L_DEBUG_KEY,
                                 'Errors from Create_Visit. Message count: ' || x_msg_count);
           END IF;
           IF l_return_status = FND_API.G_RET_STS_ERROR THEN
             RAISE FND_API.G_EXC_ERROR;
           ELSE
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
         END IF;
      ELSE
           x_return_status := l_return_status ;
           l_visit_number := NULL;
           OPEN get_visit_number(l_visit_rec.visit_id);
           FETCH get_visit_number INTO l_visit_number;
           CLOSE get_visit_number;
           fnd_file.put_line(fnd_file.log, 'Created downtime visit number -> '||l_visit_number);
         -- End of logging
     END IF;
     -- SATRAJEN :: Bug 14336467 :: Prevent Erroring out when the called from Operational Visit Procedure. :: END
   END IF; -- IF l_is_org_in_curr_OU = 'X'
 END IF; -- (l_end_date - l_vst_type_est_dur) > l_start_date

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.end',
                     'At the end of PL SQL function.');
 END IF;
EXCEPTION
 WHEN FND_API.G_EXC_ERROR THEN
   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Create_Downtime_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Create_Downtime_visit_pvt;
   FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Create_Downtime_visit_pvt;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Create_Downtime_visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;
    FND_MSG_PUB.count_and_get(p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Create_Downtime_visit;

---------------------------------------------------------------------------------------
-- PROCEDURE
--    Delete_Oper_Visit
-- Type             : Private
-- PURPOSE
--    To delete the passed operational visit
----------------------------------------------------------------------------------------

PROCEDURE Delete_Oper_Visit(
    p_visit_id       IN   NUMBER,
    x_return_status  OUT NOCOPY  VARCHAR2)
IS

--Cursor to get planned UEs
-- SATRAJEN :: Bug 14464977 :: Changed for retrieving the Non Routines also :: Aug 2012
/*Cursor get_visit_planned_ues(c_visit_id IN NUMBER)
IS
SELECT distinct unit_effectivity_id
FROM AHL_VISIT_TASKS_B
WHERE VISIT_ID = c_visit_id
 AND TASK_TYPE_CODE = 'PLANNED';*/
Cursor get_visit_planned_ues(c_visit_id IN NUMBER)
IS
SELECT unit_effectivity_id
FROM AHL_VISIT_TASKS_B
WHERE VISIT_ID = c_visit_id
AND TASK_TYPE_CODE = 'PLANNED' AND SERVICE_REQUEST_ID IS NULL
UNION
SELECT unit_effectivity_id
FROM AHL_VISIT_TASKS_B
WHERE VISIT_ID = c_visit_id
AND TASK_TYPE_CODE = 'SUMMARY' AND originating_task_id IS NULL AND SERVICE_REQUEST_ID IS NOT NULL;


L_API_NAME             CONSTANT VARCHAR2(30) := 'Delete_Oper_Visit';
L_DEBUG_KEY            CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
l_ue_ids               VARCHAR2(4000);
l_return_status        VARCHAR2(1);
l_msg_count                  NUMBER;
l_msg_data                   VARCHAR2(2000);
x_item_key             VARCHAR2(100);

BEGIN

 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
     fnd_log.string
     ( fnd_log.level_procedure,
             L_DEBUG_KEY||'.begin',
             'Before calling AHL_VWP_VISITS_PVT.Delete_Visit, visit id: '||p_visit_id);
 END IF;

 -- PRAKKUM :: Bug 14334961 :: 18/07/2012 :: Get planned ues before deleting the visit
 --Get all the planned ue ids for this visit so as to pass it to notification
 l_ue_ids := null;
 FOR l_planned_ue_id_rec IN get_visit_planned_ues(p_visit_id) LOOP
  IF l_ue_ids IS NULL THEN
     l_ue_ids := to_char(l_planned_ue_id_rec.unit_effectivity_id);
  ELSE
     l_ue_ids := l_ue_ids || ',' || to_char(l_planned_ue_id_rec.unit_effectivity_id);
  END IF;
 END LOOP;

 AHL_VWP_VISITS_PVT.Delete_Visit (
                        p_api_version => 1.0,
                        p_visit_id => p_visit_id,
                        x_return_status => l_return_status,
                        x_msg_count => l_msg_count,
                        x_msg_data => l_msg_data
                        );

 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
     fnd_log.string
          ( fnd_log.level_procedure,
           'ahl.plsql.'||g_pkg_name||'.'||l_api_name||':',
           'After calling AHL_VWP_VISITS_PVT.Delete_Visit, l_return_status= '||l_return_status);
 END IF;
 x_return_status := l_return_status ;
 IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
    l_msg_count := FND_MSG_PUB.count_msg;
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,
                       L_DEBUG_KEY,
                       'Errors from Delete_Visit. Message count: ' || l_msg_count);
    END IF;
    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
    ELSE
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
 END IF;  -- Return Status is not Success

 -- Also send a visit cancel notification
 -- if no planned UEs associated to the visit, then do not send notification
 IF l_ue_ids is not null then
    AHL_AVF_OPER_VSTS_PVT.Launch_Visit_Can_Notification (
                 p_visit_id        => p_visit_id,
                 p_ue_ids          => l_ue_ids,
                 p_commit          => Fnd_Api.g_false ,
                 x_item_key        => x_item_key,
                 x_return_status   => l_return_status );
    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        l_msg_count := FND_MSG_PUB.count_msg;
        IF (l_log_statement >= l_log_current_level) THEN
           fnd_log.string(l_log_statement,
                          L_DEBUG_KEY,
                          'Errors from Launch_Visit_Can_Notification ' );
        END IF;
        IF l_return_status = FND_API.G_RET_STS_ERROR THEN
           RAISE FND_API.G_EXC_ERROR;
        ELSE
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
    END IF;  -- Return Status is not Success
 END IF; --IF l_ue_ids is not null then

 IF (l_log_procedure >= l_log_current_level) THEN
      fnd_log.string(l_log_procedure,
                     L_DEBUG_KEY ||'.end',
                     'At the end of PL SQL function.');
 END IF;

END Delete_Oper_Visit;
--TCHIMIRA :: 14-Jun-2012 :: end

--------------------------------------------------------------------
-- PROCEDURE
--    Process_Operational_visits
--
-- PURPOSE
--    Made as an executable for the P2P CP
--  Process_Operational_visits Parameters :
--      errbuf              OUT   VARCHAR2   Required
--         Defines in pl/sql to store procedure to get error messages into log file
--      retcode             OUT   NUMBER     Required
--         To get the status of the concurrent program

--------------------------------------------------------------------
PROCEDURE Process_Operational_visits(
    errbuf            OUT NOCOPY VARCHAR2,
    retcode           OUT NOCOPY NUMBER,
    p_api_version     IN  NUMBER,
    p_oper_flag       IN  VARCHAR2
)
IS


-- Local variables section
l_msg_count             NUMBER;
l_msg_data              VARCHAR2(2000);
l_return_status         VARCHAR2(1);
l_api_version           NUMBER := 1.0;
l_api_name              VARCHAR2(30) := 'Process_Operational_visits';
l_err_msg               VARCHAR2(2000);
l_msg_index_out         NUMBER;

BEGIN

   -- Standard start of API savepoint
   SAVEPOINT Process_Operational_visits;

   -- 1. Initialize error message stack by default
   FND_MSG_PUB.Initialize;

   -- Standard call to check for call compatibility
   IF NOT FND_API.Compatible_API_Call(l_api_version, p_api_version, l_api_name, G_PKG_NAME) THEN
      retcode := 2;
      errbuf := FND_MSG_PUB.Get;
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   -- 2. Dump all input parameters
   fnd_file.put_line(fnd_file.log, '*************API input parameters**************');
   fnd_file.put_line(fnd_file.log, 'p_oper_flag -> '|| p_oper_flag);
   fnd_file.put_line(fnd_file.log, 'fnd_global.USER_ID -> '|| fnd_global.USER_ID);
   fnd_file.put_line(fnd_file.log, 'fnd_global.RESP_ID -> '||fnd_global.RESP_ID);
   fnd_file.put_line(fnd_file.log, 'fnd_global.PROG_APPL_ID -> '|| fnd_global.PROG_APPL_ID);
   fnd_file.put_line(fnd_file.log, 'mo_global.get_current_org_id -> '|| mo_global.get_current_org_id());


   IF p_oper_flag = 'C' THEN

      fnd_file.put_line(fnd_file.log, 'before calling Create_Oper_Visit');

      Create_Oper_Visit (
                          p_api_version => 1.0,
                          p_init_msg_list => FND_API.G_FALSE,
                          p_commit => FND_API.G_FALSE,
                          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                          x_return_status => l_return_status,
                          x_msg_count => l_msg_count,
                          x_msg_data => l_msg_data
                         );

       l_msg_count := FND_MSG_PUB.Count_Msg;
       IF (l_msg_count > 0) THEN
          fnd_file.put_line(fnd_file.log, 'Following error occured during the call to Create_Oper_Visit..');
          IF (l_return_status = FND_API.G_RET_STS_ERROR) THEN
              RAISE FND_API.G_EXC_ERROR;
          ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
          COMMIT WORK;
       END IF;


   ELSIF p_oper_flag = 'U' THEN

      fnd_file.put_line(fnd_file.log, 'before calling Update_Oper_Visit');

      Update_Oper_Visit (
                         p_api_version => 1.0,
                         p_init_msg_list => FND_API.G_FALSE,
                         p_commit => FND_API.G_FALSE,
                         p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                         x_return_status => l_return_status,
                         x_msg_count => l_msg_count,
                         x_msg_data => l_msg_data
                        );

       l_msg_count := FND_MSG_PUB.Count_Msg;
       IF (l_msg_count > 0) THEN
          fnd_file.put_line(fnd_file.log, 'Following error occured during the call to Update_Oper_Visit..');
          IF (l_return_status = FND_API.G_RET_STS_ERROR) THEN
              RAISE FND_API.G_EXC_ERROR;
          ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
          COMMIT WORK;
       END IF;

   END IF;

EXCEPTION
 WHEN FND_API.G_EXC_ERROR THEN
   ROLLBACK TO Process_Operational_visits;
   retcode := 2;
   FOR i IN 1..l_msg_count
       LOOP
         fnd_msg_pub.get( p_msg_index => i,
                          p_encoded   => FND_API.G_FALSE,
                          p_data      => l_err_msg,
                          p_msg_index_out => l_msg_index_out);

         fnd_file.put_line(FND_FILE.LOG, 'Err message-'||l_msg_index_out||':' || l_err_msg);
       END LOOP;


 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   ROLLBACK TO Process_Operational_visits;
   retcode := 2;
   l_msg_count := Fnd_Msg_Pub.count_msg;
   FOR i IN 1..l_msg_count
       LOOP
         fnd_msg_pub.get( p_msg_index => i,
                          p_encoded   => FND_API.G_FALSE,
                          p_data      => l_err_msg,
                          p_msg_index_out => l_msg_index_out);

         fnd_file.put_line(FND_FILE.LOG, 'Err message-'||l_msg_index_out||':' || l_err_msg);
       END LOOP;


 WHEN OTHERS THEN
   ROLLBACK TO Process_Operational_visits;
   retcode := 2;
   IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
     fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                             p_procedure_name => 'Process_Operational_visits',
                             p_error_text     => SUBSTR(SQLERRM,1,500));
   END IF;
   l_msg_count := Fnd_Msg_Pub.count_msg;
   FOR i IN 1..l_msg_count
     LOOP
        fnd_msg_pub.get( p_msg_index => i,
                         p_encoded   => FND_API.G_FALSE,
                         p_data      => l_err_msg,
                         p_msg_index_out => l_msg_index_out);

        fnd_file.put_line(FND_FILE.LOG, 'Err message-'||l_msg_index_out||':' || l_err_msg);
     END LOOP;


END Process_Operational_visits;

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Can_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a Visit is cancelled
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Can_Notification Parameters:
--       p_visit_id               IN     Visit Id                                       Required
--       p_ue_ids                 IN     Unit Effectivity Ids concatenated by using ',' Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Can_Notification (
    p_visit_id                    IN              NUMBER,
    p_ue_ids                      IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Launch_Visit_Can_Notification';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;

l_msg_count             NUMBER;
l_msg_data              VARCHAR2(4000);
l_active_flag           VARCHAR2(1);
l_process_name          VARCHAR2(30);
l_item_type             VARCHAR2(8);
l_subject               FND_NEW_MESSAGES.message_text%TYPE;
--

BEGIN
    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       '  Visit ID > '||p_visit_id||
                       '  UE IDs > '||p_ue_ids||
                       ', p_commit > '||p_commit);
    END IF;

    -- check for the Visit Id
    IF (p_visit_id IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_VWP_INVALID_VST'); -- Visit id is invalid.
        FND_MESSAGE.Set_Token('VISIT_ID', p_visit_id);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- check for the Unit Effectivity ID
    IF (p_ue_ids IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_UMP_UE_ID_INVALID'); -- Unit Effectivity Id (UEID) is invalid
        FND_MESSAGE.Set_Token('UEID', p_ue_ids);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- get the details of the Workflow process mapped to the object G_WF_CANC_OBJ
    AHL_UTILITY_PVT.Get_WF_Process_Name(
        p_object        => G_WF_CANC_OBJ,
        x_active        => l_active_flag,
        x_process_name  => l_process_name ,
        x_item_type     => l_item_type,
        x_msg_count     => l_msg_count,
        x_msg_data      => l_msg_data,
        x_return_status => x_return_status);

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the returned values from AHL_UTILITY_PVT.Get_WF_Process_Name : '||
                       '  l_active_flag > '||l_active_flag||
                       ', l_process_name > '||l_process_name||
                       ', l_item_type > '||l_item_type||
                       ', x_return_status > '||x_return_status);
    END IF;

    -- if returned with error, don't proceed any further
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RETURN;
    END IF;

    -- if the mapping is active, call the notification API
    If (l_active_flag = 'Y') THEN
        -- get the subject text
        l_subject := FND_MESSAGE.GET_STRING(G_APP_NAME, G_VISIT_CANC_SBJ);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'before calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification with arguments: '||
                           '  p_object > '||G_WF_CANC_OBJ||
                           ', p_process_name > '||l_process_name||
                           ', p_item_type > '||l_item_type||
                           ', p_subject > '||l_subject||
                           ', p_oa_function > '||G_VISIT_CANCEL_FN||
                           ', p_param1_name > '||G_VISIT_ID_FN_PARAM1||
                           ', p_param1_value > '||p_visit_id||
                           ', p_param2_name > '||G_UE_IDS_FN_PARAM2||
                           ', p_param2_value > '||p_ue_ids);
        END IF;

        -- call AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification
        AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification(
            p_object        => G_WF_CANC_OBJ,
            p_process_name  => l_process_name,
            p_item_type     => l_item_type,
            p_subject       => l_subject,
            p_oa_function   => G_VISIT_CANCEL_FN,
            p_param1_name   => G_VISIT_ID_FN_PARAM1,
            p_param2_name   => G_UE_IDS_FN_PARAM2,
            p_param1_value  => TO_CHAR(p_visit_id),
            p_param2_value  => p_ue_ids,
            p_param3_name   => G_PAGE_FUNC_PARAM3,
            p_param3_value  => G_VISIT_CANCEL_FN,
            x_item_key      => x_item_key,
            x_return_status => x_return_status);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'after calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification, '||
                           '  x_item_key > '||x_item_key||
                           ', x_return_status > '||x_return_status);
        END IF;

        -- if returned with error, don't proceed any further
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RETURN;
        END IF;
    END IF;

    -- Standard check of p_commit
    IF FND_API.TO_BOOLEAN(p_commit) THEN
        COMMIT WORK;
    END IF;

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

END Launch_Visit_Can_Notification;
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_SCE_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a Visit UE's Service Category is greater
--                      than the visit's organization and department service category
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_SCE_Notification Parameters:
--       p_visit_id               IN     Visit Id                                       Required
--       p_ue_ids                 IN     Unit Effectivity Ids concatenated by using ',' Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_SCE_Notification (
    p_visit_id                    IN              NUMBER,
    p_ue_ids                      IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Launch_Visit_SCE_Notification';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;

l_msg_count             NUMBER;
l_msg_data              VARCHAR2(4000);
l_active_flag           VARCHAR2(1);
l_process_name          VARCHAR2(30);
l_item_type             VARCHAR2(8);
l_subject               FND_NEW_MESSAGES.message_text%TYPE;
--

BEGIN
    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       '  Visit ID > '||p_visit_id||
                       '  UE IDs > '||p_ue_ids||
                       ', p_commit > '||p_commit);
    END IF;

    -- check for the Visit Id
    IF (p_visit_id IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_VWP_INVALID_VST'); -- Visit id is invalid.
        FND_MESSAGE.Set_Token('VISIT_ID', p_visit_id);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- check for the Unit Effectivity ID
    IF (p_ue_ids IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_UMP_UE_ID_INVALID'); -- Unit Effectivity Id (UEID) is invalid
        FND_MESSAGE.Set_Token('UEID', p_ue_ids);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- get the details of the Workflow process mapped to the object G_WF_VSCE_OBJ
    AHL_UTILITY_PVT.Get_WF_Process_Name(
        p_object        => G_WF_VSCE_OBJ,
        x_active        => l_active_flag,
        x_process_name  => l_process_name ,
        x_item_type     => l_item_type,
        x_msg_count     => l_msg_count,
        x_msg_data      => l_msg_data,
        x_return_status => x_return_status);

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the returned values from AHL_UTILITY_PVT.Get_WF_Process_Name : '||
                       '  l_active_flag > '||l_active_flag||
                       ', l_process_name > '||l_process_name||
                       ', l_item_type > '||l_item_type||
                       ', x_return_status > '||x_return_status);
    END IF;

    -- if returned with error, don't proceed any further
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RETURN;
    END IF;

    -- if the mapping is active, call the notification API
    If (l_active_flag = 'Y') THEN
        -- get the subject text
        l_subject := FND_MESSAGE.GET_STRING(G_APP_NAME, G_VISIT_USCE_SBJ);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'before calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification with arguments: '||
                           '  p_object > '||G_WF_VSCE_OBJ||
                           ', p_process_name > '||l_process_name||
                           ', p_item_type > '||l_item_type||
                           ', p_subject > '||l_subject||
                           ', p_oa_function > '||G_VISIT_USCE_FN||
                           ', p_param1_name > '||G_VISIT_ID_FN_PARAM1||
                           ', p_param1_value > '||p_visit_id||
                           ', p_param2_name > '||G_UE_IDS_FN_PARAM2||
                           ', p_param2_value > '||p_ue_ids);
        END IF;

        -- call AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification
        AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification(
            p_object        => G_WF_VSCE_OBJ,
            p_process_name  => l_process_name,
            p_item_type     => l_item_type,
            p_subject       => l_subject,
            p_oa_function   => G_VISIT_USCE_FN,
            p_param1_name   => G_VISIT_ID_FN_PARAM1,
            p_param2_name   => G_UE_IDS_FN_PARAM2,
            p_param1_value  => TO_CHAR(p_visit_id),
            p_param2_value  => p_ue_ids,
            p_param3_name   => G_PAGE_FUNC_PARAM3,
            p_param3_value  => G_VISIT_USCE_FN,
            x_item_key      => x_item_key,
            x_return_status => x_return_status);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'after calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification, '||
                           '  x_item_key > '||x_item_key||
                           ', x_return_status > '||x_return_status);
        END IF;

        -- if returned with error, don't proceed any further
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RETURN;
        END IF;
    END IF;

    -- Standard check of p_commit
    IF FND_API.TO_BOOLEAN(p_commit) THEN
        COMMIT WORK;
    END IF;

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

END Launch_Visit_SCE_Notification;
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Disc_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a visit is disconnected from the flight
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Disc_Notification Parameters:
--       p_unit_schedule_id       IN     Unit Schedule Id                                Required
--       p_visit_ids              IN     Visit Ids affected by the flight               Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Disc_Notification (
    p_unit_schedule_id            IN              NUMBER,
    p_visit_ids                   IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Launch_Visit_Disc_Notification';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;

l_msg_count             NUMBER;
l_msg_data              VARCHAR2(4000);
l_active_flag           VARCHAR2(1);
l_process_name          VARCHAR2(30);
l_item_type             VARCHAR2(8);
l_subject               FND_NEW_MESSAGES.message_text%TYPE;
--

BEGIN
    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       'Unit Schedule Id > '||p_unit_schedule_id||
                       '  Visit IDs > '||p_visit_ids||
                       ', p_commit > '||p_commit);
    END IF;

    -- check for the Visit Id
    IF (p_visit_ids IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_VWP_INVALID_VST'); -- Visit id is invalid.
        FND_MESSAGE.Set_Token('VISIT_ID', p_visit_ids);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- check for the Flight Schedule
    IF (p_unit_schedule_id IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_UA_US_NOT_FOUND'); -- Flight Schedule (RECORD) does not exist.
        FND_MESSAGE.Set_Token('RECORD', p_unit_schedule_id);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- get the details of the Workflow process mapped to the object G_WF_DISC_OBJ
    AHL_UTILITY_PVT.Get_WF_Process_Name(
        p_object        => G_WF_DISC_OBJ,
        x_active        => l_active_flag,
        x_process_name  => l_process_name ,
        x_item_type     => l_item_type,
        x_msg_count     => l_msg_count,
        x_msg_data      => l_msg_data,
        x_return_status => x_return_status);

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the returned values from AHL_UTILITY_PVT.Get_WF_Process_Name : '||
                       '  l_active_flag > '||l_active_flag||
                       ', l_process_name > '||l_process_name||
                       ', l_item_type > '||l_item_type||
                       ', x_return_status > '||x_return_status);
    END IF;

    -- if returned with error, don't proceed any further
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RETURN;
    END IF;

    -- if the mapping is active, call the notification API
    If (l_active_flag = 'Y') THEN
        -- get the subject text
        l_subject := FND_MESSAGE.GET_STRING(G_APP_NAME, G_VISIT_DISC_SBJ);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'before calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification with arguments: '||
                           '  p_object > '||G_WF_DISC_OBJ||
                           ', p_process_name > '||l_process_name||
                           ', p_item_type > '||l_item_type||
                           ', p_subject > '||l_subject||
                           ', p_oa_function > '||G_VISIT_DISC_FN||
                           ', p_param1_name > '||G_VISIT_ID_FN_PARAM1||
                           ', p_param1_value > '||p_visit_ids||
                           ', p_param2_name > '||G_UNIT_SCH_ID_FN_PARAM2||
                           ', p_param2_value > '||p_unit_schedule_id);
        END IF;

        -- call AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification
        AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification(
            p_object        => G_WF_DISC_OBJ,
            p_process_name  => l_process_name,
            p_item_type     => l_item_type,
            p_subject       => l_subject,
            p_oa_function   => G_VISIT_DISC_FN,
            p_param1_name   => G_VISIT_ID_FN_PARAM1,
            p_param1_value  => p_visit_ids,
            p_param2_name   => G_UNIT_SCH_ID_FN_PARAM2,
            p_param2_value  => TO_CHAR(p_unit_schedule_id),
            p_param3_name   => G_PAGE_FUNC_PARAM3,
            p_param3_value  => G_VISIT_DISC_FN,
            x_item_key      => x_item_key,
            x_return_status => x_return_status);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'after calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification, '||
                           '  x_item_key > '||x_item_key||
                           ', x_return_status > '||x_return_status);
        END IF;

        -- if returned with error, don't proceed any further
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RETURN;
        END IF;
    END IF;

    -- Standard check of p_commit
    IF FND_API.TO_BOOLEAN(p_commit) THEN
        COMMIT WORK;
    END IF;

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

END Launch_Visit_Disc_Notification;
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Launch_Visit_Dur_Notification
--  Type              : Public
--  Function          : Launches a Workflow notification when a visit is disconnected from the flight
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Dur_Notification Parameters:
--       p_unit_schedule_id       IN     Unit Schedule Id                                Required
--       p_visit_ids              IN     Visit Ids affected by the flight               Required
--       p_commit                 IN     Commit flag. Workflow will be launched only    Required
--                                       after a commit.
--       x_item_key               OUT    Item key of the launched notification          Required
--       x_return_status          OUT    Return status. Item key to be used only if     Required
--                                       this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Launch_Visit_Dur_Notification (
    p_unit_schedule_id            IN              NUMBER,
    p_visit_ids                   IN              VARCHAR2,
    p_commit                      IN              VARCHAR2  := FND_API.G_FALSE,
    x_item_key                    OUT     NOCOPY  VARCHAR2,
    x_return_status               OUT     NOCOPY  VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Launch_Visit_Dur_Notification';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;

l_msg_count             NUMBER;
l_msg_data              VARCHAR2(4000);
l_active_flag           VARCHAR2(1);
l_process_name          VARCHAR2(30);
l_item_type             VARCHAR2(8);
l_subject               FND_NEW_MESSAGES.message_text%TYPE;
--

BEGIN
    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       'Unit Schedule Id > '||p_unit_schedule_id||
                       '  Visit ID > '||p_visit_ids||
                       ', p_commit > '||p_commit);
    END IF;

    -- check for the Visit Id
    IF (p_visit_ids IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_VWP_INVALID_VST'); -- Visit id is invalid.
        FND_MESSAGE.Set_Token('VISIT_ID', p_visit_ids);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- check for the Flight Schedule
    IF (p_unit_schedule_id IS NULL) THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.Set_Name(G_APP_NAME, 'AHL_UA_US_NOT_FOUND'); -- Flight Schedule (RECORD) does not exist.
        FND_MESSAGE.Set_Token('RECORD', p_unit_schedule_id);
        FND_MSG_PUB.ADD;
        RETURN;
    END IF;

    -- get the details of the Workflow process mapped to the object G_WF_VDUR_OBJ
    AHL_UTILITY_PVT.Get_WF_Process_Name(
        p_object        => G_WF_VDUR_OBJ,
        x_active        => l_active_flag,
        x_process_name  => l_process_name ,
        x_item_type     => l_item_type,
        x_msg_count     => l_msg_count,
        x_msg_data      => l_msg_data,
        x_return_status => x_return_status);

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the returned values from AHL_UTILITY_PVT.Get_WF_Process_Name : '||
                       '  l_active_flag > '||l_active_flag||
                       ', l_process_name > '||l_process_name||
                       ', l_item_type > '||l_item_type||
                       ', x_return_status > '||x_return_status);
    END IF;

    -- if returned with error, don't proceed any further
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RETURN;
    END IF;

    -- if the mapping is active, call the notification API
    If (l_active_flag = 'Y') THEN
        -- get the subject text
        l_subject := FND_MESSAGE.GET_STRING(G_APP_NAME, G_VISIT_DURA_SBJ);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'before calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification with arguments: '||
                           '  p_object > '||G_WF_VDUR_OBJ||
                           ', p_process_name > '||l_process_name||
                           ', p_item_type > '||l_item_type||
                           ', p_subject > '||l_subject||
                           ', p_oa_function > '||G_VISIT_DURA_FN||
                           ', p_param1_name > '||G_VISIT_ID_FN_PARAM1||
                           ', p_param1_value > '||p_visit_ids||
                           ', p_param2_name > '||G_UNIT_SCH_ID_FN_PARAM2||
                           ', p_param2_value > '||p_unit_schedule_id);
        END IF;

        -- call AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification
        AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification(
            p_object        => G_WF_VDUR_OBJ,
            p_process_name  => l_process_name,
            p_item_type     => l_item_type,
            p_subject       => l_subject,
            p_oa_function   => G_VISIT_DURA_FN,
            p_param1_name   => G_VISIT_ID_FN_PARAM1,
            p_param1_value  => p_visit_ids,
            p_param2_name   => G_UNIT_SCH_ID_FN_PARAM2,
            p_param2_value  => TO_CHAR(p_unit_schedule_id),
            p_param3_name   => G_PAGE_FUNC_PARAM3,
            p_param3_value  => G_VISIT_DURA_FN,
            x_item_key      => x_item_key,
            x_return_status => x_return_status);

        IF (l_log_statement >= l_log_current_level) THEN
            FND_LOG.string(l_log_statement, l_full_name,
                           'after calling AHL_WF_NOTIFICATION_PVT.Launch_OA_Notification, '||
                           '  x_item_key > '||x_item_key||
                           ', x_return_status > '||x_return_status);
        END IF;

        -- if returned with error, don't proceed any further
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RETURN;
        END IF;
    END IF;

    -- Standard check of p_commit
    IF FND_API.TO_BOOLEAN(p_commit) THEN
        COMMIT WORK;
    END IF;

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

END Launch_Visit_Dur_Notification;
------------------------------------------------------------------------------------

-- PRAKKUM :: Bug 13844759 :: 26/07/2012 :: START
------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Load_Can_Cancel_Visit
--  Type              : Public
--  Function          : Procedure to get whether visit can be cancelled or not
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Dur_Notification Parameters:
--       p_visit_id               IN    Visit Id                                Optional
--       p_visit_id2              IN    Visit Id                                Optional
--       l_can_cancel_visit       OUT   Flag denotes whether Visit with p_visit_id can be cancelled
--       l_can_cancel_visit2      OUT   Flag denotes whether Visit with p_visit_id2 can be cancelled
--       x_return_status          OUT   Return status. Item key to be used only if     Required
--                                      this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Load_Can_Cancel_Visit (
    p_visit_id               IN                     NUMBER,
    p_visit_id2              IN                     NUMBER,
    x_can_cancel_visit       OUT NOCOPY             VARCHAR2,
    x_can_cancel_visit2      OUT NOCOPY             VARCHAR2,
    x_return_status          OUT NOCOPY             VARCHAR2,
    x_msg_count              OUT NOCOPY             NUMBER,
    x_msg_data               OUT NOCOPY             VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Load_Can_Cancel_Visit';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;

--Cursor to find if the visit is in planning status and not firmed and not locked
Cursor can_cancel_visit(c_visit_id IN NUMBER)
IS
SELECT 'X'
FROM AHL_VISITS_B
WHERE VISIT_ID = c_visit_id
 AND STATUS_CODE = 'PLANNING'
 AND NVL(FIRMED_FLAG,'N') <> 'Y'
 AND NVL(LOCKED_FLAG,'N') <> 'Y';

BEGIN
    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- Standard start of API savepoint
    SAVEPOINT Load_Can_Cancel_Visit;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       'p_visit_id --@> '||p_visit_id||
                       'p_visit_id2 --@> '||p_visit_id2);
    END IF;

    x_can_cancel_visit := null;
    x_can_cancel_visit2 := null;
    IF p_visit_id is not null THEN
      OPEN can_cancel_visit(p_visit_id);
      FETCH can_cancel_visit INTO x_can_cancel_visit;
      CLOSE can_cancel_visit;
    ELSE
      x_can_cancel_visit := 'X';
    END IF;
    IF p_visit_id2 is not null THEN
      OPEN can_cancel_visit(p_visit_id2);
      FETCH can_cancel_visit INTO x_can_cancel_visit2;
      CLOSE can_cancel_visit;
    ELSE
      x_can_cancel_visit2 := 'X';
    END IF;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'p_visit_id ** x_can_cancel_visit: '||p_visit_id||' ** '||x_can_cancel_visit);
        FND_LOG.string(l_log_statement, l_full_name, 'p_visit_id2 ** x_can_cancel_visit2: '||p_visit_id2||' ** '||x_can_cancel_visit2);
    END IF;

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

EXCEPTION

 WHEN FND_API.G_EXC_ERROR THEN

   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Load_Can_Cancel_Visit;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Load_Can_Cancel_Visit;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Load_Can_Cancel_Visit;

    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Load_Can_Cancel_Visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;

    FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);

END Load_Can_Cancel_Visit;
-- PRAKKUM :: Bug 13844759 :: 26/07/2012 :: END

------------------------------------------------------------------------------------
-- Start of Comments
--  Procedure name    : Disconnect_Flight_Visit
--  Type              : Public
--  Function          : Procedure to disconnect visit and to launch disconnect notification
--  Pre-reqs          :
--  Parameters        :
--
--  Launch_Visit_Dur_Notification Parameters:
--       p_visit_id               IN    Visit Id                                Required
--       p_unit_schedule_id       IN    Unit Schedule Id                        Required
--       x_return_status          OUT   Return status. Item key to be used only if     Required
--                                      this status is FND_API.G_RET_STS_SUCCESS.
--
--  End of Comments

PROCEDURE Disconnect_Flight_Visit (
    p_visit_id               IN                     NUMBER,
    p_unit_schedule_id       IN                     NUMBER,
    x_return_status          OUT NOCOPY             VARCHAR2,
    x_msg_count              OUT NOCOPY             NUMBER,
    x_msg_data               OUT NOCOPY             VARCHAR2
) IS

--
l_api_name     CONSTANT VARCHAR2(30)  := 'Disconnect_Flight_Visit';
l_full_name    CONSTANT VARCHAR2(100) := 'ahl.plsql.'||G_PKG_NAME||'.'||l_api_name;
x_item_key              VARCHAR2(100);
l_return_status               VARCHAR2(1);

--Cursor to get visit details
CURSOR get_visit_details(c_visit_id IN NUMBER) IS
SELECT visit_number, auto_visit_type_flag auto_flag
FROM ahl_visits_b
WHERE visit_id = c_visit_id;
vst_details_rec get_visit_details%ROWTYPE;


BEGIN

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.begin', 'At the start of the API');
    END IF;

    -- Standard start of API savepoint
    SAVEPOINT Disconnect_Flight_Visit;

    -- initialize procedure return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF (l_log_statement >= l_log_current_level) THEN
        FND_LOG.string(l_log_statement, l_full_name, 'the arguments: '||
                       'p_visit_id --@> '||p_visit_id||
                       'p_unit_schedule_id --@> '||p_unit_schedule_id);
    END IF;

    UPDATE ahl_visits_b
    SET UNIT_SCHEDULE_ID = null,
    OBJECT_VERSION_NUMBER = object_version_number + 1,
    LAST_UPDATE_DATE      = SYSDATE,
    LAST_UPDATED_BY       = Fnd_Global.USER_ID,
    LAST_UPDATE_LOGIN     = Fnd_Global.LOGIN_ID
    WHERE visit_id = p_visit_id;

    -- Send a visit disconnect notification
    AHL_AVF_OPER_VSTS_PVT.Launch_Visit_Disc_Notification (
             p_unit_schedule_id => p_unit_schedule_id,
             p_visit_ids        => p_visit_id,
             p_commit           => Fnd_Api.g_false ,
             x_item_key         => x_item_key,
             x_return_status    => l_return_status );
    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      x_msg_count := FND_MSG_PUB.count_msg;
      IF (l_log_statement >= l_log_current_level) THEN
         fnd_log.string(l_log_statement,
                        l_full_name,
                        'Errors from Launch_Visit_Disc_Notification ' );
      END IF;
      IF l_return_status = FND_API.G_RET_STS_ERROR THEN
         RAISE FND_API.G_EXC_ERROR;
      ELSE
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
    END IF;  -- Return Status is not Success

    -- For Logging :: START
    OPEN get_visit_details(p_visit_id);
    FETCH get_visit_details INTO vst_details_rec;
    CLOSE get_visit_details;

    IF vst_details_rec.visit_number IS NOT NULL THEN
      IF vst_details_rec.auto_flag IS NOT NULL THEN
         IF vst_details_rec.auto_flag = 'T' THEN
            fnd_file.put_line(fnd_file.log, 'Disconnected downtime visit number -> '||vst_details_rec.visit_number);
         ELSIF vst_details_rec.auto_flag = 'D' THEN
            fnd_file.put_line(fnd_file.log, 'Disconnected departure visit number -> '||vst_details_rec.visit_number);
         ELSIF vst_details_rec.auto_flag = 'A' THEN
            fnd_file.put_line(fnd_file.log, 'Disconnected arrival visit number -> '||vst_details_rec.visit_number);
         END IF;
      ELSE
         fnd_file.put_line(fnd_file.log, 'Disconnected visit number -> '||vst_details_rec.visit_number);
      END IF;
    END IF;
    -- For Logging :: END

    IF (l_log_procedure >= l_log_current_level) THEN
        FND_LOG.string(l_log_procedure, l_full_name || '.end', 'At the end of the API');
    END IF;

EXCEPTION

 WHEN FND_API.G_EXC_ERROR THEN

   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Disconnect_Flight_Visit;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Disconnect_Flight_Visit;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Disconnect_Flight_Visit;

    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Disconnect_Flight_Visit',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;

    FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);

END Disconnect_Flight_Visit;

END  AHL_AVF_OPER_VSTS_PVT;

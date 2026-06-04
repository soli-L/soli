
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_AVF_PRIM_VSTS_PVT" AUTHID CURRENT_USER AS
/* $Header: AHLVPRVS.pls 120.0.12020000.3 2013/03/19 09:29:46 satrajen noship $ */


--------------------------------------------------------------------
-- START: Defining local functions and procedures            --
--------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE
--    Add_Planned_MRs
-- TYPE
--    Public
-- PURPOSE
--    To Add Planned maintainence requirements to the visits.
-- PARAMETERS
--    p_visit_id      Input    Number     Optional(Any One Required)
--    p_snapshot_id   Input    Number     Optional(Any One Required)
-------------------------------------------------------------------------------------------------------------------------------

PROCEDURE Add_Planned_MRs
   (p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    p_visit_id              IN             NUMBER    := NULL,
    p_snapshot_id           IN             NUMBER    := NULL,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2);


-----------------------------------------------------------------------------------------------
-- PROCEDURE
--    Cancel_Visits
-- TYPE
--    Public
-- PURPOSE
--    To Cancel the existing visits according to the Master configuration provided and the date ranges provided by the user.
-- PARAMETERS
--    p_snapshot_id  Input    Number     Required
-----------------------------------------------------------------------------------------------

PROCEDURE Cancel_Visits
   (p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    p_snapshot_id           IN             NUMBER,
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2);


-------------------------------------------------------------------
--  Procedure name    : Create_Primary_Visits
--  Type              : Private
--  Function          : Procedure to create primary visits based on auto visit hierarchy and on primary UEs
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
--
--  Create_Primary_Visits Parameters:
--       p_snapshot_id        IN  NUMBER        Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Create_Primary_Visits (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    p_snapshot_id           IN             NUMBER,
    -- Front Porting to AHL122
    -- SATRAJEN :: Bug 16048246 :: Added for calling add_planned_mrs from create_primary_visits Procedure :: 28-12-2012
    p_add_plan_flag         IN             VARCHAR2  := 'N',
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2);



--------------------------------------------------------------------
-- PROCEDURE
--    Process_Primary_visits
--
-- PURPOSE
--    Made as an executable for the P2P CP
--  Process_Primary_visits Parameters :
--      p_snapshot_id       IN    NUMBER
--      errbuf              OUT   VARCHAR2   Required
--         Defines in pl/sql to store procedure to get error messages into log file
--      retcode             OUT   NUMBER     Required
--         To get the status of the concurrent program

--------------------------------------------------------------------
PROCEDURE Process_Primary_visits(
    errbuf            OUT NOCOPY VARCHAR2,
    retcode           OUT NOCOPY NUMBER,
    p_api_version     IN  NUMBER,
    p_snapshot_id     IN  NUMBER
);


---------------------------------------------------------------------------------------------------------------------------

END AHL_AVF_PRIM_VSTS_PVT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_AVF_PRIM_VSTS_PVT" AS
/* $Header: AHLVPRVB.pls 120.0.12020000.7 2016/12/13 11:38:32 sosahni noship $ */


G_PKG_NAME     CONSTANT VARCHAR2(30) := 'AHL_AVF_PRIM_VSTS_PVT';

------------------------------------
-- Common constants and variables --
------------------------------------
l_log_current_level     NUMBER      := fnd_log.g_current_runtime_level;
l_log_statement         NUMBER      := fnd_log.level_statement;
l_log_procedure         NUMBER      := fnd_log.level_procedure;

---------------------------------------------------------------------
--   Define Record Types for record structures needed by the APIs  --
---------------------------------------------------------------------
-- NO RECORD TYPES *************

--------------------------------------------------------------------
-- Define Table Type for Records Structures                       --
--------------------------------------------------------------------
-- NO TABLE TYPES **************

--------------------------------------------------------------------
-- START: Defining local functions and procedures BODY            --
--------------------------------------------------------------------

--  Validate MR operating organization and returns maintenance organization defined for it
-------------------------------------------------------------------
--  Procedure name   : Validate_MR_Operating_Org
--  Type             : Private
--  Function         : Validate MR operating organization and returns maintenance organization defined for it
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version             IN       NUMBER     Required
--      p_init_msg_list           IN       VARCHAR2   Optional
--      p_commit                  IN       VARCHAR2   Optional
--      p_validation_level        IN       NUMBER     Optional
--      p_mr_header_id            IN       NUMBER     Required
--      p_operating_org_id        OUT      NUMBER
--      x_maintenance_dept_id     OUT      NUMBER
--      x_return_status           OUT      VARCHAR2
--      x_msg_count               OUT      NUMBER
--      x_msg_data                OUT      VARCHAR2
--
--  Version :
--      Initial Version   12.1.3
-------------------------------------------------------------------
PROCEDURE Validate_MR_Operating_Org (
   p_api_version         IN  NUMBER,
   p_init_msg_list       IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit              IN  VARCHAR2  := Fnd_Api.g_false,
   p_validation_level    IN  NUMBER    := Fnd_Api.g_valid_level_full,
   p_mr_header_id        IN  NUMBER,
   p_operating_org_id    IN  NUMBER,
   x_maintenance_org_id  OUT NOCOPY NUMBER,
   x_maintenance_dept_id OUT NOCOPY NUMBER,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2
);

-------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE
--    Add_Planned_MRs
-- TYPE
--    Public
-- PURPOSE
--    To Add Planned maintainence requirements to the visits.
-- PARAMETERS
--    p_visit_id      Input    Number     Optional(Any One Required)
--    p_snapshot_id   Input    Number     Optional(Any One Required)
-------------------------------------------------------------------------------------------------------------------------------

PROCEDURE Add_Planned_MRs
(
p_api_version           IN             NUMBER    := 1.0,
p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
p_visit_id              IN             NUMBER    := NULL,
p_snapshot_id           IN             NUMBER    := NULL,
x_return_status         OUT  NOCOPY    VARCHAR2,
x_msg_count             OUT  NOCOPY    NUMBER,
x_msg_data              OUT  NOCOPY    VARCHAR2) IS

-- Local variables and constants.

    L_API_NAME     CONSTANT  VARCHAR2(30)  := 'Add_Planned_MRs';
    L_DEBUG_KEY    CONSTANT  VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
    L_MASTER_CODE  CONSTANT  VARCHAR2(20)  := 'MASTER_CONFIGURATION';
    L_API_VERSION  CONSTANT  NUMBER        := 1.0;
    l_start_date             DATE;
    l_end_date               DATE;
    l_mc_id                  NUMBER;
    l_ue_id                  NUMBER;
    l_earl_due_date          DATE;
    l_due_date               DATE;
    l_lat_due_date           DATE;
    l_instance_id            NUMBER;
    l_category_ue            NUMBER;
    l_visit_id               NUMBER;
    l_category_visit         VARCHAR2(2);
    l_parent_check           VARCHAR2(1);
    l_task_rec               AHL_VWP_RULES_PVT.Task_Tbl_Type;
    l_valid_visit_flag       VARCHAR2(1);
    l_valid_snapshot_flag    VARCHAR2(1);
    l_return_status          VARCHAR2(1);
    l_msg_count              NUMBER;
    l_msg_data               VARCHAR2(2000);
    l_count_ues              NUMBER;


-- Starting of Cursors definition

-- Check The Validity of the visit_id passed.
CURSOR check_validity_visit (c_visit_id IN NUMBER) is
SELECT 'X'
FROM ahl_visits_b
WHERE visit_id = c_visit_id
AND nvl(locked_flag,'N') = 'N'
AND nvl(firmed_flag,'N') = 'N'
AND start_date_time IS NOT NULL
AND close_date_time IS NOT NULL;

-- Check The Validity of the snapshot_id passed.
CURSOR check_validity_snapshot(c_snapshot_id in NUMBER) IS
SELECT 'X'
FROM ahl_autovst_snpsht_hdr
WHERE snapshot_id = c_snapshot_id;

-- Getting Visit Details for a particular Visit.
CURSOR get_visit_details(c_visit_id IN NUMBER)IS
SELECT item_instance_id, start_date_time, close_date_time,nvl(space_category_code,0)
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

-- Check for the Parent MR

CURSOR check_parent_mr(c_ue_id       in NUMBER,
                       c_instance_id in NUMBER,
                       c_visit_id    in NUMBER)IS
SELECT 'X'
FROM ahl_ue_relationships uer, ahl_visit_tasks_b vtk, ahl_unit_effectivities_b uet
WHERE uer.ue_id = c_ue_id
AND vtk.instance_id =  c_instance_id
AND vtk.visit_id = c_visit_id
AND uer.ue_id = uet.unit_effectivity_id
AND uet.mr_header_id = vtk.mr_id;

-- SOSAHNI :: 13/12/2016 :: Bug 25243398 :: Auto Visit Creation
-- Getting the UE_IDs which has the same Instance Id as the visit.
CURSOR get_ue_details_visit(c_instance_id   in NUMBER,
                            c_start_date    in DATE,
                            c_end_date      in DATE) IS
SELECT une.unit_effectivity_id, nvl(mrh.service_category_rank,0)
FROM ahl_unit_effectivities_b une, ahl_mr_headers_b mrh
WHERE une.csi_item_instance_id = c_instance_id
AND (une.status_code ='INIT-DUE' OR une.status_code IS NULL)
AND une.due_date is NOT NULL
AND ((une.due_date between c_start_date AND c_end_date)  OR (une.earliest_due_date between c_start_date AND c_end_date) OR (une.latest_due_date between c_start_date AND c_end_date)
    OR (c_start_date >= une.earliest_due_date and c_end_date <= une.due_date) OR (c_start_date >= une.due_date and c_end_date <= une.latest_due_date))
AND NOT EXISTS (SELECT 'X' FROM ahl_ue_relationships uer WHERE uer.related_ue_id = une.unit_effectivity_id)
AND une.mr_header_id = mrh.mr_header_id
AND NOT exists (SELECT 'X' FROM ahl_visit_tasks_b task, ahl_visits_b visit
                WHERE task.visit_id = visit.visit_id AND task.unit_effectivity_id = une.unit_effectivity_id
                AND task.status_code NOT IN ('CANCELLED', 'DELETED'));

-- Get the start and end dates of the Snapshot
CURSOR get_dates(c_snapshot_id in NUMBER) IS
SELECT from_date,to_date
FROM ahl_autovst_snpsht_hdr
WHERE snapshot_id = c_snapshot_id;

-- Get the MC_IDs for the given Snapshot
CURSOR get_mc_ids(c_snapshot_id in NUMBER) IS
SELECT mc_id
FROM ahl_autovisit_hierarchy
WHERE autovisit_flag = 'Y'
AND snapshot_id = c_snapshot_id
AND hierarchy_type_code = L_MASTER_CODE;

-- SOSAHNI :: 13/12/2016 :: Bug 25243398 :: Auto Visit Creation
-- Get the UE_IDs for a particular MC_ID.
CURSOR get_ue_details(c_mc_id      in NUMBER,
                      c_start_date in DATE,
                      c_end_date   in DATE) IS
SELECT une.unit_effectivity_id, une.earliest_due_date, une.due_date, une.latest_due_date, une.csi_item_instance_id, nvl(mrh.service_category_rank,0)
FROM ahl_unit_effectivities_b une, ahl_mr_headers_b mrh, ahl_unit_config_headers uch,ahl_mc_headers_b mc
WHERE mc.mc_id = c_mc_id
AND uch.master_config_id =  mc.mc_header_id --tchimira :: 21 May 2012 :: compare correct columns
AND une.csi_item_instance_id = uch.csi_item_instance_id
AND (une.status_code ='INIT-DUE' OR une.status_code IS NULL)
AND une.due_date IS NOT NULL
AND ((une.due_date between c_start_date AND c_end_date)  OR (une.earliest_due_date between c_start_date AND c_end_date) OR (une.latest_due_date between c_start_date AND c_end_date)
    OR (c_start_date >= une.earliest_due_date and c_end_date <= une.due_date) OR (c_start_date >= une.due_date and c_end_date <= une.latest_due_date))
AND NOT EXISTS (SELECT 'X' FROM ahl_ue_relationships uer WHERE uer.related_ue_id = une.unit_effectivity_id)
AND une.mr_header_id = mrh.mr_header_id
AND NOT exists (SELECT 'X' FROM ahl_visit_tasks_b task, ahl_visits_b visit
                WHERE task.visit_id = visit.visit_id AND task.unit_effectivity_id = une.unit_effectivity_id
                AND task.status_code NOT IN ('CANCELLED', 'DELETED'));

-- SOSAHNI :: 13/12/2016 :: Bug 25243398 :: Auto Visit Creation
-- Get the correct VISIT_ID for the given UE_ID.
CURSOR associating_visit(c_instance_id  in  NUMBER,
                         c_category     in  NUMBER,
                         c_earl_due_date in DATE,
                         c_due_date     in  DATE,
                         c_lat_due_date in  DATE) IS
SELECT visit_id
FROM ahl_visits_b
WHERE status_code IN ('PLANNING','RELEASED','PARTIALLY RELEASED')
AND item_instance_id = c_instance_id
AND nvl(locked_flag,'N') = 'N'
AND nvl(firmed_flag,'N') = 'N'
AND ((c_earl_due_date between start_date_time AND close_date_time) OR (c_due_date between start_date_time AND close_date_time) OR (c_lat_due_date between start_date_time AND close_date_time)
    OR (start_date_time >= c_earl_due_date and close_date_time <= c_due_date) OR (start_date_time >= c_due_date and close_date_time <= c_lat_due_date))
AND TO_NUMBER(nvl(space_category_code,0)) <= c_category
ORDER BY start_date_time, visit_id;

-- End of cursors definition

BEGIN

-- Save Point declaration.
    SAVEPOINT Save_Add_MRs;

 --------------------- Initialize -----------------------
    IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
        fnd_log.string(fnd_log.level_procedure,L_DEBUG_KEY||'.begin','At the start of PLSQL procedure');
    END IF;

 -- Printing The input Parameters
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' p_api_version        => ' || p_api_version ||
                                                    ' , p_init_msg_list    => ' || p_init_msg_list ||
                                                    ' , p_commit           => ' || p_commit ||
                                                    ' , p_validation_level => ' || p_validation_level ||
                                                    ' , p_visit_id         => ' || p_visit_id ||
                                                    ' , p_snapshot_id      => ' || p_snapshot_id);
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

----------------------------------------------------------

-- Checking which parameter is sent.
    -- SATRAJEN :: Bug 16048246 :: 04-01-2013 :: Chenged in order to pass the condition when called from create_primary_visits.
    -- IF((p_visit_id IS NOT NULL OR p_visit_id <> FND_API.G_MISS_NUM) AND (p_snapshot_id IS NULL or p_snapshot_id = FND_API.G_MISS_NUM)) THEN
    IF(p_visit_id IS NOT NULL OR p_visit_id <> FND_API.G_MISS_NUM) THEN
-- Visit_id is passed

        OPEN check_validity_visit(p_visit_id);
        FETCH check_validity_visit INTO l_valid_visit_flag;
        CLOSE check_validity_visit;

        IF l_valid_visit_flag = 'X' THEN

            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Visit Id = ' || p_visit_id);
            END IF;
            l_count_ues:= 0;
-- Getting the Visit details(Instance id (csi_id), Start date, End date and Visit category for the particular visit_id
            OPEN get_visit_details(p_visit_id);
            FETCH get_visit_details INTO l_instance_id, l_start_date,l_end_date, l_category_visit;
            CLOSE get_visit_details;

-- Getting all the UE_IDs which has the same Instance Id and the due date of the UE_ID falls between start date and end date of the visit.
-- A number of UE_IDs will be the outcome. Each UE_ID is associated to this Visit_id.

-- Checking whether the Visit is planned or not.
            OPEN get_ue_details_visit(l_instance_id,l_start_date,l_end_date);
            LOOP
                FETCH get_ue_details_visit INTO l_ue_id, l_category_ue;
                exit when get_ue_details_visit%NOTFOUND;

-- Check whether the MR is a parent MR and is already associated or not. If already associated to the same visit id then it is not added.
                l_parent_check := NULL;
                OPEN check_parent_mr(l_ue_id, l_instance_id, p_visit_id);
                FETCH check_parent_mr INTO l_parent_check;
                CLOSE check_parent_mr;

-- If the MR is a parent MR and is associated with the some visit, Visit_id is returned.
                IF l_parent_check IS NULL THEN

                    IF (l_log_statement >= l_log_current_level) THEN
                            fnd_log.string(l_log_statement,L_DEBUG_KEY,
                                          '(UE_ID,CATEGORY_UE,CATEGORY_VISIT) = ' || l_ue_id || ', ' || l_category_ue || ', ' || l_category_visit );
                    END IF;

                    IF TO_NUMBER(l_category_visit) <= l_category_ue THEN
                        l_task_rec(1).visit_id            := p_visit_id ;
                        l_task_rec(1).unit_effectivity_id := l_ue_id;
                        l_task_rec(1).task_type_code      := 'PLANNED';
-- assign l_ue_id to p_visit_id;
-- Calling the API which associates.

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_api_version--@>'||L_API_VERSION);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_init_msg_list--@>'||Fnd_Api.g_false);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_commit--@>'||Fnd_Api.g_false);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_validation_level--@>'||Fnd_Api.g_valid_level_full);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_module_type--@>'||'NULL');
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: l_ue_id--@>'||'l_ue_id');
                        END IF;

                        l_return_status  := NULL;
                        l_msg_count      := 0;
                        l_msg_data       := NULL;


                        AHL_VWP_TASKS_PVT.Create_PUP_Tasks(
                            p_api_version             => L_API_VERSION,
                            p_init_msg_list           => Fnd_Api.g_false,
                            p_commit                  => Fnd_Api.g_false,
                            p_validation_level        => Fnd_Api.g_valid_level_full,
                            p_module_type             => NULL,
                            p_x_task_tbl              => l_task_rec,
                            x_return_status           => l_return_status,
                            x_msg_count               => l_msg_count,
                            x_msg_data                => l_msg_data);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_return_status--@>'||l_return_status);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_msg_count--@>'||l_msg_count);
                            fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_msg_data--@>'||l_msg_data);
                        END IF;

                        IF nvl(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
                            IF (l_log_statement >= l_log_current_level) THEN
                                FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Error Occured while associating Unit effectivity '||l_ue_id||' to VISIT_ID : ' || l_visit_id || ' with x-return-status:' || l_return_status);
                            END IF;
                        ELSE
                            IF (l_log_statement >= l_log_current_level) THEN
                                FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Successfully associated Unit effectivity '||l_ue_id||' to VISIT_ID : ' || p_visit_id);
                            END IF;
			    l_count_ues:=l_count_ues+1;
                        END IF;

                    ELSE
                        IF (l_log_statement >= l_log_current_level) THEN
                            fnd_log.string(l_log_statement,L_DEBUG_KEY, 'UE_ID : ' || l_ue_id ||' not assigned to ' || p_visit_id || ' as category is higher ');
                        END IF;
                    END IF;
                ELSE

                    IF (l_log_statement >= l_log_current_level) THEN
                        fnd_log.string(l_log_statement,L_DEBUG_KEY,
                                       'UE_ID(Parent MR) ' || l_ue_id || ' is already associated to Visit_id ' || p_visit_id);
                    END IF;

                END IF;
            END LOOP;
            CLOSE get_ue_details_visit;
	     -- SATRAJEN :: Bug 13707339 :: Added for Seperate return status according to the UEs associated.
            IF l_count_ues = 0 THEN
                x_return_status:='V';
            END IF;
            -- End of Bug 13707339
        ELSE
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Invalid Visit Id : ' || p_visit_id);
            END IF;
            Fnd_Message.SET_NAME('AHL','AHL_VISIT_ID_INVALID');
            Fnd_Msg_Pub.ADD;
            RAISE Fnd_Api.G_EXC_ERROR;
        END IF;
    ELSIF((p_snapshot_id IS NOT NULL OR p_snapshot_id <> FND_API.G_MISS_NUM) AND (p_visit_id IS NULL or p_visit_id = FND_API.G_MISS_NUM)) THEN
-- Snapshot_id is passed

        OPEN check_validity_snapshot(p_snapshot_id);
        FETCH check_validity_snapshot INTO l_valid_snapshot_flag;
        CLOSE check_validity_snapshot;

        IF l_valid_snapshot_flag = 'X' THEN

            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Snapshot Id = ' || p_snapshot_id);
            END IF;

-- Getting the start and end date of the Snapshot
            OPEN get_dates(p_snapshot_id);
            FETCH get_dates INTO l_start_date, l_end_date;
            CLOSE get_dates;

-- Getting the MC_IDs of the snapshot. Number of MC_IDs are retrieved.
            OPEN get_mc_ids(p_snapshot_id);
            LOOP
                FETCH get_mc_ids INTO l_mc_id;
                exit when get_mc_ids%NOTFOUND;

                IF (l_log_statement >= l_log_current_level) THEN
                    fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Process for MC_ID : ' || l_mc_id);
                END IF;

-- Getting the UE_IDs for the particular MC_ID. Number of UE_IDs are retrieved.
                OPEN get_ue_details(l_mc_id, l_start_date, l_end_date);
                LOOP
                    FETCH get_ue_details INTO l_ue_id, l_earl_due_date, l_due_date, l_lat_due_date, l_instance_id, l_category_ue;
                    exit when get_ue_details%NOTFOUND;

                    IF (l_log_statement >= l_log_current_level) THEN
                        fnd_log.string(l_log_statement,L_DEBUG_KEY,
                                      '(UE_ID, INSTANCE_ID, CATEGORY_UE, DUE_DATE, LATEST_DUE_DATE) = ' || l_ue_id || ', ' || l_instance_id ||
                                              ', ' || l_category_ue || ', ' || l_due_date || ', '|| l_lat_due_date );
                    END IF;

-- Getting the correct Visit_id to associate the UE_ID.
                    l_visit_id := NULL;
                    OPEN associating_visit(l_instance_id, l_category_ue, l_earl_due_date, l_due_date, l_lat_due_date);
                    LOOP
                        FETCH associating_visit INTO l_visit_id;
                        IF associating_visit%NOTFOUND THEN
                            IF (l_log_statement >= l_log_current_level) THEN
                                fnd_log.string(l_log_statement,L_DEBUG_KEY, 'UE_ID : ' || l_ue_id || ' cannot be associated to any Visit_id' );
                            END IF;
                            EXIT;
                        END IF;
-- Check whether the MR is a parent MR and is already associated or not. If already associated to the same visit id then it is not added.
                        l_parent_check := NULL;
                        OPEN check_parent_mr(l_ue_id, l_instance_id, l_visit_id);
                        FETCH check_parent_mr INTO l_parent_check;
                        CLOSE check_parent_mr;

-- If the MR is a parent MR and is associated with the some visit, Visit_id is returned.
                        IF l_parent_check IS NULL THEN
                            l_task_rec(1).visit_id            := l_visit_id;
                            l_task_rec(1).unit_effectivity_id := l_ue_id;
                            l_task_rec(1).task_type_code      := 'PLANNED';
--assign l_ue_id to l_visit_id

                            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_api_version--@>'||L_API_VERSION);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_init_msg_list--@>'||Fnd_Api.g_false);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_commit--@>'||Fnd_Api.g_false);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_validation_level--@>'||Fnd_Api.g_valid_level_full);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: p_module_type--@>'||'NULL');
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Create_PUP_Tasks :: visit_id--@>'||'l_visit_id');
                            END IF;

                            l_return_status  := NULL;
                            l_msg_count      := 0;
                            l_msg_data       := NULL;


                            AHL_VWP_TASKS_PVT.Create_PUP_Tasks(
                            p_api_version             => L_API_VERSION,
                            p_init_msg_list           => Fnd_Api.g_false,
                            p_commit                  => Fnd_Api.g_false,
                            p_validation_level        => Fnd_Api.g_valid_level_full,
                            p_module_type             => NULL,
                            p_x_task_tbl              => l_task_rec,
                            x_return_status           => l_return_status,
                            x_msg_count               => l_msg_count,
                            x_msg_data                => l_msg_data);

                            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_return_status--@>'||l_return_status);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_msg_count--@>'||l_msg_count);
                                fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Create_PUP_Tasks :: x_msg_data--@>'||l_msg_data);
                            END IF;

                            IF nvl(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
                                IF (l_log_statement >= l_log_current_level) THEN
                                    FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Error Occured while associating Unit effectivity '||l_ue_id||' to VISIT_ID : ' || l_visit_id || ' with x-return-status:' || l_return_status);
                                END IF;
                            ELSE
                                IF (l_log_statement >= l_log_current_level) THEN
                                    FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Successfully associated Unit effectivity '||l_ue_id||' to VISIT_ID : ' || l_visit_id);
                                END IF;
                            END IF;
                            EXIT;

                        ELSE

                            IF (l_log_statement >= l_log_current_level) THEN
                                fnd_log.string(l_log_statement,L_DEBUG_KEY,
                                              'UE_ID(Parent MR) ' || l_ue_id || ' is already associated to Visit_id ' || l_visit_id);
                            END IF;
                        END IF;

                    END LOOP;
                    CLOSE associating_visit;

                END LOOP; -- UE_ID loop ends
                CLOSE get_ue_details;
            END LOOP; -- MC_ID loop ends
            CLOSE get_mc_ids;
        ELSE
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Invalid Snapshot Id : ' || p_snapshot_id);
            END IF;
            Fnd_Message.SET_NAME('AHL','AHL_AVF_INVALID_SNAPSHOT');
            Fnd_Msg_Pub.ADD;
            RAISE Fnd_Api.G_EXC_ERROR;
        END IF;
    ELSE
-- The input flag is not valid. Need to raise exception
        IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Invalid Paramters ');
        END IF;
        Fnd_Message.SET_NAME('AHL','AHL_PAGE_PARAMETERS_INVALID');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
    END IF; -- Valid Input parameters check ends

-------------------- finish --------------------------
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Add_Planned_MRs :: p_encoded--@>'||Fnd_Api.g_false);
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Add_Planned_MRs :: p_count--@>'||x_msg_count);
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Add_Planned_MRs :: p_data--@>'||x_msg_data);
    END IF;
      Fnd_Msg_Pub.count_and_get (
      p_encoded => Fnd_Api.g_false,
      p_count   => x_msg_count,
      p_data    => x_msg_data
      );


    IF (l_log_procedure >= l_log_current_level) THEN
        fnd_log.string(l_log_procedure,
                       L_DEBUG_KEY ||'.end',
                       'At the end of PL SQL Procedure.');
    END IF;

-- Proceed to commit if status is 'S' or if there were only validation errors
--Standard check for commit
    IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
        COMMIT;
    END IF;
----- EXCEPTIONS--------------------------------------
    EXCEPTION
    WHEN Fnd_Api.G_EXC_ERROR THEN
        x_return_status := Fnd_Api.G_RET_STS_ERROR;
        ROLLBACK TO Save_Add_MRs;
        Fnd_Msg_Pub.count_and_get( p_count   => x_msg_count,
                                   p_data    => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

    WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
        x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
        ROLLBACK TO Save_Add_MRs;
        Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                                   p_data  => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

    WHEN OTHERS THEN
        x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
        ROLLBACK TO Save_Add_MRs;
        Fnd_Msg_Pub.add_exc_msg( p_pkg_name       => G_PKG_NAME,
                                 p_procedure_name => 'Add_Planned_MRs',
                                 p_error_text     => SQLERRM);
        Fnd_Msg_Pub.count_and_get( p_count   => x_msg_count,
                                   p_data    => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

END Add_Planned_MRs; -- End of begin/procedure.

-----------------------------------------------------------------------------------------------
-- PROCEDURE
--    Cancel_Visits
-- TYPE
--    Public
-- PURPOSE
--    To Cancel the existing visits according to the Master configuration provided and the date ranges provided by the user.
-- PARAMETERS
--    p_snapshot_id  Input    Number     Required
-----------------------------------------------------------------------------------------------

PROCEDURE Cancel_Visits
(
p_api_version           IN             NUMBER    := 1.0,
p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
p_snapshot_id           IN             NUMBER,
x_return_status         OUT  NOCOPY    VARCHAR2,
x_msg_count             OUT  NOCOPY    NUMBER,
x_msg_data              OUT  NOCOPY    VARCHAR2) IS

-- Local variables and constants.
    L_API_NAME    CONSTANT    VARCHAR2(30)  := 'Cancel_Visits';
    L_MASTER_CODE CONSTANT    VARCHAR2(20)   := 'MASTER_CONFIGURATION';
    L_DEBUG_KEY   CONSTANT    VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
    L_STATUS_CODE CONSTANT    VARCHAR2(9)   := 'PLANNING';
    L_API_VERSION CONSTANT    NUMBER        := 1.0;
    l_valid_flag              VARCHAR2(1)   := 'N';
    l_visit_id                NUMBER;
    l_obj_ver_no              NUMBER;
    l_return_status           VARCHAR2(1);
    l_msg_count               NUMBER;
    l_msg_data                VARCHAR2(2000);

-- Starting of Cursors definition

-- Check the snapshot_id is valid or not.
CURSOR check_validity(c_snapshot_id IN NUMBER) IS
SELECT 'X'
FROM ahl_autovst_snpsht_hdr
WHERE snapshot_id = c_snapshot_id;

-- Get the Visits corresponding to the Start and End dates and Master configuration ids provided.
CURSOR get_visit_ids(c_snapshot_id IN NUMBER) IS
SELECT visit.visit_id, visit.object_version_number
FROM ahl_visits_b visit, ahl_unit_config_headers uch, ahl_autovisit_hierarchy avh, ahl_autovst_snpsht_hdr snap,ahl_mc_headers_b mc
WHERE visit.start_date_time IS NOT null AND visit.close_date_time IS NOT NULL
AND start_date_time >= snap.from_date
AND close_date_time <= snap.to_date
AND visit.status_code = L_STATUS_CODE
AND visit.item_instance_id IS NOT NULL
AND visit.item_instance_id = uch.csi_item_instance_id
AND nvl(visit.locked_flag,'N') = 'N'
AND nvl(visit.firmed_flag,'N') = 'N'
AND uch.master_config_id = mc.mc_header_id --tchimira :: 21 May 2012 :: bug 14082494
AND mc.mc_id = avh.mc_id
AND avh.snapshot_id = snap.snapshot_id
AND avh.autovisit_flag = 'Y'
AND avh.hierarchy_type_code = L_MASTER_CODE
AND snap.snapshot_id = c_snapshot_id;

-- End of cursors definition

BEGIN

-- Save Point Declaration
    SAVEPOINT Save_Cancel_visits;

 --------------------- Initialize -----------------------
    IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
        fnd_log.string(fnd_log.level_procedure,L_DEBUG_KEY||'.begin','At the start of PLSQL procedure');
    END IF;

 -- Printing The input Parameters
    IF (l_log_statement >= l_log_current_level) THEN
        fnd_log.string(l_log_statement,L_DEBUG_KEY, ' p_api_version        => ' || p_api_version ||
                                                    ' , p_init_msg_list    => ' || p_init_msg_list ||
                                                    ' , p_commit           => ' || p_commit ||
                                                    ' , p_validation_level => ' || p_validation_level ||
                                                    ' , p_snapshot_id      => ' || p_snapshot_id);
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

----------------------------------------------------------
    IF (l_log_procedure >= l_log_current_level) THEN
        fnd_log.string(l_log_procedure,
                       L_DEBUG_KEY ||'.begin',
                       'At the start of PL SQL procedure.');
    END IF;

-- Checking whether the parameter is valid or not.
    IF(p_snapshot_id IS NOT NULL OR p_snapshot_id <> FND_API.G_MISS_NUM) THEN

-- Check the Validity of the snapshot Id in the table.
        OPEN check_validity(p_snapshot_id);
        FETCH check_validity INTO l_valid_flag;
        CLOSE check_validity;

        IF (l_valid_flag = 'X') THEN
-- Getting the VISIT_IDs of the snapshot. Number of VISIT_IDs might be retrieved.
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Snapshot Id = ' || p_snapshot_id);
            END IF;

            OPEN get_visit_ids(p_snapshot_id);
            LOOP
                FETCH get_visit_ids into l_visit_id,l_obj_ver_no;
                EXIT WHEN get_visit_ids%NOTFOUND;

                IF (l_log_statement >= l_log_current_level) THEN
                    fnd_log.string(l_log_statement,L_DEBUG_KEY, ' VISIT_ID : ' || l_visit_id || ' Object Version No: ' || l_obj_ver_no);
                END IF;

-- Calling the procedure to cancel the visit.

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Delete_visit :: p_api_version--@>'||L_API_VERSION);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Delete_visit :: p_init_msg_list--@>'||Fnd_Api.g_false);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Delete_visit :: p_commit--@>'||Fnd_Api.g_false);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Delete_visit :: p_validation_level--@>'||Fnd_Api.g_valid_level_full);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Calling Delete_visit :: p_visit_id--@>'||l_visit_id);
                END IF;

                l_return_status := NULL;
                l_msg_count     := 0;
                l_msg_data      := NULL;


                AHL_VWP_VISITS_PVT.Delete_Visit(
                p_api_version             => L_API_VERSION,
                p_init_msg_list           => Fnd_Api.g_false,
                p_commit                  => Fnd_Api.g_false,
                p_validation_level        => Fnd_Api.g_valid_level_full,
                p_visit_id                => l_visit_id,
                x_return_status           => l_return_status,
                x_msg_count               => l_msg_count,
                x_msg_data                => l_msg_data);


                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Delete_visit :: x_return_status--@>'||l_return_status);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Delete_visit :: x_msg_count--@>'||l_msg_count);
                    fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Delete_visit :: x_msg_data--@>'||l_msg_data);
                END IF;

                IF nvl(l_return_status,'x') <> FND_API.G_RET_STS_SUCCESS THEN
                    IF (l_log_statement >= l_log_current_level) THEN
                        FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Error Occured while cancelling VISIT_ID : ' || l_visit_id || ' with x-return-status:' || l_return_status);
                    END IF;
                ELSE
                    IF (l_log_statement >= l_log_current_level) THEN
                        FND_LOG.string(l_log_statement, L_DEBUG_KEY, ' Successfully cancelled VISIT_ID : ' || l_visit_id);
                    END IF;
                END IF;

            END LOOP;
            close get_visit_ids;
        ELSE
            IF (l_log_statement >= l_log_current_level) THEN
                fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Invalid Snapshot Id : ' || p_snapshot_id);
            END IF;
            Fnd_Message.SET_NAME('AHL','AHL_AVF_INVALID_SNAPSHOT');
            Fnd_Msg_Pub.ADD;
            RAISE Fnd_Api.G_EXC_ERROR;
        END IF;

    ELSE
        IF (l_log_statement >= l_log_current_level) THEN
            fnd_log.string(l_log_statement,L_DEBUG_KEY, ' Null Paramter ');
        END IF;
        Fnd_Message.SET_NAME('AHL','AHL_PAGE_PARAMETERS_INVALID');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
    END IF;
-------------------- finish --------------------------
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Cancel_Visits :: p_encoded--@>'||Fnd_Api.g_false);
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Cancel_Visits :: p_count--@>'||x_msg_count);
      fnd_log.string(fnd_log.level_statement,L_DEBUG_KEY,'Return Cancel_Visits :: p_data--@>'||x_msg_data);
    END IF;
      Fnd_Msg_Pub.count_and_get (
      p_encoded => Fnd_Api.g_false,
      p_count   => x_msg_count,
      p_data    => x_msg_data
      );


    IF (l_log_procedure >= l_log_current_level) THEN
        fnd_log.string(l_log_procedure,
                       L_DEBUG_KEY ||'.end',
                       'At the end of PL SQL Procedure.');
    END IF;

    IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
        COMMIT;
    END IF;
----- EXCEPTIONS--------------------------------------

    EXCEPTION
    WHEN Fnd_Api.G_EXC_ERROR THEN
        x_return_status := Fnd_Api.G_RET_STS_ERROR;
        ROLLBACK TO Save_Cancel_visits;
        Fnd_Msg_Pub.count_and_get( p_count   => x_msg_count,
                                   p_data    => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

        WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
        x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
        ROLLBACK TO Save_Cancel_visits;
        Fnd_Msg_Pub.count_and_get( p_count => x_msg_count,
                                   p_data  => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

        WHEN OTHERS THEN
        x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
        ROLLBACK TO Save_Cancel_visits;
        Fnd_Msg_Pub.add_exc_msg( p_pkg_name       => G_PKG_NAME,
                                 p_procedure_name => 'Cancel_Visits',
                                 p_error_text     => SQLERRM);
        Fnd_Msg_Pub.count_and_get( p_count   => x_msg_count,
                                   p_data    => x_msg_data,
                                   p_encoded => Fnd_Api.g_false);

END Cancel_Visits; -- End of begin/procedure.

-------------------------------------------------------------------------------------------------------------------------
--  Validate MR operating organization and returns maintenance organization defined for it
-------------------------------------------------------------------
--  Procedure name   : Validate_MR_Operating_Org
--  Type             : Private
--  Function         : Validate MR operating organization and returns maintenance organization defined for it
--  Parameters  :
--
--  Standard IN  Parameters :
--      p_api_version             IN       NUMBER     Required
--      p_init_msg_list           IN       VARCHAR2   Optional
--      p_commit                  IN       VARCHAR2   Optional
--      p_validation_level        IN       NUMBER     Optional
--      p_mr_header_id            IN       NUMBER     Required
--      p_operating_org_id        OUT      NUMBER
--      x_maintenance_dept_id     OUT      NUMBER
--      x_return_status           OUT      VARCHAR2
--      x_msg_count               OUT      NUMBER
--      x_msg_data                OUT      VARCHAR2
--
--  Version :
--      Initial Version   12.1.3
-------------------------------------------------------------------
PROCEDURE Validate_MR_Operating_Org (
   p_api_version         IN  NUMBER,
   p_init_msg_list       IN  VARCHAR2  := Fnd_Api.g_false,
   p_commit              IN  VARCHAR2  := Fnd_Api.g_false,
   p_validation_level    IN  NUMBER    := Fnd_Api.g_valid_level_full,
   p_mr_header_id        IN  NUMBER,
   p_operating_org_id    IN  NUMBER,
   x_maintenance_org_id  OUT NOCOPY NUMBER,
   x_maintenance_dept_id OUT NOCOPY NUMBER,
   x_return_status     OUT NOCOPY VARCHAR2,
   x_msg_count         OUT NOCOPY NUMBER,
   x_msg_data          OUT NOCOPY VARCHAR2
)
IS
 -- Define local Variables
   L_API_VERSION CONSTANT NUMBER := 1.0;
   L_API_NAME    CONSTANT VARCHAR2(30) := 'Validate_MR_Operating_Org';
   L_FULL_NAME   CONSTANT VARCHAR2(60) := G_PKG_NAME || '.' || L_API_NAME;
   L_DEBUG       CONSTANT VARCHAR2(90) := 'ahl.plsql.'||L_FULL_NAME;

   l_return_status   VARCHAR2(1);
   l_msg_data           VARCHAR2(2000);

   l_mr_header_id     NUMBER;
   l_operating_org_id NUMBER;

   /* Cursor to find maintenance org. from the given operating org. and MR. */
   Cursor get_operating_org_details(c_mr_header_id IN NUMBER, c_operating_org_id IN NUMBER) IS
   SELECT MROrg.MR_ORGANIZATION_ID,
    MROrg.OPERATING_ORG_ID OPERATING_ORG_ID,
    MROrg.MAINTENANCE_ORG_ID,
    HRU.NAME MAINTENANCE_ORG_NAME,
    MROrg.MAINTENANCE_DEPT_ID,
    ADSV.DEPT_DESCRIPTION MAINTENANCE_DEPT_NAME
    FROM AHL_MR_HEADERS_B AMH,
    AHL_MR_ORGANIZATIONS MROrg,
    HR_ORGANIZATION_UNITS HRU,
    AHL_DEPARTMENT_SHIFTS_V ADSV
    WHERE MROrg.MR_TITLE          = AMH.TITLE
    AND MROrg.MAINTENANCE_ORG_ID  = HRU.ORGANIZATION_ID
    AND MROrg.MAINTENANCE_DEPT_ID = ADSV.DEPARTMENT_ID
    AND AMH.MR_HEADER_ID = c_mr_header_id
    AND ( MROrg.OPERATING_ORG_ID    = c_operating_org_id
      OR MROrg.OPERATING_ORG_ID IS NULL )
    order by MROrg.OPERATING_ORG_ID NULLS LAST;

   l_oper_org_dets get_operating_org_details%RowType;

   /* Cursor to get MR Header details*/
   Cursor get_mr_header_details(c_mr_header_id IN NUMBER) IS
    SELECT mr_header_id FROM ahl_mr_headers_vl
    WHERE mr_header_id = c_mr_header_id;

   l_mr_header_dets get_mr_header_details%RowType;

BEGIN
 --------------------- Initialize -----------------------
 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_procedure,L_DEBUG||'.begin','At the start of PLSQL procedure');
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

 ---------------------- Validate MR Header ID ------------------------
 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
      fnd_log.string(fnd_log.level_statement,L_DEBUG,'Validating MR Header ID');
 END IF;

 --Validate MR
 OPEN get_mr_header_details(p_mr_header_id);
 FETCH get_mr_header_details INTO l_mr_header_dets;
 CLOSE get_mr_header_details;

 l_mr_header_id := l_mr_header_dets.mr_header_id;
 IF l_mr_header_id IS NULL THEN

    Fnd_Message.SET_NAME('AHL','AHL_FMP_INVALID_MR');
    Fnd_Msg_Pub.ADD;
       RAISE Fnd_Api.G_EXC_ERROR;

 END IF;

 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Org Validation :: p_mr_header_id--@>'||p_mr_header_id);
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Org Validation :: l_mr_header_id--@>'||l_mr_header_id);
 END IF;

 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Validated MR Header ID');
 END IF;

 ---------------------- Validate Operating Organization ------------------------
 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Validating Operating Organization');
 END IF;

 --Validate Organization
 AHL_VWP_RULES_PVT.Check_Org_Name_Or_Id
               (p_organization_id  => p_operating_org_id,
                p_org_name         => null,
                x_organization_id  => l_operating_org_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Org Validation :: p_operating_org_id--@>'||p_operating_org_id);
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Org Validation :: l_operating_org_id--@>'||l_operating_org_id);
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Org Validation :: l_return_status--@>'||l_return_status);
 END IF;

 IF NVL(l_return_status,'x') <> 'S' THEN
   Fnd_Message.SET_NAME('AHL','AHL_VWP_ORG_NOT_EXISTS');
   Fnd_Msg_Pub.ADD;
   RAISE Fnd_Api.G_EXC_ERROR;
 END IF;

 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'Validated Operating Organization');
 END IF;

 x_maintenance_org_id  := NULL;
 x_maintenance_dept_id := NULL;

 --Get maintenance organization details for the given operating organization
 OPEN get_operating_org_details(l_mr_header_id, l_operating_org_id);
 FETCH get_operating_org_details INTO l_oper_org_dets;
 CLOSE get_operating_org_details;

 --Set OUT variables
 x_maintenance_org_id  := l_oper_org_dets.MAINTENANCE_ORG_ID;
 x_maintenance_dept_id := l_oper_org_dets.MAINTENANCE_DEPT_ID;

 IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_statement,L_DEBUG,'x_maintenance_org_id ** x_maintenance_dept_id ='||x_maintenance_org_id||' ** '||x_maintenance_dept_id);
 END IF;

 --Commented out to leave the null situation for caller to handle :: PRAKKUM :: Bug 13589168 :: 01/16/2012
 /*
 --If maintenance organization or department not found, then set status as failure and raise error
 IF x_maintenance_org_id is NULL or x_maintenance_dept_id is NULL THEN

    Fnd_Message.SET_NAME('AHL','AHL_OPER_NO_MAINTENANCE_DETS');
    Fnd_Msg_Pub.ADD;
    x_return_status := Fnd_Api.g_ret_sts_error;

 END IF;
 */

 -------------------- finish --------------------------
 Fnd_Msg_Pub.count_and_get (
      p_encoded => Fnd_Api.g_false,
      p_count   => x_msg_count,
      p_data    => x_msg_data
 );

 IF (fnd_log.level_procedure >= fnd_log.g_current_runtime_level) THEN
   fnd_log.string(fnd_log.level_procedure,L_DEBUG||'.end','At the end of PLSQL procedure');
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
      IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.g_msg_lvl_unexp_error) THEN
         Fnd_Msg_Pub.add_exc_msg (G_PKG_NAME, l_api_name);
      END IF;
      Fnd_Msg_Pub.count_and_get (
            p_encoded => Fnd_Api.g_false,
            p_count   => x_msg_count,
            p_data    => x_msg_data
      );
END Validate_MR_Operating_Org;


-------------------------------------------------------------------
--  Procedure name    : Create_Primary_Visits
--  Type              : Private
--  Function          : Procedure to create primary visits based on auto visit hierarchy and on primary UEs
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
--
--  Create_Primary_Visits Parameters:
--       p_snapshot_id        IN  NUMBER        Required
--------------------------------------------------------------------------------------------------------------------
PROCEDURE Create_Primary_Visits (
    p_api_version           IN             NUMBER    := 1.0,
    p_init_msg_list         IN             VARCHAR2  := FND_API.G_FALSE,
    p_commit                IN             VARCHAR2  := FND_API.G_FALSE,
    p_validation_level      IN             NUMBER    := FND_API.G_VALID_LEVEL_FULL,
    p_snapshot_id           IN             NUMBER,
    p_add_plan_flag         IN             VARCHAR2  := 'N',
    x_return_status         OUT NOCOPY     VARCHAR2,
    x_msg_count             OUT NOCOPY     NUMBER,
    x_msg_data              OUT NOCOPY     VARCHAR2)IS

-- Local Variables

-- Standard in/out parameters
l_api_name                    VARCHAR2(30) := 'Create_Primary_Visits';
l_api_version                 NUMBER       := 1.0;
l_debug_key          CONSTANT VARCHAR2(100) := 'ahl.plsql.' || G_PKG_NAME || '.' || L_API_NAME;
l_msg_count                   NUMBER;
l_msg_data                    VARCHAR2(2000);
l_return_status               VARCHAR2(1);

l_maintenance_org_id          NUMBER;
l_maintenance_dept_id         NUMBER;
l_start_date                  DATE;
l_start_hour                  NUMBER;
l_start_min                   NUMBER;
l_end_date                    DATE;
l_end_hour                    NUMBER;
l_end_min                     NUMBER;
l_operating_org_id            NUMBER;
-- SATRAJEN :: Bug 16048246 :: Added to call Add_planned_MRs after every creation of visit if required.
l_requery_flag                VARCHAR2(1) := 'Y';
l_visit_rec                   AHL_VWP_VISITS_PVT.Visit_Rec_Type;
l_task_rec                    AHL_VWP_RULES_PVT.Task_Tbl_Type;
l_visit_number                NUMBER;

l_start_date_ts               TIMESTAMP;  --PRAKKUM :: 09/03/2012 :: Bug 13797431
l_end_date_ts                 TIMESTAMP;  --PRAKKUM :: 09/03/2012 :: Bug 13797431

--Cursors

CURSOR get_visit_number(c_visit_id IN NUMBER) IS
SELECT visit_number
FROM ahl_visits_b
WHERE visit_id = c_visit_id;

Cursor get_mc_ids (c_snapshot_id IN NUMBER)
IS
SELECT MC_ID
FROM ahl_autovisit_hierarchy
WHERE HIERARCHY_TYPE_CODE = 'MASTER_CONFIGURATION'
AND SNAPSHOT_ID = c_snapshot_id
AND AUTOVISIT_FLAG = 'Y'
ORDER BY SEQUENCE;

Cursor get_program_type_code (c_snapshot_id IN NUMBER)
IS
SELECT PROGRAM_TYPE_CODE
FROM ahl_autovisit_hierarchy
WHERE HIERARCHY_TYPE_CODE = 'PROGRAM'
AND SNAPSHOT_ID = c_snapshot_id
AND AUTOVISIT_FLAG = 'Y'
ORDER BY SEQUENCE;

Cursor get_prog_subtyp_code (c_snapshot_id IN NUMBER, c_prog_typ_code IN VARCHAR2)
IS
SELECT PROGRAM_SUBTYPE_CODE
FROM ahl_autovisit_hierarchy
WHERE HIERARCHY_TYPE_CODE = 'SUBTYPE'
AND PROGRAM_TYPE_CODE = c_prog_typ_code
AND SNAPSHOT_ID = c_snapshot_id
AND AUTOVISIT_FLAG = 'Y'
ORDER BY SEQUENCE;

Cursor get_count_prog_subtyp (c_snapshot_id IN NUMBER, c_prog_typ_code IN VARCHAR2)
IS
SELECT count(PROGRAM_SUBTYPE_CODE)
FROM ahl_autovisit_hierarchy
WHERE HIERARCHY_TYPE_CODE = 'SUBTYPE'
AND PROGRAM_TYPE_CODE = c_prog_typ_code
AND SNAPSHOT_ID = c_snapshot_id
AND AUTOVISIT_FLAG = 'Y';
l_count NUMBER;

-- Get the start and end dates of a given Snapshot
cursor get_dates(c_snapshot_id IN NUMBER) is
select from_date,to_date
from ahl_autovst_snpsht_hdr
where snapshot_id = c_snapshot_id;
dates_rec get_dates%ROWTYPE;

-- SOSAHNI :: 13/12/2016 :: Bug 25243398 :: Auto Visit Creation
-- SOSAHNI :: 13/12/2016 :: Bug 24296486 :: Primary Auto visit creation errors out after Maintenence Requirement revision
-- Get the UE_IDs of primary MRs
cursor get_primary_ues(c_mc_id      IN NUMBER,
                          c_pt_code      IN VARCHAR2,
                          c_pst_code     IN VARCHAR2,
                          c_start_date IN DATE,
                          c_end_date   IN DATE) is
SELECT ue.unit_effectivity_id, ue.due_date, ue.csi_item_instance_id, mr.mr_header_id,
       mr_vtyp.mr_visit_type_code, vtyp.estimated_duration
FROM ahl_unit_effectivities_b ue, ahl_mr_headers_b mr, ahl_mr_visit_types_app_v mr_vtyp, ahl_visit_types_b vtyp,
AHL_UNIT_CONFIG_HEADERS unit, ahl_mc_headers_b mc
WHERE ue.csi_item_instance_id = unit.csi_item_instance_id
AND unit.master_config_id = mc.mc_header_id
AND unit.unit_config_status_code NOT IN ('QUARANTINE', 'EXPIRED')
AND (ue.status_code ='INIT-DUE' OR ue.status_code IS NULL)
AND mc.mc_id = c_mc_id
AND ue.mr_header_id = mr.mr_header_id
AND mr.program_type_code = c_pt_code
AND (mr.program_subtype_code = c_pst_code
     OR c_pst_code IS NULL)
AND mr.implement_status_code IN ('MANDATORY', 'OPTIONAL_IMPLEMENT')
AND mr.mr_header_id = mr_vtyp.mr_header_id
AND mr_vtyp.mr_visit_type_code = vtyp.visit_type_code
AND vtyp.mc_id = c_mc_id
AND vtyp.status_code = 'COMPLETE'
AND NOT EXISTS (SELECT 'X' from ahl_visit_tasks_b task
                WHERE task.unit_effectivity_id = ue.unit_effectivity_id
                AND task.status_code NOT IN ('CANCELLED', 'DELETED') )
AND ue.due_date BETWEEN c_start_date AND c_end_date;
-- AND NVL(ue.earliest_due_date, c_end_date) BETWEEN c_start_date AND c_end_date
-- AND NVL(ue.latest_due_date, c_end_date) BETWEEN c_start_date AND c_end_date;
l_primary_ue_rec get_primary_ues%ROWTYPE;

Cursor get_ue_operating_org (c_ue_id IN NUMBER) IS
SELECT fleet.operating_org_id
FROM ahl_fleet_headers_b fleet, ahl_unit_effectivities_b ue
WHERE fleet.fleet_header_id = ue.fleet_header_id
and ue.unit_effectivity_id = c_ue_id;

--PRAKKUM :: 24/02/2016 :: Bug 22877137
CURSOR get_item_owner_details(c_csi_ins_id IN NUMBER)
IS
SELECT PARTY_ID CUSTOMER_ID FROM
   CSI_ITEM_INSTANCES CSIS,
   HZ_PARTIES HZP
WHERE CSIS.INSTANCE_ID= c_csi_ins_id
AND CSIS.ACTIVE_START_DATE <= SYSDATE
AND NVL(CSIS.ACTIVE_END_DATE,SYSDATE) >= SYSDATE
AND  CSIS.INV_MASTER_ORGANIZATION_ID IN
     ( SELECT MASTER_ORGANIZATION_ID FROM
               INV_ORGANIZATION_INFO_V ORG,
               MTL_PARAMETERS MP
               WHERE ORG.ORGANIZATION_ID = MP.ORGANIZATION_ID
               AND NVL(OPERATING_UNIT,MO_GLOBAL.GET_CURRENT_ORG_ID()) = MO_GLOBAL.GET_CURRENT_ORG_ID())
AND CSIS.OWNER_PARTY_ID = HZP.PARTY_ID(+)
AND NVL(HZP.PARTY_TYPE,'NO_VAL') IN ('NO_VAL', 'PERSON' , 'ORGANIZATION' );


BEGIN

    IF (l_log_procedure >= l_log_current_level)THEN
      fnd_log.string
      (
        l_log_procedure,
       'ahl.plsql.AHL_AVF_PRIM_VSTS_PVT.Create_Primary_Visits.begin',
       'At the start of PLSQL procedure, snapshot ID : ' || p_snapshot_id
      );
    END IF;

    -- Standard start of API savepoint
     SAVEPOINT Create_Primary_Visits_pvt;

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

     -- make sure that snapshot id is present in the input and is valid
     IF(p_snapshot_id IS NULL OR p_snapshot_id = FND_API.G_MISS_NUM) THEN
        FND_MESSAGE.Set_Name('AHL','AHL_AVF_SNPSHT_INPUT_MISS');
        FND_MSG_PUB.ADD;

        IF (fnd_log.level_exception >= l_log_current_level)THEN
        fnd_log.string
        (
          fnd_log.level_exception,
          L_DEBUG_KEY,
          'Snapshot id is mandatory but found null in input '
        );
        END IF;
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

     ELSE
       OPEN get_dates (p_snapshot_id);
       FETCH get_dates INTO dates_rec;
       IF get_dates%NOTFOUND THEN
         CLOSE get_dates;
         FND_MESSAGE.Set_Name('AHL','AHL_AVF_SNPSHT_INPUT_INVLD');
         FND_MSG_PUB.ADD;

         IF (fnd_log.level_exception >= l_log_current_level)THEN
         fnd_log.string
         (
           fnd_log.level_exception,
           L_DEBUG_KEY,
           'Snapshot id is invalid '
         );
         END IF;
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;
       CLOSE get_dates;
     END IF;

     -- Added for logging visit numbers :: SATRAJEN
     fnd_file.put_line(fnd_file.log, 'List of Visit Numbers created ');


     FOR l_prog_typ_rec IN get_program_type_code( p_snapshot_id ) LOOP
       OPEN get_count_prog_subtyp ( p_snapshot_id, l_prog_typ_rec.PROGRAM_TYPE_CODE );
       FETCH get_count_prog_subtyp INTO l_count;
       CLOSE get_count_prog_subtyp;

       l_operating_org_id := null;
       IF l_count > 0 THEN
         --Get the program subtypes for the given program type and snapshot
         FOR l_prog_subtyp_rec IN get_prog_subtyp_code( p_snapshot_id, l_prog_typ_rec.PROGRAM_TYPE_CODE ) LOOP
           FOR l_mc_rec IN get_mc_ids( p_snapshot_id ) LOOP
             -- Get all the primary UEs for a given set of parameters
             -- SATRAJEN :: Changes Start : Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created. :: 28-12-2012
             -- FOR l_primary_ue_rec IN get_primary_ues( l_mc_rec.mc_id, l_prog_typ_rec.PROGRAM_TYPE_CODE, l_prog_subtyp_rec.program_subtype_code, dates_rec.from_date, dates_rec.to_date ) LOOP
             l_requery_flag := 'Y';
             LOOP
              -- Checking the l_requery_flag as 'Y' in order to requery/Query for the first time, the list of UEs that are to be processed.(As Add planned MRs would have associated some UEs to visits)
              IF l_requery_flag = 'Y' THEN
               -- Cursor get_primary_ues has to be closed inorder to requery the new list of UEs.
               IF get_primary_ues%ISOPEN THEN
                CLOSE get_primary_ues;
               END IF;
               OPEN get_primary_ues(l_mc_rec.mc_id, l_prog_typ_rec.PROGRAM_TYPE_CODE, l_prog_subtyp_rec.program_subtype_code, dates_rec.from_date, dates_rec.to_date);
               FETCH get_primary_ues INTO l_primary_ue_rec;
               l_requery_flag := 'N';
              ELSE -- l_requery_flag = 'N'. Add_planned_MRs was not called. So No need to requery, but fetch the next record.
               FETCH get_primary_ues INTO l_primary_ue_rec;
              END IF;
              EXIT WHEN get_primary_ues%NOTFOUND;
              -- SATRAJEN :: END OF Changes for Bug 16048246.:: 28-12-2012
              OPEN get_ue_operating_org(l_primary_ue_rec.unit_effectivity_id);
              FETCH get_ue_operating_org INTO l_operating_org_id;
              CLOSE get_ue_operating_org;
              IF l_operating_org_id IS NOT NULL THEN
               -- Now call Validate_MR_Operating_Org to get the organization and department of the primary visit
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling Validate_MR_Operating_Org, mr_header_id= '||l_primary_ue_rec.mr_header_id||', operating_org_id= '||l_operating_org_id);
               END IF;
               Validate_MR_Operating_Org (
                                          p_api_version => l_api_version,
                                          p_init_msg_list => Fnd_Api.g_false,
                                          p_commit => Fnd_Api.g_false,
                                          p_validation_level => p_validation_level,
                                          p_mr_header_id => l_primary_ue_rec.mr_header_id,
                                          p_operating_org_id    => l_operating_org_id,
                                          x_maintenance_org_id  => l_maintenance_org_id,
                                          x_maintenance_dept_id => l_maintenance_dept_id,
                                          x_return_status => l_return_status,
                                          x_msg_count => l_msg_count,
                                          x_msg_data => l_msg_data
                                          );
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling Validate_MR_Operating_Org l_return_status= '||l_return_status);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                 x_msg_count := FND_MSG_PUB.count_msg;
                 IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'Errors from Validate_MR_Operating_Org. Message count: ' || x_msg_count);
                 END IF;
                 IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                   RAISE FND_API.G_EXC_ERROR;
                 ELSE
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                 END IF;
               END IF;  -- Return Status is not Success

               -- PRAKKUM :: Bug 13589168 :: 01/16/2012 :: START
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'l_maintenance_org_id ** l_maintenance_dept_id: ' || l_maintenance_org_id || ' ** '|| l_maintenance_dept_id);
                END IF;
               IF l_maintenance_org_id is NULL or l_maintenance_dept_id is NULL THEN
                  CONTINUE;
               END IF;
               -- PRAKKUM :: Bug 13589168 :: 01/16/2012 :: END

               -- Calculate visits start and end date and time based on department shift and UE due date
               l_start_date := AHL_VWP_TIMES_PVT.Compute_Date(l_primary_ue_rec.due_date, l_maintenance_dept_id,0);

               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               l_start_date_ts := cast(l_start_date as timestamp);
               --l_start_hour := (l_start_date - trunc(l_start_date) )*24;
               --l_start_min  := (l_start_hour - trunc (l_start_hour))*60;
               l_start_hour := (extract(HOUR from l_start_date_ts));
               l_start_min := (extract(MINUTE from l_start_date_ts));

               l_end_date := AHL_VWP_TIMES_PVT.Compute_Date(l_primary_ue_rec.due_date, l_maintenance_dept_id, l_primary_ue_rec.estimated_duration);

               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               l_end_date_ts := cast(l_end_date as timestamp);
               --l_end_hour := (l_end_date - trunc(l_end_date) )*24;
               --l_end_min  := (l_end_hour - trunc (l_end_hour))*60;
               l_end_hour := (extract(HOUR from l_end_date_ts));
               l_end_min := (extract(MINUTE from l_end_date_ts));

               -- Nullify the visit record before populating it
               l_visit_rec := null;

               -- Populate all the visit attributes in the visit record l_visit_rec
               SELECT NAME INTO l_visit_rec.UNIT_NAME FROM AHL_UNIT_CONFIG_HEADERS
               WHERE csi_item_instance_id= l_primary_ue_rec.csi_item_instance_id;
               l_visit_rec.VISIT_TYPE_CODE       := l_primary_ue_rec.mr_visit_type_code;
               l_visit_rec.VISIT_NAME            := 'Auto-Visit';
               l_visit_rec.ORGANIZATION_ID       := l_maintenance_org_id;
               l_visit_rec.DEPARTMENT_ID         := l_maintenance_dept_id;
               l_visit_rec.START_DATE            := trunc(l_start_date);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               --l_visit_rec.START_HOUR            := to_number(trunc(l_start_hour));
               --l_visit_rec.START_MIN             := to_number(trunc (l_start_min));
               l_visit_rec.START_HOUR            := l_start_hour;
               l_visit_rec.START_MIN             := l_start_min;
               l_visit_rec.PLAN_END_DATE         := trunc(l_end_date);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               --l_visit_rec.PLAN_END_HOUR         := to_number(trunc(l_end_hour));
               --l_visit_rec.PLAN_END_MIN          := to_number(trunc (l_end_min));
               l_visit_rec.PLAN_END_HOUR         := l_end_hour;
               l_visit_rec.PLAN_END_MIN          := l_end_min;

               l_visit_rec.VISIT_CREATE_TYPE     := 'PLANNING';

               l_visit_rec.PRICING_FLAG          := 'N';--PRAKKUM :: 09/02/2016 :: BUG 22680167

               --PRAKKUM :: 24/02/2016 :: Bug 22877137
               OPEN get_item_owner_details(l_primary_ue_rec.csi_item_instance_id);
               FETCH get_item_owner_details INTO l_visit_rec.CUSTOMER_ID;
               CLOSE get_item_owner_details;

               --PRAKKUM :: 09/03/2012 :: Bug 13797431 -- Added Log Messages
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Visit Details ..');
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.VISIT_TYPE_CODE --@>'|| l_visit_rec.VISIT_TYPE_CODE);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.VISIT_NAME --@>'|| l_visit_rec.VISIT_NAME);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.UNIT_NAME --@>'|| l_visit_rec.UNIT_NAME);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.ORGANIZATION_ID --@>'|| l_visit_rec.ORGANIZATION_ID);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.DEPARTMENT_ID --@>'|| l_visit_rec.DEPARTMENT_ID);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Computed Start Date --@>'|| to_char(l_start_date,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_DATE --@>'|| to_char(l_visit_rec.START_DATE,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_HOUR --@>'|| l_visit_rec.START_HOUR);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_MIN --@>'|| l_visit_rec.START_MIN);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Computed End Date --@>'|| to_char(l_end_date,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_DATE --@>'|| to_char(l_visit_rec.PLAN_END_DATE,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_HOUR --@>'|| l_visit_rec.PLAN_END_HOUR);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_MIN --@>'|| l_visit_rec.PLAN_END_MIN);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.CUSTOMER_ID --@>'|| l_visit_rec.CUSTOMER_ID);
               END IF;

               -- Now create the primary visit
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling AHL_VWP_VISITS_PVT.Create_Visit');
               END IF;
               AHL_VWP_VISITS_PVT.Create_Visit (
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
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling Create_Visit l_return_status= '||l_return_status
                               ||', visit id: '||l_visit_rec.visit_id);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
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
	       -- Added for logging the visit numbers :: SATRAJEN
               ELSE
                   l_visit_number := NULL;
                   OPEN get_visit_number(l_visit_rec.visit_id);
                   FETCH get_visit_number INTO l_visit_number;
                   CLOSE get_visit_number;
                   fnd_file.put_line(fnd_file.log, l_visit_number);
               -- End of logging
               END IF;  -- Return Status is not Success


               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling AHL_VWP_TASKS_PVT.Create_PUP_Tasks, l_visit_rec.visit_id = '
                     ||l_visit_rec.visit_id ||', unit_effectivity_id= '||l_primary_ue_rec.unit_effectivity_id);
               END IF;
               -- Now after the primary visit is created, associate the corresponding primary UE to the visit created
               l_task_rec(1).visit_id := l_visit_rec.visit_id ;
               l_task_rec(1).unit_effectivity_id := l_primary_ue_rec.unit_effectivity_id;
               l_task_rec(1).task_type_code      := 'PLANNED';
               AHL_VWP_TASKS_PVT.Create_PUP_Tasks(
                            p_api_version             => L_API_VERSION,
                            p_init_msg_list           => Fnd_Api.g_false,
                            p_commit                  => Fnd_Api.g_false,
                            p_validation_level        => Fnd_Api.g_valid_level_full,
                            p_module_type             => 'API',
                            p_x_task_tbl              => l_task_rec,
                            x_return_status           => l_return_status,
                            x_msg_count               => l_msg_count,
                            x_msg_data                => l_msg_data);
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling AHL_VWP_TASKS_PVT.Create_PUP_Tasks l_return_status= '||l_return_status);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                 x_msg_count := FND_MSG_PUB.count_msg;
                 IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'Errors from Create_PUP_Tasks. Message count: ' || x_msg_count);
                 END IF;
                 IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                   RAISE FND_API.G_EXC_ERROR;
                 ELSE
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                 END IF;
               END IF;  -- Return Status is not Success
               -- Start of change SATRAJEN :: Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created.:: 28-12-2012
               -- Calling ADD_PLANNED_MRs to associate UEs.
               IF p_add_plan_flag = 'Y' THEN
                  Add_Planned_MRs (
                                p_api_version        => 1.0,
                                p_init_msg_list      => FND_API.G_FALSE,
                                p_commit             => FND_API.G_FALSE,
                                p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                                p_visit_id           => l_visit_rec.visit_id,
                                p_snapshot_id        => p_snapshot_id,
                                x_return_status      => l_return_status,
                                x_msg_count          => l_msg_count,
                                x_msg_data           => l_msg_data
                                );
                  IF (l_log_statement >= l_log_current_level) THEN
                         fnd_log.string(l_log_statement,
                                        L_DEBUG_KEY,
                                       'After calling Add_Planned_MRs l_return_status= '||l_return_status);
                  END IF;
                  -- l_return_status = 'V' then number of UEs for the visit is 0.
                  IF (l_return_status <> FND_API.G_RET_STS_SUCCESS AND l_return_status <> 'V') THEN
                    x_msg_count := FND_MSG_PUB.count_msg;
                    IF (l_log_statement >= l_log_current_level) THEN
                        fnd_log.string(l_log_statement,
                                       L_DEBUG_KEY,
                                      'Errors from Add_Planned_MRs. Message count: ' || x_msg_count);
                    END IF;
                    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                       RAISE FND_API.G_EXC_ERROR;
                    ELSE
                       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    END IF;
                  ELSE
                    l_requery_flag := 'Y';
                  END IF;  -- Return Status is not Success
               END IF; -- p_add_plan_flag = 'Y'
              -- End of Change SATRAJEN :: Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created.:: 28-12-2012
              END IF; -- IF l_operating_org_id IS NOT NULL THEN
             END LOOP; --end loop for UEs
             -- SATRAJEN :: Bug 16048246 : To close the cursor get_primary_ues in case its open after the looping. ( Last record turns out be l_requery_flag := 'N' ):: 28-12-2012
             IF get_primary_ues%ISOPEN THEN
                CLOSE get_primary_ues;
             END IF;
           END LOOP; --loop for MCs
         END LOOP; --loop for program subtypes
       ELSE  -- IF l_count > 0
         -- If there are no program subtype for te given program type, then no need to fetch the subtype
         -- Also pass null as program subtype to get_primary_ues so that all the subtypes will be considered
         FOR l_mc_rec IN get_mc_ids( p_snapshot_id ) LOOP
           -- SATRAJEN :: Changes Start for Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created.:: 28-12-2012
           -- FOR l_primary_ue_rec IN get_primary_ues( l_mc_rec.mc_id, l_prog_typ_rec.PROGRAM_TYPE_CODE, NULL, dates_rec.from_date, dates_rec.to_date ) LOOP
           l_requery_flag := 'Y';
           LOOP
             -- Checking the l_fetch_flag as 'Y' in order to requery the list of UEs that are to be processed.(As Add planned MRs would have associated some UEs to visits)
             IF l_requery_flag = 'Y' THEN
             -- Cursor get_primary_ues has to be closed inorder to requery the new list of UEs.
               IF get_primary_ues%ISOPEN THEN
                 CLOSE get_primary_ues;
               END IF;
               OPEN get_primary_ues(l_mc_rec.mc_id, l_prog_typ_rec.PROGRAM_TYPE_CODE, NULL, dates_rec.from_date, dates_rec.to_date);
               FETCH get_primary_ues INTO l_primary_ue_rec;
               l_requery_flag := 'N';
             ELSE -- l_requery_flag = 'N'. Add_planned_MRs was not called. So No need to requery, but fetch the next record.
               FETCH get_primary_ues INTO l_primary_ue_rec;
             END IF;
             EXIT WHEN get_primary_ues%NOTFOUND;
             -- SATRAJEN :: END OF Changes for Bug 16048246:: 28-12-2012

             OPEN get_ue_operating_org(l_primary_ue_rec.unit_effectivity_id);
             FETCH get_ue_operating_org INTO l_operating_org_id;
             CLOSE get_ue_operating_org;
             IF l_operating_org_id IS NOT NULL THEN
               -- Now call Validate_MR_Operating_Org to get the organization and department of the primary visit
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling Validate_MR_Operating_Org, mr_header_id= '||l_primary_ue_rec.mr_header_id||', operating_org_id= '||l_operating_org_id);
               END IF;
               Validate_MR_Operating_Org (
                                          p_api_version => l_api_version,
                                          p_init_msg_list => Fnd_Api.g_false,
                                          p_commit => Fnd_Api.g_false,
                                          p_validation_level => p_validation_level,
                                          p_mr_header_id => l_primary_ue_rec.mr_header_id,
                                          p_operating_org_id    => l_operating_org_id,
                                          x_maintenance_org_id  => l_maintenance_org_id,
                                          x_maintenance_dept_id => l_maintenance_dept_id,
                                          x_return_status => l_return_status,
                                          x_msg_count => l_msg_count,
                                          x_msg_data => l_msg_data
                                          );
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling Validate_MR_Operating_Org l_return_status= '||l_return_status);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                 x_msg_count := FND_MSG_PUB.count_msg;
                 IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'Errors from Validate_MR_Operating_Org. Message count: ' || x_msg_count);
                 END IF;
                 IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                   RAISE FND_API.G_EXC_ERROR;
                 ELSE
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                 END IF;
               END IF;  -- Return Status is not Success

               -- PRAKKUM :: Bug 13589168 :: 01/16/2012 :: START
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'l_maintenance_org_id ** l_maintenance_dept_id: ' || l_maintenance_org_id || ' ** '|| l_maintenance_dept_id);
               END IF;
               IF l_maintenance_org_id is NULL or l_maintenance_dept_id is NULL THEN
                  CONTINUE;
               END IF;
               -- PRAKKUM :: Bug 13589168 :: 01/16/2012 :: END

               -- Calculate visits start and end date and time based on department shift and UE due date

               l_start_date := AHL_VWP_TIMES_PVT.Compute_Date(l_primary_ue_rec.due_date, l_maintenance_dept_id,0);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               l_start_date_ts := cast(l_start_date as timestamp);
               --l_start_hour := (l_start_date - trunc(l_start_date) )*24;
               --l_start_min  := (l_start_hour - trunc (l_start_hour))*60;
               l_start_hour := (extract(HOUR from l_start_date_ts));
               l_start_min := (extract(MINUTE from l_start_date_ts));

               l_end_date := AHL_VWP_TIMES_PVT.Compute_Date(l_primary_ue_rec.due_date, l_maintenance_dept_id, l_primary_ue_rec.estimated_duration);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               l_end_date_ts := cast(l_end_date as timestamp);
               --l_end_hour := (l_end_date - trunc(l_end_date) )*24;
               --l_end_min  := (l_end_hour - trunc (l_end_hour))*60;
               l_end_hour := (extract(HOUR from l_end_date_ts));
               l_end_min := (extract(MINUTE from l_end_date_ts));

               -- Nullify the visit record before populating it
               l_visit_rec := null;

               -- Populate all the visit attributes
               SELECT NAME INTO l_visit_rec.UNIT_NAME FROM AHL_UNIT_CONFIG_HEADERS
               WHERE csi_item_instance_id= l_primary_ue_rec.csi_item_instance_id;
               l_visit_rec.VISIT_TYPE_CODE       := l_primary_ue_rec.mr_visit_type_code;
               l_visit_rec.VISIT_NAME            := 'Auto-Visit';
               l_visit_rec.ORGANIZATION_ID       := l_maintenance_org_id;
               l_visit_rec.DEPARTMENT_ID         := l_maintenance_dept_id;
               l_visit_rec.START_DATE            := trunc(l_start_date);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               --l_visit_rec.START_HOUR            := to_number(trunc(l_start_hour));
               --l_visit_rec.START_MIN             := to_number(trunc (l_start_min));
               l_visit_rec.START_HOUR            := l_start_hour;
               l_visit_rec.START_MIN             := l_start_min;
               l_visit_rec.PLAN_END_DATE         := trunc(l_end_date);
               --PRAKKUM :: 09/03/2012 :: Bug 13797431
               --l_visit_rec.PLAN_END_HOUR         := to_number(trunc(l_end_hour));
               --l_visit_rec.PLAN_END_MIN          := to_number(trunc (l_end_min));
               l_visit_rec.PLAN_END_HOUR         := l_end_hour;
               l_visit_rec.PLAN_END_MIN          := l_end_min;

               l_visit_rec.VISIT_CREATE_TYPE     := 'PLANNING';

               l_visit_rec.PRICING_FLAG          := 'N';--PRAKKUM :: 09/02/2016 :: BUG 22680167

               --PRAKKUM :: 24/02/2016 :: Bug 22877137
               OPEN get_item_owner_details(l_primary_ue_rec.csi_item_instance_id);
               FETCH get_item_owner_details INTO l_visit_rec.CUSTOMER_ID;
               CLOSE get_item_owner_details;

               --PRAKKUM :: 09/03/2012 :: Bug 13797431 -- Added Log Messages
               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Visit Details ..');
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.VISIT_TYPE_CODE --@>'|| l_visit_rec.VISIT_TYPE_CODE);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.VISIT_NAME --@>'|| l_visit_rec.VISIT_NAME);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.UNIT_NAME --@>'|| l_visit_rec.UNIT_NAME);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.ORGANIZATION_ID --@>'|| l_visit_rec.ORGANIZATION_ID);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.DEPARTMENT_ID --@>'|| l_visit_rec.DEPARTMENT_ID);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Computed Start Date --@>'|| to_char(l_start_date,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_DATE --@>'|| to_char(l_visit_rec.START_DATE,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_HOUR --@>'|| l_visit_rec.START_HOUR);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.START_MIN --@>'|| l_visit_rec.START_MIN);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'Computed End Date --@>'|| to_char(l_end_date,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_DATE --@>'|| to_char(l_visit_rec.PLAN_END_DATE,'DD-MON-YY hh24:mi:ss'));
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_HOUR --@>'|| l_visit_rec.PLAN_END_HOUR);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.PLAN_END_MIN --@>'|| l_visit_rec.PLAN_END_MIN);
                   fnd_log.string( l_log_statement, L_DEBUG_KEY, 'l_visit_rec.CUSTOMER_ID --@>'|| l_visit_rec.CUSTOMER_ID);
               END IF;

               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling AHL_VWP_VISITS_PVT.Create_Visit');
               END IF;
               AHL_VWP_VISITS_PVT.Create_Visit (
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
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling Create_Visit l_return_status= '||l_return_status
                               ||', visit id: '||l_visit_rec.visit_id);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
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
	       -- Added for logging the visit numbers :: SATRAJEN
               ELSE
                   l_visit_number := NULL;
                   OPEN get_visit_number(l_visit_rec.visit_id);
                   FETCH get_visit_number INTO l_visit_number;
                   CLOSE get_visit_number;
                   fnd_file.put_line(fnd_file.log, l_visit_number);
               -- End of logging
               END IF;  -- Return Status is not Success

               IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string
                    ( l_log_statement,
                      L_DEBUG_KEY,
                     'Before calling AHL_VWP_TASKS_PVT.Create_PUP_Tasks, l_visit_rec.visit_id = '
                     ||l_visit_rec.visit_id ||', unit_effectivity_id= '||l_primary_ue_rec.unit_effectivity_id);
               END IF;

               l_task_rec(1).visit_id := l_visit_rec.visit_id ;
               l_task_rec(1).unit_effectivity_id := l_primary_ue_rec.unit_effectivity_id;
               l_task_rec(1).task_type_code      := 'PLANNED';
               AHL_VWP_TASKS_PVT.Create_PUP_Tasks(
                            p_api_version             => L_API_VERSION,
                            p_init_msg_list           => Fnd_Api.g_false,
                            p_commit                  => Fnd_Api.g_false,
                            p_validation_level        => Fnd_Api.g_valid_level_full,
                            p_module_type             => 'API',
                            p_x_task_tbl              => l_task_rec,
                            x_return_status           => l_return_status,
                            x_msg_count               => l_msg_count,
                            x_msg_data                => l_msg_data);
               IF (l_log_statement >= l_log_current_level) THEN
                 fnd_log.string(l_log_statement,
                                L_DEBUG_KEY,
                               'After calling AHL_VWP_TASKS_PVT.Create_PUP_Tasks l_return_status= '||l_return_status);
               END IF;

               IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                 x_msg_count := FND_MSG_PUB.count_msg;
                 IF (l_log_statement >= l_log_current_level) THEN
                   fnd_log.string(l_log_statement,
                                  L_DEBUG_KEY,
                                  'Errors from Create_PUP_Tasks. Message count: ' || x_msg_count);
                 END IF;
                 IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                   RAISE FND_API.G_EXC_ERROR;
                 ELSE
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                 END IF;
               END IF;  -- Return Status is not Success
               -- Start of change SATRAJEN :: Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created.:: 28-12-2012
               -- Calling ADD_PLANNED_MRs to associate UEs.
               IF p_add_plan_flag = 'Y' THEN
                  Add_Planned_MRs (
                                p_api_version        => 1.0,
                                p_init_msg_list      => FND_API.G_FALSE,
                                p_commit             => FND_API.G_FALSE,
                                p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                                p_visit_id           => l_visit_rec.visit_id,
                                p_snapshot_id        => p_snapshot_id,
                                x_return_status      => l_return_status,
                                x_msg_count          => l_msg_count,
                                x_msg_data           => l_msg_data
                                );
                  IF (l_log_statement >= l_log_current_level) THEN
                         fnd_log.string(l_log_statement,
                                        L_DEBUG_KEY,
                                       'After calling Add_Planned_MRs l_return_status= '||l_return_status);
                  END IF;
                  -- l_return_status = 'V' then number of UEs for the visit is 0.
                  IF (l_return_status <> FND_API.G_RET_STS_SUCCESS AND l_return_status <> 'V') THEN
                    x_msg_count := FND_MSG_PUB.count_msg;
                    IF (l_log_statement >= l_log_current_level) THEN
                        fnd_log.string(l_log_statement,
                                       L_DEBUG_KEY,
                                      'Errors from Add_Planned_MRs. Message count: ' || x_msg_count);
                    END IF;
                    IF l_return_status = FND_API.G_RET_STS_ERROR THEN
                       RAISE FND_API.G_EXC_ERROR;
                    ELSE
                       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    END IF;
                  ELSE
                    l_requery_flag := 'Y';
                  END IF;  -- Return Status is not Success
               END IF; -- p_add_plan_flag = 'Y'
             -- End of Change SATRAJEN :: Bug 16048246 : To call Add_Planned_MRs when ever a Primary visit gets created. :: 28-12-2012
             END IF; --l_operating_org_id IS NOT NULL THEN

           END LOOP; -- loop for UEs
           -- SATRAJEN :: Bug 16048246: To close the cursor get_primary_ues in case its open after the looping. ( Last record turns out be l_fetch_flag := 'N' ):: 28-12-2012
           IF get_primary_ues%ISOPEN THEN
             CLOSE get_primary_ues;
           END IF;
         END LOOP; --loop for MC
       END IF; -- IF l_count > 0
     END LOOP; -- loop for program type
     -- Added for logging visit numbers :: SATRAJEN
     fnd_file.put_line(fnd_file.log, '** END of Visits Created ** ');


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

      IF (l_log_procedure >= l_log_current_level)THEN
        fnd_log.string
        (
          l_log_procedure,
          'ahl.plsql.AHL_VWP_PRIM_VSTS_PVT.Create_Primary_Visits.end',
          'At the end of PLSQL procedure'
        );
      END IF;

EXCEPTION

 WHEN FND_API.G_EXC_ERROR THEN

   x_return_status := FND_API.G_RET_STS_ERROR;
   ROLLBACK TO Create_Primary_Visits_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   ROLLBACK TO Create_Primary_Visits_pvt;
   FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                              p_data  => x_msg_data,
                              p_encoded => fnd_api.g_false);

 WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    ROLLBACK TO Create_Primary_Visits_pvt;

    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
       fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                               p_procedure_name => 'Create_Primary_Visits',
                               p_error_text     => SUBSTR(SQLERRM,1,500));
    END IF;

    FND_MSG_PUB.count_and_get( p_count => x_msg_count,
                               p_data  => x_msg_data,
                               p_encoded => fnd_api.g_false);
END Create_Primary_Visits;

--------------------------------------------------------------------
-- PROCEDURE
--    Process_Primary_visits
--
-- PURPOSE
--    Made as an executable for the concurrent program for processing primary visits
--  Process_Primary_visits Parameters :
--      p_snapshot_id       IN    NUMBER
--      errbuf              OUT   VARCHAR2   Required
--         Defines in pl/sql to store procedure to get error messages into log file
--      retcode             OUT   NUMBER     Required
--         To get the status of the concurrent program

--------------------------------------------------------------------
PROCEDURE Process_Primary_visits(
    errbuf            OUT NOCOPY VARCHAR2,
    retcode           OUT NOCOPY NUMBER,
    p_api_version     IN  NUMBER,
    p_snapshot_id     IN  NUMBER
)
IS


-- Local variables section
l_msg_count             NUMBER;
l_msg_data              VARCHAR2(2000);
l_return_status         VARCHAR2(1);
l_api_version           NUMBER := 1.0;
l_api_name              VARCHAR2(30) := 'Process_Primary_visits';
l_err_msg               VARCHAR2(2000);
l_msg_index_out         NUMBER;
l_create_visit_flag     VARCHAR2(1);
l_add_planned_reqs_flag VARCHAR2(1);
l_cancel_visit_flag     VARCHAR2(1);

BEGIN

   -- Standard start of API savepoint
   SAVEPOINT Process_Primary_visits;

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
   fnd_file.put_line(fnd_file.log, 'p_snapshot_id -> '|| p_snapshot_id);
   fnd_file.put_line(fnd_file.log, 'fnd_global.USER_ID -> '|| fnd_global.USER_ID);
   fnd_file.put_line(fnd_file.log, 'fnd_global.RESP_ID -> '||fnd_global.RESP_ID);
   fnd_file.put_line(fnd_file.log, 'fnd_global.PROG_APPL_ID -> '|| fnd_global.PROG_APPL_ID);
   fnd_file.put_line(fnd_file.log, 'mo_global.get_current_org_id -> '|| mo_global.get_current_org_id());

   SELECT create_visit_flag, add_planned_reqs_flag, cancel_visit_flag
   INTO l_create_visit_flag, l_add_planned_reqs_flag, l_cancel_visit_flag
   FROM ahl_autovst_snpsht_hdr WHERE snapshot_id = p_snapshot_id;

   fnd_file.put_line(fnd_file.log, 'l_create_visit_flag -> '|| l_create_visit_flag);
   fnd_file.put_line(fnd_file.log, 'l_add_planned_reqs_flag -> '|| l_add_planned_reqs_flag);
   fnd_file.put_line(fnd_file.log, 'l_cancel_visit_flag -> '|| l_cancel_visit_flag);


   IF NVL(l_cancel_visit_flag,'N') = 'Y' THEN
      fnd_file.put_line(fnd_file.log, 'before calling Cancel_Visits');
      Cancel_Visits (
                        p_api_version        => 1.0,
                        p_init_msg_list      => FND_API.G_FALSE,
                        p_commit             => FND_API.G_FALSE,
                        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                        p_snapshot_id        => p_snapshot_id,
                        x_return_status      => l_return_status,
                        x_msg_count          => l_msg_count,
                        x_msg_data           => l_msg_data
                        );

       l_msg_count := FND_MSG_PUB.Count_Msg;
       IF (l_msg_count > 0) THEN
          fnd_file.put_line(fnd_file.log, 'Following error occured during the call to Cancel_Visits..');
          IF (l_return_status = FND_API.G_RET_STS_ERROR) THEN
              RAISE FND_API.G_EXC_ERROR;
          ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
         COMMIT WORK;
         SAVEPOINT Process_Primary_visits; -- PRAKKUM :: 12/02/2016 :: Fixed issue in error handling
       END IF;

   END IF;

   -- SATRAJEN : Bug 16048246 : Procedure Call based on the number of options selected.:: Added p_add_plan_flag parameter. :: 28-12-2012
   IF NVL(l_create_visit_flag,'N') = 'Y' THEN
      fnd_file.put_line(fnd_file.log, 'before calling Create_Primary_Visits');
      Create_Primary_Visits (
                                p_api_version        => 1.0,
                                p_init_msg_list      => FND_API.G_FALSE,
                                p_commit             => FND_API.G_FALSE,
                                p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                                p_snapshot_id        => p_snapshot_id,
                                p_add_plan_flag      => NVL(l_add_planned_reqs_flag,'N'),
                                x_return_status      => l_return_status,
                                x_msg_count          => l_msg_count,
                                x_msg_data           => l_msg_data
                                );

       l_msg_count := FND_MSG_PUB.Count_Msg;
       IF (l_msg_count > 0) THEN
          fnd_file.put_line(fnd_file.log, 'Following error occured during the call to Create_Primary_Visits..');
          IF (l_return_status = FND_API.G_RET_STS_ERROR) THEN
              RAISE FND_API.G_EXC_ERROR;
          ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
         COMMIT WORK;
         SAVEPOINT Process_Primary_visits; -- PRAKKUM :: 12/02/2016 :: Fixed issue in error handling
       END IF;
   END IF;

   -- SATRAJEN : Bug 16048246 : Procedure Call based on the number of options selected. :: 28-12-2012
   -- IF NVL(l_add_planned_reqs_flag,'N') = 'Y' THEN
   IF ((NVL(l_add_planned_reqs_flag,'N') = 'Y') AND (NVL(l_create_visit_flag,'N') = 'N')) THEN
      fnd_file.put_line(fnd_file.log, 'before calling Add_Planned_MRs');
      Add_Planned_MRs (
                        p_api_version        => 1.0,
                        p_init_msg_list      => FND_API.G_FALSE,
                        p_commit             => FND_API.G_FALSE,
                        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
                        p_snapshot_id        => p_snapshot_id,
                        x_return_status      => l_return_status,
                        x_msg_count          => l_msg_count,
                        x_msg_data           => l_msg_data
                        );

       l_msg_count := FND_MSG_PUB.Count_Msg;
       IF (l_msg_count > 0) THEN
          fnd_file.put_line(fnd_file.log, 'Following error occured during the call to Add_Planned_MRs..');
          IF (l_return_status = FND_API.G_RET_STS_ERROR) THEN
              RAISE FND_API.G_EXC_ERROR;
          ELSE
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
         COMMIT WORK;
         SAVEPOINT Process_Primary_visits; -- PRAKKUM :: 12/02/2016 :: Fixed issue in error handling
       END IF;
   END IF;

EXCEPTION
 WHEN FND_API.G_EXC_ERROR THEN
   ROLLBACK TO Process_Primary_visits;
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
   ROLLBACK TO Process_Primary_visits;
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
   ROLLBACK TO Process_Primary_visits;
   retcode := 2;
   IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
     fnd_msg_pub.add_exc_msg(p_pkg_name       => G_PKG_NAME,
                             p_procedure_name => 'Process_Primary_visits',
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


END Process_Primary_visits;


---------------------------------------------------------------------------------------------------------------------------

END AHL_AVF_PRIM_VSTS_PVT;

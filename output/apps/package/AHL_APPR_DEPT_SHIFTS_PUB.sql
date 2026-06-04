
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPR_DEPT_SHIFTS_PUB" AUTHID CURRENT_USER AS
/* $Header: AHLPDSHS.pls 120.1.12020000.4 2015/01/31 12:36:02 bachandr ship $ */
TYPE APPR_DEPTSHIFT_REC IS RECORD
(
        AHL_DEPARTMENT_SHIFTS_ID                NUMBER,
        ORGANIZATION_ID                         NUMBER,
        ORGANIZATION_NAME                       VARCHAR2(240),
        OBJECT_VERSION_NUMBER                   NUMBER,
        LAST_UPDATE_DATE                        DATE,
        LAST_UPDATED_BY                         NUMBER,
        CREATION_DATE                           DATE,
        CREATED_BY                              NUMBER,
        LAST_UPDATE_LOGIN                       NUMBER,
        DEPARTMENT_ID                           NUMBER,
        DEPT_DESCRIPTION                        VARCHAR2(240),
        CALENDAR_CODE                           VARCHAR2(10),
        CALENDAR_DESCRIPTION                    VARCHAR2(240),
        BOM_WORKDAY_PATTERNS_ID                 NUMBER,
        SHIFT_NUM                               NUMBER,
        SEQ_NUM                                 NUMBER,
        SEQ_NAME                                VARCHAR2(240),
-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
        SUBINVENTORY                            VARCHAR2(10),
        INV_LOCATOR_ID                          NUMBER,
        LOCATOR_SEGMENTS                        VARCHAR2(240),
--ADDED BY SANSATPA FOR NR
        MAX_SERVICE_CATEGORY                    NUMBER,
        DESCRIPTION                             VARCHAR2(240),
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712
        ATTRIBUTE_CATEGORY                      VARCHAR2(30),
        ATTRIBUTE1                              VARCHAR2(150),
        ATTRIBUTE2                              VARCHAR2(150),
        ATTRIBUTE3                              VARCHAR2(150),
        ATTRIBUTE4                              VARCHAR2(150),
        ATTRIBUTE5                              VARCHAR2(150),
        ATTRIBUTE6                              VARCHAR2(150),
        ATTRIBUTE7                              VARCHAR2(150),
        ATTRIBUTE8                              VARCHAR2(150),
        ATTRIBUTE9                              VARCHAR2(150),
        ATTRIBUTE10                             VARCHAR2(150),
        ATTRIBUTE11                             VARCHAR2(150),
        ATTRIBUTE12                             VARCHAR2(150),
        ATTRIBUTE13                             VARCHAR2(150),
        ATTRIBUTE14                             VARCHAR2(150),
        ATTRIBUTE15                             VARCHAR2(150),
        DML_OPERATION                           VARCHAR2(1):='N',
	--Added by Balaji for Endeca Integratin project - start
	DEPT_LATITUDE                           NUMBER,
	DEPT_LONGITUDE                          NUMBER
	--Added by Balaji for Endeca Integratin project - end
	);


PROCEDURE CREATE_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT  NOCOPY     VARCHAR2,
 x_msg_count                    OUT  NOCOPY    NUMBER,
 x_msg_data                     OUT  NOCOPY    VARCHAR2,
 p_x_appr_deptshift_rec      IN  OUT NOCOPY APPR_DEPTSHIFT_REC
 );

PROCEDURE DELETE_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT NOCOPY     VARCHAR2,
 x_msg_count                    OUT NOCOPY     NUMBER,
 x_msg_data                     OUT NOCOPY     VARCHAR2,
 p_x_appr_deptshift_rec      IN  OUT NOCOPY APPR_DEPTSHIFT_REC
 );

 --Added by sansatpa for NR Analysis
 PROCEDURE EDIT_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT NOCOPY     VARCHAR2,
 x_msg_count                    OUT NOCOPY     NUMBER,
 x_msg_data                     OUT NOCOPY     VARCHAR2,
 p_x_appr_deptshift_rec      IN  OUT NOCOPY APPR_DEPTSHIFT_REC
 );


END AHL_APPR_DEPT_SHIFTS_PUB;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPR_DEPT_SHIFTS_PUB" AS
/* $Header: AHLPDSHB.pls 120.1.12020000.5 2015/04/08 10:29:44 sosahni ship $ */
--
G_PKG_NAME    VARCHAR2(30):='AHL_APPR_DEPT_SHIFTS_PUB';

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
G_LOG_PREFIX  CONSTANT VARCHAR2(100) := 'ahl.plsql.AHL_APPR_DEPT_SHIFTS_PUB';
--
PROCEDURE DEFAULT_MISSING_ATTRIBS
(
p_x_appr_deptshift_rec IN OUT NOCOPY AHL_APPR_DEPT_SHIFTS_PUB.appr_deptshift_rec
)
AS
BEGIN
        IF p_x_appr_deptshift_rec.OBJECT_VERSION_NUMBER=FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.OBJECT_VERSION_NUMBER:=NULL;
        END IF;

        IF p_x_appr_deptshift_rec.DEPARTMENT_ID= FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.DEPARTMENT_ID:=NULL;
        END IF;

        IF p_x_appr_deptshift_rec.SHIFT_NUM= FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.SHIFT_NUM:=NULL;
        END IF;

        IF p_x_appr_deptshift_rec.SEQ_NUM= FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.SEQ_NUM:=NULL;
        END IF;

        IF p_x_appr_deptshift_rec.CALENDAR_CODE= FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_rec.CALENDAR_CODE:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE_CATEGORY IS NULL OR p_x_appr_deptshift_Rec.ATTRIBUTE_CATEGORY= FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE_CATEGORY:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE1=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE1:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE2=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE2:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE3=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE3:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE4 IS NULL OR p_x_appr_deptshift_Rec.ATTRIBUTE4=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE4:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE5=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE5:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE6=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE6:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE7=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE7:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE8=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE8:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE9=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE9:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE10=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE10:=NULL;
        END IF;

        IF  p_x_appr_deptshift_Rec.ATTRIBUTE11=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE11:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE12 IS NULL OR p_x_appr_deptshift_Rec.ATTRIBUTE12=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE12:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE13=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE13:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE14=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE14:=NULL;
        END IF;

        IF p_x_appr_deptshift_Rec.ATTRIBUTE15=FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_Rec.ATTRIBUTE15:=NULL;
        END IF;

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
        IF p_x_appr_deptshift_rec.SUBINVENTORY = FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_rec.SUBINVENTORY := NULL;
        END IF;

        IF p_x_appr_deptshift_rec.INV_LOCATOR_ID = FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.INV_LOCATOR_ID := NULL;
        END IF;

        IF p_x_appr_deptshift_rec.LOCATOR_SEGMENTS = FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_rec.LOCATOR_SEGMENTS := NULL;
        END IF;
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712

-- Added by sansatpa for nr analysis
        IF p_x_appr_deptshift_rec.MAX_SERVICE_CATEGORY = FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.MAX_SERVICE_CATEGORY := NULL;
        END IF;

        IF p_x_appr_deptshift_rec.DESCRIPTION = FND_API.G_MISS_CHAR
        THEN
                p_x_appr_deptshift_rec.DESCRIPTION := NULL;
        END IF;

-- end changes by sansatpa for nr analysis

        -- SOSAHNI :: 08/04/2015 :: BUG 20822801 :: Added code to handle empty geocodes :: start

        IF p_x_appr_deptshift_rec.DEPT_LATITUDE = FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.DEPT_LATITUDE := NULL;
        END IF;

        IF p_x_appr_deptshift_rec.DEPT_LONGITUDE = FND_API.G_MISS_NUM
        THEN
                p_x_appr_deptshift_rec.DEPT_LONGITUDE := NULL;
        END IF;

        -- SOSAHNI :: 08/04/2015 :: BUG 20822801 :: Added code to handle empty geocodes :: end

END;

PROCEDURE TRANSLATE_VALUE_ID
 (
 x_return_status                OUT NOCOPY VARCHAR2,
 x_msg_count                    OUT NOCOPY NUMBER,
 x_msg_data                     OUT NOCOPY VARCHAR2,
 p_x_appr_deptshift_rec       IN OUT NOCOPY AHL_APPR_DEPT_SHIFTS_PUB.APPR_DEPTSHIFT_REC
 )
as
 CURSOR get_org_id(C_NAME  VARCHAR2)
 IS
 SELECT ORGANIZATION_ID
 FROM HR_ALL_ORGANIZATION_UNITS
 WHERE NAME=C_NAME;

 CURSOR get_org_dept_id(C_ORG_ID  NUMBER,C_DESCRIPTION  VARCHAR2)
 IS
 SELECT  DEPARTMENT_ID
 FROM BOM_DEPARTMENTS_V
 WHERE ORGANIZATION_ID=C_ORG_ID
 AND DESCRIPTION=C_DESCRIPTION;

 CURSOR get_bom_calendar(C_CALENDAR  VARCHAR2)
 IS
 SELECT CALENDAR_CODE
 FROM  BOM_CALENDARS
 WHERE DESCRIPTION=C_CALENDAR;


 CURSOR get_bom_shift_num(C_CALENDAR_CODE  VARCHAR2,C_SHIFT_NUM NUMBER)
 IS
 SELECT SHIFT_NUM
 FROM BOM_SHIFT_TIMES
 WHERE CALENDAR_CODE=C_CALENDAR_CODE
 AND SHIFT_NUM=C_SHIFT_NUM;

 CURSOR get_bom_workdays(C_CALENDAR_CODE VARCHAR2,C_SHIFT NUMBER,C_DESCRIPTION VARCHAR2)
 IS
 SELECT SEQ_NUM
 FROM BOM_WORKDAY_PATTERNS
 WHERE CALENDAR_CODE=C_CALENDAR_CODE
 AND SHIFT_NUM=C_SHIFT
 AND DESCRIPTION=C_DESCRIPTION;

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 CURSOR get_inv_loc_id(C_ORGANIZATION_ID NUMBER, C_SUBINVENTORY VARCHAR2, C_LOCATOR_SEGMENTS VARCHAR2)
 IS
 SELECT INVENTORY_LOCATION_ID
 FROM MTL_ITEM_LOCATIONS_KFV
 WHERE ORGANIZATION_ID = C_ORGANIZATION_ID
   AND SUBINVENTORY_CODE = C_SUBINVENTORY
   AND CONCATENATED_SEGMENTS = C_LOCATOR_SEGMENTS;
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712
 l_lookup_code           VARCHAR2(30);
 l_num_rec               NUMBER;
 l_msg_count             NUMBER;
 l_msg_data              VARCHAR2(2000);
 l_return_status         VARCHAR2(1);
 l_mr_header_id          number:=0;
 l_lookup_var  varchar2(1);
 l_object_version_number NUMBER;
 l_check_flag            VARCHAR2(1):='N';
 l_counter               NUMBER:=0;
-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 L_DEBUG_KEY             CONSTANT VARCHAR2(150) := G_LOG_PREFIX || '.TRANSLATE_VALUE_ID';
 BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.begin', 'Entering Procedure.');
  END IF;
        x_return_status:=FND_API.G_RET_STS_SUCCESS;
        IF p_x_appr_deptshift_rec.ORGANIZATION_NAME IS NULL OR p_x_appr_deptshift_rec.ORGANIZATION_NAME=FND_API.G_MISS_CHAR
        THEN
                FND_MESSAGE.SET_NAME('AHL','AHL_APPR_ORG_NAME_NULL');
                FND_MSG_PUB.ADD;
                l_check_flag:='N';
        ELSE
                l_check_flag:='Y';
                OPEN get_org_id(p_x_appr_deptshift_rec.ORGANIZATION_NAME);
                FETCH get_org_id INTO p_x_appr_deptshift_rec.ORGANIZATION_ID;
                IF get_org_id%NOTFOUND
                THEN
                        FND_MESSAGE.SET_NAME('AHL','AHL_APPR_ORG_NAME_INVALID');
                        FND_MSG_PUB.ADD;
                        l_check_flag:='N';
                END IF;
                CLOSE get_org_id;
        END IF;

        l_check_flag:='N';
        IF p_x_appr_deptshift_rec.DEPT_DESCRIPTION IS NULL OR p_x_appr_deptshift_rec.DEPT_DESCRIPTION=FND_API.G_MISS_CHAR
        THEN
                FND_MESSAGE.SET_NAME('AHL','AHL_APPR_DEPT_NAME_NULL');
                FND_MSG_PUB.ADD;
                l_check_flag:='N';
        ELSE
                l_check_flag:='Y';
        END IF;

        IF l_check_flag='Y'
        THEN
             OPEN get_org_dept_id(p_x_appr_deptshift_rec.ORGANIZATION_ID,p_x_appr_deptshift_rec.DEPT_DESCRIPTION);
             FETCH get_org_dept_id INTO p_x_appr_deptshift_rec.DEPARTMENT_ID;
             IF get_org_dept_id%NOTFOUND
             THEN
                 FND_MESSAGE.SET_NAME('AHL','AHL_APPR_DEPT_NAME_INVALID');
                 FND_MSG_PUB.ADD;
                 l_check_flag:='N';
             END IF;
             CLOSE get_org_dept_id;
        END IF;


        l_check_flag:='N';
        IF p_x_appr_deptshift_rec.CALENDAR_DESCRIPTION IS NULL OR p_x_appr_deptshift_rec.CALENDAR_DESCRIPTION=FND_API.G_MISS_CHAR
        THEN
                FND_MESSAGE.SET_NAME('AHL','AHL_APPR_CALENDER_NAME_NULL');
                FND_MSG_PUB.ADD;
                l_check_flag:='N';
        ELSE
                l_check_flag:='Y';
        END IF;


        IF l_check_flag='Y'
        THEN
                OPEN get_bom_calendar(p_x_appr_deptshift_rec.CALENDAR_DESCRIPTION);
                FETCH get_bom_calendar INTO p_x_appr_deptshift_rec.CALENDAR_CODE;
                IF get_bom_calendar%NOTFOUND
                THEN
                        FND_MESSAGE.SET_NAME('AHL','AHL_APPR_CALENDER_INVALID');
                        FND_MSG_PUB.ADD;
                        l_check_flag:='N';
                ELSE
                        l_check_flag:='Y';
                END IF;
                CLOSE get_bom_calendar;
        END IF;


        l_check_flag:='N';
        IF p_x_appr_deptshift_rec.SHIFT_NUM IS NULL OR p_x_appr_deptshift_rec.SHIFT_NUM=FND_API.G_MISS_NUM
        THEN
                FND_MESSAGE.SET_NAME('AHL','AHL_APPR_SHIFT_NUMBER_NULL');
                FND_MSG_PUB.ADD;
                l_check_flag:='N';
        ELSE
                l_check_flag:='Y';
        END IF;

        IF l_check_flag='Y'
        THEN
            OPEN  get_bom_shift_num(p_x_appr_deptshift_rec.CALENDAR_CODE,p_x_appr_deptshift_rec.SHIFT_NUM);
            FETCH get_bom_shift_num INTO  p_x_appr_deptshift_rec.SHIFT_NUM;
            IF get_bom_shift_num%NOTFOUND
            THEN
                 FND_MESSAGE.SET_NAME('AHL','AHL_APPR_SHIFT_NUMBER_INVALID');
                 FND_MSG_PUB.ADD;
                 l_check_flag:='N';
            ELSE
                 l_check_flag:='Y';
            END IF;
            CLOSE get_bom_shift_num;
        END IF;


        l_check_flag:='N';
        IF p_x_appr_deptshift_rec.SEQ_NAME IS NULL OR p_x_appr_deptshift_rec.SEQ_NAME=FND_API.G_MISS_CHAR
        THEN
        FND_MESSAGE.SET_NAME('AHL','AHL_APPR_WORK_DAYS_NULL');
                FND_MSG_PUB.ADD;
                l_check_flag:='N';
        ELSE
                l_check_flag:='Y';
        END IF;
        IF l_check_flag='Y'
        THEN
                OPEN  get_bom_workdays(p_x_appr_deptshift_rec.CALENDAR_CODE,p_x_appr_deptshift_rec.SHIFT_NUM,p_x_appr_deptshift_rec.SEQ_NAME);
                FETCH get_bom_workdays INTO p_x_appr_deptshift_rec.SEQ_NUM;
                IF get_bom_workdays%NOTFOUND
                THEN
                        FND_MESSAGE.SET_NAME('AHL','AHL_APPR_SEQ_DESCRIP_INVALID');
                        FND_MSG_PUB.ADD;
                        -- Added by rbhavsar on Nov 27, 2007 for ER 5854712
                        l_check_flag:='N';
                END IF;
                CLOSE get_bom_workdays;
        END IF;

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'p_x_appr_deptshift_rec.ORGANIZATION_ID = ' || p_x_appr_deptshift_rec.ORGANIZATION_ID ||
                                                         ', p_x_appr_deptshift_rec.SUBINVENTORY = ' || p_x_appr_deptshift_rec.SUBINVENTORY ||
                                                         ', p_x_appr_deptshift_rec.INV_LOCATOR_ID = ' || p_x_appr_deptshift_rec.INV_LOCATOR_ID ||
                                                         ', p_x_appr_deptshift_rec.LOCATOR_SEGMENTS = ' || p_x_appr_deptshift_rec.LOCATOR_SEGMENTS);
  END IF;
  -- Convert G_MISS to NULL since this API is called only for creating
  IF (p_x_appr_deptshift_rec.SUBINVENTORY = FND_API.G_MISS_CHAR) THEN
    p_x_appr_deptshift_rec.SUBINVENTORY := NULL;
  END IF;
  IF (p_x_appr_deptshift_rec.LOCATOR_SEGMENTS = FND_API.G_MISS_CHAR) THEN
    p_x_appr_deptshift_rec.LOCATOR_SEGMENTS := NULL;
  END IF;
  IF (p_x_appr_deptshift_rec.INV_LOCATOR_ID = FND_API.G_MISS_NUM) THEN
    p_x_appr_deptshift_rec.INV_LOCATOR_ID := NULL;
  END IF;
  IF (l_check_flag = 'Y' AND
      p_x_appr_deptshift_rec.ORGANIZATION_ID IS NOT NULL AND
      p_x_appr_deptshift_rec.SUBINVENTORY IS NOT NULL AND
      p_x_appr_deptshift_rec.INV_LOCATOR_ID IS NULL AND
      p_x_appr_deptshift_rec.LOCATOR_SEGMENTS IS NOT NULL) THEN
    OPEN get_inv_loc_id(C_ORGANIZATION_ID  => p_x_appr_deptshift_rec.ORGANIZATION_ID,
                        C_SUBINVENTORY     => p_x_appr_deptshift_rec.SUBINVENTORY,
                        C_LOCATOR_SEGMENTS => p_x_appr_deptshift_rec.LOCATOR_SEGMENTS);
    FETCH get_inv_loc_id INTO p_x_appr_deptshift_rec.INV_LOCATOR_ID;
    IF (get_inv_loc_id%NOTFOUND) THEN
        p_x_appr_deptshift_rec.INV_LOCATOR_ID := 0;
    END IF;
    CLOSE get_inv_loc_id;
  END IF;
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'p_x_appr_deptshift_rec.INV_LOCATOR_ID = ' || p_x_appr_deptshift_rec.INV_LOCATOR_ID);
  END IF;

  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.end', 'Exiting Procedure');
  END IF;
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712

EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);

 WHEN FND_API.G_EXC_ERROR THEN
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
 WHEN OTHERS THEN
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_DEPT_SHIFTS_PUB',
                            p_procedure_name  =>  'TRANSLATE_VALUE_ID',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
END;

-- Start of Validate

PROCEDURE VALIDATE_APPR_DEPT_SHIFT
 (
 x_return_status                OUT NOCOPY VARCHAR2,
 x_msg_count                    OUT NOCOPY NUMBER,
 x_msg_data                     OUT NOCOPY VARCHAR2,
 p_appr_deptshift_rec         IN     AHL_APPR_DEPT_SHIFTS_PUB.appr_deptshift_rec
 )
as
 l_counter               NUMBER:=0;
 l_prim_key              NUMBER:=0;

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 CURSOR validate_subinventory(C_ORGANIZATION_ID NUMBER, C_SUBINVENTORY VARCHAR2) IS
 SELECT status_id
   FROM MTL_SECONDARY_INVENTORIES
   WHERE organization_id = C_ORGANIZATION_ID
     AND secondary_inventory_name = C_SUBINVENTORY;

 CURSOR validate_inv_loc_id(C_ORGANIZATION_ID NUMBER, C_SUBINVENTORY VARCHAR2, C_INVENTORY_LOCATION_ID NUMBER) IS
 SELECT 1
 FROM MTL_ITEM_LOCATIONS
 WHERE ORGANIZATION_ID = C_ORGANIZATION_ID
   AND SUBINVENTORY_CODE = C_SUBINVENTORY
   AND INVENTORY_LOCATION_ID = C_INVENTORY_LOCATION_ID
   AND SEGMENT19 IS NULL
   AND SEGMENT20 IS NULL;

 L_DEBUG_KEY CONSTANT VARCHAR2(150) := G_LOG_PREFIX || '.VALIDATE_APPR_DEPT_SHIFT';
 l_temp_num  NUMBER;
 l_status_id NUMBER;
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712

BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.begin', 'Entering Procedure.');
  END IF;
        x_return_status:=FND_API.G_RET_STS_SUCCESS;

IF p_appr_deptshift_rec.DML_OPERATION='C' or p_appr_deptshift_rec.DML_OPERATION='U' THEN
    IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY,
        'ORGANIZATION_NAME = ' || p_appr_deptshift_rec.ORGANIZATION_NAME ||
        ', DEPT_DESCRIPTION = ' || p_appr_deptshift_rec.DEPT_DESCRIPTION ||
        ', CALENDAR_DESCRIPTION = ' || p_appr_deptshift_rec.CALENDAR_DESCRIPTION ||
        ', SHIFT_NUM = ' || p_appr_deptshift_rec.SHIFT_NUM ||
        ', WORKDAY_ID = ' || p_appr_deptshift_rec.BOM_WORKDAY_PATTERNS_ID ||
        ', MAX_SERVICE_CATEGORY = ' || p_appr_deptshift_rec.MAX_SERVICE_CATEGORY);
    end if;
end if;

        IF p_appr_deptshift_rec.DML_OPERATION='D'
        THEN
                IF p_appr_deptshift_rec.OBJECT_VERSION_NUMBER  IS NULL OR p_appr_deptshift_rec.OBJECT_VERSION_NUMBER=FND_API.G_MISS_NUM
                THEN
                       FND_MESSAGE.SET_NAME('AHL','AHL_COM_OBJECT_VERS_NUM_NULL');
                       FND_MSG_PUB.ADD;
                END IF;

                IF p_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID  IS NULL OR p_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID=FND_API.G_MISS_NUM
                THEN
                       FND_MESSAGE.SET_NAME('AHL','AHL_DEPARTMENT_SHIFTS_ID_NULL');
                       FND_MSG_PUB.ADD;
                ELSE
                       SELECT   AHL_DEPARTMENT_SHIFTS_ID INTO l_prim_key
                        FROM AHL_DEPARTMENT_SHIFTS
                        WHERE AHL_DEPARTMENT_SHIFTS_ID=p_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID;
                END IF;
        ELSIF p_appr_deptshift_rec.DML_OPERATION <> 'U'
        THEN
                Select COUNT(DEPARTMENT_ID) INTO l_counter
                FROM AHL_DEPARTMENT_SHIFTS
                WHERE DEPARTMENT_ID=p_appr_deptshift_rec.DEPARTMENT_ID;

                IF l_counter>0
                THEN
                        FND_MESSAGE.SET_NAME('AHL','AHL_APPR_DEPT_EXISTS');
                        FND_MSG_PUB.ADD;
                END IF;
       END IF;

-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
  IF p_appr_deptshift_rec.DML_OPERATION='C' or p_appr_deptshift_rec.DML_OPERATION='U' THEN
    IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'p_appr_deptshift_rec.ORGANIZATION_ID = ' || p_appr_deptshift_rec.ORGANIZATION_ID ||
                                                           ',p_appr_deptshift_rec.SUBINVENTORY = ' || p_appr_deptshift_rec.SUBINVENTORY ||
                                                           ',p_appr_deptshift_rec.INV_LOCATOR_ID = ' || p_appr_deptshift_rec.INV_LOCATOR_ID ||
                                                           ',p_appr_deptshift_rec.LOCATOR_SEGMENTS = ' || p_appr_deptshift_rec.LOCATOR_SEGMENTS);
    END IF;
    IF (p_appr_deptshift_rec.SUBINVENTORY IS NOT NULL) THEN
      OPEN validate_subinventory(C_ORGANIZATION_ID => p_appr_deptshift_rec.ORGANIZATION_ID,
                                 C_SUBINVENTORY    => p_appr_deptshift_rec.SUBINVENTORY);
      FETCH validate_subinventory INTO l_status_id;
      IF (validate_subinventory%NOTFOUND) THEN
        CLOSE validate_subinventory;
        FND_MESSAGE.SET_NAME('AHL','AHL_PRD_INVALID_SUBINVENTORY');
        FND_MESSAGE.Set_Token('INV', p_appr_deptshift_rec.SUBINVENTORY);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSE
        IF l_status_id in (NVL(fnd_profile.value('AHL_MTL_MAT_STATUS_UNSERVICABLE'), -1), NVL(fnd_profile.value('AHL_MTL_MAT_STATUS_MRB'), -1)) THEN
          CLOSE validate_subinventory;
          FND_MESSAGE.SET_NAME('AHL', 'AHL_SUBINVENTORY_NOT_SVC');
          FND_MESSAGE.Set_Token('INV', p_appr_deptshift_rec.SUBINVENTORY);
          FND_MSG_PUB.ADD;
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;
      CLOSE validate_subinventory;
    END IF;

    IF (p_appr_deptshift_rec.SUBINVENTORY IS NULL AND
        (p_appr_deptshift_rec.INV_LOCATOR_ID IS NOT NULL OR p_appr_deptshift_rec.LOCATOR_SEGMENTS IS NOT NULL)) THEN
      FND_MESSAGE.SET_NAME('AHL','AHL_PRD_PC_SUBINV_MANDATORY');
      FND_MSG_PUB.ADD;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF (p_appr_deptshift_rec.INV_LOCATOR_ID IS NOT NULL) THEN
      OPEN validate_inv_loc_id(C_ORGANIZATION_ID       => p_appr_deptshift_rec.ORGANIZATION_ID,
                               C_SUBINVENTORY          => p_appr_deptshift_rec.SUBINVENTORY,
                               C_INVENTORY_LOCATION_ID => p_appr_deptshift_rec.INV_LOCATOR_ID);
      FETCH validate_inv_loc_id INTO l_temp_num;
      IF (validate_inv_loc_id%NOTFOUND) THEN
        CLOSE validate_inv_loc_id;
        FND_MESSAGE.SET_NAME('AHL','AHL_PRD_INVALID_LOCATOR');
        FND_MESSAGE.Set_Token('LOC', p_appr_deptshift_rec.INV_LOCATOR_ID);
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;
      CLOSE validate_inv_loc_id;
    END IF;
  END IF; -- DML_OPERATION='C'

  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.end', 'Exiting Procedure');
  END IF;
-- End Changes by rbhavsar on Nov 27, 2007 for ER 5854712

EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);

 WHEN FND_API.G_EXC_ERROR THEN
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

 WHEN OTHERS THEN
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_DEPT_SHIFTS_PUB',
                            p_procedure_name  =>  'VALIDATE_APPR_DEPT_SHIFT',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

END;

PROCEDURE CREATE_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT  NOCOPY    VARCHAR2,
 x_msg_count                    OUT  NOCOPY    NUMBER,
 x_msg_data                     OUT  NOCOPY    VARCHAR2,
 p_x_appr_deptshift_rec      IN OUT NOCOPY  APPR_DEPTSHIFT_REC
 )
 AS
 l_appr_deptshift_rec     APPR_DEPTSHIFT_REC:= p_x_appr_deptshift_rec;
 l_lookup_code           VARCHAR2(30);
 l_api_name     CONSTANT VARCHAR2(30) := 'CREATE_APPR_DEPT_SHIFTS';
 l_api_version  CONSTANT NUMBER       := 1.0;
 l_msg_count             NUMBER:=0;
 l_msg_data              VARCHAR2(2000);
 l_return_status         VARCHAR2(1);
 l_init_msg_list         VARCHAR2(10):=FND_API.G_TRUE;
 l_department_shifts_id  number:=0;
 l_object_version_number NUMBER;
 l_check_flag            VARCHAR2(1):='Y';
-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 L_DEBUG_KEY CONSTANT VARCHAR2(150) := G_LOG_PREFIX || '.CREATE_APPR_DEPT_SHIFTS';
 BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.begin', 'Entering Procedure.');
  END IF;

        SAVEPOINT CREATE_APPR_DEPT_SHIFTS;

   --   Initialize message list if p_init_msg_list is set to TRUE.

        IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                       p_api_version,
                                       l_api_name,G_PKG_NAME)
        THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        IF FND_API.to_boolean(l_init_msg_list) THEN
                FND_MSG_PUB.initialize;
        END IF;

        x_return_status:=FND_API.G_RET_STS_SUCCESS;


        IF p_module_type = 'JSP'
        THEN
                l_appr_deptshift_rec.ORGANIZATION_ID:=NULL;
                l_appr_deptshift_rec.DEPARTMENT_ID:=NULL;
                l_appr_deptshift_rec.CALENDAR_CODE:=NULL;
                -- Added by rbhavsar on Nov 27, 2007 for ER 5854712
                l_appr_deptshift_rec.INV_LOCATOR_ID := NULL;
        END IF;

    -- Debug info.
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'About to call TRANSLATE_VALUE_ID');
  END IF;

         TRANSLATE_VALUE_ID
         (
         x_return_status             =>x_return_Status,
         x_msg_count                 =>l_msg_count,
         x_msg_data                  =>l_msg_data,
         p_x_appr_deptshift_rec      =>l_appr_deptshift_rec
         );
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'Returned from TRANSLATE_VALUE_ID. x_return_status = ' || x_return_status);
  END IF;
        l_msg_count := FND_MSG_PUB.count_msg;
        IF l_msg_count > 0
        THEN
                x_msg_count := l_msg_count;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                RAISE FND_API.G_EXC_ERROR;
        END IF;


        IF FND_API.to_boolean(p_default)
        THEN
         DEFAULT_MISSING_ATTRIBS
         (
         p_x_appr_deptshift_rec      =>l_appr_deptshift_rec
         );
        END IF;

        IF (p_validation_level = FND_API.G_VALID_LEVEL_FULL )
        THEN

         VALIDATE_APPR_DEPT_SHIFT
         (
         x_return_status             =>x_return_status,
         x_msg_count                 =>l_msg_count,
         x_msg_data                  =>l_msg_data,
         p_appr_deptshift_rec         =>l_appr_deptshift_rec);
        END IF;
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'Returned from VALIDATE_APPR_DEPT_SHIFT. x_return_status = ' || x_return_status);
  END IF;

        l_msg_count := FND_MSG_PUB.count_msg;

        IF l_msg_count > 0
        THEN
                x_msg_count := l_msg_count;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                RAISE FND_API.G_EXC_ERROR;
        END IF;

        -- insert process goes here
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'About to insert into table.');
  END IF;
        IF  l_appr_deptshift_rec.DML_OPERATION='C'
        THEN
                 Select  AHL_DEPARTMENT_SHIFTS_S.nextval into
                          l_department_shifts_id
                         from dual;

                 l_appr_deptshift_rec.OBJECT_VERSION_NUMBER:=1;
                 l_appr_deptshift_rec.LAST_UPDATE_DATE:=sysdate;
                 l_appr_deptshift_rec.LAST_UPDATED_BY:=fnd_global.user_id;
                 l_appr_deptshift_rec.CREATION_DATE:=sysdate;
                 l_appr_deptshift_rec.CREATED_BY:=fnd_global.user_id;
                 l_appr_deptshift_rec.LAST_UPDATE_LOGIN:=fnd_global.user_id;
                 l_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID:=l_department_shifts_id;

                INSERT INTO AHL_DEPARTMENT_SHIFTS
                (
                 AHL_DEPARTMENT_SHIFTS_ID,
                 OBJECT_VERSION_NUMBER,
                 LAST_UPDATE_DATE,
                 LAST_UPDATED_BY,
                 CREATION_DATE,
                 CREATED_BY,
                 LAST_UPDATE_LOGIN,
                 DEPARTMENT_ID,
                 CALENDAR_CODE,
                 SHIFT_NUM,
                 SEQ_NUM,
-- Following two columns added by rbhavsar on Nov 27, 2007 for ER 5854712
                 SUBINVENTORY,
                 INV_LOCATOR_ID,
                 MAX_SERVICE_CATEGORY, --added by sansatpa
                 DESCRIPTION, --added by sansatpa
                 ATTRIBUTE_CATEGORY,
                 ATTRIBUTE1,
                 ATTRIBUTE2,
                 ATTRIBUTE3,
                 ATTRIBUTE4,
                 ATTRIBUTE5,
                 ATTRIBUTE6,
                 ATTRIBUTE7,
                 ATTRIBUTE8,
                 ATTRIBUTE9,
                 ATTRIBUTE10,
                 ATTRIBUTE11,
                 ATTRIBUTE12,
                 ATTRIBUTE13,
                 ATTRIBUTE14,
                 ATTRIBUTE15,
		 DEPT_LATTITUDE,
		 DEPT_LONGITUDE
                )
                VALUES
                (
                 l_DEPARTMENT_SHIFTS_ID,
                 l_appr_deptshift_rec.OBJECT_VERSION_NUMBER,
                 l_appr_deptshift_rec.LAST_UPDATE_DATE,
                 l_appr_deptshift_rec.LAST_UPDATED_BY,
                 l_appr_deptshift_rec.CREATION_DATE,
                 l_appr_deptshift_rec.CREATED_BY,
                 l_appr_deptshift_rec.LAST_UPDATE_LOGIN,
                 l_appr_deptshift_rec.DEPARTMENT_ID,
                 l_appr_deptshift_rec.CALENDAR_CODE,
                 l_appr_deptshift_rec.SHIFT_NUM,
                 l_appr_deptshift_rec.SEQ_NUM,
-- Following two columns added by rbhavsar on Nov 27, 2007 for ER 5854712
                 l_appr_deptshift_rec.SUBINVENTORY,
                 l_appr_deptshift_rec.INV_LOCATOR_ID,
                 l_appr_deptshift_rec.MAX_SERVICE_CATEGORY, --added by sansatpa
                 l_appr_deptshift_rec.DESCRIPTION, --added by sansatpa
                 l_appr_deptshift_rec.ATTRIBUTE_CATEGORY,
                 l_appr_deptshift_rec.ATTRIBUTE1,
                 l_appr_deptshift_rec.ATTRIBUTE2,
                 l_appr_deptshift_rec.ATTRIBUTE3,
                 l_appr_deptshift_rec.ATTRIBUTE4,
                 l_appr_deptshift_rec.ATTRIBUTE5,
                 l_appr_deptshift_rec.ATTRIBUTE6,
                 l_appr_deptshift_rec.ATTRIBUTE7,
                 l_appr_deptshift_rec.ATTRIBUTE8,
                 l_appr_deptshift_rec.ATTRIBUTE9,
                 l_appr_deptshift_rec.ATTRIBUTE10,
                 l_appr_deptshift_rec.ATTRIBUTE11,
                 l_appr_deptshift_rec.ATTRIBUTE12,
                 l_appr_deptshift_rec.ATTRIBUTE13,
                 l_appr_deptshift_rec.ATTRIBUTE14,
                 l_appr_deptshift_rec.ATTRIBUTE15,
		 --Added by Balaji for Endeca Integratin project - start
		 l_appr_deptshift_rec.dept_latitude,
		 l_appr_deptshift_rec.dept_longitude)
                 returning l_DEPARTMENT_SHIFTS_ID into p_x_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID;
                 --Added by Balaji for Endeca Integratin project - end

                 --p_x_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID := l_DEPARTMENT_SHIFTS_ID;

                 IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL)
                 THEN
                 FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY,
                 ' AHL_DEPARTMENT_SHIFTS_ID = ' || p_x_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID ||
                 ' OBJECT_VERSION_NUMBER = ' || p_x_appr_deptshift_rec.OBJECT_VERSION_NUMBER ||
                 ' DEPARTMENT_ID = ' || p_x_appr_deptshift_rec.DEPARTMENT_ID ||
                 ' CALENDAR_CODE = ' || p_x_appr_deptshift_rec.CALENDAR_CODE ||
                 ' SHIFT_NUM = ' || p_x_appr_deptshift_rec.SHIFT_NUM ||
                 ' SEQ_NUM = ' || p_x_appr_deptshift_rec.SEQ_NUM ||
                 ' MAX_SERVICE_CATEGORY = ' || p_x_appr_deptshift_rec.MAX_SERVICE_CATEGORY ||
                 ' DESCRIPTION = ' || p_x_appr_deptshift_rec.DESCRIPTION);
                 END IF;
         END IF;

         IF FND_API.TO_BOOLEAN(p_commit) THEN
            COMMIT;
         END IF;
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.end', 'Exiting Procedure');
  END IF;

 EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO CREATE_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
 WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO CREATE_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
 WHEN OTHERS THEN
    ROLLBACK TO CREATE_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_DEPT_SHIFTS_PUB',
                            p_procedure_name  =>  'CREATE_APPR_DEPT_SHIFTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));

    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
END;

PROCEDURE DELETE_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT NOCOPY     VARCHAR2,
 x_msg_count                    OUT NOCOPY     NUMBER,
 x_msg_data                     OUT NOCOPY     VARCHAR2,
 p_x_appr_deptshift_rec      IN OUT NOCOPY APPR_DEPTSHIFT_REC
 )
 AS
 l_appr_deptshift_rec      APPR_DEPTSHIFT_REC:=p_x_appr_deptshift_rec;
 l_lookup_code           VARCHAR2(30);
 l_api_name     CONSTANT VARCHAR2(30) := 'DELETE_APPR_DEPT_SHIFTS';
 l_api_version  CONSTANT NUMBER       := 1.0;
 l_num_rec               NUMBER;
 l_msg_count             NUMBER;
 l_msg_data              VARCHAR2(2000);
 l_return_status         VARCHAR2(1);
 l_init_msg_list         VARCHAR2(10):=FND_API.G_TRUE;
 l_department_shifts_id          number:=0;
 l_lookup_var  varchar2(1);
 l_object_version_number NUMBER;
 l_check_flag            VARCHAR2(1):='Y';
-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 L_DEBUG_KEY CONSTANT VARCHAR2(150) := G_LOG_PREFIX || '.DELETE_APPR_DEPT_SHIFTS';

 BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.begin', 'Entering Procedure.');
  END IF;

        SAVEPOINT DELETE_DEPT_SHIFTS;

   --   Initialize message list if p_init_msg_list is set to TRUE.

        IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                       p_api_version,
                                       l_api_name,G_PKG_NAME)
        THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        IF FND_API.to_boolean(l_init_msg_list) THEN
                FND_MSG_PUB.initialize;
        END IF;


        x_return_status:=FND_API.G_RET_STS_SUCCESS;


        IF p_module_type = 'JSP'
        THEN
                l_appr_deptshift_rec.ORGANIZATION_ID:=NULL;
                l_appr_deptshift_rec.DEPARTMENT_ID:=NULL;
                l_appr_deptshift_rec.CALENDAR_CODE:=NULL;
                l_appr_deptshift_rec.SHIFT_NUM:=NULL;
        END IF;





        IF (p_validation_level = FND_API.G_VALID_LEVEL_FULL )
        THEN
         VALIDATE_APPR_DEPT_SHIFT
         (
         x_return_status             =>x_return_Status,
         x_msg_count                 =>l_msg_count,
         x_msg_data                  =>l_msg_data,
         p_appr_deptshift_rec         =>l_appr_deptshift_rec);
        END IF;

        l_msg_count := FND_MSG_PUB.count_msg;

        IF l_msg_count > 0
        THEN
                x_msg_count := l_msg_count;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                RAISE FND_API.G_EXC_ERROR;
        END IF;

   -- DELETE GOES HERE

        IF  l_appr_deptshift_rec.DML_OPERATION='D'
        THEN
                DELETE AHL_DEPARTMENT_SHIFTS
                WHERE  AHL_DEPARTMENT_SHIFTS_ID=l_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID
                AND OBJECT_VERSION_NUMBER=l_appr_deptshift_rec.OBJECT_VERSION_NUMBER;
                IF (sql%ROWCOUNT=0)
                THEN
                      FND_MESSAGE.SET_NAME('AHL','AHL_COM_RECORD_CHANGED');
                      FND_MSG_PUB.ADD;
                END IF;
        END IF;

         IF FND_API.TO_BOOLEAN(p_commit) THEN
            COMMIT;
         END IF;
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.end', 'Exiting Procedure');
  END IF;

 EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO DELETE_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
 WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO DELETE_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

 WHEN OTHERS THEN
    ROLLBACK TO DELETE_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_DEPT_SHIFTS_PUB',
                            p_procedure_name  =>  'CREATE_APPR_DEPT_SHIFTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));

    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
END;

--sansatpa added for nr analysis
PROCEDURE EDIT_APPR_DEPT_SHIFTS
 (
 p_api_version               IN         NUMBER:=  1.0,
 p_init_msg_list             IN         VARCHAR2,
 p_commit                    IN         VARCHAR2,
 p_validation_level          IN         NUMBER,
 p_default                   IN         VARCHAR2   := FND_API.G_FALSE,
 p_module_type               IN         VARCHAR2,
 x_return_status                OUT  NOCOPY    VARCHAR2,
 x_msg_count                    OUT  NOCOPY    NUMBER,
 x_msg_data                     OUT  NOCOPY    VARCHAR2,
 p_x_appr_deptshift_rec      IN OUT NOCOPY  APPR_DEPTSHIFT_REC
 )
 AS
 l_appr_deptshift_rec     APPR_DEPTSHIFT_REC := p_x_appr_deptshift_rec;
 l_lookup_code           VARCHAR2(30);
 l_api_name     CONSTANT VARCHAR2(30) := 'EDIT_APPR_DEPT_SHIFTS';
 l_api_version  CONSTANT NUMBER       := 1.0;
 l_msg_count             NUMBER:=0;
 l_msg_data              VARCHAR2(2000);
 l_return_status         VARCHAR2(1);
 l_init_msg_list         VARCHAR2(10):=FND_API.G_TRUE;
 l_department_shifts_id  number:=0;
 l_object_version_number NUMBER;
 l_check_flag            VARCHAR2(1):='Y';
-- Added by rbhavsar on Nov 27, 2007 for ER 5854712
 L_DEBUG_KEY CONSTANT VARCHAR2(150) := G_LOG_PREFIX || '.CREATE_APPR_DEPT_SHIFTS';
 BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.begin', 'Entering Procedure.');
  END IF;

        SAVEPOINT EDIT_APPR_DEPT_SHIFTS;

   --   Initialize message list if p_init_msg_list is set to TRUE.

        IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                       p_api_version,
                                       l_api_name,G_PKG_NAME)
        THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        IF FND_API.to_boolean(l_init_msg_list) THEN
                FND_MSG_PUB.initialize;
        END IF;

        x_return_status:=FND_API.G_RET_STS_SUCCESS;


        IF p_module_type = 'JSP'
        THEN
                l_appr_deptshift_rec.ORGANIZATION_ID:=NULL;
                l_appr_deptshift_rec.DEPARTMENT_ID:=NULL;
                l_appr_deptshift_rec.CALENDAR_CODE:=NULL;
                -- Added by rbhavsar on Nov 27, 2007 for ER 5854712
                l_appr_deptshift_rec.INV_LOCATOR_ID := NULL;
        END IF;

    -- Debug info.
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'About to call TRANSLATE_VALUE_ID');
  END IF;

         TRANSLATE_VALUE_ID
         (
         x_return_status             =>x_return_Status,
         x_msg_count                 =>l_msg_count,
         x_msg_data                  =>l_msg_data,
         p_x_appr_deptshift_rec      =>l_appr_deptshift_rec
         );
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'Returned from TRANSLATE_VALUE_ID. x_return_status = ' || x_return_status);
  END IF;
        l_msg_count := FND_MSG_PUB.count_msg;
        IF l_msg_count > 0
        THEN
                x_msg_count := l_msg_count;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                RAISE FND_API.G_EXC_ERROR;
        END IF;


        IF FND_API.to_boolean(p_default)
        THEN
         DEFAULT_MISSING_ATTRIBS
         (
         p_x_appr_deptshift_rec      =>l_appr_deptshift_rec
         );
        END IF;

        IF (p_validation_level = FND_API.G_VALID_LEVEL_FULL )
        THEN

         VALIDATE_APPR_DEPT_SHIFT
         (
         x_return_status             =>x_return_status,
         x_msg_count                 =>l_msg_count,
         x_msg_data                  =>l_msg_data,
         p_appr_deptshift_rec         =>l_appr_deptshift_rec);
        END IF;
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'Returned from VALIDATE_APPR_DEPT_SHIFT. x_return_status = ' || x_return_status);
  END IF;

        l_msg_count := FND_MSG_PUB.count_msg;

        IF l_msg_count > 0
        THEN
                x_msg_count := l_msg_count;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                RAISE FND_API.G_EXC_ERROR;
        END IF;

        -- insert process goes here
  IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT, L_DEBUG_KEY, 'About to insert into table.');
  END IF;
        IF  l_appr_deptshift_rec.DML_OPERATION = 'U'
        THEN
                 /*Select  AHL_DEPARTMENT_SHIFTS_S.nextval into
                          l_department_shifts_id
                         from dual; */

                l_appr_deptshift_rec.LAST_UPDATE_DATE:=sysdate;
                l_appr_deptshift_rec.LAST_UPDATED_BY:=fnd_global.user_id;
                l_appr_deptshift_rec.CREATION_DATE:=sysdate;
                l_appr_deptshift_rec.CREATED_BY:=fnd_global.user_id;
                l_appr_deptshift_rec.LAST_UPDATE_LOGIN:=fnd_global.user_id;
                --l_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID:=l_department_shifts_id;

                UPDATE AHL_DEPARTMENT_SHIFTS SET
                OBJECT_VERSION_NUMBER =    l_appr_deptshift_rec.OBJECT_VERSION_NUMBER + 1,
                LAST_UPDATE_DATE =         l_appr_deptshift_rec.LAST_UPDATE_DATE,
                LAST_UPDATED_BY =          l_appr_deptshift_rec.LAST_UPDATED_BY,
                CREATION_DATE =            l_appr_deptshift_rec.CREATION_DATE,
                CREATED_BY =               l_appr_deptshift_rec.CREATED_BY,
                LAST_UPDATE_LOGIN =        l_appr_deptshift_rec.LAST_UPDATE_LOGIN,
                DEPARTMENT_ID =            l_appr_deptshift_rec.DEPARTMENT_ID,
                CALENDAR_CODE =            l_appr_deptshift_rec.CALENDAR_CODE,
                SHIFT_NUM =                l_appr_deptshift_rec.SHIFT_NUM,
                SEQ_NUM =                  l_appr_deptshift_rec.SEQ_NUM,
                SUBINVENTORY =             l_appr_deptshift_rec.SUBINVENTORY,
                INV_LOCATOR_ID =           l_appr_deptshift_rec.INV_LOCATOR_ID,
                MAX_SERVICE_CATEGORY =     l_appr_deptshift_rec.MAX_SERVICE_CATEGORY,
                DESCRIPTION =              l_appr_deptshift_rec.DESCRIPTION,
                ATTRIBUTE_CATEGORY =       l_appr_deptshift_rec.ATTRIBUTE_CATEGORY,
                ATTRIBUTE1 =               l_appr_deptshift_rec.ATTRIBUTE1,
                ATTRIBUTE2 =               l_appr_deptshift_rec.ATTRIBUTE2,
                ATTRIBUTE3 =               l_appr_deptshift_rec.ATTRIBUTE3,
                ATTRIBUTE4 =               l_appr_deptshift_rec.ATTRIBUTE4,
                ATTRIBUTE5 =               l_appr_deptshift_rec.ATTRIBUTE5,
                ATTRIBUTE6 =               l_appr_deptshift_rec.ATTRIBUTE6,
                ATTRIBUTE7 =               l_appr_deptshift_rec.ATTRIBUTE7,
                ATTRIBUTE8 =               l_appr_deptshift_rec.ATTRIBUTE8,
                ATTRIBUTE9 =               l_appr_deptshift_rec.ATTRIBUTE9,
                ATTRIBUTE10 =              l_appr_deptshift_rec.ATTRIBUTE10,
                ATTRIBUTE11 =              l_appr_deptshift_rec.ATTRIBUTE11,
                ATTRIBUTE12 =              l_appr_deptshift_rec.ATTRIBUTE12,
                ATTRIBUTE13 =              l_appr_deptshift_rec.ATTRIBUTE13,
                ATTRIBUTE14 =              l_appr_deptshift_rec.ATTRIBUTE14,
                ATTRIBUTE15 =              l_appr_deptshift_rec.ATTRIBUTE15,
              	--Added by Balaji for Endeca Integratin project - start
		DEPT_LATTITUDE =           l_appr_deptshift_rec.DEPT_LATITUDE,
                DEPT_LONGITUDE =           l_appr_deptshift_rec.DEPT_LONGITUDE
              	--Added by Balaji for Endeca Integratin project - end
		where
                AHL_DEPARTMENT_SHIFTS_ID = l_appr_deptshift_rec.AHL_DEPARTMENT_SHIFTS_ID
                and OBJECT_VERSION_NUMBER =l_appr_deptshift_rec.OBJECT_VERSION_NUMBER;
         END IF;

        -- If the record does not exist, then, abort API.
        IF ( SQL%ROWCOUNT = 0 ) THEN
          FND_MESSAGE.set_name('AHL','AHL_FMP_RECORD_CHANGED');
          --FND_MESSAGE.set_token( 'RECORD', get_record_identifier( l_appr_deptshift_rec ) );
          FND_MSG_PUB.add;
        END IF;

         IF FND_API.TO_BOOLEAN(p_commit) THEN
            COMMIT;
         END IF;
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE, L_DEBUG_KEY || '.end', 'Exiting Procedure');
  END IF;

 EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO EDIT_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
 WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO EDIT_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
 WHEN OTHERS THEN
    ROLLBACK TO EDIT_APPR_DEPT_SHIFTS;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_DEPT_SHIFTS_PUB',
                            p_procedure_name  =>  'CREATE_APPR_DEPT_SHIFTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));

    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
END;

END AHL_APPR_DEPT_SHIFTS_PUB;

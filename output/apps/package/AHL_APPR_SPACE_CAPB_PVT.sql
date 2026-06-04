
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPR_SPACE_CAPB_PVT" AUTHID CURRENT_USER AS
/* $Header: AHLVSPCS.pls 115.7 2003/11/04 10:43:18 rroy noship $ */

-----------------------------------------------------------
-- PACKAGE
--    AHL_APPR_SPACE_CAPB_PVT
--
-- PURPOSE
--    This package is a Private API for managing Space and space Capabilities information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_VL  And AHL_SPACE_CAPABILITIES:
--    Create_Space (see below for specification)
--    Update_Space (see below for specification)
--    Delete_Space (see below for specification)
--    Create_Space_Capblts (see below for specification)
--    Update_Space_Capblts (see below for specification)
--    Delete_Space_Capblts (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 19-Apr-2002    ssurapan      Created.
-----------------------------------------------------------

-------------------------------------
-----          SPACES And SPACE CAPABILITIES            -----
-------------------------------------
-- Record for AHL_SPACES_VL
TYPE Space_Rec IS RECORD (
   space_id                     NUMBER,
   space_name                   VARCHAR2(30),
   last_update_date             DATE,
   last_updated_by              NUMBER,
   creation_date                DATE,
   created_by                   NUMBER,
   last_update_login            NUMBER,
   object_version_number        NUMBER,
   organization_id              NUMBER,
   org_name                     VARCHAR2(240),
   department_id                NUMBER,
   dept_description             VARCHAR2(240),
   space_category_code          VARCHAR2(30),
   space_category_mean          VARCHAR2(80),
   inactive_flag_code           VARCHAR2(1),
   inactive_flag_mean           VARCHAR2(30),
   description                  VARCHAR2(2000),
   attribute_category           VARCHAR2(30),
   attribute1                   VARCHAR2(150),
   attribute2                   VARCHAR2(150),
   attribute3                   VARCHAR2(150),
   attribute4                   VARCHAR2(150),
   attribute5                   VARCHAR2(150),
   attribute6                   VARCHAR2(150),
   attribute7                   VARCHAR2(150),
   attribute8                   VARCHAR2(150),
   attribute9                   VARCHAR2(150),
   attribute10                  VARCHAR2(150),
   attribute11                  VARCHAR2(150),
   attribute12                  VARCHAR2(150),
   attribute13                  VARCHAR2(150),
   attribute14                  VARCHAR2(150),
   attribute15                  VARCHAR2(150),
   operation_flag               VARCHAR2(1)
);

-- Record for AHL_SPACE_CAPABILITIES
TYPE Space_Capbl_Rec IS RECORD (
   space_capability_id          NUMBER,
   last_update_date             DATE,
   last_updated_by              NUMBER,
   creation_date                DATE,
   created_by                   NUMBER,
   last_update_login            NUMBER,
   object_version_number        NUMBER,
   visit_type_code              VARCHAR2(30),
   visit_type_mean              VARCHAR2(80),
   inventory_item_id            NUMBER,
   item_description             varchar2(240),
   organization_id              NUMBER,
   org_name                     VARCHAR2(240),
   space_id                     NUMBER,
   space_name                   VARCHAR2(30),
   attribute_category           VARCHAR2(30),
   attribute1                   VARCHAR2(150),
   attribute2                   VARCHAR2(150),
   attribute3                   VARCHAR2(150),
   attribute4                   VARCHAR2(150),
   attribute5                   VARCHAR2(150),
   attribute6                   VARCHAR2(150),
   attribute7                   VARCHAR2(150),
   attribute8                   VARCHAR2(150),
   attribute9                   VARCHAR2(150),
   attribute10                  VARCHAR2(150),
   attribute11                  VARCHAR2(150),
   attribute12                  VARCHAR2(150),
   attribute13                  VARCHAR2(150),
   attribute14                  VARCHAR2(150),
   attribute15                  VARCHAR2(150),
   operation_flag               VARCHAR2(1)
);

--Declare Space table type
TYPE space_tbl IS TABLE OF Space_Rec
INDEX BY BINARY_INTEGER;

--Declare Space Capabilities table type
TYPE space_Capbl_tbl IS TABLE OF Space_Capbl_Rec
INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space
--
-- PURPOSE
--    Create Space Record
--
-- PARAMETERS
--    p_x_space_restriction_rec: the record representing AHL_SPACES_VL view..
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Create_Space (
   p_api_version             IN      NUMBER,
   p_init_msg_list           IN      VARCHAR2  := FND_API.g_false,
   p_commit                  IN      VARCHAR2  := FND_API.g_false,
   p_validation_level        IN      NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN      VARCHAR2  := 'JSP',
   p_x_space_rec             IN  OUT NOCOPY ahl_appr_space_capb_pub.Space_Rec,
   x_return_status               OUT NOCOPY VARCHAR2,
   x_msg_count                   OUT NOCOPY NUMBER,
   x_msg_data                    OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space
--
-- PURPOSE
--    Update Space Record.
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACES_VL
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_rec               IN    ahl_appr_space_capb_pub.Space_Rec,
   x_return_status             OUT NOCOPY VARCHAR2,
   x_msg_count                 OUT NOCOPY NUMBER,
   x_msg_data                  OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space
--
-- PURPOSE
--    Delete  Space Record.
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACES_VL
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space (
   p_api_version                IN    NUMBER,
   p_init_msg_list              IN    VARCHAR2  := FND_API.g_false,
   p_commit                     IN    VARCHAR2  := FND_API.g_false,
   p_validation_level           IN    NUMBER    := FND_API.g_valid_level_full,
   p_space_rec                  IN    ahl_appr_space_capb_pub.Space_Rec,
   x_return_status                OUT NOCOPY VARCHAR2,
   x_msg_count                    OUT NOCOPY NUMBER,
   x_msg_data                     OUT NOCOPY VARCHAR2

);

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space_Capblts
--
-- PURPOSE
--    Create Space Capabilities Record
--
-- PARAMETERS
--    p_x_space_capblts_rec: the record representing AHL_SPACE_CAPABILITIES table..
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Create_Space_Capblts (
   p_api_version             IN      NUMBER,
   p_init_msg_list           IN      VARCHAR2  := FND_API.g_false,
   p_commit                  IN      VARCHAR2  := FND_API.g_false,
   p_validation_level        IN      NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN      VARCHAR2  := 'JSP',
   p_x_space_capblts_rec     IN  OUT NOCOPY ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status               OUT NOCOPY VARCHAR2,
   x_msg_count                   OUT NOCOPY NUMBER,
   x_msg_data                    OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space_Capblts
--
-- PURPOSE
--    Update Space Capblities Record.
--
-- PARAMETERS
--    p_space_capblts_rec: the record representing AHL_SPACE_CAPBLITIES table
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space_Capblts (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_capblts_rec       IN    ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status             OUT NOCOPY VARCHAR2,
   x_msg_count                 OUT NOCOPY NUMBER,
   x_msg_data                  OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space_Capblts
--
-- PURPOSE
--    Delete  Space Capabilities Record.
--
-- PARAMETERS
--    p_space_capblts_rec: the record representing AHL_SPACE_CAPABILITIES table
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space_Capblts (
   p_api_version                IN    NUMBER,
   p_init_msg_list              IN    VARCHAR2  := FND_API.g_false,
   p_commit                     IN    VARCHAR2  := FND_API.g_false,
   p_validation_level           IN    NUMBER    := FND_API.g_valid_level_full,
   p_space_capblts_rec         IN    ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status                OUT NOCOPY VARCHAR2,
   x_msg_count                    OUT NOCOPY NUMBER,
   x_msg_data                     OUT NOCOPY VARCHAR2

);

END AHL_APPR_SPACE_CAPB_PVT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPR_SPACE_CAPB_PVT" AS
/* $Header: AHLVSPCB.pls 115.12 2003/11/04 10:43:16 rroy noship $ */

G_PKG_NAME  VARCHAR2(30)  := 'AHL_APPR_SPACE_CAPB_PVT';
G_DEBUG 		 VARCHAR2(1):=AHL_DEBUG_PUB.is_log_enabled;
--
-----------------------------------------------------------
-- PACKAGE
--    AHL_APPR_SPACE_CAPB_PVT
--
-- PURPOSE
--    This package is a Private API for managing Space and space capabilities information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_UNAVIALABLE_VL:
--    Create_Space (see below for specification)
--    Update_Space (see below for specification)
--    Delete_Space (see below for specification)
--    Validate_Space (see below for specification)
--    Create_Space_capblts (see below for specification)
--    Update_Space_capblts (see below for specification)
--    Delete_Space_capblts (see below for specification)
--    Validate_Space_capblts (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 19-Apr-2002    ssurapan      Created

-------------------------------------------------------------
--  procedure name: Check_lookup_name_Or_Id(private procedure)
-- description :  used to retrieve lookup code
--
--------------------------------------------------------------

PROCEDURE Check_lookup_name_Or_Id
 ( p_lookup_type      IN FND_LOOKUPS.lookup_type%TYPE,
   p_lookup_code      IN FND_LOOKUPS.lookup_code%TYPE,
   p_meaning          IN FND_LOOKUPS.meaning%TYPE,
   p_check_id_flag    IN VARCHAR2,
   x_lookup_code      OUT NOCOPY VARCHAR2,
   x_return_status    OUT NOCOPY VARCHAR2)
IS

BEGIN
      --
      IF (p_lookup_code IS NOT NULL) THEN
        IF (p_check_id_flag = 'Y') THEN
          SELECT lookup_code INTO x_lookup_code
           FROM FND_LOOKUP_VALUES_VL
          WHERE lookup_type = p_lookup_type
            AND lookup_code = p_lookup_code
            AND SYSDATE BETWEEN start_date_active
            AND NVL(end_date_active,SYSDATE);
        ELSE
           x_lookup_code := p_lookup_code;
        END IF;
     ELSE
          SELECT lookup_code INTO x_lookup_code
           FROM FND_LOOKUP_VALUES_VL
          WHERE lookup_type = p_lookup_type
            AND meaning     = p_meaning
            AND SYSDATE BETWEEN start_date_active
            AND NVL(end_date_active,SYSDATE);
    END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_return_status := Fnd_Api.G_RET_STS_ERROR;
   WHEN TOO_MANY_ROWS THEN
      x_return_status := Fnd_Api.G_RET_STS_ERROR;
   WHEN OTHERS THEN
      x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE;
END;


--------------------------------------------------------------------
-- PROCEDURE
--    CHECK_ORG_NAME_OR_ID
--
-- PURPOSE
--    Converts Org Name to ID or Vice versa
--
-- PARAMETERS
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Check_org_name_Or_Id
    (p_organization_id     IN NUMBER,
     p_org_name            IN VARCHAR2,
     x_organization_id     OUT NOCOPY NUMBER,
     x_return_status       OUT NOCOPY VARCHAR2,
     x_error_msg_code      OUT NOCOPY VARCHAR2
     )
   IS
BEGIN
      IF (p_organization_id IS NOT NULL)
       THEN
          SELECT organization_id
              INTO x_organization_id
            FROM HR_ALL_ORGANIZATION_UNITS
          WHERE organization_id   = p_organization_id;
      ELSE
          SELECT organization_id
              INTO x_organization_id
            FROM HR_ALL_ORGANIZATION_UNITS
          WHERE NAME  = p_org_name;
      END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_ORG_ID_NOT_EXISTS';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_ORG_ID_NOT_EXISTS';
       WHEN OTHERS THEN
         x_return_status:= Fnd_Api.G_RET_STS_UNEXP_ERROR;
         RAISE;
END Check_org_name_Or_Id;
--------------------------------------------------------------------
-- PROCEDURE
--    CHECK_DEPT_DESC_OR_ID
--
-- PURPOSE
--    Converts Dept description to ID or Vice Versa
--
-- PARAMETERS
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Check_dept_desc_Or_Id
    (p_organization_id     IN NUMBER,
     p_org_name            IN VARCHAR2,
     p_department_id       IN NUMBER,
     p_dept_description    IN VARCHAR2,
     x_department_id       OUT NOCOPY NUMBER,
     x_return_status       OUT NOCOPY VARCHAR2,
     x_error_msg_code      OUT NOCOPY VARCHAR2
     )
   IS
BEGIN

      IF (p_department_id IS NOT NULL)
       THEN
          SELECT department_id
             INTO x_department_id
            FROM BOM_DEPARTMENTS
          WHERE organization_id = p_organization_id
            AND department_id   = p_department_id;
      END IF;
      --
      IF(p_dept_description IS NOT NULL) THEN
          SELECT department_id
             INTO x_department_id
           FROM BOM_DEPARTMENTS
          WHERE organization_id =  p_organization_id
            AND description = p_dept_description;
      END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_DEPT_ID_NOT_EXIST';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_DEPT_ID_NOT_EXIST';
       WHEN OTHERS THEN
         x_return_status:= Fnd_Api.G_RET_STS_UNEXP_ERROR;
         RAISE;
END Check_dept_desc_Or_Id;

--------------------------------------------------------------------
-- PROCEDURE
--    CHECK_SPACE_NAME_OR_ID
--
-- PURPOSE
--    Converts Space Name to ID or Vice versa
--
-- PARAMETERS
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Check_space_name_Or_Id
    (p_space_id            IN NUMBER,
     p_space_name          IN VARCHAR2,
     x_space_id            OUT NOCOPY NUMBER,
     x_return_status       OUT NOCOPY VARCHAR2,
     x_error_msg_code      OUT NOCOPY VARCHAR2
     )
   IS
BEGIN
      IF (p_space_id IS NOT NULL)
       THEN
          SELECT space_id
              INTO x_space_id
            FROM AHL_SPACES_VL
          WHERE space_id   = p_space_id;
      ELSE
          SELECT space_id
              INTO x_space_id
           FROM AHL_SPACES_VL
          WHERE SPACE_NAME  = p_space_name;
      END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_SPACE_NOT_EXISTS';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_SPACE_NOT_EXISTS';
       WHEN OTHERS THEN
         x_return_status:= Fnd_Api.G_RET_STS_UNEXP_ERROR;
         RAISE;
END Check_space_name_Or_Id;

---------------------------------------------------------------------
-- PROCEDURE
--    Assign_Space_Rec
--
---------------------------------------------------------------------
PROCEDURE Assign_Space_Rec (
   p_space_rec      IN  AHL_APPR_SPACE_CAPB_PUB.Space_rec,
   x_space_rec        OUT NOCOPY Space_rec
)
IS

BEGIN
     x_space_rec.space_id            :=  p_space_rec.space_id;
     x_space_rec.organization_id     :=  p_space_rec.organization_id;
     x_space_rec.org_name            :=  p_space_rec.org_name;
     x_space_rec.department_id       :=  p_space_rec.department_id;
     x_space_rec.dept_Description    :=  p_space_rec.dept_description;
     x_space_rec.space_name          :=  p_space_rec.space_name;
     x_space_rec.space_category_code :=  p_space_rec.space_category_code;
     x_space_rec.space_category_mean :=  p_space_rec.space_category_mean;
     x_space_rec.inactive_flag_code  :=  p_space_rec.inactive_flag_code;
     x_space_rec.inactive_flag_mean  :=  p_space_rec.inactive_flag_mean;
     x_space_rec.object_version_number :=  p_space_rec.object_version_number;
     x_space_rec.attribute_category  :=  p_space_rec.attribute_category;
     x_space_rec.attribute1          :=  p_space_rec.attribute1;
     x_space_rec.attribute2          :=  p_space_rec.attribute2;
     x_space_rec.attribute3          :=  p_space_rec.attribute3;
     x_space_rec.attribute4          :=  p_space_rec.attribute4;
     x_space_rec.attribute5          :=  p_space_rec.attribute5;
     x_space_rec.attribute6          :=  p_space_rec.attribute6;
     x_space_rec.attribute7          :=  p_space_rec.attribute7;
     x_space_rec.attribute8          :=  p_space_rec.attribute8;
     x_space_rec.attribute9          :=  p_space_rec.attribute9;
     x_space_rec.attribute10         :=  p_space_rec.attribute10;
     x_space_rec.attribute11         :=  p_space_rec.attribute11;
     x_space_rec.attribute12         :=  p_space_rec.attribute12;
     x_space_rec.attribute13         :=  p_space_rec.attribute13;
     x_space_rec.attribute14         :=  p_space_rec.attribute14;
     x_space_rec.attribute15         :=  p_space_rec.attribute15;

END Assign_Space_Rec;

---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Space_Rec
--
---------------------------------------------------------------------
PROCEDURE Complete_Space_Rec (
   p_space_rec      IN  Space_rec,
   x_space_rec      OUT NOCOPY Space_rec
)
IS
  CURSOR c_space_rec
   IS
   SELECT ROW_ID,
          SPACE_ID,
          SPACE_NAME,
          BOM_DEPARTMENT_ID,
          ORGANIZATION_ID,
          SPACE_CATEGORY,
          INACTIVE_FLAG,
          OBJECT_VERSION_NUMBER,
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
          ATTRIBUTE15
     FROM  ahl_spaces_vl
   WHERE   space_id = p_space_rec.space_id;
   --
 CURSOR check_dup_name (c_space_name IN VARCHAR2,
                        c_dept_id   IN NUMBER)
 IS
   SELECT space_id FROM
     AHL_SPACES_VL
   WHERE space_name = c_space_name
     AND bom_department_id = c_dept_id;
   -- This is the only exception for using %ROWTYPE.
   l_space_rec    c_space_rec%ROWTYPE;
   l_dummy        NUMBER;
BEGIN
   x_space_rec := p_space_rec;
   OPEN c_space_rec;
   FETCH c_space_rec INTO l_space_rec;
   IF c_space_rec%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
        RAISE Fnd_Api.G_EXC_ERROR;
      END IF;
   END IF;
   CLOSE c_space_rec;
   --
   --Check for object version number
    IF (l_space_rec.object_version_number <> p_space_rec.object_version_number)
    THEN
        Fnd_Message.SET_NAME('AHL','AHL_COM_RECORD_CHANGED');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
    END IF;
   --
   IF p_space_rec.space_name <> l_space_rec.space_name THEN
       OPEN check_dup_name(p_space_rec.space_name,l_space_rec.bom_department_id);
       FETCH check_dup_name INTO l_dummy;
       CLOSE check_dup_name;
   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'DUMMY'||l_dummy);
   END IF;
       IF l_dummy IS NOT NULL THEN
        Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NAME_EXISTS');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
        END IF;
   END IF;

   -- BOM_DEPARTMENT ID
   IF (
       p_space_rec.department_id <> FND_API.g_miss_num) THEN
       x_space_rec.department_id := p_space_rec.department_id;
       ELSE
       x_space_rec.department_id := l_space_rec.bom_department_id;
   END IF;
   -- ORGANIZATION_ID
   IF (p_space_rec.organization_id <> FND_API.g_miss_num) THEN
      x_space_rec.organization_id := p_space_rec.organization_id;
      ELSE
      x_space_rec.organization_id := l_space_rec.organization_id;
   END IF;
   -- SPACE_NAME
   IF p_space_rec.space_name IS NULL
    THEN
      x_space_rec.space_name := l_space_rec.space_name;
      ELSE
      x_space_rec.space_name := p_space_rec.space_name;
   END IF;
   -- SPACE_CATEGORY
   IF (p_space_rec.space_category_code <> FND_API.g_miss_char) THEN
       x_space_rec.space_category_code := p_space_rec.space_category_code;
       ELSE
       x_space_rec.space_category_code := l_space_rec.space_category;
   END IF;
   -- INACTIVE_FLAG
   IF (
       p_space_rec.inactive_flag_code <> FND_API.g_miss_char) THEN
       x_space_rec.inactive_flag_code := p_space_rec.inactive_flag_code;
       ELSE
       x_space_rec.inactive_flag_code := l_space_rec.inactive_flag;
   END IF;
   -- ATTRIBUTE CATEGORY
   IF p_space_rec.attribute_category <> FND_API.g_miss_char THEN
      x_space_rec.attribute_category := p_space_rec.attribute_category;
      ELSE
      x_space_rec.attribute_category := l_space_rec.attribute_category;
   END IF;
   -- ATTRIBUTE 1
   IF p_space_rec.attribute1 <> FND_API.g_miss_char THEN
      x_space_rec.attribute1 := l_space_rec.attribute1;
      ELSE
      x_space_rec.attribute1 := p_space_rec.attribute1;
   END IF;
   -- ATTRIBUTE 2
   IF p_space_rec.attribute2 <> FND_API.g_miss_char THEN
      x_space_rec.attribute2 := l_space_rec.attribute2;
      ELSE
      x_space_rec.attribute2 := p_space_rec.attribute2;
   END IF;
   -- ATTRIBUTE 3
   IF p_space_rec.attribute3 <> FND_API.g_miss_char THEN
      x_space_rec.attribute3 := l_space_rec.attribute3;
      ELSE
      x_space_rec.attribute3 := p_space_rec.attribute3;
   END IF;
   -- ATTRIBUTE 4
   IF p_space_rec.attribute4 <> FND_API.g_miss_char THEN
      x_space_rec.attribute4 := l_space_rec.attribute4;
      ELSE
      x_space_rec.attribute4 := p_space_rec.attribute4;
   END IF;
   -- ATTRIBUTE 5
   IF p_space_rec.attribute5 <> FND_API.g_miss_char THEN
      x_space_rec.attribute5 := l_space_rec.attribute5;
      ELSE
      x_space_rec.attribute5 := p_space_rec.attribute5;
   END IF;
   -- ATTRIBUTE 6
   IF p_space_rec.attribute6 <> FND_API.g_miss_char THEN
      x_space_rec.attribute6 := l_space_rec.attribute6;
      ELSE
      x_space_rec.attribute6 := p_space_rec.attribute6;
   END IF;
   -- ATTRIBUTE 7
   IF p_space_rec.attribute7 <> FND_API.g_miss_char THEN
      x_space_rec.attribute7 := l_space_rec.attribute7;
      ELSE
      x_space_rec.attribute7 := p_space_rec.attribute7;
   END IF;
   -- ATTRIBUTE 8
   IF p_space_rec.attribute8 <> FND_API.g_miss_char THEN
      x_space_rec.attribute8 := l_space_rec.attribute8;
      ELSE
      x_space_rec.attribute8 := p_space_rec.attribute8;
   END IF;
   -- ATTRIBUTE 9
   IF p_space_rec.attribute9 <> FND_API.g_miss_char THEN
      x_space_rec.attribute9 := l_space_rec.attribute9;
      ELSE
      x_space_rec.attribute9 := p_space_rec.attribute9;
   END IF;
   -- ATTRIBUTE 10
   IF p_space_rec.attribute10 <> FND_API.g_miss_char THEN
      x_space_rec.attribute10 := l_space_rec.attribute10;
      ELSE
      x_space_rec.attribute10 := p_space_rec.attribute10;
   END IF;
   -- ATTRIBUTE 11
   IF p_space_rec.attribute11 <> FND_API.g_miss_char THEN
      x_space_rec.attribute11 := l_space_rec.attribute11;
      ELSE
      x_space_rec.attribute11 := p_space_rec.attribute11;
   END IF;
   -- ATTRIBUTE 12
   IF p_space_rec.attribute12 <> FND_API.g_miss_char THEN
      x_space_rec.attribute12 := l_space_rec.attribute12;
      ELSE
      x_space_rec.attribute12 := p_space_rec.attribute12;
   END IF;
   -- ATTRIBUTE 13
   IF p_space_rec.attribute13 <> FND_API.g_miss_char THEN
      x_space_rec.attribute13 := l_space_rec.attribute13;
      ELSE
      x_space_rec.attribute13 := p_space_rec.attribute13;
    END IF;
   -- ATTRIBUTE 14
   IF p_space_rec.attribute14 <> FND_API.g_miss_char THEN
      x_space_rec.attribute14 := l_space_rec.attribute14;
      ELSE
      x_space_rec.attribute14 := p_space_rec.attribute14;
   END IF;
   -- ATTRIBUTE 15
   IF p_space_rec.attribute15 <> FND_API.g_miss_char THEN
      x_space_rec.attribute15 := l_space_rec.attribute15;
      ELSE
      x_space_rec.attribute15 := p_space_rec.attribute15;
   END IF;


END Complete_Space_Rec;

------------------------------------------------------------------------------
--
-- NAME
--   Validate_Space_Items
--
-- PURPOSE
--   This procedure is to validate Space attributes
-- End of Comments
-------------------------------------------------------------------------------
PROCEDURE Validate_Space_Items
( p_space_rec	                IN	space_rec,
  p_validation_mode		IN	VARCHAR2 := Jtf_Plsql_Api.g_create,
  x_return_status		OUT NOCOPY	VARCHAR2
) IS
--
CURSOR space_name_cur (c_space_name IN VARCHAR2,
                       c_dept_id   IN NUMBER)
IS
 SELECT space_name
   FROM AHL_SPACES_VL
  WHERE space_name = c_space_name
   AND  bom_department_id = c_dept_id;
 --
  l_table_name	VARCHAR2(30);
  l_pk_name	VARCHAR2(30);
  l_pk_value	VARCHAR2(30);
  l_where_clause VARCHAR2(2000);
  l_space_name  VARCHAR2(30);
  l_space_id     NUMBER;
BEGIN
        --  Initialize API/Procedure return status to success
	x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
 -- Check required parameters
     IF  (p_space_rec.ORGANIZATION_ID IS NULL OR
          p_space_rec.ORGANIZATION_ID = Fnd_Api.G_MISS_NUM
         )
         --
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_ORG_REQUIRED');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     -- BOM_DEPARTMENT_ID
     IF (p_space_rec.DEPARTMENT_ID = Fnd_Api.G_MISS_NUM OR
         p_space_rec.DEPARTMENT_ID IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_DEPT_REQUIRED');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     --SPACE CATEGORY
     IF  (p_space_rec.SPACE_CATEGORY_CODE = Fnd_Api.G_MISS_CHAR OR
         p_space_rec.SPACE_CATEGORY_CODE IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_SP_CATEGORY_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;

     --SPACE_NAME
     IF  (p_space_rec.space_name = Fnd_Api.G_MISS_CHAR OR
         p_space_rec.SPACE_NAME IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
  --   Validate uniqueness
   IF p_validation_mode = Jtf_Plsql_Api.g_create
      AND (p_space_rec.space_id  = FND_API.G_MISS_NUM OR
           p_space_rec.space_id IS NULL)
   THEN
      IF Ahl_Utility_Pvt.check_uniqueness(
                'ahl_spaces_vl',
                    'space_name = ' || p_space_rec.space_name
               ) = Fnd_Api.g_false
          THEN
         IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error)
               THEN
            Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_EXISTS');
            Fnd_Msg_Pub.ADD;
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
      END IF;
   END IF;
   --
   IF (p_space_rec.space_id = FND_API.G_MISS_NUM OR
       p_space_rec.space_id IS NULL) THEN
   OPEN space_name_cur(p_space_rec.space_name,p_space_rec.department_id);
   FETCH space_name_cur INTO l_space_name;
   IF l_space_name IS NOT NULL THEN
       Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_EXISTS');
        Fnd_Msg_Pub.ADD;
    END IF;
   CLOSE space_name_cur;
  END IF;

/*
  --
  IF (p_space_rec.space_id <> FND_API.G_MISS_NUM AND
      p_space_rec.space_id IS NOT NULL) THEN
      --
      SELECT space_id INTO l_space_id
        FROM AHL_SPACE_ASSIGNMENTS
      WHERE space_id = p_space_rec.space_id;
      --
    IF l_space_id IS NOT NULL THEN
       Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_ASSIGN_EXISTS');
       Fnd_Msg_Pub.ADD;
     ELSE
        OPEN space_name_cur(p_space_rec.space_name,p_space_rec.department_id);
        FETCH space_name_cur INTO l_space_name;
       IF l_space_name IS NOT NULL THEN
          Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_EXISTS');
           Fnd_Msg_Pub.ADD;
       END IF;
       CLOSE space_name_cur;
     END IF;
      END IF;
  */
 -- END IF;

END Validate_Space_Items;
----------------------------------------------------------------------------
-- NAME
--   Validate_Space_Record
--
-- PURPOSE
--   This procedure is to validate Space Restriction record
--
-- NOTES
-- End of Comments
-----------------------------------------------------------------------------
PROCEDURE Validate_Space_Record(
   p_space_rec  IN	    space_rec,
   x_return_status             OUT NOCOPY  VARCHAR2
) IS
      -- Status Local Variables
     l_return_status	VARCHAR2(1);
  BEGIN
        --  Initialize API return status to success
        x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
	--
	NULL;
        --
END Validate_Space_Record;

--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Space
--
-- PURPOSE
--    Validate  space attributes
--
-- PARAMETERS
--
-- NOTES
--
--------------------------------------------------------------------
PROCEDURE Validate_Space
( p_api_version		  IN    NUMBER,
  p_init_msg_list      	  IN    VARCHAR2 := Fnd_Api.G_FALSE,
  p_validation_level      IN    NUMBER	 := Fnd_Api.G_VALID_LEVEL_FULL,
  p_space_rec             IN    space_rec,
  x_return_status	    OUT NOCOPY VARCHAR2,
  x_msg_count		    OUT NOCOPY NUMBER,
  x_msg_data		    OUT NOCOPY VARCHAR2
)
IS
   l_api_name	    CONSTANT    VARCHAR2(30)  := 'Validate_Space';
   l_api_version    CONSTANT    NUMBER        := 1.0;
   l_full_name      CONSTANT    VARCHAR2(60)  := G_PKG_NAME || '.' || l_api_name;
   l_return_status		VARCHAR2(1);
   l_space_rec	                space_rec;
  BEGIN
        -- Standard call to check for call compatibility.
        IF NOT Fnd_Api.Compatible_API_Call ( l_api_version,
                                           p_api_version,
                                           l_api_name,
                                           G_PKG_NAME)
        THEN
        	RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
        END IF;
        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF Fnd_Api.to_Boolean( p_init_msg_list ) THEN
        	Fnd_Msg_Pub.initialize;
        END IF;
        --  Initialize API return status to success
        x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
        --
        -- API body
        --
	IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item
	THEN
		Validate_Space_Items
		( p_space_rec	                => p_space_rec,
		  p_validation_mode 	        => Jtf_Plsql_Api.g_create,
		  x_return_status		=> l_return_status
		);
		-- If any errors happen abort API.
		IF l_return_status = Fnd_Api.G_RET_STS_UNEXP_ERROR
		THEN
		   RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
		ELSIF l_return_status = Fnd_Api.G_RET_STS_ERROR
		THEN
		    RAISE Fnd_Api.G_EXC_ERROR;
		END IF;
	END IF;
	-- Perform cross attribute validation and missing attribute checks. Record
	-- level validation.
	IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_record
	THEN
		Validate_Space_Record(
		  p_space_rec	                => p_space_rec,
		  x_return_status     		=> l_return_status

		);
		IF l_return_status = Fnd_Api.G_RET_STS_ERROR
		THEN
	            RAISE Fnd_Api.G_EXC_ERROR;
		ELSIF l_return_status = Fnd_Api.G_RET_STS_UNEXP_ERROR
		THEN
		    RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
		END IF;
	END IF;
        --
        -- END of API body.
        --
   -------------------- finish --------------------------
   Fnd_Msg_Pub.count_and_get(
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data);
  EXCEPTION
        WHEN Fnd_Api.G_EXC_ERROR THEN
       	x_return_status := Fnd_Api.G_RET_STS_ERROR ;
        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
		  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
        WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
       	x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR ;
        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
		  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
        WHEN OTHERS THEN
       	x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR ;
        IF Fnd_Msg_Pub.Check_Msg_Level ( Fnd_Msg_Pub.G_MSG_LVL_UNEXP_ERROR )
        	THEN
              		Fnd_Msg_Pub.Add_Exc_Msg( G_PKG_NAME,l_api_name);
	        END IF;
	        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
                  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
END Validate_Space;

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space
--
-- PURPOSE
--    Create Space Record
--
-- PARAMETERS
--    p_x_space_rec: the record representing AHL_SPACES_VL view..
--
-- NOTES
--------------------------------------------------------------------

PROCEDURE Create_Space (
   p_api_version             IN     NUMBER,
   p_init_msg_list           IN     VARCHAR2  := FND_API.g_false,
   p_commit                  IN     VARCHAR2  := FND_API.g_false,
   p_validation_level        IN     NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_x_space_rec             IN  OUT NOCOPY ahl_appr_space_capb_pub.Space_Rec,
   x_return_status              OUT NOCOPY VARCHAR2,
   x_msg_count                  OUT NOCOPY NUMBER,
   x_msg_data                   OUT NOCOPY VARCHAR2
 )
IS
 l_api_name        CONSTANT VARCHAR2(30) := 'CREATE_SPACE';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_department_id            NUMBER;
 l_space_id                 NUMBER;
 l_space_unavaialability_id NUMBER;
 l_space_rec    Space_Rec;
 --
 CURSOR c_seq
  IS
  SELECT AHL_SPACES_B_S.NEXTVAL
    FROM   dual;
 --
   CURSOR c_id_exists (x_id IN NUMBER) IS
     SELECT 1
       FROM   dual
      WHERE EXISTS (SELECT 1
                      FROM   ahl_spaces_b
                     WHERE  space_id = x_id);
 --
BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT create_space;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Create Space ','+SPCBL+');
   END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   --------------------Value OR ID conversion---------------------------
   --Start API Body
   IF p_module_type = 'JSP'
   THEN
      p_x_space_rec.organization_id := null;
      p_x_space_rec.department_id   := null;
     END IF;

      -- Convert org name to organization id
      IF (p_x_space_rec.org_name IS NOT NULL AND
          p_x_space_rec.org_name <> FND_API.G_MISS_CHAR )   OR
         (p_x_space_rec.organization_id IS NOT NULL AND
          p_x_space_rec.organization_id <> FND_API.G_MISS_NUM) THEN

          Check_org_name_Or_Id
               (p_organization_id  => p_x_space_rec.organization_id,
                p_org_name         => p_x_space_rec.org_name,
                x_organization_id  => l_organization_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ORG_ID_NOT_EXISTS');
              Fnd_Msg_Pub.ADD;
          END IF;
        ELSE
             Fnd_Message.SET_NAME('AHL','AHL_APPR_ORG_REQUIRED');
             Fnd_Msg_Pub.ADD;
     END IF;

     --Assign the returned value
     p_x_space_rec.organization_id := l_organization_id;

      -- Get dept code using dept description
      IF (p_x_space_rec.dept_description IS NOT NULL AND
          p_x_space_rec.dept_description <> FND_API.G_MISS_CHAR ) OR
         (p_x_space_rec.department_id IS NOT NULL AND
          p_x_space_rec.department_id <> FND_API.G_MISS_NUM) THEN

          Check_dept_desc_Or_Id
               (p_organization_id  => p_x_space_rec.organization_id,
                p_org_name         => p_x_space_rec.org_name,
                p_dept_description => p_x_space_rec.dept_description,
                p_department_id    => p_x_space_rec.department_id,
                x_department_id    => l_department_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_DEPT_ID_NOT_EXIST');
              Fnd_Msg_Pub.ADD;
          END IF;
       ELSE
             Fnd_Message.SET_NAME('AHL','AHL_APPR_DEPT_REQUIRED');
             Fnd_Msg_Pub.ADD;
     END IF;


     --Assign the returned value
     p_x_space_rec.department_id := l_department_id;

         --For Space Category
         IF p_x_space_rec.space_category_mean IS NOT NULL AND
            p_x_space_rec.space_category_mean <> Fnd_Api.G_MISS_CHAR
         THEN
             Check_lookup_name_Or_Id (
                  p_lookup_type  => 'AHL_SPACE_CATEGORY',
                  p_lookup_code  => NULL,
                  p_meaning      => p_x_space_rec.space_category_mean,
                  p_check_id_flag => 'Y',
                  x_lookup_code   => l_space_rec.space_category_code,
                  x_return_status => l_return_status);

         IF NVL(l_return_status, 'X') <> 'S'
         THEN
            Fnd_Message.SET_NAME('AHL','AHL_APPR_SP_CATEGORY_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
         END IF;
        END IF;
        -- Id presents
         IF p_x_space_rec.space_category_code IS NOT NULL AND
            p_x_space_rec.space_category_code <> Fnd_Api.G_MISS_CHAR
         THEN
           l_space_rec.space_category_code := p_x_space_rec.space_category_code;
        ELSE
            Fnd_Message.SET_NAME('AHL','AHL_APPR_SP_CATEGORY_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
        END IF;
        --
     --SPACE_NAME
     IF  (p_x_space_rec.space_name = Fnd_Api.G_MISS_CHAR OR
         p_x_space_rec.SPACE_NAME IS NULL)
     THEN
         -- missing required fields
         Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_NOT_EXIST');
         Fnd_Msg_Pub.ADD;
     END IF;

  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

  --------------------------------Validation ---------------------------
  --Assign to local variable
   Assign_Space_Rec (
   p_space_rec  => p_x_space_rec,
   x_space_rec  => l_Space_rec);

     -- Call Validate space rec input attributes

    Validate_Space
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_rec             => l_space_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );

   IF (p_x_space_rec.space_id = Fnd_Api.G_MISS_NUM OR
      p_x_space_rec.space_id IS NULL )
   THEN
         --
         -- If the ID is not passed into the API, then
         -- grab a value from the sequence.
         OPEN c_seq;
         FETCH c_seq INTO l_space_id;
         CLOSE c_seq;
         --

         -- Check to be sure that the sequence does not exist.
         OPEN c_id_exists (l_space_id);
         FETCH c_id_exists INTO l_dummy;
         CLOSE c_id_exists;
         --
         -- If the value for the ID already exists, then
         -- l_dummy would be populated with '1', otherwise,
         -- it receives NULL.
         IF l_dummy IS NOT NULL  THEN
             Fnd_Message.SET_NAME('AHL','AHL_APPR_SEQUENCE_NOT_EXISTS');
             Fnd_Msg_Pub.ADD;
          END IF;
         -- For optional fields
         IF  p_x_space_rec.description = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.description := NULL;
         ELSE
            l_space_rec.description := p_x_space_rec.description;
         END IF;
         --
         IF  p_x_space_rec.attribute_category = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute_category := NULL;
         ELSE
            l_space_rec.attribute_category := p_x_space_rec.attribute_category;
         END IF;
         --
         IF  p_x_space_rec.attribute1 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute1 := NULL;
         ELSE
            l_space_rec.attribute1 := p_x_space_rec.attribute1;
         END IF;
         --
         IF  p_x_space_rec.attribute2 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute2 := NULL;
         ELSE
            l_space_rec.attribute2 := p_x_space_rec.attribute2;
         END IF;
         --
         IF  p_x_space_rec.attribute3 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute3 := NULL;
         ELSE
            l_space_rec.attribute3 := p_x_space_rec.attribute3;
         END IF;
         --
         IF  p_x_space_rec.attribute4 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute4 := NULL;
         ELSE
            l_space_rec.attribute4 := p_x_space_rec.attribute4;
         END IF;
         --
         IF  p_x_space_rec.attribute5 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute5 := NULL;
         ELSE
            l_space_rec.attribute5 := p_x_space_rec.attribute5;
         END IF;
         --
         IF  p_x_space_rec.attribute6 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute6 := NULL;
         ELSE
            l_space_rec.attribute6 := p_x_space_rec.attribute6;
         END IF;
         --
         IF  p_x_space_rec.attribute7 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute7 := NULL;
         ELSE
            l_space_rec.attribute7 := p_x_space_rec.attribute7;
         END IF;
         --
         IF  p_x_space_rec.attribute8 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute8 := NULL;
         ELSE
            l_space_rec.attribute8 := p_x_space_rec.attribute8;
         END IF;
         --
         IF  p_x_space_rec.attribute9 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute9 := NULL;
         ELSE
            l_space_rec.attribute9 := p_x_space_rec.attribute9;
         END IF;
         --
         IF  p_x_space_rec.attribute10 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute10 := NULL;
         ELSE
            l_space_rec.attribute10 := p_x_space_rec.attribute10;
         END IF;
         --
         IF  p_x_space_rec.attribute11 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute11 := NULL;
         ELSE
            l_space_rec.attribute11 := p_x_space_rec.attribute11;
         END IF;
         --
         IF  p_x_space_rec.attribute12 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute12 := NULL;
         ELSE
            l_space_rec.attribute12 := p_x_space_rec.attribute12;
         END IF;
         --
         IF  p_x_space_rec.attribute13 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute13 := NULL;
         ELSE
            l_space_rec.attribute13 := p_x_space_rec.attribute13;
         END IF;
         --
         IF  p_x_space_rec.attribute14 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute14 := NULL;
         ELSE
            l_space_rec.attribute14 := p_x_space_rec.attribute14;
         END IF;
         --
         IF  p_x_space_rec.attribute15 = FND_API.G_MISS_CHAR
         THEN
            l_space_rec.attribute15 := NULL;
         ELSE
            l_space_rec.attribute15 := p_x_space_rec.attribute15;
         END IF;
   END IF;

  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   ----------------------------DML Operation---------------------------------
   --Call table handler generated package to insert a record
   AHL_SPACES_PKG.INSERT_ROW (
         X_ROWID                   => l_rowid,
         X_SPACE_ID                => l_space_id,
         X_BOM_DEPARTMENT_ID       => l_space_rec.department_id,
         X_ORGANIZATION_ID         => l_space_rec.organization_id,
         X_INACTIVE_FLAG           => 'Y',
         X_SPACE_CATEGORY          => p_x_space_rec.space_category_code,
         X_SPACE_NAME              => p_x_space_rec.space_name,
         X_OBJECT_VERSION_NUMBER   => 1,
         X_ATTRIBUTE_CATEGORY      => l_space_rec.attribute_category,
         X_ATTRIBUTE1              => l_space_rec.attribute1,
         X_ATTRIBUTE2              => l_space_rec.attribute2,
         X_ATTRIBUTE3              => l_space_rec.attribute3,
         X_ATTRIBUTE4              => l_space_rec.attribute4,
         X_ATTRIBUTE5              => l_space_rec.attribute5,
         X_ATTRIBUTE6              => l_space_rec.attribute6,
         X_ATTRIBUTE7              => l_space_rec.attribute7,
         X_ATTRIBUTE8              => l_space_rec.attribute8,
         X_ATTRIBUTE9              => l_space_rec.attribute9,
         X_ATTRIBUTE10             => l_space_rec.attribute10,
         X_ATTRIBUTE11             => l_space_rec.attribute11,
         X_ATTRIBUTE12             => l_space_rec.attribute12,
         X_ATTRIBUTE13             => l_space_rec.attribute13,
         X_ATTRIBUTE14             => l_space_rec.attribute14,
         X_ATTRIBUTE15             => l_space_rec.attribute15,
         X_CREATION_DATE           => SYSDATE,
         X_CREATED_BY              => Fnd_Global.USER_ID,
         X_LAST_UPDATE_DATE        => SYSDATE,
         X_LAST_UPDATED_BY         => Fnd_Global.USER_ID,
         X_LAST_UPDATE_LOGIN       => Fnd_Global.LOGIN_ID);

          p_x_space_rec.space_id := l_space_id;
---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Create Space ','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;
  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO create_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
      AHL_DEBUG_PUB.log_app_messages (
            x_msg_count, x_msg_data, 'ERROR' );
      AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
      AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO create_space;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
             x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
    END IF;
WHEN OTHERS THEN
    ROLLBACK TO create_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'CREATE_SPACE',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
             x_msg_count, x_msg_data, 'SQL ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

END Create_Space;

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space
--
-- PURPOSE
--    Update Space Record.
--
-- PARAMETERS
--    p_space_rec: the record representing AHL_SPACES_VL
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_rec               IN    ahl_appr_space_capb_pub.Space_Rec,
   x_return_status             OUT NOCOPY VARCHAR2,
   x_msg_count                 OUT NOCOPY NUMBER,
   x_msg_data                  OUT NOCOPY VARCHAR2
)
IS
CURSOR space_name_cur (c_space_id IN  NUMBER,
                       c_dept_id   IN NUMBER)
IS
 SELECT space_name, space_id
   FROM AHL_SPACES_VL
  WHERE space_id = c_space_id
   AND  bom_department_id = c_dept_id;
--

 l_api_name        CONSTANT VARCHAR2(30) := 'UPDATE_SPACE';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_department_id            NUMBER;
 l_space_id                 NUMBER;
 l_space_rec                Space_Rec;
 l_Aspace_rec               Space_Rec;
 l_space_name               VARCHAR2(30);
 l_dup_space_id      NUMBER;
BEGIN


  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT update_space;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Update Space ','+SPCBL+');
   END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   --------------------Value OR ID conversion---------------------------
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'space id'||p_space_rec.space_id);
   Ahl_Debug_Pub.debug( 'space id'||p_space_rec.space_name);
   END IF;
   --Assign to local variable
   Assign_Space_Rec (
                p_space_rec  => p_space_rec,
                x_space_rec  => l_Space_rec);

   IF p_module_type = 'JSP'
   THEN
      l_space_rec.organization_id := null;
      l_space_rec.department_id   := null;
     END IF;

      -- Convert Space name to space id
      IF (l_space_rec.space_name IS NOT NULL AND
          l_space_rec.space_name <> FND_API.G_MISS_CHAR )   OR
         (l_space_rec.space_id IS NOT NULL AND
          l_space_rec.space_id <> FND_API.G_MISS_NUM) THEN

          Check_space_name_Or_Id
               (p_space_id         => l_space_rec.space_id,
                p_space_name       => l_space_rec.space_name,
                x_space_id         => l_space_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('SPACEID',l_space_rec.space_name);
              Fnd_Msg_Pub.ADD;
          END IF;
       ELSE
           Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_ID_NOT_EXIST');
           Fnd_Msg_Pub.ADD;
           RAISE Fnd_Api.G_EXC_ERROR;
      END IF;

     --Assign the returned value
     l_space_rec.space_id := l_space_id;

   --Check for space name
    IF (l_space_rec.space_name IS NULL OR
	     l_space_rec.space_name = fnd_api.g_miss_char)
    THEN
       Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_NAME_NOT_EXIST');
       Fnd_Msg_Pub.ADD;
       RAISE Fnd_Api.G_EXC_ERROR;
    END IF;

         --For Space Category
         IF l_space_rec.space_category_mean IS NOT NULL AND
            l_space_rec.space_category_mean <> Fnd_Api.G_MISS_CHAR
         THEN
             Check_lookup_name_Or_Id (
                  p_lookup_type  => 'AHL_SPACE_CATEGORY',
                  p_lookup_code  => NULL,
                  p_meaning      => l_space_rec.space_category_mean,
                  p_check_id_flag => 'Y',
                  x_lookup_code   => l_space_rec.space_category_code,
                  x_return_status => l_return_status);

         IF NVL(l_return_status, 'X') <> 'S'
         THEN
            Fnd_Message.SET_NAME('AHL','AHL_APPR_SP_CATEGORY_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
         END IF;
        END IF;
        -- Id presents
         IF l_space_rec.space_category_code IS NOT NULL AND
            l_space_rec.space_category_code <> Fnd_Api.G_MISS_CHAR
         THEN
           l_space_rec.space_category_code := l_space_rec.space_category_code;
        END IF;

         --For Inactive Flag
         IF p_space_rec.inactive_flag_mean IS NOT NULL AND
            p_space_rec.inactive_flag_mean <> Fnd_Api.G_MISS_CHAR
         THEN
             Check_lookup_name_Or_Id (
                  p_lookup_type  => 'AHL_SPACE_STATUS',
                  p_lookup_code  => NULL,
                  p_meaning      => p_space_rec.inactive_flag_mean,
                  p_check_id_flag => 'Y',
                  x_lookup_code   => l_space_rec.inactive_flag_code,
                  x_return_status => l_return_status);

         IF NVL(l_return_status, 'X') <> 'S'
         THEN
            Fnd_Message.SET_NAME('AHL','AHL_APPR_SP_STATUS_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
         END IF;
        END IF;
        -- Id presents
         IF p_space_rec.inactive_flag_code IS NOT NULL AND
            p_space_rec.inactive_flag_code <> Fnd_Api.G_MISS_CHAR
         THEN
           l_space_rec.inactive_flag_code := p_space_rec.inactive_flag_code;
        END IF;

  --------------------------------Validation ---------------------------
   -- get existing values and compare
   Complete_Space_Rec (
      p_space_rec  => l_space_rec,
      x_space_rec   => l_Aspace_rec);

     -- Call Validate space rec attributes
    Validate_Space
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_rec              => l_Aspace_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );

  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;
   --
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'before update space id'||p_space_rec.space_id);
   END IF;
   ----------------------------DML Operation---------------------------------
   --Call table handler generated package to update a record
   AHL_SPACES_PKG.UPDATE_ROW
         (
         X_SPACE_ID                => l_Aspace_rec.space_id,
         X_BOM_DEPARTMENT_ID       => l_Aspace_rec.department_id,
         X_ORGANIZATION_ID         => l_Aspace_rec.organization_id,
         X_SPACE_NAME              => l_Aspace_rec.space_name,
         X_SPACE_CATEGORY          => l_Aspace_rec.space_category_code,
         X_INACTIVE_FLAG           => l_Aspace_rec.inactive_flag_code,
         X_OBJECT_VERSION_NUMBER   => l_Aspace_rec.object_version_number+1,
         X_ATTRIBUTE_CATEGORY      => l_Aspace_rec.attribute_category,
         X_ATTRIBUTE1              => l_Aspace_rec.attribute1,
         X_ATTRIBUTE2              => l_Aspace_rec.attribute2,
         X_ATTRIBUTE3              => l_Aspace_rec.attribute3,
         X_ATTRIBUTE4              => l_Aspace_rec.attribute4,
         X_ATTRIBUTE5              => l_Aspace_rec.attribute5,
         X_ATTRIBUTE6              => l_Aspace_rec.attribute6,
         X_ATTRIBUTE7              => l_Aspace_rec.attribute7,
         X_ATTRIBUTE8              => l_Aspace_rec.attribute8,
         X_ATTRIBUTE9              => l_Aspace_rec.attribute9,
         X_ATTRIBUTE10             => l_Aspace_rec.attribute10,
         X_ATTRIBUTE11             => l_Aspace_rec.attribute11,
         X_ATTRIBUTE12             => l_Aspace_rec.attribute12,
         X_ATTRIBUTE13             => l_Aspace_rec.attribute13,
         X_ATTRIBUTE14             => l_Aspace_rec.attribute14,
         X_ATTRIBUTE15             => l_Aspace_rec.attribute15,
         X_LAST_UPDATE_DATE        => SYSDATE,
         X_LAST_UPDATED_BY         => Fnd_Global.USER_ID,
         X_LAST_UPDATE_LOGIN       => Fnd_Global.LOGIN_ID);


  ---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Update Space ','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;
  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO update_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Update Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO update_space;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Update Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN OTHERS THEN
    ROLLBACK TO update_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'UPDATE_SPACE',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'SQL ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Update Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
END Update_Space;

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space
--
-- PURPOSE
--    Delete  Space Record.
--
-- PARAMETERS
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space (
   p_api_version                IN     NUMBER,
   p_init_msg_list              IN     VARCHAR2  := FND_API.g_false,
   p_commit                     IN     VARCHAR2  := FND_API.g_false,
   p_validation_level           IN     NUMBER    := FND_API.g_valid_level_full,
   p_space_rec                  IN     ahl_appr_space_capb_pub.Space_Rec,
   x_return_status                 OUT NOCOPY VARCHAR2,
   x_msg_count                     OUT NOCOPY NUMBER,
   x_msg_data                      OUT NOCOPY VARCHAR2

)
IS
--
  CURSOR c_space_cur
                 (c_space_id IN NUMBER)
   IS
  SELECT   space_id,object_version_number
    FROM     ahl_spaces_vl
   WHERE    space_id = c_space_id
    FOR UPDATE OF OBJECT_VERSION_NUMBER NOWAIT;
  --
  CURSOR c_space_visit_cur (c_space_id IN NUMBER)
  IS
  SELECT visit_id FROM
     AHL_SPACE_ASSIGNMENTS
   WHERE space_id = c_space_id;
  --
  CURSOR get_status_cur(c_visit_id IN NUMBER)
      IS
    SELECT status_code FROM AHL_VISITS_B
     WHERE visit_id = c_visit_id;

  --
 l_api_name        CONSTANT VARCHAR2(30) := 'DELETE_SPACE';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_space_id                 NUMBER;
 l_object_version_number    NUMBER;
 l_visit_status_code        VARCHAR2(30);
 l_visit_id                 NUMBER;
   --
BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT delete_space;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Delete Space','+SPCBL+');
    END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   -----------------------Start of API Body-----------------------------
   -- Check for Record exists
   OPEN c_space_cur(p_space_rec.space_id);
   FETCH c_space_cur INTO l_space_id,
                          l_object_version_number;
   IF c_space_cur%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
      END IF;
      CLOSE c_space_cur;
      RAISE FND_API.g_exc_error;
   END IF;
   CLOSE c_space_cur;
   --Check for object version number
   IF l_object_version_number <> p_space_rec.object_version_number
   THEN
       FND_MESSAGE.set_name('AHL', 'AHL_COM_RECORD_CHANGED');
       FND_MSG_PUB.add;
      RAISE FND_API.g_exc_error;
   END IF;
   --Ckeck for any visits assigned
   OPEN c_space_visit_cur(l_space_id);
   LOOP
   FETCH c_space_visit_cur INTO l_visit_id;
   EXIT WHEN c_space_visit_cur%NOTFOUND;
   IF l_visit_id IS NOT NULL THEN
         --
         OPEN get_status_cur(l_visit_id);
         FETCH get_status_cur INTO l_visit_status_code;
         CLOSE get_status_cur;
         --
    IF l_visit_status_code <> 'CLOSED' THEN
       FND_MESSAGE.set_name('AHL', 'AHL_APPR_SP_VISITS_ASSIGNED');
       FND_MSG_PUB.add;
      RAISE Fnd_Api.G_EXC_ERROR;
     ELSE
       UPDATE AHL_SPACES_B
         SET INACTIVE_FLAG = 'N'
        WHERE space_id = l_space_id;
      END IF;
   END IF;
   END LOOP;
   CLOSE c_space_visit_cur;
   --
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   -------------------Call Table handler generated procedure------------
IF l_visit_id IS NULL THEN
 AHL_SPACES_PKG.DELETE_ROW (
         X_SPACE_ID => l_space_id
     );
  --
     DELETE FROM AHL_SPACE_CAPABILITIES
      WHERE SPACE_ID = l_space_id;

 END IF;
  ---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Delete Space ','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;
   --
  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO delete_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO delete_space;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space ','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN OTHERS THEN
    ROLLBACK TO delete_space;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'DELETE_SPACE',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'SQL ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
END Delete_Space;

--------------------------------------------------------------------
-- PROCEDURE
--    CHECK_INVENTORY_DESC_OR_ID
--
-- PURPOSE
--    Converts Inventory Item description to ID or Vice Versa
--
-- PARAMETERS
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Check_inventory_desc_Or_Id
    (p_organization_id     IN NUMBER,
     p_org_name            IN VARCHAR2,
     p_inventory_item_id   IN NUMBER,
     p_item_description    IN VARCHAR2,
     x_inventory_item_id   OUT NOCOPY NUMBER,
     x_return_status       OUT NOCOPY VARCHAR2,
     x_error_msg_code      OUT NOCOPY VARCHAR2
     )
   IS
BEGIN

        IF p_inventory_item_id IS NOT NULL
         THEN
          SELECT DISTINCT(inventory_item_id)
             INTO x_inventory_item_id
            FROM MTL_SYSTEM_ITEMS_B_KFV
          WHERE inventory_item_id   = p_inventory_item_id;
          END IF;
       --
       IF p_item_description IS NOT NULL THEN
          SELECT DISTINCT(inventory_item_id)
             INTO x_inventory_item_id
           FROM MTL_SYSTEM_ITEMS_B_KFV
          WHERE concatenated_segments = p_item_description;
      END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
    IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'inside conevrt orgid'||p_organization_id);
       AHL_DEBUG_PUB.debug( 'iten id inside convert'||x_inventory_item_id);
    END IF;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_ITEM_NOT_EXISTS';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_ITEM_NOT_EXISTS';
       WHEN OTHERS THEN
         x_return_status:= Fnd_Api.G_RET_STS_UNEXP_ERROR;
         RAISE;
END Check_inventory_desc_Or_Id;

---------------------------------------------------------------------
-- PROCEDURE
--    Assign_Space_Capbl_Rec
--
---------------------------------------------------------------------
PROCEDURE Assign_Space_Capbl_Rec (
   p_space_capbl_rec      IN  AHL_APPR_SPACE_CAPB_PUB.Space_capbl_rec,
   x_space_capbl_rec        OUT NOCOPY Space_capbl_rec
)
IS

BEGIN
     x_space_capbl_rec.space_capability_id :=  p_space_capbl_rec.space_capability_id;
     x_space_capbl_rec.organization_id     :=  p_space_capbl_rec.organization_id;
     x_space_capbl_rec.org_name            :=  p_space_capbl_rec.org_name;
     x_space_capbl_rec.inventory_item_id   :=  p_space_capbl_rec.inventory_item_id;
     x_space_capbl_rec.item_Description    :=  p_space_capbl_rec.item_description;
     x_space_capbl_rec.space_name          :=  p_space_capbl_rec.space_name;
     x_space_capbl_rec.space_id            :=  p_space_capbl_rec.space_id;
     x_space_capbl_rec.visit_type_code     :=  p_space_capbl_rec.visit_type_code;
     x_space_capbl_rec.visit_type_mean     :=  p_space_capbl_rec.visit_type_mean;
     x_space_capbl_rec.object_version_number :=  p_space_capbl_rec.object_version_number;
     x_space_capbl_rec.attribute_category  :=  p_space_capbl_rec.attribute_category;
     x_space_capbl_rec.attribute1          :=  p_space_capbl_rec.attribute1;
     x_space_capbl_rec.attribute2          :=  p_space_capbl_rec.attribute2;
     x_space_capbl_rec.attribute3          :=  p_space_capbl_rec.attribute3;
     x_space_capbl_rec.attribute4          :=  p_space_capbl_rec.attribute4;
     x_space_capbl_rec.attribute5          :=  p_space_capbl_rec.attribute5;
     x_space_capbl_rec.attribute6          :=  p_space_capbl_rec.attribute6;
     x_space_capbl_rec.attribute7          :=  p_space_capbl_rec.attribute7;
     x_space_capbl_rec.attribute8          :=  p_space_capbl_rec.attribute8;
     x_space_capbl_rec.attribute9          :=  p_space_capbl_rec.attribute9;
     x_space_capbl_rec.attribute10         :=  p_space_capbl_rec.attribute10;
     x_space_capbl_rec.attribute11         :=  p_space_capbl_rec.attribute11;
     x_space_capbl_rec.attribute12         :=  p_space_capbl_rec.attribute12;
     x_space_capbl_rec.attribute13         :=  p_space_capbl_rec.attribute13;
     x_space_capbl_rec.attribute14         :=  p_space_capbl_rec.attribute14;
     x_space_capbl_rec.attribute15         :=  p_space_capbl_rec.attribute15;

END Assign_Space_capbl_Rec;
---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Space_Capbl_Rec
--
---------------------------------------------------------------------
PROCEDURE Complete_Space_Capbl_Rec (
   p_space_capbl_rec      IN  Space_capbl_rec,
   x_space_capbl_rec      OUT NOCOPY Space_capbl_rec
)
IS
  CURSOR c_space_capbl_rec
   IS
   SELECT SPACE_CAPABILITY_ID,
          ORGANIZATION_ID,
          VISIT_TYPE,
          INVENTORY_ITEM_ID,
          SPACE_ID,
          OBJECT_VERSION_NUMBER,
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
          ATTRIBUTE15
     FROM  ahl_space_capabilities
   WHERE   space_capability_id = p_space_capbl_rec.space_capability_id
    FOR UPDATE OF OBJECT_VERSION_NUMBER NOWAIT;
   --
   -- This is the only exception for using %ROWTYPE.
   l_space_capbl_rec    c_space_capbl_rec%ROWTYPE;
BEGIN
   x_space_capbl_rec := p_space_capbl_rec;
   OPEN c_space_capbl_rec;
   FETCH c_space_capbl_rec INTO l_space_capbl_rec;
   IF c_space_capbl_rec%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
        RAISE Fnd_Api.G_EXC_ERROR;
      END IF;
   END IF;
   CLOSE c_space_capbl_rec;



   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'inside complete orgid :'||p_space_capbl_rec.organization_id);
       AHL_DEBUG_PUB.debug( 'inside complete itemid :'||p_space_capbl_rec.inventory_item_id);
       AHL_DEBUG_PUB.debug( 'inside complete visit :'||p_space_capbl_rec.inventory_item_id);
       AHL_DEBUG_PUB.debug( 'inside complete itemid :'||p_space_capbl_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'inside complete spaceid :'||p_space_capbl_rec.space_id);
    END IF;

   --Check for object version number
    IF (l_space_capbl_rec.object_version_number <> p_space_capbl_rec.object_version_number)
    THEN
        Fnd_Message.SET_NAME('AHL','AHL_COM_RECORD_CHANGED');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
    END IF;
   -- SPACE ID
   IF p_space_capbl_rec.space_id <> FND_API.g_miss_num THEN
      x_space_capbl_rec.space_id := p_space_capbl_rec.space_id;
      ELSE
      x_space_capbl_rec.space_id := l_space_capbl_rec.space_id;
   END IF;
   -- ORGANIZATION_ID
   IF p_space_capbl_rec.organization_id <> FND_API.g_miss_num THEN
      x_space_capbl_rec.organization_id := p_space_capbl_rec.organization_id;
      ELSE
      x_space_capbl_rec.organization_id := l_space_capbl_rec.organization_id;
   END IF;
   -- VISIT TYPE
   IF p_space_capbl_rec.visit_type_code <> FND_API.g_miss_char THEN
      x_space_capbl_rec.visit_type_code := p_space_capbl_rec.visit_type_code;
      ELSE
      x_space_capbl_rec.visit_type_code := l_space_capbl_rec.visit_type;
   END IF;
   -- INVENTORY ITEM
   IF p_space_capbl_rec.inventory_item_id <> FND_API.g_miss_num THEN
      x_space_capbl_rec.inventory_item_id := p_space_capbl_rec.inventory_item_id;
      ELSE
      x_space_capbl_rec.inventory_item_id := l_space_capbl_rec.inventory_item_id;
   END IF;
   -- ATTRIBUTE CATEGORY
   IF p_space_capbl_rec.attribute_category = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute_category := l_space_capbl_rec.attribute_category;
   END IF;
   -- ATTRIBUTE 1
   IF p_space_capbl_rec.attribute1 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute1 := l_space_capbl_rec.attribute1;
   END IF;
   -- ATTRIBUTE 2
   IF p_space_capbl_rec.attribute2 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute2 := l_space_capbl_rec.attribute2;
   END IF;
   -- ATTRIBUTE 3
   IF p_space_capbl_rec.attribute3 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute3 := l_space_capbl_rec.attribute3;
   END IF;
   -- ATTRIBUTE 4
   IF p_space_capbl_rec.attribute4 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute4 := l_space_capbl_rec.attribute4;
   END IF;
   -- ATTRIBUTE 5
   IF p_space_capbl_rec.attribute5 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute5 := l_space_capbl_rec.attribute5;
   END IF;
   -- ATTRIBUTE 6
   IF p_space_capbl_rec.attribute6 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute6 := l_space_capbl_rec.attribute6;
   END IF;
   -- ATTRIBUTE 7
   IF p_space_capbl_rec.attribute7 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute7 := l_space_capbl_rec.attribute7;
   END IF;
   -- ATTRIBUTE 8
   IF p_space_capbl_rec.attribute8 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute8 := l_space_capbl_rec.attribute8;
   END IF;
   -- ATTRIBUTE 9
   IF p_space_capbl_rec.attribute9 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute9 := l_space_capbl_rec.attribute9;
   END IF;
   -- ATTRIBUTE 10
   IF p_space_capbl_rec.attribute10 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute10 := l_space_capbl_rec.attribute10;
   END IF;
   -- ATTRIBUTE 11
   IF p_space_capbl_rec.attribute11 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute11 := l_space_capbl_rec.attribute11;
   END IF;
   -- ATTRIBUTE 12
   IF p_space_capbl_rec.attribute12 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute12 := l_space_capbl_rec.attribute12;
   END IF;
   -- ATTRIBUTE 13
   IF p_space_capbl_rec.attribute13 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute13 := l_space_capbl_rec.attribute13;
   END IF;
   -- ATTRIBUTE 14
   IF p_space_capbl_rec.attribute14 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute14 := l_space_capbl_rec.attribute14;
   END IF;
   -- ATTRIBUTE 15
   IF p_space_capbl_rec.attribute15 = FND_API.g_miss_char THEN
      x_space_capbl_rec.attribute15 := l_space_capbl_rec.attribute15;
   END IF;

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'end complete orgid :'||x_space_capbl_rec.organization_id);
       AHL_DEBUG_PUB.debug( 'end complete itemid :'||x_space_capbl_rec.inventory_item_id);
       AHL_DEBUG_PUB.debug( 'end complete visit :'||x_space_capbl_rec.inventory_item_id);
       AHL_DEBUG_PUB.debug( 'end complete itemid :'||x_space_capbl_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'end complete spaceid :'||x_space_capbl_rec.space_id);
    END IF;

END Complete_Space_Capbl_Rec;

------------------------------------------------------------------------------
--
-- NAME
--   Validate_Space_Capbl_Items
--
-- PURPOSE
--   This procedure is to validate Space Capability attributes
-- End of Comments
-------------------------------------------------------------------------------
PROCEDURE Validate_Space_Capbl_Items
( p_space_capbl_rec	        IN	space_capbl_rec,
  p_validation_mode		IN	VARCHAR2 := Jtf_Plsql_Api.g_create,
  x_return_status		OUT NOCOPY	VARCHAR2
) IS
  l_table_name	VARCHAR2(30);
  l_pk_name	VARCHAR2(30);
  l_pk_value	VARCHAR2(30);
  l_where_clause VARCHAR2(2000);
  l_dummy        VARCHAR2(10);


CURSOR check_unique_cur (c_organization_id IN NUMBER,
                         c_visit_type     IN VARCHAR2,
                         c_inventory_item_code IN VARCHAR2,
                         c_space_id    IN NUMBER)
 IS
 SELECT 'X'
   FROM AHL_SPACE_CAPABILITIES
 WHERE ORGANIZATION_ID    = c_organization_id
   AND VISIT_TYPE        = c_visit_type
   AND INVENTORY_ITEM_ID = c_inventory_item_code
   AND SPACE_ID          = c_space_id;


BEGIN
        --  Initialize API/Procedure return status to success
	x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
 -- Check required parameters
     IF  (p_space_capbl_rec.ORGANIZATION_ID IS NULL OR
         p_space_capbl_rec.ORGANIZATION_ID = Fnd_Api.G_MISS_NUM )
         THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_ORG_ID_NOT_EXISTS');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     -- SPACE_ID
     IF (p_space_capbl_rec.SPACE_ID = Fnd_Api.G_MISS_NUM OR
         p_space_capbl_rec.SPACE_ID IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_DEPT_ID_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     --VISIT TYPE
     IF  (p_space_capbl_rec.VISIT_TYPE_CODE = Fnd_Api.G_MISS_CHAR OR
         p_space_capbl_rec.VISIT_TYPE_CODE IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_VISIT_TYPE_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;

     --INVENTORY ITEM
     IF  (p_space_capbl_rec.INVENTORY_ITEM_ID = Fnd_Api.G_MISS_NUM OR
         p_space_capbl_rec.INVENTORY_ITEM_ID IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_INV_ITEM_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;

  --   Validate uniqueness
/*   IF p_validation_mode = Jtf_Plsql_Api.g_create
      AND p_space_capbl_rec.visit_type_code IS NOT NULL
   THEN
      IF Ahl_Utility_Pvt.check_uniqueness(
                'ahl_space_capabilities',
                    'visit_type = ' || p_space_capbl_rec.visit_type_code ||
                    ''' AND inventory_item_id = ''' || p_space_capbl_rec.inventory_item_id
               ) = Fnd_Api.g_false
          THEN
         IF Fnd_Msg_Pub.check_msg_level(Fnd_Msg_Pub.g_msg_lvl_error)
               THEN
            Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_CAPBL_DUPL_ID');
            Fnd_Msg_Pub.ADD;
         END IF;
         x_return_status := Fnd_Api.g_ret_sts_error;
      END IF;
   END IF;   */

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'org id invalidation:'||p_space_capbl_rec.organization_id);
       AHL_DEBUG_PUB.debug( 'item id valid 1:'||p_space_capbl_rec.inventory_item_id);
       AHL_DEBUG_PUB.debug( 'visit type 1:'||p_space_capbl_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'space valid 1:'||p_space_capbl_rec.space_id);
    END IF;

 --Check for Unique Record
    IF p_space_capbl_rec.visit_type_code IS NOT NULL THEN
      IF p_space_capbl_rec.inventory_item_id IS NOT NULL THEN

      OPEN check_unique_cur(p_space_capbl_rec.organization_id,
                            p_space_capbl_rec.visit_type_code,
                            p_space_capbl_rec.inventory_item_id,
                            p_space_capbl_rec.space_id);
      FETCH check_unique_cur INTO l_dummy;
      IF l_dummy is NOT NULL THEN
            Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_CAPBL_DUPL_ID');
            Fnd_Msg_Pub.ADD;
      END IF;
           x_return_status := Fnd_Api.g_ret_sts_error;
      END IF;
    END IF;


END Validate_Space_Capbl_Items;
----------------------------------------------------------------------------
-- NAME
--   Validate_Space_Capbl_Record
--
-- PURPOSE
--   This procedure is to validate Space Restriction record
--
-- NOTES
-- End of Comments
-----------------------------------------------------------------------------
PROCEDURE Validate_Space_Capbl_Record(
   p_space_capbl_rec  IN	    space_capbl_rec,
   x_return_status             OUT NOCOPY  VARCHAR2
) IS
      -- Status Local Variables
     l_return_status	VARCHAR2(1);
  BEGIN
        --  Initialize API return status to success
        x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
	--
	NULL;
        --
END Validate_Space_Capbl_Record;

--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Space_Capblts
--
-- PURPOSE
--    Validate  space capabilities attributes
--
-- PARAMETERS
--
-- NOTES
--
--------------------------------------------------------------------
PROCEDURE Validate_Space_Capblts
( p_api_version		  IN    NUMBER,
  p_init_msg_list      	  IN    VARCHAR2 := Fnd_Api.G_FALSE,
  p_validation_level      IN    NUMBER	 := Fnd_Api.G_VALID_LEVEL_FULL,
  p_space_capblts_rec     IN    space_capbl_rec,
  x_return_status	    OUT NOCOPY VARCHAR2,
  x_msg_count		    OUT NOCOPY NUMBER,
  x_msg_data		    OUT NOCOPY VARCHAR2
)
IS
   l_api_name	    CONSTANT    VARCHAR2(30)  := 'Validate_Space_Capblts';
   l_api_version    CONSTANT    NUMBER        := 1.0;
   l_full_name      CONSTANT    VARCHAR2(60)  := G_PKG_NAME || '.' || l_api_name;
   l_return_status		VARCHAR2(1);
   l_space_capblts_rec	        space_capbl_rec;
  BEGIN
        -- Standard call to check for call compatibility.
        IF NOT Fnd_Api.Compatible_API_Call ( l_api_version,
                                           p_api_version,
                                           l_api_name,
                                           G_PKG_NAME)
        THEN
        	RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
        END IF;
        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF Fnd_Api.to_Boolean( p_init_msg_list ) THEN
        	Fnd_Msg_Pub.initialize;
        END IF;
        --  Initialize API return status to success
        x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
        --
        -- API body
        --
	IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_item
	THEN
		Validate_Space_capbl_Items
		( p_space_capbl_rec	        => p_space_capblts_rec,
		  p_validation_mode 	        => Jtf_Plsql_Api.g_create,
		  x_return_status		=> l_return_status
		);
		-- If any errors happen abort API.
		IF l_return_status = Fnd_Api.G_RET_STS_UNEXP_ERROR
		THEN
		   RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
		ELSIF l_return_status = Fnd_Api.G_RET_STS_ERROR
		THEN
		    RAISE Fnd_Api.G_EXC_ERROR;
	 	END IF;
	END IF;
	-- Perform cross attribute validation and missing attribute checks. Record
	-- level validation.
	IF p_validation_level >= Jtf_Plsql_Api.g_valid_level_record
	THEN
		Validate_Space_Capbl_Record(
		  p_space_capbl_rec	        => p_space_capblts_rec,
		  x_return_status     		=> l_return_status

		);
		IF l_return_status = Fnd_Api.G_RET_STS_ERROR
		THEN
	            RAISE Fnd_Api.G_EXC_ERROR;
		ELSIF l_return_status = Fnd_Api.G_RET_STS_UNEXP_ERROR
		THEN
		    RAISE Fnd_Api.G_EXC_UNEXPECTED_ERROR;
		END IF;
	END IF;
        --
        -- END of API body.
        --
   -------------------- finish --------------------------
   Fnd_Msg_Pub.count_and_get(
         p_encoded => Fnd_Api.g_false,
         p_count   => x_msg_count,
         p_data    => x_msg_data);
  EXCEPTION
        WHEN Fnd_Api.G_EXC_ERROR THEN
       	x_return_status := Fnd_Api.G_RET_STS_ERROR ;
        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
		  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
        WHEN Fnd_Api.G_EXC_UNEXPECTED_ERROR THEN
       	x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR ;
        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
		  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
        WHEN OTHERS THEN
       	x_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR ;
        IF Fnd_Msg_Pub.Check_Msg_Level ( Fnd_Msg_Pub.G_MSG_LVL_UNEXP_ERROR )
        	THEN
              		Fnd_Msg_Pub.Add_Exc_Msg( G_PKG_NAME,l_api_name);
	        END IF;
	        Fnd_Msg_Pub.Count_AND_Get
        	( p_count	=>      x_msg_count,
                  p_data	=>      x_msg_data,
		  p_encoded	=>      Fnd_Api.G_FALSE
	     );
END Validate_Space_Capblts;

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space_Capblts
--
-- PURPOSE
--    Create Space Capabilities Record
--
-- PARAMETERS
--    p_x_space_capblts_rec: the record representing AHL_SPACE_CAPABILITIES table..
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Create_Space_Capblts (
   p_api_version             IN      NUMBER,
   p_init_msg_list           IN      VARCHAR2  := FND_API.g_false,
   p_commit                  IN      VARCHAR2  := FND_API.g_false,
   p_validation_level        IN      NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN      VARCHAR2  := 'JSP',
   p_x_space_capblts_rec     IN  OUT NOCOPY ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status               OUT NOCOPY VARCHAR2,
   x_msg_count                   OUT NOCOPY NUMBER,
   x_msg_data                    OUT NOCOPY VARCHAR2
)
 IS

 l_api_name        CONSTANT VARCHAR2(30) := 'CREATE_SPACE_CAPBLTS';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_inventory_item_id        NUMBER;
 l_space_id                 NUMBER;
 l_space_capability_id      NUMBER;
 l_space_capblts_rec    Space_Capbl_Rec;
 --
 CURSOR c_seq
  IS
  SELECT AHL_SPACE_CAPABILITIES_S.NEXTVAL
    FROM   dual;
 --
   CURSOR c_id_exists (x_id IN NUMBER) IS
     SELECT 1
       FROM   dual
      WHERE EXISTS (SELECT 1
                      FROM   ahl_space_capabilities
                     WHERE  space_capability_id = x_id);
 --Get organization id
CURSOR get_org_cur (c_space_id IN NUMBER)
 IS
 SELECT organization_id
  FROM AHL_SPACES_B
  WHERE SPACE_ID = c_space_id;

 BEGIN

  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT create_space_capblts;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Create Space Capblts ','+SPCBL+');
    END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'org name 1:'||p_x_space_capblts_rec.org_name);
       AHL_DEBUG_PUB.debug( 'item desc 1:'||p_x_space_capblts_rec.item_Description);
       AHL_DEBUG_PUB.debug( 'visit type 1:'||p_x_space_capblts_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'space 1:'||p_x_space_capblts_rec.space_name);
    END IF;

   --------------------Value OR ID conversion---------------------------
   --Start API Body
   IF p_module_type = 'JSP'
   THEN
      p_x_space_capblts_rec.organization_id := null;
      p_x_space_capblts_rec.inventory_item_id   := null;
     END IF;


      -- Convert Space name to space id
      IF (p_x_space_capblts_rec.space_name IS NOT NULL AND
          p_x_space_capblts_rec.space_name <> FND_API.G_MISS_CHAR )   OR
         (p_x_space_capblts_rec.space_id IS NOT NULL AND
          p_x_space_capblts_rec.space_id <> FND_API.G_MISS_NUM) THEN

          Check_space_name_Or_Id
               (p_space_id         => p_x_space_capblts_rec.space_id,
                p_space_name       => p_x_space_capblts_rec.space_name,
                x_space_id         => l_space_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('ORGID',p_x_space_capblts_rec.space_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     p_x_space_capblts_rec.space_id := l_space_id;
/*
      -- Convert org name to organization id
      IF (p_x_space_capblts_rec.org_name IS NOT NULL AND
          p_x_space_capblts_rec.org_name <> FND_API.G_MISS_CHAR )   OR
         (p_x_space_capblts_rec.organization_id IS NOT NULL AND
          p_x_space_capblts_rec.organization_id <> FND_API.G_MISS_NUM) THEN

          Check_org_name_Or_Id
               (p_organization_id  => p_x_space_capblts_rec.organization_id,
                p_org_name         => p_x_space_capblts_rec.org_name,
                x_organization_id  => l_organization_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ORG_NT_EXISTS');
              Fnd_Message.SET_TOKEN('ORGID',p_x_space_capblts_rec.org_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     p_x_space_capblts_rec.organization_id := l_organization_id;
*/

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'org id '||p_x_space_capblts_rec.organization_id);
       AHL_DEBUG_PUB.debug( 'ietm desc '||p_x_space_capblts_rec.item_description);
       AHL_DEBUG_PUB.debug( 'space id '||p_x_space_capblts_rec.space_id);
    END IF;
     --Get organization id
       OPEN get_org_cur(l_space_id);
       FETCH get_org_cur INTO l_organization_id;
       CLOSE get_org_cur;

     --Assign the returned value
     p_x_space_capblts_rec.organization_id := l_organization_id;

      -- Get Inventory item id
      IF (p_x_space_capblts_rec.item_description IS NOT NULL AND
          p_x_space_capblts_rec.item_description <> FND_API.G_MISS_CHAR ) OR
         (p_x_space_capblts_rec.inventory_item_id IS NOT NULL AND
          p_x_space_capblts_rec.inventory_item_id <> FND_API.G_MISS_NUM) THEN

          Check_inventory_desc_Or_Id
               (p_organization_id  => null, --p_x_space_capblts_rec.organization_id,
                p_org_name         => null, --p_x_space_capblts_rec.org_name,
                p_item_description => p_x_space_capblts_rec.item_description,
                p_inventory_item_id    => p_x_space_capblts_rec.inventory_item_id,
                x_inventory_item_id    => l_inventory_item_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ITEM_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('ITEM',p_x_space_capblts_rec.item_description);
              Fnd_Msg_Pub.ADD;
          END IF;
     --Assign the returned value
     p_x_space_capblts_rec.inventory_item_id := l_inventory_item_id;

     END IF;
     --Assign the returned value
--     p_x_space_capblts_rec.inventory_item_id := l_inventory_item_id;

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'item id '||l_inventory_item_id);
       AHL_DEBUG_PUB.debug( 'visit type '||p_x_space_capblts_rec.visit_type_code);
    END IF;

         --For Visit Type
         IF p_x_space_capblts_rec.visit_type_mean IS NOT NULL AND
            p_x_space_capblts_rec.visit_type_mean <> Fnd_Api.G_MISS_CHAR
         THEN
             Check_lookup_name_Or_Id (
                  p_lookup_type  => 'AHL_PLANNING_VISIT_TYPE',
                  p_lookup_code  => NULL,
                  p_meaning      => p_x_space_capblts_rec.visit_type_mean,
                  p_check_id_flag => 'Y',
                  x_lookup_code   => l_space_capblts_rec.visit_type_code,
                  x_return_status => l_return_status);

         IF NVL(l_return_status, 'X') <> 'S'
         THEN
            Fnd_Message.SET_NAME('AHL','AHL_APPR_VISIT_TYPE_NOT_EXISTS');
            Fnd_Message.SET_TOKEN('VISIT',p_x_space_capblts_rec.visit_type_mean);
            Fnd_Msg_Pub.ADD;
         END IF;
--        END IF;
        -- Id presents
         ELSIF p_x_space_capblts_rec.visit_type_code IS NOT NULL AND
            p_x_space_capblts_rec.visit_type_code <> Fnd_Api.G_MISS_CHAR
         THEN
           l_space_capblts_rec.visit_type_code := p_x_space_capblts_rec.visit_type_code;
        ELSE
            Fnd_Message.SET_NAME('AHL','AHL_APPR_VISIT_TYPE_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
        END IF;
--           Assign return value
           p_x_space_capblts_rec.visit_type_code := l_space_capblts_rec.visit_type_code;

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'after space id '||p_x_space_capblts_rec.space_id);
       AHL_DEBUG_PUB.debug( 'after visit type '||l_space_capblts_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'after item id  '||p_x_space_capblts_rec.inventory_item_id);

    END IF;

  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

  --------------------------------Validation ---------------------------
  --Assign to local variable
   Assign_Space_capbl_Rec (
   p_space_capbl_rec  => p_x_space_capblts_rec,
   x_space_capbl_rec  => l_space_capblts_rec
   );

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'after assign space id '||l_space_capblts_rec.space_id);
       AHL_DEBUG_PUB.debug( 'after visit type '||l_space_capblts_rec.visit_type_code);
       AHL_DEBUG_PUB.debug( 'after assign item '||l_space_capblts_rec.inventory_item_id);
    END IF;

     -- Call Validate space rec input attributes

    Validate_Space_Capblts
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_capblts_rec     => l_space_capblts_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );

   IF (p_x_space_capblts_rec.space_capability_id = Fnd_Api.G_MISS_NUM OR
       p_x_space_capblts_rec.space_capability_id IS NULL )
   THEN
         --
         -- If the ID is not passed into the API, then
         -- grab a value from the sequence.
         OPEN c_seq;
         FETCH c_seq INTO l_space_capability_id;
         CLOSE c_seq;
         --
         -- Check to be sure that the sequence does not exist.
         OPEN c_id_exists (l_space_capability_id);
         FETCH c_id_exists INTO l_dummy;
         CLOSE c_id_exists;
         --
         -- If the value for the ID already exists, then
         -- l_dummy would be populated with '1', otherwise,
         -- it receives NULL.
         IF l_dummy IS NOT NULL  THEN
             Fnd_Message.SET_NAME('AHL','AHL_APPR_SEQUENCE_NOT_EXISTS');
             Fnd_Msg_Pub.ADD;
          END IF;
         -- For optional fields
         --
         IF  p_x_space_capblts_rec.attribute_category = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute_category := NULL;
         ELSE
            l_space_capblts_rec.attribute_category := p_x_space_capblts_rec.attribute_category;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute1 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute1 := NULL;
         ELSE
            l_space_capblts_rec.attribute1 := p_x_space_capblts_rec.attribute1;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute2 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute2 := NULL;
         ELSE
            l_space_capblts_rec.attribute2 := p_x_space_capblts_rec.attribute2;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute3 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute3 := NULL;
         ELSE
            l_space_capblts_rec.attribute3 := p_x_space_capblts_rec.attribute3;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute4 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute4 := NULL;
         ELSE
            l_space_capblts_rec.attribute4 := p_x_space_capblts_rec.attribute4;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute5 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute5 := NULL;
         ELSE
            l_space_capblts_rec.attribute5 := p_x_space_capblts_rec.attribute5;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute6 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute6 := NULL;
         ELSE
            l_space_capblts_rec.attribute6 := p_x_space_capblts_rec.attribute6;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute7 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute7 := NULL;
         ELSE
            l_space_capblts_rec.attribute7 := p_x_space_capblts_rec.attribute7;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute8 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute8 := NULL;
         ELSE
            l_space_capblts_rec.attribute8 := p_x_space_capblts_rec.attribute8;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute9 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute9 := NULL;
         ELSE
            l_space_capblts_rec.attribute9 := p_x_space_capblts_rec.attribute9;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute10 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute10 := NULL;
         ELSE
            l_space_capblts_rec.attribute10 := p_x_space_capblts_rec.attribute10;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute11 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute11 := NULL;
         ELSE
            l_space_capblts_rec.attribute11 := p_x_space_capblts_rec.attribute11;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute12 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute12 := NULL;
         ELSE
            l_space_capblts_rec.attribute12 := p_x_space_capblts_rec.attribute12;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute13 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute13 := NULL;
         ELSE
            l_space_capblts_rec.attribute13 := p_x_space_capblts_rec.attribute13;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute14 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute14 := NULL;
         ELSE
            l_space_capblts_rec.attribute14 := p_x_space_capblts_rec.attribute14;
         END IF;
         --
         IF  p_x_space_capblts_rec.attribute15 = FND_API.G_MISS_CHAR
         THEN
            l_space_capblts_rec.attribute15 := NULL;
         ELSE
            l_space_capblts_rec.attribute15 := p_x_space_capblts_rec.attribute15;
         END IF;
   END IF;

  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   ----------------------------DML Operation---------------------------------
   --insert space capabilities record

    INSERT INTO AHL_SPACE_CAPABILITIES
                  (
                 SPACE_CAPABILITY_ID,
                 VISIT_TYPE,
                 INVENTORY_ITEM_ID,
                 ORGANIZATION_ID,
                 SPACE_ID,
                 OBJECT_VERSION_NUMBER,
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
                 LAST_UPDATE_DATE,
                 LAST_UPDATED_BY,
                 CREATION_DATE,
                 CREATED_BY,
                 LAST_UPDATE_LOGIN
                )
         VALUES
               (
                l_space_capability_id,
                l_space_capblts_rec.visit_type_code,
                l_space_capblts_rec.inventory_item_id,
                p_x_space_capblts_rec.organization_id,
                l_space_capblts_rec.space_id,
                1,
                l_space_capblts_rec.attribute_category,
                l_space_capblts_rec.attribute1,
                l_space_capblts_rec.attribute2,
                l_space_capblts_rec.attribute3,
                l_space_capblts_rec.attribute4,
                l_space_capblts_rec.attribute5,
                l_space_capblts_rec.attribute6,
                l_space_capblts_rec.attribute7,
                l_space_capblts_rec.attribute8,
                l_space_capblts_rec.attribute9,
                l_space_capblts_rec.attribute10,
                l_space_capblts_rec.attribute11,
                l_space_capblts_rec.attribute12,
                l_space_capblts_rec.attribute13,
                l_space_capblts_rec.attribute14,
                l_space_capblts_rec.attribute15,
                SYSDATE,
                Fnd_Global.user_id,
                SYSDATE,
                Fnd_Global.user_id,
                Fnd_Global.login_id
              );

          p_x_space_capblts_rec.space_capability_id := l_space_capability_id;
---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Create Space Capblts ','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO create_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);

   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space Capblts','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
    END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO create_space_capblts;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space Capblts','+SPCBL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

WHEN OTHERS THEN
    ROLLBACK TO create_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'CREATE_SPACE_CAPBLTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'SQL ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Create Space Capblts','+SPCBL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

 END Create_Space_Capblts;

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space_Capblts
--
-- PURPOSE
--    Update Space Capblities Record.
--
-- PARAMETERS
--    p_space_capblts_rec: the record representing AHL_SPACE_CAPBLITIES table
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space_Capblts (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_capblts_rec       IN    ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status             OUT NOCOPY VARCHAR2,
   x_msg_count                 OUT NOCOPY NUMBER,
   x_msg_data                  OUT NOCOPY VARCHAR2
)
IS

 l_api_name        CONSTANT VARCHAR2(30) := 'UPDATE_SPACE_CAPBLTS';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_inventory_item_id        NUMBER;
 l_space_id                 NUMBER;
 l_space_capability_id      NUMBER;
 l_space_capblts_rec        Space_Capbl_Rec;

 --Get organization id
CURSOR get_org_cur (c_space_id IN NUMBER)
 IS
 SELECT organization_id
  FROM AHL_SPACES_B
  WHERE SPACE_ID = c_space_id;

BEGIN

  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT update_space_capblts;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Update Space Capblts','+SPCBL+');
    END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   ---------------------art API Body------------------------------------

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'org name 1:'||p_space_capblts_rec.org_name);
       AHL_DEBUG_PUB.debug( 'item desc 1:'||p_space_capblts_rec.item_Description);
       AHL_DEBUG_PUB.debug( 'visit type 1:'||p_space_capblts_rec.visit_type_mean);

    END IF;

   --------------------Value OR ID conversion---------------------------
   --Assign to local variable
   Assign_Space_capbl_Rec (
   p_space_capbl_rec  => p_space_capblts_rec,
   x_space_capbl_rec  => l_space_capblts_rec
   );
   IF p_module_type = 'JSP'
   THEN
      l_space_capblts_rec.organization_id     := null;
      l_space_capblts_rec.inventory_item_id   := null;
      l_space_capblts_rec.space_id            := null;
     END IF;
/*      -- Convert org name to organization id
      IF (p_space_capblts_rec.org_name IS NOT NULL AND
          p_space_capblts_rec.org_name <> FND_API.G_MISS_CHAR )   OR
         (l_space_capblts_rec.organization_id IS NOT NULL AND
          l_space_capblts_rec.organization_id <> FND_API.G_MISS_NUM) THEN

          Check_org_name_Or_Id
               (p_organization_id  => l_space_capblts_rec.organization_id,
                p_org_name         => p_space_capblts_rec.org_name,
                x_organization_id  => l_organization_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ORG_NT_EXISTS');
              Fnd_Message.SET_TOKEN('ORGID',p_space_capblts_rec.org_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     l_space_capblts_rec.organization_id := l_organization_id;
*/

      -- Convert Space name to space id
      IF (p_space_capblts_rec.space_name IS NOT NULL AND
          p_space_capblts_rec.space_name <> FND_API.G_MISS_CHAR )   OR
         (p_space_capblts_rec.space_id IS NOT NULL AND
          p_space_capblts_rec.space_id <> FND_API.G_MISS_NUM) THEN

          Check_space_name_Or_Id
               (p_space_id         => p_space_capblts_rec.space_id,
                p_space_name       => p_space_capblts_rec.space_name,
                x_space_id         => l_space_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('SPACEID',p_space_capblts_rec.space_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     l_space_capblts_rec.space_id := l_space_id;

     --Get organization id
       OPEN get_org_cur(l_space_id);
       FETCH get_org_cur INTO l_organization_id;
       CLOSE get_org_cur;

     --Assign the returned value
     l_space_capblts_rec.organization_id := l_organization_id;

      -- Get Inventory item id
      IF (p_space_capblts_rec.item_description IS NOT NULL AND
          p_space_capblts_rec.item_description <> FND_API.G_MISS_CHAR ) OR
         (p_space_capblts_rec.inventory_item_id IS NOT NULL AND
          p_space_capblts_rec.inventory_item_id <> FND_API.G_MISS_NUM) THEN

          Check_inventory_desc_Or_Id
               (p_organization_id  => l_organization_id,
                p_org_name         => p_space_capblts_rec.org_name,
                p_item_description => p_space_capblts_rec.item_description,
                p_inventory_item_id    => p_space_capblts_rec.inventory_item_id,
                x_inventory_item_id    => l_inventory_item_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ITEM_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('DEPTID',p_space_capblts_rec.item_description);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     l_space_capblts_rec.inventory_item_id := l_inventory_item_id;

         --For Visit Type
         IF p_space_capblts_rec.visit_type_mean IS NOT NULL AND
            p_space_capblts_rec.visit_type_mean <> Fnd_Api.G_MISS_CHAR
         THEN
             Check_lookup_name_Or_Id (
                  p_lookup_type  => 'AHL_VISIT_TYPE',
                  p_lookup_code  => NULL,
                  p_meaning      => p_space_capblts_rec.visit_type_mean,
                  p_check_id_flag => 'Y',
                  x_lookup_code   => l_space_capblts_rec.visit_type_code,
                  x_return_status => l_return_status);

         IF NVL(l_return_status, 'X') <> 'S'
         THEN
            Fnd_Message.SET_NAME('AHL','AHL_APPR_VISIT_TYPE_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
         END IF;
        END IF;
        -- Id presents
         IF p_space_capblts_rec.visit_type_code IS NOT NULL AND
            p_space_capblts_rec.visit_type_code <> Fnd_Api.G_MISS_CHAR
         THEN
           l_space_capblts_rec.visit_type_code := p_space_capblts_rec.visit_type_code;
        ELSE
            Fnd_Message.SET_NAME('AHL','AHL_APPR_VISIT_TYPE_NOT_EXIST');
            Fnd_Msg_Pub.ADD;
        END IF;


  --------------------------------Validation ---------------------------
   -- get existing values and compare
   Complete_Space_Capbl_Rec (
      p_space_capbl_rec  => l_space_capblts_rec,
      x_space_capbl_rec   => l_space_capblts_rec);
     -- Call Validate space Capability attributes
    Validate_Space_Capblts
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_capblts_rec     => l_space_capblts_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );


   ----------------------------DML Operation---------------------------------
   --Call table handler generated package to update a record

           UPDATE AHL_SPACE_CAPABILITIES
             SET organization_id       = l_space_capblts_rec.organization_id,
                 space_id              = l_space_capblts_rec.space_id,
                 visit_type            = l_space_capblts_rec.visit_type_code,
                 inventory_item_id     = l_space_capblts_rec.inventory_item_id,
                 object_version_number = l_space_capblts_rec.object_version_number+1,
                 attribute_category    = l_space_capblts_rec.attribute_category,
                 attribute1            = l_space_capblts_rec.attribute1,
                 attribute2            = l_space_capblts_rec.attribute2,
                 attribute3            = l_space_capblts_rec.attribute3,
                 attribute4            = l_space_capblts_rec.attribute4,
                 attribute5            = l_space_capblts_rec.attribute5,
                 attribute6            = l_space_capblts_rec.attribute6,
                 attribute7            = l_space_capblts_rec.attribute7,
                 attribute8            = l_space_capblts_rec.attribute8,
                 attribute9            = l_space_capblts_rec.attribute9,
                 attribute10           = l_space_capblts_rec.attribute10,
                 attribute11           = l_space_capblts_rec.attribute11,
                 attribute12           = l_space_capblts_rec.attribute12,
                 attribute13           = l_space_capblts_rec.attribute13,
                 attribute14           = l_space_capblts_rec.attribute14,
                 attribute15           = l_space_capblts_rec.attribute15,
                 last_update_date      = SYSDATE,
                 last_updated_by       = Fnd_Global.user_id,
                 last_update_login     = Fnd_Global.login_id
         WHERE  space_capability_id  = p_space_capblts_rec.space_capability_id;


  ---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Update Space Capblts','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO update_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);

   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Update Space Capblts','+SPCBL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO update_space_capblts;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Update Space Capblts','+SPCBL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

WHEN OTHERS THEN
    ROLLBACK TO update_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'UPDATE_SPACE_CAPBLTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'SQL ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Update Space Capblts','+SPCBL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

END Update_Space_Capblts;

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space_Capblts
--
-- PURPOSE
--    Delete  Space Capabilities Record.
--
-- PARAMETERS
--    p_space_capblts_rec: the record representing AHL_SPACE_CAPABILITIES table
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space_Capblts (
   p_api_version                IN    NUMBER,
   p_init_msg_list              IN    VARCHAR2  := FND_API.g_false,
   p_commit                     IN    VARCHAR2  := FND_API.g_false,
   p_validation_level           IN    NUMBER    := FND_API.g_valid_level_full,
   p_space_capblts_rec         IN    ahl_appr_space_capb_pub.Space_Capbl_Rec,
   x_return_status                OUT NOCOPY VARCHAR2,
   x_msg_count                    OUT NOCOPY NUMBER,
   x_msg_data                     OUT NOCOPY VARCHAR2

)
IS

  CURSOR c_space_capb_cur
                 (c_space_capability_id IN NUMBER)
   IS
  SELECT   space_capability_id,object_version_number,
           visit_type,inventory_item_id
    FROM     ahl_space_capabilities
   WHERE    space_capability_id = c_space_capability_id
    FOR UPDATE OF OBJECT_VERSION_NUMBER NOWAIT;
  -- Get space assignment
  CURSOR space_assign_cur (c_space_id IN NUMBER)
    IS
      SELECT visit_id
      FROM  ahl_space_assignments
       WHERE space_id = c_space_id;
--
 CURSOR check_space_capb_cur (c_visit_id IN NUMBER,
                              c_visit_type IN VARCHAR2,
                              c_inventory_item_id IN NUMBER)
   IS
   SELECT 1 FROM ahl_visits_b
   WHERE visit_id = c_visit_id
     AND visit_type_code = c_visit_type
     AND inventory_item_id = c_inventory_item_id;
--
 l_api_name        CONSTANT VARCHAR2(30) := 'DELETE_SPACE_CAPBLTS';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_space_capability_id      NUMBER;
 l_object_version_number    NUMBER;
 l_visit_type               VARCHAR2(30);
 l_visit_id                 NUMBER;
 l_inventory_item_id        NUMBER;
--
BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT delete_space_capblts;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_capb_pvt.Delete Space Capblts','+SPCBL+');
   END IF;
   -- Standard call to check for call compatibility.
   IF FND_API.to_boolean(p_init_msg_list)
   THEN
     FND_MSG_PUB.initialize;
   END IF;
    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                      p_api_version,
                                      l_api_name,G_PKG_NAME)
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;
   -----------------------Start of API Body-----------------------------
   -- Check for Record exists
   OPEN c_space_capb_cur(p_space_capblts_rec.space_capability_id);
   FETCH c_space_capb_cur INTO l_space_capability_id,
                               l_object_version_number,l_visit_type,
                               l_inventory_item_id;
   IF c_space_capb_cur%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
      END IF;
      CLOSE c_space_capb_cur;
      RAISE FND_API.g_exc_error;
   END IF;
   CLOSE c_space_capb_cur;

   --Check for object version number
   IF l_object_version_number <> p_space_capblts_rec.object_version_number
   THEN
       FND_MESSAGE.set_name('AHL', 'AHL_COM_RECORD_CHANGED');
       FND_MSG_PUB.add;
      RAISE FND_API.g_exc_error;
   END IF;
   -- Check for space assignment exists, If so any visit has same capability
   OPEN space_assign_cur(p_space_capblts_rec.space_id);
   LOOP
    FETCH space_assign_cur INTO l_visit_id;
    EXIT WHEN space_assign_cur%NOTFOUND;
      IF l_visit_id IS NOT NULL THEN
         OPEN check_space_capb_cur(l_visit_id,l_visit_type,l_inventory_item_id);
         FETCH check_space_capb_cur INTO l_dummy;
         IF check_space_capb_cur%FOUND THEN
            FND_MESSAGE.set_name('AHL', 'AHL_CAPBL_ASIGN_TO_VIIST');
            FND_MSG_PUB.add;
            CLOSE check_space_capb_cur;
            RAISE FND_API.g_exc_error;
          END IF;
         CLOSE check_space_capb_cur;
      END IF;
      --
    END LOOP;
    CLOSE space_assign_cur;

   --
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'before delete capabilities');
   END IF;
   -------------------Remove the reocrd from space capabilities------------
      DELETE FROM AHL_SPACE_CAPABILITIES
      WHERE SPACE_CAPABILITY_ID = l_space_capability_id;

  ---------------------------End of Body---------------------------------------
  --Standard check to count messages
   l_msg_count := Fnd_Msg_Pub.count_msg;

   IF l_msg_count > 0 THEN
      X_msg_count := l_msg_count;
      X_return_status := Fnd_Api.G_RET_STS_UNEXP_ERROR;
      RAISE Fnd_Api.G_EXC_ERROR;
   END IF;

   --Standard check for commit
   IF Fnd_Api.TO_BOOLEAN(p_commit) THEN
      COMMIT;
   END IF;
   -- Debug info
   IF G_DEBUG='Y' THEN
   Ahl_Debug_Pub.debug( 'End of private api Delete Space Capblts','+SPCBL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO delete_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
         AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'ERROR' );
         AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space Capblts','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO delete_space_capblts;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
             x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space Capblts','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN OTHERS THEN
    ROLLBACK TO delete_space_capblts;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_CAPB_PVT',
                            p_procedure_name  =>  'DELETE_SPACE_CAPBLTS',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'SQL ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_capb_pvt.Delete Space Capblts','+SPCBL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
 END Delete_Space_Capblts;

END AHL_APPR_SPACE_CAPB_PVT;

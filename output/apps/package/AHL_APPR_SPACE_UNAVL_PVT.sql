
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPR_SPACE_UNAVL_PVT" AUTHID CURRENT_USER AS
/* $Header: AHLVSUAS.pls 115.8 2003/11/04 10:43:22 rroy noship $ */

-----------------------------------------------------------
-- PACKAGE
--    AHL_SPACE_UNAVL_PVT
--
-- PURPOSE
--    This package is a Private API for managing Space Unavailable information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_UNAVIALABLE_VL:
--    Create_Space_Restriction (see below for specification)
--    Update_Space_Restriction (see below for specification)
--    Delete_Space_Restriction (see below for specification)
--    Validate_Space_Restriction (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 17-Apr-2002    ssurapan      Created.
-----------------------------------------------------------

-------------------------------------
-----          SPACE UNAVAILABILITY            -----
-------------------------------------
TYPE Space_Restriction_Rec IS RECORD (
   space_unavailability_id      NUMBER,
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
   space_id                     NUMBER,
   space_name                   VARCHAR2(30),
   start_date                   DATE,
   end_date                     DATE,
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

--Declare table type
TYPE space_restriction_tbl IS TABLE OF Space_Restriction_Rec
INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space_Restriction
--
-- PURPOSE
--    Create Space Restriction Record
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACE_UNAVAILABLE_VL view..
--    x_space_unavailability_id: the space_unavailability_id.
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Create_Space_Restriction (
   p_api_version             IN      NUMBER,
   p_init_msg_list           IN      VARCHAR2  := FND_API.g_false,
   p_commit                  IN      VARCHAR2  := FND_API.g_false,
   p_validation_level        IN      NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN      VARCHAR2  := 'JSP',
   p_x_space_restriction_rec IN   OUT NOCOPY ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status               OUT NOCOPY VARCHAR2,
   x_msg_count                   OUT NOCOPY NUMBER,
   x_msg_data                    OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space_Restriction
--
-- PURPOSE
--    Update Space Restriction Record.
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACE_UNAVAILABLE_VL
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space_Restriction (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_restriction_rec   IN  ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status              OUT NOCOPY VARCHAR2,
   x_msg_count                  OUT NOCOPY NUMBER,
   x_msg_data                   OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space_Restriction
--
-- PURPOSE
--    Delete  Space Restriction Record.
--
-- PARAMETERS
--    p_space_unavailability_id: the space unavailability id
--    p_object_version_number: the object_version_number
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space_Restriction (
   p_api_version                IN    NUMBER,
   p_init_msg_list              IN    VARCHAR2  := FND_API.g_false,
   p_commit                     IN    VARCHAR2  := FND_API.g_false,
   p_validation_level           IN    NUMBER    := FND_API.g_valid_level_full,
   p_space_restriction_rec      IN    ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status                OUT NOCOPY VARCHAR2,
   x_msg_count                    OUT NOCOPY NUMBER,
   x_msg_data                     OUT NOCOPY VARCHAR2

);

END AHL_APPR_SPACE_UNAVL_PVT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPR_SPACE_UNAVL_PVT" AS
/* $Header: AHLVSUAB.pls 115.17 2003/11/04 10:43:21 rroy noship $ */
--

G_PKG_NAME  VARCHAR2(30)  := 'AHL_APPR_SPACE_UNAVL_PVT';
G_DEBUG     VARCHAR2(1)   :=  AHL_DEBUG_PUB.is_log_enabled;
--
-----------------------------------------------------------
-- PACKAGE
--    AHL_APPR_SPACE_UNAVL_PVT
--
-- PURPOSE
--    This package is a Private API for managing Space Unavailable information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_UNAVIALABLE_VL:
--    Create_Space_Restriction (see below for specification)
--    Update_Space_Restriction (see below for specification)
--    Delete_Space_Restriction (see below for specification)
--    Validate_Space_Restriction (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 17-Apr-2002    ssurapan      Created.

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
         x_error_msg_code:= 'AHL_APPR_ORG_NT_EXISTS';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_ORG_NT_EXISTS';
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
      IF (p_organization_id IS NOT NULL)
       THEN
         IF (p_dept_description IS NOT NULL)
         THEN

   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'Org id'||p_organization_id);
   END IF;

          SELECT department_id
             INTO x_department_id
            FROM HR_ALL_ORGANIZATION_UNITS HAOU, BOM_DEPARTMENTS BMDP
          WHERE HAOU.organization_id = BMDP.organization_id
            AND BMDP.organization_id = p_organization_id
            AND BMDP.description   = p_dept_description;
          END IF;
      ELSE
          SELECT department_id
             INTO x_department_id
           FROM HR_ALL_ORGANIZATION_UNITS HAOU, BOM_DEPARTMENTS BMDP
          WHERE HAOU.organization_id = BMDP.organization_id
            AND BMDP.organization_id = (SELECT organization_id
                                          FROM HR_ALL_ORGANIZATION_UNITS
                                         WHERE NAME  = p_org_name)
            AND BMDP.description = p_dept_description;
      END IF;
      x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_DPT_NOT_EXISTS';
       WHEN TOO_MANY_ROWS THEN
         x_return_status:= Fnd_Api.G_RET_STS_ERROR;
         x_error_msg_code:= 'AHL_APPR_DPT_NOT_EXISTS';
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
--    Assign_Space_Restic_Rec
--
---------------------------------------------------------------------
PROCEDURE Assign_Space_Restric_Rec (
   p_space_restriction_rec      IN  AHL_APPR_SPACE_UNAVL_PUB.Space_restriction_rec,
   x_space_restriction_rec        OUT NOCOPY Space_restriction_rec
)
IS

BEGIN
     x_space_restriction_rec.space_unavailability_id :=  p_space_restriction_rec.space_unavailability_id;
     x_space_restriction_rec.organization_id         :=  p_space_restriction_rec.organization_id;
     x_space_restriction_rec.org_name                :=  p_space_restriction_rec.org_name;
     x_space_restriction_rec.department_id           :=  p_space_restriction_rec.department_id;
     x_space_restriction_rec.dept_Description        :=  p_space_restriction_rec.dept_description;
     x_space_restriction_rec.space_id                :=  p_space_restriction_rec.space_id;
     x_space_restriction_rec.space_name              :=  p_space_restriction_rec.space_name;
     x_space_restriction_rec.start_date              :=  p_space_restriction_rec.start_date;
     x_space_restriction_rec.end_date                :=  p_space_restriction_rec.end_date;
     x_space_restriction_rec.description             :=  p_space_restriction_rec.description;
     x_space_restriction_rec.object_version_number   :=  p_space_restriction_rec.object_version_number;
     x_space_restriction_rec.attribute_category      :=  p_space_restriction_rec.attribute_category;
     x_space_restriction_rec.attribute1              :=  p_space_restriction_rec.attribute1;
     x_space_restriction_rec.attribute2              :=  p_space_restriction_rec.attribute2;
     x_space_restriction_rec.attribute3              :=  p_space_restriction_rec.attribute3;
     x_space_restriction_rec.attribute4              :=  p_space_restriction_rec.attribute4;
     x_space_restriction_rec.attribute5              :=  p_space_restriction_rec.attribute5;
     x_space_restriction_rec.attribute6              :=  p_space_restriction_rec.attribute6;
     x_space_restriction_rec.attribute7              :=  p_space_restriction_rec.attribute7;
     x_space_restriction_rec.attribute8              :=  p_space_restriction_rec.attribute8;
     x_space_restriction_rec.attribute9              :=  p_space_restriction_rec.attribute9;
     x_space_restriction_rec.attribute10             :=  p_space_restriction_rec.attribute10;
     x_space_restriction_rec.attribute11             :=  p_space_restriction_rec.attribute11;
     x_space_restriction_rec.attribute12             :=  p_space_restriction_rec.attribute12;
     x_space_restriction_rec.attribute13             :=  p_space_restriction_rec.attribute13;
     x_space_restriction_rec.attribute14             :=  p_space_restriction_rec.attribute14;
     x_space_restriction_rec.attribute15             :=  p_space_restriction_rec.attribute15;

END Assign_Space_Restric_Rec;


---------------------------------------------------------------------
-- PROCEDURE
--    Complete_Space_Restic_Rec
--
---------------------------------------------------------------------
PROCEDURE Complete_Space_Restric_Rec (
   p_space_restriction_rec      IN  Space_restriction_rec,
   x_space_restriction_rec        OUT NOCOPY Space_restriction_rec
)
IS
  CURSOR c_space_restriction_rec
   IS
   SELECT ROW_ID,
          SPACE_ID,
          START_DATE,
          END_DATE,
          DESCRIPTION,
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
     FROM  ahl_space_unavailable_vl
   WHERE   space_unavailability_id = p_space_restriction_rec.space_unavailability_id
    FOR UPDATE OF OBJECT_VERSION_NUMBER NOWAIT;
   --
   -- This is the only exception for using %ROWTYPE.
   l_space_restriction_rec    c_space_restriction_rec%ROWTYPE;
BEGIN
   x_space_restriction_rec := p_space_restriction_rec;
   OPEN c_space_restriction_rec;
   FETCH c_space_restriction_rec INTO l_space_restriction_rec;
   IF c_space_restriction_rec%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
        RAISE Fnd_Api.G_EXC_ERROR;
      END IF;
   END IF;
   CLOSE c_space_restriction_rec;
   --Check for object version number
    IF (l_space_restriction_rec.object_version_number <> p_space_restriction_rec.object_version_number)
    THEN
        Fnd_Message.SET_NAME('AHL','AHL_COM_RECORD_CHANGED');
        Fnd_Msg_Pub.ADD;
        RAISE Fnd_Api.G_EXC_ERROR;
    END IF;
    -- SPACE ID
   IF p_space_restriction_rec.space_id <> FND_API.g_miss_num THEN
      x_space_restriction_rec.space_id := p_space_restriction_rec.space_id;
      ELSE
      x_space_restriction_rec.space_id := l_space_restriction_rec.space_id;
   END IF;
   -- DESCRIPTION
   IF nvl(p_space_restriction_rec.description, 'x') <> FND_API.g_miss_char THEN
      x_space_restriction_rec.description := p_space_restriction_rec.description;
      ELSE
      x_space_restriction_rec.description := l_space_restriction_rec.description;
   END IF;
   -- ATTRIBUTE CATEGORY
   IF nvl(p_space_restriction_rec.attribute_category,'x') <> FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute_category := p_space_restriction_rec.attribute_category;
      ELSE
      x_space_restriction_rec.attribute_category := l_space_restriction_rec.attribute_category;
   END IF;
   -- ATTRIBUTE 1
   IF nvl(p_space_restriction_rec.attribute1,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute1 := p_space_restriction_rec.attribute1;
      ELSE
      x_space_restriction_rec.attribute1 := l_space_restriction_rec.attribute1;
   END IF;
   -- ATTRIBUTE 2
   IF nvl(p_space_restriction_rec.attribute2,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute2 := p_space_restriction_rec.attribute2;
   END IF;
   -- ATTRIBUTE 3
   IF nvl(p_space_restriction_rec.attribute3,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute3 := l_space_restriction_rec.attribute3;
   END IF;
   -- ATTRIBUTE 4
   IF nvl(p_space_restriction_rec.attribute4,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute4 := l_space_restriction_rec.attribute4;
   END IF;
   -- ATTRIBUTE 5
   IF nvl(p_space_restriction_rec.attribute5,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute5 := l_space_restriction_rec.attribute5;
   END IF;
   -- ATTRIBUTE 6
   IF nvl(p_space_restriction_rec.attribute6,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute6 := l_space_restriction_rec.attribute6;
   END IF;
   -- ATTRIBUTE 7
   IF nvl(p_space_restriction_rec.attribute7,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute7 := l_space_restriction_rec.attribute7;
   END IF;
   -- ATTRIBUTE 8
   IF nvl(p_space_restriction_rec.attribute8,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute8 := l_space_restriction_rec.attribute8;
   END IF;
   -- ATTRIBUTE 9
   IF nvl(p_space_restriction_rec.attribute9,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute9 := l_space_restriction_rec.attribute9;
   END IF;
   -- ATTRIBUTE 10
   IF nvl(p_space_restriction_rec.attribute10,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute10 := l_space_restriction_rec.attribute10;
   END IF;
   -- ATTRIBUTE 11
   IF nvl(p_space_restriction_rec.attribute11,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute11 := l_space_restriction_rec.attribute11;
   END IF;
   -- ATTRIBUTE 12
   IF nvl(p_space_restriction_rec.attribute12,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute12 := l_space_restriction_rec.attribute12;
   END IF;
   -- ATTRIBUTE 13
   IF nvl(p_space_restriction_rec.attribute13,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute13 := l_space_restriction_rec.attribute13;
   END IF;
   -- ATTRIBUTE 14
   IF nvl(p_space_restriction_rec.attribute14,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute14 := l_space_restriction_rec.attribute14;
   END IF;
   -- ATTRIBUTE 15
   IF nvl(p_space_restriction_rec.attribute15,'x') = FND_API.g_miss_char THEN
      x_space_restriction_rec.attribute15 := l_space_restriction_rec.attribute15;
   END IF;

END Complete_Space_Restric_Rec;

------------------------------------------------------------------------------
--
-- NAME
--   Validate_Space_Restrict_Items
--
-- PURPOSE
--   This procedure is to validate Space Unavailability attributes
-- End of Comments
-------------------------------------------------------------------------------
PROCEDURE Validate_Space_Restrict_Items
( p_space_restriction_rec	IN	space_restriction_rec,
  p_validation_mode		IN	VARCHAR2 := Jtf_Plsql_Api.g_create,
  x_return_status		OUT NOCOPY	VARCHAR2
) IS
  l_table_name	VARCHAR2(30);
  l_pk_name	VARCHAR2(30);
  l_pk_value	VARCHAR2(30);
  l_where_clause VARCHAR2(2000);


BEGIN
        --  Initialize API/Procedure return status to success
	x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
 -- Check required parameters
     IF  (p_space_restriction_rec.ORGANIZATION_ID IS NULL
         OR
         p_space_restriction_rec.ORGANIZATION_ID = FND_API.G_MISS_NUM)
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
     --
     IF  (p_space_restriction_rec.DEPARTMENT_ID IS NULL
         OR
         p_space_restriction_rec.DEPARTMENT_ID = FND_API.G_MISS_NUM)
         --
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_DEPT_REQUIRED');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     --
     IF  (p_space_restriction_rec.SPACE_ID IS NULL
         OR
         p_space_restriction_rec.SPACE_ID = FND_API.G_MISS_NUM)
         --
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_ID_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     -- START_DATE
     IF (p_space_restriction_rec.START_DATE = Fnd_Api.G_MISS_DATE OR
         p_space_restriction_rec.START_DATE IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_START_DATE_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;
     --END DATE
     IF  (p_space_restriction_rec.END_DATE = Fnd_Api.G_MISS_DATE OR
         p_space_restriction_rec.END_DATE IS NULL)
     THEN
          -- missing required fields
          IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
          THEN
               Fnd_Message.set_name('AHL', 'AHL_APPR_END_DATE_NOT_EXIST');
               Fnd_Msg_Pub.ADD;
          END IF;
          x_return_status := Fnd_Api.G_RET_STS_ERROR;
     END IF;

    -- Check FK parameter: SPACE_ID
    IF p_space_restriction_rec.SPACE_ID <> Fnd_Api.g_miss_num
    THEN
 	l_table_name := 'AHL_SPACES_VL';
	l_pk_name := 'SPACE_ID';
	l_pk_value := p_space_restriction_rec.SPACE_ID;
	IF Ahl_Utility_Pvt.Check_FK_Exists (
	 p_table_name			=> l_table_name,
	 p_pk_name			=> l_pk_name,
	 p_pk_value			=> l_pk_value
		) = Fnd_Api.G_FALSE
	THEN
		IF Fnd_Msg_Pub.check_msg_level (Fnd_Msg_Pub.G_MSG_LVL_ERROR)
		THEN
		Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_SPACE_ID');
		Fnd_Msg_Pub.ADD;
		END IF;
		x_return_status := Fnd_Api.G_RET_STS_ERROR;
		END IF;  -- check_fk_exists
	END IF;

END Validate_Space_Restrict_Items;
----------------------------------------------------------------------------
-- NAME
--   Validate_Space_Restrict_Record
--
-- PURPOSE
--   This procedure is to validate Space Restriction record
--
-- NOTES
-- End of Comments
-----------------------------------------------------------------------------
PROCEDURE Validate_Space_Restrict_Record(
   p_space_restriction_rec  IN	    space_restriction_rec,
   x_return_status             OUT NOCOPY  VARCHAR2
) IS
--
CURSOR space_visit_cur (c_space_id IN NUMBER)
IS
 SELECT a.visit_id,
        space_id,
        trunc(start_date_time) start_date_time
    FROM ahl_space_Assignments a,
         ahl_visits_b b
   WHERE a.visit_id = b.visit_id
    AND a.space_id = c_space_id;
 --
 CURSOR space_restirct_date_cur
               (c_space_unavailability_id IN NUMBER)
  IS
   SELECT start_date, end_date
     FROM ahl_space_unavailable_b
    WHERE space_unavailability_id = c_space_unavailability_id;
 --
      -- Status Local Variables
     l_return_status	VARCHAR2(1);
     l_visit_id         NUMBER;
     l_space_id         NUMBER;
     l_start_date_time  DATE;
     l_start_date       DATE;
     l_end_date         DATE;
  BEGIN
        --  Initialize API return status to success
        x_return_status := Fnd_Api.G_RET_STS_SUCCESS;
	--
  IF (p_space_restriction_rec.space_unavailability_id = fnd_api.g_miss_num
      or
      p_space_restriction_rec.space_unavailability_id IS NULL )THEN
     IF p_space_restriction_rec.START_DATE IS NOT NULL
      THEN
       IF p_space_restriction_rec.START_DATE  < TRUNC(SYSDATE)
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_START_DATE');
	    Fnd_Msg_Pub.ADD;
            x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;

      --
     IF (p_space_restriction_rec.END_DATE IS NOT NULL AND
         p_space_restriction_rec.START_DATE IS NOT NULL)
      THEN
       IF( p_space_restriction_rec.END_DATE  < p_space_restriction_rec.START_DATE )
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INV_START_END_DATE');
	    Fnd_Msg_Pub.ADD;
            x_return_status := Fnd_Api.G_RET_STS_ERROR;
           END IF;
       END IF;

      --
      IF (p_space_restriction_rec.START_DATE IS NULL AND
           p_space_restriction_rec.END_DATE IS NOT NULL) THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_START_DATE');
	    Fnd_Msg_Pub.ADD;
       END IF;
     --
  ELSE
       OPEN space_restirct_date_cur(p_space_restriction_rec.space_unavailability_id);
       FETCH space_restirct_date_cur INTO l_start_date, l_end_date;
       CLOSE space_restirct_date_cur;
    IF (p_space_restriction_rec.START_DATE IS NOT NULL AND
        p_space_restriction_rec.START_DATE <> l_start_date)
      THEN
       IF p_space_restriction_rec.START_DATE  < TRUNC(SYSDATE)
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_START_DATE');
	    Fnd_Msg_Pub.ADD;
          END IF;
       END IF;
     --
     IF ((p_space_restriction_rec.END_DATE IS NOT NULL AND
         p_space_restriction_rec. END_DATE <> l_end_date) AND
         (p_space_restriction_rec.START_DATE IS NOT NULL AND
          p_space_restriction_rec.START_DATE <> l_start_date))
      THEN
       IF( p_space_restriction_rec.END_DATE  < p_space_restriction_rec.START_DATE )
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INV_START_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;
     --
     IF ((p_space_restriction_rec.END_DATE IS NOT NULL AND
         p_space_restriction_rec. END_DATE <> l_end_date) AND
         (p_space_restriction_rec.START_DATE IS NOT NULL AND
          p_space_restriction_rec.START_DATE = l_start_date))
      THEN
       IF( p_space_restriction_rec.END_DATE  < p_space_restriction_rec.START_DATE )
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INV_START_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;
       --
     IF ((p_space_restriction_rec.END_DATE IS NOT NULL AND
         p_space_restriction_rec. END_DATE = l_end_date) AND
         (p_space_restriction_rec.START_DATE IS NOT NULL AND
          p_space_restriction_rec.START_DATE <> l_start_date))
      THEN
       IF( p_space_restriction_rec.END_DATE  < p_space_restriction_rec.START_DATE )
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INV_START_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;
       --

     IF ((p_space_restriction_rec.END_DATE IS NOT NULL AND
         p_space_restriction_rec. END_DATE = l_end_date) AND
         (p_space_restriction_rec.START_DATE IS NOT NULL AND
          p_space_restriction_rec.START_DATE = l_start_date))
      THEN
       IF( p_space_restriction_rec.END_DATE  < p_space_restriction_rec.START_DATE )
       THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INV_START_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;


/*
       --
     IF ((p_space_restriction_rec.START_DATE IS NOT NULL AND
         p_space_restriction_rec.START_DATE <> l_start_date) AND
          (p_space_restriction_rec.END_DATE IS NOT NULL AND
           p_space_restriction_rec.END_DATE <> l_end_date ))
       THEN
         IF p_space_restriction_rec.END_DATE < trunc(sysdate) THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;   */
       --
         IF (p_space_restriction_rec.END_DATE IS NOT NULL AND
             p_space_restriction_rec.END_DATE <> l_end_date )
       THEN
         IF p_space_restriction_rec.END_DATE < trunc(sysdate) THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_INVALID_END_DATE');
	    Fnd_Msg_Pub.ADD;
           x_return_status := Fnd_Api.G_RET_STS_ERROR;
          END IF;
       END IF;

END IF;
   IF G_DEBUG='Y' THEN
      AHL_DEBUG_PUB.debug( 'date 3:'||p_space_restriction_rec.start_date);
   END IF;
       --Check for any visits exist during start and end dates
       OPEN space_visit_cur(p_space_restriction_rec.space_id);
       LOOP
       FETCH space_visit_cur INTO l_visit_id,l_space_id,l_start_date_time;
       EXIT WHEN space_visit_cur%NOTFOUND;
       IF l_visit_id IS NOT NULL THEN
          IF (l_start_date_time >= p_space_restriction_rec.START_DATE
              AND l_start_date_time <= p_space_restriction_rec.END_DATE)
              THEN
	    Fnd_Message.set_name('AHL', 'AHL_APPR_SPACE_VISITS_EXIST');
	    Fnd_Msg_Pub.ADD;
          END IF;
       END IF;
       END LOOP;
       CLOSE space_visit_cur;
       --

--
END Validate_Space_Restrict_Record;
--------------------------------------------------------------------
-- PROCEDURE
--    Validate_Space_Restriction
--
-- PURPOSE
--    Validate  space restriction attributes
--
-- PARAMETERS
--
-- NOTES
--
--------------------------------------------------------------------
PROCEDURE Validate_Space_Restriction
( p_api_version		  IN    NUMBER,
  p_init_msg_list      	  IN    VARCHAR2 := Fnd_Api.G_FALSE,
  p_validation_level      IN    NUMBER	 := Fnd_Api.G_VALID_LEVEL_FULL,
  p_space_restriction_rec IN    space_restriction_rec,
  x_return_status	    OUT NOCOPY VARCHAR2,
  x_msg_count		    OUT NOCOPY NUMBER,
  x_msg_data		    OUT NOCOPY VARCHAR2
)
IS
   l_api_name	    CONSTANT    VARCHAR2(30)  := 'Validate_Space_Restriction';
   l_api_version    CONSTANT    NUMBER        := 1.0;
   l_full_name      CONSTANT    VARCHAR2(70)  := G_PKG_NAME || '.' || l_api_name;
   l_return_status		VARCHAR2(1);
   l_space_restriction_rec	space_restriction_rec;
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
		Validate_Space_Restrict_Items
		( p_space_restriction_rec	=> p_space_restriction_rec,
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
		Validate_Space_Restrict_Record(
		  p_space_restriction_rec	=> p_space_restriction_rec,
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
END Validate_Space_Restriction;

--------------------------------------------------------------------
-- PROCEDURE
--    Create_Space_Restriction
--
-- PURPOSE
--    Create Space Restriction Record
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACE_UNAVAILABLE_VL view..
--    x_space_unavailability_id: the space_unavailability_id.
--
-- NOTES
--------------------------------------------------------------------

PROCEDURE Create_Space_Restriction (
   p_api_version             IN     NUMBER,
   p_init_msg_list           IN     VARCHAR2  := FND_API.g_false,
   p_commit                  IN     VARCHAR2  := FND_API.g_false,
   p_validation_level        IN     NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_x_space_restriction_rec IN OUT NOCOPY ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status              OUT NOCOPY VARCHAR2,
   x_msg_count                  OUT NOCOPY NUMBER,
   x_msg_data                   OUT NOCOPY VARCHAR2
 )
IS
 --
 CURSOR c_seq
  IS
  SELECT AHL_SPACE_UNAVAILABLE_B_S.NEXTVAL
    FROM   dual;
 --
   CURSOR c_id_exists (x_id IN NUMBER) IS
     SELECT 1
       FROM   dual
      WHERE EXISTS (SELECT 1
                      FROM   ahl_space_unavailable_b
                     WHERE  space_unavailability_id = x_id);
 --
 CURSOR check_duplicate_cur (c_space_id IN NUMBER,
                             c_start_date IN DATE,
                             c_end_date IN DATE)
 IS
   SELECT space_id
     FROM AHL_SPACE_UNAVAILABLE_VL
    WHERE space_id = c_space_id
     AND trunc(start_date) = c_start_date
     AND trunc(end_date) = c_end_date;
  --
   l_api_name        CONSTANT VARCHAR2(30) := 'CREATE_SPACE_RESTRICTION';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_dup_id                   NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_department_id            NUMBER;
 l_space_id                 NUMBER;
 l_space_unavaialability_id NUMBER;
 l_start_date  DATE  := trunc(p_x_space_restriction_rec.start_date);
 l_end_date  DATE    := trunc(p_x_space_restriction_rec.end_date);
 l_space_restriction_rec    Space_Restriction_Rec;

BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT create_space_restriction;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_unavl_pvt.Create Space Restriction','+SUAVL+');
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
      p_x_space_restriction_rec.organization_id := null;
      p_x_space_restriction_rec.department_id   := null;
      p_x_space_restriction_rec.space_id        := null;
     END IF;
      -- Convert org name to organization id
      IF (p_x_space_restriction_rec.org_name IS NOT NULL AND
          p_x_space_restriction_rec.org_name <> FND_API.G_MISS_CHAR )   OR
         (p_x_space_restriction_rec.organization_id IS NOT NULL AND
          p_x_space_restriction_rec.organization_id <> FND_API.G_MISS_NUM) THEN

          Check_org_name_Or_Id
               (p_organization_id  => p_x_space_restriction_rec.organization_id,
                p_org_name         => p_x_space_restriction_rec.org_name,
                x_organization_id  => l_organization_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_ORG_NT_EXISTS');
              Fnd_Message.SET_TOKEN('ORGID',p_x_space_restriction_rec.org_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     p_x_space_restriction_rec.organization_id := l_organization_id;

   IF G_DEBUG='Y' THEN
      AHL_DEBUG_PUB.debug( 'Org id'||p_x_space_restriction_rec.organization_id);
   END IF;

      -- Get dept code using dept description
      IF (p_x_space_restriction_rec.dept_description IS NOT NULL AND
          p_x_space_restriction_rec.dept_description <> FND_API.G_MISS_CHAR ) OR
         (p_x_space_restriction_rec.department_id IS NOT NULL AND
          p_x_space_restriction_rec.department_id <> FND_API.G_MISS_NUM) THEN

          Check_dept_desc_Or_Id
               (p_organization_id  => p_x_space_restriction_rec.organization_id,
                p_org_name         => p_x_space_restriction_rec.org_name,
                p_dept_description => p_x_space_restriction_rec.dept_description,
                p_department_id    => p_x_space_restriction_rec.department_id,
                x_department_id    => l_department_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_DPT_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('DEPTID',p_x_space_restriction_rec.dept_description);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     p_x_space_restriction_rec.department_id := l_department_id;

   IF G_DEBUG='Y' THEN
      AHL_DEBUG_PUB.debug( 'Dept id'||p_x_space_restriction_rec.department_id);
   END IF;
      -- Convert Space name to space id
      IF (p_x_space_restriction_rec.space_name IS NOT NULL AND
          p_x_space_restriction_rec.space_name <> FND_API.G_MISS_CHAR )   OR
         (p_x_space_restriction_rec.space_id IS NOT NULL AND
          p_x_space_restriction_rec.space_id <> FND_API.G_MISS_NUM) THEN

          Check_space_name_Or_Id
               (p_space_id         => p_x_space_restriction_rec.space_id,
                p_space_name       => p_x_space_restriction_rec.space_name,
                x_space_id         => l_space_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('SPACEID',p_x_space_restriction_rec.space_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
     --Assign the returned value
     p_x_space_restriction_rec.space_id := l_space_id;

   IF G_DEBUG='Y' THEN
      AHL_DEBUG_PUB.debug( 'Space id'||p_x_space_restriction_rec.space_id);
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
   Assign_Space_Restric_Rec (
   p_space_restriction_rec  => p_x_space_restriction_rec,
   x_space_restriction_rec  => l_Space_restriction_rec);

     -- Call Validate space rec input attributes
    Validate_Space_Restriction
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_restriction_rec => l_Space_restriction_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );

   IF (p_x_space_restriction_rec.space_unavailability_id = Fnd_Api.G_MISS_NUM OR
       p_x_space_restriction_rec.space_unavailability_id IS NULL )
   THEN
         --
         -- If the ID is not passed into the API, then
         -- grab a value from the sequence.
         OPEN c_seq;
         FETCH c_seq INTO l_space_unavaialability_id;
         CLOSE c_seq;
         --
         -- Check to be sure that the sequence does not exist.
         OPEN c_id_exists (l_space_unavaialability_id);
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
         IF  p_x_space_restriction_rec.description = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.description := NULL;
         ELSE
            l_space_restriction_rec.description := p_x_space_restriction_rec.description;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute_category = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute_category := NULL;
         ELSE
            l_space_restriction_rec.attribute_category := p_x_space_restriction_rec.attribute_category;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute1 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute1 := NULL;
         ELSE
            l_space_restriction_rec.attribute1 := p_x_space_restriction_rec.attribute1;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute2 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute2 := NULL;
         ELSE
            l_space_restriction_rec.attribute2 := p_x_space_restriction_rec.attribute2;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute3 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute3 := NULL;
         ELSE
            l_space_restriction_rec.attribute3 := p_x_space_restriction_rec.attribute3;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute4 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute4 := NULL;
         ELSE
            l_space_restriction_rec.attribute4 := p_x_space_restriction_rec.attribute4;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute5 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute5 := NULL;
         ELSE
            l_space_restriction_rec.attribute5 := p_x_space_restriction_rec.attribute5;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute6 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute6 := NULL;
         ELSE
            l_space_restriction_rec.attribute6 := p_x_space_restriction_rec.attribute6;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute7 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute7 := NULL;
         ELSE
            l_space_restriction_rec.attribute7 := p_x_space_restriction_rec.attribute7;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute8 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute8 := NULL;
         ELSE
            l_space_restriction_rec.attribute8 := p_x_space_restriction_rec.attribute8;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute9 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute9 := NULL;
         ELSE
            l_space_restriction_rec.attribute9 := p_x_space_restriction_rec.attribute9;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute10 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute10 := NULL;
         ELSE
            l_space_restriction_rec.attribute10 := p_x_space_restriction_rec.attribute10;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute11 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute11 := NULL;
         ELSE
            l_space_restriction_rec.attribute11 := p_x_space_restriction_rec.attribute11;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute12 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute12 := NULL;
         ELSE
            l_space_restriction_rec.attribute12 := p_x_space_restriction_rec.attribute12;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute13 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute13 := NULL;
         ELSE
            l_space_restriction_rec.attribute13 := p_x_space_restriction_rec.attribute13;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute14 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute14 := NULL;
         ELSE
            l_space_restriction_rec.attribute14 := p_x_space_restriction_rec.attribute14;
         END IF;
         --
         IF  p_x_space_restriction_rec.attribute15 = FND_API.G_MISS_CHAR
         THEN
            l_space_restriction_rec.attribute15 := NULL;
         ELSE
            l_space_restriction_rec.attribute15 := p_x_space_restriction_rec.attribute15;
         END IF;
   END IF;
   --Assign it to local variable
   --
   OPEN check_duplicate_cur(p_x_space_restriction_rec.space_id,
                            l_start_date,
                            l_end_date);
   FETCH check_duplicate_cur INTO l_dup_id;
   CLOSE check_duplicate_cur;
   IF l_dup_id IS NOT NULL
     THEN
         Fnd_Message.SET_NAME('AHL','AHL_APPR_RECORD_EXISTS');
        Fnd_Msg_Pub.ADD;
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
   AHL_SPACE_UNAVAILABLE_PKG.INSERT_ROW (
         X_ROWID                   => l_rowid,
         X_SPACE_UNAVAILABILITY_ID => l_space_unavaialability_id,
         X_SPACE_ID                => p_x_space_restriction_rec.space_id,
         X_START_DATE              => p_x_space_restriction_rec.start_date,
         X_END_DATE                => p_x_space_restriction_rec.end_date,
         X_OBJECT_VERSION_NUMBER   => 1,
         X_ATTRIBUTE_CATEGORY      => l_space_restriction_rec.attribute_category,
         X_ATTRIBUTE1              => l_space_restriction_rec.attribute1,
         X_ATTRIBUTE2              => l_space_restriction_rec.attribute2,
         X_ATTRIBUTE3              => l_space_restriction_rec.attribute3,
         X_ATTRIBUTE4              => l_space_restriction_rec.attribute4,
         X_ATTRIBUTE5              => l_space_restriction_rec.attribute5,
         X_ATTRIBUTE6              => l_space_restriction_rec.attribute6,
         X_ATTRIBUTE7              => l_space_restriction_rec.attribute7,
         X_ATTRIBUTE8              => l_space_restriction_rec.attribute8,
         X_ATTRIBUTE9              => l_space_restriction_rec.attribute9,
         X_ATTRIBUTE10             => l_space_restriction_rec.attribute10,
         X_ATTRIBUTE11             => l_space_restriction_rec.attribute11,
         X_ATTRIBUTE12             => l_space_restriction_rec.attribute12,
         X_ATTRIBUTE13             => l_space_restriction_rec.attribute13,
         X_ATTRIBUTE14             => l_space_restriction_rec.attribute14,
         X_ATTRIBUTE15             => l_space_restriction_rec.attribute15,
         X_DESCRIPTION             => l_space_restriction_rec.description,
         X_CREATION_DATE           => SYSDATE,
         X_CREATED_BY              => Fnd_Global.USER_ID,
         X_LAST_UPDATE_DATE        => SYSDATE,
         X_LAST_UPDATED_BY         => Fnd_Global.USER_ID,
         X_LAST_UPDATE_LOGIN       => Fnd_Global.LOGIN_ID);

  p_x_space_restriction_rec.space_unavailability_id := l_space_unavaialability_id;
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
   Ahl_Debug_Pub.debug( 'End of private api Create Space Restriction','+SUAVL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO create_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Create Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO create_space_restriction;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
             x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Create Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

WHEN OTHERS THEN
    ROLLBACK TO create_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_UNAVL_PVT',
                            p_procedure_name  =>  'CREATE_SPACE_RESTRICTION',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
             x_msg_count, x_msg_data, 'SQL ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Create Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

END Create_Space_Restriction;



--------------------------------------------------------------------
-- PROCEDURE
--    Update_Space_Restriction
--
-- PURPOSE
--    Update Space Restriction Record.
--
-- PARAMETERS
--    p_space_restriction_rec: the record representing AHL_SPACE_UNAVAILABLE_VL
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Update_Space_Restriction (
   p_api_version             IN    NUMBER,
   p_init_msg_list           IN    VARCHAR2  := FND_API.g_false,
   p_commit                  IN    VARCHAR2  := FND_API.g_false,
   p_validation_level        IN    NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_space_restriction_rec   IN    ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status             OUT NOCOPY VARCHAR2,
   x_msg_count                 OUT NOCOPY NUMBER,
   x_msg_data                  OUT NOCOPY VARCHAR2
)
IS
--
 CURSOR check_duplicate_cur (c_space_id IN NUMBER,
                             c_start_date IN DATE,
                             c_end_date IN DATE)
 IS
   SELECT space_id
     FROM AHL_SPACE_UNAVAILABLE_VL
    WHERE space_id = c_space_id
     AND trunc(start_date) = c_start_date
     AND trunc(end_date) = c_end_date;
--
CURSOR get_space_capb_cur (c_space_unavabl_id IN NUMBER)
IS
 SELECT start_date,end_date
   FROM AHL_SPACE_UNAVAILABLE_VL
  WHERE space_unavailability_id = c_space_unavabl_id;
--
CURSOR get_space_detail_cur (c_space_id IN NUMBER)
 IS
  SELECT organization_id,bom_department_id
   FROM ahl_spaces_b
   WHERE space_id = c_space_id;

--
 l_api_name        CONSTANT VARCHAR2(30) := 'UPDATE_SPACE_RESTRICTION';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_description              VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_rowid                    VARCHAR2(30);
 l_organization_id          NUMBER;
 l_department_id            NUMBER;
 l_space_id                 NUMBER;
 l_dup_id                   NUMBER;
 l_start_date               DATE;
 l_end_date                 DATE;
 l_space_unavaialability_id NUMBER;
 l_space_restriction_rec    Space_Restriction_Rec;
 l_Aspace_restriction_rec    Space_Restriction_Rec;

BEGIN


  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT update_space_restriction;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   -- Debug info.
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_unavl_pvt.Update Space Restriction','+SUAVL+');
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
   --Assign to local variable
   Assign_Space_Restric_Rec (
   p_space_restriction_rec  => p_space_restriction_rec,
   x_space_restriction_rec  => l_Space_restriction_rec);
   --Start API Body
   IF p_module_type = 'JSP'
   THEN
      l_space_restriction_rec.organization_id := null;
      l_space_restriction_rec.department_id   := null;
     END IF;
      -- Convert Space name to space id
      IF (p_space_restriction_rec.space_name IS NOT NULL AND
          p_space_restriction_rec.space_name <> FND_API.G_MISS_CHAR )   OR
         (l_space_restriction_rec.space_id IS NOT NULL AND
          l_space_restriction_rec.space_id <> FND_API.G_MISS_NUM) THEN

          Check_space_name_Or_Id
               (p_space_id         => l_space_restriction_rec.space_id,
                p_space_name       => p_space_restriction_rec.space_name,
                x_space_id         => l_space_id,
                x_return_status    => l_return_status,
                x_error_msg_code   => l_msg_data);

          IF NVL(l_return_status,'x') <> 'S'
          THEN
              Fnd_Message.SET_NAME('AHL','AHL_APPR_SPACE_NOT_EXISTS');
              Fnd_Message.SET_TOKEN('ORGID',p_space_restriction_rec.space_name);
              Fnd_Msg_Pub.ADD;
          END IF;
     END IF;
	 -- Get organization , department id
	 OPEN get_space_detail_cur (l_space_id);
	 FETCH get_space_detail_cur INTO l_space_restriction_rec.organization_id,
	                                 l_space_restriction_rec.department_id;
	 CLOSE get_space_detail_cur;

     --Assign the returned value
     l_space_restriction_rec.space_id := l_space_id;
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'start date'||l_space_restriction_rec.start_date);
   AHL_DEBUG_PUB.debug( 'end date'||l_space_restriction_rec.end_date);
   AHL_DEBUG_PUB.debug( 'org id'||l_space_restriction_rec.organization_id);
   AHL_DEBUG_PUB.debug( 'dept id'||l_space_restriction_rec.department_id);
   END IF;
  --------------------------------Validation ---------------------------
   -- get existing values and compare
   Complete_Space_Restric_Rec (
      p_space_restriction_rec  => l_space_restriction_rec,
      x_space_restriction_rec   => l_Aspace_restriction_rec);
     -- Call Validate space rec attributes
    Validate_Space_Restriction
        ( p_api_version	          => l_api_version,
          p_init_msg_list         => p_init_msg_list,
          p_validation_level      => p_validation_level,
          p_space_restriction_rec => l_Aspace_restriction_rec,
          x_return_status	  => l_return_status,
          x_msg_count		  => l_msg_count,
          x_msg_data		  => l_msg_data );

   -- Check for Duplicate Records
   OPEN check_duplicate_cur(l_Aspace_restriction_rec.space_id,
                            trunc(p_space_restriction_rec.start_date),
                            trunc(p_space_restriction_rec.end_date));
   FETCH check_duplicate_cur INTO l_dup_id;
   CLOSE check_duplicate_cur;
   --
    IF l_dup_id IS NOT NULL THEN
       OPEN get_space_capb_cur(p_space_restriction_rec.space_unavailability_id);
       FETCH get_space_capb_cur INTO l_start_date,l_end_date;
       CLOSE get_space_capb_cur;
       --
     IF (p_space_restriction_rec.start_date <> l_start_date OR
           p_space_restriction_rec.end_date <> l_end_date ) THEN
         Fnd_Message.SET_NAME('AHL','AHL_APPR_RECORD_EXISTS');
        Fnd_Msg_Pub.ADD;
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
   --Call table handler generated package to update a record
   AHL_SPACE_UNAVAILABLE_PKG.UPDATE_ROW
         (
         X_SPACE_UNAVAILABILITY_ID => l_Aspace_restriction_rec.space_unavailability_id,
         X_SPACE_ID                => l_Aspace_restriction_rec.space_id,
         X_START_DATE              => l_Aspace_restriction_rec.start_date,
         X_END_DATE                => l_Aspace_restriction_rec.end_date,
         X_OBJECT_VERSION_NUMBER   => l_Aspace_restriction_rec.object_version_number+1,
         X_ATTRIBUTE_CATEGORY      => l_Aspace_restriction_rec.attribute_category,
         X_ATTRIBUTE1              => l_Aspace_restriction_rec.attribute1,
         X_ATTRIBUTE2              => l_Aspace_restriction_rec.attribute2,
         X_ATTRIBUTE3              => l_Aspace_restriction_rec.attribute3,
         X_ATTRIBUTE4              => l_Aspace_restriction_rec.attribute4,
         X_ATTRIBUTE5              => l_Aspace_restriction_rec.attribute5,
         X_ATTRIBUTE6              => l_Aspace_restriction_rec.attribute6,
         X_ATTRIBUTE7              => l_Aspace_restriction_rec.attribute7,
         X_ATTRIBUTE8              => l_Aspace_restriction_rec.attribute8,
         X_ATTRIBUTE9              => l_Aspace_restriction_rec.attribute9,
         X_ATTRIBUTE10             => l_Aspace_restriction_rec.attribute10,
         X_ATTRIBUTE11             => l_Aspace_restriction_rec.attribute11,
         X_ATTRIBUTE12             => l_Aspace_restriction_rec.attribute12,
         X_ATTRIBUTE13             => l_Aspace_restriction_rec.attribute13,
         X_ATTRIBUTE14             => l_Aspace_restriction_rec.attribute14,
         X_ATTRIBUTE15             => l_Aspace_restriction_rec.attribute15,
         X_DESCRIPTION             => l_Aspace_restriction_rec.description,
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
   IF G_DEBUG='Y' THEN
   -- Debug info
   Ahl_Debug_Pub.debug( 'End of private api Update Space Restriction','+SUAVL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO update_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Update Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO update_space_restriction;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Update Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

WHEN OTHERS THEN
    ROLLBACK TO update_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_UNAVL_PVT',
                            p_procedure_name  =>  'UPDATE_SPACE_RESTRICTION',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'SQL ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Update Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
    END IF;
END Update_Space_Restriction;

--------------------------------------------------------------------
-- PROCEDURE
--    Delete_Space_Restriction
--
-- PURPOSE
--    Delete  Space Restriction Record.
--
-- PARAMETERS
--
-- ISSUES
--
-- NOTES
--    1. Raise exception if the object_version_number doesn't match.
--------------------------------------------------------------------
PROCEDURE Delete_Space_Restriction (
   p_api_version                IN     NUMBER,
   p_init_msg_list              IN     VARCHAR2  := FND_API.g_false,
   p_commit                     IN     VARCHAR2  := FND_API.g_false,
   p_validation_level           IN     NUMBER    := FND_API.g_valid_level_full,
   p_space_restriction_rec      IN     ahl_appr_space_unavl_pub.Space_Restriction_Rec,
   x_return_status                 OUT NOCOPY VARCHAR2,
   x_msg_count                     OUT NOCOPY NUMBER,
   x_msg_data                      OUT NOCOPY VARCHAR2

)
IS
 l_api_name        CONSTANT VARCHAR2(30) := 'DELETE_SPACE_RESTRICTION';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 l_dummy                    NUMBER;
 l_space_unavailability_id  NUMBER;
 l_object_version_number    NUMBER;

  CURSOR c_space_restrict_cur
                 (c_space_unavailability_id IN NUMBER)
   IS
  SELECT   space_unavailability_id,object_version_number
    FROM     ahl_space_unavailable_vl
   WHERE    space_unavailability_id = c_space_unavailability_id
    FOR UPDATE OF OBJECT_VERSION_NUMBER NOWAIT;

BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT delete_space_restriction;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_unavl_pvt.Delete Space Restriction','+SUAVL+');
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
   OPEN c_space_restrict_cur(p_space_restriction_rec.space_unavailability_id);
   FETCH c_space_restrict_cur INTO l_space_unavailability_id,
                                   l_object_version_number;
   IF c_space_restrict_cur%NOTFOUND THEN
      IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_error) THEN
         FND_MESSAGE.set_name('AHL', 'AHL_APPR_RECORD_NOT_FOUND');
         FND_MSG_PUB.add;
      END IF;
      CLOSE c_space_restrict_cur;
      RAISE FND_API.g_exc_error;
   END IF;
   CLOSE c_space_restrict_cur;
   --Check for object version number
   IF l_object_version_number <> p_space_restriction_rec.object_version_number
   THEN
       FND_MESSAGE.set_name('AHL', 'AHL_COM_RECORD_CHANGED');
       FND_MSG_PUB.add;
      RAISE FND_API.g_exc_error;
   END IF;
   -------------------Call Table handler generated procedure------------
 AHL_SPACE_UNAVAILABLE_PKG.DELETE_ROW (
         X_SPACE_UNAVAILABILITY_ID => l_space_unavailability_id
     );
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
   IF G_DEBUG='Y' THEN
   -- Debug info
   Ahl_Debug_Pub.debug( 'End of private api Delete Space Restriction','+SUAVL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO delete_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);
   IF G_DEBUG='Y' THEN
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Delete Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;
WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO delete_space_restriction;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Delete Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

WHEN OTHERS THEN
    ROLLBACK TO delete_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_UNAVL_PVT',
                            p_procedure_name  =>  'DELETE_SPACE_RESTRICTION',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
   IF G_DEBUG='Y' THEN
        -- Debug info.
        AHL_DEBUG_PUB.log_app_messages (
              x_msg_count, x_msg_data, 'SQL ERROR' );
        AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pvt.Delete Space Restriction','+SUAVL+');
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;
   END IF;

END Delete_Space_Restriction;

END AHL_APPR_SPACE_UNAVL_PVT;

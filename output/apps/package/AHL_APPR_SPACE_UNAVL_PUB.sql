
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPR_SPACE_UNAVL_PUB" AUTHID CURRENT_USER AS
/* $Header: AHLPSUAS.pls 115.6 2003/11/04 10:43:13 rroy noship $ */

-----------------------------------------------------------
-- PACKAGE
--    AHL_SPACE_UNAVL_PUB
--
-- PURPOSE
--    This package is a Public API for managing Space Unavailable information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_UNAVIALABLE_VL:
--    Process_Space_Restriction (see below for specification)
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
-- Record for AHL_SPACE_UNAVAILABLE_VL
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
--    Process_Space_Restriction
--
-- PURPOSE
--    Process Space Restriction Record
--
-- PARAMETERS
--    p_x_space_restriction_tbl: the table representing space_restriction_tbl
--
-- NOTES
--------------------------------------------------------------------
PROCEDURE Process_Space_Restriction (
   p_api_version             IN      NUMBER,
   p_init_msg_list           IN      VARCHAR2  := FND_API.g_false,
   p_commit                  IN      VARCHAR2  := FND_API.g_false,
   p_validation_level        IN      NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN      VARCHAR2  := 'JSP',
   p_x_space_restriction_tbl IN  OUT NOCOPY Space_Restriction_Tbl,
   x_return_status               OUT NOCOPY VARCHAR2,
   x_msg_count                   OUT NOCOPY NUMBER,
   x_msg_data                    OUT NOCOPY VARCHAR2
);


END AHL_APPR_SPACE_UNAVL_PUB;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPR_SPACE_UNAVL_PUB" AS
/* $Header: AHLPSUAB.pls 115.6 2003/11/04 10:43:12 rroy noship $ */

G_PKG_NAME  VARCHAR2(30)  := 'AHL_APPR_SPACE_UNAVL_PUB';
G_DEBUG     VARCHAR2(1)   := AHL_DEBUG_PUB.is_log_enabled;
--
-----------------------------------------------------------
-- PACKAGE
--    AHL_APPR_SPACE_UNAVL_PUB
--
-- PURPOSE
--    This package is a Public API for managing Space Unavailable information in
--    Advanced Services Online.  It contains specification for pl/sql records and tables
--
--    AHL_SPACE_UNAVIALABLE_VL:
--    Process_Space_Restriction (see below for specification)
--
--
-- NOTES
--
--
-- HISTORY
-- 17-Apr-2002    ssurapan      Created.

--------------------------------------------------------------------
-- PROCEDURE
--    Process_Space_Restriction
--
-- PURPOSE
--    Process Space Restrictions
--
-- PARAMETERS
--    p_x_space_restriction_tbl: the table representing space_restriction_tbl
--
-- NOTES
--------------------------------------------------------------------

PROCEDURE Process_Space_Restriction (
   p_api_version             IN     NUMBER,
   p_init_msg_list           IN     VARCHAR2  := FND_API.g_false,
   p_commit                  IN     VARCHAR2  := FND_API.g_false,
   p_validation_level        IN     NUMBER    := FND_API.g_valid_level_full,
   p_module_type             IN     VARCHAR2  := 'JSP',
   p_x_space_restriction_tbl IN OUT NOCOPY Space_Restriction_Tbl,
   x_return_status              OUT NOCOPY VARCHAR2,
   x_msg_count                  OUT NOCOPY NUMBER,
   x_msg_data                   OUT NOCOPY VARCHAR2
 )
IS
 l_api_name        CONSTANT VARCHAR2(30) := 'PROCESS_SPACE_RESTRICTION';
 l_api_version     CONSTANT NUMBER       := 1.0;
 l_msg_count                NUMBER;
 l_return_status            VARCHAR2(1);
 l_msg_data                 VARCHAR2(2000);
 --
BEGIN
  --------------------Initialize ----------------------------------
  -- Standard Start of API savepoint
  SAVEPOINT process_space_restriction;
   -- Check if API is called in debug mode. If yes, enable debug.
   IF G_DEBUG='Y' THEN
   AHL_DEBUG_PUB.enable_debug;
   END IF;
   -- Debug info.
   IF G_DEBUG='Y' THEN
       AHL_DEBUG_PUB.debug( 'enter ahl_appr_space_unavl_pub.Process Space Restriction','+SUAVL+');
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
   --------------------Start of API Body-----------------------------------
   IF p_x_space_restriction_tbl.COUNT > 0
   THEN
     FOR i IN p_x_space_restriction_tbl.FIRST..p_x_space_restriction_tbl.LAST
     LOOP
       IF p_x_space_restriction_tbl(i).operation_flag = 'C' THEN
         AHL_APPR_SPACE_UNAVL_PVT.CREATE_SPACE_RESTRICTION
           (
            p_api_version             => l_api_version,
            p_init_msg_list           => p_init_msg_list,
            p_commit                  => p_commit,
            p_validation_level        => p_validation_level,
            p_module_type             => p_module_type,
            p_x_space_restriction_rec   => p_x_space_restriction_tbl(i),
            x_return_status           => l_return_status,
            x_msg_count               => l_msg_count,
            x_msg_data                => l_msg_data
          );
          ELSIF p_x_space_restriction_tbl(i).operation_flag = 'U' THEN

         AHL_APPR_SPACE_UNAVL_PVT.UPDATE_SPACE_RESTRICTION
           (
            p_api_version             => l_api_version,
            p_init_msg_list           => p_init_msg_list,
            p_commit                  => p_commit,
            p_validation_level        => p_validation_level,
            p_module_type             => p_module_type,
            p_space_restriction_rec   => p_x_space_restriction_tbl(i),
            x_return_status           => l_return_status,
            x_msg_count               => l_msg_count,
            x_msg_data                => l_msg_data
          );
       ELSIF p_x_space_restriction_tbl(i).operation_flag = 'D' THEN
         AHL_APPR_SPACE_UNAVL_PVT.DELETE_SPACE_RESTRICTION
           (
            p_api_version             => l_api_version,
            p_init_msg_list           => p_init_msg_list,
            p_commit                  => p_commit,
            p_validation_level        => p_validation_level,
            p_space_restriction_rec   => p_x_space_restriction_tbl(i),
            x_return_status           => l_return_status,
            x_msg_count               => l_msg_count,
            x_msg_data                => l_msg_data
          );
         END IF;
      END LOOP;
   END IF;

   ------------------------End of Body---------------------------------------
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
   Ahl_Debug_Pub.debug( 'End of private api Process Space Restriction','+SUAVL+');
   -- Check if API is called in debug mode. If yes, disable debug.
   Ahl_Debug_Pub.disable_debug;
   END IF;

  EXCEPTION
 WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO process_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);

   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pub.Process Space Restriction','+SUAVL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO process_space_restriction;
    X_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);
        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'UNEXPECTED ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pub.Process Space Restriction','+SUAVL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

WHEN OTHERS THEN
    ROLLBACK TO process_space_restriction;
    X_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
    fnd_msg_pub.add_exc_msg(p_pkg_name        =>  'AHL_APPR_SPACE_UNAVL_PUB',
                            p_procedure_name  =>  'PROCESS_SPACE_RESTRICTION',
                            p_error_text      => SUBSTR(SQLERRM,1,240));
    END IF;
    FND_MSG_PUB.count_and_get( p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => X_msg_data);

        -- Debug info.
   IF G_DEBUG='Y' THEN
            AHL_DEBUG_PUB.log_app_messages (
                x_msg_count, x_msg_data, 'SQL ERROR' );
            AHL_DEBUG_PUB.debug( 'ahl_appr_space_unavl_pub.Process Space Restriction','+SUAVL+');
        END IF;
        -- Check if API is called in debug mode. If yes, disable debug.
        AHL_DEBUG_PUB.disable_debug;

END Process_Space_Restriction;

END AHL_APPR_SPACE_UNAVL_PUB;

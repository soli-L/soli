
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPROVAL_RULES_PKG" AUTHID CURRENT_USER as
/*$Header: AHLLAPRS.pls 120.0.12020000.2 2019/10/23 00:11:50 sracha ship $*/

procedure INSERT_ROW
(
  X_ROWID                    IN OUT NOCOPY  VARCHAR2,
  X_APPROVAL_RULE_ID         IN        NUMBER,
  X_OBJECT_VERSION_NUMBER    IN        NUMBER,
  X_APPROVAL_OBJECT_CODE     IN        VARCHAR2,
  X_APPROVAL_PRIORITY_CODE   IN        VARCHAR2,
  X_APPROVAL_TYPE_CODE       IN        VARCHAR2,
  X_OPERATING_UNIT_ID        IN        NUMBER,
  X_ACTIVE_START_DATE        IN        DATE,
  X_ACTIVE_END_DATE          IN        DATE,
  X_STATUS_CODE              IN        VARCHAR2,
  X_SEEDED_FLAG              IN        VARCHAR2,
  ---X_SECURITY_GROUP_ID        IN        NUMBER,
  X_ATTRIBUTE_CATEGORY       IN        VARCHAR2,
  X_ATTRIBUTE1               IN        VARCHAR2,
  X_ATTRIBUTE2               IN        VARCHAR2,
  X_ATTRIBUTE3               IN        VARCHAR2,
  X_ATTRIBUTE4               IN        VARCHAR2,
  X_ATTRIBUTE5               IN        VARCHAR2,
  X_ATTRIBUTE6               IN        VARCHAR2,
  X_ATTRIBUTE7               IN        VARCHAR2,
  X_ATTRIBUTE8               IN        VARCHAR2,
  X_ATTRIBUTE9               IN        VARCHAR2,
  X_ATTRIBUTE10              IN        VARCHAR2,
  X_ATTRIBUTE11              IN        VARCHAR2,
  X_ATTRIBUTE12              IN        VARCHAR2,
  X_ATTRIBUTE13              IN        VARCHAR2,
  X_ATTRIBUTE14              IN        VARCHAR2,
  X_ATTRIBUTE15              IN        VARCHAR2,
  X_APPROVAL_RULE_NAME       IN        VARCHAR2,
  X_DESCRIPTION              IN        VARCHAR2,
  X_CREATION_DATE            IN        DATE,
  X_CREATED_BY               IN        NUMBER,
  X_LAST_UPDATE_DATE         IN        DATE,
  X_LAST_UPDATED_BY          IN        NUMBER,
  X_LAST_UPDATE_LOGIN        IN        NUMBER,
  X_APPLICATION_USG_CODE     IN        VARCHAR2,
  --Added by aschakka for Bug#30235037, Start
  X_PROGRAM_TYPE_CODE        IN        VARCHAR2 DEFAULT NULL,
  X_PROGRAM_SUBTYPE_CODE     IN        VARCHAR2 DEFAULT NULL,
  X_REVISION_TYPE_CODE       IN        VARCHAR2 DEFAULT NULL
  --Added by aschakka for Bug#30235037, End
);

procedure LOCK_ROW (
  X_APPROVAL_RULE_ID in NUMBER,
  X_OBJECT_VERSION_NUMBER in NUMBER,
  X_APPROVAL_OBJECT_CODE in VARCHAR2,
  X_APPROVAL_PRIORITY_CODE in VARCHAR2,
  X_APPROVAL_TYPE_CODE in VARCHAR2,
  X_OPERATING_UNIT_ID in NUMBER,
  X_ACTIVE_START_DATE in DATE,
  X_ACTIVE_END_DATE in DATE,
  X_STATUS_CODE in VARCHAR2,
  X_SEEDED_FLAG in VARCHAR2,
  --X_SECURITY_GROUP_ID in NUMBER,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2,
  X_APPROVAL_RULE_NAME in VARCHAR2,
  X_DESCRIPTION in VARCHAR2,
  X_APPLICATION_USG_CODE     IN        VARCHAR2
);
procedure UPDATE_ROW
(
  X_APPROVAL_RULE_ID         IN        NUMBER,
  X_OBJECT_VERSION_NUMBER    IN        NUMBER,
  X_APPROVAL_OBJECT_CODE     IN        VARCHAR2,
  X_APPROVAL_PRIORITY_CODE   IN        VARCHAR2,
  X_APPROVAL_TYPE_CODE       IN        VARCHAR2,
  X_OPERATING_UNIT_ID        IN        NUMBER,
  X_ACTIVE_START_DATE        IN        DATE,
  X_ACTIVE_END_DATE          IN        DATE,
  X_STATUS_CODE              IN        VARCHAR2,
  X_SEEDED_FLAG              IN        VARCHAR2,
  --X_SECURITY_GROUP_ID        IN        NUMBER,
  X_ATTRIBUTE_CATEGORY       IN        VARCHAR2,
  X_ATTRIBUTE1               IN        VARCHAR2,
  X_ATTRIBUTE2               IN        VARCHAR2,
  X_ATTRIBUTE3               IN        VARCHAR2,
  X_ATTRIBUTE4               IN        VARCHAR2,
  X_ATTRIBUTE5               IN        VARCHAR2,
  X_ATTRIBUTE6               IN        VARCHAR2,
  X_ATTRIBUTE7               IN        VARCHAR2,
  X_ATTRIBUTE8               IN        VARCHAR2,
  X_ATTRIBUTE9               IN        VARCHAR2,
  X_ATTRIBUTE10              IN        VARCHAR2,
  X_ATTRIBUTE11              IN        VARCHAR2,
  X_ATTRIBUTE12              IN        VARCHAR2,
  X_ATTRIBUTE13              IN        VARCHAR2,
  X_ATTRIBUTE14              IN        VARCHAR2,
  X_ATTRIBUTE15              IN        VARCHAR2,
  X_APPROVAL_RULE_NAME       IN        VARCHAR2,
  X_DESCRIPTION              IN        VARCHAR2,
  X_LAST_UPDATE_DATE         IN        DATE,
  X_LAST_UPDATED_BY          IN        NUMBER,
  X_LAST_UPDATE_LOGIN        IN        NUMBER,
  X_APPLICATION_USG_CODE     IN        VARCHAR2,
  --Added by aschakka for Bug#30235037, Start
  X_PROGRAM_TYPE_CODE        IN        VARCHAR2 DEFAULT NULL,
  X_PROGRAM_SUBTYPE_CODE     IN        VARCHAR2 DEFAULT NULL,
  X_REVISION_TYPE_CODE       IN        VARCHAR2 DEFAULT NULL
  --Added by aschakka for Bug#30235037, End
);

procedure DELETE_ROW
(
  X_APPROVAL_RULE_ID in NUMBER
);

procedure ADD_LANGUAGE;

procedure TRANSLATE_ROW(
          x_APPROVAL_RULE_ID      in NUMBER,
          X_APPROVAL_RULE_NAME    in VARCHAR2,
          X_DESCRIPTION           in VARCHAR2,
          X_OWNER                 in VARCHAR2
 ) ;

procedure  LOAD_ROW(
  X_APPROVAL_RULE_ID in NUMBER,
  X_APPLICATION_USG_CODE IN VARCHAR2,
  X_SEEDED_FLAG in VARCHAR2,
  X_STATUS_CODE in VARCHAR2,
  X_APPROVAL_RULE_NAME in VARCHAR2,
  X_DESCRIPTION in VARCHAR2,
  X_ACTIVE_START_DATE in DATE,
  X_OWNER in VARCHAR2,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2
 );


end AHL_APPROVAL_RULES_PKG;


CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPROVAL_RULES_PKG" as
/*$Header: AHLLAPRB.pls 120.0.12020000.2 2019/10/23 00:09:16 sracha ship $*/

procedure INSERT_ROW

(
  X_ROWID               IN OUT NOCOPY   VARCHAR2,
  X_APPROVAL_RULE_ID         IN        NUMBER,
  X_OBJECT_VERSION_NUMBER    IN        NUMBER,
  X_APPROVAL_OBJECT_CODE     IN        VARCHAR2,
  X_APPROVAL_PRIORITY_CODE   IN        VARCHAR2,
  X_APPROVAL_TYPE_CODE       IN        VARCHAR2,
  X_OPERATING_UNIT_ID        IN        NUMBER,
  X_ACTIVE_START_DATE        IN        DATE,
  X_ACTIVE_END_DATE          IN        DATE,
  X_STATUS_CODE              IN        VARCHAR2,
  X_SEEDED_FLAG              IN        VARCHAR2,
  X_ATTRIBUTE_CATEGORY       IN        VARCHAR2,
  X_ATTRIBUTE1               IN        VARCHAR2,
  X_ATTRIBUTE2               IN        VARCHAR2,
  X_ATTRIBUTE3               IN        VARCHAR2,
  X_ATTRIBUTE4               IN        VARCHAR2,
  X_ATTRIBUTE5               IN        VARCHAR2,
  X_ATTRIBUTE6               IN        VARCHAR2,
  X_ATTRIBUTE7               IN        VARCHAR2,
  X_ATTRIBUTE8               IN        VARCHAR2,
  X_ATTRIBUTE9               IN        VARCHAR2,
  X_ATTRIBUTE10              IN        VARCHAR2,
  X_ATTRIBUTE11              IN        VARCHAR2,
  X_ATTRIBUTE12              IN        VARCHAR2,
  X_ATTRIBUTE13              IN        VARCHAR2,
  X_ATTRIBUTE14              IN        VARCHAR2,
  X_ATTRIBUTE15              IN        VARCHAR2,
  X_APPROVAL_RULE_NAME       IN        VARCHAR2,
  X_DESCRIPTION              IN        VARCHAR2,
  X_CREATION_DATE            IN        DATE,
  X_CREATED_BY               IN        NUMBER,
  X_LAST_UPDATE_DATE         IN        DATE,
  X_LAST_UPDATED_BY          IN        NUMBER,
  X_LAST_UPDATE_LOGIN        IN        NUMBER,
  X_APPLICATION_USG_CODE     IN        VARCHAR2,
  --Added by aschakka for Bug#30235037, Start
  X_PROGRAM_TYPE_CODE        IN        VARCHAR2,
  X_PROGRAM_SUBTYPE_CODE     IN        VARCHAR2,
  X_REVISION_TYPE_CODE       IN        VARCHAR2
  --Added by aschakka for Bug#30235037, End
)

is

cursor C is Select ROWID from AHL_APPROVAL_RULES_B where

            APPROVAL_RULE_ID = X_APPROVAL_RULE_ID ;

begin

insert into AHL_APPROVAL_RULES_B

(
  APPROVAL_RULE_ID,
  OBJECT_VERSION_NUMBER,
  APPROVAL_OBJECT_CODE,
  APPROVAL_PRIORITY_CODE,
  APPROVAL_TYPE_CODE,
  APPLICATION_USG_CODE,
  OPERATING_UNIT_ID,
  ACTIVE_START_DATE,
  ACTIVE_END_DATE,
  STATUS_CODE,
  SEEDED_FLAG,
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
  CREATION_DATE,
  CREATED_BY,
  LAST_UPDATE_DATE,
  LAST_UPDATED_BY,
  LAST_UPDATE_LOGIN,
  --Added by aschakka for Bug#30235037, Start
  PROGRAM_TYPE_CODE,
  PROGRAM_SUBTYPE_CODE,
  REVISION_TYPE_CODE
  --Added by aschakka for Bug#30235037, End
)

 values

(
  X_APPROVAL_RULE_ID,
  X_OBJECT_VERSION_NUMBER,
  X_APPROVAL_OBJECT_CODE,
  X_APPROVAL_PRIORITY_CODE,
  X_APPROVAL_TYPE_CODE,
  X_APPLICATION_USG_CODE,
  X_OPERATING_UNIT_ID,
  X_ACTIVE_START_DATE,
  X_ACTIVE_END_DATE,
  X_STATUS_CODE,
  X_SEEDED_FLAG,
  X_ATTRIBUTE_CATEGORY,
  X_ATTRIBUTE1,
  X_ATTRIBUTE2,
  X_ATTRIBUTE3,
  X_ATTRIBUTE4,
  X_ATTRIBUTE5,
  X_ATTRIBUTE6,
  X_ATTRIBUTE7,
  X_ATTRIBUTE8,
  X_ATTRIBUTE9,
  X_ATTRIBUTE10,
  X_ATTRIBUTE11,
  X_ATTRIBUTE12,
  X_ATTRIBUTE13,
  X_ATTRIBUTE14,
  X_ATTRIBUTE15,
  X_CREATION_DATE,
  X_CREATED_BY,
  X_LAST_UPDATE_DATE,
  X_LAST_UPDATED_BY,
  X_LAST_UPDATE_LOGIN,
  --Added by aschakka for Bug#30235037, Start
  X_PROGRAM_TYPE_CODE,
  X_PROGRAM_SUBTYPE_CODE,
  X_REVISION_TYPE_CODE
  --Added by aschakka for Bug#30235037, End
);



insert into AHL_APPROVAL_RULES_TL

(
    APPROVAL_RULE_NAME,
    DESCRIPTION,
    APPROVAL_RULE_ID,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_LOGIN,
    LANGUAGE,
    SOURCE_LANG
  ) select
    X_APPROVAL_RULE_NAME,
    X_DESCRIPTION,
    X_APPROVAL_RULE_ID,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATED_BY,
    X_CREATION_DATE,
    X_CREATED_BY,
    X_LAST_UPDATE_LOGIN,
    L.LANGUAGE_CODE,
    userenv('LANG')
  from FND_LANGUAGES L

  where L.INSTALLED_FLAG in ('I', 'B')

  and not exists

    (select NULL
    from AHL_APPROVAL_RULES_TL T
    where T.APPROVAL_RULE_ID = X_APPROVAL_RULE_ID
    and T.LANGUAGE = L.LANGUAGE_CODE);



 open c;

 fetch c into X_ROWID;

 if (c%notfound) then

    close c;

 raise no_data_found;

 end if;

 close c;

end INSERT_ROW;



procedure LOCK_ROW (

  X_APPROVAL_RULE_ID in NUMBER,

  X_OBJECT_VERSION_NUMBER in NUMBER,

  X_APPROVAL_OBJECT_CODE in VARCHAR2,

  X_APPROVAL_PRIORITY_CODE in VARCHAR2,

  X_APPROVAL_TYPE_CODE in VARCHAR2,

  X_OPERATING_UNIT_ID in NUMBER,

  X_ACTIVE_START_DATE in DATE,

  X_ACTIVE_END_DATE in DATE,

  X_STATUS_CODE in VARCHAR2,

  X_SEEDED_FLAG in VARCHAR2,

--  X_SECURITY_GROUP_ID in NUMBER,

  X_ATTRIBUTE_CATEGORY in VARCHAR2,

  X_ATTRIBUTE1 in VARCHAR2,

  X_ATTRIBUTE2 in VARCHAR2,

  X_ATTRIBUTE3 in VARCHAR2,

  X_ATTRIBUTE4 in VARCHAR2,

  X_ATTRIBUTE5 in VARCHAR2,

  X_ATTRIBUTE6 in VARCHAR2,

  X_ATTRIBUTE7 in VARCHAR2,

  X_ATTRIBUTE8 in VARCHAR2,

  X_ATTRIBUTE9 in VARCHAR2,

  X_ATTRIBUTE10 in VARCHAR2,

  X_ATTRIBUTE11 in VARCHAR2,

  X_ATTRIBUTE12 in VARCHAR2,

  X_ATTRIBUTE13 in VARCHAR2,

  X_ATTRIBUTE14 in VARCHAR2,

  X_ATTRIBUTE15 in VARCHAR2,

  X_APPROVAL_RULE_NAME in VARCHAR2,

  X_DESCRIPTION in VARCHAR2,
  X_APPLICATION_USG_CODE     IN        VARCHAR2

  ) is

  cursor c is select

      OBJECT_VERSION_NUMBER,

      APPROVAL_OBJECT_CODE,

      APPROVAL_PRIORITY_CODE,

      APPROVAL_TYPE_CODE,

      APPLICATION_USG_CODE,

      OPERATING_UNIT_ID,

      ACTIVE_START_DATE,

      ACTIVE_END_DATE,

      STATUS_CODE,

      SEEDED_FLAG,

--      SECURITY_GROUP_ID,

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

    from AHL_APPROVAL_RULES_B

    where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID

    for update of APPROVAL_RULE_ID nowait;

  recinfo c%rowtype;

  cursor c1 is select

      APPROVAL_RULE_NAME,

      DESCRIPTION,

      decode(LANGUAGE, userenv('LANG'), 'Y', 'N') BASELANG

    from AHL_APPROVAL_RULES_TL

    where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID

    and userenv('LANG') in (LANGUAGE, SOURCE_LANG)

    for update of APPROVAL_RULE_ID nowait;

begin

  open c;

  fetch c into recinfo;

  if (c%notfound) then

    close c;

    fnd_message.set_name('FND', 'FORM_RECORD_DELETED');

    app_exception.raise_exception;

  end if;

  close c;

  if (    (recinfo.OBJECT_VERSION_NUMBER = X_OBJECT_VERSION_NUMBER)

      AND (recinfo.APPROVAL_OBJECT_CODE = X_APPROVAL_OBJECT_CODE)

      AND (recinfo.APPROVAL_PRIORITY_CODE = X_APPROVAL_PRIORITY_CODE)

      AND (recinfo.APPROVAL_TYPE_CODE = X_APPROVAL_TYPE_CODE)

      AND (recinfo.APPLICATION_USG_CODE = X_APPLICATION_USG_CODE)

      AND (recinfo.OPERATING_UNIT_ID = X_OPERATING_UNIT_ID)

      AND (recinfo.ACTIVE_START_DATE = X_ACTIVE_START_DATE)

      AND ((recinfo.ACTIVE_END_DATE = X_ACTIVE_END_DATE)

      OR ((recinfo.ACTIVE_END_DATE is null) AND (X_ACTIVE_END_DATE is null)))

      AND (recinfo.STATUS_CODE = X_STATUS_CODE)

      AND (recinfo.SEEDED_FLAG = X_SEEDED_FLAG)

      /*AND ((recinfo.SECURITY_GROUP_ID = X_SECURITY_GROUP_ID)

           OR ((recinfo.SECURITY_GROUP_ID is null) AND (X_SECURITY_GROUP_ID is null)))*/

      AND ((recinfo.ATTRIBUTE_CATEGORY = X_ATTRIBUTE_CATEGORY)

           OR ((recinfo.ATTRIBUTE_CATEGORY is null) AND (X_ATTRIBUTE_CATEGORY is null)))

      AND ((recinfo.ATTRIBUTE1 = X_ATTRIBUTE1)

           OR ((recinfo.ATTRIBUTE1 is null) AND (X_ATTRIBUTE1 is null)))

      AND ((recinfo.ATTRIBUTE2 = X_ATTRIBUTE2)

           OR ((recinfo.ATTRIBUTE2 is null) AND (X_ATTRIBUTE2 is null)))

      AND ((recinfo.ATTRIBUTE3 = X_ATTRIBUTE3)

      OR ((recinfo.ATTRIBUTE3 is null) AND (X_ATTRIBUTE3 is null)))

      AND ((recinfo.ATTRIBUTE4 = X_ATTRIBUTE4)

           OR ((recinfo.ATTRIBUTE4 is null) AND (X_ATTRIBUTE4 is null)))

      AND ((recinfo.ATTRIBUTE5 = X_ATTRIBUTE5)

           OR ((recinfo.ATTRIBUTE5 is null) AND (X_ATTRIBUTE5 is null)))

      AND ((recinfo.ATTRIBUTE6 = X_ATTRIBUTE6)

           OR ((recinfo.ATTRIBUTE6 is null) AND (X_ATTRIBUTE6 is null)))

      AND ((recinfo.ATTRIBUTE7 = X_ATTRIBUTE7)

           OR ((recinfo.ATTRIBUTE7 is null) AND (X_ATTRIBUTE7 is null)))

      AND ((recinfo.ATTRIBUTE8 = X_ATTRIBUTE8)

           OR ((recinfo.ATTRIBUTE8 is null) AND (X_ATTRIBUTE8 is null)))

      AND ((recinfo.ATTRIBUTE9 = X_ATTRIBUTE9)

           OR ((recinfo.ATTRIBUTE9 is null) AND (X_ATTRIBUTE9 is null)))

      AND ((recinfo.ATTRIBUTE10 = X_ATTRIBUTE10)

           OR ((recinfo.ATTRIBUTE10 is null) AND (X_ATTRIBUTE10 is null)))

      AND ((recinfo.ATTRIBUTE11 = X_ATTRIBUTE11)

           OR ((recinfo.ATTRIBUTE11 is null) AND (X_ATTRIBUTE11 is null)))

      AND ((recinfo.ATTRIBUTE12 = X_ATTRIBUTE12)

           OR ((recinfo.ATTRIBUTE12 is null) AND (X_ATTRIBUTE12 is null)))

      AND ((recinfo.ATTRIBUTE13 = X_ATTRIBUTE13)

           OR ((recinfo.ATTRIBUTE13 is null) AND (X_ATTRIBUTE13 is null)))

      AND ((recinfo.ATTRIBUTE14 = X_ATTRIBUTE14)

           OR ((recinfo.ATTRIBUTE14 is null) AND (X_ATTRIBUTE14 is null)))

      AND ((recinfo.ATTRIBUTE15 = X_ATTRIBUTE15)

           OR ((recinfo.ATTRIBUTE15 is null) AND (X_ATTRIBUTE15 is null)))

  ) then

    null;

  else

    fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');

    app_exception.raise_exception;

  end if;

  for tlinfo in c1 loop

    if (tlinfo.BASELANG = 'Y') then

      if (    (tlinfo.APPROVAL_RULE_NAME = X_APPROVAL_RULE_NAME)

          AND ((tlinfo.DESCRIPTION = X_DESCRIPTION)

               OR ((tlinfo.DESCRIPTION is null) AND (X_DESCRIPTION is null)))

      ) then

        null;

      else

        fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');

        app_exception.raise_exception;

      end if;

    end if;

  end loop;

  return;

end LOCK_ROW;



procedure UPDATE_ROW

(

  X_APPROVAL_RULE_ID in NUMBER,

  X_OBJECT_VERSION_NUMBER in NUMBER,

  X_APPROVAL_OBJECT_CODE in VARCHAR2,

  X_APPROVAL_PRIORITY_CODE in VARCHAR2,

  X_APPROVAL_TYPE_CODE in VARCHAR2,

  X_OPERATING_UNIT_ID in NUMBER,

  X_ACTIVE_START_DATE in DATE,

  X_ACTIVE_END_DATE in DATE,

  X_STATUS_CODE in VARCHAR2,

  X_SEEDED_FLAG in VARCHAR2,

--  X_SECURITY_GROUP_ID in NUMBER,

  X_ATTRIBUTE_CATEGORY in VARCHAR2,

  X_ATTRIBUTE1 IN VARCHAR2,

  X_ATTRIBUTE2 IN VARCHAR2,

  X_ATTRIBUTE3 IN VARCHAR2,

  X_ATTRIBUTE4 IN VARCHAR2,

  X_ATTRIBUTE5 IN VARCHAR2,

  X_ATTRIBUTE6 IN VARCHAR2,

  X_ATTRIBUTE7 IN VARCHAR2,

  X_ATTRIBUTE8 IN VARCHAR2,

  X_ATTRIBUTE9 IN VARCHAR2,

  X_ATTRIBUTE10 IN VARCHAR2,

  X_ATTRIBUTE11 IN VARCHAR2,

  X_ATTRIBUTE12 IN VARCHAR2,

  X_ATTRIBUTE13 IN VARCHAR2,

  X_ATTRIBUTE14 IN VARCHAR2,

  X_ATTRIBUTE15 IN VARCHAR2,

  X_APPROVAL_RULE_NAME in VARCHAR2,

  X_DESCRIPTION in VARCHAR2,

  X_LAST_UPDATE_DATE in DATE,

  X_LAST_UPDATED_BY in NUMBER,

  X_LAST_UPDATE_LOGIN in NUMBER,

  X_APPLICATION_USG_CODE IN VARCHAR2,
  --Added by aschakka for Bug#30235037, Start
  X_PROGRAM_TYPE_CODE        IN        VARCHAR2,
  X_PROGRAM_SUBTYPE_CODE     IN        VARCHAR2,
  X_REVISION_TYPE_CODE       IN        VARCHAR2
  --Added by aschakka for Bug#30235037, End

) is

begin



update AHL_APPROVAL_RULES_B set

    OBJECT_VERSION_NUMBER = X_OBJECT_VERSION_NUMBER,

    APPROVAL_OBJECT_CODE = X_APPROVAL_OBJECT_CODE,

    APPROVAL_PRIORITY_CODE = X_APPROVAL_PRIORITY_CODE,

    APPROVAL_TYPE_CODE = X_APPROVAL_TYPE_CODE,

    APPLICATION_USG_CODE = X_APPLICATION_USG_CODE,

    OPERATING_UNIT_ID = X_OPERATING_UNIT_ID,

    ACTIVE_START_DATE = X_ACTIVE_START_DATE,

    ACTIVE_END_DATE = X_ACTIVE_END_DATE,

    STATUS_CODE = X_STATUS_CODE,

    SEEDED_FLAG = X_SEEDED_FLAG,

--    SECURITY_GROUP_ID = X_SECURITY_GROUP_ID,

    ATTRIBUTE_CATEGORY = X_ATTRIBUTE_CATEGORY,

    ATTRIBUTE1 =  X_ATTRIBUTE1,

    ATTRIBUTE2 =  X_ATTRIBUTE2,

    ATTRIBUTE3 =  X_ATTRIBUTE3,

    ATTRIBUTE4 =  X_ATTRIBUTE4,

    ATTRIBUTE5 =  X_ATTRIBUTE5,

    ATTRIBUTE6 =  X_ATTRIBUTE6,

    ATTRIBUTE7 =  X_ATTRIBUTE7,

    ATTRIBUTE8 =  X_ATTRIBUTE8,

    ATTRIBUTE9 =  X_ATTRIBUTE9,

    ATTRIBUTE10 =  X_ATTRIBUTE10,

    ATTRIBUTE11 =  X_ATTRIBUTE11,

    ATTRIBUTE12 =  X_ATTRIBUTE12,

    ATTRIBUTE13 =  X_ATTRIBUTE13,

    ATTRIBUTE14 =  X_ATTRIBUTE14,

    ATTRIBUTE15 =  X_ATTRIBUTE15,

    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,

    LAST_UPDATED_BY = X_LAST_UPDATED_BY,

    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN,
    --Added by aschakka for Bug#30235037, Start
    PROGRAM_TYPE_CODE    = X_PROGRAM_TYPE_CODE,
    PROGRAM_SUBTYPE_CODE = X_PROGRAM_SUBTYPE_CODE,
    REVISION_TYPE_CODE   = X_REVISION_TYPE_CODE
  --Added by aschakka for Bug#30235037, End

  where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID

  and OBJECT_VERSION_NUMBER = X_OBJECT_VERSION_NUMBER-1;


if (sql%notfound) then

  raise no_data_found;

end if;



 update AHL_APPROVAL_RULES_TL set

    APPROVAL_RULE_NAME = X_APPROVAL_RULE_NAME,

    DESCRIPTION = X_DESCRIPTION,

    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,

    LAST_UPDATED_BY = X_LAST_UPDATED_BY,

    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN,

    SOURCE_LANG = userenv('LANG')

  where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID

  and userenv('LANG') in (LANGUAGE, SOURCE_LANG);



  if (sql%notfound) then

    raise no_data_found;

  end if;

end UPDATE_ROW;



procedure DELETE_ROW(

  X_APPROVAL_RULE_ID in NUMBER

)

is

begin

  delete from AHL_APPROVAL_RULES_TL

  where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID;



  if (sql%notfound) then

    raise no_data_found;

  end if;



  delete from AHL_APPROVAL_RULES_B

  where APPROVAL_RULE_ID = X_APPROVAL_RULE_ID;



  if (sql%notfound) then

    raise no_data_found;

  end if;

end DELETE_ROW;



procedure ADD_LANGUAGE

is

begin

  delete from AHL_APPROVAL_RULES_TL T

  where not exists

    (select NULL

    from AHL_APPROVAL_RULES_B B

    where B.APPROVAL_RULE_ID = T.APPROVAL_RULE_ID

    );



  update AHL_APPROVAL_RULES_TL T set (

      APPROVAL_RULE_NAME,

      DESCRIPTION

    ) = (select

      B.APPROVAL_RULE_NAME,

      B.DESCRIPTION

    from AHL_APPROVAL_RULES_TL B

    where B.APPROVAL_RULE_ID = T.APPROVAL_RULE_ID

    and B.LANGUAGE = T.SOURCE_LANG)

  where (

      T.APPROVAL_RULE_ID,

      T.LANGUAGE

  ) in (select

      SUBT.APPROVAL_RULE_ID,

      SUBT.LANGUAGE

    from AHL_APPROVAL_RULES_TL SUBB, AHL_APPROVAL_RULES_TL SUBT

    where SUBB.APPROVAL_RULE_ID = SUBT.APPROVAL_RULE_ID

    and SUBB.LANGUAGE = SUBT.SOURCE_LANG

    and (SUBB.APPROVAL_RULE_NAME <> SUBT.APPROVAL_RULE_NAME

      or (SUBB.APPROVAL_RULE_NAME is null and SUBT.APPROVAL_RULE_NAME is not null)

      or (SUBB.APPROVAL_RULE_NAME is not null and SUBT.APPROVAL_RULE_NAME is null)

      or SUBB.DESCRIPTION <> SUBT.DESCRIPTION

      or (SUBB.DESCRIPTION is null and SUBT.DESCRIPTION is not null)

      or (SUBB.DESCRIPTION is not null and SUBT.DESCRIPTION is null)

  ));



  insert into AHL_APPROVAL_RULES_TL (

    APPROVAL_RULE_NAME,

    DESCRIPTION,

--    SECURITY_GROUP_ID,

    APPROVAL_RULE_ID,

    LAST_UPDATE_DATE,

    LAST_UPDATED_BY,

    CREATION_DATE,

    CREATED_BY,

    LAST_UPDATE_LOGIN,

    LANGUAGE,

    SOURCE_LANG

  ) select

    B.APPROVAL_RULE_NAME,

    B.DESCRIPTION,

--    B.SECURITY_GROUP_ID,

    B.APPROVAL_RULE_ID,

    B.LAST_UPDATE_DATE,

    B.LAST_UPDATED_BY,

    B.CREATION_DATE,

    B.CREATED_BY,

    B.LAST_UPDATE_LOGIN,

    L.LANGUAGE_CODE,

    B.SOURCE_LANG

  from AHL_APPROVAL_RULES_TL B, FND_LANGUAGES L

  where L.INSTALLED_FLAG in ('I', 'B')

  and B.LANGUAGE = userenv('LANG')

  and not exists

    (select NULL

    from AHL_APPROVAL_RULES_TL T

    where T.APPROVAL_RULE_ID = B.APPROVAL_RULE_ID

    and T.LANGUAGE = L.LANGUAGE_CODE);

end ADD_LANGUAGE;


procedure TRANSLATE_ROW(
          X_APPROVAL_RULE_ID      in NUMBER,
          X_APPROVAL_RULE_NAME                in VARCHAR2,
          X_DESCRIPTION         in VARCHAR2,
          X_OWNER               in VARCHAR2
 ) IS

 begin
    update AHL_APPROVAL_RULES_TL set
       approval_rule_name = nvl(x_approval_rule_name, approval_rule_name),
       description = nvl(x_description, description),
       source_lang = userenv('LANG'),
       last_update_date = sysdate,
       last_updated_by = decode(x_owner, 'SEED', 1, 0),
       last_update_login = 0
    where  approval_rule_id = x_approval_rule_id
    and      userenv('LANG') in (language, source_lang);
end TRANSLATE_ROW;

procedure  LOAD_ROW(
  X_APPROVAL_RULE_ID in NUMBER,
  X_APPLICATION_USG_CODE IN VARCHAR2,
  X_SEEDED_FLAG in VARCHAR2,
  X_STATUS_CODE in VARCHAR2,
  X_APPROVAL_RULE_NAME in VARCHAR2,
  X_DESCRIPTION in VARCHAR2,
  X_ACTIVE_START_DATE in DATE,
  X_OWNER in VARCHAR2,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2
 )
IS
  l_user_id     number := 0;
  l_obj_verno   number;
  l_dummy_char  varchar2(1);
  l_row_id      varchar2(100);
  l_rule_id      number;
  l_approval_object_code  VARCHAR2(30);
  l_approval_priority_code  VARCHAR2(30);
  l_approval_type_code     VARCHAR2(30);
  l_operating_unit_id      NUMBER;
  l_active_end_date        DATE;


cursor  c_obj_verno is
  select  object_version_number
  from    AHL_APPROVAL_RULES_B
  where   approval_rule_id =  X_APPROVAL_RULE_ID;

cursor c_chk_rule_exists is
  select 'x'
  from   AHL_APPROVAL_RULES_B
  where  approval_rule_id = X_APPROVAL_RULE_ID;

cursor c_get_rule_id is
   select ahl_approval_rules_b_s.nextval
   from dual;


BEGIN

  if X_OWNER = 'SEED' then
     l_user_id := 1;
 end if;

 open c_chk_rule_exists;
 fetch c_chk_rule_exists into l_dummy_char;
 if c_chk_rule_exists%notfound
 then
    close c_chk_rule_exists;

    if X_APPROVAL_RULE_ID is null then
        open c_get_rule_id;
        fetch c_get_rule_id into l_rule_id;
        close c_get_rule_id;
    else
       l_rule_id := X_APPROVAL_RULE_ID;
    end if ;

    l_obj_verno := 1;

 AHL_APPROVAL_RULES_PKG.INSERT_ROW (
  X_ROWID                       => l_row_id,
  X_APPROVAL_RULE_ID         => l_rule_id,
  X_OBJECT_VERSION_NUMBER     => l_obj_verno,
  X_APPROVAL_OBJECT_CODE        => l_approval_object_code,
  X_APPROVAL_PRIORITY_CODE      => l_approval_priority_code,
  X_APPROVAL_TYPE_CODE          => l_approval_type_code,
  X_APPLICATION_USG_CODE        => X_APPLICATION_USG_CODE,
  X_OPERATING_UNIT_ID           => l_operating_unit_id,
  X_ACTIVE_END_DATE             => l_active_end_date,
  X_STATUS_CODE         => X_STATUS_CODE ,
  X_ACTIVE_START_DATE         => X_ACTIVE_START_DATE ,
  X_SEEDED_FLAG         => X_SEEDED_FLAG ,
  X_APPROVAL_RULE_NAME         => X_APPROVAL_RULE_NAME ,
  X_ATTRIBUTE_CATEGORY         => X_ATTRIBUTE_CATEGORY,
  X_ATTRIBUTE1            =>  X_ATTRIBUTE1,
  X_ATTRIBUTE2            =>  X_ATTRIBUTE2,
  X_ATTRIBUTE3            =>  X_ATTRIBUTE3,
  X_ATTRIBUTE4            =>  X_ATTRIBUTE4,
  X_ATTRIBUTE5            =>  X_ATTRIBUTE5,
  X_ATTRIBUTE6            =>  X_ATTRIBUTE6,
  X_ATTRIBUTE7            =>  X_ATTRIBUTE7,
  X_ATTRIBUTE8            =>  X_ATTRIBUTE8,
  X_ATTRIBUTE9            =>  X_ATTRIBUTE9,
  X_ATTRIBUTE10            =>  X_ATTRIBUTE10,
  X_ATTRIBUTE11            =>  X_ATTRIBUTE11,
  X_ATTRIBUTE12            =>  X_ATTRIBUTE12,
  X_ATTRIBUTE13            =>  X_ATTRIBUTE13,
  X_ATTRIBUTE14            =>  X_ATTRIBUTE14,
  X_ATTRIBUTE15            =>  X_ATTRIBUTE15,
  X_DESCRIPTION         => X_DESCRIPTION ,
  X_CREATION_DATE         => SYSDATE,
  X_CREATED_BY                  => l_user_id,
  X_LAST_UPDATE_DATE            => SYSDATE,
  X_LAST_UPDATED_BY             => l_user_id,
  X_LAST_UPDATE_LOGIN           => 0
);

else
   close c_chk_rule_exists;
   open c_obj_verno;
   fetch c_obj_verno into l_obj_verno;
   close c_obj_verno;

AHL_APPROVAL_RULES_PKG.UPDATE_ROW (

  X_APPROVAL_RULE_ID         => X_APPROVAL_RULE_ID,
  X_OBJECT_VERSION_NUMBER     => l_obj_verno + 1,
  X_STATUS_CODE            => X_STATUS_CODE ,
  X_APPLICATION_USG_CODE        => X_APPLICATION_USG_CODE,
  X_ACTIVE_START_DATE         => X_ACTIVE_START_DATE ,
  X_SEEDED_FLAG         => X_SEEDED_FLAG,
  X_APPROVAL_OBJECT_CODE        => l_approval_object_code,
  X_APPROVAL_PRIORITY_CODE      => l_approval_priority_code,
  X_APPROVAL_TYPE_CODE          => l_approval_type_code,
  X_OPERATING_UNIT_ID           => l_operating_unit_id,
  X_ACTIVE_END_DATE             => l_active_end_date,
  X_ATTRIBUTE_CATEGORY         => X_ATTRIBUTE_CATEGORY,
  X_ATTRIBUTE1            =>  X_ATTRIBUTE1,
  X_ATTRIBUTE2            =>  X_ATTRIBUTE2,
  X_ATTRIBUTE3            =>  X_ATTRIBUTE3,
  X_ATTRIBUTE4            =>  X_ATTRIBUTE4,
  X_ATTRIBUTE5            =>  X_ATTRIBUTE5,
  X_ATTRIBUTE6            =>  X_ATTRIBUTE6,
  X_ATTRIBUTE7            =>  X_ATTRIBUTE7,
  X_ATTRIBUTE8            =>  X_ATTRIBUTE8,
  X_ATTRIBUTE9            =>  X_ATTRIBUTE9,
  X_ATTRIBUTE10            =>  X_ATTRIBUTE10,
  X_ATTRIBUTE11            =>  X_ATTRIBUTE11,
  X_ATTRIBUTE12            =>  X_ATTRIBUTE12,
  X_ATTRIBUTE13            =>  X_ATTRIBUTE13,
  X_ATTRIBUTE14            =>  X_ATTRIBUTE14,
  X_ATTRIBUTE15            =>  X_ATTRIBUTE15,
  X_APPROVAL_RULE_NAME         => X_APPROVAL_RULE_NAME ,
  X_DESCRIPTION         => X_DESCRIPTION ,
  X_LAST_UPDATE_DATE            => SYSDATE,
  X_LAST_UPDATED_BY             => l_user_id,
  X_LAST_UPDATE_LOGIN           => 0



);


end if;

END LOAD_ROW ;


end AHL_APPROVAL_RULES_PKG;


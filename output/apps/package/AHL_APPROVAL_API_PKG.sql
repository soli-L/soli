
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AHL_APPROVAL_API_PKG" AUTHID CURRENT_USER as
/* $Header: AHLLAPIS.pls 115.3 2002/12/04 00:04:29 ssurapan noship $ */

procedure INSERT_ROW (
  X_ROWID in out NOCOPY VARCHAR2,
  X_APPROVAL_API_ID in NUMBER,
  X_OBJECT_VERSION_NUMBER in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_CREATION_DATE in DATE,
  X_CREATED_BY in NUMBER,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
);

procedure UPDATE_ROW (
  X_APPROVAL_API_ID in NUMBER,
  X_OBJECT_VERSION_NUMBER in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
);

procedure DELETE_ROW
(
  X_APPROVAL_API_ID in NUMBER
);


procedure  LOAD_ROW(
  X_APPROVAL_API_ID in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_OWNER in VARCHAR2
    ) ;



END ahl_approval_api_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AHL_APPROVAL_API_PKG" as
/* $Header: AHLLAPIB.pls 115.2 2002/12/04 00:03:53 ssurapan noship $ */
procedure INSERT_ROW (
  X_ROWID in out NOCOPY VARCHAR2,
  X_APPROVAL_API_ID in NUMBER,
  X_OBJECT_VERSION_NUMBER in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_CREATION_DATE in DATE,
  X_CREATED_BY in NUMBER,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
) is
  cursor C is select ROWID from AHL_APPROVAL_API
    where APPROVAL_API_ID = X_APPROVAL_API_ID
    ;
begin
    insert into ahl_approval_api (
    APPROVAL_API_ID,
    OBJECT_VERSION_NUMBER,
    API_USED_BY,
    APPROVAL_OBJECT_TYPE,
    APPROVAL_TYPE,
    ACTIVITY_TYPE,
    PACKAGE_NAME,
    PROCEDURE_NAME,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN
  ) values (
    X_APPROVAL_API_ID,
    X_OBJECT_VERSION_NUMBER,
    X_API_USED_BY,
    X_APPROVAL_OBJECT_TYPE,
    X_APPROVAL_TYPE,
    X_ACTIVITY_TYPE,
    X_PACKAGE_NAME,
    X_PROCEDURE_NAME,
    X_CREATION_DATE,
    X_CREATED_BY,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATED_BY,
    X_LAST_UPDATE_LOGIN
  );

  open c;
  fetch c into X_ROWID;
  if (c%notfound) then
    close c;
    raise no_data_found;
  end if;
  close c;

end INSERT_ROW;

procedure UPDATE_ROW
(
  X_APPROVAL_API_ID in NUMBER,
  X_OBJECT_VERSION_NUMBER in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
) is
begin
  update AHL_APPROVAL_API set
    OBJECT_VERSION_NUMBER = X_OBJECT_VERSION_NUMBER,
    API_USED_BY = X_API_USED_BY,
    APPROVAL_OBJECT_TYPE = X_APPROVAL_OBJECT_TYPE,
    APPROVAL_TYPE = X_APPROVAL_TYPE,
    ACTIVITY_TYPE = X_ACTIVITY_TYPE,
    PACKAGE_NAME =  X_PACKAGE_NAME,
    PROCEDURE_NAME =  X_PROCEDURE_NAME,
    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,
    LAST_UPDATED_BY =  X_LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN
    where APPROVAL_API_ID = X_APPROVAL_API_ID;

if (sql%notfound) then
  raise no_data_found;
end if;

end UPDATE_ROW;

procedure DELETE_ROW
(
  X_APPROVAL_API_ID in NUMBER
)
is
begin
  delete from AHL_APPROVAL_API
  where APPROVAL_API_ID = X_APPROVAL_API_ID;

  if (sql%notfound) then
    raise no_data_found;
  end if;

end DELETE_ROW;

procedure  LOAD_ROW(
  X_APPROVAL_API_ID in NUMBER,
  X_API_USED_BY in VARCHAR2,
  X_APPROVAL_OBJECT_TYPE in VARCHAR2,
  X_APPROVAL_TYPE in VARCHAR2,
  X_ACTIVITY_TYPE in VARCHAR2,
  X_PACKAGE_NAME in VARCHAR2,
  X_PROCEDURE_NAME in VARCHAR2,
  X_OWNER in VARCHAR2
    )
IS
  l_user_id     number := 0;
  l_obj_verno   number;
  l_dummy_char  varchar2(1);
  l_row_id      varchar2(100);
  l_api_id      number;

cursor  c_obj_verno is
  select  object_version_number
  from    AHL_APPROVAL_API
  where   approval_api_id =  X_APPROVAL_API_ID;

cursor c_chk_api_exists is
  select 'x'
  from   AHL_APPROVAL_API
  where  approval_api_id = X_APPROVAL_API_ID;

cursor c_get_api_id is
   select ahl_approval_api_s.nextval
   from dual;


BEGIN

  if X_OWNER = 'SEED' then
     l_user_id := 1;
 end if;

 open c_chk_api_exists;
 fetch c_chk_api_exists into l_dummy_char;
 if c_chk_api_exists%notfound
 then
    close c_chk_api_exists;

    if X_APPROVAL_API_ID is null then
        open c_get_api_id;
        fetch c_get_api_id into l_api_id;
        close c_get_api_id;
    else
       l_api_id := X_APPROVAL_API_ID;
    end if ;

    l_obj_verno := 1;

AHL_APPROVAL_API_PKG.INSERT_ROW (
  X_ROWID                       => l_row_id,
  X_APPROVAL_API_ID 		=> l_api_id,
  X_OBJECT_VERSION_NUMBER 	=> l_obj_verno,
  X_API_USED_BY 		=> X_API_USED_BY ,
  X_APPROVAL_OBJECT_TYPE 	=> X_APPROVAL_OBJECT_TYPE ,
  X_APPROVAL_TYPE 		=> X_APPROVAL_TYPE ,
  X_ACTIVITY_TYPE 		=> X_ACTIVITY_TYPE ,
  X_PACKAGE_NAME 		=> X_PACKAGE_NAME ,
  X_PROCEDURE_NAME 		=> X_PROCEDURE_NAME ,
  X_CREATION_DATE 		=> SYSDATE,
  X_CREATED_BY                  => l_user_id,
  X_LAST_UPDATE_DATE            => SYSDATE,
  X_LAST_UPDATED_BY             => l_user_id,
  X_LAST_UPDATE_LOGIN           => 0
);


else
   close c_chk_api_exists;
   open c_obj_verno;
   fetch c_obj_verno into l_obj_verno;
   close c_obj_verno;



AHL_APPROVAL_API_PKG.UPDATE_ROW (
  X_APPROVAL_API_ID 		=> X_APPROVAL_API_ID,
  X_OBJECT_VERSION_NUMBER 	=> l_obj_verno + 1,
  X_API_USED_BY 		=> X_API_USED_BY ,
  X_APPROVAL_OBJECT_TYPE 	=> X_APPROVAL_OBJECT_TYPE ,
  X_APPROVAL_TYPE 		=> X_APPROVAL_TYPE ,
  X_ACTIVITY_TYPE 		=> X_ACTIVITY_TYPE ,
  X_PACKAGE_NAME 		=> X_PACKAGE_NAME ,
  X_PROCEDURE_NAME 		=> X_PROCEDURE_NAME ,
  X_LAST_UPDATE_DATE            => SYSDATE,
  X_LAST_UPDATED_BY             => l_user_id,
  X_LAST_UPDATE_LOGIN           => 0
);


end if;

END LOAD_ROW ;


end AHL_APPROVAL_API_PKG;

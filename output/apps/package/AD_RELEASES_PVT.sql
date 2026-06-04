
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_RELEASES_PVT" 
/* $Header: adphrlss.pls 115.8 2004/06/02 11:43:05 sallamse ship $ */
AUTHID CURRENT_USER as

Procedure CreateRelease
           (p_major_version                 number,
            p_minor_version                 number,
            p_tape_version                  number,
            p_row_src_comments              varchar2,
            p_base_rel_flag                 varchar2,
            p_start_dt                      date,
            p_end_dt                        date     default null,
            p_created_by_user_id            number,
            p_release_id         out nocopy number);

end ad_releases_pvt;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_RELEASES_PVT" as
/* $Header: adphrlsb.pls 120.1 2006/04/10 01:44:35 rahkumar noship $ */
procedure CreateRelease
           (p_major_version                 number,
            p_minor_version                 number,
            p_tape_version                  number,
            p_row_src_comments              varchar2,
            p_base_rel_flag                 varchar2,
            p_start_dt                      date,
            p_end_dt                        date     default null,
            p_created_by_user_id            number,
            p_release_id         out nocopy number)
is
  v_release_id number;
begin

--  Have a savepoint here
--
  savepoint S1;

  begin
    select release_id
    into p_release_id
    from ad_releases
    where major_version = p_major_version
    and minor_version = p_minor_version
    and tape_version = p_tape_version;

    return;
  exception when no_data_found then
    null;
  end;

  --  Validate   p_base_rel_flag
  --
  if(upper(p_base_rel_flag) not in ('Y','N') and
                                    p_base_rel_flag is not null )
  then
    raise_application_error(-20000, 'Error:Invalid parameters');
  end if;


--  Validate p_end_dt  >  p_start_dt
--
  if p_start_dt is null then
    raise_application_error(-20000, 'Error: Start-date is null.');
  end if;

  if p_end_dt < p_start_dt then
    raise_application_error(-20000,
                            'Error:End-date is earlier than start-date');
  end if;

--   Lock the table exclusively to do further validations
--   Major and Minor ids and update thge table
--   If somebody has the lock then exit with a error message
--
-- Do not reference table AD_RELEASES via the schema name APPS as some
-- customers do not have an APPS schema. Bug 2042101.

  lock table ad_releases in exclusive mode nowait;

  update ad_releases
  set end_date_active = p_start_dt - 1 / (24*60*60)
  where release_id in (select release_id
                       from ad_releases
                       where major_version = p_major_version
                       and minor_version = p_minor_version
                       and sysdate between start_date_active and
                                           nvl(end_date_active, sysdate+1));

  select ad_releases_s.nextval
  into v_release_id
  from dual;

  insert into ad_releases
  (
    RELEASE_ID,
    MAJOR_VERSION,
    MINOR_VERSION,
    TAPE_VERSION,
    ROW_SOURCE_COMMENTS,
    ARU_RELEASE_NAME,
    BASE_RELEASE_FLAG,
    START_DATE_ACTIVE,
    END_DATE_ACTIVE,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY
  )
  values
  (
    v_release_id   ,
    p_major_version,
    p_minor_version,
    p_tape_version ,
    p_row_src_comments,
    'R12',               /* @@ Be sure to update this in future apps releases */
    UPPER(p_base_rel_flag),
    p_start_dt,
    p_end_dt,
    sysdate,
    p_created_by_user_id,
    sysdate,
    p_created_by_user_id
  );


  p_release_id:=v_release_id;

exception when others then
  rollback to S1;
  raise;
end CreateRelease;


end ad_releases_pvt;


  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CTX_DDL" AUTHID CURRENT_USER as
/* $Header: ADCTXDDLS.pls 120.0.12020000.2 2021/01/24 18:40:36 mkumandu noship $ */
OPTLEVEL_FAST     constant varchar2(4) := 'FAST';
OPTLEVEL_FULL     constant varchar2(4) := 'FULL';
MAXTIME_UNLIMITED constant number := 2147483647;
DR_SEC_TYPE_UNKNOWN  constant number :=  0;
DR_SEC_TYPE_ZONE     constant number :=  1;
DR_SEC_TYPE_FIELD    constant number :=  2;
DR_SEC_TYPE_SPECIAL  constant number :=  3;
DR_SEC_TYPE_STOP     constant number :=  4;
DR_SEC_TYPE_ATTR     constant number :=  5;
DR_SEC_ZONE_FID      constant number :=  1;
DR_SEC_FIELD_MIN_FID constant number :=  16;
DR_SEC_FIELD_MAX_FID constant number :=  79;
DR_SEC_MAX_FIELD     constant number :=  64;
procedure add_attr_section (group_name in varchar2,
                            section_name in varchar2,
                            tag in varchar2);
procedure add_field_section (group_name in varchar2,
                             section_name in varchar2,
                             tag in varchar2,
                             visible in boolean default FALSE);
procedure add_index (set_name in varchar2,
                     column_list in varchar2,
                     storage_clause in varchar2 default null);
procedure add_special_section (group_name in varchar2,
                               section_name in varchar2);
procedure add_stopclass (stoplist_name in varchar2,
                         stopclass in varchar2);
procedure add_stoptheme (stoplist_name in varchar2,
                         stoptheme in varchar2);
procedure add_stopword (stoplist_name in varchar2,
                        stopword in varchar2,
                        language in varchar2 default null);
procedure add_stop_section (group_name in varchar2,
                            tag in varchar2);
procedure add_sub_lexer (lexer_name in varchar2,
                         language in varchar2,
                         sub_lexer in varchar2,
                         alt_value in varchar2 default null);
procedure add_zone_section (group_name in varchar2,
                            section_name in varchar2,
                            tag in varchar2);
procedure create_index_set (set_name in varchar2);
procedure create_preference (preference_name in varchar2,
                             object_name in varchar2);
procedure create_section_group (group_name in varchar2,
group_type in varchar2);
procedure create_stoplist (stoplist_name in varchar2,
                           stoplist_type in varchar2 default 'BASIC_STOPLIST');
procedure drop_index_set (set_name in varchar2);
procedure drop_preference (preference_name in varchar2);
procedure drop_section_group (group_name in varchar2);
procedure drop_stoplist (stoplist_name in varchar2);
procedure optimize_index (idx_name in varchar2,
                          optlevel in varchar2,
                          maxtime in number default null,
                          token in varchar2 default null,  parallel_degree in number default 1);
procedure remove_index (set_name in varchar2,
                        column_list in varchar2);
procedure remove_section (group_name in varchar2,
                          section_name in varchar2);
procedure remove_section (group_name in varchar2,
                          section_id in number);
procedure remove_stopclass (stoplist_name in varchar2,
                            stopclass in varchar2);
procedure remove_stoptheme (stoplist_name in varchar2,
                            stoptheme in varchar2);
procedure remove_stopword (stoplist_name in varchar2,
                           stopword in varchar2,
                           language in varchar2 default null);
procedure remove_sub_lexer (lexer_name in varchar2,
                            language in varchar2);
procedure set_attribute (preference_name in varchar2,
                         attribute_name in varchar2,
                         attribute_value in varchar2);
procedure sync_index (idx_name in varchar2 default null, parallel_degree in number default 1);
procedure unset_attribute (preference_name in varchar2,
                           attribute_name in varchar2);
procedure set_effective_schema(user_schema in varchar2);
procedure add_sdata_section(group_name in varchar2,
                            section_name in varchar2,
                            tag in varchar2,
                            datatype in varchar2 default null);
end AD_CTX_DDL;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CTX_DDL" as
/* $Header: ADCTXDDLB.pls 120.0.12020000.3 2021/07/27 15:01:37 rsatyava noship $ */
v_context varchar2(30) := sys_context('USERENV','CURRENT_USER');
procedure add_attr_section (group_name in varchar2,
                 section_name in varchar2,
                 tag in varchar2)
is

begin
if group_name like '%.%' then
 ctx_ddl.add_attr_section(group_name, section_name, tag);
else
 ctx_ddl.add_attr_section( v_context||'.'||group_name, section_name, tag);
 end if;
end add_attr_section;
procedure add_field_section (group_name in varchar2,
                  section_name in varchar2,
                  tag in varchar2,
                  visible in boolean default FALSE)
is

begin

if group_name like '%.%' then
  ctx_ddl.add_field_section(group_name, section_name, tag, visible);
else
  ctx_ddl.add_field_section( v_context||'.'||group_name, section_name, tag, visible);
end if;
end add_field_section;
procedure add_index (set_name in varchar2,
          column_list in varchar2,
          storage_clause in varchar2 default null)
is

begin

 if set_name like '%.%' then
 ctx_ddl.add_index(set_name, column_list,storage_clause);
 else
 ctx_ddl.add_index( v_context||'.'||set_name, column_list, storage_clause);
 end if;
end  add_index;
procedure add_special_section (group_name in varchar2,
                    section_name in varchar2)
is

begin
if group_name like '%.%' then
  ctx_ddl.add_special_section(group_name, section_name);
else
   ctx_ddl.add_special_section( v_context||'.'||group_name, section_name);
 end if;
end add_special_section;
procedure add_stopclass (stoplist_name in varchar2,
               stopclass in varchar2)
is

begin

 if stoplist_name like '%.%' then
   ctx_ddl.add_stopclass(stoplist_name, stopclass);
else
   ctx_ddl.add_stopclass( v_context||'.'||stoplist_name, stopclass);
 end if;
end  add_stopclass;
procedure add_stoptheme (stoplist_name in varchar2,
               stoptheme in varchar2)
is

begin

if stoplist_name like '%.%' then
 ctx_ddl.add_stoptheme(stoplist_name, stoptheme);
else
 ctx_ddl.add_stoptheme( v_context||'.'||stoplist_name, stoptheme);
end if;
end add_stoptheme;
procedure add_stopword (stoplist_name in varchar2,
              stopword in varchar2,
              language in varchar2 default null)
is

begin

 if stoplist_name like '%.%' then
  ctx_ddl.add_stopword(stoplist_name, stopword, language);
 else
  ctx_ddl.add_stopword( v_context||'.'||stoplist_name, stopword, language);
 end if;
end  add_stopword;
procedure add_stop_section (group_name in varchar2,
                  tag in varchar2)
is

begin

if group_name like '%.%' then
  ctx_ddl.add_stop_section(group_name, tag);
else
  ctx_ddl.add_stop_section( v_context||'.'||group_name, tag);
 end if;
end  add_stop_section;
procedure add_sub_lexer (lexer_name in varchar2,
                         language in varchar2,
                         sub_lexer in varchar2,
                         alt_value in varchar2 default null)
is

   v_sublexer  varchar2(50);
begin

v_sublexer := v_context||'.'||sub_lexer;
if lexer_name like '%.%' or sub_lexer like '%.%' then
 ctx_ddl.add_sub_lexer(lexer_name, language, sub_lexer, alt_value);
else
 ctx_ddl.add_sub_lexer( v_context||'.'||lexer_name, language, v_sublexer, alt_value);
 end if;
end  add_sub_lexer;
procedure add_zone_section (group_name in varchar2,
                  section_name in varchar2,
                  tag in varchar2)
is

begin

if group_name like '%.%' then
 ctx_ddl.add_zone_section(group_name, section_name, tag);
else
 ctx_ddl.add_zone_section( v_context||'.'||group_name, section_name, tag);
end if;
end  add_zone_section;
procedure create_index_set (set_name in varchar2)
is

begin

if set_name like '%.%' then
 ctx_ddl.create_index_set(set_name);
else
 ctx_ddl.create_index_set( v_context||'.'||set_name);
end if;
end  create_index_set;
procedure create_preference (preference_name in varchar2,
                   object_name in varchar2)
is

begin

if preference_name like '%.%' then
  ctx_ddl.create_preference(preference_name, object_name);
else
 ctx_ddl.create_preference(v_context||'.'||preference_name, object_name);
end if;
end  create_preference;
procedure create_section_group (group_name in varchar2,
                     group_type in varchar2)
is

begin

if group_name like '%.%' then
  ctx_ddl.create_section_group(group_name, group_type);
 else
  ctx_ddl.create_section_group( v_context||'.'||group_name, group_type);
 end if;
end  create_section_group;
procedure create_stoplist (stoplist_name in varchar2,
stoplist_type in varchar2 default 'BASIC_STOPLIST')
is

begin

if stoplist_name like '%.%' then
 ctx_ddl.create_stoplist(stoplist_name, stoplist_type);
else
 ctx_ddl.create_stoplist( v_context||'.'||stoplist_name, stoplist_type);
end if;
end  create_stoplist;
procedure drop_index_set (set_name in varchar2)
is

begin
if set_name like '%.%' then
  ctx_ddl.drop_index_set(set_name);
else
  ctx_ddl.drop_index_set( v_context||'.'||set_name);
end if;
end  drop_index_set;
procedure drop_preference (preference_name in varchar2)
is

begin

if preference_name like '%.%' then
  ctx_ddl.drop_preference(preference_name);
else
 ctx_ddl.drop_preference(v_context||'.'||preference_name);
end if;
end drop_preference;
procedure drop_section_group (group_name in varchar2)
is

begin
if group_name like '%.%' then
 ctx_ddl.drop_section_group(group_name);
else
 ctx_ddl.drop_section_group( v_context||'.'||group_name);
end if;
end  drop_section_group;
procedure drop_stoplist (stoplist_name in varchar2)
is

begin

 if stoplist_name like '%.%' then
  ctx_ddl.drop_stoplist(stoplist_name);
 else
   ctx_ddl.drop_stoplist( v_context||'.'||stoplist_name);
end if;
end  drop_stoplist;
procedure optimize_index (idx_name in varchar2,
                          optlevel in varchar2,
                          maxtime in number default null,
                          token in varchar2 default null,  parallel_degree in number default 1)
is

begin

if idx_name like '%.%' then
  ctx_ddl.optimize_index(idx_name, optlevel, maxtime, token,  PARALLEL_DEGREE => parallel_degree);
else
  ctx_ddl.optimize_index( v_context||'.'||idx_name, optlevel, maxtime,  token, PARALLEL_DEGREE => parallel_degree);
 end if;
end  optimize_index;
procedure remove_index (set_name in varchar2,
                        column_list in varchar2)
is
begin
if set_name like '%.%' then
 ctx_ddl.remove_index(set_name, column_list);
 else
 ctx_ddl.remove_index( v_context||'.'||set_name, column_list);
end if;
end  remove_index;
procedure remove_section (group_name in varchar2,
             section_name in varchar2)
is

begin

if group_name like '%.%' then
  ctx_ddl.remove_section(group_name, section_name);
else
  ctx_ddl.remove_section( v_context||'.'||group_name, section_name);
 end if;
end  remove_section;
procedure remove_section (group_name in varchar2,
              section_id in number)
is

begin

if group_name like '%.%' then
  ctx_ddl.remove_section(group_name, section_id);
else
  ctx_ddl.remove_section( v_context||'.'||group_name, section_id);
end if;
end  remove_section;
procedure remove_stopclass (stoplist_name in varchar2,
               stopclass in varchar2)
is

begin

 if stoplist_name like '%.%' then
 ctx_ddl.remove_stopclass(stoplist_name, stopclass);
 else
 ctx_ddl.remove_stopclass( v_context||'.'||stoplist_name, stopclass);
 end if;
end  remove_stopclass;
procedure remove_stoptheme (stoplist_name in varchar2,
               stoptheme in varchar2)
is

begin

if stoplist_name like '%.%' then
  ctx_ddl.remove_stoptheme(stoplist_name, stoptheme);
else
  ctx_ddl.remove_stoptheme( v_context||'.'||stoplist_name, stoptheme);
end if;
end  remove_stoptheme;
procedure remove_stopword (stoplist_name in varchar2,
               stopword in varchar2,
               language in varchar2 default null)
is

begin

if stoplist_name like '%.%' then
 ctx_ddl.remove_stopword(stoplist_name, stopword, language);
else
 ctx_ddl.remove_stopword( v_context||'.'||stoplist_name, stopword, language);
 end if;
end  remove_stopword;
procedure remove_sub_lexer (lexer_name in varchar2,
               language in varchar2)
is

begin

if lexer_name like '%.%' then
 ctx_ddl.remove_sub_lexer(lexer_name, language);
 else
 ctx_ddl.remove_sub_lexer( v_context||'.'||lexer_name, language);
end if;
end  remove_sub_lexer;
procedure set_attribute (preference_name in varchar2,
       attribute_name in varchar2,
       attribute_value in varchar2)
is

begin
if preference_name like '%.%' then
 ctx_ddl.set_attribute(preference_name, attribute_name, attribute_value);
else
 ctx_ddl.set_attribute(v_context||'.'||preference_name, attribute_name, attribute_value);
end if;
end  set_attribute;
procedure sync_index (idx_name in varchar2 default null, parallel_degree in number default 1)
is

begin

if idx_name like '%.%' then
  ctx_ddl.sync_index(idx_name, PARALLEL_DEGREE => parallel_degree);
 else
  ctx_ddl.sync_index( v_context||'.'||idx_name, PARALLEL_DEGREE => parallel_degree);
end if;
end  sync_index;
procedure unset_attribute (preference_name in varchar2,
       attribute_name in varchar2)
is
begin

if preference_name like '%.%' then
 ctx_ddl.unset_attribute(preference_name, attribute_name);
else
 ctx_ddl.unset_attribute( v_context||'.'||preference_name, attribute_name);
end if;
end  unset_attribute;
procedure set_effective_schema(user_schema in varchar2)
 is
 begin
 v_context := upper(user_schema);
 end set_effective_schema;
procedure add_sdata_section(group_name in varchar2,
               section_name in varchar2,
               tag in varchar2,
               datatype in varchar2 default null)
is
begin

 if group_name like '%.%' then
   ctx_ddl.add_sdata_section(group_name, section_name, tag, datatype);
else
   ctx_ddl.add_sdata_section( v_context||'.'||group_name, section_name, tag, datatype);
 end if;
 end  add_sdata_section;
end AD_CTX_DDL;

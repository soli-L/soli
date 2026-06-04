
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_AW_LOADER" AUTHID CURRENT_USER as
/* $Header: adawld9is.pls 120.0 2005/05/25 11:50:15 appldev noship $ */

type DIM_VALUES is table of VARCHAR2(32) index by BINARY_INTEGER;
type PROP_VALUES is table of VARCHAR2(32) index by VARCHAR2(32);

procedure ATTACH_AW(p_schema in varchar2,
                    p_aw     in varchar2);

procedure CREATE_OBJECT(p_object_name       in varchar2,
                        p_object_type       in varchar2,
                        p_object_attributes in varchar2,
                        p_object_ld         in varchar2);

procedure DELETE_OBJECT(p_object_name	in varchar2);

procedure LOAD_DIMENSION_INT(p_dimension_size in number);

procedure LOAD_DIMENSION_VALUES(p_dimension_values in DIM_VALUES);

procedure LOAD_FORMULA(p_formula in varchar2);

procedure LOAD_MODEL(p_model in varchar2);

procedure LOAD_PROGRAM(p_program in CLOB);

procedure LOAD_PROPERTIES(p_properties in PROP_VALUES);

procedure LOAD_VALUESET(p_dimension_values in DIM_VALUES);

procedure UPDATE_AW;

end AD_AW_LOADER;
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_AW_LOADER" as
/* $Header: adawld9ib.pls 120.0 2005/05/25 12:01:49 appldev noship $ */

m_ascii_nl number;
m_curr_obj varchar2(32);

function CALL_AW(p_cmd in varchar2) return varchar2
   is
      l_clob   clob;
      l_return varchar2(4000);
      l_pos    number          := 1;
begin
   l_clob := dbms_aw.interp (p_cmd);
   l_return := dbms_lob.substr(l_clob);

   if (l_return is null or length (l_return) = 0) then
      return l_return;
   end if;
   loop
      if (ascii (substr (l_return, l_pos)) = m_ascii_nl) then
         l_pos := l_pos + 1;
       else
         exit;
      end if;
   end loop;
   return substr (l_return, l_pos);
end CALL_AW;

procedure ATTACH_AW(p_schema in varchar2,
                    p_aw     in varchar2)
   is
      l_ret  varchar2(16);
      l_aw   varchar2(32);
begin
   l_aw := p_schema||'.'||p_aw;
   dbms_aw.execute ('awwaittime = 200');
   if (upper (CALL_AW('shw aw (attached '''||p_aw||''')')) = 'YES' and
       upper(CALL_AW('shw aw (rw '''||p_aw||''')')) = 'NO') then
      dbms_aw.execute ('aw detach '||p_aw);
   end if;
   if (upper (CALL_AW('shw aw (attached '''||p_aw||''')')) <> 'YES') then
      dbms_aw.execute ('aw attach '||l_aw||' rw wait');
   end if;
end ATTACH_AW;

procedure CREATE_OBJECT(p_object_name       in varchar2,
                        p_object_type       in varchar2,
                        p_object_attributes in varchar2,
                        p_object_ld         in varchar2)
   is
      l_ret   varchar2(16);
begin
   if (upper (CALL_AW('shw exists ('''||p_object_name||''')')) = 'YES') then
      if (p_object_type = 'DIMENSION') then
         dbms_aw.execute ('cns '||p_object_name);
         dbms_aw.execute ('property delete all');
       else
         dbms_aw.execute ('dlt '||p_object_name);
         dbms_aw.execute ('dfn '||p_object_name||' '||p_object_type||' '||
                          p_object_attributes);
      end if;
    else
      dbms_aw.execute ('dfn '||p_object_name||' '||p_object_type||' '||
                       p_object_attributes);
   end if;
   dbms_aw.execute ('ld '||p_object_ld);
   m_curr_obj := p_object_name;
end CREATE_OBJECT;

procedure DELETE_OBJECT(p_object_name   in varchar2)
        is
begin
        if(upper (CALL_AW('shw exists ('''||p_object_name||''')')) = 'YES') then
                dbms_aw.execute('delete ' || p_object_name);
        end if;
end DELETE_OBJECT;

procedure LOAD_DIMENSION_INT(p_dimension_size in number)
   is
      l_size  number;
      l_diff  number;
begin
   l_size := to_number(CALL_AW('shw obj(dimmax '''||m_curr_obj||''')'));
   if (l_size < p_dimension_size) then
      dbms_aw.execute('mnt '||m_curr_obj||' add '||
                      (p_dimension_size - l_size));
    elsif (l_size > p_dimension_size) then
      dbms_aw.execute('mnt '||m_curr_obj||' delete last '||
                      (l_size - p_dimension_size));
   end if;
end LOAD_DIMENSION_INT;

procedure LOAD_DIMENSION_VALUES(p_dimension_values in DIM_VALUES)
   is
      i       number := 0;
      l_value varchar2(32);
      l_size  number;
begin
   loop
      if not p_dimension_values.exists(i) then
         exit;
      end if;
      l_value := p_dimension_values(i);


    --  If not a conjoint, add surrounding parenthesis:

      if (instr (l_value, '<') <> 1) then
         l_value := ''''||l_value||'''';
      end if;

      if (upper (CALL_AW ('shw isvalue ('||m_curr_obj||' '||l_value||')'))
          = 'NO') then
         dbms_aw.execute ('mnt '||m_curr_obj||' add '||l_value||'');
      end if;
      dbms_aw.execute('mnt '||m_curr_obj||' move '||l_value||' after '||i);
      i := i + 1;
   end loop;


   --  Remove extra entries:

   l_size := to_number(CALL_AW ('shw obj(dimmax '''||m_curr_obj||''')'));
   if (l_size > i) then
      dbms_aw.execute ('lmt '||m_curr_obj||' to last '||(l_size - i));
      dbms_aw.execute ('mnt '||m_curr_obj||' delete values('||m_curr_obj||')');
   end if;

end LOAD_DIMENSION_VALUES;

procedure LOAD_FORMULA(p_formula in varchar2)
   is
begin
   dbms_aw.execute ('cns '||m_curr_obj);
   dbms_aw.execute('eq '||p_formula);
end LOAD_FORMULA;

procedure LOAD_MODEL(p_model in varchar2)
   is
begin
   dbms_aw.execute ('cns '||m_curr_obj);
   dbms_aw.execute('model;'||p_model||';end');
end LOAD_MODEL;

procedure LOAD_PROGRAM(p_program in CLOB)
   is
      templob CLOB;
begin
   templob := 'program;';
   dbms_aw.execute ('cns '||m_curr_obj);
   dbms_lob.append(templob, p_program);
   dbms_lob.append(templob, ';end');
   templob := dbms_aw.interpclob(templob);
end LOAD_PROGRAM;

procedure LOAD_PROPERTIES(p_properties in PROP_VALUES)
   is
      l_key varchar2(32);
begin
   dbms_aw.execute ('cns '||m_curr_obj);
   l_key := p_properties.FIRST;
   while (l_key is not null)
   loop
      dbms_aw.execute('prp '''||l_key||''' '||p_properties(l_key));
      l_key := p_properties.NEXT(l_key);
   end loop;
end LOAD_PROPERTIES;

procedure LOAD_VALUESET(p_dimension_values in DIM_VALUES)
   is
      i       number := 0;
      l_value varchar2(32);
      l_size  number;
begin
   dbms_aw.execute('lmt '||m_curr_obj||' to null');
   loop
      if not p_dimension_values.exists(i) then
         exit;
      end if;
      l_value := p_dimension_values(i);
      dbms_aw.execute('lmt '||m_curr_obj||' add '||l_value);
      i := i + 1;
   end loop;

end LOAD_VALUESET;

procedure UPDATE_AW
   is
begin
   dbms_aw.execute ('upd');
end UPDATE_AW;
begin
  m_ascii_nl := ascii(fnd_global.local_chr(10));
end AD_AW_LOADER;
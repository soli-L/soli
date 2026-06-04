
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_VERSION_UTIL" AUTHID CURRENT_USER as
-- $Header: aduvers.pls 115.7 2004/06/01 10:55:40 sallamse ship $

  function validate_patch_level
            (p_patch_level       in         varchar2,
             p_product_shortname in         varchar2,
             p_error_msg         out nocopy varchar2)
   return boolean;

  procedure get_product_patch_level
             (p_appl_id      in         number,
              p_patch_level  out nocopy varchar2);

  procedure get_product_patch_level
             (p_appl_shortname in         varchar2,
              p_patch_level    out nocopy varchar2);

  procedure set_product_patch_level
             (p_appl_shortname  in varchar2,
              p_patchset_name   in varchar2,
              p_force_flag      in varchar2);

  procedure set_product_patch_level
             (p_appl_shortname  in varchar2,
              p_patchset_name   in varchar2);

  procedure get_patch_level_details
             (p_patch_level    in         varchar2,
              p_base_release   out nocopy varchar2,
              p_appl_shortname out nocopy varchar2,
              p_patchset_name  out nocopy varchar2);

  procedure get_patch_level_details
             (p_patch_level       in         varchar2,
              p_base_release      out nocopy varchar2,
              p_appl_shortname    out nocopy varchar2,
              p_patchset_name     out nocopy varchar2,
              p_patchset_revision out nocopy varchar2);

end;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_VERSION_UTIL" as
-- $Header: aduverb.pls 120.2 2006/08/25 18:33:12 vlim noship $

  --
  -- constant values used when comparing two patchset names
  --

  PATCH_LEVEL_SAME    CONSTANT integer := 0;
  PATCH_LEVEL1_HIGHER CONSTANT integer := -1;
  PATCH_LEVEL2_HIGHER CONSTANT integer := 1;

  VERCOMP_SEPARATOR   CONSTANT varchar2(1) := '.';

  --
  -- Function to get base release name. This name will be used when
  -- contructing patch level name for a product.
  --

function get_base_release
 return varchar2
is
  begin
     return('R12');
  end;

  --
  -- Return product abbreviation given a product shortname
  --
  -- Raises an exception if the product shortname is not found in
  -- FND_APPLICATION table
  --

function get_appl_abbr
          (p_appl_shortname in varchar2)
 return varchar2
is
    l_dummy varchar2(1);
  begin

      --
      -- first check if this is a valid application
      --

      begin
         select null
         into   l_dummy
         from   fnd_application
         where  application_short_name = upper(p_appl_shortname);
      exception
         when NO_DATA_FOUND then
           raise_application_error(-20001,
             'Invalid application shortname : '||p_appl_shortname);
      end;

      if    (p_appl_shortname = 'SQLAP') then
         return('AP');
      elsif (p_appl_shortname = 'SQLGL') then
         return('GL');
      elsif (p_appl_shortname = 'OFA') then
         return('FA');
      else
         return(p_appl_shortname);
      end if;
  end;

  function get_appl_id
            (p_appl_sn in varchar2) return number
  is
   l_appl_id number;
  begin
    select application_id
    into   l_appl_id
    from   fnd_application
    where  application_short_name = upper(p_appl_sn);

    return(l_appl_id);
  end;

  --
  -- function to check the validity of a patch level
  --
  -- The patch level is of the form
  --    [<BASE RELEASE>.<PRODUCT>.<PATCHSET NAME>]{.<REVISION>}
  --

  function validate_patch_level
            (p_patch_level       in         varchar2,
             p_product_shortname in         varchar2,
             p_error_msg         out nocopy varchar2)
   return boolean
  is
    l_patch_base              varchar2(30);
    l_patch_appl_shortname    varchar2(30);
    l_patch_patchset_name     varchar2(30);
    l_patch_patchset_revision varchar2(30);
    l_patchset_revision       number;

    l_base_release         varchar2(30);
    l_appl_shortname       varchar2(30);
  begin
    get_patch_level_details(p_patch_level,
                            l_patch_base,
                            l_patch_appl_shortname,
                            l_patch_patchset_name,
                            l_patch_patchset_revision);

    l_base_release := get_base_release;

    if (nvl(l_patch_base, 'UNKNOWN') <> l_base_release) then
       p_error_msg := 'Incorrect base release "'||l_patch_base||'" found '||
                      'when expecting "'||l_base_release||'"';
       return(FALSE);
    end if;

    l_appl_shortname := get_appl_abbr(p_product_shortname);

    if (l_appl_shortname <> nvl(l_patch_appl_shortname, 'UNKNOWN')) then
       p_error_msg := 'Incorrect product abbreviation "'||
                      l_patch_appl_shortname||'" found '||
                      'when expecting "'||l_appl_shortname||'"';
       return(FALSE);
    end if;

    if (length(l_patch_patchset_name) <> 1
        or
        l_patch_patchset_name not between 'A' and 'Z') then
       p_error_msg := 'Incorrect patchset name "'||l_patch_patchset_name||
                      '". A patchset name must be a character between A to Z.';
       return(FALSE);
    end if;

    if (l_patch_patchset_revision is not null)
    then
       if (replace(translate(l_patch_patchset_revision,
                             '0123456789', ' '),
                   ' ', '') is not null)
       then
          p_error_msg := 'Incorrect patchset revision format "'||
                            l_patch_patchset_revision||
                      '". A patchset revision must be a number from 1 to 99.';
          return(FALSE);
       end if;

       if (not(to_number(l_patch_patchset_revision) between 1 and 99)) then
          p_error_msg := 'Incorrect patchset revision "'||
                            l_patch_patchset_revision||
                      '". A patchset revision must be a number from 1 to 99.';
          return(FALSE);
       end if;
    end if;

    return(TRUE);
  end;


  --
  -- Compares two patch levels
  --    returns 0 : patch levels are same
  --            1 : patch level 2 is higher than patch level 1
  --                or
  --                patch level 2 is not null and patch level 1 is null
  --           -1 : patch level 1 is higher than patch level 2
  --                or
  --                patch level 1 is not null and patch level 2 is null
  --

  function compare_patch_levels
            (p_level1 in varchar2,
             p_level2 in varchar2) return number
  is

    l_base1           varchar2(30);
    l_appl_shortname1 varchar2(30);
    l_patchset_name1  varchar2(30);
    l_patchset_rev1   varchar2(30);
    l_base2           varchar2(30);
    l_appl_shortname2 varchar2(30);
    l_patchset_name2  varchar2(30);
    l_patchset_rev2   varchar2(30);

  begin

    if    (upper(p_level1) = upper(p_level2)) then
       return(PATCH_LEVEL_SAME);
    end if;

    if (p_level1 is not null and p_level2 is null) then
       return(PATCH_LEVEL1_HIGHER);
    end if;

    if (p_level1 is null and p_level2 is not null) then
       return(PATCH_LEVEL2_HIGHER);
    end if;

    get_patch_level_details(p_level1,
                            l_base1, l_appl_shortname1, l_patchset_name1,
                            l_patchset_rev1);
    get_patch_level_details(p_level2,
                            l_base2, l_appl_shortname2, l_patchset_name2,
                            l_patchset_rev2);

    if (l_base1 <> l_base2) then
       raise_application_error(-20001,
           'The base release should be same when comparing patchset versions '||
           l_base1||' vs '||l_base2);
    end if;

    if (l_appl_shortname1 <> l_appl_shortname2) then
       raise_application_error(-20001,
           'The product should be same when comparing patchset versions '||
           l_appl_shortname1||' vs '||l_appl_shortname2);
    end if;

    if (l_patchset_name1 <> l_patchset_name2) then
       if (l_patchset_name1 > l_patchset_name2) then
                return(PATCH_LEVEL1_HIGHER);
       else
                return(PATCH_LEVEL2_HIGHER);
       end if;
    end if;

    if (nvl(l_patchset_rev1, -1) = nvl(l_patchset_rev2, -1)) then
       return(PATCH_LEVEL_SAME);
    end if;

    if (nvl(to_number(l_patchset_rev1), -1) >
          nvl(to_number(l_patchset_rev2), -1)) then
       return(PATCH_LEVEL1_HIGHER);
    else
       return(PATCH_LEVEL2_HIGHER);
    end if;

  end;

  --
  -- get current patch level from the database
  --
  -- this procedure returns NULL for patch levels
  -- that do not belong to the current base release;
  -- this procedure is only called within this package.
  -- (created to fix bugs 5376688 and 5484176)
  --

procedure get_product_patch_level_priv
           (p_appl_id      in         number,
            p_patch_level  out nocopy varchar2)
is
    l_patch_level varchar2(30);
  begin
    select patch_level
    into   l_patch_level
    from   fnd_product_installations
    where  application_id = p_appl_id
    and    install_group_num in (0, 1)
    and    rownum = 1;

    p_patch_level := l_patch_level;

    --
    -- return NULL if earlier releases
    --
    if (l_patch_level like '10.7%'
        or
        l_patch_level like '11.0%'
        or
        l_patch_level like '11i%')
    then
       p_patch_level := null;
    end if;
  end;

  --
  -- get current patch level from the database
  --
  -- this procedure returns NULL for patch levels
  -- that do not belong to the current base release;
  -- this procedure is only called within this package.
  -- (created to fix bugs 5376688 and 5484176)
  --

procedure get_product_patch_level_priv
           (p_appl_shortname in         varchar2,
            p_patch_level    out nocopy varchar2)
is
    l_appl_id     number;
    l_patch_level varchar2(30);
  begin

    l_appl_id := get_appl_id(p_appl_shortname);

    get_product_patch_level_priv(p_appl_id=>l_appl_id,
                                 p_patch_level=>p_patch_level);
  end;


  --
  -- get current patch level from the database
  --

procedure get_product_patch_level
           (p_appl_id      in         number,
            p_patch_level  out nocopy varchar2)
is
    l_patch_level varchar2(30);
  begin
    select patch_level
    into   l_patch_level
    from   fnd_product_installations
    where  application_id = p_appl_id
    and    install_group_num in (0, 1)
    and    rownum = 1;

    p_patch_level := l_patch_level;

    --
    -- return NULL if earlier releases
    --
    if (l_patch_level like '10.7%'
        or
        l_patch_level like '11.0%')
    then
       p_patch_level := null;
    end if;
  end;

  --
  -- get current patch level from the database
  --

procedure get_product_patch_level
           (p_appl_shortname in         varchar2,
            p_patch_level    out nocopy varchar2)
is
    l_appl_id     number;
    l_patch_level varchar2(30);
  begin

    l_appl_id := get_appl_id(p_appl_shortname);

    get_product_patch_level(p_appl_id=>l_appl_id,
                            p_patch_level=>p_patch_level);
  end;

  --
  -- construct patch level for a product
  --

procedure build_patch_level
           (p_appl_shortname    in         varchar2,
            p_patchset_name     in         varchar2,
            p_patchset_revision in         varchar2,
            p_patch_level       out nocopy varchar2)
is
  begin
     p_patch_level := get_base_release||VERCOMP_SEPARATOR||
                    get_appl_abbr(upper(p_appl_shortname))||VERCOMP_SEPARATOR||
                    upper(p_patchset_name);

     if (p_patchset_revision is not null) then
       p_patch_level := p_patch_level||VERCOMP_SEPARATOR||p_patchset_revision;
     end if;
  end;

  --
  -- update product row with patch level information, if the new
  -- patch level is higher
  --

-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)

procedure set_product_patch_level
           (p_appl_shortname in varchar2,
            p_patchset_name  in varchar2)
is
begin
  set_product_patch_level
             (p_appl_shortname => p_appl_shortname,
              p_patchset_name  => p_patchset_name ,
              p_force_flag     => 'N');
end;

procedure set_product_patch_level
           (p_appl_shortname in varchar2,
            p_patchset_name  in varchar2,
            p_force_flag     in varchar2)
is
    l_new_patch_level   varchar2(30);
    l_old_patch_level   varchar2(30);
    l_error_msg         varchar2(200);
    l_patchset_revision varchar2(30);
    l_patchset_name     varchar2(30);
    l_pos_first         number;
  begin

     --
     -- check to see if revision is specified along with the patchset name.
     -- if so, split it into individual components
     --
     l_pos_first := instr(p_patchset_name, VERCOMP_SEPARATOR);
     if (l_pos_first > 0) then
        l_patchset_name     := substr(p_patchset_name,
                                      1, (l_pos_first - 1));
        l_patchset_revision := substr(p_patchset_name,
                                      (l_pos_first+1));
     else
        l_patchset_name     := p_patchset_name;
        l_patchset_revision := null;
     end if;

     build_patch_level(p_appl_shortname, l_patchset_name,
                       l_patchset_revision, l_new_patch_level);

     if (validate_patch_level(l_new_patch_level,
                              p_appl_shortname, l_error_msg) = FALSE)
     then
        raise_application_error(-20001,
                                'Unable to build and validate patch version '||
                                'information. ('||l_error_msg||')');
     end if;

     get_product_patch_level_priv(p_appl_shortname, l_old_patch_level);

     if (l_old_patch_level is not null
         and
         validate_patch_level(l_old_patch_level,
                              p_appl_shortname, l_error_msg) = FALSE)
     then
        raise_application_error(-20001,
                                'Incorrect patch version "'||l_old_patch_level||
                                '" in database. ('||l_error_msg||')');
     end if;

     if (upper(p_force_flag) = 'Y'
         or
         (compare_patch_levels(l_old_patch_level,
                               l_new_patch_level) = PATCH_LEVEL2_HIGHER))
     then
        update fnd_product_installations
        set    patch_level = l_new_patch_level
        where  application_id in (
                    select application_id
                    from   fnd_application
                    where  application_short_name = upper(p_appl_shortname));
     end if;
  end;

  --
  -- get individual components of a patch level namely
  --        o  base release
  --        o  application abbreviation
  --        o  patchset name
  --

procedure get_patch_level_details
           (p_patch_level       in         varchar2,
            p_base_release      out nocopy varchar2,
            p_appl_shortname    out nocopy varchar2,
            p_patchset_name     out nocopy varchar2,
            p_patchset_revision out nocopy varchar2)
is
    l_pos_first  number;
    l_pos_second number;
    l_pos_third  number;
  begin

     p_base_release   := null;
     p_appl_shortname := null;
     p_patchset_name  := null;
     p_patchset_revision := null;

     if (p_patch_level is null) then
       return;
     end if;

     l_pos_first  := instr(p_patch_level, VERCOMP_SEPARATOR, 1, 1);
     l_pos_second := instr(p_patch_level, VERCOMP_SEPARATOR, 1, 2);
     l_pos_third  := instr(p_patch_level, VERCOMP_SEPARATOR, 1, 3);

     if (l_pos_first = 0) then
        --
        -- first seperator not found, use entire string as the
        -- first component
        --
        p_base_release := p_patch_level;
        return;
     else
        p_base_release := substr(p_patch_level, 1, l_pos_first - 1);
     end if;

     if (l_pos_second = 0) then
        --
        -- second seperator not found, use remaining string as the
        -- second component
        --
        p_appl_shortname := substr(p_patch_level, l_pos_first +1);
        return;
     else
        p_appl_shortname := substr(p_patch_level,
                                   l_pos_first +1,
                                   ((l_pos_second) - (l_pos_first+1)));
     end if;

     if (l_pos_third = 0) then
        --
        -- third seperator not found, use remaining string as the
        -- third component (patchset name)
        --
        p_patchset_name  := substr(p_patch_level,
                                   l_pos_second+1);
     else
        p_patchset_name  := substr(p_patch_level,
                                   l_pos_second +1,
                                   ((l_pos_third) - (l_pos_second+1)));
        p_patchset_revision := substr(p_patch_level,
                                      l_pos_third+1);

     end if;

  end;

procedure get_patch_level_details
           (p_patch_level    in         varchar2,
            p_base_release   out nocopy varchar2,
            p_appl_shortname out nocopy varchar2,
            p_patchset_name  out nocopy varchar2)
is
    l_patchset_revision varchar2(30);
  begin
    get_patch_level_details(p_patch_level,
                            p_base_release,
                            p_appl_shortname,
                            p_patchset_name,
                            l_patchset_revision);
  end;
end;

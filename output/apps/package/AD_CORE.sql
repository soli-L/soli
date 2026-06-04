
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CORE" AUTHID CURRENT_USER as
/* $Header: aducores.pls 115.1 2003/05/22 19:01:12 kksingh noship $ */

-- Given an elapsed time in days (such as that returned by subtracting 2
-- dates in SQL), return the formatted value in Hrs/Mins/Secs.
--   Supported format_modes: 1, 2
--     1 => Always display hrs, min, secs
--       eg: 0.00030093 days is displayed as 0 Hrs, 0 Mins, 26 Secs
--     2 => Only display applicable units
--       eg: 0.00030093 days is displayed as 26 Secs

function get_formatted_elapsed_time
(
  p_ela_days number,
  p_format_mode number
) return varchar2;

pragma restrict_references (get_formatted_elapsed_time, wnds, rnds,
                                                        wnps, rnps);

end ad_core;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CORE" as
/* $Header: aducoreb.pls 115.3 2004/06/04 14:31:53 sallamse noship $ */


--
-- Private program units
--

--
--
-- Debug utils START
--
G_DEBUG constant boolean := FALSE;  --%%set to FALSE in production code

procedure put_line
           (msg varchar2, len number default 80)
is
  n number := 1;
  nmax number;
begin
  nmax := nvl(length(msg), 0);
  if not G_DEBUG then
    return;
  end if;

  loop
--  dbms_output.put_line(substr(msg, n, len)); --%%comment out in prodn code
    n := n + len;
    exit when n > nmax;
  end loop;
end put_line;
--
-- Debug utils END
--
--


--
-- Public program units
--


-- Given an elapsed time in days (such as that returned by subtracting 2
-- dates in SQL), return the formatted value in Hrs/Mins/Secs.
--   Supported format_modes: 1, 2
--     1 => Always display hrs, min, secs
--       eg: 0.00030093 days is displayed as 0 Hrs, 0 Mins, 26 Secs
--     2 => Only display applicable units
--       eg: 0.00030093 days is displayed as 26 Secs

function get_formatted_elapsed_time
(
  p_ela_days number,
  p_format_mode number
) return varchar2 is

  l_hrs    number := 0;
  l_mins   number := 0;
  l_secs   number := 0;

  l_days_i number := 0;   -- integral # of days
  l_hrs_i  number := 0;   -- integral # of total hrs
  l_mins_i number := 0;   -- integral # of mins within the hour
  l_secs_i number := 0;   -- integral # of secs within the min

  l_fmt_val varchar2(80) := null;  -- formatted value

begin
  if p_ela_days  is  NULL then  -- This is to check the value of p_ela_days, in case of SerialmodeAutopatchoptions and NoExecuted Actions where the value of p_ela_days will be null
 l_fmt_val := null;
 else

  l_days_i := floor(p_ela_days);

  l_hrs  := p_ela_days * 24; -- Total hrs. eg: 1 day, 1 hr, 1 min, 1 sec equals
                             -- 25.0169 hrs

  l_hrs_i  := floor(l_hrs);  -- Integral hrs: 25 hrs in the above eg.

  l_mins := (l_hrs - l_hrs_i) * 60;  -- Total mins within the hr: 1.014 mins in
                                     -- the above eg.

  l_mins_i := floor(l_mins);  -- Integral mins: 1 min in the above eg.

  l_secs := (l_mins - l_mins_i) * 60;  -- Total secs within the min: 0.84 secs
                                       -- in the eg.

  l_secs_i := round(l_secs);  -- Integral secs (rounded): 1 sec in the above eg


  if p_format_mode = 1 then

    -- Here the interest is in showing all components, even if 0. So it
    -- is assumed that we want the components aligned. Hence lpad the min
    -- and sec components to 2 places with 0's. Hr component is intentionally
    -- not lpadded, since we'd like that to stand out unaligned if >= 10 hrs
    -- (atleast thats what we'd like for the current sole consumer, viz. OAM
    -- patch history UI's)

    l_fmt_val := to_char(l_hrs_i)                || ' hr, '  ||
                 lpad(to_char(l_mins_i), 2, '0') || ' min, ' ||
                 lpad(to_char(l_secs_i), 2, '0') || ' sec';

  elsif p_format_mode = 2 then

    -- Here the interest is in showing only applicable components. So it
    -- is assumed that alignment is not needed. So DONT lpad.

    if l_hrs_i > 0 then
      l_fmt_val := to_char(l_hrs_i)  || ' hr, '  ||
                   to_char(l_mins_i) || ' min ';
                   --to_char(l_secs_i) || ' sec'; -- Decided not to show sec
    elsif l_mins_i > 0 then
      l_fmt_val := to_char(l_mins_i) || ' min, ' ||
                   to_char(l_secs_i) || ' sec';
    else
      l_fmt_val := to_char(l_secs_i) || ' sec';


    end if;

  else
    raise_application_error(-20000, 'Invalid format_mode: '||
                                    to_char(p_format_mode));
 end if;
end if;
  return l_fmt_val;

end get_formatted_elapsed_time;


end ad_core;

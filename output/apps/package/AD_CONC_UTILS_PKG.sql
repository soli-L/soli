
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CONC_UTILS_PKG" AUTHID CURRENT_USER AS
-- $Header: adcmutls.pls 115.0 2004/06/24 23:28:36 athies noship $


    CONC_SUCCESS   CONSTANT NUMBER := 0;
    CONC_WARNING   CONSTANT NUMBER := 1;
    CONC_FAIL      CONSTANT NUMBER := 2;

    --
    -- do not change the CHR(0) as FND_SUBMIT requires it.
    --
    PROCEDURE submit_subrequests(
        X_errbuf                   out nocopy varchar2,
        X_retcode                  out nocopy varchar2,
        X_WorkerConc_app_shortname  in varchar2,
        X_WorkerConc_progname       in varchar2,
        X_Batch_Size                in number,
        X_Num_Workers               in number,
        X_Argument4                 in varchar2 default null,
        X_Argument5                 in varchar2 default null,
        X_Argument6                 in varchar2 default null,
        X_Argument7                 in varchar2 default null,
        X_Argument8                 in varchar2 default null,
        X_Argument9                 in varchar2 default null,
        X_Argument10                in varchar2 default null);

END;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CONC_UTILS_PKG" AS
-- $Header: adcmutlb.pls 115.0 2004/06/24 23:28:27 athies noship $

PROCEDURE submit_subrequests(
        X_errbuf                   out nocopy varchar2,
        X_retcode                  out nocopy varchar2,
        X_WorkerConc_app_shortname  in varchar2,
        X_WorkerConc_progname       in varchar2,
        X_Batch_Size                in number,
        X_Num_Workers               in number,
        X_Argument4                 in varchar2 default null,
        X_Argument5                 in varchar2 default null,
        X_Argument6                 in varchar2 default null,
        X_Argument7                 in varchar2 default null,
        X_Argument8                 in varchar2 default null,
        X_Argument9                 in varchar2 default null,
        X_Argument10                in varchar2 default null)
    is
      L_errbuf   varchar2(2000);
      L_retcode  varchar2(1000);
    begin

      --
      -- this section is coded as dynamic SQL to avoid build and packaging
      -- dependencies on AOL code.

      EXECUTE IMMEDIATE
        ' declare '||
        '  req_status     number; '||
        '  req_data       varchar2(10); '||
        '  strt_wrkr      number; '||
        '  submit_req     boolean; '||
        '  l_batch_size   number  := :X_Batch_Size; '||
        '  l_num_workers  number  := :X_Num_Workers; '||
        '  L_SUB_REQTAB   fnd_concurrent.requests_tab_type; '||
        ''||
        ' begin '||
        ''||
        '   if (nvl(fnd_global.conc_request_id, -1) <  0) then '||
        '      raise_application_error(-20001, '||
        '''SUBMIT_SUBREQUESTS() must be called from a concurrent request'');'||
        '   end if;  '||
        ''||
        '   req_data := fnd_conc_global.request_data;  '||
        ''||
        '   if (req_data is null) then '||
        '      submit_req := TRUE; '||
        '   else '||
        '      submit_req := FALSE; '||
        '   end if; '||
        ''||
        '   if (submit_req = TRUE) then '||
        ''||
        '      FOR i in 1..l_num_workers LOOP '||
        ''||
        '         req_status := fnd_request.submit_request( '||
        '                       APPLICATION=>:X_WorkerConc_app_shortname, '||
        '                       PROGRAM=>:X_WorkerConc_app_progname, '||
        '                       DESCRIPTION=>'||
        '                        ''WRKR(''||lpad(i, 2, ''0'')||'')'', '||
        '                       SUB_REQUEST=>TRUE, '||
        '                       ARGUMENT1=>l_batch_size, '||
        '                       ARGUMENT2=>i, '||
        '                       ARGUMENT3=>l_num_workers, '||
        '                       ARGUMENT4=>nvl(:X_argument4,   chr(0)), '||
        '                       ARGUMENT5=>nvl(:X_argument5,   chr(0)), '||
        '                       ARGUMENT6=>nvl(:X_argument6,   chr(0)), '||
        '                       ARGUMENT7=>nvl(:X_argument7,   chr(0)), '||
        '                       ARGUMENT8=>nvl(:X_argument8,   chr(0)), '||
        '                       ARGUMENT9=>nvl(:X_argument9,   chr(0)), '||
        '                       ARGUMENT10=>nvl(:X_argument10, chr(0))); '||
        ''||
        '         if (req_status = 0) then '||
        ''||
        '            :L_errbuf    := fnd_message.get; '||
        '            :L_retcode := AD_CONC_UTILS_PKG.CONC_FAIL; '||
        '            return; '||
        ''||
        '         end if; '||
        ''||
        '      END LOOP; '||
        ''||
        '      fnd_conc_global.set_req_globals(conc_status=>''PAUSED'', '||
        '                                      request_data=>l_num_workers); '||
        ''||
        '      :L_errbuf    := ''Submitted sub-requests''; '||
        '      :L_retcode := 0; '||
        '      return; '||
        ''||
        '    else '||
        ''||
             --
             -- restart case
             --
        ''||
        '     l_sub_reqtab := fnd_concurrent.get_sub_requests( '||
        '                           fnd_global.conc_request_id); '||
        ''||
        '     :L_retcode := AD_CONC_UTILS_PKG.CONC_SUCCESS; '||
        ''||
        '     for i IN 1..l_sub_reqtab.COUNT() '||
        '     loop '||
        ''||
        '        if (l_sub_reqtab(i).dev_status != ''NORMAL'') then '||
        '           :L_retcode := AD_CONC_UTILS_PKG.CONC_FAIL; '||
        '        end if; '||
        ''||
        '     end loop; '||
        ''||
        '  end if; '||
        'end;' USING IN X_Batch_Size, X_Num_Workers,
                        X_WorkerConc_app_shortname, X_WorkerConc_progname,
                        X_Argument4, X_Argument5,
                        X_Argument6, X_Argument7,
                        X_Argument8, X_Argument9,
                        X_Argument10,
                    OUT L_errbuf, OUT l_retcode;

        X_errbuf := L_errbuf;
        X_retcode := L_retcode;

END submit_subrequests;

END;

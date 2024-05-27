declare
    l_serviceId varchar2(200);
    l_res CLOB;
    l_resCode varchar2(200);
    l_resMsg varchar2(200);
    l_trackingId varchar2(200);
begin
    begin
        PKG_MONO_MISCELLANEOUS.PRC_GET_IPLOOKUP (   in_ip              => '8.8.8.8',
                                                    in_apiKey          => '605b57e0bcmshd0886f7b374d8bap1c6921jsnddf8d33cbffb',
                                                    in_apiHost         => 'weatherapi-com.p.rapidapi.com',
                                                    out_trackingId     => l_trackingId,
                                                    out_serviceId      => l_serviceId,
                                                    out_res            => l_res,
                                                    out_resCode        => l_resCode,
                                                    out_resMsg         => l_resMsg);
    end;
    dbms_output.put_line('ServiceId : '||l_serviceId);
    dbms_output.put_line('TrackingId : '||l_trackingId);
    dbms_output.put_line('Res : '||l_res);
    dbms_output.put_line('ResCode : '||l_resCode);
    dbms_output.put_line('ResMsg : '||l_resMsg);
end;
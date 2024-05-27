create or replace PACKAGE           PKG_MONO_MISCELLANEOUS
IS
    PROCEDURE PRC_GLOBAL_LOGGING (
        in_serviceId      IN     VARCHAR2,
        in_oprName        IN     VARCHAR2,
        in_oprEndPoint    IN     VARCHAR2,
        in_oprReq         IN     VARCHAR2,
        in_oprRes         IN     VARCHAR2,
        in_channelName    IN     VARCHAR2,
        in_requestForm    IN     VARCHAR2,
        in_dbErrMessage   IN     VARCHAR2,
        in_errorMessage   IN     VARCHAR2,
        out_notifyFlag       OUT VARCHAR2,
        out_notifyMsg        OUT VARCHAR2);
        
    PROCEDURE PRC_GET_REALTIMEWEATHER (in_lat          IN     NUMBER,
                                       in_lon          IN     NUMBER,
                                       out_trackingId     OUT VARCHAR2,
                                       out_serviceId      OUT VARCHAR2,
                                       out_res            OUT CLOB,
                                       out_resCode        OUT VARCHAR2,
                                       out_resMsg         OUT VARCHAR2);
                                       
    PROCEDURE PRC_GET_IPLOOKUP (in_ip              IN     VARCHAR2,
                                in_apiKey          IN     VARCHAR2,
                                in_apiHost         IN     VARCHAR2,
                                out_trackingId     OUT VARCHAR2,
                                out_serviceId      OUT VARCHAR2,
                                out_res            OUT CLOB,
                                out_resCode        OUT VARCHAR2,
                                out_resMsg         OUT VARCHAR2);
END;
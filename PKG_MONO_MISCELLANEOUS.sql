--------------------------------------------------------
--  File created - Tuesday-May-21-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package PKG_MONO_MISCELLANEOUS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "DATACORE"."PKG_MONO_MISCELLANEOUS" 
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
                                       out_serviceId      OUT VARCHAR2,
                                       out_res            OUT CLOB,
                                       out_resCode        OUT VARCHAR2,
                                       out_resMsg         OUT VARCHAR2);
END;

/

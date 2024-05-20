--------------------------------------------------------
--  File created - Tuesday-May-21-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body PKG_MONO_MISCELLANEOUS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DATACORE"."PKG_MONO_MISCELLANEOUS" 
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
        out_notifyMsg        OUT VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_runtimeException   EXCEPTION;
        l_logId              DATACORE.GLOBAL_LOGGING.LOG_ID%TYPE;
    BEGIN
        out_notifyFlag := 'S';

        BEGIN
            BEGIN 
                l_logId := DATACORE.SEQ_LOGID.NEXTVAL;
                INSERT INTO DATACORE.GLOBAL_LOGGING (LOG_ID,
                                                    SERVICE_ID,
                                                    OPR_NAME,
                                                    OPR_ENDPOINT,
                                                    OPR_REQ,
                                                    OPR_RES,
                                                    REQUEST_FROM,
                                                    ISSUE_DATE,
                                                    DB_ERROR_MSG,
                                                    ERROR_MSG)
                     VALUES (l_logId,
                             in_serviceId,
                             in_oprName,
                             in_oprEndPoint,
                             in_oprReq,
                             in_oprRes,
                             in_requestForm,
                             SYSDATE,
                             in_dbErrMessage,
                             in_errorMessage);
            EXCEPTION
                WHEN OTHERS
                THEN
                    out_notifyMsg := 'Global Error Log Gen. Problem.';
                    RAISE l_runtimeException;
            END;
            
            COMMIT;
        END;
    EXCEPTION
        WHEN l_runtimeException
        THEN
            out_notifyFlag := 'F';
            COMMIT;
    END;
    
    PROCEDURE PRC_GET_REALTIMEWEATHER (in_lat          IN     NUMBER,
                                       in_lon          IN     NUMBER,
                                       out_serviceId      OUT VARCHAR2,
                                       out_res            OUT CLOB,
                                       out_resCode        OUT VARCHAR2,
                                       out_resMsg         OUT VARCHAR2)
    AS
        l_runtimeException   EXCEPTION;
        l_req                UTL_HTTP.REQ;
        l_resp               UTL_HTTP.RESP;
        l_resCode            VARCHAR2 (10);
        l_resMsg             VARCHAR2 (1024);
        l_proto              VARCHAR2 (4) := 'http';
        l_httpVerb           VARCHAR2 (3) := 'GET';
        l_httpCode           NUMBER;
        l_httpResp           CLOB;
        l_notifyFlag         VARCHAR2 (1);
        l_notifyMsg          VARCHAR2 (1024);
        l_loggingPayload     VARCHAR2(1024);
        l_ip                 VARCHAR2 (20) := '192.168.0.108';
        l_port               VARCHAR2 (4) := '9000';
        l_endPoint           VARCHAR2 (1024) := '/miscellaneous/checkWeatherReport';
        l_url                DATACORE.GLOBAL_LOGGING.OPR_ENDPOINT%TYPE;
        l_logId              DATACORE.GLOBAL_LOGGING.LOG_ID%TYPE;
        l_trackingId         DATACORE.GLOBAL_LOGGING.SERVICE_ID%TYPE;
    BEGIN
        l_url := l_proto || '://' || l_ip || ':' || l_port || l_endPoint || '?lat=' || in_lat || '&lon=' || in_lon;
        l_trackingId := 'TRK' || TO_CHAR(DATACORE.SEQ_TRACKING_ID.NEXTVAL, 'FM000000');
        
        -- Write Request log START
        BEGIN
            l_loggingPayload := JSON_OBJECT('lat' VALUE in_lat, 'lon' VALUE in_lon);
            
            DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                in_oprName        => 'GET_REALTIMEWEATHER',
                                                                in_oprEndPoint    => l_url,
                                                                in_oprReq         => l_loggingPayload,
                                                                in_oprRes         => '',
                                                                in_channelName    => 'RAPID_API',
                                                                in_requestForm    => 'WEB',
                                                                in_dbErrMessage   => NULL,
                                                                in_errorMessage   => NULL,
                                                                out_notifyFlag    => l_notifyFlag,
                                                                out_notifyMsg     => l_notifyMsg
                                                            );
        EXCEPTION
            WHEN OTHERS
            THEN
                l_resCode := '999';
                l_resMsg := SQLERRM;
                RAISE l_runtimeException;
        END;
        IF l_notifyFlag = 'F'
        THEN
            l_resCode := '999';
            l_resMsg := SQLERRM;
            RAISE l_runtimeException;
        END IF;
        -- Write Request log END
        
        -- Consuming REST api START
        BEGIN
            l_req := UTL_HTTP.BEGIN_REQUEST (l_url, l_httpVerb);
            l_resp := UTL_HTTP.GET_RESPONSE (l_req);
            l_httpCode := l_resp.status_code;
            l_httpResp := l_resp.reason_phrase;
            UTL_HTTP.READ_TEXT (l_resp, out_res);
            UTL_HTTP.END_RESPONSE (l_resp);

            IF l_httpCode = 200
            THEN
                NULL;
            ELSE
                NULL;
            END IF;


        EXCEPTION
            WHEN OTHERS
            THEN
                l_resCode := '999';
                l_resMsg := SQLERRM;
                UTL_HTTP.END_RESPONSE (l_resp);
                
                -- Write Error Response log START
                BEGIN
                    l_loggingPayload := JSON_OBJECT('lat' VALUE in_lat, 'lon' VALUE in_lon);
                    
                    DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                        in_oprName        => 'GET_REALTIMEWEATHER',
                                                                        in_oprEndPoint    => l_url,
                                                                        in_oprReq         => l_loggingPayload,
                                                                        in_oprRes         => l_httpResp,
                                                                        in_channelName    => 'RAPID_API',
                                                                        in_requestForm    => 'WEB',
                                                                        in_dbErrMessage   => l_resMsg,
                                                                        in_errorMessage   => 'downstream error',
                                                                        out_notifyFlag    => l_notifyFlag,
                                                                        out_notifyMsg     => l_notifyMsg
                                                                    );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_resCode := '999';
                        l_resMsg := SQLERRM;
                        RAISE l_runtimeException;
                END;
                IF l_notifyFlag = 'F'
                THEN
                    l_resCode := '999';
                    l_resMsg := SQLERRM;
                    RAISE l_runtimeException;
                END IF;
                -- Write Error Response log END
                
                RAISE l_runtimeException;
        END;
        -- Consuming REST api END
        
        -- Write Response log START
        BEGIN
            l_loggingPayload := JSON_OBJECT('lat' VALUE in_lat, 'lon' VALUE in_lon);
            
            DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                in_oprName        => 'GET_REALTIMEWEATHER',
                                                                in_oprEndPoint    => l_url,
                                                                in_oprReq         => l_loggingPayload,
                                                                in_oprRes         => l_httpResp,
                                                                in_channelName    => 'RAPID_API',
                                                                in_requestForm    => 'WEB',
                                                                in_dbErrMessage   => NULL,
                                                                in_errorMessage   => NULL,
                                                                out_notifyFlag    => l_notifyFlag,
                                                                out_notifyMsg     => l_notifyMsg
                                                            );
        EXCEPTION
            WHEN OTHERS
            THEN
                l_resCode := '999';
                l_resMsg := SQLERRM;
                RAISE l_runtimeException;
        END;
        IF l_notifyFlag = 'F'
        THEN
            l_resCode := '999';
            l_resMsg := SQLERRM;
            RAISE l_runtimeException;
        END IF;
        -- Write Response log END
        
    EXCEPTION
        WHEN l_runtimeException
        THEN
            out_resCode := l_resCode;
            out_resMsg := l_resMsg;
            out_serviceId := l_trackingId;
    END PRC_GET_REALTIMEWEATHER;
END;

/

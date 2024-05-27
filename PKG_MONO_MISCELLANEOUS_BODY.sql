create or replace PACKAGE BODY          PKG_MONO_MISCELLANEOUS
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
                                       out_trackingId     OUT VARCHAR2,
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
        l_ip                 VARCHAR2 (20) := '192.168.0.110';
        l_port               VARCHAR2 (4) := '9000';
        l_endPoint           VARCHAR2 (1024) := '/miscellaneous/v1/checkWeatherReport';
        l_url                DATACORE.GLOBAL_LOGGING.OPR_ENDPOINT%TYPE;
        l_logId              DATACORE.GLOBAL_LOGGING.LOG_ID%TYPE;
        l_trackingId         DATACORE.GLOBAL_LOGGING.SERVICE_ID%TYPE;
        l_json_obj           JSON_OBJECT_T;
    BEGIN
        l_url := l_proto || '://' || l_ip || ':' || l_port || l_endPoint || '?lat=' || in_lat || '&lon=' || in_lon;
        l_trackingId := 'TRK' || TO_CHAR(DATACORE.SEQ_TRACKING_ID.NEXTVAL, 'FM000000');
        l_loggingPayload := JSON_OBJECT('lat' VALUE in_lat, 'lon' VALUE in_lon);
        
        -- Write Request log START
        BEGIN
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
                l_json_obj    := JSON_OBJECT_T.parse(out_res);
                out_resCode   := l_json_obj.get_string('responseCode');
                out_resMsg    := l_json_obj.get_string('responseMsg');
                out_serviceId := l_json_obj.get_string('correlationId');
            END IF;


        EXCEPTION
            WHEN OTHERS
            THEN
                l_resCode := '999';
                l_resMsg := SQLERRM;
                UTL_HTTP.END_RESPONSE (l_resp);
                
                -- Write Error Response log START
                BEGIN
                    DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                        in_oprName        => 'GET_REALTIMEWEATHER',
                                                                        in_oprEndPoint    => l_url,
                                                                        in_oprReq         => l_loggingPayload,
                                                                        in_oprRes         => out_res,
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
            DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                in_oprName        => 'GET_REALTIMEWEATHER',
                                                                in_oprEndPoint    => l_url,
                                                                in_oprReq         => l_loggingPayload,
                                                                in_oprRes         => out_res,
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
    
        out_trackingId := l_trackingId;
    EXCEPTION
        WHEN l_runtimeException
        THEN
            out_resCode := l_resCode;
            out_resMsg := l_resMsg;
            out_serviceId := l_json_obj.get_string('correlationId');
            out_trackingId := l_trackingId;
    END PRC_GET_REALTIMEWEATHER;
    
    PROCEDURE PRC_GET_IPLOOKUP (in_ip              IN     VARCHAR2,
                                in_apiKey          IN     VARCHAR2,
                                in_apiHost         IN     VARCHAR2,
                                out_trackingId     OUT VARCHAR2,
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
        l_httpVerb           VARCHAR2 (4) := 'POST';
        l_httpCode           NUMBER;
        l_httpResp           CLOB;
        l_notifyFlag         VARCHAR2 (1);
        l_notifyMsg          VARCHAR2 (1024);
        l_loggingPayload     VARCHAR2(1024);
        l_payload            VARCHAR2(1024);
        l_ip                 VARCHAR2 (20) := '192.168.0.110';
        l_port               VARCHAR2 (4) := '9000';
        l_endPoint           VARCHAR2 (1024) := '/miscellaneous/v1/getIpLookUp';
        l_url                DATACORE.GLOBAL_LOGGING.OPR_ENDPOINT%TYPE;
        l_logId              DATACORE.GLOBAL_LOGGING.LOG_ID%TYPE;
        l_trackingId         DATACORE.GLOBAL_LOGGING.SERVICE_ID%TYPE;
        l_json_obj           JSON_OBJECT_T;
    BEGIN
        l_url := l_proto || '://' || l_ip || ':' || l_port || l_endPoint;
        l_trackingId := 'TRK' || TO_CHAR(DATACORE.SEQ_TRACKING_ID.NEXTVAL, 'FM000000');
        l_loggingPayload := JSON_OBJECT('ip' VALUE in_ip, 'apiKey' VALUE in_apiKey, 'apiHost' VALUE in_apiHost);
        -- Write Request log START
        BEGIN

            DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                in_oprName        => 'GET_IPLOOKUP',
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
            --UTL_HTTP.SET_TRANSFER_TIMEOUT (10);
            --UTL_HTTP.SET_WALLET ('file:/u01/wallets', 'Ab#123456');
            l_payload := JSON_OBJECT('ip' VALUE in_ip);
            l_req := UTL_HTTP.BEGIN_REQUEST (l_url, l_httpVerb);
            UTL_HTTP.SET_HEADER (l_req, 'content-type', 'application/json');
            UTL_HTTP.SET_HEADER (l_req, 'Content-Length', LENGTH (l_payload));
            UTL_HTTP.SET_HEADER (l_req, 'apiKey', in_apiKey);
            UTL_HTTP.SET_HEADER (l_req, 'apiHost', in_apiHost);
            UTL_HTTP.WRITE_TEXT (l_req, l_payload);
            l_resp := UTL_HTTP.GET_RESPONSE (l_req);
            l_httpCode := l_resp.status_code;
            UTL_HTTP.READ_TEXT (l_resp, out_res);
            UTL_HTTP.END_RESPONSE (l_resp);

            IF l_httpCode = 200
            THEN
                l_json_obj    := JSON_OBJECT_T.parse(out_res);
                out_resCode   := l_json_obj.get_string('responseCode');
                out_resMsg    := l_json_obj.get_string('responseMsg');
                out_serviceId := l_json_obj.get_string('correlationId');
            END IF;


        EXCEPTION
            WHEN OTHERS
            THEN
                l_resCode := '999';
                l_resMsg := SQLERRM;
                UTL_HTTP.END_RESPONSE (l_resp);
                
                -- Write Error Response log START
                BEGIN
                    DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                        in_oprName        => 'GET_IPLOOKUP',
                                                                        in_oprEndPoint    => l_url,
                                                                        in_oprReq         => l_loggingPayload,
                                                                        in_oprRes         => out_res,
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
            DATACORE.PKG_MONO_MISCELLANEOUS.PRC_GLOBAL_LOGGING (in_serviceId      => l_trackingId,
                                                                in_oprName        => 'GET_IPLOOKUP',
                                                                in_oprEndPoint    => l_url,
                                                                in_oprReq         => l_loggingPayload,
                                                                in_oprRes         => out_res,
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
    
        out_trackingId := l_trackingId;
    EXCEPTION
        WHEN l_runtimeException
        THEN
            out_resCode := l_resCode;
            out_resMsg := l_resMsg;
            out_serviceId := l_json_obj.get_string('correlationId');
            out_trackingId := l_trackingId;
    END PRC_GET_IPLOOKUP;
END;
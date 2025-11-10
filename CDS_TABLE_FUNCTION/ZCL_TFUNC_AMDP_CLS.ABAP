CLASS zcl_tfunc_amdp_cls DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES IF_AMDP_MARKER_HDB.

    TYPES: BEGIN OF TY_SCARR,
           MANDT TYPE S_MANDT,
           CARRID TYPE S_CARR_ID,
           CONNID TYPE S_CONN_ID,
           CARRNAME TYPE S_CARRNAME,
           URL TYPE S_CARRURL,
           END OF TY_SCARR .

    TYPES: TTY_SCARR TYPE TABLE OF TY_SCARR WITH EMPTY KEY.

    CLASS-METHODS:

    get_scarr_for_cds for TABLE FUNCTION ZPARAM_TFUNC.

    CLASS-METHODS:


    get_scarr_by_opensql
        importing
            value(p_mandt) type s_mandt
            value(p_carrid) type s_carr_id
            value(p_connid) type s_conn_id
        exporting
            value(et_scarr) type tty_scarr,



    get_carr_procedure1
        importing
            value(p_carrid) type s_carr_id
            value(p_connid) type s_conn_id
        exporting
            value(et_scarr) type tty_scarr,

    get_carr_procedure2
        importing
            value(p_string) type string
        EXPORTING
            value(et_scarr) type tty_scarr ,


    get_scarr_function1
        importing
            value(p_carrid) type s_carr_id
            value(p_connid) type s_conn_id
        returning
            value(et_scarr) type tty_scarr.



  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_tfunc_amdp_cls IMPLEMENTATION.

    METHOD get_scarr_for_cds BY DATABASE FUNCTION
                             FOR HDB
                             LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY
                             USING SFLIGHT SCARR .
        return
        select
            a.mandt,
            a.carrid,
            a.connid,
            b.carrname,
            b.url

            from sflight as a
            inner join scarr as b
            on a.mandt = b.mandt
            and a.carrid = b.carrid
            where a.mandt = :p_mandt
            and a.carrid = :p_carrid
            and a.connid = :p_connid;
    ENDMETHOD.

    METHOD get_scarr_by_opensql .
        SELECT A~MANDT,
               A~CARRID,
               A~CONNID,
               B~CARRNAME,
               B~URL

               FROM SFLIGHT AS A
               INNER JOIN SCARR AS B
               ON A~CARRID = B~CARRID
               WHERE A~CARRID = @P_CARRID
               AND A~CONNID = @P_CONNID
               INTO CORRESPONDING FIELDS OF TABLE @ET_SCARR .
    ENDMETHOD.

    METHOD get_carr_procedure1 BY DATABASE PROCEDURE
                               FOR HDB
                               LANGUAGE SQLSCRIPT
                               OPTIONS READ-ONLY
                               USING sflight scarr .
        et_scarr =
            SELECT A.MANDT,
                   A.CARRID,
                   A.CONNID,
                   B.CARRNAME,
                   B.URL
            FROM SFLIGHT AS A
            INNER JOIN SCARR AS B
            ON A.MANDT = B.MANDT
            AND A.CARRID = B.CARRID
            WHERE A.MANDT = SESSION_CONTEXT( 'CLIENT' )
            AND A.CARRID = :P_CARRID
            AND A.CONNID = :P_CONNID;

    ENDMETHOD.

    METHOD get_carr_procedure2 BY DATABASE PROCEDURE
                               FOR HDB
                               LANGUAGE SQLSCRIPT
                               OPTIONS READ-ONLY
                               USING SFLIGHT SCARR .
        LT_SCARR =
            SELECT A.MANDT,
                   A.CARRID,
                   A.CONNID,
                   B.CARRNAME,
                   B.URL
            FROM SFLIGHT AS A
            INNER JOIN SCARR AS B
            ON A.MANDT = B.MANDT
            AND A.CARRID = B.CARRID;

        ET_SCARR = APPLY_FILTER( :LT_SCARR, :P_STRING );
    ENDMETHOD.

    METHOD get_scarr_function1 BY DATABASE FUNCTION
                               FOR HDB
                               LANGUAGE SQLSCRIPT
                               OPTIONS READ-ONLY
                               USING SFLIGHT SCARR .
        RETURN
            SELECT A.MANDT,
                   A.CARRID,
                   A.CONNID,
                   B.CARRNAME,
                   B.URL
            FROM SFLIGHT AS A
            INNER JOIN SCARR AS B
            ON A.MANDT = B.MANDT
            AND A.CARRID = B.CARRID
            WHERE A.MANDT = SESSION_CONTEXT( 'CLIENT' )
            AND A.CARRID = :P_CARRID
            AND A.CONNID = :P_CONNID ;
    ENDMETHOD.



ENDCLASS.
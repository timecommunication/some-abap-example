METHOD convert_xstring_to_string.
    DATA: lv_length TYPE i,
          lt_binary TYPE STANDARD TABLE OF x255.
 
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = i_xstring
      IMPORTING
        output_length = lv_length
      TABLES
        binary_tab    = lt_binary.
 
    CALL FUNCTION 'SCMS_BINARY_TO_STRING'
      EXPORTING
        input_length = lv_length
      IMPORTING
        text_buffer  = e_string
      TABLES
        binary_tab   = lt_binary
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.
  ENDMETHOD.

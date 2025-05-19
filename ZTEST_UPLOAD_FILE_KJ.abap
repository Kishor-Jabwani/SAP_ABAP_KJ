*&---------------------------------------------------------------------*
*& Report ZTEST_UPLOAD_FILE_KJ
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_upload_file_kj.


* Data declarations
DATA: lt_excel_data TYPE TABLE OF fkkmaze, " Custom structure for Excel data
      lt_fieldcat TYPE lvc_t_fcat, " Field catalog for ALV
      lo_alv_grid TYPE REF TO cl_gui_alv_grid,
      lt_raw_data TYPE TABLE OF alsmex_tabline, " Raw data from Excel
      lv_filename TYPE string.

* Selection screen for file upload
PARAMETERS: p_file TYPE rlgrap-filename.

* F4 help for file selection
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f4_help_for_file_selection.

* Start-of-selection event
START-OF-SELECTION.

  " Upload Excel file
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = p_file
      i_begin_col             = 1
      i_begin_row             = 1
      i_end_col               = 256
      i_end_row               = 65536
    TABLES
      intern                  = lt_raw_data
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Error uploading Excel file' TYPE 'E'.
    EXIT.
  ENDIF.

  " Process raw data into structured table
  LOOP AT lt_raw_data INTO DATA(ls_raw_data).
    DATA(ls_excel_data) = VALUE fkkmaze(
      LAUFD = ls_raw_data-col
      LAUFI = ls_raw_data-col
      GPART = ls_raw_data-col
      " Add more fields as per your structure
    ).
    APPEND ls_excel_data TO lt_excel_data.
  ENDLOOP.

  " Create field catalog for ALV
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZEXCEL_DATA'
    CHANGING
      ct_fieldcat      = lt_fieldcat
    EXCEPTIONS
      OTHERS           = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Error creating field catalog' TYPE 'E'.
    EXIT.
  ENDIF.

  " Create ALV grid
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  " Create ALV grid container
  DATA(lo_container) = NEW cl_gui_custom_container(
    container_name = 'ALV_CONTAINER'
  ).

  " Create ALV grid
  lo_alv_grid = NEW cl_gui_alv_grid(
    i_parent = lo_container
  ).

  " Set ALV grid data
  CALL METHOD lo_alv_grid->set_table_for_first_display
    EXPORTING
      i_structure_name = 'FKKMAZE'
    CHANGING
      it_outtab        = lt_excel_data
      it_fieldcatalog  = lt_fieldcat
    EXCEPTIONS
      OTHERS           = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying ALV grid' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'EXIT' OR 'BACK' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.


FORM f4_help_for_file_selection.
  DATA: lt_file_table TYPE TABLE OF rlgrap-filename,
        lv_path TYPE string.

  " Use standard file selection dialog
  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      program_name        = sy-repid
      dynpro_number       = sy-dynnr
      field_name          = 'P_FILE'
    IMPORTING
      file_name           = lv_filename
    EXCEPTIONS
      OTHERS              = 1.

  IF sy-subrc = 0.
    p_file = lv_filename.
  ELSE.
    MESSAGE 'Error selecting file' TYPE 'E'.
  ENDIF.
ENDFORM.

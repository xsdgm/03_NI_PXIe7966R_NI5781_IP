@echo off
call "C:\NIFPGA\programs\Xilinx14_7\settings32.bat"
"C:\NIFPGA\programs\Xilinx14_7\ISE\bin\nt\xst.exe" -intstyle xflow -ifn "C:\03_NI_PXIe7966R_NI5781_IP\build\ise14_7\fog_core_ni7966r_ni5781_lv_adapter\fog_core_ni7966r_ni5781_lv_adapter.xst" -ofn "C:\Users\aa\Desktop\code_sitai_labview\03_NI_PXIe7966R_NI5781_IP\build\ise14_7\fog_core_ni7966r_ni5781_lv_adapter\fog_core_ni7966r_ni5781_lv_adapter.syr"
exit /b %ERRORLEVEL%

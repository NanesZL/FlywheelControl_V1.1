
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name FlywheelControl_V1.1 -dir "E:/Zhangliumingyuan/ISE_Projects/FlywheelControl_V1.1/planAhead_run_2" -part xc4vlx25ff668-10
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/Zhangliumingyuan/ISE_Projects/FlywheelControl_V1.1/Top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/Zhangliumingyuan/ISE_Projects/FlywheelControl_V1.1} {ipcore_dir} }
add_files [list {ipcore_dir/Chipscope_ICON.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/Chipscope_ILA.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "E:/Zhangliumingyuan/ISE_Projects/FlywheelControl_V1.1/user/Flywheel.ucf" [current_fileset -constrset]
add_files [list {E:/Zhangliumingyuan/ISE_Projects/FlywheelControl_V1.1/user/Flywheel.ucf}] -fileset [get_property constrset [current_run]]
link_design

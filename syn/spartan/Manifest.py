action = "synthesis"

syn_device = "xc7s15"
syn_package = "ftgb196"
syn_grade = "-1"
syn_tool = "vivado"
syn_top = "topUnit"
syn_project = "gbahd.xpr"

syn_fail_on_timing = False

fetchto = "../../ip"

modules = {
    "local": ["../../hdl"],
    "git": [
        "https://github.com/hdl-util/hdmi.git@@b2e5688"
    ]
}

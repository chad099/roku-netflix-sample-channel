Function InitTheme() as void
    app = CreateObject("roAppManager")
    primaryText                 = "#FFFFFF"
    secondaryText               = "#707070"
    'buttonText                 = "#C0C0C0"
    'buttonHighlight            = "#ffffff"
    backgroundColor             = "#FFFFFF"
    logo_X                      = "60"
    logo_Y                      = "47"
    logo_SD_Y                   = "47"
    logo_SD_X                   = "200"

    theme = {
        BackgroundColor                   : backgroundColor
        OverhangSliceHD                   : "pkg:/images/Overhang_Slice_HD.png"
        OverhangSliceSD                   : "pkg:/images/Overhang_Slice_SD.png"
        OverhangLogoHD                    : "pkg:/images/channel_logo.png"
        OverhangLogoSD                    : "pkg:/images/channel_logo.png"
        OverhangPrimaryLogoOffsetHD_X     : logo_X
        OverhangPrimaryLogoOffsetHD_Y     : logo_Y
        OverhangPrimaryLogoOffsetSD_Y     : logo_Y
        OverhangPrimaryLogoOffsetSD_X     : logo_SD_X
        BreadcrumbTextLeft                : "#ADAD00"
        BreadcrumbTextRight               : "#ADAD00"
        BreadcrumbDelimiter               : "#37491D"
        'ThemeType: "generic-dark"
        GridScreenListNameColor           : "#666666"
        GridScreenDescriptionRuntimeColor : "#2A6496"
        GridScreenDescriptionSynopsisColor: "#000000"
        GridScreenLogoHD                  : "pkg:/images/channel_logo.png"
        GridScreenOverhangSliceHD         : "pkg:/images/Overhang_Slice_HD.png"
        GridScreenOverhangSliceSD         : "pkg:/images/Overhang_Slice_SD.png"
        GridScreenOverhangHeightHD        : "137"
        GridScreenOverhangHeightSD        : "137"
        GridScreenBackgroundColor         : backgroundColor
        GridScreenRetrievingColor         : "#FBFAFA"
        GridScreenLogoOffsetHD_Y          : logo_Y
        GridScreenLogoOffsetHD_x          : logo_X
        GridScreenLogoOffsetSD_Y          : logo_Y
        GridScreenLogoOffsetSD_x          : logo_SD_X
    }
    app.SetTheme( theme )
End Function

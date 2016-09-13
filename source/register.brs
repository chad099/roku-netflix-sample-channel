Function checkUserRegistration() As Integer
    m.RegToken = loadRegistrationToken()
    if isLinked() then
          return 1
    endif
  return 0
End Function

Function GetDeviceESN() As String
  sn = CreateObject("roDeviceInfo")
  return sn.GetDeviceUniqueId()
End Function

Function doRegistration() As Integer

    m.UrlBase         = Config().url + "/roku"
    m.UrlGetRegCode   = m.UrlBase + "/getRegCode"
    m.UrlGetRegResult = m.UrlBase + "/getRegResult"
    m.UrlWebSite      = Config().url + "/#!/roku"
    m.RegToken = loadRegistrationToken()
    if isLinked() then
        print "device already linked, skipping registration process"
        'return 0
    endif
    regscreen = displayRegistrationScreen()

    while true
        duration = 0
        sn = GetDeviceESN()
        print "this is device sn :" sn
        regCode = getRegistrationCode(sn)

        print "this is device registration : " regCode

        'if we've failed to get the registration code, bail out, otherwise we'll
        'get rid of the retreiving... text and replace it with the real code
        if regCode = "" then return 2
        regscreen.SetRegistrationCode(regCode)
        print "Enter registration code " + regCode + " at " + m.UrlWebSite + " for " + sn

        'make an http request to see if the device has been registered on the backend
        while true
            sleep(5000)
            status = checkRegistrationStatus(sn, regCode)
            if status < 3 return status
            getNewCode = false
            retryInterval = getRetryInterval()
            retryDuration = getRetryDuration()
            while true
                'print "Wait for " + itostr(retryInterval)
                msg = wait(retryInterval * 1000, regscreen.GetMessagePort())
                duration = duration + retryInterval
                if msg = invalid exit while

                if type(msg) = "roCodeRegistrationScreenEvent"
                    if msg.isScreenClosed()
                        print "Screen closed"
                        return 1
                    elseif msg.isButtonPressed()
                        print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                        if msg.GetIndex() = 0
                            regscreen.SetRegistrationCode("retrieving code...")
                            getNewCode = true
                            exit while
                        endif
                        if msg.GetIndex() = 1 return 1
                    endif
                endif
            end while

            if duration > retryDuration exit while
            if getNewCode exit while

            print "poll prelink again..."
        end while
    end while

End Function


'********************************************************************
'** display the registration screen in its initial state with the
'** text "retreiving..." shown.  We'll get the code and replace it
'** in the next step after we have something onscreen for teh user
'********************************************************************
Function displayRegistrationScreen() As Object

    regsite   = "go to " + m.UrlWebsite
    regscreen = CreateObject("roCodeRegistrationScreen")
    regscreen.SetMessagePort(CreateObject("roMessagePort"))

    regscreen.SetTitle("")
    regscreen.AddParagraph("Please link your Roku player to your account by visiting")
    regscreen.AddFocalText(" ", "spacing-dense")
    regscreen.AddFocalText("From your computer,", "spacing-dense")
    regscreen.AddFocalText(regsite, "spacing-dense")
    regscreen.AddFocalText("and enter this code to activate:", "spacing-dense")
    regscreen.SetRegistrationCode("retrieving code...")
    regscreen.AddParagraph("This screen will automatically update as soon as your activation completes")
    regscreen.AddButton(0, "Get a new code")
    regscreen.AddButton(1, "Back")
    regscreen.Show()

    return regscreen

End Function


'********************************************************************
'** Fetch the prelink code from the registration service. return
'** valid registration code on success or an empty string on failure
'********************************************************************
Function getRegistrationCode(sn As String) As String

    if sn = "" then return ""

    http = NewHttp(m.UrlGetRegCode)
    http.AddParam("partner", "roku")
    http.AddParam("deviceID", sn)
    http.AddParam("deviceTypeName", "roku")

    http.Http.AddHeader("partner","roku")
    http.Http.AddHeader("deviceID",sn)
    http.Http.AddHeader("deviceTypeName","roku")

    rsp = ParseJSON(http.Http.GetToString())

    print "This is code response"; rsp

    'default values for retry logic
    retryInterval = 30  'seconds
    retryDuration = 900 'seconds (aka 15 minutes)
    regCode       = ""

    regCode = rsp.regCode

    print "This is code response"; regCode

    if regCode = "" then
        'Dbg("Parse yields empty registration code")
        ShowConnectionFailed()
    endif

    m.retryDuration = rsp.retryDuration
    m.retryInterval = rsp.retryInterval
    m.regCode = regCode

    return regCode

End Function


'******************************************************************
'** Check the status of the registration to see if we've linked
'** Returns:
'**     0 - We're registered. Proceed.
'**     1 - Reserved. Used by calling function.
'**     2 - We're not registered. There was an error, abort.
'**     3 - We're not registered. Keep trying.
'******************************************************************
Function checkRegistrationStatus(sn As String, regCode As String) As Integer
    http = NewHttp(m.UrlGetRegResult)
    http.AddParam("partner", "roku")
    http.AddParam("deviceID", sn)
    http.AddParam("regCode", regCode)
    http.Http.AddHeader("partner","roku")
    http.Http.AddHeader("deviceID",sn)
    http.Http.AddHeader("regCode",regCode)
    while true
        rsp = ParseJSON(http.Http.GetToString())
        print "This is response:  "rsp
        if rsp.status <> "success" then
            print "Can't parse check registration status response"
            'ShowConnectionFailed()
            return 4
        endif

        if rsp.regToken = "" then
            print "unexpected check registration status response: ",regCode
            ShowConnectionFailed()
            return 2
        endif
        token =  rsp.regToken
        if token <> "" and token <> invalid then
            saveRegistrationToken(token) 'commit it
            m.RegistrationToken = token
            showCongratulationsScreen()
            return 0
        else
            return 3
        endif

    end while
    print "result: " + validstr(regToken) +  " for " + validstr(customerId) + " at " + validstr(creationTime)

    return 3

End Function


'***************************************************************
' The retryInterval is used to control how often we retry and
' check for registration success. its generally sent by the
' service and if this hasn't been done, we just return defaults
'***************************************************************
Function getRetryInterval() As Integer
    if m.retryInterval < 1 then m.retryInterval = 30
    return m.retryInterval
End Function


'**************************************************************
' The retryDuration is used to control how long we attempt to
' retry. this value is generally obtained from the service
' if this hasn't yet been done, we just return the defaults
'**************************************************************
Function getRetryDuration() As Integer
    if m.retryDuration < 1 then m.retryDuration = 900
    return m.retryDuration
End Function


'******************************************************
'Load/Save RegistrationToken to registry
'******************************************************

Function loadRegistrationToken() As dynamic
    m.RegToken =  RegRead("RegToken", "Authentication")
    if m.RegToken = invalid then m.RegToken = ""
    return m.RegToken
End Function

Sub saveRegistrationToken(token As String)
    RegWrite("RegToken", token, "Authentication")
End Sub

Sub deleteRegistrationToken()
    RegDelete("RegToken", "Authentication")
    m.RegToken = ""
End Sub

Function isLinked() As Dynamic
    if Len(m.RegToken) > 0  then return true
    return false
End Function

'******************************************************
'Show congratulations screen
'******************************************************
Sub showCongratulationsScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Congratulations!")
    screen.AddParagraph("You have successfully linked your Roku player to your account")
    screen.AddParagraph("Select 'start' to begin.")
    screen.AddButton(1, "start")
    screen.Show()
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isButtonPressed()
                videoPlayer(m.videoID)
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            endif
        endif
    end while
End Sub

Sub showPurchaseCreditScreen(video) As Integer
  port = CreateObject("roMessagePort")
  screen = CreateObject("roParagraphScreen")
  screen.SetMessagePort(port)
  m.creditDetail = video
  screen.AddHeaderText("Insufficient Credits!")
  screen.AddParagraph("You can purchase credits or pay per view for watch this video.")
  screen.AddParagraph("Video per view credit : "+ tostr(m.currentVideo.credit))
  screen.AddParagraph("Select 'credits' to purchase.")
  if(m.purchaseCreditMessage <> invalid and m.purchaseCreditMessage <> "")
    screen.AddParagraph(m.purchaseCreditMessage)
  end if
  if(m.purchaseCreditMessage <> invalid)
      m.purchaseCreditMessage = ""
  endif
  amounts = CreateObject("roArray", 10, true)
  inc = 0
  m.transactionFee = video.transactionFee
  for each credit in video.credits
    creditstring    = StrI(credit.credit)
    amount          = credit.amount
    perCreditCost   = credit.perCreditCost
    temp = creditstring+" credit = $"+ amount +" ( $"+ perCreditCost +" / credit )"
    data = {
        credit:credit.credit
        amount:credit.amount
        perCreditCost:credit.perCreditCost
      }
    amounts.push(data)
    screen.AddButton(inc,temp)
    inc = inc+1
  end  for
  screen.AddButton(9999,"$"+tostr(m.currentVideo.payPerViewPrice)+" pay per view (valid for 24 hours)")
  print "this is amount push"; amounts.count()
  screen.Show()
  if(m.currenScreen <> invalid)
    print "previous screen not closed"
    m.currenScreen.close()
  else
    print "Previous screen not closed"
  endif
  while true
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roParagraphScreenEvent"
          if msg.isScreenClosed()
              print "Screen closed"
              exit while
          else if msg.isButtonPressed()
              print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
              if(msg.GetIndex() = 9999)
                payPerAmountDetail(m.currentVideo)
              else
                amountDetailScreen(amounts[msg.GetIndex()])
                print "I am showPurchaseCreditScreen while loop closed"
              end if
              exit while
          else
              print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
              exit while
          endif
      endif
  end while
End Sub

Sub amountDetailScreen(amount)
    total  = Val(tostr(amount.amount))
    total  = total + Val("0.30")
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.AddHeaderText("Amount Detail")
    screen.AddParagraph(" Amount will be charged from your Good News Media account.")
    screen.AddParagraph("Amount :               $ "+amount.amount)
    screen.AddParagraph("Transaction Fee :  $ 0.30")
    screen.AddParagraph("Total :                      $ "+ toFixed(total) )
    screen.AddButton(1, "continue")
    screen.AddButton(2, "back")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isButtonPressed()
                if(msg.GetIndex() = 1)
                  purchaseCredits(amount.credit)
                else
                  showPurchaseCreditScreen(m.creditDetail)
                endif
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            endif
        endif
    end while
End Sub

Sub purchaseCredits(credit)
    dlg = createObject("roOneLineDialog")
    dlg.setTitle("Please wait...")
    dlg.showBusyAnimation()
    dlg.show()
    print "This is credit ="credit
    credit = tostr(credit)
    authtoken = RegRead("RegToken", "Authentication")
    url = Config().url + "/api/roku-purchase-credits/?credit="+credit
    print "this is url " url
    print "authtoken  "authtoken
    http = NewHttp(url)
    http.addParam("deviceid",GetDeviceESN())
    http.addParam("authtoken",RegRead("RegToken", "Authentication"))
    http.addParam("device","roku")

    http.Http.AddHeader("deviceid",GetDeviceESN())
    http.Http.AddHeader("authtoken",RegRead("RegToken", "Authentication"))
    http.Http.AddHeader("device","roku")

    rsp = ParseJSON(http.Http.GetToString())
    print "This is purchase credit response:  " rsp
    dlg.close()
    if(rsp = invalid)
        obj = {
          status: "failed"
          reason: "unknown"
          message: "Something went wrong!"
        }
        ShowNotification(obj)
    else if(rsp.status = "success")
        m.isPurchaseCredit = true
        m.purchaseCreditMessage = "Not enough credit purchased to play this Video."
        videoPlayer(m.videoID)
    else if(rsp.status = "failed")
      obj = {
        status: "failed"
        reason: "unknown"
        message: rsp.message
      }
      ShowNotification(obj)
    endif

End Sub
